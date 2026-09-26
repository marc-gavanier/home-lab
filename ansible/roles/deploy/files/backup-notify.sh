#!/usr/bin/env bash

set -uo pipefail

OUTCOME="${1:-up}"
WHAT="${2:-backup}"
MODE="${3:-}"
SUBSET="${4:-}"
DUMP_TAP="/run/homelab-backup-dumps.tap"
BACKUP_LOG="/var/log/homelab-backup.log"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] notify: $*" | tee -a "$BACKUP_LOG"; }

case "$WHAT" in
    copy)          url="${KUMA_OFFSITE_PUSH_URL:-}";       unit="homelab-backup" ;;
    maintenance)   url="${KUMA_LOCAL_MAINT_PUSH_URL:-}";   unit="homelab-local-maintenance" ;;
    offsite-check) url="${KUMA_OFFSITE_CHECK_PUSH_URL:-}"; unit="homelab-offsite-check" ;;
    *)             url="${KUMA_PUSH_URL:-}";               unit="homelab-backup" ;;
esac
url="${url%%\?*}"
if [ -z "$url" ]; then
    log "no push URL for ${WHAT} — nothing pushed"
    echo "kuma-push-failed: this report reached nobody — ${WHAT}: no push URL was set (is backup.env sourced?)" >&2
    exit 0
fi

problems=()
readings=""

[ "$OUTCOME" = "down" ] && problems+=("${WHAT} command failed")

if [ "$WHAT" != "backup" ]; then
    case "$WHAT" in
        copy)          readings="offsite copy completed" ;;
        maintenance)
            case "$MODE" in
                deep)     readings="prune ok, deep check re-read data subset ${SUBSET:-?}/12" ;;
                metadata) readings="prune ok, metadata check only (no data re-read)" ;;
                *)        readings="prune and check completed, mode not reported" ;;
            esac
            ;;
        offsite-check) readings="offsite repository intact" ;;
        *)             readings="${WHAT} completed" ;;
    esac
    [ ${#problems[@]} -eq 0 ] || readings=""
else
    snapshot=$(restic snapshots --json 2>/dev/null \
      | jq -r 'sort_by(.time) | .[-1].short_id // empty' 2>/dev/null) || snapshot=""

    if [ ! -f "$DUMP_TAP" ]; then
        problems+=("dump step did not run")
    else
        dump_total=$(sed -n 's/^1\.\.\([0-9]*\)$/\1/p' "$DUMP_TAP")
        dump_seen=$(grep -cE '^(not )?ok [0-9]+ ' "$DUMP_TAP") || true
        if [ -z "$dump_total" ] || [ "$dump_total" -eq 0 ]; then
            problems+=("goss asserted nothing about the dumps — spec unreadable, empty, or goss missing")
        elif [ "$dump_seen" -ne "$dump_total" ]; then
            problems+=("goss declared $dump_total dump checks and produced $dump_seen — the run was cut short")
        else
            failed=$(sed -n 's/^not ok [0-9]* - Command: \([^:]*\):.*/\1/p' "$DUMP_TAP" |
                     sort -u | tr '\n' ' ')
            failed="${failed% }"
            [ -n "$failed" ] && problems+=("dump checks failed: $failed")
        fi
    fi

    readings="dumps ok${dump_total:+ (${dump_total} checks)}${snapshot:+, snapshot ${snapshot}}"
    [ ${#problems[@]} -eq 0 ] || readings="${snapshot:+snapshot ${snapshot}}"
fi

if [ ${#problems[@]} -gt 0 ]; then
    OUTCOME="down"
    msg="$(printf '%s; ' "${problems[@]}")"
    msg="${msg%; }${readings:+ | ${readings}} — journalctl -u ${unit} -n 50"
else
    OUTCOME="up"
    msg="${readings}"
fi

rc=0
printf 'url = "%s"\n' "$url" |
    curl -fsS -m 10 --retry 2 -K - -G \
        --data-urlencode "status=${OUTCOME}" \
        --data-urlencode "msg=${msg}" >/dev/null 2>&1 || rc=$?
case "$rc" in
    0) ;;
    28)
        log "push unconfirmed"
        echo "kuma-push-unconfirmed: no reply within 10s, the beat may have landed — ${WHAT}: ${msg}" >&2
        ;;
    *)
        log "push failed"
        echo "kuma-push-failed: this report reached nobody — ${WHAT}: ${msg}" >&2
        ;;
esac

log "pushed ${OUTCOME} (${WHAT}): ${msg}"
