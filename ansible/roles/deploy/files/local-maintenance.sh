#!/usr/bin/env bash
# =============================================================================
# Home Lab — Weekly LOCAL restic repo maintenance (prune + integrity check)
# =============================================================================
# The nightly backup runs `restic forget` (cheap, drops old snapshots) but no
# longer prunes. The expensive work lives here, off the 03:00 backup window:
#
#   - prune: repack and reclaim space referenced by forgotten snapshots.
#   - check --read-data-subset=N/10: forget/prune validate structure and indexes
#     but do NOT read pack data, so HDD bit-rot in the local repo (on the aging
#     5TB) would surface only when a restore fails. The subset rotates by ISO
#     week (1/10 .. 10/10), verifying the whole repo's pack data over ~10 weeks
#     — mirroring the weekly offsite check.
#
# Environment comes from /opt/homelab/backup.env (systemd EnvironmentFile):
# RESTIC_REPOSITORY + RESTIC_PASSWORD point at the LOCAL repo.
# =============================================================================

set -euo pipefail

BACKUP_LOG="/var/log/homelab-backup.log"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$BACKUP_LOG"; }

notify() {
    [ -n "${KUMA_LOCAL_MAINT_PUSH_URL:-}" ] || return 0
    curl -fsS -m 10 --retry 2 -G "$KUMA_LOCAL_MAINT_PUSH_URL" \
        --data-urlencode "status=$1" --data-urlencode "msg=$2" >/dev/null 2>&1 || true
}

# ISO week (10#... forces base-10: weeks 08/09 would otherwise be invalid octal).
week="$(date +%V)"
subset="$(( (10#$week % 10) + 1 ))/10"

log "=== Local repo maintenance started (read-data-subset=$subset) ==="

rc=0
log "Pruning local repo..."
restic prune 2>> "$BACKUP_LOG" || { log "ERROR: prune failed"; rc=1; }

log "Checking local repo (read-data-subset=$subset)..."
restic check --read-data-subset="$subset" 2>> "$BACKUP_LOG" || { log "ERROR: check failed"; rc=1; }

if [ "$rc" -eq 0 ]; then
    log "=== Local repo maintenance passed ==="
    notify up "local prune+check passed ($subset)"
else
    log "ERROR: local repo maintenance FAILED"
    notify down "local prune+check FAILED — see $BACKUP_LOG"
    exit 1
fi
