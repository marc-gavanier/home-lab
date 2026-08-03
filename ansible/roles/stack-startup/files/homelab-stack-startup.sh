#!/usr/bin/env bash
# =============================================================================
# Home Lab — staged container startup (DNS first)
# =============================================================================
# At a cold boot the Docker daemon would restart all containers at once, spiking
# load on the 4 GB Pi and leaving LAN DNS (Pi-hole) down for ~15 min. To avoid
# that, only Tier 0 (pihole/traefik/wg-easy) keeps `restart: unless-stopped` and
# auto-starts with the daemon; every other service is `restart: "no"` — Docker
# never starts them on its own (`on-failure` resurrected containers killed
# non-gracefully by a reboot/power cut; crashes are covered by the heal timer).
# This oneshot service then brings the rest up in waves, gating each wave on
# the previous one becoming healthy.
#
# Fail-fast by design (post-mortem of 2026-07-04): a missing container or a
# failed `compose up` aborts the whole run with a FATAL in the journal, instead
# of silently dispatching waves into the void for 6 minutes.
#
# Run by homelab-stack-startup.service (pulled by homelab-services.target).
# =============================================================================
set -uo pipefail

COMPOSE_DIR=/opt/homelab
DATA_MOUNT=/mnt/data

log() { logger -t homelab-startup "$*"; }
fatal() { log "FATAL: $*"; exit 1; }

cd "$COMPOSE_DIR" || fatal "$COMPOSE_DIR missing"

# --- Sanity gates — fail loudly rather than dispatch waves into the void -----
mountpoint -q "$DATA_MOUNT" || fatal "$DATA_MOUNT not mounted — aborting"
docker info >/dev/null 2>&1 || fatal "docker not responding — aborting"

# Ghost-store guard: if dockerd started BEFORE the mount, it initialised an
# empty store on the SD card under the mount point (0 containers, and pulls
# collide with the real store through the mount). Compare systemd monotonic
# start timestamps: the daemon must have started after the mount.
mount_ts=$(systemctl show -p ActiveEnterTimestampMonotonic --value mnt-data.mount)
docker_ts=$(systemctl show -p ActiveEnterTimestampMonotonic --value docker.service)
if [ -z "$docker_ts" ] || [ -z "$mount_ts" ] || [ "$docker_ts" -lt "$mount_ts" ]; then
    fatal "dockerd started before $DATA_MOUNT was mounted (ghost store) — run: systemctl restart docker"
fi

# Wait until a container is healthy (or merely running, if it has no healthcheck).
# Bounded by a timeout so a stuck/perma-unhealthy service never blocks the boot.
# A *missing* container is fatal: at every call site it must already exist
# (Tier 0 auto-started by the daemon, wave members created by `compose up`).
wait_healthy() {
    local name=$1 timeout=${2:-180} elapsed=0 status
    while true; do
        status=$(docker inspect -f \
            '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' \
            "$name" 2>/dev/null || echo missing)
        case "$status" in
            healthy|running) log "$name is $status (${elapsed}s)"; return 0 ;;
            missing) fatal "container $name does not exist — store problem?" ;;
        esac
        if [ "$elapsed" -ge "$timeout" ]; then
            log "WARN: $name still '$status' after ${timeout}s — continuing"
            return 1
        fi
        sleep 5; elapsed=$((elapsed + 5))
    done
}

# Bring a wave up. `compose up` honours depends_on (unlike the daemon's boot
# restart), so listed dependencies start and gate in the right order. Output is
# captured and journald-logged on failure — then abort: a wave that cannot even
# be dispatched means something is structurally wrong (store, network, .env).
up() {
    local out
    log "starting wave: $*"
    if ! out=$(docker compose up -d "$@" 2>&1); then
        log "compose up output: $out"
        fatal "compose up failed for: $*"
    fi
}

log "staged startup begin"

# Tier 0 (pihole/traefik/wg-easy) is auto-started by Docker. Block on DNS first —
# nothing else matters until the LAN can resolve names again. Generous timeout:
# at a cold start FTL reloads gravity and can take >2 min to pass its
# healthcheck; waiting here IS the point (DNS before the herd).
wait_healthy pihole 300

# Wave 1 — light services
# Dozzle belongs here: it depends on socket-proxy, which Docker already
# auto-started with Tier 0, and `compose up` honours that dependency anyway.
up vaultwarden uptime-kuma searxng navidrome dozzle
wait_healthy vaultwarden 120

# Wave 2 — Nextcloud stack + Transmission (medium)
up nextcloud-db nextcloud-redis nextcloud nextcloud-cron nextcloud-notify-push transmission
wait_healthy nextcloud 240

# Wave 3 — Immich stack, Jellyfin, Netdata, Collabora (heavy; no gating after
# the last wave). Collabora belongs here rather than with Nextcloud: it takes
# ~80 s to serve, and nothing needs it until someone opens a document.
up immich-redis immich-db immich-machine-learning immich-server jellyfin netdata collabora

log "staged startup complete — all waves dispatched"
