#!/usr/bin/env bash

set -euo pipefail

LOG="/var/log/homelab-ddns.log"
API="https://api.cloudflare.com/client/v4"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG"; }

notify() {
    local url="${KUMA_DDNS_PUSH_URL:-}"
    [ -n "$url" ] || return 0
    url="${url%%\?*}"
    local rc=0
    printf 'url = "%s"\n' "$url" |
        curl -fsS -m 10 --retry 2 -K - -G \
            --data-urlencode "status=$1" --data-urlencode "msg=$2" >/dev/null || rc=$?
    case "$rc" in
        0) ;;
        28) echo "kuma-push-unconfirmed: no reply within 10s, the beat may have landed — $2" >&2 ;;
        *)  echo "kuma-push-failed: this report reached nobody — $2" >&2 ;;
    esac
}

: "${CF_DNS_API_TOKEN:?missing CF_DNS_API_TOKEN}" "${CF_ZONE:?missing CF_ZONE}" "${CF_RECORD:?missing CF_RECORD}"
_cf_curl() {
    printf 'header = "Authorization: Bearer %s"\nheader = "Content-Type: application/json"\n' \
        "$CF_DNS_API_TOKEN" |
        curl -fsS -m 10 -K - "$@"
}

cf_api() { _cf_curl --retry 2 --retry-connrefused "$@"; }

cf_api_once() { _cf_curl "$@"; }

cf_why() {
    case "$1" in
        22) echo "Cloudflare rejected the $2 with an HTTP error status" ;;
        28) echo "Cloudflare timed out on the $2" ;;
        6 | 7) echo "Cloudflare was unreachable for the $2" ;;
        *) echo "the $2 failed" ;;
    esac
}

IP="$(curl -fsS -m 10 --retry 2 --retry-connrefused https://api.ipify.org 2>/dev/null ||
    curl -fsS -m 10 --retry 2 --retry-connrefused https://ifconfig.me 2>/dev/null || true)"
if ! [[ "$IP" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
    log "ERROR: could not determine public IPv4 (got '$IP')"; notify down "no public IP"; exit 1
fi

ZONES="$(cf_api "$API/zones?name=$CF_ZONE")" && RC=0 || RC=$?
[ "$RC" -eq 0 ] ||
    { log "ERROR: $(cf_why "$RC" "zone lookup") (curl exit $RC)"; notify down "$(cf_why "$RC" "zone lookup") (curl $RC)"; exit 1; }
jq -e '.success == true and (.result | type == "array")' >/dev/null 2>&1 <<<"$ZONES" ||
    { log "ERROR: zone lookup for '$CF_ZONE' did not return a zone listing"; notify down "zone lookup: unusable answer"; exit 1; }
ZID="$(jq -r '.result[0].id // empty' <<<"$ZONES")"
[ -n "$ZID" ] || { log "ERROR: zone '$CF_ZONE' not found (token scope?)"; notify down "zone not found (token scope?)"; exit 1; }

REC="$(cf_api "$API/zones/$ZID/dns_records?type=A&name=$CF_RECORD")" && RC=0 || RC=$?
[ "$RC" -eq 0 ] ||
    { log "ERROR: $(cf_why "$RC" "record lookup") (curl exit $RC)"; notify down "$(cf_why "$RC" "record lookup") (curl $RC)"; exit 1; }
jq -e '.success == true and (.result | type == "array")' >/dev/null 2>&1 <<<"$REC" ||
    { log "ERROR: record lookup for $CF_RECORD did not return a record listing"; notify down "record lookup: unusable answer"; exit 1; }
NREC="$(echo "$REC" | jq -r '.result | length')"
[ "$NREC" -le 1 ] ||
    { log "ERROR: $CF_RECORD carries $NREC A records — this script maintains exactly one and would certify only the first"; notify down "$CF_RECORD: $NREC A records"; exit 1; }
RID="$(echo "$REC" | jq -r '.result[0].id // empty')"
CUR="$(echo "$REC" | jq -r '.result[0].content // empty')"

if [ -z "$RID" ]; then
    OUT="$(cf_api_once -X POST "$API/zones/$ZID/dns_records" \
        --data "{\"type\":\"A\",\"name\":\"$CF_RECORD\",\"content\":\"$IP\",\"ttl\":1,\"proxied\":false}")" && RC=0 || RC=$?
    if [ "$RC" -ne 0 ]; then
        log "ERROR: $(cf_why "$RC" "create") (curl exit $RC)"; notify down "$(cf_why "$RC" "create") (curl $RC)"; exit 1
    elif echo "$OUT" | jq -e '.success' >/dev/null 2>&1; then
        log "CREATED $CF_RECORD -> $IP"; notify up "created $IP"
    else
        log "ERROR: create failed: $(echo "$OUT" | jq -c '.errors' 2>/dev/null || echo 'no valid response')"; notify down "create failed"; exit 1
    fi
    exit 0
fi

if [ "$CUR" = "$IP" ]; then
    log "unchanged ($IP)"; notify up "ok $IP"; exit 0
fi

OUT="$(cf_api -X PATCH "$API/zones/$ZID/dns_records/$RID" --data "{\"content\":\"$IP\"}")" && RC=0 || RC=$?
if [ "$RC" -ne 0 ]; then
    log "ERROR: $(cf_why "$RC" "update") (curl exit $RC)"; notify down "$(cf_why "$RC" "update") (curl $RC)"; exit 1
elif echo "$OUT" | jq -e '.success' >/dev/null 2>&1; then
    log "UPDATED $CF_RECORD $CUR -> $IP"; notify up "updated $IP"
else
    log "ERROR: update failed: $(echo "$OUT" | jq -c '.errors' 2>/dev/null || echo 'no valid response')"; notify down "update failed"; exit 1
fi
