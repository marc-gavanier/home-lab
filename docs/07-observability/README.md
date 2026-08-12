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

Netdata's history now survives a restart. Until 2026-07-27 its registry and its
metrics database sat in the container's writable layer with no volume, so every
recreate — every image bump, every configuration test — silently restarted the
history from zero. Both now live on `/mnt/data/services/netdata` (ADR-019).

### The daily posture check

`homelab-posture.sh` (daily, its own Kuma push monitor) asserts that the
container hardening is still in place — `cap_drop: ALL`, the exact capability
set per service, `read_only`, `no-new-privileges`, the AppArmor profile the
kernel actually applied, and netdata's three axes below (issue #33). Nothing
else would notice a drift: an image update whose entrypoint starts writing
somewhere new, or a container recreated without its `user:`, looks exactly like
a healthy stack from the outside.

The expected values are **generated from `docker/compose.yaml`** rather than
maintained by hand, so the check cannot drift from the file it checks: adding a
service or changing a capability updates the expectation. Verified by regressing
a real service (navidrome, `read_only` removed and recreated) and confirming the
report caught it.

**They are generated when the `observability` role templates the script, not
when the stack is deployed** — the running script holds a snapshot, it does not
read `compose.yaml`. So a hardening change needs `--tags deploy,observability`:
deploy only the stack and the check keeps yesterday's expectations and accuses a
container that is exactly right. Seen on 2026-07-28 after the wg-easy 15
migration dropped `SYS_MODULE` (ADR-020).

Because the expectations are generated per service, a container that legitimately
carries *fewer* hardening options is described accurately rather than needing an
exemption list: netdata and Collabora are the only two without
`no-new-privileges` (both run binaries that must gain privilege after `exec` —
setuid plugins and file capabilities respectively), and the check now asserts
they must **not** have it, catching an accidental addition just as readily as a
removal. Their reasons live in ADR-017 and ADR-021.

Separate from `Pi health` on purpose — a posture drift is not an outage, and it
should not compete with temperature and disk alerts for attention. It also
skips entirely while `/mnt/data` is locked, since the whole stack is
legitimately down in that window.

It also asserts that **every fail2ban jail configured is actually loaded**. A
jail with a broken filter or action is not reported as broken — fail2ban starts,
declares itself healthy, and protects one door less (measured: a single
misindented line made two jails vanish). The check compares `jail.local` against
`fail2ban-client status`, so it needs no list of its own to keep in sync.

The health report covers the complementary case at a five-minute cadence:
**expected containers that are not running at all**. `docker ps --filter
health=unhealthy` cannot see them, and the heal timer only resurrects containers
that *exited* — one that fails to come back was invisible to both (issue #34).

### Checking that Netdata itself is not lying

Netdata is the one service whose breakage is invisible from the outside: the
container stays `healthy` and the dashboard keeps answering while a plugin is
dead or the agent has silently fallen back to running as root. Any change to its
container — image bump, capability, AppArmor profile (ADR-017, ADR-018) — is
verified on three axes, never on status:

```bash
# 1. the agent must have dropped to uid 201; 0 means it gave up and runs as root
docker exec netdata awk '/^Uid:/' /proc/1/status

# 2. every plugin must be running — NETWORK-VIEWER's absence shows nowhere else
docker exec netdata ps -eo comm | sort

# 3. the chart contexts must still be there, per family
docker exec netdata curl -s http://127.0.0.1:19999/api/v3/contexts \
| python3 -c 'import sys,json,collections; c=json.load(sys.stdin)["contexts"]; \
p=collections.Counter(k.split(".")[0] for k in c); print(len(c), dict(p.most_common(8)))'
```

Reference on this host: uid **201**, **10** plugin processes (`NETWORK-VIEWER`,
`apps.plugin`, `debugfs.plugin`, `go.d.plugin`, `otel-plugin`,
`otel-signal-viewer`, `sd-jrnl.plugin`, `sd-unit.plugin`, `spawn-plugins`,
`spawn-setns`), **278** contexts — app 14, user 14, usergroup 14, cgroup 25,
systemd 7. AppArmor denials, if any, land in `dmesg | grep apparmor`.

## What is actually monitored

The authoritative inventory is the Kuma database itself; export it with
`ops/kuma-dump.sh` (read-only, WAL-safe). Broad shape:

### Reachability (Kuma active checks)

Real health endpoints rather than a bare `200 on /`, so a service that is up
but broken still trips: Nextcloud `/status.php`, Vaultwarden `/alive`,
Jellyfin `/health`, Navidrome `/ping`, SearXNG `/healthz`, Dozzle
`/healthcheck`, Calibre-Web `/login`, Collabora `/hosting/capabilities`, plus
IT-Tools, Immich, Transmission, wg-easy, Traefik on :443, Pi-hole on :53, an ICMP
ping of the Pi and the BitTorrent peer port.

Dozzle is where that rule stopped being a principle and became a measurement.
Stop its socket-proxy and it keeps serving `/` exactly as before — container
`Up`, page loading, and nothing in it — while `/healthcheck` turns 500
(ADR-023). The first version of that ADR pointed the monitor at `/`, which would
have stayed green through the one failure worth catching.

**Two services reach the limit of this pattern**, and it is worth naming them
rather than pretending the rule is universal.

**Collabora** is the first. Its
`/hosting/capabilities` endpoint is answered by the main process, so a monitor
on it stays green while no document can open — the failure mode described in
ADR-021. The real probe is a document conversion, which is a multipart POST and
does not fit a Kuma HTTP check. Two other things cover the gap instead: the
image's own healthcheck flips the container `unhealthy`, which the host health
report picks up within 10 minutes, and every deploy runs the conversion itself
and fails if it does not produce a PDF. A Kuma monitor on `/hosting/capabilities`
was added on 2026-08-05 — it had been described here for months without existing,
which the `ops/kuma-dump.sh` inventory exposed. It covers reachability and TLS
expiry; it is not the thing that proves editing works.

**Calibre-Web** is the second, and worse in one respect: its own healthcheck
lies. While measuring its capability requirements, two variants that could not
create `/app` caches or install `/config/processed_books/*` still reported
`healthy` and still served the login page — so neither `docker ps` nor an
unauthenticated HTTP monitor would have noticed. The web app and the library
fail independently, and proving the library is readable needs an authenticated
request, which a Kuma HTTP check cannot make without storing credentials. The
compose healthcheck therefore probes `/login` explicitly instead of trusting the
image's, and the monitor is understood to cover reachability only (ADR-025).

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
| Container missing   | an expected container is not running at all for > **10 min**   |
| systemd unit failed | anything in `systemctl --failed`                               |
| systemd restart loop | a unit stuck in `auto-restart` across two consecutive runs   |
| Expected unit down  | docker, containerd, fail2ban, claude-remote-control or wg-quick@wg0 not `active` |
| Timer last run      | a `homelab-*` timer whose triggered service did not end in `success` |

The last two close the gaps the rest of the stack cannot see: Netdata graphs
disk fill but has no notification path, and the heal timer only resurrects
containers that *exited* — one that stays up while failing its healthcheck
(notably `nextcloud-notify-push`, whose death silently kills mobile push)
would otherwise be invisible.

**The unit checks exist because a service can die for hours in silence** (issue
#52): `claude-remote-control` looped 1 112 times over 5h47 on 2026-07-27 while
work was going on continuously on this host, and `fail2ban` — sshd jail included
— was down for six minutes the same morning. Neither was noticed by anything but
a human happening to look.

`systemctl --failed` alone would have caught **neither**. A unit with
`Restart=on-failure` and `StartLimitIntervalSec=0` restarts forever and never
reaches the failed state: it sits in `activating/auto-restart` while `--failed`
stays empty. That is why the loop check looks at the sub-state instead, and
reports on the second consecutive sighting so a single legitimate restart does
not page.

Timer-driven services rest at `inactive/dead`, so their state says nothing — for
those the signal is the **result of the last run**, and the timer list is
enumerated rather than hard-coded so a new timer is covered without editing the
script.

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

### DDNS (push dead-man's switch)

`cloudflare-ddns.sh` keeps the `vpn.<domain>` A record pointing at the current
public IP, every 15 minutes. It pushes on **every** run, including the common
no-change one, and pushes `down` with a specific reason on each failure path
(no public IP, zone lookup, create, update). Heartbeat 1080 s — the 900 s period
plus a 180 s grace, the same period-plus-margin shape the other push monitors
use — with one retry, so a single transient Cloudflare error does not page.

**What it adds is narrower than it looks, and worth stating.** A DDNS run that
*fails* was already caught within 5 minutes: the host-health timer check
enumerates `homelab-*` timers and reports any whose last run did not end in
`success`, and `homelab-ddns.service` is one of them. An expired token, a
Cloudflare API change, a rate limit — all of those exit non-zero and were
covered, faster than this monitor's 36-minute worst case.

What was **not** covered is the timer that stops running at all. A disabled,
stopped or masked timer leaves the last recorded result at `success`
indefinitely, so the result check stays green over a job that no longer
happens. Silence is the only signal for that, and only a dead-man's switch
reads silence.

Neither check proves the published record is *correct*. Verifying that the A
record matches the real public IP needs a probe from outside the LAN, which is
a different piece of work. Note also that the WireGuard HTTP monitor does not
help here despite watching `vpn.<domain>`: Kuma resolves through Pi-hole, split
DNS pins that name to the LAN IP, so the monitor tests the internal path and is
structurally blind to the public record DDNS maintains.

The cost of a stale record is asymmetric. Remote access breaks immediately and
silently — a device off the LAN resolves the old address and the tunnel never
comes up. The offsite Pi also loses its link home, since its `Endpoint` is a
hostname WireGuard resolves once at bring-up; that failure *is* caught, but
indirectly, as a backup alarm up to a day later pointing at the wrong
subsystem.

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

## Reading the UFW log

`UFW BLOCK` lines are the closest thing this host has to an intrusion signal, and
they are readable — which was not true until 2026-08-02, when Transmission's
NAT-PMP was emitting 3 739 blocked packets a day, 86% of the log, and burying
everything else.

```bash
sudo journalctl --since "24 hours ago" -k | grep "UFW BLOCK" \
  | grep -oP 'SRC=\K[0-9.]+' | sort | uniq -c | sort -rn
```

What is normal, so that what is not stands out:

| Source        | Port | Why it is there                                              |
|---------------|------|--------------------------------------------------------------|
| `192.168.1.1` | —    | the router's IGMP multicast to 224.0.0.1. Constant, harmless |
| `10.8.0.x`    | 853  | a VPN client probing DoT. See below                          |
| LAN addresses | misc | occasional device chatter                                    |

**Do not re-investigate the port 853 entries.** They are Android's Private DNS in
automatic mode: the device probes its DNS server on 853, gets nothing, and falls
back to plain DNS on 53. Measured on 2026-08-02 — the same client had made 2 135
queries to Pi-hole over the previous 24 h, so filtering applies to it in full.
It is noise, not a bypass. Offering DoT on the Pi would silence it and encrypt
that hop, but that is a feature, not a fix.

**The baseline.** Over 24 h on 2026-08-02, after the Transmission fix: two packets
from the internet, both from a Meta range. fail2ban held zero failures and zero
bans across its three jails, and seven days of SSH logs contained no failed
attempt. Almost nothing hostile reaches this host, because almost nothing is
forwarded to it — see the amended attack-surface note in ADR-013.
