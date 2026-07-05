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
systemctl -q is-active homelab-stack-startup.service || exit 0

cd "$COMPOSE_DIR" || { log "FATAL: $COMPOSE_DIR missing"; exit 1; }

docker ps -a --filter "label=com.docker.compose.project" --filter "status=exited" --format '{{.Names}}' \
| while read -r name; do
    code=$(docker inspect -f '{{.State.ExitCode}}' "$name" 2>/dev/null) || continue
    [ "$code" = "0" ] && continue
    svc=$(docker inspect -f '{{index .Config.Labels "com.docker.compose.service"}}' "$name" 2>/dev/null)
    [ -n "$svc" ] || continue
    log "container $name (service $svc) exited with code $code — restarting"
    docker compose up -d "$svc" >/dev/null 2>&1 || log "ERROR: failed to restart $svc"
done
