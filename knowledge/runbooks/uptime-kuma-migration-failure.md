# Runbook — Uptime Kuma refuses to start after an upgrade (failed DB migration)

Use this when Uptime Kuma exits at startup after an image bump. Kuma runs its knex migrations
before it listens and exits 1 if one fails; since Kuma is the monitoring, nothing alerts on it.

## Symptom

```
docker logs uptime-kuma
Uptime Kuma Version: 2.5.0
migration file "2026-07-22-0000-fix-stat-daily-overflow.js" failed
migration failed with error: ROLLBACK TO SAVEPOINT trx6 - SQLITE_ERROR: no such savepoint: trx6
[DB] ERROR: Database migration failed
[SERVER] ERROR: Failed to prepare your database: ROLLBACK - SQLITE_ERROR: cannot rollback - no transaction is active
```

## Before you start

- Always copy all three files, `kuma.db*` (`.db`, `-wal`, `-shm`), never `kuma.db` alone: a
  crash-looping container never checkpointed its WAL, so recent writes live only in `-wal`.
- Never open a copy with `?immutable=1`: it makes SQLite ignore the `-wal` entirely.
- Never test on the live database.

## Steps

### 1. Stop the retry loop

`restart: "no"` does not help: the crash-heal timer restarts the container and re-runs the
migration every two minutes. Take it out of heal scope first:

```bash
cd /opt/homelab && sudo docker compose down uptime-kuma
```

### 2. Assess the data on a copy

A failed knex migration normally rolls back, so the data is probably intact. The throwaway copy is
opened read-write so SQLite replays the `-wal`. Every copy on this page expands its glob inside
`sudo sh -c`: the directory is `0700 root`, so the operator's shell cannot see `kuma.db*`, and a
plain `sudo cp` would copy nothing. `test -s` stops the step when the copy is empty.

```bash
S=/mnt/data/services/uptime-kuma
W=/mnt/data/tmp/kuma-assess
sudo rm -rf $W && sudo mkdir -p $W
sudo sh -c "cp -a $S/kuma.db* $W/" && sudo test -s $W/kuma.db

sudo docker run --rm -v $W:/d alpine:3.24 \
  sh -c 'apk add -q sqlite; sqlite3 /d/kuma.db \
    "PRAGMA integrity_check; SELECT count(*) FROM monitor; SELECT name FROM knex_migrations ORDER BY id DESC LIMIT 1;"'

sudo rm -rf $W
```

Expected: `ok`, the usual monitor count, and a last-applied migration older than the failing one.
If so, no restore is needed.

### 3. Decide whether the migration is a no-op on this schema

```bash
sudo docker run --rm --entrypoint sh louislam/uptime-kuma:<version> \
  -c 'cat /app/db/knex_migrations/<failing-file>.js'
```

Example: the 2026-07-22 migration retypes `stat_daily.up`/`down` to `integer unsigned NOT NULL`,
identical in SQLite to the existing `integer NOT NULL`. Mark a migration applied only if it is
provably a no-op like this one.

### 4. Prove the repair on a trial copy

```bash
T=/mnt/data/tmp/kuma-trial
sudo mkdir -p $T && sudo sh -c "cp -a $S/kuma.db* $T/" && sudo test -s $T/kuma.db

cat > /tmp/mark.sql <<'SQL'
INSERT INTO knex_migrations (name, batch, migration_time)
VALUES ('<failing-file>.js', <max_batch + 1>, datetime('now'));
SQL
sudo docker run --rm -v $T:/d -v /tmp/mark.sql:/s.sql:ro alpine:3.24 \
  sh -c 'apk add -q sqlite; sqlite3 /d/kuma.db < /s.sql'

sudo docker run -d --name kuma-trial --network none -v $T:/app/data louislam/uptime-kuma:<version>
timeout 900 sh -c 'until sudo docker logs kuma-trial 2>&1 | grep -q "Listening on"; do sleep 15; done'
docker logs kuma-trial 2>&1 | grep -iE 'migrat|error|Listening'
```

Expected: the wait returns within about 7 minutes, and the logs show `Listening on` with no migration error.
A timeout after 15 minutes means the repair failed.

Then dump the trial schema:

```bash
KUMA_CONTAINER=kuma-trial ops/kuma-dump.sh /tmp/kuma-trial.json
```

It prints e.g. `→ 34 monitors, 114 columns each, derived from the live schema`. Compared with the
pre-upgrade dump, more columns is expected; fewer means dropped columns — find which before trusting
the trial.

Clean up: `sudo docker rm -f kuma-trial && sudo rm -rf $T`.

### 5. Apply to production

The rollback copy carries a timestamp so a later repair cannot overwrite it; `resticprofile.yaml.j2`
excludes these copies by glob.

```bash
S=/mnt/data/services/uptime-kuma
R=$S/kuma-pre-migration-$(date +%F-%H%M)
sudo mkdir -p $R && sudo sh -c "cp -a $S/kuma.db* $R/" && sudo test -s $R/kuma.db \
  && sudo docker run --rm -v $S:/d -v /tmp/mark.sql:/s.sql:ro alpine:3.24 \
    sh -c 'apk add -q sqlite; sqlite3 /d/kuma.db < /s.sql'
cd /opt/homelab && sudo docker compose up -d uptime-kuma
```

## Check it worked

Heartbeats, not container state, prove monitoring resumed. Kuma takes 5 to 7 minutes to start listening;
run this once `docker logs uptime-kuma` shows `Listening on`:

```bash
docker exec uptime-kuma sqlite3 "file:/app/data/kuma.db?mode=ro" \
  "SELECT count(*) FROM heartbeat WHERE time > datetime('now','-3 minutes');"
```

Expected: non-zero, from about twenty monitors (every 60 s check). Push monitors (Pi health, Lynis, restic,
posture) report on their own slower schedules and lag.

## Before any Kuma upgrade

Kuma has `dependencyDashboardApproval` in `renovate.json`, so it never rides the weekly batch.
Take both backups first — the monitors exist only in this database and are re-entered by hand if
lost:

```bash
ops/kuma-dump.sh .secrets/kuma-dump-pre-<version>.json
docker exec uptime-kuma sqlite3 "file:/app/data/kuma.db?mode=ro" \
  ".backup /app/data/kuma-pre-<version>.db"
```

## Caveat

A migration marked applied is skipped forever, even if upstream ships a fixed version of the same
file. That is harmless only while it stays a no-op on this schema — re-check for the next one.

See also: ADR-013 (update & patching strategy), `docs/07-observability/`, `ops/kuma-dump.sh`.
