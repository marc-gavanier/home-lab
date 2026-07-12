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
#     scripts/kuma-dump.sh [output.json]
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

# Build the JSON entirely in SQL with json_object/json_group_array so we avoid
# shell quoting hell and get one clean document. mode=ro is WAL-safe: concurrent
# reads alongside the live writer, zero risk to Kuma.
read -r -d '' SQL <<'SQL' || true
SELECT json_object(
  'monitors', (SELECT json_group_array(json_object(
     'id',id,'name',name,'type',type,'active',active,'url',url,'hostname',hostname,'port',port,
     'interval',interval,'maxretries',maxretries,'retry_interval',retry_interval,'keyword',keyword,
     'invert_keyword',invert_keyword,'method',method,'upside_down',upside_down,'ignore_tls',ignore_tls,
     'accepted_statuscodes',accepted_statuscodes_json,'push_token',push_token,'parent',parent,
     'description',description,'expiry_notification',expiry_notification,'resend_interval',resend_interval
  )) FROM monitor),
  'notifications', (SELECT json_group_array(json_object(
     'id',id,'name',name,'active',active,'is_default',is_default,'config',config)) FROM notification),
  'monitor_notification', (SELECT json_group_array(json_object(
     'monitor_id',monitor_id,'notification_id',notification_id)) FROM monitor_notification),
  'tags', (SELECT json_group_array(json_object('id',id,'name',name,'color',color)) FROM tag),
  'monitor_tag', (SELECT json_group_array(json_object(
     'monitor_id',monitor_id,'tag_id',tag_id)) FROM monitor_tag)
);
SQL

echo "→ Dumping Kuma config from ${SSH_HOST}:${CONTAINER} (${DB}) — read-only" >&2

ssh "$SSH_HOST" "docker exec -i ${CONTAINER} sqlite3 'file:${DB}?mode=ro'" <<<"$SQL" >"$OUT"

if [ ! -s "$OUT" ]; then
    echo "✗ Empty output — is the container running and the DB path correct?" >&2
    exit 1
fi

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
