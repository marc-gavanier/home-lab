#!/usr/bin/env bash
set -uo pipefail

COMPOSE_DIR=/opt/homelab
DATA_MOUNT=/mnt/data

log() { logger -t homelab-startup "$*"; }
fatal() { log "FATAL: $*"; exit 1; }

cd "$COMPOSE_DIR" || fatal "$COMPOSE_DIR missing"

mountpoint -q "$DATA_MOUNT" || fatal "$DATA_MOUNT not mounted — aborting"
docker info >/dev/null 2>&1 || fatal "docker not responding — aborting"

mount_ts=$(systemctl show -p ActiveEnterTimestampMonotonic --value mnt-data.mount)
docker_ts=$(systemctl show -p ActiveEnterTimestampMonotonic --value docker.service)
if [ -z "$docker_ts" ] || [ -z "$mount_ts" ] || [ "$docker_ts" -lt "$mount_ts" ]; then
    fatal "dockerd started before $DATA_MOUNT was mounted (ghost store) — run: systemctl restart docker"
fi

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

up() {
    local out
    log "starting wave: $*"
    if ! out=$(docker compose up -d "$@" 2>&1); then
        log "compose up output: $out"
        fatal "compose up failed for: $*"
    fi
}

log "staged startup begin"

for svc in dnsproxy pihole socket-proxy traefik traefik-log-redactor wg-easy; do
    docker inspect "$svc" >/dev/null 2>&1 || missing_tier0="${missing_tier0:-} $svc"
done
if [ -n "${missing_tier0:-}" ]; then
    log "tier 0 absent after a maintenance down — creating:${missing_tier0}"
    # shellcheck disable=SC2086
    up $missing_tier0
fi

wait_healthy pihole 300

up vaultwarden uptime-kuma searxng navidrome dozzle it-tools miniflux-db miniflux forgejo
wait_healthy vaultwarden 120

up nextcloud-db nextcloud-redis nextcloud nextcloud-cron nextcloud-notify-push transmission
wait_healthy nextcloud 240

# [important]: splitting this wave bought nothing and cost up to 120 s per boot; do not re-propose it
up immich-redis immich-db immich-machine-learning immich-server jellyfin netdata collabora calibre-web prowlarr sonarr radarr

log "staged startup complete — all waves dispatched"
