# Runbook — Restore from backup (Restic)

> **Last tested: 2026-07-19** — Immich built-in dump restored end-to-end into a throwaway
> VectorChord postgres (search_path transform + `--single-transaction --set ON_ERROR_STOP=on`):
> 66 tables, `vector`/`vchord`/`vectors` extensions, 9 283 `asset` rows + 9 247 `smart_search`
> embeddings. Vaultwarden `.backup` restored from the snapshot (`PRAGMA integrity_check` = ok).
> Local prune+check timer exercised (deep read-data + metadata paths).
> Earlier (2026-07-11): `restic check --read-data-subset=2%`, Vaultwarden scratch restore,
> Nextcloud dump into a throwaway MariaDB (156 tables).

Backups are made by `homelab-backup.timer`, which runs resticprofile (ADR-031), into the Restic repo
at `/mnt/data/backups/restic-repo`. They cover `/mnt/data/services` (service data),
`/mnt/data/media` (photos/music/videos), `/mnt/data/secrets` (the credential files —
omitted from this list until #178, though the backup has always included them), the
DB dumps, and `/opt/homelab`. See
`docs/06-backup/README.md`.

## Prerequisites

Restic needs the repo credentials and a HOME (for its cache). As root on the Pi:

```bash
sudo -i
set -a; . /opt/homelab/backup.env; set +a   # RESTIC_REPOSITORY, RESTIC_PASSWORD
export HOME=/root
restic snapshots          # list snapshots
```

## Restore a single file or folder

```bash
# Safest: restore into a scratch dir, then copy out what you need
restic restore latest --target /tmp/restore --include /mnt/data/services/vaultwarden

# Or restore in place (OVERWRITES existing files)
restic restore latest --target / --include /mnt/data/media/photos/2019
```

## Restore one service

`compose down`, never `docker stop`. The heal timer brings a stopped
container back within two minutes — on top of the files being restored,
with the service reading them as they change (ADR-007). Removing the
container takes it out of the timer's view entirely.

```bash
cd /opt/homelab
docker compose down <service>
restic restore latest --target / --include /mnt/data/services/<service>
docker compose up -d <service>
```

`<service>` is the **compose service name**, not the container name. They
are identical for every service here except `immich-machine-learning`,
whose container is named `immich-ml`; `compose` answers "no such service"
rather than doing nothing quietly.

(Each service's own doc lists its exact path.)

## Ownership after a restore

Five services start **as** uid 999 rather than as root (`user:` in
`compose.yaml`), which is what lets them run with no capability at all
(ADR-017). The consequence for a restore: **they can no longer repair the
ownership of their own data directory**, because `CHOWN` is gone.

Measured on the running host, so the list below is the one to act on:

| Service | Data directory to own |
|---|---|
| `nextcloud-db` | `/mnt/data/services/nextcloud/db` |
| `immich-db` | `/mnt/data/services/immich/db` |
| `miniflux-db` | `/mnt/data/services/miniflux/db` |
| `nextcloud-redis` | none — no bind mount, nothing to repair |
| `immich-redis` | none — no bind mount, nothing to repair |

`nextcloud-cron` is **not** in this set, whatever ADR-017 used to say: starting
it as uid 33 was tried and reverted under #28, so it runs as root with `SETUID`
and `SETGID`.

`restic restore` runs as root and preserves ownership, so a normal restore is
safe. What is not safe is recreating a datadir by hand — `mkdir`, `cp -r` out of
`/tmp/restore`, or an `rsync` without `-a` — which leaves it owned by root.
Postgres then refuses to start ("data directory has wrong ownership") and
MariaDB fails on its first write.

```bash
# After any hand-made copy into a database directory — all three, miniflux
# included: it is a uid-999 datadir on a container with cap_drop: ALL, so it has
# nothing left to repair itself with.
chown -R 999:999 /mnt/data/services/nextcloud/db /mnt/data/services/immich/db /mnt/data/services/miniflux/db
chmod 700        /mnt/data/services/nextcloud/db /mnt/data/services/immich/db /mnt/data/services/miniflux/db
# Or simply let Ansible do it:
ansible-playbook playbooks/site.yml --tags storage --ask-vault-pass
```

Run that **after every restore**, not only after a hand-made copy: restic
returns files with the ownership and permissions they had *in the snapshot*,
which is not necessarily what the current configuration expects. Measured in the
2026-07-27 drill below — the restored Nextcloud datadir came back mode 755, the
value it had before that morning's change to 700.

## Restore a database

DB dumps are taken before each backup and captured in the snapshot at
`/mnt/data/backups/dumps/`. They are deleted from disk after each run, so restore them from a
snapshot first:

```bash
restic restore latest --target /tmp/restore --include /mnt/data/backups/dumps

# Nextcloud (MariaDB) — put it in maintenance mode around the import
docker exec -u www-data nextcloud php occ maintenance:mode --on
docker exec -i nextcloud-db sh -c \
  'MYSQL_PWD=$(cat /run/secrets/nextcloud_db_password) mariadb -u"$MYSQL_USER" "$MYSQL_DATABASE"' \
  < /tmp/restore/mnt/data/backups/dumps/nextcloud.sql
docker exec -u www-data nextcloud php occ maintenance:mode --off

# Immich (PostgreSQL) — see "Restore Immich" below (special search_path handling)
# Miniflux (PostgreSQL), Forgejo (SQLite) — see their own sections below: both
# need the target reset or the service stopped first, not just an import.
```

## Restore Vaultwarden (SQLite)

The nightly backup writes a consistent `sqlite3 .backup` copy to
`/mnt/data/backups/dumps/vaultwarden.sqlite3` (captured in the snapshot). Restore
that file rather than the live `db.sqlite3` from the service folder — the live
copy can carry a torn WAL. Restore it as the new database:

```bash
restic restore latest --target /tmp/restore --include /mnt/data/backups/dumps

cd /opt/homelab
docker compose down vaultwarden
# Drop any stale WAL/SHM so SQLite reopens cleanly from the restored DB
rm -f /mnt/data/services/vaultwarden/db.sqlite3-wal /mnt/data/services/vaultwarden/db.sqlite3-shm
cp /tmp/restore/mnt/data/backups/dumps/vaultwarden.sqlite3 \
   /mnt/data/services/vaultwarden/db.sqlite3
docker compose up -d vaultwarden
```

(Attachments/sends/rsa keys live alongside the DB in `/mnt/data/services/vaultwarden`
and are already restored by a full service restore — see "Restore one service".)

## Restore Immich (PostgreSQL — VectorChord / pgvecto.rs)

Immich takes its **own** scheduled DB backup (Admin → Settings → Backup), written
to `/mnt/data/services/immich/upload/backups/*.sql.gz` and captured in the restic
snapshot (`/mnt/data/services` is in the set). Restore follows Immich's official
procedure: the `search_path` `sed` transform is **mandatory** for the vector
extensions, and the dump must be loaded into a **freshly-initialised** database.

> ⚠️ Our stack is one shared `compose.yaml`, and the Immich DB is a **bind mount**
> (`services/immich/db`), not a named volume — so **never** run
> `docker compose down -v` (it would target every service's volumes). Reset only
> the Immich DB directory, as below.

```bash
# 1. Get the newest dump (from disk, or restore the folder from a snapshot first):
restic restore latest --target /tmp/restore \
  --include /mnt/data/services/immich/upload/backups
# `sudo sh -c`, NOT `sudo ls`: the directory is 0700 root since #272, and a glob
# in `sudo ls /path/*.sql.gz` is expanded by YOUR shell, which cannot read it —
# you get "no matches" rather than a permission error, which reads like an empty
# backup directory. The restored copy under /tmp is root-owned 0700 for the same
# reason, so it needs the same form.
DUMP=$(sudo sh -c 'ls -t /mnt/data/services/immich/upload/backups/*.sql.gz' | head -1)
# (or: DUMP=$(sudo sh -c 'ls -t /tmp/restore/mnt/data/services/immich/upload/backups/*.sql.gz' | head -1))

cd /opt/homelab

# 2. Remove Immich's containers and reset the DB dir so the container re-runs
#    initdb (fresh, empty `immich` database owned by the `immich` superuser).
#    `down`, not `stop`: a stopped container is resurrected by the heal timer
#    within two minutes, and here that lands on a datadir being deleted.
#    `immich-machine-learning` is the COMPOSE SERVICE; `immich-ml` is only its
#    container_name, and compose rejects the whole command with "no such
#    service" if you pass it. That matters more here than anywhere else in this
#    file: the very next line deletes the database directory, so a command that
#    removes nothing leaves you deleting a datadir under a running Postgres.
docker compose down immich-server immich-machine-learning immich-db immich-redis
rm -rf /mnt/data/services/immich/db/*

# 3. Bring the DB back up empty and wait until it is healthy:
docker compose up -d immich-db
until [ "$(docker inspect -f '{{.State.Health.Status}}' immich-db)" = healthy ]; do sleep 2; done

# 4. Load the dump — search_path transform + atomic, abort-on-error import:
gunzip --stdout "$DUMP" \
| sed "s/SELECT pg_catalog.set_config('search_path', '', false);/SELECT pg_catalog.set_config('search_path', 'public, pg_catalog', true);/g" \
| docker exec -i immich-db psql \
    --dbname=immich --username=immich \
    --single-transaction --set ON_ERROR_STOP=on

# 5. Start the rest of the stack:
docker compose up -d immich-server immich-machine-learning immich-redis
```

Sanity-check: log in, confirm the timeline and search (VectorChord) work. The
photo/video files themselves live in `services/immich/upload` and `media/photos`
— restore those from a snapshot too if they were lost.

## Restore Miniflux (PostgreSQL)

The nightly backup writes a plain-SQL `pg_dump` to
`/mnt/data/backups/dumps/miniflux.sql` (captured in the snapshot). Restore that,
**not** the datadir under `services/miniflux/db`: the datadir is in the restic
set, but restic walks it file by file while Postgres writes, so the copy in a
snapshot can be a torn cluster. The dump carries no `--clean`, so it has to be
loaded into a freshly-initialised database.

> `down`, not `stop`: the crash-heal timer brings back containers it finds
> exited, so a merely stopped service can return mid-restore
> (`homelab-stack-heal.sh`).

```bash
restic restore latest --target /tmp/restore --include /mnt/data/backups/dumps

cd /opt/homelab

# 1. Remove both containers — the reader too, so nothing writes during the load:
docker compose down miniflux miniflux-db

# 2. Reset the datadir so the entrypoint re-runs initdb. Clear the parent, not
#    db/18/docker: Postgres 18 keeps PGDATA one level below the mounted volume.
rm -rf /mnt/data/services/miniflux/db/*

# 3. Bring the database back up empty and wait until it is healthy:
docker compose up -d miniflux-db
until [ "$(docker inspect -f '{{.State.Health.Status}}' miniflux-db)" = healthy ]; do sleep 2; done

# 4. Load the dump — atomic, abort on first error:
docker exec -i miniflux-db psql \
    --dbname=miniflux --username=miniflux \
    --single-transaction --set ON_ERROR_STOP=on \
  < /tmp/restore/mnt/data/backups/dumps/miniflux.sql

# 5. Start the reader again:
docker compose up -d miniflux
```

(Role and database are both `miniflux` unless `miniflux_db_user` /
`miniflux_db_name` were overridden in `local.yml`.)

Sanity-check: log in at `https://rss.<domain>` and confirm the feed list and the
unread counts. Nothing else to restore — Miniflux keeps all of its state in
Postgres, which is why its container needs no writable filesystem at all.

## Restore Forgejo (SQLite)

Two halves, and both are needed. The database
(`/mnt/data/backups/dumps/forgejo.sqlite3`, a consistent `sqlite3 .backup` copy)
holds the users, the repository list and the mirror settings; the repositories
themselves are plain files under `services/forgejo/data/git/repositories` that
restic restores directly. Restore only one and you get a forge that lists
repositories it cannot serve, or serves repositories it does not list.

```bash
restic restore latest --target /tmp/restore \
  --include /mnt/data/backups/dumps \
  --include /mnt/data/services/forgejo

cd /opt/homelab
docker compose down forgejo

# Repositories and config — skip if only the database was lost:
rsync -a --delete /tmp/restore/mnt/data/services/forgejo/ /mnt/data/services/forgejo/

# Database. The doubled data/data is the rootless layout, not a typo: the host
# directory forgejo/data is mounted at /var/lib/gitea, and APP_DATA_PATH sits
# one level under that. Drop any stale WAL/SHM so SQLite reopens cleanly.
rm -f /mnt/data/services/forgejo/data/data/forgejo.db-wal \
      /mnt/data/services/forgejo/data/data/forgejo.db-shm
cp /tmp/restore/mnt/data/backups/dumps/forgejo.sqlite3 \
   /mnt/data/services/forgejo/data/data/forgejo.db

chown -R 1000:1000 /mnt/data/services/forgejo   # `git` in the rootless image
docker compose up -d forgejo
```

Sanity-check: log in at `https://git.<domain>`, then Repository → Settings →
Mirror Settings → *Synchronize Now*. There are no mirror credentials to restore:
the pull runs tokenless by decision (ADR-028), which also means issues and pull
requests were never mirrored — only the git objects come back.

## Restore Uptime Kuma (SQLite)

Restore this one early, not last. Every dead-man's switch in the lab — nightly
backup, offsite copy, weekly audit, disk report, feed digest — terminates in a
Kuma push monitor, so until Kuma is back nothing is watching the recovery
itself. The database also has no second copy anywhere: Kuma v2 has no
configuration export, and the monitors were entered by hand in the web UI.

```bash
restic restore latest --target /tmp/restore \
  --include /mnt/data/backups/dumps \
  --include /mnt/data/services/uptime-kuma

cd /opt/homelab
docker compose down uptime-kuma

# Drop any stale WAL/SHM so SQLite reopens cleanly against the restored file.
rm -f /mnt/data/services/uptime-kuma/kuma.db-wal \
      /mnt/data/services/uptime-kuma/kuma.db-shm
cp /tmp/restore/mnt/data/backups/dumps/uptime-kuma.sqlite3 \
   /mnt/data/services/uptime-kuma/kuma.db
chown root:root /mnt/data/services/uptime-kuma/kuma.db   # the image runs as root

docker compose up -d uptime-kuma
```

Sanity-check by *function*, not by a green container: log in at
`https://services.<domain>`, confirm the monitor count, and confirm the
notification channel is still attached (Settings → Notifications) — a restored
monitor list that notifies nobody looks healthy and is not.

The push tokens come back inside the database, so the push URLs held in
`local.yml` and `backup.env` keep matching and the dead-man's switches resume on
their own. That only holds because both halves ride the same snapshot: if you
ever restore the database from an *older* snapshot than the configuration, the
tokens diverge and every push monitor stays silently DOWN.

## Full disaster recovery

1. **Re-provision the OS** with Ansible (the OS isn't backed up — it's reproducible): flash
   Ubuntu, then `ansible-playbook playbooks/site.yml`. The LUKS disk is passphrase-based and
   hardware-independent.
2. **Point Restic at the repo** (local on `/mnt/data`, or the offsite repo — see
   `offsite-backup.md` when the homelab itself is lost) and restore data.
   Secrets first, and on their own: `/opt/homelab` holds symlinks *into*
   `/mnt/data/secrets` (ADR-011), so restoring it first leaves every `.env`
   dangling — and a container that finds a directory where a secret file
   should be fails the way #27 did.
   ```bash
   restic restore latest --target / --include /mnt/data/secrets
   restic restore latest --target / \
     --include /opt/homelab \
     --include /mnt/data/services \
     --include /mnt/data/media \
     --include /mnt/data/backups/dumps
   ```
   `/mnt/data/backups/dumps` is not optional here: the dumps are deleted from
   disk after each run, so the snapshot is the only place they exist — and step
   3 needs them.

   > **This path does not depend on `local.yml`, and that is the point.** Step 1
   > says Ansible can regenerate all of this, which is true — but only while
   > `local.yml` survives, and `local.yml` is gitignored and lives in no
   > backed-up path. Restoring `/mnt/data/secrets` is the branch that still
   > works when it does not. Without it there is also no `wg0.conf`, therefore
   > no tunnel, on a Pi whose only remote access is that tunnel.
3. **Import the DB dumps** (see above), then bring services up (`docker compose up -d`,
   handled by the deploy role).
4. Sanity-check services; re-run `occ files:scan` if media browsing looks stale.

## Drill record

A restore procedure that has never been executed is a hypothesis. Each drill
goes here, with what it measured and what it contradicted.

### 2026-08-15 — second drill, **on site, with the homelab cut off**

The July drill restored from the offsite repository *through the tunnel*, which
still routes via the machine whose loss it insures against. This one was run
standing next to the offsite Pi, with the WireGuard tunnel down, to answer the
only question that matters: can the data be read when the homelab no longer
exists?

Both paths were exercised and produced the same bytes:

| Path | Volume | Time |
|---------------------------------------|-------------|------|
| Through the tunnel (rest-server) | 22.819 MiB | 3 s |
| On site, tunnel down, local repo path | 22.819 MiB | < 1 s |

Verified by *loading*, never by listing:

- `vaultwarden.sqlite3` — `pragma integrity_check` ok, 1 user, **591 ciphers**
- `forgejo.sqlite3` — `pragma integrity_check` ok, 1 repository, 1 user
- `nextcloud.sql` — MariaDB header and `Dump completed` trailer, **168 tables**

Repository state read directly off the disk: 343 GB, 20 991 pack files, last
written the same morning at 03:06 — the nightly copy had landed.

**What the drill contradicted or confirmed:**

1. **The password you reach for first is the wrong one.** The local and offsite
   repositories have different passwords by design (ADR-010), and the first
   on-site attempt failed on exactly that. The working value is
   `offsite_restic_password`, not the local `restic_password`. Knowing *which*
   secret opens the offsite repository is part of the procedure, not a detail to
   work out during an incident.
2. **The recovery toolbox was not reproducible from this repository.** `restic`
   was present only because someone installed it by hand in July; `sqlite3` was
   absent, so the integrity check could not run on site at all. A rebuilt
   offsite Pi would not have been able to read its own repository. Now installed
   by `roles/offsite-backup/tasks/toolbox.yml`.
3. **Reaching the Pi by its LAN address trips host-key verification** — the key
   is known under the tunnel address. Compare the fingerprint against the known
   entry rather than accepting blindly; they matched.
4. **The repository needs `sudo` to read**: it belongs to `rest-server`, so an
   unprivileged `restic -r` fails on `keys/` before ever asking for a password.
5. **Confirmed**: restic 0.16.4 on both sides, so no repository-format mismatch
   between reading it in place and reading it from the homelab.

### 2026-07-27 — first drill, from the **offsite** repository (issue #36)

Restored through the WireGuard tunnel from the repo at the relative's house —
the one that matters when the house is gone — not from the local one.

| What | Volume | Time |
|--------------------------------|-----------|--------|
| DB dumps (`nextcloud.sql`, `vaultwarden.sqlite3`) | 13.3 MiB | 2 s |
| Nextcloud datadir (`services/nextcloud/db`) | 243 MiB | 18 s |

**≈ 13.5 MiB/s** through the tunnel. The whole snapshot is **343 GiB across
116 482 files**, so a full restore at that rate is **around 7 hours** — the
number worth knowing before deciding anything during an incident.

Verified by *loading*, never by listing:

- `vaultwarden.sqlite3` — `pragma integrity_check` ok, 1 user, 587 ciphers.
- The restored datadir **started a MariaDB** under the current hardened
  configuration (uid 999, no capability, read-only rootfs) and answered
  queries: 1 user, 18 899 filecache rows.
- The SQL dump imported into a fresh database in 10 s and produced the *same*
  counts — so the dump and the datadir agree, which no `ls` would have shown.

**What the drill contradicted or confirmed:**

1. **A restore returns the permissions of the snapshot, not today's.** The
   datadir came back mode 755 — its value before it was tightened to 700 the
   same morning. Harmless for MariaDB, fatal for Postgres, and a real trap now
   that the databases run as uid 999 with no `CHOWN` to repair themselves.
   **Re-run the storage role after any restore** (see "Ownership after a
   restore" above). This was written that morning as a precaution; the drill
   turned it into a measured fact.
2. **Retention starts 2026-07-11** (20 snapshots offsite). Anything older is
   gone, including the pre-Immich-v3 state — which retroactively justified
   deleting the v2.7.5 images the same day: the rollback path they existed for
   had already expired.
3. **The passphrase survives the house.** The offsite repo password is
   deliberately absent from the offsite Pi, and every copy that lives at home
   is taken by the same fire — so the recovery chain rests on it existing in at
   least two independent places outside the homelab, at least one of them
   reachable with no network and no other secret. That path was verified cold
   on 2026-07-27, with no server reachable. **Re-verify at each drill**: it
   breaks silently — a reinstall or a reorganisation is enough — and it is the
   only path that survives the house.

**Next drill: 2027-07** (annual). Bring it forward if the storage layout, the
uid model or the repository backend changes.

## Verify a backup without restoring

```bash
restic check                  # repo integrity
restic snapshots --latest 1   # confirm the most recent snapshot exists and is recent
```

See also: `docs/06-backup/README.md`, `knowledge/runbooks/backup-monitoring.md`.
