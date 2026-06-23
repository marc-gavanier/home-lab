#!/usr/bin/env bash
# =============================================================================
# Home Lab — ntfy kill switch
# =============================================================================
# Subscribes (OUTBOUND) to a secret ntfy topic. When a message whose body equals
# the secret keyword arrives, powers the machine off. Run as root by a systemd
# service (killswitch.service). No inbound port is opened.
#
# Config from /etc/killswitch.env:
#   KILLSWITCH_URL      — https://ntfy.sh/<secret-topic>/raw
#   KILLSWITCH_KEYWORD  — exact message body that triggers poweroff
#
# Trigger from anywhere:  curl -d '<keyword>' https://ntfy.sh/<secret-topic>
# Recovery (deliberate):  restore power, then SSH in and enter the LUKS passphrase.
# =============================================================================
set -uo pipefail

: "${KILLSWITCH_URL:?KILLSWITCH_URL not set}"
: "${KILLSWITCH_KEYWORD:?KILLSWITCH_KEYWORD not set}"

logger -t killswitch "armed — listening on ntfy topic (outbound)"

while true; do
    # Stream the topic: one message body per line; empty lines are keepalives.
    curl -sN "$KILLSWITCH_URL" 2>/dev/null | while IFS= read -r msg; do
        [ -z "$msg" ] && continue
        if [ "$msg" = "$KILLSWITCH_KEYWORD" ]; then
            logger -t killswitch "TRIGGER received — powering off now"
            systemctl poweroff
        else
            logger -t killswitch "message received but keyword mismatch — ignored"
        fi
    done
    # Stream ended (network drop / server restart) — wait and reconnect.
    sleep 5
done
