#!/usr/bin/env bash
# =============================================================================
# Home Lab — Cloudflare DDNS (keep the vpn A record on the current public IP)
# =============================================================================
# `vpn.<domain>` is the ONE public DNS record (ADR-014): the host a remote
# WireGuard client must resolve before the tunnel exists. On a dynamic-IP home
# ISP the public IPv4 can change on reconnect → the record goes stale → remote
# access dies silently. This runs on a timer and:
#   - updates the record only when the IP actually changed, and
#   - creates it if missing (auto-heals an accidental deletion).
#
# Environment (systemd EnvironmentFile /opt/homelab/ddns.env):
#   CF_DNS_API_TOKEN   scoped Cloudflare token (Zone:DNS:Edit + Zone:Read)
#   CF_ZONE            the zone, e.g. example.com
#   CF_RECORD          the record to keep fresh, e.g. vpn.example.com
#   KUMA_DDNS_PUSH_URL optional Uptime Kuma push monitor (empty = disabled)
# =============================================================================

set -euo pipefail

LOG="/var/log/homelab-ddns.log"
API="https://api.cloudflare.com/client/v4"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG"; }

notify() {
    local url="${KUMA_DDNS_PUSH_URL:-}"
    [ -n "$url" ] || return 0
    url="${url%%\?*}"   # strip any pasted ?status=...&msg=... query (dup params read as DOWN)
    curl -fsS -m 10 --retry 2 -G "$url" \
        --data-urlencode "status=$1" --data-urlencode "msg=$2" >/dev/null 2>&1 || true
}

: "${CF_DNS_API_TOKEN:?missing CF_DNS_API_TOKEN}" "${CF_ZONE:?missing CF_ZONE}" "${CF_RECORD:?missing CF_RECORD}"
AUTH=(-H "Authorization: Bearer $CF_DNS_API_TOKEN" -H "Content-Type: application/json")

# --- Current public IPv4 (with a fallback source) ---
IP="$(curl -fsS -m 10 https://api.ipify.org 2>/dev/null || curl -fsS -m 10 https://ifconfig.me 2>/dev/null || true)"
if ! [[ "$IP" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
    log "ERROR: could not determine public IPv4 (got '$IP')"; notify down "no public IP"; exit 1
fi

# Every Cloudflare call below ends in `|| VAR=""`, and it is not decoration.
# `set -e` plus `pipefail` kills the script on the failing ASSIGNMENT, before
# the line that inspects the result — so each `notify down` branch here was
# unreachable for exactly the failures it names: an expired token, a 5xx, a
# rate limit. Reproduced, and the only visible trace was the dead-man window on
# the push monitor hours later, with no message saying which call failed
# (#156). Falling back to an empty string hands control to the check that
# follows, which is where the diagnosis was meant to happen.

# --- Zone id ---
ZID="$(curl -fsS -m 10 "${AUTH[@]}" "$API/zones?name=$CF_ZONE" | jq -r '.result[0].id // empty')" || ZID=""
[ -n "$ZID" ] || { log "ERROR: zone '$CF_ZONE' not found (token scope?)"; notify down "zone lookup failed"; exit 1; }

# --- Record lookup ---
# Guarded on its own line rather than left to fall through: an empty REC makes
# RID empty too, and an empty RID means "the record does not exist" to the
# branch below — so a transient API failure would try to CREATE a record that
# is already there. `jq` on empty input would also abort the script one line
# later, which is how this stayed hidden.
REC="$(curl -fsS -m 10 "${AUTH[@]}" "$API/zones/$ZID/dns_records?type=A&name=$CF_RECORD")" || REC=""
[ -n "$REC" ] || { log "ERROR: record lookup failed for $CF_RECORD"; notify down "record lookup failed"; exit 1; }
RID="$(echo "$REC" | jq -r '.result[0].id // empty')"
CUR="$(echo "$REC" | jq -r '.result[0].content // empty')"

# --- Create if missing (auto-heal) ---
if [ -z "$RID" ]; then
    OUT="$(curl -fsS -m 10 "${AUTH[@]}" -X POST "$API/zones/$ZID/dns_records" \
        --data "{\"type\":\"A\",\"name\":\"$CF_RECORD\",\"content\":\"$IP\",\"ttl\":1,\"proxied\":false}")" || OUT=""
    if echo "$OUT" | jq -e '.success' >/dev/null 2>&1; then
        log "CREATED $CF_RECORD -> $IP"; notify up "created $IP"
    else
        log "ERROR: create failed: $(echo "$OUT" | jq -c '.errors' 2>/dev/null || echo 'no valid response')"; notify down "create failed"; exit 1
    fi
    exit 0
fi

# --- Update only on change ---
if [ "$CUR" = "$IP" ]; then
    log "unchanged ($IP)"; notify up "ok $IP"; exit 0
fi

OUT="$(curl -fsS -m 10 "${AUTH[@]}" -X PATCH "$API/zones/$ZID/dns_records/$RID" --data "{\"content\":\"$IP\"}")" || OUT=""
if echo "$OUT" | jq -e '.success' >/dev/null 2>&1; then
    log "UPDATED $CF_RECORD $CUR -> $IP"; notify up "updated $IP"
else
    log "ERROR: update failed: $(echo "$OUT" | jq -c '.errors' 2>/dev/null || echo 'no valid response')"; notify down "update failed"; exit 1
fi
