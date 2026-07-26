# Observability

## Philosophy

Lightweight and actionable monitoring. We watch what requires human
intervention, nothing more. One alert = one action needed. Anything that is
merely interesting belongs on a dashboard, not in a notification.

## Stack

| Tool            | Role                                                            |
|-----------------|-----------------------------------------------------------------|
| **Netdata**     | Real-time system metrics — forensic dashboard, **no alerting**   |
| **Uptime Kuma** | Availability monitoring + alerting (Discord)                    |

Netdata is deliberately kept notification-free: its temperature/undervoltage
alarms would duplicate what `homelab-health.sh` already pushes, and the extra
config surface is not worth it on a RAM-limited Pi. Use it to investigate
*after* Kuma has told you something is wrong.

## What is actually monitored

The authoritative inventory is the Kuma database itself; export it with
`ops/kuma-dump.sh` (read-only, WAL-safe). Broad shape:

### Reachability (Kuma active checks)

Real health endpoints rather than a bare `200 on /`, so a service that is up
but broken still trips: Nextcloud `/status.php`, Vaultwarden `/alive`,
Jellyfin `/health`, Navidrome `/ping`, SearXNG `/healthz`, plus Immich,
Transmission, wg-easy, Traefik on :443, Pi-hole on :53, an ICMP ping of the Pi
and the BitTorrent peer port.

TLS certificate expiry notification is enabled on the HTTPS monitors. Traefik
renews automatically, so this is normally moot — it exists to catch a *silent*
renewal failure (ACME error, bad API token, rate limit), which would otherwise
only surface as an outage on expiry day.

Since the public HTTP surface was closed (ADR-014, issue #12), these checks
run **from the Pi itself** — they prove the service works, not that it is
reachable from the internet. Nothing is meant to be reachable from the
internet except WireGuard.

### Host health (push, every 5 min)

`homelab-health.sh` pushes one monitor covering the host-level signals that
need a human:

| Signal              | Alarms when                                                   |
|---------------------|---------------------------------------------------------------|
| CPU temperature     | ≥ 80 °C (Pi 4 throttles at ~80-85 °C)                         |
| Undervoltage        | the `rpi_volt` hwmon alarm has latched                        |
| Pending reboot      | `/var/run/reboot-required` exists — auto-reboot is disabled by policy, so it waits on the operator |
| Security updates    | still pending after **48 h** (age-gated: unattended-upgrades runs daily) |
| Disk capacity       | `/` or `/mnt/data` ≥ **85 %** full                            |
| Unhealthy container | a container fails its healthcheck for > **10 min**            |

The last two close the gaps the rest of the stack cannot see: Netdata graphs
disk fill but has no notification path, and the heal timer only resurrects
containers that *exited* — one that stays up while failing its healthcheck
(notably `nextcloud-notify-push`, whose death silently kills mobile push)
would otherwise be invisible.

That last alert only reaches containers that *declare* a healthcheck, so a
missing one is a blind spot rather than a green light. `socket-proxy` was one,
and its failure is invisible without help: freezing HAProxy inside it was
measured to leave Traefik answering 200 from its in-memory routes, so no page
breaks — Traefik has merely gone blind to container changes, and would come up
with an empty routing table whenever it next restarts. The check flips to
unhealthy ~105 s after the proxy stops answering. It probes `/_ping` through
the proxy rather than testing the port, since a HAProxy still listening but no
longer reaching the Docker socket would pass a port test.

A weekly Lynis run pushes its hardening score to a separate monitor.

### Backups (push dead-man's switches)

Every leg of the backup chain pushes on success, and the Kuma monitor alarms
on *silence* — so a job that never ran is caught, not just one that failed:
local backup (25 h window), local repository prune + check, offsite copy,
offsite repository check, and the offsite Pi's own disk/SMART health. See
`knowledge/runbooks/backup-monitoring.md`.

## Alerting

Discord webhook, wired to every monitor.

**Known limitations, accepted for now** (issue #13):

- **Nothing watches the watcher.** Kuma runs on the Pi, so a power loss, SD
  corruption or kernel panic takes the alerting down with the services: a total
  outage produces *silence*, not an alert. Closing this needs an off-Pi checker
  (the offsite Pi over the WireGuard tunnel, since there is no longer a public
  endpoint to poll externally).
- **Single channel.** A broken or muted Discord webhook means no alerts at all.
- **Notification storm.** Monitor dependencies are not chained (`parent` is
  null everywhere — Kuma v2's chaining is limited), so a single Pi or Traefik
  outage trips nearly every monitor at once. `resend_interval: 0` makes it a
  one-off burst rather than ongoing spam, so this is tolerated rather than
  worked around.

## Log retention

Both write sources are bounded so they can never fill the SD card:

- Docker: `json-file` driver, `max-size 10m` × `max-file 3`
  (`ansible/roles/docker/tasks/install.yml`).
- journald: persistent but capped at `SystemMaxUse=200M`, via a drop-in
  (`ansible/roles/base/tasks/logging.yml`). Persistence is deliberate — the
  boot logs are what the "unexplained poweroff" runbook reads.
