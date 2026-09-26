# Backup

Restic backs up all service data every night, encrypted (AES-256) and deduplicated,
into a local repository and an offsite one (3-2-1). The OS is not backed up: Ansible
rebuilds it.

## At a glance

| Item          | Value                                                                                           |
|---------------|-------------------------------------------------------------------------------------------------|
| Tool          | Restic, driven by `resticprofile` (ADR-031)                                                     |
| Profile       | `ansible/roles/deploy/templates/resticprofile.yaml.j2`                                          |
| Local repo    | `/mnt/data/backups/restic-repo` (same HDD: covers deletion and corruption, not loss of the disk) |
| Offsite repo  | offsite Pi (Pi 4 4GB + 2TB SSD), rest-server **append-only**, over WireGuard (ADR-010)          |
| Passwords     | local and offsite differ; the offsite one is never stored on the offsite host                  |
| Retention     | 7 daily, 4 weekly, 6 monthly                                                                    |
| Monitoring    | Uptime Kuma push monitors ([`backup-monitoring.md`](../../knowledge/runbooks/backup-monitoring.md)) |
| Restore       | [`restore-from-backup.md`](../../knowledge/runbooks/restore-from-backup.md)                    |
| Offsite ops   | [`offsite-backup.md`](../../knowledge/runbooks/offsite-backup.md)                              |
| LUKS header   | [`luks-header-backup.md`](../../knowledge/runbooks/luks-header-backup.md) — needed to reach any of `/mnt/data` |

## What is backed up

Mirrors the profile's `source` list: keep both in sync. All daily.

| Data                   | Source (host path)                                                                        | Method            |
|------------------------|-------------------------------------------------------------------------------------------|-------------------|
| Service data & configs | `/mnt/data/services` (Nextcloud files, Vaultwarden, Immich uploads, Jellyfin/Navidrome config…) | Restic            |
| Media originals        | `/mnt/data/media` (photos, music, home videos, music videos, books)                       | Restic            |
| Stack config           | `/opt/homelab` (compose, scripts)                                                         | Restic            |
| Secrets (ADR-011)      | `/mnt/data/secrets` (`.env`, `backup.env`, `wg0.conf`…; `/opt/homelab` holds symlinks)    | Restic            |
| Nextcloud DB           | MariaDB dump (`--single-transaction`) → `/mnt/data/backups/dumps`                         | dump → Restic     |
| Miniflux DB            | `pg_dump` via `docker exec` (plain SQL) → `/mnt/data/backups/dumps`                       | dump → Restic     |
| SQLite DBs             | Vaultwarden, Forgejo, Uptime Kuma, wg-easy, Sonarr, Radarr, Prowlarr: `sqlite3 .backup` (WAL-safe) → `/mnt/data/backups/dumps` | dump → Restic     |
| Immich DB              | Immich's own scheduled backup → `services/immich/upload/backups/*.sql.gz`                 | built-in → Restic |

**Not backed up:** `/mnt/data/library` (torrent video, re-obtainable, kept until
watched — ADR-035), and the OS.

The deployed spec is the list of dumped databases that cannot drift (one line per
database, ten today):

```bash
sudo grep -oE '^  dump-[a-z0-9-]+-present:' /etc/goss/backup-dumps.yaml \
  | sed 's/^  dump-//; s/-present:$//' | grep -v -- '-container$' | sort -u
```

## How it works

### Schedule

| Timer                             | When           | What                                                                                  |
|-----------------------------------|----------------|---------------------------------------------------------------------------------------|
| `homelab-backup.timer`            | daily 03:00    | dumps → backup → `forget` → offsite copy of every snapshot it lacks (a failed night catches up) |
| `homelab-local-maintenance.timer` | Tuesday 01:00  | `resticprofile -n homelab prune` then metadata `check`; deep read in the first 7 days of the month |
| `homelab-offsite-check.timer`     | Tuesday 02:00  | offsite repo metadata check                                                           |

The monthly deep read uses `--read-data-subset=<month>/12`, so the whole local repo is
re-read over about 12 months. The offsite side also runs a daily health report and a
monthly SMART long test ([`offsite-backup.md`](../../knowledge/runbooks/offsite-backup.md)).

Schedules as actually deployed: `systemctl list-timers 'homelab-*'` on the homelab,
`systemctl list-timers 'offsite-*'` on the offsite host.

### Database dumps

- The dump commands are `run-before` hooks in the profile. The checks are goss
  assertions in `/etc/goss/backup-dumps.yaml`.
- **SQLite:** hooks and assertions are both generated from `backup_sqlite_dumps` in
  group_vars. Add a database there and it is dumped and checked.
- **SQL:** only the assertions come from `backup_sql_dumps`. The Nextcloud and
  Miniflux hooks are written out in the profile, so a new SQL database also needs its
  own `run-before` hook — until then the check fails.
- `backup-notify.sh` builds the Kuma message from goss's TAP file and names the
  failing assertions (resticprofile hooks receive no restic output).

### Retention

`restic forget` runs nightly; the expensive `prune` runs weekly in the maintenance
job, outside the backup window.

**Retention is per path set.** `forget` groups snapshots by `host,paths` (restic's
default). Changing the backup source starts a new group, and the last snapshots of
the old shape stay **forever**. Three such groups exist: before `media/` joined the
source, before `secrets/` joined, and one snapshot of 2026-09-13 03:00, the last
before `library/` left. That one is the only snapshot still holding films and
series; keeping it is deliberate.

Asking for a film exits 0 either way, and neither tells you what happened:

- `restic restore latest --include /mnt/data/library/...` restores **nothing**:
  `latest` is the newest snapshot, which lacks that path.
- `restic restore latest --path /mnt/data/library/movies` restores the
  **2026-09-13 copy**, without mentioning its age.
