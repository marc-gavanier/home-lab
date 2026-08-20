# ADR-007: Staged container startup, gated on the manual LUKS unlock

**Date**: 2026-07-05
**Status**: Accepted
**Deciders**: Marc Gavanier

## Context

Two incidents (2026-06-23 and 2026-07-04) exposed the same pair of flaws in how
the stack came up after a reboot or power cut:

1. **Thundering herd**: all 19 containers carried `restart: unless-stopped`, so
   the Docker daemon restarted them simultaneously. On the 4 GB Pi the load
   spiked to ~22 and Pi-hole — the LAN's DNS resolver — took ~16 minutes to
   become healthy. Every reboot meant a quarter-hour without internet for the
   whole house.
2. **Ghost store**: Docker's data-root lives on the LUKS-encrypted HDD
   (`/mnt/data/docker`), unlocked manually via `homelab-unlock`. Nothing
   actually prevented `dockerd` from starting *before* the mount:
   `RequiresMountsFor=/mnt/data` was a **no-op** because, with no fstab entry,
   no `mnt-data.mount` unit exists at boot for it to bind to — systemd resolved
   the dependency against `/` instead. Worse, `docker.socket` stayed enabled,
   so a mere `docker ps` before the unlock woke the daemon, which then
   initialised an **empty "ghost" store on the SD card under the mount point**.
   The same path-resolution hole applied to the fstab swap entry: the system
   had been silently swapping on a ghost swapfile on the SD card since
   provisioning (wear + slow).

## Decision

Make the manual unlock the **single entry point** for everything that needs the
encrypted disk, and stage the containers behind it — all automated by the
`storage`, `docker` and `stack-startup` Ansible roles:

1. **Static units instead of path magic.** `mnt-data.mount` and
   `mnt-data-swapfile.swap` are real unit files (never started at boot; the
   mount is pulled by `homelab-services.target`, the swap binds to the mount).
   `RequiresMountsFor=/mnt/data` on `docker.service` now actually blocks a
   pre-mount start. `docker.service` **and** `docker.socket` are disabled at
   boot; the target pulls them in at unlock time.
2. **Restart-policy tiering.** Tier 0 (`traefik`, `pihole`, `wg-easy`, `dnsproxy`,
   `socket-proxy`) keeps
   `restart: unless-stopped` and starts with the daemon, so LAN DNS is back in
   ~1–3 minutes. Everything else is `restart: "no"` — *not* `on-failure`,
   because at daemon start Docker resurrects any container whose last exit code
   is non-zero, and a reboot/power cut kills them all with 137/143/255: the
   herd came right back (observed in the 2026-07-05 reboot test).
3. **Health-gated waves.** A oneshot orchestrator
   (`homelab-stack-startup.service`, in the target) waits for Pi-hole, then
   starts light services → the Nextcloud stack → the heavy tier
   (Immich/Jellyfin/Netdata), gating each wave on the previous one's
   healthcheck. It is **fail-fast**: a ghost store (dockerd older than the
   mount, compared via systemd monotonic timestamps), a missing container or a
   failed `compose up` aborts loudly in the journal instead of dispatching
   waves into the void.
4. **Crash recovery by timer.** Since `restart: "no"` also disables Docker's
   crash restarts, `homelab-stack-heal.timer` (every 2 min while the target is
   up) restarts any compose container found exited with a non-zero code.

## Consequences

### Pros
- **DNS first**: the LAN resolves again ~1–3 min after the unlock, instead of
  ~16 min after boot; the heavy tier warms up last.
- **Ghost store impossible**: the daemon cannot start without the real
  data-root mounted, whatever pokes the Docker CLI — and if a regression ever
  reintroduces one, the orchestrator refuses to start the stack and says why.
- **Deterministic**: Docker never starts a non-Tier-0 container on its own;
  the orchestrator is the only path, whatever the previous shutdown looked like.
- **Swap actually on the HDD**, ending silent SD-card wear.

### Cons
- **Startup is asynchronous**: `homelab-unlock` returns immediately
  (`--no-block`) while the waves run ~5–8 min in the background; the only
  progress surface is `journalctl -t homelab-startup -b -f`.
- **Manual stops get healed**: the heal timer cannot tell a crash (exit 137)
  from `docker stop` (often 137/143 too). Maintenance must use
  `docker compose down <svc>` or stop the timer.
- **A crashed service can stay down up to 2 min** (timer cadence) instead of
  being restarted immediately by the daemon.

## Alternatives Considered

- **`restart: on-failure` for non-Tier-0**: first implementation; rejected
  after the reboot test — the daemon restarts every uncleanly-killed container
  at startup, defeating the tiering exactly when it matters (power cut).
- **Graceful `compose stop` at shutdown** (so containers exit 0 and
  `on-failure` stays quiet): rejected — covers clean reboots only, not power
  cuts, which are the actual failure mode.
- **One systemd unit per container**: maximum control, but duplicates what
  Compose already knows (dependencies, healthchecks) and bloats the roles.
- **`autoheal`-style container** watching healthchecks: another always-on
  container with a Docker-socket mount (attack surface) to do what a 20-line
  timer script does under journald.

See also: `knowledge/runbooks/boot-and-unlock.md`,
[ADR-006](ADR-006-remote-kill-switch.md) (the kill switch powers off into this
boot path).
