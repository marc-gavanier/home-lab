#!/usr/bin/env bash
set -uo pipefail

UNHEALTHY_SECONDS=${UNHEALTHY_SECONDS:-900}
UNHEALTHY_LATCH=${UNHEALTHY_LATCH:-3600}
EXITED_LATCH=${EXITED_LATCH:-600}
HEALTH_INTERVAL_DEFAULT=${HEALTH_INTERVAL_DEFAULT:-30}
STAMP_DIR=${STAMP_DIR:-/run/homelab/heal}

COMPOSE_DIR=/opt/homelab

log() { logger -t homelab-heal "$*"; }

# [critical]: never heal while the staged startup is still dispatching its waves (#241)
if ! systemctl -q is-active homelab-stack-startup.service &&
   ! systemctl -q is-failed homelab-stack-startup.service; then
    exit 0
fi

cd "$COMPOSE_DIR" || { log "FATAL: $COMPOSE_DIR missing"; exit 1; }

exited=$(docker ps -a --filter "label=com.docker.compose.project" \
                      --filter "status=exited" \
                      --filter "status=created" \
                      --filter "status=dead" --format '{{.Names}}')

unhealthy=$(docker ps -a --filter "label=com.docker.compose.project" \
                         --filter "health=unhealthy" --format '{{.Names}}')
checked=$(docker ps -a --filter "label=com.docker.compose.project" --format '{{.Names}}' | grep -c .)

declared=$(docker compose config --services 2>/dev/null | grep -c .)
[ "$declared" -gt 0 ] || declared='?'
healed=0

while read -r name; do
    [ -n "$name" ] || continue
    state=$(docker inspect -f '{{.State.Status}}' "$name" 2>/dev/null) || continue
    case "$state" in
        exited)
            code=$(docker inspect -f '{{.State.ExitCode}}' "$name" 2>/dev/null) || continue
            [ "$code" = "0" ] && continue
            why="exited with code $code"
            ;;
        created|dead)
            why="is $state"
            ;;
        running)
            h=$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{end}}' "$name" 2>/dev/null)
            [ "$h" = "unhealthy" ] || continue

            streak=$(docker inspect -f '{{if .State.Health}}{{.State.Health.FailingStreak}}{{end}}' "$name" 2>/dev/null)
            iv=$(docker inspect -f '{{if .Config.Healthcheck}}{{.Config.Healthcheck.Interval.Seconds}}{{end}}' "$name" 2>/dev/null)
            iv=${iv%%.*}
            case "${streak:-x}" in ''|*[!0-9]*) continue ;; esac
            case "${iv:-x}" in
                ''|*[!0-9]*|0)
                    iv=$HEALTH_INTERVAL_DEFAULT
                    log "container $name declares no healthcheck interval — aging its $streak failed probes at the daemon default of ${iv}s"
                    ;;
            esac
            [ $(( streak * iv )) -ge "$UNHEALTHY_SECONDS" ] || continue

            stamp="$STAMP_DIR/unhealthy-$name"
            if [ -f "$stamp" ]; then
                last=$(stat -c %Y "$stamp" 2>/dev/null || echo 0)
                if [ $(( $(date +%s) - last )) -lt "$UNHEALTHY_LATCH" ]; then
                    log "container $name unhealthy for $(( streak * iv ))s — already restarted within the last $((UNHEALTHY_LATCH / 60)) min, leaving it alone"
                    continue
                fi
            fi
            mkdir -p "$STAMP_DIR" 2>/dev/null
            : > "$stamp"
            why="has been unhealthy for $(( streak * iv ))s ($streak failed probes at ${iv}s)"
            ;;
        *)
            continue
            ;;
    esac
    if [ "$state" != running ]; then
        stamp="$STAMP_DIR/exited-$name"
        if [ -f "$stamp" ]; then
            last=$(stat -c %Y "$stamp" 2>/dev/null || echo 0)
            if [ $(( $(date +%s) - last )) -lt "$EXITED_LATCH" ]; then
                log "container $name $why — already restarted within the last $((EXITED_LATCH / 60)) min, leaving it alone"
                continue
            fi
        fi
        mkdir -p "$STAMP_DIR" 2>/dev/null
        : > "$stamp"
    fi
    svc=$(docker inspect -f '{{index .Config.Labels "com.docker.compose.service"}}' "$name" 2>/dev/null)
    [ -n "$svc" ] || continue
    log "container $name (service $svc) $why — restarting"
    rc=0
    if [ "$state" = running ]; then
        docker restart "$name" >/dev/null 2>&1 || rc=1
    else
        docker compose up -d "$svc" >/dev/null 2>&1 || rc=1
    fi
    if [ "$rc" = 0 ]; then
        healed=$((healed + 1))
        if [ "$svc" = pihole ]; then
            if docker compose up -d --force-recreate dnsproxy >/dev/null 2>&1; then
                log "re-attached dnsproxy to pihole's new network namespace"
            else
                log "ERROR: failed to re-attach dnsproxy after healing pihole"
                rc=1
            fi
        fi
    else
        log "ERROR: failed to restart $svc"
    fi
done <<EOF
$exited
$unhealthy
EOF

log "checked $checked of $declared declared container(s), $healed restarted"
