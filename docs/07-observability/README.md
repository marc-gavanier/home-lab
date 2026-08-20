# Observability

## Philosophy

Lightweight and actionable monitoring. We watch what requires human
intervention, nothing more. One alert = one action needed. Anything that is
merely interesting belongs on a dashboard, not in a notification.

## Stack

| Tool            | Role                                                                             |
|-----------------|----------------------------------------------------------------------------------|
| **Netdata**     | Real-time system metrics — forensic dashboard, **alerts reach nobody by design** |
| **Uptime Kuma** | Availability monitoring + alerting (Discord)                                     |

Netdata is not notification-free — that wording was wrong and it mattered. It
ships **57 stock alarms and runs them**. What it has no configured recipient,
so when one fires it executes its notifier, the notifier fails, and nothing
leaves the machine. That is not a hypothetical: `used_swap` sat CRITICAL for
5 days 19 hours in August 2026 and reached no one.

Leaving it that way is a deliberate choice, not an oversight. The stock alarms
are tuned for a generic server — the disk-backlog one alone would fire on every
nightly backup — so wiring them to Discord would produce exactly the noise this
stack refuses. **Any signal worth acting on gets added to `homelab-health.sh`
instead**, with a threshold chosen and justified here, and travels the push path
that demonstrably reaches a human.

So: use Netdata to investigate *after* Kuma has told you something is wrong, and
never treat a quiet Netdata as evidence that nothing is wrong.

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

### The hourly notify_push self-test

`homelab-notify-push.sh` (hourly, its own Kuma push monitor) runs Nextcloud's
`occ notify_push:self-test` and reports what it says. It exists because
notify_push is the one service here that fails without a symptom: when the push
server breaks, the desktop and mobile clients fall back to polling every 30s,
files keep syncing, nothing logs an error, and the only trace is a Pi quietly
doing more work than it should.

An HTTP monitor cannot stand in for it. The binary answers 404 on `/` and 400 on
`/test/cookie` whether or not it can reach Redis, load mount info from the
database, or be trusted as a reverse proxy — so a status-code check stays green
through exactly the failures worth catching. The six steps it verifies are the
ones that have actually broken here: the 403 through the DNS hairpin, the
untrusted proxy, the missing trusted domain
(`knowledge/runbooks/notify-push-troubleshooting.md`).

The failing step travels in the push message, so the Discord alert names it
instead of only saying something is wrong. The active connection count rides
along as context and never alarms — zero is the normal state when every client
is asleep.

### The daily disk-health report

`homelab-disk.sh` (daily at 07:00, its own Kuma push monitor) watches the 5 TB
drive: SMART early-warning counters, capacity, temperature, and the result of
the weekly short self-test started by `homelab-smart-test.timer`.

It exists because until 2026-08-15 nothing watched that disk at all — while the
offsite Pi, which holds only a *copy*, had a weekly SMART report and a monthly
self-test since July. **The copy was better monitored than the original.** The
only self-test ever run on the drive was a short one at 16 power-on hours; it
had reached 2363.

The overall `smartctl -H` verdict is deliberately not trusted on its own: it
stays PASSED until a drive is nearly dead. The counters that predict failure
early are checked individually — reallocated and pending sectors, offline
uncorrectable, end-to-end errors, and the interface CRC count that catches a bad
cable or bridge — and any of them leaving zero reports DOWN. The self-test
result is checked for failure *and* for staleness, comparing its power-on-hour
stamp against the drive's current one, so a silently dead timer surfaces instead
of leaving an eternally green result from a year ago.

Daily rather than the offsite's weekly, because this drive takes writes from 25
services continuously while the offsite one is read once a night. It is separate
from `homelab-health.sh` for the same reason the posture check is: a reallocated
sector is not an outage, it is a countdown, and it would be buried inside a
five-minute signal carrying CPU temperature.

**The self-test is short, not extended, and that was measured.** The extended
test was tried first: the drive announces 228 minutes for it, then returns
`Completed: read failure` at LBA 730424728 within seconds — twice, at the
identical LBA — while that sector and the 64 MiB around it read without error
from the host, every SMART counter stays at zero and dmesg is silent. The
WD50NDZW is a USB-native SMR drive whose bridge does not implement the extended
self-test; the verdict is canned, not a finding. Alerting on it would have meant
a permanently red monitor, which is worse than no monitor. The short test does
run correctly here, completing in the two minutes it announces.

Losing the surface scan matters less than it sounds, because the media is read
in full anyway: the nightly backup reads every file, and `local-maintenance.sh`
runs a rotating `restic check --read-data-subset` across the repository. A
sector that cannot be read surfaces there.

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

### Checking that the git mirror is still mirroring

The health push carries a `mirror ok` field, and it exists because a mirror that
stops mirroring is invisible everywhere else: the container is healthy, the web
UI answers, every page loads, and the repository it serves is simply frozen. On
2026-08-16 it had been 22 hours behind for a day before anyone noticed, killed by
the previous day's own `SECRET_KEY` fix, which left the remote address
undecryptable (issue #123).

The field reads `mirror ok`, or `mirror Nh overdue` with an alert once a sync is
more than an hour late. One hour of grace because a sync in flight leaves the
schedule seconds overdue, never an hour.

What it reads matters, and the obvious choice is wrong. `mirror.updated_unix`
moves on every **attempt**, so it looked current throughout the outage — four
hours in, it still carried a timestamp from that morning. Forgejo records no
last-successful-sync at all. `next_update_unix` is the real signal: it only
advances when a sync **completes**, so during that outage it sat two and a half
hours in the past and sinking.

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
`ops/kuma-dump.sh` (read-only, WAL-safe). Being authoritative is also why that
database is dumped nightly with `sqlite3 .backup` before the Restic snapshot
(`docs/06-backup/README.md`): Kuma v2 has no configuration export and every
monitor below was entered by hand in the web UI, so `kuma.db` is the only place
this inventory exists. Restoring it comes early in a recovery, not late — until
Kuma is back, none of the dead-man's switches below are watching. Broad shape:

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

**Nextcloud** is a third case, and a different one: the endpoint is right and the
*acceptance criterion* was too loose. `/status.php` returns **HTTP 200** with
`"maintenance":true`, and again with `"needsDbUpgrade":true` — precisely the two
states where Nextcloud is up, answering, and unusable, and precisely the states a
bad upgrade leaves behind. A monitor accepting `200-299` is green throughout.

The fix is a keyword match. **It is not a field on an `HTTP(s)` monitor** — in
Kuma, keyword matching is a separate *monitor type*, so the change is:

1. Monitor Type: `HTTP(s)` → **`HTTP(s) - Keyword`** (`type='keyword'` in the
   database). The Keyword field only appears once the type is changed.
2. Keyword:

   ```
   "maintenance":false,"needsDbUpgrade":false
   ```

Everything else stays — URL, `Accepted Status Codes` at `200-299`, and the
heartbeat history, since the monitor id does not change. The keyword is checked
*in addition to* the status code, not instead of it. Monitor #6 (Immich,
keyword `pong`) is a working example of the same type in this instance.

Kuma searches for the string literally, and the two fields are adjacent in the
payload — verified against the live response rather than the source:

```json
{"installed":true,"maintenance":false,"needsDbUpgrade":false,"version":"34.0.2.1",…}
```

**This lives only in `kuma.db`.** Kuma v2 has no configuration import, so a
rebuilt Kuma comes back with the monitor green and the keyword gone — which is
why the exact string is written here rather than left in the UI alone. Re-enter
it whenever monitor #1 is recreated, and treat that as part of restoring Kuma,
not as an optional refinement.

TLS certificate expiry notification is enabled on the HTTPS monitors. Traefik
renews automatically, so this is normally moot — it exists to catch a *silent*
renewal failure (ACME error, bad API token, rate limit), which would otherwise
only surface as an outage on expiry day.

That mechanism covered **15 of the 18 certificates**: it can only watch what an
HTTPS monitor polls, and three hostnames have no monitor. Since #157,
`homelab-health.sh` parses `acme.json` directly instead, so all 18 are watched
from the store Traefik actually writes — the push carries e.g. `certs 50d/18`,
naming the soonest expiry and the count. It alarms at **21 days**: Traefik renews
at 30, so the alarm means renewal has been failing for over a week — long enough
that one unreachable night is retried and never seen, short enough to act on
calmly.

Reading the log was not an option and that is worth recording: Traefik's log
filter is at WARN, and renewal lines are below it, so a log-based watch was
structurally blind. The parse is indifferent to *why* a renewal stopped.

An absent `acme.json` reports rather than skips — while `/mnt/data` is locked the
file is legitimately missing and the disk report already says so, but on a
mounted volume its absence means nothing is being watched at all (#177).

Since the public HTTP surface was closed (ADR-014, issue #12), these checks
run **from the Pi itself** — they prove the service works, not that it is
reachable from the internet. Nothing is meant to be reachable from the
internet except WireGuard.

### Host health (push, every 5 min)

`homelab-health.sh` pushes one monitor covering the host-level signals that
need a human:

| Signal               | Alarms when                                                                                        |
|----------------------|----------------------------------------------------------------------------------------------------|
| CPU temperature      | ≥ 80 °C (Pi 4 throttles at ~80-85 °C)                                                              |
| Undervoltage         | the `rpi_volt` hwmon alarm has latched                                                             |
| Pending reboot       | `/var/run/reboot-required` exists — auto-reboot is disabled by policy, so it waits on the operator |
| Security updates     | still pending after **48 h** (age-gated: unattended-upgrades runs daily)                           |
| Disk capacity        | `/` or `/mnt/data` ≥ **85 %** full                                                                 |
| Available memory     | `MemAvailable` < **800 MiB** on two consecutive runs (> 5 min)                                     |
| Swap occupancy       | ≥ **85 %** of the 4 GiB swap file — provisional threshold, see below                               |
| DNS upstream         | a cache-busting query gets no answer, or a non-answer rcode, on two consecutive runs (> 5 min)     |
| Unhealthy container  | a container fails its healthcheck for > **10 min**                                                 |
| Container missing    | an expected container is not running at all for > **10 min**                                       |
| systemd unit failed  | anything in `systemctl --failed`                                                                   |
| systemd restart loop | a unit stuck in `auto-restart` across two consecutive runs                                         |
| Expected unit down   | docker, containerd, fail2ban, claude-remote-control or wg-quick@wg0 not `active`                   |
| Timer last run       | a `homelab-*` timer whose triggered service did not end in `success`                               |
| Unit restarted       | a watched unit's `NRestarts` moved since the last run — held across a second beat                  |
| Git mirror stale     | the mirror has not **completed** a sync for > 4 h, or its state is unreadable twice running         |
| Certificate expiry   | the soonest of the 18 certificates is under **21 days**, unreadable, or `acme.json` is absent       |

The table is generated from nothing — keep it level with `problems+=(` in
`homelab-health.sh.j2` by hand. It drifted to eleven rows against twenty-one
conditions before #178, and the gap was made of exactly the two mechanisms added
most recently, which is the shape to expect next time.

**Why 800 MiB.** `MemAvailable` rather than free memory: the page cache is
reclaimable and `/mnt/data` churns hundreds of MB a night, so free memory reads
alarmingly low on a perfectly healthy Pi. The threshold was measured against 19
days of Netdata retention — the hourly minimum never went below 800 MiB, and the
lowest instantaneous dip (756 MiB) is absorbed by requiring two consecutive
runs, so it would have been silent throughout.

**Why the swap file was doubled before it could be alarmed on.** At 2 GiB it did
not sit at a high percentage — it ran *saturated*, mostly on cold pages
(Collabora's pre-forked kits, `immich-server`) that will never be touched again:

| Window                  | `used` peak            | `free` peak in the same bucket        |
|-------------------------|------------------------|---------------------------------------|
| 2026-08-09 → 2026-08-12 | 2047.996 MiB of 2048.0 | never above ~60 MiB, down to 1.76 MiB |

An occupancy that is already full in the steady state carries no information. A
threshold below it would have been red for six days with nothing to do about it,
the same trap that retired the extended SMART self-test; one above it could
never fire. So the file went to 4 GiB (2 GiB more on a disk with 3.6 TiB free,
no RAM, no CPU).

**What the new steady state should be — and why it is not 46 %.** A swap pinned
at its ceiling does not tell you how much it wanted, only that it wanted *at
least* 2 GiB. Halving the observed figure would be arithmetic on a truncated
value: the measurement was censored by the size of the file, so it cannot be
scaled. Reconstructing instead from the refill rate after the 2026-08-03 reset —
+500, +901, +205, +181, +66 MiB per night, driven by the 03:00 backup, a concave
curve — puts the real steady state around **2.1–2.3 GiB, i.e. 52–57 %** of the
new file. That is the number that makes occupancy mean something again.

It is worth being clear about what a full swap does and does not mean. It is
**not** evidence that the machine is short of memory — nothing here has ever
been OOM-killed. It means the kernel has nowhere left to evict *to*, which only
matters on the day available memory also runs short. The two lows have never
coincided; the alarm exists so that they are not discovered coinciding.

> **85 % is provisional.** It is the one threshold on this page not backed by
> measurement: every observation available was capped by the old 2 GiB size, so
> how much the kernel would have evicted with more room is an inference, not
> data. With `swappiness=10` it should stay conservative. Revisit after a few
> weeks of the new steady state — and if it settles above 85 %, raise the
> threshold rather than delete it.

Resizing the swap file is a **manual** operation: `creates:` guards it, so
changing `swap_size_mb` alone does nothing. The procedure, and the reason
`swapoff` deserves care, are in `ansible/roles/storage/tasks/swap.yml`.

**Why the DNS check queries a random name.** A dead DoH upstream is the failure
this stack was least equipped to notice, because everything that looks like it
should catch it is answering from cache or from the wrong side of the path:

| Would-be check         | Why it cannot see a dead upstream                                                                                                                                                             |
|------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Kuma `Pi-hole DNS`     | asks for the A record of the domain every 60 s, which FTL serves from cache — **10 084 queries over 7 days produced 2 upstream forwards**, both of them container restarts flushing the cache |
| `dnsproxy` healthcheck | there isn't one                                                                                                                                                                               |
| Pi-hole healthcheck    | uses `+norecurse` against a local name, so it cannot reach the upstream by construction                                                                                                       |

So if `dnsproxy` dies, Pi-hole keeps answering cached names, both containers read
green, and the LAN loses resolution for everything else — a failure `compose.yaml`
already documents and, until now, only prescribed an operational workaround for.

A random label under the domain cannot be served from cache, so it walks the
whole path. Verified rather than assumed: a probe query landed in the FTL
database as `status=2 forward=127.0.0.1#5053` and took 656 ms, where a cached
answer returns in ~0 ms with no forward at all.

**`NXDOMAIN` counts as success.** The question is whether the upstream *answered*,
not whether the name exists. `SERVFAIL`, `REFUSED` and silence are the failures —
they are what a dead `dnsproxy` produces. The alarm needs two consecutive
failures, the same gate as the memory check, because this probe deliberately
removes the cache from the path and so has no cushion of its own.

The last two close the gaps the rest of the stack cannot see: Netdata graphs
disk fill but delivers no notification, and the heal timer only resurrects
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
comes up.

The offsite Pi used to share that fate, and worse: its `Endpoint` is a hostname
`wg-quick` resolves once at bring-up, so a change in the home address partitioned
it *permanently*. The failure was caught, but indirectly — a backup alarm up to
a day later, pointing at the wrong subsystem — and since SSH to that host runs
through the same tunnel, the only repair left was a trip.

It now recovers on its own (#180). `offsite-wg-reresolve.timer` re-resolves the
name and calls `wg set` when the peer's handshake goes stale, bounded to under
four minutes. Two properties make it safe on a host nobody can reach: it fires
on the *handshake*, so a working tunnel is never touched, and it hands the name
to `wg set` rather than resolving itself, so a resolution failure aborts instead
of clearing an endpoint. It works at all only because that tunnel is split —
the offsite Pi resolves through its own LAN router, not through the link it is
repairing.

Detection follows the same asymmetry. The offsite health report now carries the
handshake age, but that message travels through the tunnel, so it can only
describe a tunnel that is *alive* — one that needed repairing, or one whose
handshake is ageing. A tunnel that is truly down is still read from silence, by
the dead-man's switch.

One caveat, measured rather than assumed. A deliberate break on the live tunnel
recovered in under ten seconds — by WireGuard's **roaming**, not by the timer,
which never reached its gate. A peer adopts the source address of any
authenticated packet it receives, so the homelab's next rekey taught the offsite
host where home was. That covers a broken endpoint while the home address is
unchanged. Whether it also covers an address *change* depends on whether the
parents' NAT accepts inbound packets from a source it has never seen, which is
unmeasured. The timer is the recovery path that does not depend on that answer;
it is not yet proven against the real failure. See ADR-029.

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
- journald: persistent but capped at `SystemMaxUse=500M`, via a drop-in
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
