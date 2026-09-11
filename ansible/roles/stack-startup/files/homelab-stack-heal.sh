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

# A running container is restarted only after this long CONTINUOUSLY unhealthy.
# 900 s is deliberately generous: calibre-web's s6 init takes ~90 s, collabora
# ~80 s, and a saturated startup wave stretches both. The point is to catch a
# service that is broken, not one that is slow.
UNHEALTHY_SECONDS=${UNHEALTHY_SECONDS:-900}
# At most one restart per container per hour — see the latch below.
UNHEALTHY_LATCH=${UNHEALTHY_LATCH:-3600}
STAMP_DIR=${STAMP_DIR:-/run/homelab/heal}

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
# So the count leaves the loop. `checked 0` and `checked 29 of 29 declared, 0
# restarted` are now different sentences, and homelab-health.sh asserts the run
# saw every service compose declares — the silence is no longer something a
# human has to interpret.
#
# The list is captured BEFORE the loop rather than piped into it: a piped
# `while` runs in a subshell and the counter would not survive it. The existing
# `[ -n "$name" ]` guard already absorbs the empty line a here-document makes
# from an empty list.
# `status=exited` alone cannot see two of the three ways a service ends up not
# running. A container that never started sits in `created`, and one whose
# filesystem the daemon could not remove sits in `dead`; neither is `exited`,
# and a service that was never created at all is invisible to any of the three.
# The first two are cheap to add here. The third is what `checked ... of ...
# declared` below is for.
#
# `created` and `dead` carry ExitCode 0, so the non-zero test that is right for
# `exited` would skip exactly the containers this line was added to catch. The
# state decides which question to ask.
exited=$(docker ps -a --filter "label=com.docker.compose.project" \
                      --filter "status=exited" \
                      --filter "status=created" \
                      --filter "status=dead" --format '{{.Names}}')

# Running-but-broken containers, asked of the DAEMON rather than by inspecting
# all twenty-nine. `health=unhealthy` is a Docker-side filter, so the normal case
# — nothing unhealthy — costs one command and returns nothing, and no container
# without a declared healthcheck can appear here at all. Measured 2026-09-12:
# 0.086 s against twenty-nine `docker inspect` calls the naive version would have
# made every two minutes.
unhealthy=$(docker ps -a --filter "label=com.docker.compose.project" \
                         --filter "health=unhealthy" --format '{{.Names}}')
checked=$(docker ps -a --filter "label=com.docker.compose.project" --format '{{.Names}}' | grep -c .)

# --- The floor has to be the DECLARED count, not one -------------------------
# `checked` counts what the daemon admits to knowing. On a daemon that has lost
# its store, or one answering from a half-built state, that number is small and
# truthful and useless: `checked 3, 0 restarted` passed the `>= 1` floor that
# homelab-health.sh applied when this counter was first taken out of the loop.
# Total blindness was caught; partial blindness was not.
#
# `docker compose config --services` is the only independent statement of how
# many there should be, and it costs 0.51-0.69 s measured on this Pi against a
# 120 s period. It is emitted even when it cannot be read, so a compose file
# that has gone missing shows as `of ?` rather than as nothing at all.
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
            # A container that RUNS and does not work was invisible here until
            # 2026-09-12. netdata spent thirty-five minutes up, answering its
            # API, with its go.d plugin killed and DISABLED — no docker charts,
            # no container alarms, and nothing in this loop to notice, because
            # `running` fell through to `continue`.
            #
            # Only a DECLARED healthcheck can say a running container is broken,
            # so a container without one is skipped rather than guessed at.
            h=$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{end}}' "$name" 2>/dev/null)
            [ "$h" = "unhealthy" ] || continue

            # How LONG it has been unhealthy, derived from the container's own
            # cadence rather than from a number written here: Docker counts
            # consecutive failures, and the container declares its interval.
            # A fixed streak threshold would mean 15 min for a 60 s interval and
            # 2.5 min for a 10 s one, which is how an eager restart gets shipped.
            streak=$(docker inspect -f '{{if .State.Health}}{{.State.Health.FailingStreak}}{{end}}' "$name" 2>/dev/null)
            iv=$(docker inspect -f '{{if .Config.Healthcheck}}{{.Config.Healthcheck.Interval.Seconds}}{{end}}' "$name" 2>/dev/null)
            iv=${iv%%.*}
            case "${streak:-x}" in ''|*[!0-9]*) continue ;; esac
            case "${iv:-x}" in ''|*[!0-9]*) continue ;; esac
            [ "$iv" -gt 0 ] || continue
            [ $(( streak * iv )) -ge "$UNHEALTHY_SECONDS" ] || continue

            # One restart per container per hour. Without the latch a container
            # that comes back unhealthy is restarted every two minutes forever,
            # which turns a degraded service into a flapping one and buries the
            # cause under its own recovery attempts.
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
    svc=$(docker inspect -f '{{index .Config.Labels "com.docker.compose.service"}}' "$name" 2>/dev/null)
    [ -n "$svc" ] || continue
    log "container $name (service $svc) $why — restarting"
    # `compose up -d` is a NO-OP on a container that is already running with the
    # declared configuration, so the unhealthy branch has to restart the
    # container itself. The exited branches keep `compose up` because there the
    # container has to be created.
    rc=0
    if [ "$state" = running ]; then
        docker restart "$name" >/dev/null 2>&1 || rc=1
    else
        docker compose up -d "$svc" >/dev/null 2>&1 || rc=1
    fi
    if [ "$rc" = 0 ]; then
        healed=$((healed + 1))
    else
        log "ERROR: failed to restart $svc"
    fi
done <<EOF
$exited
$unhealthy
EOF

log "checked $checked of $declared declared container(s), $healed restarted"
