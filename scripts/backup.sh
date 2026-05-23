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
# =============================================================================

set -euo pipefail

BACKUP_LOG="/var/log/homelab-backup.log"
DUMP_DIR="/mnt/data/backups/dumps"
COMPOSE_DIR="/opt/homelab"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$BACKUP_LOG"; }

# Load restic environment
if [ -f /opt/homelab/backup.env ]; then
    set -a
    source /opt/homelab/backup.env
    set +a
else
    log "ERROR: /opt/homelab/backup.env not found"
    exit 1
fi

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