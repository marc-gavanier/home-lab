#!/usr/bin/env bash
# =============================================================================
# Home Lab — backup notification (ADR-031)
# =============================================================================
# resticprofile's hooks receive PROFILE_NAME and PROFILE_COMMAND, and nothing
# else — no snapshot id, no sizes, no restic summary. Verified by dumping the
# hook environment, and there is no status file either: `status-file` is not an
# option, and `resticprofile status` reports on SCHEDULES, not on runs.
#
# So the message backup.sh used to build from restic's --json summary cannot be
# reproduced by configuration alone. This is the adapter that keeps the
# notification worth reading.
#
# WHAT IT KEEPS, and what it drops:
#   kept    which snapshot, and whether the dumps passed — the two things that
#           tell you if tonight's backup is usable
#   dropped files new/changed, bytes added, duration. Diagnostic rather than
#           actionable, and still one `restic snapshots` away. If they turn out
#           to be missed, they come back here, not into a bigger script.
#
# Invoked as resticprofile's run-after (success) and run-after-fail (failure).
# The outcome is passed as $1 because a hook cannot tell which one it is.
# =============================================================================

set -uo pipefail

OUTCOME="${1:-up}"                     # up | down
DUMP_STATUS="/run/homelab-backup-dumps.status"
BACKUP_LOG="/var/log/homelab-backup.log"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] notify: $*" | tee -a "$BACKUP_LOG"; }

url="${KUMA_PUSH_URL:-}"
# Strip a pasted example query. Kuma's UI shows the push URL decorated with
# ?status=up&msg=OK&ping=, and appending ours would send each parameter twice —
# Kuma reads the duplicates as arrays and records the beat DOWN with the message
# "[object Object]". Measured, on this stack.
url="${url%%\?*}"
[ -n "$url" ] || { log "no KUMA_PUSH_URL — nothing pushed"; exit 0; }

# The newest snapshot, for traceability. `--latest 1` returns the newest of EACH
# path group, so take the most recent by time rather than the first row.
snapshot=$(restic snapshots --json 2>/dev/null \
  | jq -r 'sort_by(.time) | .[-1].short_id // empty' 2>/dev/null) || snapshot=""

# Problems first, readings after — the shape every other push on this host
# uses, so the first words of a Discord notification are what is wrong.
problems=()

# The caller says whether restic itself failed. A hook cannot tell.
[ "$OUTCOME" = "down" ] && problems+=("backup command failed")

# An ABSENT status file means the dump step did not run at all, which is not the
# same as "no failures" and must not read as success.
if [ ! -f "$DUMP_STATUS" ]; then
    problems+=("dump step did not run")
elif [ -s "$DUMP_STATUS" ]; then
    problems+=("$(cat "$DUMP_STATUS")")
fi

readings="dumps ok${snapshot:+, snapshot ${snapshot}}"
[ ${#problems[@]} -eq 0 ] || readings="${snapshot:+snapshot ${snapshot}}"

if [ ${#problems[@]} -gt 0 ]; then
    OUTCOME="down"
    msg="$(printf '%s; ' "${problems[@]}")"
    msg="${msg%; }${readings:+ | ${readings}} — see ${BACKUP_LOG}"
else
    OUTCOME="up"
    msg="${readings}"
fi

# The URL carries the monitor's token, so it goes in on stdin rather than argv:
# /proc has no hidepid here and this runs unattended (#177). printf is a
# builtin, so the value never reaches an argv there either.
printf 'url = "%s"\n' "$url" |
    curl -fsS -m 10 --retry 2 -K - -G \
        --data-urlencode "status=${OUTCOME}" \
        --data-urlencode "msg=${msg}" >/dev/null 2>&1 || log "push failed"

log "pushed ${OUTCOME}: ${msg}"
