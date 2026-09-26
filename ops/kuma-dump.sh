#!/usr/bin/env bash
set -euo pipefail

SSH_HOST="${KUMA_SSH_HOST:-homelab}"
CONTAINER="${KUMA_CONTAINER:-uptime-kuma}"
DB="${KUMA_DB:-/app/data/kuma.db}"
OUT="${1:-.secrets/kuma-dump.json}"

umask 077
mkdir -p "$(dirname "$OUT")"

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

RAW="$RAW" python3 - "$OUT" <<'PYEOF'
import json, os, sys

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

chmod 600 "$OUT"

echo "✓ Snapshot written to ${OUT} ($(wc -c <"$OUT") bytes, mode $(stat -c %a "$OUT"))" >&2

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
