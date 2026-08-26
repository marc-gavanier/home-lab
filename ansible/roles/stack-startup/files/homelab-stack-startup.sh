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
# (Tier 0 created below, wave members created by `compose up`).
#
# The missing branch used to be unreachable, and was so from the day it was
# written for the 2026-07-04 post-mortem. `docker inspect` on an absent
# container writes an empty line to stdout *before* exiting non-zero, and
# `2>/dev/null` hides the error but not that line, so `$(… || echo missing)`
# yielded "\nmissing" — which `case` never matches against `missing)`. The run
# fell through to the timeout instead: 300 s of waiting, then every remaining
# wave dispatched with no DNS. Measured twice on 2026-08-26 (#252).
#
# Testing the exit status of the assignment removes the string collision
# entirely. But `docker inspect` fails identically for a container that does
# not exist and for a daemon that blinked, and only the first deserves a FATAL —
# so `docker info` arbitrates. Without it, this fix would turn a transient
# daemon hiccup into an aborted boot.
wait_healthy() {
    local name=$1 timeout=${2:-180} elapsed=0 status
    while true; do
        if ! status=$(docker inspect -f \
            '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' \
            "$name" 2>/dev/null); then
            if docker info >/dev/null 2>&1; then
                fatal "container $name does not exist — store problem?"
            fi
            log "WARN: docker not responding while waiting for $name — retrying"
            status=unavailable
        fi
        case "$status" in
            healthy|running) log "$name is $status (${elapsed}s)"; return 0 ;;
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

# Tier 0 is auto-started by Docker — but a restart policy only ever applies to a
# container that still EXISTS, and `docker compose down`, the documented
# maintenance path, removes them. On 2026-08-26 this script waited 300 s for a
# pihole nobody was going to create, then dispatched all three waves with no
# DNS, no reverse proxy and no VPN (#253).
#
# Only the missing ones are created, never the whole tier: `compose up -d`
# RECREATES a container whose definition drifted since it was started, so an
# unconditional call would cut DNS and the VPN at every boot that follows a
# pending pin bump — the same trap as a targeted deploy shipping the whole
# compose file.
#
# The list is the set of services carrying `restart: unless-stopped` in
# docker/compose.yaml, which is the source of truth; check it with
#   docker compose config --format json | jq -r \
#     '.services | to_entries[] | select(.value.restart=="unless-stopped") | .key'
# A service gaining or losing that policy without this list following would fail
# silently, so the stack-startup role asserts the two agree at deploy time — the
# comparison runs on the workstation, keeping jq and python3 off the boot path
# of the one script that has to work when nothing else does.
for svc in dnsproxy pihole socket-proxy traefik wg-easy; do
    docker inspect "$svc" >/dev/null 2>&1 || missing_tier0="${missing_tier0:-} $svc"
done
if [ -n "${missing_tier0:-}" ]; then
    log "tier 0 absent after a maintenance down — creating:${missing_tier0}"
    # shellcheck disable=SC2086  # deliberate word splitting: a service list
    up $missing_tier0
fi

# Block on DNS first — nothing else matters until the LAN can resolve names
# again. Generous timeout: at a cold start FTL reloads gravity and can take
# >2 min to pass its healthcheck; waiting here IS the point (DNS before the
# herd).
wait_healthy pihole 300

# Wave 1 — light services
# Dozzle belongs here: it depends on socket-proxy, which Docker already
# auto-started with Tier 0, and `compose up` honours that dependency anyway.
# IT-Tools is the cheapest member by an order of magnitude (4 MB, static nginx,
# no dependency of any kind), so it costs this wave nothing.
# Miniflux brings its own Postgres, which is why it is named before it here even
# though `compose up` would resolve the depends_on anyway — the wave lists what
# it starts. Together they are ~90 MB and the database is small enough that its
# healthcheck passes well inside this wave.
# Forgejo is here rather than in wave 3 despite a 120 s start_period: it is one
# Go binary on SQLite with no peer to wait for, and nothing gates on it — the
# start_period covers schema migrations, not a slow init this wave has to absorb.
up vaultwarden uptime-kuma searxng navidrome dozzle it-tools miniflux-db miniflux forgejo
wait_healthy vaultwarden 120

# Wave 2 — Nextcloud stack + Transmission (medium)
up nextcloud-db nextcloud-redis nextcloud nextcloud-cron nextcloud-notify-push transmission
wait_healthy nextcloud 240

# Wave 3 — Immich stack, Jellyfin, Netdata, Collabora, Calibre-Web (heavy; no
# gating after the last wave). Collabora belongs here rather than with
# Nextcloud: it takes ~80 s to serve, and nothing needs it until someone opens a
# document. Calibre-Web is here for the same reason — its s6 init takes ~90 s
# before the login page answers, and nothing in the stack depends on it.
up immich-redis immich-db immich-machine-learning immich-server jellyfin netdata collabora calibre-web

log "staged startup complete — all waves dispatched"
