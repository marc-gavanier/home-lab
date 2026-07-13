#!/usr/bin/env bash
# =============================================================================
# Home Lab — Weekly offsite repo integrity check (ADR-010)
# =============================================================================
# Runs from the HOMELAB (which holds the offsite repo password — the offsite
# Pi deliberately does not). Metadata-only check: fast and cheap over the
# WAN. For a deep data check, run manually with --read-data-subset=2%
# (see knowledge/runbooks/offsite-backup.md).
#
# Environment comes from /opt/homelab/backup.env (systemd EnvironmentFile).
# =============================================================================

set -euo pipefail

BACKUP_LOG="/var/log/homelab-backup.log"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$BACKUP_LOG"; }

notify() {
    [ -n "${KUMA_OFFSITE_CHECK_PUSH_URL:-}" ] || return 0
    curl -fsS -m 10 --retry 2 -G "$KUMA_OFFSITE_CHECK_PUSH_URL" \
        --data-urlencode "status=$1" --data-urlencode "msg=$2" >/dev/null 2>&1 || true
}

if [ -z "${OFFSITE_RESTIC_REPOSITORY:-}" ]; then
    log "Offsite repo not configured — skipping check"
    exit 0
fi

log "=== Offsite repo check started ==="

if RESTIC_REPOSITORY="$OFFSITE_RESTIC_REPOSITORY" \
   RESTIC_PASSWORD="$OFFSITE_RESTIC_PASSWORD" \
   RESTIC_REST_USERNAME="$OFFSITE_REST_USER" \
   RESTIC_REST_PASSWORD="$OFFSITE_REST_PASSWORD" \
   restic check 2>> "$BACKUP_LOG"; then
    log "=== Offsite repo check passed ==="
    notify up "offsite check passed"
else
    log "ERROR: offsite repo check FAILED"
    notify down "offsite check FAILED — see $BACKUP_LOG"
    exit 1
fi
