#!/usr/bin/env bash
# =============================================================================
# Home Lab — database dumps and their assertions (ADR-031)
# =============================================================================
# Extracted verbatim from backup.sh, and deliberately NOT replaced by anything.
# resticprofile takes the orchestration; this is the half no tool expresses:
# 26 application-specific dump commands, and the assertions that check they
# produced something real.
#
# Those assertions are the most valuable lines in the original script. They are
# what turned "the dump file is present" into "it opens, it is fresh, and it
# carries its completion marker" — see #190, where a guard tested a DIRECTORY
# and a truncated dump passed for months.
#
# Runs as resticprofile's `run-before` on the backup.
#
# --- Why this always exits 0 ------------------------------------------------
# In backup.sh a failed dump did NOT stop the backup: the failure was deferred,
# the snapshot was taken anyway with whatever succeeded, and the operator was
# told at the end. A `run-before` that exits non-zero would make resticprofile
# ABORT the backup instead — so one bad dump would mean no backup at all that
# night. That would be a regression, not a migration.
#
# So the verdict goes to a status file that the notification hook reads, and
# this script always exits 0. The failure is reported, never silent, and never
# costs the snapshot.
# =============================================================================

# `set -e` is deliberately ABSENT, and backup.sh had it.
#
# Under `-e`, any unguarded failure aborts the script — which here would mean
# exiting before the verdict is written, and resticprofile then cancelling the
# backup. The whole point of the paragraph above is that a bad dump must not
# cost the snapshot.
#
# What replaces it is not nothing: the assertions below ARE the contract. A dump
# command that fails silently is caught by the check that opens its file, not by
# an exit code — which is the lesson of #190, where the file existed and the
# guard was satisfied while the content was truncated.
set -uo pipefail

BACKUP_LOG="/var/log/homelab-backup.log"
DUMP_DIR="/mnt/data/backups/dumps"
DUMP_STATUS="/run/homelab-backup-dumps.status"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$BACKUP_LOG"; }

if [ -f /opt/homelab/backup.env ]; then
    set -a
    # shellcheck disable=SC1091
    source /opt/homelab/backup.env
    set +a
else
    log "ERROR: /opt/homelab/backup.env not found"
    echo "backup.env missing — no dump was taken" > "$DUMP_STATUS"
    exit 0
fi

log "=== Database dumps started ==="

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
# 0700, not the unit's umask (#199). `mkdir -p` under UMask=0022 gave 0755, and
# the dumps 0644, under parents that are 0755 all the way up — so for the length
# of every run, any local unprivileged account could read the complete
# Vaultwarden vault, the Kuma database with its push tokens and notification
# path, Nextcloud's password hashes, and the Forgejo database. The modes were
# read back out of a snapshot, so they are what really existed on disk.
#
# The #177 sweep closed the six LIVE credential stores to 0700 and never looked
# at the copy this script makes of the same data every night.
#
# Six minutes a night is the normal case, not the bounding one: the cleanup at
# the bottom is only reached on a successful run, while a failed restic backup
# exits well before it, leaving the dumps in place until the next night.
#
# The directory, not the files: `sqlite3 .backup` and `>` both create with the
# process umask, so a per-file expectation would drift back on its own. Nothing
# else reads this path — no container mounts /mnt/data/backups — and restic runs
# as root, which ignores the mode.
install -d -m 0700 "$DUMP_DIR"

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

# --- Verdict, for the notification hook to read ------------------------------
# Written on every run, success included: an absent file must read as "the dump
# step did not run", not as "everything was fine".
if [ "${dump_failures:-0}" -gt 0 ]; then
    log "ERROR: ${dump_failures} dump check(s) failed — the snapshot will be incomplete"
    echo "${dump_failures} dump check(s) failed — the snapshot is incomplete" > "$DUMP_STATUS"
else
    log "=== Database dumps complete, all checks passed ==="
    : > "$DUMP_STATUS"
fi

# Always 0. See the header: a non-zero exit here would abort the backup.
exit 0
