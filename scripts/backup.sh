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
COMPOSE_DIR="/opt/homelab"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$BACKUP_LOG"; }

# Ping the Uptime Kuma push monitor (dead-man's switch). Best-effort: never fails the backup.
notify() {
    [ -n "${KUMA_PUSH_URL:-}" ] || return 0
    curl -fsS -m 10 --retry 2 -G "$KUMA_PUSH_URL" \
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

# Immich PostgreSQL (if running)
if docker ps --format '{{.Names}}' | grep -q immich-db; then
    log "Dumping Immich database..."
    docker exec immich-db pg_dump \
        -U "${IMMICH_DB_USER:-immich}" \
        "${IMMICH_DB_NAME:-immich}" \
        > "$DUMP_DIR/immich.sql" 2>> "$BACKUP_LOG" || log "WARNING: Immich DB dump failed"
fi

# --- Restic backup ---

log "Running restic backup..."
restic backup \
    --verbose \
    --tag auto \
    /mnt/data/services \
    /mnt/data/media \
    /mnt/data/backups/dumps \
    /opt/homelab \
    2>> "$BACKUP_LOG" || { log "ERROR: Restic backup failed"; exit 1; }

# --- Retention ---

log "Applying retention policy..."
restic forget \
    --keep-daily 7 \
    --keep-weekly 4 \
    --keep-monthly 6 \
    --prune \
    2>> "$BACKUP_LOG" || log "WARNING: Restic prune failed"

# --- Cleanup dumps ---
rm -rf "$DUMP_DIR"

log "=== Backup completed ==="