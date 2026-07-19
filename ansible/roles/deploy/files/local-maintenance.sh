#!/usr/bin/env bash
# =============================================================================
# Home Lab — Weekly LOCAL restic repo maintenance (prune + integrity check)
# =============================================================================
# The nightly backup runs `restic forget` (cheap, drops old snapshots) but no
# longer prunes. The maintenance work lives here, off the 03:00 backup window:
#
#   - prune (weekly): repack and reclaim space referenced by forgotten snapshots.
#   - check (weekly, metadata only): validate repo structure and indexes — fast,
#     reads no pack data.
#   - check --read-data-subset (monthly, first Sunday): forget/prune/metadata
#     check never read pack data, so HDD bit-rot in the local repo (on the aging
#     5TB) would surface only when a restore fails. Reading ~10% weekly pegs the
#     Pi for ~1h; instead read a rotating 1/12 of the data once a month (by
#     calendar month), re-verifying the whole repo over a year at a fraction of
#     the cost. The timer is Sunday-only, so day-of-month <= 7 is the 1st Sunday.
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

# 10#... forces base-10 (a leading zero would otherwise be read as octal).
dom="$((10#$(date +%d)))"
month="$((10#$(date +%m)))"

log "=== Local repo maintenance started ==="

rc=0
log "Pruning local repo..."
restic prune 2>> "$BACKUP_LOG" || { log "ERROR: prune failed"; rc=1; }

if [ "$dom" -le 7 ]; then
    # First Sunday of the month: deep read-data check of a rotating 1/12 subset
    # (also covers metadata). Full repo data re-read over ~12 months.
    subset="${month}/12"
    log "Deep-checking local repo (read-data-subset=$subset)..."
    restic check --read-data-subset="$subset" 2>> "$BACKUP_LOG" || { log "ERROR: deep check failed"; rc=1; }
    msg="prune + deep check ($subset)"
else
    log "Checking local repo (metadata only)..."
    restic check 2>> "$BACKUP_LOG" || { log "ERROR: check failed"; rc=1; }
    msg="prune + metadata check"
fi

if [ "$rc" -eq 0 ]; then
    log "=== Local repo maintenance passed ($msg) ==="
    notify up "local $msg passed"
else
    log "ERROR: local repo maintenance FAILED"
    notify down "local maintenance FAILED — see $BACKUP_LOG"
    exit 1
fi
