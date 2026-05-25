# Runbook — Restore from backup (Restic)

Backups are made by `scripts/backup.sh` (daily `homelab-backup.timer`) into the Restic repo
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

# Immich (PostgreSQL)
docker exec -i immich-db psql -U immich immich \
  < /tmp/restore/mnt/data/backups/dumps/immich.sql
```

## Full disaster recovery

1. **Re-provision the OS** with Ansible (the OS isn't backed up — it's reproducible): flash
   Ubuntu, then `ansible-playbook playbooks/site.yml`. The LUKS disk is passphrase-based and
   hardware-independent.
2. **Point Restic at the repo** (local on `/mnt/data`, or the offsite repo) and restore data:
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
