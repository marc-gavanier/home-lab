# Backup

## Tool: Restic

Chosen for its deduplication, native encryption (AES-256), incremental support, and low memory footprint. Perfect for a Raspberry Pi.

## Strategy

### What to Back Up

Mirrors exactly what `scripts/backup.sh` does (keep this table and the script in sync).

| Data                   | Source (host path)                                                                              | Method        | Frequency |
|------------------------|-------------------------------------------------------------------------------------------------|---------------|-----------|
| Service data & configs | `/mnt/data/services` (Nextcloud files, Vaultwarden, Immich uploads, Jellyfin/Navidrome config…) | Restic        | Daily     |
| **Media originals**    | `/mnt/data/media` (photos, music, videos)                                                       | Restic        | Daily     |
| Databases              | Nextcloud (MariaDB) + Immich (PostgreSQL) dumps → `/mnt/data/backups/dumps`                      | dump → Restic | Daily     |
| Stack config           | `/opt/homelab` (compose, `.env`, scripts)                                                        | Restic        | Daily     |

> The OS itself is **not** backed up — it is reproducible from scratch via Ansible (IaC).

### Retention

- **7** daily snapshots
- **4** weekly snapshots
- **6** monthly snapshots

### Destination (3-2-1)

- **Local**: `/mnt/data/backups/restic-repo` (same HDD, separate directory) — automated
  daily; guards against accidental deletion, corruption and bad edits.
- **Offsite** (planned): a second Restic repository on a remote node joined to the home
  WireGuard network (REST server / SFTP), for an automated, always-current copy that
  survives disk failure, theft or fire.

> A backup that shares the originals' physical disk only covers deletion/corruption, not
> physical loss — hence the offsite repository (3-2-1 rule).

## Restoration

Service-by-service restoration procedures will be documented in `knowledge/runbooks/`.

## Automation

- Script: `scripts/backup.sh`
- Scheduling: systemd timer (`homelab-backup.timer`), daily at 03:00
- Monitoring: Uptime Kuma **Push** monitor (dead-man's switch) — `backup.sh` pings it on
  success/failure, and missed pings turn it red (catches "didn't run at all"). Setup:
  `knowledge/runbooks/backup-monitoring.md`
