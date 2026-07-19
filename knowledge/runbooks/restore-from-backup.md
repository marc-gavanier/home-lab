# Runbook — Restore from backup (Restic)

> **Last tested: 2026-07-11** — full drill on the Pi: `restic check` (incl. `--read-data-subset=2%`),
> Vaultwarden restore to scratch (SQLite integrity OK), Nextcloud dump imported into a throwaway
> MariaDB container (156 tables). Immich dump header-checked only (PostgreSQL import not drilled).

Backups are made by `ansible/roles/deploy/files/backup.sh` (daily `homelab-backup.timer`) into the Restic repo
at `/mnt/data/backups/restic-repo`. They cover `/mnt/data/services` (service data),
`/mnt/data/media` (photos/music/videos), the DB dumps, and `/opt/homelab`. See
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

```bash
docker stop <service>
restic restore latest --target / --include /mnt/data/services/<service>
docker start <service>
```

(Each service's own doc lists its exact path.)

## Restore a database

DB dumps are taken before each backup and captured in the snapshot at
`/mnt/data/backups/dumps/`. They are deleted from disk after each run, so restore them from a
snapshot first:

```bash
restic restore latest --target /tmp/restore --include /mnt/data/backups/dumps

# Nextcloud (MariaDB) — put it in maintenance mode around the import
docker exec -u www-data nextcloud php occ maintenance:mode --on
docker exec -i nextcloud-db mariadb -u nextcloud -p"$NEXTCLOUD_DB_PASSWORD" nextcloud \
  < /tmp/restore/mnt/data/backups/dumps/nextcloud.sql
docker exec -u www-data nextcloud php occ maintenance:mode --off

# Immich (PostgreSQL) — see "Restore Immich" below (special search_path handling)
```

## Restore Vaultwarden (SQLite)

The nightly backup writes a consistent `sqlite3 .backup` copy to
`/mnt/data/backups/dumps/vaultwarden.sqlite3` (captured in the snapshot). Restore
that file rather than the live `db.sqlite3` from the service folder — the live
copy can carry a torn WAL. Restore it as the new database:

```bash
restic restore latest --target /tmp/restore --include /mnt/data/backups/dumps

docker stop vaultwarden
# Drop any stale WAL/SHM so SQLite reopens cleanly from the restored DB
rm -f /mnt/data/services/vaultwarden/db.sqlite3-wal /mnt/data/services/vaultwarden/db.sqlite3-shm
cp /tmp/restore/mnt/data/backups/dumps/vaultwarden.sqlite3 \
   /mnt/data/services/vaultwarden/db.sqlite3
docker start vaultwarden
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
DUMP=$(ls -t /mnt/data/services/immich/upload/backups/*.sql.gz | head -1)
# (or: DUMP=$(ls -t /tmp/restore/mnt/data/services/immich/upload/backups/*.sql.gz | head -1))

cd /opt/homelab

# 2. Stop Immich and reset the DB dir so the container re-runs initdb (fresh,
#    empty `immich` database owned by the `immich` superuser):
docker compose stop immich-server immich-ml immich-db immich-redis
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
docker compose up -d immich-server immich-ml immich-redis
```

Sanity-check: log in, confirm the timeline and search (VectorChord) work. The
photo/video files themselves live in `services/immich/upload` and `media/photos`
— restore those from a snapshot too if they were lost.

## Full disaster recovery

1. **Re-provision the OS** with Ansible (the OS isn't backed up — it's reproducible): flash
   Ubuntu, then `ansible-playbook playbooks/site.yml`. The LUKS disk is passphrase-based and
   hardware-independent.
2. **Point Restic at the repo** (local on `/mnt/data`, or the offsite repo — see
   `offsite-backup.md` when the homelab itself is lost) and restore data:
   ```bash
   restic restore latest --target / --include /mnt/data/services --include /mnt/data/media
   ```
3. **Import the DB dumps** (see above), then bring services up (`docker compose up -d`,
   handled by the deploy role).
4. Sanity-check services; re-run `occ files:scan` if media browsing looks stale.

## Verify a backup without restoring

```bash
restic check                  # repo integrity
restic snapshots --latest 1   # confirm the most recent snapshot exists and is recent
```

See also: `docs/06-backup/README.md`, `knowledge/runbooks/backup-monitoring.md`.
