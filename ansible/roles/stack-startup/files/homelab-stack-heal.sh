#!/usr/bin/env bash
# =============================================================================
# Home Lab — crash recovery for staged services
# =============================================================================
# Non-Tier-0 services use `restart: "no"`: Docker must never start them on its
# own — with `on-failure`, the daemon resurrected at boot every container that
# had been killed non-gracefully (reboot/power cut => exit 137/143/255), which
# defeated the staged startup. The trade-off is that Docker no longer restarts
# real crashes either; this timer-driven script covers that: any compose
# container found exited with a non-zero code is brought back with `compose up`.
#
# For manual maintenance, remove the container (`docker compose down <svc>`)
# instead of stopping it — a stopped container often reports a non-zero exit
# code and would be resurrected on the next timer tick.
#
# Run by homelab-stack-heal.timer (every 2 min while homelab-services.target up).
# =============================================================================
set -uo pipefail

COMPOSE_DIR=/opt/homelab

log() { logger -t homelab-heal "$*"; }

# Never race the staged startup: the oneshot reports "active" (RemainAfterExit)
# only once all waves have been dispatched — "activating" while they run.
#
# `is-active` ALONE was the bug (#241). It is false for two different states,
# and only one of them means "do not heal yet":
#
#   activating / inactive   the waves are still running, or have not started.
#                           Healing here would fight the orchestrator. Correct.
#   failed                  the startup ran and gave up. Every container it did
#                           not reach is stopped and nothing else will start
#                           them. This is the case healing exists FOR, and it
#                           was the one being skipped.
#
# Measured on 2026-08-26: wave 1 died because miniflux-db was nine seconds short
# of finishing its crash recovery, homelab-stack-startup went to `failed`, and
# 15 containers sat stopped while this timer fired every two minutes into an
# empty `exit 0` — `journalctl -t homelab-heal -b` returned "-- No entries --"
# for the whole outage. Two safety mechanisms, one failure: the stack could not
# restart itself and the thing whose job is to restart it had been switched off
# by the same event.
if ! systemctl -q is-active homelab-stack-startup.service &&
   ! systemctl -q is-failed homelab-stack-startup.service; then
    exit 0
fi

cd "$COMPOSE_DIR" || { log "FATAL: $COMPOSE_DIR missing"; exit 1; }

# --- Say how many were LOOKED AT, not only what was healed -------------------
# Every log line below sits inside the loop, so a run that heals nothing writes
# nothing — and so does a run whose query is blind. The two were indistinguishable
# for the whole of the 2026-08-26 outage described above: `journalctl -t
# homelab-heal -b` returned "-- No entries --" while 15 containers sat stopped,
# which is byte for byte what it returns on a healthy night.
#
# So the count leaves the loop. `checked 0` and `checked 29, 0 restarted` are
# now different sentences, and homelab-health.sh asserts the first number is
# above zero — the silence is no longer something a human has to interpret.
#
# The list is captured BEFORE the loop rather than piped into it: a piped
# `while` runs in a subshell and the counter would not survive it. The existing
# `[ -n "$name" ]` guard already absorbs the empty line a here-document makes
# from an empty list.
exited=$(docker ps -a --filter "label=com.docker.compose.project" --filter "status=exited" --format '{{.Names}}')
checked=$(docker ps -a --filter "label=com.docker.compose.project" --format '{{.Names}}' | grep -c .)
healed=0

while read -r name; do
    [ -n "$name" ] || continue
    code=$(docker inspect -f '{{.State.ExitCode}}' "$name" 2>/dev/null) || continue
    [ "$code" = "0" ] && continue
    svc=$(docker inspect -f '{{index .Config.Labels "com.docker.compose.service"}}' "$name" 2>/dev/null)
    [ -n "$svc" ] || continue
    log "container $name (service $svc) exited with code $code — restarting"
    if docker compose up -d "$svc" >/dev/null 2>&1; then
        healed=$((healed + 1))
    else
        log "ERROR: failed to restart $svc"
    fi
done <<EOF
$exited
EOF

log "checked $checked container(s), $healed restarted"
