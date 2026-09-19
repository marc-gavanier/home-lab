#!/usr/bin/env bash
# =============================================================================
# Home Lab — backup notification (ADR-031)
# =============================================================================
# resticprofile's SUCCESS hooks receive PROFILE_NAME and PROFILE_COMMAND, and
# nothing else — no snapshot id, no sizes, no restic summary. Verified by
# dumping the hook environment. `resticprofile status` reports on SCHEDULES,
# not on runs, so it is no help either.
#
# Two claims that used to stand here were WRONG, corrected 2026-09-11, and both
# were load-bearing enough to be worth naming:
#
#   - "`status-file` is not an option" — it is. The installed binary's own
#     schema documents it (`resticprofile generate --json-schema v1`), and the
#     profile now sets it. It carries the result and the DURATION of the last
#     restic command, which is what lets the posture spec assert an OBSERVED
#     deep check instead of a self-reported one.
#   - "a hook sees none of restic's output", which sent the DOWN path to
#     `journalctl`. The binary carries ERROR_STDERR, ERROR_EXIT_CODE,
#     ERROR_COMMANDLINE and RESTICPROFILE_COMMAND_OUTPUT alongside PROFILE_NAME
#     and PROFILE_COMMAND. What is verified is that those names exist in
#     resticprofile 0.33.1; whether they are populated in OUR run-after-fail
#     environment has not been observed, because that needs a real failure. The
#     cost of the old belief is on record: the copy failure of 2026-08-23 14:37
#     pointed the operator at a file holding one line and no cause.
#
# The adapter still earns its place — the rich message backup.sh built from
# restic's --json summary is not reproducible by configuration alone — but it
# is now a choice rather than the only option.
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
#   backup-notify.sh up|down backup        -> backup monitor, with the dump verdict
#   backup-notify.sh up|down copy          -> offsite replication monitor
#   backup-notify.sh up|down maintenance <mode> [subset]
#                                          -> weekly prune + check monitor, where
#                                             <mode> is `deep` or `metadata`
#   backup-notify.sh up|down offsite-check -> weekly offsite integrity monitor
#
# Four monitors and not one, deliberately: they fail for different reasons and on
# different schedules. A weekly integrity check that goes quiet is not the same
# event as a nightly backup that goes quiet, and folding them together would hide
# whichever stopped second.
#
# The outcome is passed as $1 because a hook cannot tell which one it is, and the
# command as $2 because PROFILE_COMMAND is not exported to run-after-fail on
# every path. Passing both explicitly costs one word and removes the guesswork.
# =============================================================================

set -uo pipefail

OUTCOME="${1:-up}"                     # up | down
WHAT="${2:-backup}"                    # backup | copy | maintenance | offsite-check
# The weekly maintenance runs in two modes that do NOT establish the same thing:
# one re-reads a twelfth of the repository's actual bytes, the other lists
# metadata. resticprofile decides which by the day of the month, and only
# resticprofile knows — a hook receives PROFILE_NAME and PROFILE_COMMAND and
# nothing else. So the mode is passed in, from the same template branch that
# sets `read-data-subset` (#290, class C39).
#
# It used to reach the monitor and stopped. The shell job this replaced pushed
# `local prune + deep check (8/12) passed` against `local prune + metadata check
# passed`, and Kuma still holds both — 2026-08-02 and 2026-08-09. The move to
# resticprofile (ADR-031) collapsed them into `prune and check completed`, and
# the only durable trace of which one ran became the journal, which holds 16.8
# days against a period of 30. The evidence expired before the event repeated.
MODE="${3:-}"                          # deep | metadata (maintenance only)
SUBSET="${4:-}"                        # e.g. 8/12, when MODE=deep
DUMP_TAP="/run/homelab-backup-dumps.tap"
BACKUP_LOG="/var/log/homelab-backup.log"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] notify: $*" | tee -a "$BACKUP_LOG"; }

# One monitor per command, as backup.sh already did for the copy: each fails for
# its own reasons (the tunnel, the remote host, a corrupt pack) and on its own
# schedule, so a shared signal would hide one behind the other.
# `unit` is here for the DOWN message only. Where a failure is DIAGNOSED is not
# where it is announced: $BACKUP_LOG receives the log() lines above and nothing
# else, so the message used to send the operator to a file that holds one line
# and no cause — measured on the real copy failure of 2026-08-23 14:37. The
# journal has the restic output; that is where the message now points.
case "$WHAT" in
    copy)          url="${KUMA_OFFSITE_PUSH_URL:-}";       unit="homelab-backup" ;;
    maintenance)   url="${KUMA_LOCAL_MAINT_PUSH_URL:-}";   unit="homelab-local-maintenance" ;;
    offsite-check) url="${KUMA_OFFSITE_CHECK_PUSH_URL:-}"; unit="homelab-offsite-check" ;;
    *)             url="${KUMA_PUSH_URL:-}";               unit="homelab-backup" ;;
esac
# Strip a pasted example query. Kuma's UI shows the push URL decorated with
# ?status=up&msg=OK&ping=, and appending ours would send each parameter twice —
# Kuma reads the duplicates as arrays and records the beat DOWN with the message
# "[object Object]". Measured, on this stack.
url="${url%%\?*}"
# An EMPTY url is a lost report, and it used to be the one lost report nothing
# could see. The script logged one line to $BACKUP_LOG — which no assertion and
# no monitor reads — and exited 0, so a hand-run copy announced nothing and
# claimed success. It fired on 2026-09-13 at 14:41:24: `no push URL for copy —
# nothing pushed`, from the manual block in knowledge/runbooks/offsite-backup.md
# that omitted `. /opt/homelab/backup.env`. The runbook is fixed in the same
# commit; this is the half that makes the NEXT such omission visible instead of
# silent, whatever writes it.
#
# The marker goes to stderr in the exact anchored form
# `no-kuma-report-was-lost-in-silence` greps for — the same channel the two
# failure paths at the bottom of this file already use.
#
# STILL `exit 0`, deliberately: this runs as resticprofile's run-after and
# run-after-fail, and a non-zero hook changes what resticprofile reports about
# the restic command itself. A backup that ran perfectly must not be recorded
# as failed because its notification had nowhere to go. The failure is
# announced, not propagated.
if [ -z "$url" ]; then
    log "no push URL for ${WHAT} — nothing pushed"
    echo "kuma-push-failed: this report reached nobody — ${WHAT}: no push URL was set (is backup.env sourced?)" >&2
    exit 0
fi

# Problems first, readings after — the shape every other push on this host
# uses, so the first words of a Discord notification are what is wrong.
problems=()
readings=""

# The caller says whether the restic command failed. A hook cannot tell.
[ "$OUTCOME" = "down" ] && problems+=("${WHAT} command failed")

if [ "$WHAT" != "backup" ]; then
    # No counts here: a hook sees none of restic's output, and re-deriving them
    # would re-read the repository — or cross the tunnel — for a number that adds
    # nothing, since the monitor going green already means the command ran clean.
    case "$WHAT" in
        copy)          readings="offsite copy completed" ;;
        # Named so a metadata run CANNOT produce the deep run's message, which is
        # the whole acceptance of #290: the distinction has to survive in the
        # monitor's own history. It does — 13 beats back to 2026-07-19 against a
        # 30-day period — because this monitor is weekly, not because of Kuma's
        # 180-day setting: heartbeat rows are pruned against a per-monitor row
        # budget, measured 2026-09-19 at ~36 h for an ordinary beat on the
        # 5-minute monitor. An unset mode is reported as unknown rather than guessed —
        # a message that quietly claims a mode it was not told is the defect
        # again, one level down.
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
    # "copy command failed | offsite copy completed" contradicts itself. A
    # reading only describes a run that finished.
    [ ${#problems[@]} -eq 0 ] || readings=""
else
    # The newest snapshot, for traceability. `--latest 1` returns the newest of
    # EACH path group, so take the most recent by time rather than the first row.
    snapshot=$(restic snapshots --json 2>/dev/null \
      | jq -r 'sort_by(.time) | .[-1].short_id // empty' 2>/dev/null) || snapshot=""

    # goss's own TAP output, written by the backup's run-before (ADR-032). An
    # ABSENT file means the dump step did not run at all, which is not the same
    # as "no failures" and must not read as success.
    #
    # The failing ASSERTION NAMES go into the message rather than a count. goss
    # cannot report the actual value of a command's stdout — it streams it, and
    # every output format says `object: *bytes.Reader` — so the spec puts the
    # failure mode in the name instead, and this is where that pays: the
    # notification reads `dump-vaultwarden-content` rather than
    # `1 dump check(s) failed`, and says which database and which way.
    if [ ! -f "$DUMP_TAP" ]; then
        problems+=("dump step did not run")
    else
        # The plan line is goss's own count, and checking it is not optional
        # here (#261). The hook redirects with `> $DUMP_TAP`, so the shell
        # CREATES the file before exec'ing goss: a missing spec, an unreadable
        # spec or a missing binary all leave a file that exists and holds no
        # `not ok` line. Grepping only for failures reads that as a clean run,
        # and the beat says "dumps ok" on a night nothing was asserted — the
        # exact state backup-dumps.sh used to express as "no dump was taken".
        # Same three-step guard as homelab-posture.sh, homelab-health.sh and
        # offsite-health.sh, for the same reason (#156, #177).
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

    # The count travels with the verdict: "dumps ok" alone cannot distinguish a
    # clean run from a spec that shrank to nothing.
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

# The URL carries the monitor's token, so it goes in on stdin rather than argv:
# /proc has no hidepid here and this runs unattended (#177). printf is a
# builtin, so the value never reaches an argv there either.
# A TIMEOUT IS NOT A LOSS — the reasoning lives once, in homelab-netdata-kuma.sh:
# whether the beat LANDED is decided by the server, while curl only reports
# whether a reply came back inside its own budget. curl exit 28 therefore gets
# `kuma-push-unconfirmed:`, which the live assertion's anchored grep does NOT
# match. `|| rc=$?` keeps the guard the old `|| {` provided, so a failing push
# can never abort the caller.
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
        # The marker, on stderr, unprefixed. `log` cannot carry it: it
        # stamps a timestamp in front, and the assertion that reads this
        # (`no-kuma-report-was-lost-in-silence`) anchors at ^ precisely so
        # that a line merely MENTIONING the marker does not count. This
        # script and the digest were the two push sites of ten that
        # detected the failure and named it something else, so the
        # assertion read eight — the whole backup chain's lost beats were
        # invisible to the check written to catch exactly that.
        echo "kuma-push-failed: this report reached nobody — ${WHAT}: ${msg}" >&2
        ;;
esac

log "pushed ${OUTCOME} (${WHAT}): ${msg}"
