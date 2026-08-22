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

# What this run actually did. Filled in from restic's own summary below and read
# by the EXIT trap. The push used to be the constant "completed", so a night that
# added nothing was indistinguishable from a normal one — on the dashboard and in
# the log alike, since neither carried a restic summary (#127). Empty here means
# restic produced no summary, and the push says so rather than glossing over it.
backup_summary=""
backup_snapshot=""

# Failures that must not abort the run but must not be reported as a clean night
# either. Appended to as they happen, read by the EXIT trap and by the deferred
# verdict at the end. Declared here, before `trap finish EXIT`, so the trap can
# always expand it — including on a run that dies before reaching the stages
# that fill it.
deferred_problems=()

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$BACKUP_LOG"; }

# Ping the Uptime Kuma push monitor (dead-man's switch). Best-effort: never fails the backup.
notify() {
    local url="${KUMA_PUSH_URL:-}"
    [ -n "$url" ] || return 0
    url="${url%%\?*}"   # strip any pasted ?status=...&msg=... query (dup params read as DOWN)
    # The push URL carries the monitor's own token, so it goes in on stdin
    # instead of argv: /proc is mounted without hidepid, any local account can
    # read another process's command line, and this runs unattended on a timer
    # (#177). printf is a shell builtin, so the value never reaches an argv there
    # either.
    printf 'url = "%s"\n' "$url" |
        curl -fsS -m 10 --retry 2 -K - -G \
            --data-urlencode "status=$1" --data-urlencode "msg=$2" >/dev/null 2>&1 || true
}

# Report the final outcome to the monitor on any exit (success or failure).
#
# The middle branch is the point of #168: a deferred failure knows what it was,
# and the push should carry it. Without it, a stage that is deliberately allowed
# to continue reports as "FAILED (rc=1)" — true, and useless for deciding
# whether the night needs attention now or in the morning. An abort (crash, OOM,
# a stage that exits on the spot) leaves the list empty and still gets the
# generic message, which is the right answer when nothing had a chance to say
# anything.
finish() {
    local rc=$?
    if [ "$rc" -eq 0 ]; then
        notify up "${backup_summary:-completed, but restic reported no summary}"
    elif [ ${#deferred_problems[@]} -gt 0 ]; then
        notify down "$(printf '%s; ' "${deferred_problems[@]}")see $BACKUP_LOG"
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
# Emptied first, and that is not housekeeping. A `sqlite3 .backup` that fails
# does NOT touch its destination — measured: 12288 bytes, 2 tables, quick_check
# ok, byte-for-byte unchanged after a failed run. So a dump left behind by an
# earlier run passes every assertion below while being a day old, and gets
# snapshotted as if it were fresh. The window is narrow (a run that FAILS its
# assertions still reaches the cleanup at the bottom, because that `rm -rf` is
# before the `exit 1`) but it is real: it needs a run that ABORTED — crash, OOM,
# a reboot inside the window — and the log shows 103 "started" against 102
# "completed", the orphan being 2026-07-12.
#
# The two .sql dumps are already safe: `>` truncates at open, so a failed dump
# loses its completion marker and is caught. The three SQLite ones were not.
rm -rf "$DUMP_DIR"
mkdir -p "$DUMP_DIR"

# --- Database dumps ---

# Nextcloud MariaDB
log "Dumping Nextcloud database..."
# The password is read from the secret already mounted in the container, and
# handed to mariadb-dump through MYSQL_PWD — never through `-p"…"`, which put it
# in the argv of the `docker` client on the host for the 6 to 9 seconds this dump
# takes, every night at a fixed and known hour (#198). /proc carries no hidepid
# here, so any local account could read it; measured over five nights.
#
# `sh -c` with single quotes is what keeps the expansion inside the container:
# expanded on the host, the path does not exist and the dump would run with an
# empty password against a server that refuses it — loudly, at least.
docker exec nextcloud-db sh -c '
    MYSQL_PWD=$(cat /run/secrets/nextcloud_db_password) \
    mariadb-dump \
        --single-transaction \
        --routines \
        --triggers \
        -u"${MYSQL_USER:-nextcloud}" \
        "${MYSQL_DATABASE:-nextcloud}"
' > "$DUMP_DIR/nextcloud.sql" 2>> "$BACKUP_LOG" || log "WARNING: Nextcloud DB dump failed"

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

# Uptime Kuma SQLite — the monitoring definition has no other copy.
# Kuma v2 dropped the built-in Settings > Backup export and the v1 automation
# tooling does not speak v2 (ops/kuma-dump.sh exists for exactly that reason),
# so every monitor here was entered by hand in the web UI and kuma.db is the
# only place they live. Restoring it torn means rebuilding the supervision from
# memory, right after the incident that made you restore in the first place.
# This database is under constant write pressure — a heartbeat row per monitor
# per interval — so unlike the two above it can genuinely collide with the
# copy. `.backup` returns SQLITE_BUSY on a locked source, and the failure is
# only a WARNING in this log: give it a busy timeout rather than discover the
# missing dump on restore day.
# The copy carries the full history (~41k heartbeats, ~9 MB) and not just the
# configuration. Kept whole on purpose: it restores with a single cp, exactly
# like Vaultwarden and Forgejo, and the alternative saves megabytes on a link
# that already moves far more every night.
KUMA_DB="/mnt/data/services/uptime-kuma/kuma.db"
if [ -f "$KUMA_DB" ]; then
    log "Backing up Uptime Kuma database (sqlite3 .backup)..."
    sqlite3 -cmd ".timeout 5000" "$KUMA_DB" ".backup '$DUMP_DIR/uptime-kuma.sqlite3'" 2>> "$BACKUP_LOG" \
        || log "WARNING: Uptime Kuma DB backup failed"
fi

# Miniflux PostgreSQL — the datadir being inside the restic set is not enough.
# services/miniflux/db is backed up below, but restic walks it file by file
# while Postgres writes: the copy is not atomic and can restore to a torn
# cluster. Every other database here already answers that (mariadb-dump,
# sqlite3 .backup, Immich's own backup); this one was the exception.
# Plain SQL rather than a .gz on purpose: restic chunks and deduplicates a text
# dump from one day to the next, while a compressed one changes end to end on
# any edit and crosses the offsite link whole every night.
# No password: the image entrypoint writes `local all all trust` into pg_hba,
# and `docker exec` connects over the unix socket, not TCP.
log "Dumping Miniflux database..."
docker exec miniflux-db pg_dump \
    -U "${MINIFLUX_DB_USER:-miniflux}" \
    "${MINIFLUX_DB_NAME:-miniflux}" \
    > "$DUMP_DIR/miniflux.sql" 2>> "$BACKUP_LOG" || log "WARNING: Miniflux DB dump failed"

# --- Dump assertions ---
# Every dump above degrades to `|| log WARNING` and leaves the exit code
# untouched, so a failure sails straight past: restic snapshots whatever is in
# DUMP_DIR, the run pushes `up "completed"`, and the cleanup at the bottom of
# this script deletes the evidence. Three months of logs show zero occurrences
# — this is a design gap, not an incident, and it costs ten lines to close.
#
# The point is to catch the file that is ABSENT and the one that is TRUNCATED —
# a redirected dump whose command died mid-write leaves a short file behind, and
# that is precisely what restores into a broken database.
#
# This used to be a byte floor of 10240 for all five. Measured against the real
# run of 2026-08-16, that floor was 0.037 % of miniflux.sql and 0.85 % of
# vaultwarden.sqlite3: a dump cut to one percent of itself passed a check whose
# own message said "truncated?" (#127). Raising the number was never the answer
# — modelling expected growth buys nothing and breaks on a quiet day, which is
# why the floor was crude in the first place.
#
# So assert the CONTENT instead. It does not drift as the data grows, and it
# catches a dump truncated at any size, which is the actual failure mode:
#   - the two SQL dumps each end with their tool's completion marker, written
#     last, so its absence is exactly what "died mid-write" looks like;
#   - the three SQLite copies answer `pragma quick_check`.
#
# Read the TAIL rather than the last line: pg_dump 18 writes a `\unrestrict`
# line AFTER its completion marker, so a last-line test would fail on a dump
# that is perfectly fine.
#
# Checked BEFORE the restic run, so what gets asserted is what gets snapshotted.
# The verdict is deferred to the end: a missing dump must not cost us the
# backup of everything else. The snapshot is taken, and then the run reports
# DOWN so the operator finds out the same night.
assert_dump() { # $1=filename  $2=sqlite|marker  $3=marker text when $2=marker
    local f="$DUMP_DIR/$1" kind="$2" marker="${3:-}" size verdict tables
    if [ ! -f "$f" ]; then
        log "ERROR: expected dump $1 is missing"
        return 1
    fi
    size=$(stat -c %s "$f")
    case "$kind" in
        marker)
            if tail -c 4096 "$f" | grep -qF -- "$marker"; then
                log "dump $1 ok ($size bytes, completion marker present)"
            else
                log "ERROR: dump $1 has no completion marker — truncated ($size bytes)"
                return 1
            fi
            ;;
        sqlite)
            # head -1: quick_check prints "ok" alone, or one line per problem.
            verdict=$(sqlite3 -cmd ".timeout 5000" "$f" 'pragma quick_check;' 2>&1 | head -1) \
                || verdict="sqlite3 could not read the file"
            if [ "$verdict" != "ok" ]; then
                log "ERROR: dump $1 failed quick_check: ${verdict:-<no output>} ($size bytes)"
                return 1
            fi
            # quick_check alone is NOT enough, and measurement is the only reason
            # we know it: a ZERO-BYTE file passes it. SQLite reads an empty file
            # as a valid empty database, and an empty file is exactly what a
            # `.backup` that failed at the first step leaves behind — the one
            # case the old byte floor did catch. So assert the database has
            # content too, which also rejects a structurally perfect but empty
            # copy: restoring an empty Vaultwarden is not a lesser disaster.
            tables=$(sqlite3 -cmd ".timeout 5000" "$f" \
                     'select count(*) from sqlite_master;' 2>/dev/null) || tables=0
            if [ "${tables:-0}" -lt 1 ]; then
                log "ERROR: dump $1 holds no tables — empty database ($size bytes)"
                return 1
            fi
            log "dump $1 ok ($size bytes, quick_check ok, $tables schema objects)"
            ;;
        *)
            log "ERROR: assert_dump called with unknown kind '$kind' for $1"
            return 1
            ;;
    esac
}

dump_failures=0
check_dump() { assert_dump "$@" || dump_failures=$((dump_failures + 1)); }

check_dump nextcloud.sql marker '-- Dump completed on'
check_dump miniflux.sql  marker '-- PostgreSQL database dump complete'

# Gated on the CONTAINER, not on the database file (#177). Both used to hang off
# the same `[ -f "$DB" ]`, so if a version bump moved the path, the dump, its
# assertion and every log line disappeared TOGETHER: dump_failures stayed 0 and
# the night pushed UP with nothing to show. Not theoretical — a version bump
# renamed wg-easy's store from wg0.json to wg-easy.db and nothing noticed for
# weeks.
#
# A service that is not deployed here legitimately has no dump, and still says
# nothing. A service that IS deployed and whose database is not where we look is
# exactly the failure this now names.
deployed() { docker ps -a --format '{{.Names}}' 2>/dev/null | grep -qx "$1"; }

check_sqlite_dump() {   # container, expected source path, dump filename
    deployed "$1" || return 0
    if [ ! -f "$2" ]; then
        log "ERROR: $1 is deployed but its database is not at $2 — nothing was dumped"
        dump_failures=$((dump_failures + 1))
        return 0
    fi
    check_dump "$3" sqlite
}

check_sqlite_dump vaultwarden "$VAULTWARDEN_DB" vaultwarden.sqlite3
check_sqlite_dump forgejo     "$FORGEJO_DB"     forgejo.sqlite3
check_sqlite_dump uptime-kuma "$KUMA_DB"        uptime-kuma.sqlite3

# Immich is not dumped here — it runs its own scheduled backup into the restic
# set — so its failure mode is not a missing file but a STALE one. keepLastAmount
# only prunes when a new dump is written, so if that job ever stops, the last
# seven sit there indefinitely and every snapshot keeps carrying a dump of
# arbitrary age. Nothing would look wrong anywhere. Same staleness guard as the
# SMART self-test check, for the same reason: the absence of a fresh artefact is
# the signal, not the absence of an artefact.
#
# Gated on the CONTAINER like its three siblings above (#190). It used to hang off
# `[ -d "$IMMICH_BACKUP_DIR" ]` with no else, which is the same defect #177 fixed
# for the SQLite dumps wearing different clothes: if a version bump moves that
# path, the directory test goes false, the whole check is SKIPPED, dump_failures
# stays 0 and the night pushes UP having asserted nothing about the only
# consistent copy of the photo database. wg-easy's store moved exactly that way.
#
# And the content is asserted now, not just the mtime. A truncated .sql.gz lands
# with a current mtime, was certified fresh, and keepLastAmount then pruned the
# last good one behind it.
#
# One pass does both. zcat has to decompress the whole stream to reach the tail,
# and it verifies the CRC as it finishes, so its exit status covers integrity
# while the tail carries the marker. Measured on the real 89 MB dump: `gzip -t`
# 3.60s, `zcat | tail -c 4096` 4.03s — the tail read is the MORE expensive of the
# two, not the cheaper as #190 assumed, so running both would pay twice for one
# answer. 4s inside a run that already takes ~200s.
#
# The tail goes into a variable rather than straight into `grep -qF`. `grep -q`
# exits on the first match, which can SIGPIPE the `tail` behind it, and under
# `pipefail` that turns a SUCCESSFUL match into pipeline status 141 — a race that
# would report a good dump as broken on some nights and not others.
#
# Read the TAIL, not the last line: pg_dump writes `\unrestrict` AFTER its
# completion marker, the same reason assert_dump() gives above.
IMMICH_BACKUP_DIR="/mnt/data/services/immich/upload/backups"
if deployed immich-server; then
    if [ ! -d "$IMMICH_BACKUP_DIR" ]; then
        log "ERROR: immich-server is deployed but $IMMICH_BACKUP_DIR does not exist — nothing was dumped"
        dump_failures=$((dump_failures + 1))
    else
        immich_newest=$(find "$IMMICH_BACKUP_DIR" -name 'immich-db-backup-*.sql.gz' \
                        -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1)
        immich_dump=${immich_newest#* }
        if [ -z "$immich_newest" ]; then
            log "ERROR: immich-server is deployed and $IMMICH_BACKUP_DIR holds no dump at all"
            dump_failures=$((dump_failures + 1))
        elif [ "$(( ( $(date +%s) - ${immich_newest%%.*} ) / 3600 ))" -ge 48 ]; then
            log "ERROR: newest Immich dump is $(( ( $(date +%s) - ${immich_newest%%.*} ) / 3600 ))h old — the scheduled job has stopped"
            dump_failures=$((dump_failures + 1))
        elif ! immich_tail=$(zcat -- "$immich_dump" 2>/dev/null | tail -c 4096); then
            log "ERROR: Immich dump $(basename "$immich_dump") does not decompress — truncated or corrupt"
            dump_failures=$((dump_failures + 1))
        elif ! printf '%s' "$immich_tail" | grep -qF -- '-- PostgreSQL database dump complete'; then
            log "ERROR: Immich dump $(basename "$immich_dump") has no completion marker — truncated ($(stat -c %s "$immich_dump") bytes)"
            dump_failures=$((dump_failures + 1))
        else
            log "dump $(basename "$immich_dump") ok ($(stat -c %s "$immich_dump") bytes, fresh <48h, completion marker present)"
        fi
    fi
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
# `--json` in place of `--verbose`: restic's summary is the only thing that can
# tell a normal night from one that added nothing, and it was going nowhere —
# not to the monitor, which said "completed" either way, and not to this log.
# The trade-off is the per-file listing that `--verbose` sent to the journal;
# what replaces it is one line that can actually be compared night to night.
backup_report=$(restic backup --json \
    --tag auto \
    --exclude '/mnt/data/services/nextcloud/data/data/appdata_*/libresign/aarch64' \
    /mnt/data/services \
    /mnt/data/media \
    /mnt/data/backups/dumps \
    /mnt/data/secrets \
    /opt/homelab \
    2>> "$BACKUP_LOG" \
  | python3 -c '
import json, sys

def human(n):
    for unit in ("B", "KiB", "MiB", "GiB", "TiB"):
        if n < 1024.0:
            return "%.1f %s" % (n, unit)
        n /= 1024.0
    return "%.1f PiB" % n

summary = None
for line in sys.stdin:               # status messages stream; the summary is last
    try:
        msg = json.loads(line)
    except ValueError:
        continue
    if msg.get("message_type") == "summary":
        summary = msg

if summary:
    print("%s\t%d new + %d changed files, %s added, %s processed in %ds" % (
        summary.get("snapshot_id", "")[:8],
        summary.get("files_new", 0),
        summary.get("files_changed", 0),
        human(summary.get("data_added", 0)),
        human(summary.get("total_bytes_processed", 0)),
        summary.get("total_duration", 0)))
') || { log "ERROR: Restic backup failed"; exit 1; }

if [ -n "$backup_report" ]; then
    backup_snapshot="${backup_report%%$'\t'*}"
    backup_summary="snapshot ${backup_snapshot}: ${backup_report#*$'\t'}"
    log "$backup_summary"
else
    # Not fatal — the snapshot may well exist. But the push must not claim a
    # normal night on the strength of an exit code alone.
    log "WARNING: restic produced no summary — the push will say so"
fi

# --- Offsite replication (restic copy over WireGuard, ADR-010) ---
# Runs BEFORE local retention so the snapshot just taken is always copied.
# An offsite failure (link down, parents' outage) never fails the local
# backup — it only trips the dedicated Kuma monitor.

notify_offsite() {
    local url="${KUMA_OFFSITE_PUSH_URL:-}"
    [ -n "$url" ] || return 0
    url="${url%%\?*}"   # strip any pasted ?status=...&msg=... query (dup params read as DOWN)
    # The push URL carries the monitor's own token, so it goes in on stdin
    # instead of argv: /proc is mounted without hidepid, any local account can
    # read another process's command line, and this runs unattended on a timer
    # (#177). printf is a shell builtin, so the value never reaches an argv there
    # either.
    printf 'url = "%s"\n' "$url" |
        curl -fsS -m 10 --retry 2 -K - -G \
            --data-urlencode "status=$1" --data-urlencode "msg=$2" >/dev/null 2>&1 || true
}

# flock: two concurrent copies to the append-only repo re-upload each other's
# packs as permanent duplicates (only a manual prune reclaims them — learned
# the hard way during the 2026-07-12 seed). Same lock file must be used by
# any manual copy/seed: flock /var/lock/offsite-copy.lock restic copy ...
# `restic copy latest` copied exactly one snapshot, so a night whose copy stage
# failed was never retried: the next night took a NEW snapshot and copied that
# one, leaving a permanent hole. The offsite repository has no 2026-07-20
# snapshot for precisely that reason, and `restic check` passes every week
# regardless — it verifies that a repository is internally consistent, not that
# it holds what the other one holds (#158).
#
# Bare `restic copy` would self-heal, and would also push 18 snapshots from
# 2026-05-14 to 2026-07-10 that predate the offsite repository — measured, not
# feared. That repository is APPEND-ONLY, so it is not undoable without a manual
# prune. Tag filtering does not help either: all 32 local snapshots carry `auto`,
# the old ones included.
#
# So the window is time-based, and it is deliberately the same 7 days as
# `--keep-daily` below: beyond that the local snapshot may already have been
# pruned, which makes a wider window a promise this script cannot keep. Restic
# skips whatever the destination already has, so a normal night copies one and
# a night after an outage copies the backlog.
#
# The date is compared as a YYYY-MM-DD prefix rather than parsed. restic emits
# nanosecond precision with an offset (2026-05-14T16:26:36.688901974+02:00), and
# a 7-day window has no business depending on how a given Python version feels
# about nine fractional digits.
if [ -n "${OFFSITE_RESTIC_REPOSITORY:-}" ]; then
    copy_ids=$(restic snapshots --no-lock --json 2>> "$BACKUP_LOG" | python3 -c '
import json, sys, datetime
cutoff = (datetime.date.today() - datetime.timedelta(days=7)).isoformat()
print(" ".join(s["id"] for s in json.load(sys.stdin) if s["time"][:10] >= cutoff))
') || copy_ids=""

    # A hard stop, not a warning. `restic copy` with NO snapshot argument copies
    # the entire source repository — so an empty list here, from a failed listing
    # or a parse error, is exactly the accident this window exists to prevent.
    if [ -z "$copy_ids" ]; then
        log "ERROR: could not list local snapshots — offsite copy skipped rather than run unbounded"
        notify_offsite down "offsite copy skipped: could not list local snapshots"
    else
        offered=$(wc -w <<< "$copy_ids")
        log "Copying the last 7 days to the offsite repo ($offered snapshot(s) offered)..."
        copy_rc=0
        # Unquoted on purpose: the ids are a list of arguments, not one string.
        copy_out=$(flock -n /var/lock/offsite-copy.lock \
           env RESTIC_FROM_REPOSITORY="$RESTIC_REPOSITORY" \
           RESTIC_FROM_PASSWORD="$RESTIC_PASSWORD" \
           RESTIC_REPOSITORY="$OFFSITE_RESTIC_REPOSITORY" \
           RESTIC_PASSWORD="$OFFSITE_RESTIC_PASSWORD" \
           RESTIC_REST_USERNAME="$OFFSITE_REST_USER" \
           RESTIC_REST_PASSWORD="$OFFSITE_REST_PASSWORD" \
           restic copy $copy_ids 2>&1) || copy_rc=$?
        printf '%s\n' "$copy_out" >> "$BACKUP_LOG"

        if [ "$copy_rc" -eq 0 ]; then
            # restic 0.16.4 prints "snapshot <id> saved" per copy and
            # "skipping source snapshot <id>, was already copied to snapshot
            # <id>" per skip (both read out of the binary rather than guessed).
            # Anchored so the second never counts as the first.
            copied=$(grep -cE '^[[:space:]]*snapshot [0-9a-f]+ saved$' <<< "$copy_out" || true)
            log "Offsite copy completed ($copied new, $((offered - copied)) already there)"
            notify_offsite up "offsite copy completed${backup_snapshot:+ (snapshot $backup_snapshot)}: $copied new, $((offered - copied)) already there"
        else
            log "WARNING: offsite copy failed (local backup unaffected)"
            notify_offsite down "offsite copy FAILED — see $BACKUP_LOG"
        fi
    fi
fi

# --- Retention ---
# Nightly: forget only (cheap — updates the snapshot list). The expensive prune
# (repack) + a rotating read-data integrity check run weekly in
# local-maintenance.sh, off the backup window. See homelab-local-maintenance.timer.

log "Applying retention policy..."
# The `|| log` this replaces sent the failure to a file nothing reads, and the
# run still exited 0, so the trap pushed UP with a correct snapshot summary. It
# happened on 2026-08-17: four stale locks left by interrupted read-only audit
# commands the day before, `repo already locked`, retention did nothing, monitor
# green (#168). One skipped night costs nothing — what costs something is that
# the cause persists: a stale lock stays until someone removes it, so the honest
# description is not "a night was skipped" but "retention stopped".
#
# Deferred rather than fatal on the spot: the snapshot exists and has already
# gone offsite, so aborting here would throw away a good backup over
# housekeeping. Down rather than a note on an UP push, because nothing here
# clears itself.
#
# NOT auto-unlocked. `restic unlock` during a nightly run would remove a lock
# held by a legitimate concurrent operation, and the whole reason the offsite
# copy takes a flock is that concurrent writers to a restic repo are expensive
# to undo.
forget_rc=0
restic forget \
    --keep-daily 7 \
    --keep-weekly 4 \
    --keep-monthly 6 \
    2>> "$BACKUP_LOG" || forget_rc=$?
if [ "$forget_rc" -ne 0 ]; then
    log "ERROR: restic forget failed (rc=$forget_rc) — retention did NOT run"
    deferred_problems+=("retention failed (restic forget rc=$forget_rc)")
fi

# --- Cleanup dumps ---
rm -rf "$DUMP_DIR"

log "=== Backup completed ==="

# Deferred verdict. Everything else has already run — the snapshot exists, it
# went offsite, retention was attempted — so this only decides what the monitor
# is told. Non-zero makes the EXIT trap push DOWN instead of "completed", which
# is the whole point: the night a dump goes missing, or retention stops, should
# not look like the night before.
if [ "$dump_failures" -gt 0 ]; then
    deferred_problems+=("$dump_failures dump check(s) failed — the snapshot is incomplete")
fi

if [ ${#deferred_problems[@]} -gt 0 ]; then
    log "ERROR: $(printf '%s; ' "${deferred_problems[@]}")"
    exit 1
fi
