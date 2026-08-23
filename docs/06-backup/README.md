# Backup

## Tool: Restic

Chosen for its deduplication, native encryption (AES-256), incremental support, and low memory footprint. Perfect for a Raspberry Pi.

## Strategy

### What to Back Up

Mirrors the `source` list in `ansible/roles/deploy/templates/resticprofile.yaml.j2` (keep this table and that profile in sync).

| Data                   | Source (host path)                                                                              | Method            | Frequency |
|------------------------|-------------------------------------------------------------------------------------------------|-------------------|-----------|
| Service data & configs | `/mnt/data/services` (Nextcloud files, Vaultwarden, Immich uploads, Jellyfin/Navidrome config…) | Restic            | Daily     |
| **Media originals**    | `/mnt/data/media` (photos, music, videos)                                                       | Restic            | Daily     |
| Nextcloud DB           | MariaDB dump (`--single-transaction`) → `/mnt/data/backups/dumps`                               | dump → Restic     | Daily     |
| Vaultwarden DB         | SQLite `sqlite3 .backup` (WAL-safe) → `/mnt/data/backups/dumps`                                 | dump → Restic     | Daily     |
| Forgejo DB             | SQLite `sqlite3 .backup` (WAL-safe) → `/mnt/data/backups/dumps`                                 | dump → Restic     | Daily     |
| Uptime Kuma DB         | SQLite `sqlite3 .backup` (WAL-safe) → `/mnt/data/backups/dumps`                                 | dump → Restic     | Daily     |
| Miniflux DB            | `pg_dump` via `docker exec` (plain SQL) → `/mnt/data/backups/dumps`                             | dump → Restic     | Daily     |
| Immich DB              | Immich's own scheduled backup → `services/immich/upload/backups/*.sql.gz`                       | built-in → Restic | Daily     |
| Stack config           | `/opt/homelab` (compose, scripts)                                                               | Restic            | Daily     |
| Secrets (ADR-011)      | `/mnt/data/secrets` (`.env`, `backup.env`, `wg0.conf`… — `/opt/homelab` entries are symlinks)   | Restic            | Daily     |

> The OS itself is **not** backed up — it is reproducible from scratch via Ansible (IaC).

### Retention

- **7** daily snapshots
- **4** weekly snapshots
- **6** monthly snapshots

`restic forget` runs nightly (cheap); the expensive `prune` (repack/reclaim) runs
weekly in the local maintenance job, not in the backup window.

### Destination (3-2-1)

- **Local**: `/mnt/data/backups/restic-repo` (same HDD, separate directory) — automated
  daily; guards against accidental deletion, corruption and bad edits. Weekly `prune`
  + metadata `restic check`, plus a **monthly** deep read (rotating
  `--read-data-subset=<month>/12`, whole repo re-read over ~12 months) to catch local
  bit-rot without pegging the Pi every week.
- **Offsite** (ADR-010): second Restic repo on the offsite Pi (Pi 4 4GB + 2TB SSD,
  WireGuard client, rest-server **append-only**), fed nightly with every snapshot from
  the last 7 days it does not already hold — a retry window rather than the latest
  snapshot alone, so a failed night is recovered by the next one (#158). Distinct repo password, never stored on the offsite host. Weekly
  `restic check` from the homelab + weekly disk/SMART/power self-report and a
  monthly SMART long self-test. Runbook: `knowledge/runbooks/offsite-backup.md`.

> A backup that shares the originals' physical disk only covers deletion/corruption, not
> physical loss — hence the offsite repository (3-2-1 rule).

## Restoration

Procedures are in `knowledge/runbooks/restore-from-backup.md` (single files, services,
Nextcloud/Vaultwarden/Immich/Miniflux/Forgejo/Uptime Kuma databases, full disaster
recovery). The
LUKS header — the prerequisite for reaching *any* of `/mnt/data` — has its own backstop:
`knowledge/runbooks/luks-header-backup.md`.

## Automation

- Orchestration: `resticprofile`, configured by
  `ansible/roles/deploy/templates/resticprofile.yaml.j2` (ADR-031). The database
  dumps and the assertions that check them are NOT in it and are not meant to
  be: they live in `backup-dumps.sh`, invoked as a pre-backup hook, because no
  tool expresses them. `backup-notify.sh` builds the Kuma message, because
  resticprofile's hooks receive no restic output at all.
- Weekly: `resticprofile -n homelab prune` then `check`
- Scheduling (systemd timers):
  - `homelab-backup.timer` — daily 03:00 (dumps → backup → offsite copy → forget)
  - `homelab-local-maintenance.timer` — Sunday 05:00 (weekly prune + metadata check; deep read-data on the 1st Sunday of the month)
  - `homelab-offsite-check.timer` — Sunday 06:00 (offsite repo check)
- Monitoring: Uptime Kuma **Push** monitors (dead-man's switches) — the scripts ping on
  success/failure, and missed pings turn a monitor red (catches "didn't run at all"). Setup:
  `knowledge/runbooks/backup-monitoring.md`
