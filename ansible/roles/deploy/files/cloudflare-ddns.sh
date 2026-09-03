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
    # The push URL carries the monitor's own token, so it goes in on stdin
    # instead of argv: /proc is mounted without hidepid, any local account can
    # read another process's command line, and this runs unattended on a timer
    # (#177). printf is a shell builtin, so the value never reaches an argv there
    # either.
    #
    # The failure is KEPT, not discarded. This call used to end in `2>&1 || true`,
    # which threw away curl's diagnosis AND its verdict, so a report that reached
    # nobody was indistinguishable from one that landed. Measured on 2026-08-30:
    # three runs of homelab-health finished green, having done their work, while
    # their beats never reached Kuma and the monitor sat on a reading 16 min 55 s
    # old. `|| echo` rather than a real failure because the caller must not abort
    # on it — what failed is the report, not the check it carries. The marker
    # string is what `no-kuma-report-was-lost-in-silence` reads in the posture
    # spec; keep the two in step.
    printf 'url = "%s"\n' "$url" |
        curl -fsS -m 10 --retry 2 -K - -G \
            --data-urlencode "status=$1" --data-urlencode "msg=$2" >/dev/null ||
            echo "kuma-push-failed: this report reached nobody — $2" >&2
}

: "${CF_DNS_API_TOKEN:?missing CF_DNS_API_TOKEN}" "${CF_ZONE:?missing CF_ZONE}" "${CF_RECORD:?missing CF_RECORD}"
# The token authenticates every Cloudflare call below. It goes in through a
# config file on stdin rather than `-H` in argv: /proc is mounted without
# hidepid, so any local unprivileged account can read this process's command
# line, and the timer runs it ~192 times a day (#177). The secret FILE was
# always correctly protected at 0600 — only its use leaked.
#
# printf is a shell builtin, so the token never reaches an argv there either,
# and the pipe means it never touches the filesystem the way a heredoc would.
_cf_curl() {
    printf 'header = "Authorization: Bearer %s"\nheader = "Content-Type: application/json"\n' \
        "$CF_DNS_API_TOKEN" |
        curl -fsS -m 10 -K - "$@"
}

# `--retry 2`, and the split from `cf_api_once` below is the point of it. Three
# runs died on a SINGLE 10 s timeout to api.cloudflare.com — 2026-08-31 20:00,
# 2026-09-02 16:30, 2026-09-03 12:45 — out of 4364 runs since 2026-07-20. Each
# healed unaided at the next tick 15 minutes later, having reddened two Kuma
# monitors on the way: DDNS itself, and `Pi health`, which reports the last
# systemd unit that failed. The A record was correct throughout; what was lost
# was only the confirmation of it. curl counts a timeout as a transient error,
# so these flags cover exactly the observed failure — and `notify` above has
# carried the same two all along, which made this call the odd one out rather
# than the careful one.
#
# Retrying is safe here ONLY because the request is idempotent: the two lookups
# read, and the PATCH sets the record to a value computed before sending, so a
# replay lands the same record.
cf_api() { _cf_curl --retry 2 --retry-connrefused "$@"; }

# One attempt, for the one request that must never be replayed. A POST whose
# answer is lost is not a POST that did not happen, so asking again is how you
# get the duplicate A record the record-lookup guard below exists to prevent.
cf_api_once() { _cf_curl "$@"; }

# `-f` collapses two unrelated events into exit 22: Cloudflare ANSWERED, with a
# 4xx or 5xx. Every other code means no answer arrived. Reporting an expired
# token as a network fault is the same class of misdirection this fix exists to
# remove — only pointing the other way — so the code is translated rather than
# printed raw. It is still printed alongside, because `curl exit 28` is what
# `journalctl -u homelab-ddns` shows on the line above and the two should match.
cf_why() {
    case "$1" in
        22) echo "Cloudflare rejected the $2 with an HTTP error status" ;;
        28) echo "Cloudflare timed out on the $2" ;;
        6 | 7) echo "Cloudflare was unreachable for the $2" ;;
        *) echo "the $2 failed" ;;
    esac
}

# --- Current public IPv4 (with a fallback source) ---
# Same `--retry 2` as the Cloudflare calls and for the same reason: the second
# provider is a fallback for one that is DOWN, and does nothing for a network
# that is merely slow for ten seconds — which is the failure actually observed.
IP="$(curl -fsS -m 10 --retry 2 --retry-connrefused https://api.ipify.org 2>/dev/null ||
    curl -fsS -m 10 --retry 2 --retry-connrefused https://ifconfig.me 2>/dev/null || true)"
if ! [[ "$IP" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
    log "ERROR: could not determine public IPv4 (got '$IP')"; notify down "no public IP"; exit 1
fi

# Every Cloudflare call below ends in `&& RC=0 || RC=$?`, and it is not
# decoration. `set -e` plus `pipefail` kills the script on the failing
# ASSIGNMENT, before the line that inspects the result — so each `notify down`
# branch here was unreachable for exactly the failures it names: an expired
# token, a 5xx, a rate limit. Reproduced, and the only visible trace was the
# dead-man window on the push monitor hours later, with no message saying which
# call failed (#156). Deferring hands control to the checks that follow, which
# is where the diagnosis was meant to happen.
#
# The status is now KEPT rather than flattened into `|| VAR=""`, and that is the
# second half of the 2026-09-03 fix. "No answer arrived" and "an answer arrived
# and it is unusable" are different faults with different answers, and the old
# form reported both as the latter: on 2026-09-02 the log read
# `zone 'example.com' not found (token scope?)` for what the line above it shows
# was a ten-second network timeout, sending the reader to audit a token that was
# never involved. Each call below now separates the two, and names curl's exit
# code when the transport is what failed.

# --- Zone id ---
ZONES="$(cf_api "$API/zones?name=$CF_ZONE")" && RC=0 || RC=$?
[ "$RC" -eq 0 ] ||
    { log "ERROR: $(cf_why "$RC" "zone lookup") (curl exit $RC)"; notify down "$(cf_why "$RC" "zone lookup") (curl $RC)"; exit 1; }
jq -e '.success == true and (.result | type == "array")' >/dev/null 2>&1 <<<"$ZONES" ||
    { log "ERROR: zone lookup for '$CF_ZONE' did not return a zone listing"; notify down "zone lookup: unusable answer"; exit 1; }
ZID="$(jq -r '.result[0].id // empty' <<<"$ZONES")"
[ -n "$ZID" ] || { log "ERROR: zone '$CF_ZONE' not found (token scope?)"; notify down "zone not found (token scope?)"; exit 1; }

# --- Record lookup ---
# Guarded on its own line rather than left to fall through: an empty REC makes
# RID empty too, and an empty RID means "the record does not exist" to the
# branch below — so a transient API failure would try to CREATE a record that
# is already there. `jq` on empty input would also abort the script one line
# later, which is how this stayed hidden.
#
# And the guard is on the ANSWER, not on the string (#289, class C03). A
# well-formed JSON that is not a record listing is non-empty, passes `-n`, and
# yields an empty RID — which this script reads as "the record does not exist"
# and answers by creating a duplicate of a record that is already there. That is
# the very failure the paragraph above says this line prevents.
#
# The zone lookup carries the same three-way shape since 2026-09-03. Guarding
# ZID on the value actually consumed was never WRONG — an unusable body yields
# an empty id and the check fires — but it collapsed three different faults into
# one message that named the token, and the token was the one thing that had not
# failed.
REC="$(cf_api "$API/zones/$ZID/dns_records?type=A&name=$CF_RECORD")" && RC=0 || RC=$?
[ "$RC" -eq 0 ] ||
    { log "ERROR: $(cf_why "$RC" "record lookup") (curl exit $RC)"; notify down "$(cf_why "$RC" "record lookup") (curl $RC)"; exit 1; }
jq -e '.success == true and (.result | type == "array")' >/dev/null 2>&1 <<<"$REC" ||
    { log "ERROR: record lookup for $CF_RECORD did not return a record listing"; notify down "record lookup: unusable answer"; exit 1; }
RID="$(echo "$REC" | jq -r '.result[0].id // empty')"
CUR="$(echo "$REC" | jq -r '.result[0].content // empty')"

# --- Create if missing (auto-heal) ---
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

# --- Update only on change ---
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
