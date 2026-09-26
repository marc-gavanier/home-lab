#!/usr/bin/env bash
set -uo pipefail

: "${KILLSWITCH_URL:?KILLSWITCH_URL not set}"
: "${KILLSWITCH_KEYWORD:?KILLSWITCH_KEYWORD not set}"

logger -t killswitch "armed — listening on ntfy topic (outbound)"

while true; do
    printf 'url = "%s"\n' "$KILLSWITCH_URL" |
        curl -sN -K - 2>/dev/null | while IFS= read -r msg; do
        [ -z "$msg" ] && continue
        if [ "$msg" = "$KILLSWITCH_KEYWORD" ]; then
            logger -t killswitch "TRIGGER received — powering off now"
            systemctl poweroff
        else
            logger -t killswitch "message received but keyword mismatch — ignored"
        fi
    done
    sleep 5
done
