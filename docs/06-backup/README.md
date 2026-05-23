# Backup

## Tool: Restic

Chosen for its deduplication, native encryption (AES-256), incremental support, and low memory footprint. Perfect for a Raspberry Pi.

## Strategy

### What to Back Up

| Data                  | Source                            | Method                    | Frequency |
|-----------------------|-----------------------------------|---------------------------|-----------|
| System configs        | `/etc/` (selective)               | Restic                    | Daily     |
| Docker Compose + .env | `docker/`                         | Restic                    | Daily     |
| Nextcloud files       | `/mnt/data/services/nextcloud/`   | Restic (maintenance mode) | Daily     |
| Nextcloud DB          | MariaDB dump                      | Restic                    | Daily     |
| Vaultwarden           | `/mnt/data/services/vaultwarden/` | Restic                    | Daily     |
| Immich DB + data      | PostgreSQL dump + files           | Restic                    | Daily     |
| Service configs       | `/mnt/data/services/*/config`     | Restic                    | Daily     |
| Media                 | `/mnt/data/media/`                | Restic                    | Weekly    |

### Retention

- **7** daily snapshots
- **4** weekly snapshots
- **6** monthly snapshots

### Destination

- **Local**: `/mnt/data/backups/` (same HDD, separate directory)
- **Offsite** (future): to be planned — options: encrypted cloud (Backblaze B2), second drive at a relative's

## Restoration

Service-by-service restoration procedures will be documented in `knowledge/runbooks/`.

## Automation

- Script: `scripts/backup.sh`
- Scheduling: systemd timer or cron, daily execution at 3 AM
- Monitoring: failure notification via Uptime Kuma
