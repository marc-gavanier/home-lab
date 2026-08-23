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
# Invoked as resticprofile's run-after (success) and run-after-fail (failure),
# for BOTH commands the nightly job runs:
#
#   backup-notify.sh up|down backup   -> the backup monitor, with the dump verdict
#   backup-notify.sh up|down copy     -> the offsite monitor
#
# The outcome is passed as $1 because a hook cannot tell which one it is, and the
# command as $2 because PROFILE_COMMAND is not exported to run-after-fail on
# every path. Passing both explicitly costs one word and removes the guesswork.
# =============================================================================

set -uo pipefail

OUTCOME="${1:-up}"                     # up | down
WHAT="${2:-backup}"                    # backup | copy
DUMP_STATUS="/run/homelab-backup-dumps.status"
BACKUP_LOG="/var/log/homelab-backup.log"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] notify: $*" | tee -a "$BACKUP_LOG"; }

# The offsite copy has its own monitor, as it did in backup.sh: it fails for
# entirely different reasons (the tunnel, the remote host) and on its own
# schedule, so folding it into the backup signal would hide one behind the other.
if [ "$WHAT" = "copy" ]; then
    url="${KUMA_OFFSITE_PUSH_URL:-}"
else
    url="${KUMA_PUSH_URL:-}"
fi
# Strip a pasted example query. Kuma's UI shows the push URL decorated with
# ?status=up&msg=OK&ping=, and appending ours would send each parameter twice —
# Kuma reads the duplicates as arrays and records the beat DOWN with the message
# "[object Object]". Measured, on this stack.
url="${url%%\?*}"
[ -n "$url" ] || { log "no push URL for ${WHAT} — nothing pushed"; exit 0; }

# Problems first, readings after — the shape every other push on this host
# uses, so the first words of a Discord notification are what is wrong.
problems=()
readings=""

# The caller says whether the restic command failed. A hook cannot tell.
[ "$OUTCOME" = "down" ] && problems+=("${WHAT} command failed")

if [ "$WHAT" = "copy" ]; then
    # No snapshot count here: a hook sees none of restic's output, and querying
    # the offsite repository would cross the tunnel for a number that adds
    # nothing — the monitor going green already means the copy ran clean.
    readings="offsite copy completed"
    # "copy command failed | offsite copy completed" contradicts itself. A
    # reading only describes a run that finished.
    [ ${#problems[@]} -eq 0 ] || readings=""
else
    # The newest snapshot, for traceability. `--latest 1` returns the newest of
    # EACH path group, so take the most recent by time rather than the first row.
    snapshot=$(restic snapshots --json 2>/dev/null \
      | jq -r 'sort_by(.time) | .[-1].short_id // empty' 2>/dev/null) || snapshot=""

    # An ABSENT status file means the dump step did not run at all, which is not
    # the same as "no failures" and must not read as success.
    if [ ! -f "$DUMP_STATUS" ]; then
        problems+=("dump step did not run")
    elif [ -s "$DUMP_STATUS" ]; then
        problems+=("$(cat "$DUMP_STATUS")")
    fi

    readings="dumps ok${snapshot:+, snapshot ${snapshot}}"
    [ ${#problems[@]} -eq 0 ] || readings="${snapshot:+snapshot ${snapshot}}"
fi

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

log "pushed ${OUTCOME} (${WHAT}): ${msg}"
