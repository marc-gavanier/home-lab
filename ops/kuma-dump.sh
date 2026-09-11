#!/usr/bin/env bash
#
# kuma-dump.sh — Read-only export of the Uptime Kuma configuration.
#
# Uptime Kuma v2 dropped the built-in Settings > Backup export, and the mature
# automation tooling (uptime-kuma-api / the lucasheld Ansible collection) does
# not support v2 yet. This script sidesteps both by reading the SQLite database
# directly over SSH, in READ-ONLY mode (mode=ro), so it never touches the DB
# the running container has open.
#
# Output is a single JSON snapshot of monitors, notifications, their links and
# tags — a versioned, disaster-recovery inventory of what Kuma monitors.
#
# WARNING: the snapshot contains secrets (push tokens, the Discord webhook).
# It defaults to .secrets/ (git-ignored). To keep it for DR in-repo, encrypt it:
#     ansible-vault encrypt .secrets/kuma-dump.json
#
# Usage:
#     ops/kuma-dump.sh [output.json]
#
# Environment overrides:
#     KUMA_SSH_HOST   SSH alias/host of the Kuma server   (default: homelab)
#     KUMA_CONTAINER  Kuma container name                 (default: uptime-kuma)
#     KUMA_DB         DB path inside the container         (default: /app/data/kuma.db)
#
set -euo pipefail

SSH_HOST="${KUMA_SSH_HOST:-homelab}"
CONTAINER="${KUMA_CONTAINER:-uptime-kuma}"
DB="${KUMA_DB:-/app/data/kuma.db}"
OUT="${1:-.secrets/kuma-dump.json}"

mkdir -p "$(dirname "$OUT")"

# The `monitor` columns are DERIVED from the schema, not listed here, and that
# is the whole point of the change of 2026-09-11. The hand-kept list named 21
# columns against a table that has 114. It aborts loudly on a column that is
# REMOVED, because sqlite3 then errors under `set -e`, and passes in silence on
# a column that is ADDED — which is the only way Uptime Kuma v2 actually
# evolves. So it was loud in the direction that does not happen and blind in the
# one that does.
#
# That mattered because three of the 92 columns it omitted carry operator-set
# values that decide whether a monitor tests the right thing at all:
#
#   monitor 8  "Pi-hole DNS"   dns_resolve_server = the Pi itself. Monitors 1-12
#                              default to 1.1.1.1, so a monitor rebuilt from a
#                              dump without this column asks Cloudflare and stays
#                              GREEN while Pi-hole is dead. It stops being a
#                              Pi-hole monitor and nothing says so.
#   monitor 13 "Transmission"  auth_method/basic_auth_* — the only monitor with
#                              any. Lost, the probe gets 401, which per #191 that
#                              monitor accepts. Green again.
#   monitor 12 "Pi (ping)"     ping_count = 1, a deliberate single packet, which
#                              would silently become three.
#
# And `conditions` — the v2 monitor-condition column — is [] everywhere today,
# so the first one ever written would have been dropped without a word.
#
# The version signature is visible in the data: monitors 1-12 carry
# dns_resolve_server and no location, monitors 13-37 carry location='world' and
# no dns_resolve_server. The schema moved under a static list.
#
# uptime-kuma-migration-failure.md runs this script against a trial container to
# "check that ops/kuma-dump.sh still reads the schema". With a hand-kept list it
# could not check that: it read 19 % of the columns and reported success on them.
#
# The other four tables keep explicit lists. They are small, stable, and their
# columns are the relationship itself; if that stops being true the same
# treatment applies.
# `monitor` is exported with EVERY column, via sqlite3's own -json mode, and the
# other four tables keep their explicit lists. Two mechanisms were tried and
# rejected first, both worth recording so nobody re-tries them:
#
#   json_object() with all 114 columns exceeds SQLITE_MAX_FUNCTION_ARG (127 —
#   114 columns are 228 arguments) and fails outright, loudly.
#
#   Splitting it into chunks merged with json_patch() parses, and is WRONG:
#   json_patch implements RFC 7386, where a null value DELETES the key. Columns
#   that are null — dns_resolve_server is null on monitors 13-37 — would vanish
#   from every chunk after the first, giving a dump whose shape varies with its
#   content. That is the same class of silent difference this script exists to
#   stop.
#
# -json has neither limit. mode=ro is WAL-safe: concurrent reads alongside the
# live writer, zero risk to Kuma.
echo "→ Dumping Kuma config from ${SSH_HOST}:${CONTAINER} (${DB}) — read-only" >&2

read -r -d '' SQL <<'SQL' || true
.mode json
select * from monitor;
select '---TABLE---';
select id, name, active, is_default, config from notification;
select '---TABLE---';
select monitor_id, notification_id from monitor_notification;
select '---TABLE---';
select id, name, color from tag;
select '---TABLE---';
select monitor_id, tag_id from monitor_tag;
SQL

RAW=$(ssh "$SSH_HOST" "docker exec -i ${CONTAINER} sqlite3 'file:${DB}?mode=ro'" <<<"$SQL")

if [ -z "$RAW" ]; then
    echo "✗ Empty output — is the container running and the DB path correct?" >&2
    exit 1
fi

# Split on the marker rows and assemble. An empty table yields an empty section,
# which becomes [] rather than nothing — sqlite3 prints no array at all for zero
# rows, and a missing value would make the document unparseable instead of empty.
RAW="$RAW" python3 - "$OUT" <<'PYEOF'
import json, os, sys

# RAW arrives through the environment, not stdin: stdin is already carrying this
# script, and a second redirection would silently replace the first.
parts, cur = [], []
for line in os.environ["RAW"].splitlines():
    if "---TABLE---" in line:
        parts.append("\n".join(cur))
        cur = []
        continue
    cur.append(line)
parts.append("\n".join(cur))

names = ["monitors", "notifications", "monitor_notification", "tags", "monitor_tag"]
if len(parts) != len(names):
    sys.exit("\u2717 expected %d table sections, got %d — the marker rows moved"
             % (len(names), len(parts)))

doc = {}
for name, blob in zip(names, parts):
    blob = blob.strip()
    # sqlite3 prints NO array at all for zero rows, so an empty section has to
    # become [] here; leaving it out would make the document unparseable rather
    # than empty, which is the wrong failure.
    doc[name] = json.loads(blob) if blob else []

if not doc["monitors"]:
    sys.exit("\u2717 zero monitors exported — refusing to write a dump that looks successful")
ncols = len(doc["monitors"][0])
if ncols <= 21:
    sys.exit("\u2717 %d columns per monitor — the hand-kept list this replaced had 21, "
             "so the derivation is doing worse than what it fixed" % ncols)
print("\u2192 %d monitors, %d columns each, derived from the live schema"
      % (len(doc["monitors"]), ncols), file=sys.stderr)

with open(sys.argv[1], "w", encoding="utf-8") as fh:
    json.dump(doc, fh, indent=2, sort_keys=True)
    fh.write("\n")
PYEOF

echo "✓ Snapshot written to ${OUT} ($(wc -c <"$OUT") bytes)" >&2

# Optional human summary (secrets masked), only if python3 is available.
if command -v python3 >/dev/null 2>&1; then
    python3 - "$OUT" <<'PY' >&2
import json, sys
d = json.load(open(sys.argv[1]))
m = d.get("monitors") or []
print(f"\n  {len(m)} monitors:")
for x in m:
    tgt = x.get("url") or x.get("hostname") or "-"
    print(f"    [{x['id']:>2}] {x['name']:<26} {x['type']:<6} {tgt}")
n = d.get("notifications") or []
print(f"  {len(n)} notification(s): " + ", ".join(x["name"] for x in n))
PY
fi
