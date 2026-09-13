# Runbook — Uptime Kuma refuses to start after an upgrade (failed DB migration)

Uptime Kuma runs its knex migrations at startup and **exits 1 if one fails**, before it ever
listens. The container never becomes healthy, and because it is the monitoring, nothing is left
to raise the alarm — this failure hides itself.

First seen 2026-08-02 upgrading 2.4.0 → 2.5.0.

## Symptom

```
docker logs uptime-kuma
  Uptime Kuma Version: 2.5.0
  migration file "2026-07-22-0000-fix-stat-daily-overflow.js" failed
  migration failed with error: ROLLBACK TO SAVEPOINT trx6 - SQLITE_ERROR: no such savepoint: trx6
  [DB] ERROR: Database migration failed
  [SERVER] ERROR: Failed to prepare your database: ROLLBACK - SQLITE_ERROR: cannot rollback - no transaction is active
```

## Stop the retry loop FIRST

`restart: "no"` does not protect you here: the crash-heal timer restarts stopped containers, so
the failed migration is re-run against the database **every two minutes**. Take Kuma out of heal
scope before doing anything else:

```bash
cd /opt/homelab && sudo docker compose down uptime-kuma
```

## Assess before repairing — the data is probably fine

A knex migration that fails rolls itself back, so the schema normally stays on the previous
version. Check rather than assume (the container is down, so read the file from the host):

**Read a COPY OF ALL THREE FILES, never `kuma.db` alone.** The database runs in
WAL mode, so the most recent writes are in `kuma.db-wal` and not yet in
`kuma.db` — 4.1 MB of them when this was measured on 2026-09-13. This runbook's
own premise makes that certain rather than unlikely: a container that is
crash-looping was killed, so nothing checkpointed the WAL on the way out.

`?immutable=1` is the specific trap and it used to be on the next line. It tells
SQLite the file cannot change, which makes it **ignore the `-wal` entirely** —
so the assessment below would have reported a monitor count and a schema version
from before the last writes, and reported them confidently. The same trap is
recorded against Pi-hole's FTL database.

```bash
W=/mnt/data/tmp/kuma-assess
sudo rm -rf $W && sudo mkdir -p $W
sudo cp -a /mnt/data/services/uptime-kuma/kuma.db* $W/     # .db, -wal and -shm

sudo docker run --rm -v $W:/d alpine:3.20 \
  sh -c 'apk add -q sqlite; sqlite3 /d/kuma.db \
    "PRAGMA integrity_check; SELECT count(*) FROM monitor; SELECT name FROM knex_migrations ORDER BY id DESC LIMIT 1;"'

sudo rm -rf $W
```

The copy is mounted read-WRITE on purpose: opening it plainly lets SQLite replay
the `-wal`, which is the whole point, and it is a throwaway copy so nothing that
matters is mutated. The live directory is never opened for writing here.

On 2026-08-02 this returned `ok`, 20 monitors, and a last-applied migration still from 2026-05-25
— nothing had been lost, and no restore was needed.

## Decide: is the migration a no-op on this schema?

Read what it actually does:

```bash
sudo docker run --rm --entrypoint sh louislam/uptime-kuma:<version> \
  -c 'cat /app/db/knex_migrations/<failing-file>.js'
```

The 2026-07-22 one alters `stat_daily.up`/`down` from `smallint` to `integer unsigned NOT NULL`.
**SQLite has no unsigned type and the columns were already `integer NOT NULL`** — the migration
would produce byte-identical DDL. It fails only because SQLite has no `ALTER COLUMN`, so knex
rebuilds the whole table by copy, and `stat_daily` is the one table involved that carries a
foreign key.

If, and only if, the migration is provably a no-op on your schema, marking it applied is
semantically correct: the target state is already reached.

## Repair — prove it on a copy first

Never test this on the live database.

```bash
T=/mnt/data/tmp/kuma-trial
sudo mkdir -p $T && sudo cp -a /mnt/data/services/uptime-kuma/kuma.db* $T/   # .db, -wal, -shm

cat > /tmp/mark.sql <<'SQL'
INSERT INTO knex_migrations (name, batch, migration_time)
VALUES ('<failing-file>.js', <max_batch + 1>, datetime('now'));
SQL
sudo docker run --rm -v $T:/d -v /tmp/mark.sql:/s.sql:ro alpine:3.20 \
  sh -c 'apk add -q sqlite; sqlite3 /d/kuma.db < /s.sql'

sudo docker run -d --name kuma-trial --network none -v $T:/app/data louislam/uptime-kuma:<version>
sleep 75 && docker ps -a | grep kuma-trial      # expect: Up … (healthy)
docker logs kuma-trial 2>&1 | grep -iE 'migrat|error|Listening'
```

Check the trial database kept everything, and that `ops/kuma-dump.sh` still reads the schema.

The script prints the column count it derived — `→ 34 monitors, 114 columns
each, derived from the live schema`. **That line is the check.** Compare it with
the pre-upgrade dump: a column count that went UP is the new version's own
additions and is expected; one that went DOWN means the upgrade dropped columns,
and you want to know which before you trust the trial. Until 2026-09-11 the
script named 21 columns by hand out of 114, so this step could not check
anything — it read 19 % of the schema and reported success on that.

```bash
KUMA_CONTAINER=kuma-trial ops/kuma-dump.sh /tmp/kuma-trial.json
```

Then clean up: `sudo docker rm -f kuma-trial && sudo rm -rf $T`.

## Apply to production

```bash
S=/mnt/data/services/uptime-kuma
R=$S/kuma-pre-migration-$(date +%F-%H%M)               # the name carries its run — see below
sudo mkdir -p $R && sudo cp -a $S/kuma.db* $R/         # .db, -wal and -shm, immediately before mutating
sudo docker run --rm -v $S:/d -v /tmp/mark.sql:/s.sql:ro alpine:3.20 \
  sh -c 'apk add -q sqlite; sqlite3 /d/kuma.db < /s.sql'
cd /opt/homelab && sudo docker compose up -d uptime-kuma
```

**Two things about that rollback copy, both learned the hard way.**

It copies `kuma.db*`, not `kuma.db`. A rollback point that omits the `-wal` is a
rollback to an older state than the one you meant to protect, and the 37 monitors
exist nowhere else.

Its name carries a timestamp, so a second migration cannot overwrite the first
one's rollback point. The previous fixed name — `kuma-pre-migration-mark.db` —
meant the second repair compared against, and destroyed, the artefact of the
first. `resticprofile.yaml.j2` excludes these by glob for the same reason; a
literal path would have excluded the 2026-08-02 copies and silently backed up
every later one.

Verify the **function**, not the container state — heartbeats are the proof monitoring resumed:

```bash
docker exec uptime-kuma sqlite3 "file:/app/data/kuma.db?mode=ro" \
  "SELECT count(*) FROM heartbeat WHERE time > datetime('now','-3 minutes');"
```

Expect a non-zero count from roughly a dozen distinct monitors; the push-type ones (Pi health,
Lynis, restic, posture) report on their own slower schedules and will lag.

## Before any Kuma upgrade

Uptime Kuma carries `dependencyDashboardApproval` in `renovate.json` for this reason — it never
rides the weekly batch. Take both backups first; they cost seconds and turn an incident into an
investigation:

```bash
ops/kuma-dump.sh .secrets/kuma-dump-pre-<version>.json          # config inventory
docker exec uptime-kuma sqlite3 "file:/app/data/kuma.db?mode=ro" \
  ".backup /app/data/kuma-pre-<version>.db"                     # consistent DB copy
```

The monitors exist **only** in that database — Kuma v2 dropped the built-in export and the
lucasheld tooling is v1-only, so they are re-entered by hand if lost.

## Caveat

Marking a migration applied means knex will skip that filename forever. If upstream ships a fixed
version of the *same* file, it will not run. That is harmless when the migration was a no-op on
this schema, but it must stay true — re-read this page before assuming it of the next one.

See also: ADR-013 (update & patching strategy), `docs/07-observability/`, `ops/kuma-dump.sh`.
