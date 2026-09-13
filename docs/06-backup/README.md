# Backup

## Tool: Restic

Chosen for its deduplication, native encryption (AES-256), incremental support, and low memory footprint. Perfect for a Raspberry Pi.

## Strategy

### What to Back Up

Mirrors the `source` list in `ansible/roles/deploy/templates/resticprofile.yaml.j2` (keep this table and that profile in sync).

| Data                   | Source (host path)                                                                                                                        | Method            | Frequency |
|------------------------|-------------------------------------------------------------------------------------------------------------------------------------------|-------------------|-----------|
| Service data & configs | `/mnt/data/services` (Nextcloud files, Vaultwarden, Immich uploads, Jellyfin/Navidrome config…)                                           | Restic            | Daily     |
| **Media originals**    | `/mnt/data/media` (photos, music, home videos, music videos, books)                                                                       | Restic            | Daily     |
| **Library**            | `/mnt/data/library` — **not backed up** since 2026-09-13, deliberately: torrent video, re-obtainable, kept until watched (ADR-035)        | —                 | Never     |
| Nextcloud DB           | MariaDB dump (`--single-transaction`) → `/mnt/data/backups/dumps`                                                                         | dump → Restic     | Daily     |
| Vaultwarden DB         | SQLite `sqlite3 .backup` (WAL-safe) → `/mnt/data/backups/dumps`                                                                           | dump → Restic     | Daily     |
| Forgejo DB             | SQLite `sqlite3 .backup` (WAL-safe) → `/mnt/data/backups/dumps`                                                                           | dump → Restic     | Daily     |
| Uptime Kuma DB         | SQLite `sqlite3 .backup` (WAL-safe) → `/mnt/data/backups/dumps`                                                                           | dump → Restic     | Daily     |
| wg-easy DB             | SQLite `sqlite3 .backup` (WAL-safe) → `/mnt/data/backups/dumps`                                                                           | dump → Restic     | Daily     |
| Sonarr DB              | SQLite `sqlite3 .backup` (WAL-safe) → `/mnt/data/backups/dumps`                                                                           | dump → Restic     | Daily     |
| Radarr DB              | SQLite `sqlite3 .backup` (WAL-safe) → `/mnt/data/backups/dumps`                                                                           | dump → Restic     | Daily     |
| Prowlarr DB            | SQLite `sqlite3 .backup` (WAL-safe) → `/mnt/data/backups/dumps`                                                                           | dump → Restic     | Daily     |
| Miniflux DB            | `pg_dump` via `docker exec` (plain SQL) → `/mnt/data/backups/dumps`                                                                       | dump → Restic     | Daily     |
| Immich DB              | Immich's own scheduled backup → `services/immich/upload/backups/*.sql.gz`                                                                 | built-in → Restic | Daily     |
| Stack config           | `/opt/homelab` (compose, scripts)                                                                                                         | Restic            | Daily     |
| Secrets (ADR-011)      | `/mnt/data/secrets` (`.env`, `backup.env`, `wg0.conf`… — `/opt/homelab` entries are symlinks)                                             | Restic            | Daily     |

> The OS itself is **not** backed up — it is reproducible from scratch via Ansible (IaC).

### Retention

- **7** daily snapshots
- **4** weekly snapshots
- **6** monthly snapshots

`restic forget` runs nightly (cheap); the expensive `prune` (repack/reclaim) runs
weekly in the local maintenance job, not in the backup window.

> **Retention is per path-set, and changing the source strands a group.**
> `forget` groups snapshots by `host,paths` (restic's default — nothing here
> overrides it). A snapshot whose source list differs from today's therefore
> forms its own group, receives no new members, and its keep-daily slots never
> age out. Changing the backup source leaves the last snapshot of the old shape
> behind **permanently**.
>
> There is one such snapshot today, taken 2026-09-13 03:00, the last before
> `library/` left the source. It is the only snapshot in the repository that
> still holds films and series, and it will stay. The consequence worth knowing
> is not the disk it occupies but that **both ways of asking for a film exit 0
> and neither tells you what happened**:
>
> - `restic restore latest --include /mnt/data/library/...` resolves `latest` to
>   the newest snapshot overall, which no longer carries that path — so it
>   restores **nothing**, silently.
> - `restic restore latest --path /mnt/data/library/movies` resolves `latest`
>   within the snapshots holding that path — so it restores the **2026-09-13
>   copy**, however long ago that becomes, and says nothing about its age.
>
> Leaving the snapshot is a deliberate choice (2026-09-13): the data is
> re-obtainable and reclaiming the space was declined.

### Destination (3-2-1)

- **Local**: `/mnt/data/backups/restic-repo` (same HDD, separate directory) — automated
  daily; guards against accidental deletion, corruption and bad edits. Weekly `prune`
  + metadata `restic check`, plus a **monthly** deep read (rotating
  `--read-data-subset=<month>/12`, whole repo re-read over ~12 months) to catch local
  bit-rot without pegging the Pi every week.
- **Offsite** (ADR-010): second Restic repo on the offsite Pi (Pi 4 4GB + 2TB SSD,
  WireGuard client, rest-server **append-only**), fed nightly with every snapshot it
  does not already hold, with no time bound — so a failed night is recovered by the
  next run whenever that happens (#158, and the 7-day window removed by ADR-031:
  `restic copy` is idempotent, so the bound was an optimisation, not a guarantee). Distinct repo password, never stored on the offsite host. Weekly
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
  dump COMMANDS are `run-before` hooks in that profile and the assertions that
  check them are `/etc/goss/backup-dumps.yaml`, both generated from
  `backup_sql_dumps` and `backup_sqlite_dumps` in group_vars — so a database
  added there gets dumped AND checked, and cannot get one without the other.
  This replaced a 373-line script (ADR-031 kept it saying "resticprofile has no
  equivalent"; ADR-032 installed goss, which has). `backup-notify.sh` remains
  and builds the Kuma message, because resticprofile's hooks receive no restic
  output at all — it now reads goss's TAP file and names the failing
  assertions.
- Weekly: `resticprofile -n homelab prune` then `check`
- Scheduling (systemd timers):
  - `homelab-backup.timer` — daily 03:00 (dumps → backup → offsite copy → forget)
  - `homelab-local-maintenance.timer` — Tuesday 01:00 (weekly prune + metadata check; deep read-data on the run that falls in the first 7 days of the month)
  - `homelab-offsite-check.timer` — Tuesday 02:00 (offsite repo check)
- Monitoring: Uptime Kuma **Push** monitors (dead-man's switches) — the scripts ping on
  success/failure, and missed pings turn a monitor red (catches "didn't run at all"). Setup:
  `knowledge/runbooks/backup-monitoring.md`
