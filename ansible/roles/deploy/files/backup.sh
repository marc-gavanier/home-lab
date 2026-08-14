#!/usr/bin/env bash
# =============================================================================
# Home Lab — Restic Backup Script
# =============================================================================
# Runs daily via systemd timer. Backs up service data and database dumps.
#
# Usage:
#   sudo /opt/homelab/scripts/backup.sh
#
# Environment variables (set in /opt/homelab/backup.env):
#   RESTIC_REPOSITORY  — path to restic repo
#   RESTIC_PASSWORD    — repo encryption password
#   KUMA_PUSH_URL      — Uptime Kuma push monitor URL (optional; empty = no monitoring)
# =============================================================================

set -euo pipefail

BACKUP_LOG="/var/log/homelab-backup.log"
DUMP_DIR="/mnt/data/backups/dumps"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$BACKUP_LOG"; }

# Ping the Uptime Kuma push monitor (dead-man's switch). Best-effort: never fails the backup.
notify() {
    local url="${KUMA_PUSH_URL:-}"
    [ -n "$url" ] || return 0
    url="${url%%\?*}"   # strip any pasted ?status=...&msg=... query (dup params read as DOWN)
    curl -fsS -m 10 --retry 2 -G "$url" \
        --data-urlencode "status=$1" --data-urlencode "msg=$2" >/dev/null 2>&1 || true
}

# Report the final outcome to the monitor on any exit (success or failure).
finish() {
    local rc=$?
    if [ "$rc" -eq 0 ]; then
        notify up "completed"
    else
        notify down "FAILED (rc=$rc) — see $BACKUP_LOG"
    fi
}

# Load restic environment
if [ -f /opt/homelab/backup.env ]; then
    set -a
    source /opt/homelab/backup.env
    set +a
else
    log "ERROR: /opt/homelab/backup.env not found"
    exit 1
fi

# From here on, report the outcome to the Uptime Kuma push monitor on exit.
trap finish EXIT

log "=== Backup started ==="

# --- Create dump directory ---
mkdir -p "$DUMP_DIR"

# --- Database dumps ---

# Nextcloud MariaDB
log "Dumping Nextcloud database..."
docker exec nextcloud-db mariadb-dump \
    --single-transaction \
    --routines \
    --triggers \
    -u"${NEXTCLOUD_DB_USER:-nextcloud}" \
    -p"${NEXTCLOUD_DB_PASSWORD}" \
    "${NEXTCLOUD_DB_NAME:-nextcloud}" \
    > "$DUMP_DIR/nextcloud.sql" 2>> "$BACKUP_LOG" || log "WARNING: Nextcloud DB dump failed"

# Immich PostgreSQL — handled by Immich's OWN scheduled DB backup, not here.
# A hand-rolled `pg_dump` is fragile on this DB (VectorChord + pgvecto.rs need a
# search_path transform on restore). Immich's built-in backup (Admin → Settings
# → Backup) writes a correctly-formatted dump.sql.gz to UPLOAD_LOCATION/backups
# = /mnt/data/services/immich/upload/backups, already inside the restic set
# below. Restore per knowledge/runbooks/restore-from-backup.md ("Restore Immich").

# Vaultwarden SQLite — consistent online backup (WAL-safe).
# Restic snapshotting the live db.sqlite3 while Vaultwarden runs can capture a
# torn WAL state. sqlite3 .backup uses SQLite's Online Backup API to write a
# consistent copy even under concurrent writes (run host-side: the Vaultwarden
# image ships no sqlite3 CLI). See Vaultwarden wiki "Backing up your vault".
VAULTWARDEN_DB="/mnt/data/services/vaultwarden/db.sqlite3"
if [ -f "$VAULTWARDEN_DB" ]; then
    log "Backing up Vaultwarden database (sqlite3 .backup)..."
    sqlite3 "$VAULTWARDEN_DB" ".backup '$DUMP_DIR/vaultwarden.sqlite3'" 2>> "$BACKUP_LOG" \
        || log "WARNING: Vaultwarden DB backup failed"
fi

# Forgejo SQLite — same reasoning, and it matters more here than it looks.
# The point of this service is to be the copy that survives losing GitHub, so a
# backup of it that restores to a torn WAL would defeat the whole exercise. The
# git object stores under /var/lib/gitea are plain files restic handles fine; it
# is only the database (users, mirror settings, issues) that needs the Online
# Backup API. Runs host-side because the rootless image ships no sqlite3 CLI.
# The doubled segment below is not a typo: the host directory forgejo/data is
# mounted at /var/lib/gitea, and Forgejo keeps its own APP_DATA_PATH one level
# under that (/var/lib/gitea/data), so the database lands in forgejo/data/data/.
FORGEJO_DB="/mnt/data/services/forgejo/data/data/forgejo.db"
if [ -f "$FORGEJO_DB" ]; then
    log "Backing up Forgejo database (sqlite3 .backup)..."
    sqlite3 "$FORGEJO_DB" ".backup '$DUMP_DIR/forgejo.sqlite3'" 2>> "$BACKUP_LOG" \
        || log "WARNING: Forgejo DB backup failed"
fi

# --- Restic backup ---

log "Running restic backup..."
# /mnt/data/secrets holds the credential files (.env, backup.env, wg0.conf…)
# whose /opt/homelab entries are now symlinks — restic stores symlinks as
# links, so the real directory must be listed for DR to restore the secrets.
# The excluded directory is LibreSign's binary cache — a JRE, JSignPdf and
# pdftk, 185 MB measured, downloaded from GitHub by `occ libresign:install` and
# re-downloadable with it (ADR-022). Backing them up would send a copy offsite
# over the parents' uplink for something a single command rebuilds.
# Scoped to the architecture directory on purpose: the root CA, including
# ca-key.pem, sits in a sibling directory under libresign/ and MUST stay in the
# backup — losing it invalidates every signature ever issued here.
restic backup \
    --verbose \
    --tag auto \
    --exclude '/mnt/data/services/nextcloud/data/data/appdata_*/libresign/aarch64' \
    /mnt/data/services \
    /mnt/data/media \
    /mnt/data/backups/dumps \
    /mnt/data/secrets \
    /opt/homelab \
    2>> "$BACKUP_LOG" || { log "ERROR: Restic backup failed"; exit 1; }

# --- Offsite replication (restic copy over WireGuard, ADR-010) ---
# Runs BEFORE local retention so the snapshot just taken is always copied.
# An offsite failure (link down, parents' outage) never fails the local
# backup — it only trips the dedicated Kuma monitor.

notify_offsite() {
    local url="${KUMA_OFFSITE_PUSH_URL:-}"
    [ -n "$url" ] || return 0
    url="${url%%\?*}"   # strip any pasted ?status=...&msg=... query (dup params read as DOWN)
    curl -fsS -m 10 --retry 2 -G "$url" \
        --data-urlencode "status=$1" --data-urlencode "msg=$2" >/dev/null 2>&1 || true
}

# flock: two concurrent copies to the append-only repo re-upload each other's
# packs as permanent duplicates (only a manual prune reclaims them — learned
# the hard way during the 2026-07-12 seed). Same lock file must be used by
# any manual copy/seed: flock /var/lock/offsite-copy.lock restic copy ...
if [ -n "${OFFSITE_RESTIC_REPOSITORY:-}" ]; then
    log "Copying latest snapshot to offsite repo..."
    if flock -n /var/lock/offsite-copy.lock \
       env RESTIC_FROM_REPOSITORY="$RESTIC_REPOSITORY" \
       RESTIC_FROM_PASSWORD="$RESTIC_PASSWORD" \
       RESTIC_REPOSITORY="$OFFSITE_RESTIC_REPOSITORY" \
       RESTIC_PASSWORD="$OFFSITE_RESTIC_PASSWORD" \
       RESTIC_REST_USERNAME="$OFFSITE_REST_USER" \
       RESTIC_REST_PASSWORD="$OFFSITE_REST_PASSWORD" \
       restic copy latest 2>> "$BACKUP_LOG"; then
        log "Offsite copy completed"
        notify_offsite up "offsite copy completed"
    else
        log "WARNING: offsite copy failed (local backup unaffected)"
        notify_offsite down "offsite copy FAILED — see $BACKUP_LOG"
    fi
fi

# --- Retention ---
# Nightly: forget only (cheap — updates the snapshot list). The expensive prune
# (repack) + a rotating read-data integrity check run weekly in
# local-maintenance.sh, off the backup window. See homelab-local-maintenance.timer.

log "Applying retention policy..."
restic forget \
    --keep-daily 7 \
    --keep-weekly 4 \
    --keep-monthly 6 \
    2>> "$BACKUP_LOG" || log "WARNING: Restic forget failed"

# --- Cleanup dumps ---
rm -rf "$DUMP_DIR"

log "=== Backup completed ==="
