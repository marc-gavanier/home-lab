# Observability

What watches the lab, what each alert means, and how the pieces fit. One alert = one action
needed; anything merely interesting belongs on a dashboard.

## Stack

| Tool                 | Role                                                                                                   |
|----------------------|--------------------------------------------------------------------------------------------------------|
| **Netdata**          | Metrics, forensic dashboard, six **curated** alarms. Its stock alarms (59 at last count) reach nobody |
| **Uptime Kuma**      | Availability checks, push monitors, and the only alerting channel (Discord)                           |
| **homelab-health**   | Host checks every 5 min, pushed to `Pi health` and `Pi pending action`                                 |
| **goss**             | Declared assertions, run by the health, posture, backup and offsite scripts                           |
| **Lynis**            | Weekly audit, pushed to its own monitor                                                                |

Use Netdata to investigate after Kuma has said something is wrong. A quiet Netdata is not evidence
that nothing is wrong.

## Netdata alarms, and how they reach Kuma

- Netdata's stock alarms (count them from `/api/v1/alarms`) address `silent`, `sysadmin` and
  `root`; none is routed. They are tuned for a generic server and would be noise here.
- Curated alarms live in the repository under `health.d/`, each with a threshold justified on this
  page (ADR-030). They are also `to: silent`: Netdata notifies nobody.
- `homelab-netdata-kuma.sh` (every 5 min) reads them and pushes each into the Kuma monitor of its
  group — six alarms, two monitors. The notification channel is configured only in Kuma.
- It pushes on **every** run, whatever the state, so each curated monitor is also a dead-man's
  switch: a dead netdata, stopped adapter or absent host turns it red. (A Kuma push monitor with no
  beat reports "No heartbeat in the time window", so pushing only on transitions would not work.)
- A curated alarm replaces a check in `homelab-health.sh` only after it has been observed firing;
  until then both run.
- Metric history lives on `/mnt/data/services/netdata` and survives recreation (ADR-019).

**Startup grace (the one exception to "whatever the state").** A freshly started netdata answers
HTTP 200 with an empty `alarms` object: 25 s to ~4 min on a warm restart; on a cold boot its API
first answered ~301 s after start and the first verdict came at 779 s. The adapter therefore uses a
**1200 s** grace based on netdata's own start time:

| netdata answer                    | netdata up < 1200 s                                    | netdata up ≥ 1200 s |
|-----------------------------------|--------------------------------------------------------|---------------------|
| empty `alarms`                    | UP, message names the window                           | DOWN, with an actionable message |
| unreachable                       | UP only if docker reports the container running and younger than the grace | DOWN |
| container stopped or absent       | DOWN                                                   | DOWN                |

The grace defers the switch, never disarms it. A netdata restarting faster than the grace is caught
by `netdata-health-engine-has-verdicts` in the posture spec.

## One monitor per action, not per condition

Conditions that send you to the same place share a monitor:

| Monitor                  | What it carries                                                                                                             | Fed by                              | What you would do        |
|--------------------------|-----------------------------------------------------------------------------------------------------------------------------|-------------------------------------|--------------------------|
| **Pi health**            | `/` and `/mnt/data` usage, undervoltage, DNS, mirror, certificate store, failed units and timers, restart loops, crash-heal | `homelab-health.sh`                 | look at the host         |
| **Pi resources**         | temperature, undervoltage, memory, swap                                                                                     | curated alarms via the Kuma adapter | look at load             |
| **Pi disk health**       | `/mnt/data` usage, SMART, drive temperature, pending sectors, ext4 state                                                    | `homelab-disk.sh`                   | look at the disk         |
| **Pi pending action**    | reboot pending, services on replaced libraries, journal skew under pressure, security updates, certificate expiry           | `homelab-health.sh`                 | schedule an intervention |
| **Netdata — containers** | containers down, containers unhealthy                                                                                       | curated alarms via the Kuma adapter | look at the stack        |

- Few monitors keeps the hand-built Kuma surface flat.
- **Group by lifetime, not subject.** A condition waiting for a human stays red for days; folded in
  with acute checks it mutes them. That is why `Pi pending action` exists.
- **Grouping needs resend.** Kuma notifies only on a state change, so a second condition inside an
  already-red group reaches nobody. Set "Resend Notification if Down X times" on each (values in
  [uptime-kuma.md](../05-services/uptime-kuma.md)).

## Evidence that outlives the run

Rule: **every periodic job must leave a distinguishable result in a store that outlives its own
period.** A green monitor says the job ran, not what it did.

| Evidence                                           | Jobs                                            | Retention                           |
|----------------------------------------------------|-------------------------------------------------|-------------------------------------|
| A Kuma push monitor whose message carries readings | most jobs                                       | per-monitor row budget              |
| The journal alone                                  | `homelab-stack-heal`, `offsite-wg-reresolve`    | ~59 days at saturation              |
| Nothing at all                                     | `homelab-image-retention` (monthly)             | —                                   |

Enumerate the timers, not the monitors — a job with no channel never shows up in a list of
channels:

```bash
systemctl list-timers 'homelab-*'
systemctl list-timers 'offsite-*'
```

Messages carry readings, e.g. `dumps ok (19 checks), snapshot c8f63e2a`, `hardening index 73
(best 73)`, `disk 17%, hdd 49C (peak 54C), pending 2`.

**Prune + check.** The weekly job re-reads one twelfth of the repository's bytes in the first week
of the month and checks metadata otherwise. It is the only step that reads backed-up bytes back.

| Mode            | Message                                           |
|-----------------|---------------------------------------------------|
| deep            | `prune ok, deep check re-read data subset 8/12`   |
| metadata        | `prune ok, metadata check only (no data re-read)` |
| mode not passed | `prune and check completed, mode not reported`    |

**Missed deep check.** resticprofile picks the mode from the day of the month, so a host off during
the first week silently degrades that month to metadata only. `restic-deep-check-not-stale` reads
Kuma's heartbeat history for the last "data subset re-read" beat and fails past **45 days** (healthy
gaps are 24–37 days). It works because this monitor is weekly and keeps all its beats; do not count
on Kuma's `keepDataPeriodDays` (180): raw beats are pruned by a per-monitor row budget (~45.6 h for
an ordinary beat on the 5-minute health monitor).

**Access log.** The redacted access log (ADR-034) is the only trace the offsite host leaves here,
and it writes once a week. The log carries its own `logging:` block, 10 x 20 MB (~32 days of
capacity at ~6 MB/day). The ring belongs to the container and restarts empty on every recreation,
so a weekly writer is answerable only once the redactor has run for more than a week. The
`window=48h` of `traefik-access-log-carries-no-credential` is met by its `seen>=1` floor.

## goss — where the assertions live

ADR-032 moved assertions from shell into declared specs:

| Spec                          | Host    | Run by                                                  | When                              |
|-------------------------------|---------|---------------------------------------------------------|-----------------------------------|
| `/etc/goss/posture.yaml`      | homelab | `homelab-posture.sh`                                    | daily, 11:00 + up to 10 min jitter |
| `/etc/goss/units.yaml`        | homelab | `homelab-health.sh`                                     | every 5 min                       |
| `/etc/goss/backup-dumps.yaml` | homelab | a resticprofile hook, result read by `backup-notify.sh` | nightly, inside the 03:00 backup  |
| `/etc/goss/offsite-health.yaml` | offsite | `offsite-health.sh`                                   | daily, 08:00 + jitter             |

- Binary: `/usr/local/bin/goss` on both hosts. Specs are not world-readable: use `sudo`.
- `sudo goss -g /etc/goss/*.yaml` expands the glob unprivileged and matches nothing — use `sudo sh -c`.
- Never write a check count down; specs grow with the stack. Read `1..N` from the machine (the TAP
  line count follows declared attributes, not assertions, so it cannot be derived):

```bash
for h in homelab offsite; do
  ssh $h 'sudo sh -c "for f in /etc/goss/*.yaml; do
    printf \"%s %s\\n\" \"$f\" \"$(goss -g $f validate --format tap | grep -m1 \"^1\\.\\.\")\"
  done"'
done
```

Run one by hand on the homelab (the offsite host has only `offsite-health.yaml`, so these return
"file does not exist" there):

```bash
sudo goss -g /etc/goss/posture.yaml validate
sudo goss -g /etc/goss/posture.yaml validate --format tap
```

The first ends in `Count: N, Failed: 0`; the second is what the scripts consume.

**`backup-dumps.yaml` fails by hand — that is normal.** The dump directory exists only during a
backup run (ADR-031), so outside one it fails one assertion per dump (`dump-nextcloud-present`,
`dump-miniflux-complete`, …). Count the dump assertions with
`grep -cE '^  dump-' /etc/goss/backup-dumps.yaml`. The spec is only meaningful as the hook.

**Consumers check the plan line.** goss failing to start and goss finding nothing both print no
`not ok`. Every consumer checks, in order: spec readable → binary present → a `1..N` plan line with
N > 0, and only then counts failures. Any new consumer must do the same.

**Never edit `/etc/goss/*.yaml` on the host** — the next deploy overwrites them:

| Spec                  | Template                                                     | Deployed by                                   |
|-----------------------|--------------------------------------------------------------|-----------------------------------------------|
| `posture.yaml`        | `roles/observability/templates/goss-posture.yaml.j2`         | any tagged run (`tags: always`)               |
| `units.yaml`          | `roles/observability/templates/goss-units.yaml.j2`           | `--tags observability`                        |
| `backup-dumps.yaml`   | `roles/deploy/templates/goss-backup-dumps.yaml.j2`           | `--tags deploy`                               |
| `offsite-health.yaml` | `roles/offsite-backup/templates/goss-offsite-health.yaml.j2` | `playbooks/offsite.yml --tags offsite-backup` |

## The daily posture check

`homelab-posture.sh` runs `posture.yaml` daily and pushes `Pi security posture`. It asserts:

- container hardening: `cap_drop: ALL`, the exact capability set per service, `read_only`,
  `no-new-privileges`, the AppArmor profile the kernel applied, and netdata's three axes (below);
- netdata and Collabora must **not** have `no-new-privileges` (setuid plugins, file capabilities —
  ADR-018, ADR-021), so an accidental addition is caught too;
- every fail2ban jail in `jail.local` is loaded (`fail2ban-client status`) — a broken jail vanishes
  silently while fail2ban reports healthy;
- `every-declared-service-has-a-container` — an expected container gone from the engine;
- every `homelab-*` control timer is `enabled` and `active`.

How it behaves:

- Expectations are generated from `docker/compose.yaml` when the `observability` role templates
  the spec — a snapshot, not a live read. The render is `tags: always`, so any tagged run
  (`--tags deploy` included) refreshes it (see `container-config-changes.md`).
- Separate from `Pi health`: a drift is not an outage.
- Skips entirely while `/mnt/data` is locked.

## The hourly notify_push self-test

`homelab-notify-push.sh` (hourly, its own push monitor `Nextcloud notify_push`) runs
`occ notify_push:self-test` and pushes the result.

- Why: when notify_push breaks, clients fall back to polling every 30s and nothing else notices.
  An HTTP check cannot help: the binary answers 404 on `/` and 400 on `/test/cookie` either way.
- The failing step is in the push message, so the alert names it. Past failures are in
  `knowledge/runbooks/notify-push-troubleshooting.md`.
- The active connection count is context only; zero is normal.
- It also reads `core lastcron` and goes DOWN when `cron.php` has not completed for more than
  **3600 s**, or the value is unreadable. `nextcloud-cron` can stay Up without running jobs, and jobs
  run every 5 min.

## The daily disk-health report

`homelab-disk.sh` (daily at 07:00, push monitor `Pi disk health`) watches the 5 TB drive: SMART
counters, capacity, temperature, and the weekly **extended** self-test started by
`homelab-smart-test.timer`.

| Check                                     | Alarms when                                                           |
|-------------------------------------------|-----------------------------------------------------------------------|
| Reallocated, offline uncorrectable, end-to-end errors, interface CRC | any leaves zero                        |
| `Current_Pending_Sector`                  | it **rises** since the last run, or the last completed self-test was not clean |
| Newest self-test entry                    | status unknown (abort and interruption are reported, not alarmed)    |
| Last completed self-test                  | failed, or stale by power-on hours                                   |

- `smartctl -H` alone is not trusted: it stays PASSED until a drive is nearly dead.
- A non-zero pending count with a clean full-surface scan behind it is green ("weak sectors, act at
  leisure"). Only a write retires a pending sector; reads walk over it.
- The log is read twice: the newest entry (what the last run did) and the newest `Completed` entry
  (the last verdict). Staleness is measured on the completed one, so repeated aborts cannot reset it.
- A `Completed: read failure` from the extended test is a true positive, not a bridge artefact —
  host reads can succeed through retries while a sector is failing. Do not switch to `-t short`.
- The extended test is the only control that reads cold bytes; it runs in the background, no
  maintenance window needed.
- Repair of a pending sector: rewrite the affected file in place (`dd conv=notrunc` onto the same
  extents) after verifying the replacement bytes, then read the LBA back with `O_DIRECT`.
- Separate from `Pi health`: a reallocated sector is a countdown, not an outage.

## Git mirror

The health push carries `mirror ok`, or `mirror Nh overdue`, alerting once a sync is more than an
hour late. A frozen mirror looks healthy everywhere else.

- It reads `next_update_unix`, which only advances when a sync **completes**. `mirror.updated_unix`
  moves on every attempt and hides an outage.
- The interval is **8 h** and `MIRROR_GRACE` is 3600 s, so the earliest alarm is ~9 h after the last
  good sync. Faster detection means a shorter mirror interval.

## Checking that Netdata itself is not lying

Netdata's container stays `healthy` while a plugin is dead or the agent runs as root. After any
change to its container (image, capability, AppArmor — ADR-017, ADR-018), check three axes:

```bash
docker exec netdata awk '/^Uid:/' /proc/1/status
docker exec netdata ps -eo comm | sort
docker exec netdata curl -s http://127.0.0.1:19999/api/v3/contexts \
| python3 -c 'import sys,json,collections; c=json.load(sys.stdin)["contexts"]; \
p=collections.Counter(k.split(".")[0] for k in c); print(len(c), dict(p.most_common(8)))'
```

| Axis        | Expected                                                                                                   |
|-------------|------------------------------------------------------------------------------------------------------------|
| 1. uid      | **201** (0 means it fell back to root)                                                                     |
| 2. plugins  | **11**: `NETWORK-VIEWER`, `apps.plugin`, `debugfs.plugin`, `go.d.plugin`, `netflow-plugin`, `otel-plugin`, `scripts.d.plugin`, `sd-jrnl.plugin`, `sd-unit.plugin`, `spawn-plugins`, `spawn-setns` |
| 3. contexts | **383** — netdata 137, system 43, ipv6 26, cgroup 25, ipv4 24, mem 23, app 14, user 14                      |

AppArmor denials land in `dmesg | grep apparmor`. Re-measure these values whenever you change the
container and update this table in the same commit; a stale baseline makes the check useless.

## What is actually monitored

The authoritative inventory is the Kuma database: export it with `ops/kuma-dump.sh` (read-only,
WAL-safe). Every monitor was entered by hand, so `kuma.db` is dumped nightly with `sqlite3 .backup`
before the Restic snapshot (`docs/06-backup/README.md`). Restore it early in a recovery: until Kuma
is back, no dead-man's switch is watching. Monitor list and settings:
[uptime-kuma.md](../05-services/uptime-kuma.md#monitors-configured).

### Reachability (Kuma active checks)

- Real health endpoints, not `200 on /`: Nextcloud `/status.php`, Vaultwarden `/alive`, Jellyfin
  `/health`, Navidrome `/ping`, SearXNG `/healthz`, Dozzle `/healthcheck` (ADR-023), Calibre-Web
  `/login`, Collabora `/hosting/capabilities`, Transmission `/transmission/web/` (authenticated,
  keyword), plus IT-Tools, Immich, wg-easy, Traefik on :443, Pi-hole on :53, an ICMP ping of the Pi
  and the BitTorrent peer port.
- Checks run from the Pi itself (ADR-014): they prove the service works, not that it is reachable
  from the internet.

Limits of the pattern:

- **Collabora**: the endpoint stays green while no document opens. Covered instead by the image
  healthcheck (→ `homelab_container_unhealthy` after 10 min, pushed on the adapter's next 5-min
  tick: 15 min worst case) and by the conversion every deploy runs. The monitor covers reachability
  and TLS expiry (ADR-021).
- **Calibre-Web**: its own healthcheck can report `healthy` with a broken library. The compose
  healthcheck probes `/login`, and the monitor covers reachability only (ADR-025).
- **Nextcloud**: `/status.php` returns 200 with `"maintenance":true` or `"needsDbUpgrade":true`, so
  the monitor is a keyword check.

**Nextcloud keyword monitor (monitor #1).** It lives only in `kuma.db`; re-enter it whenever the
monitor is recreated, as part of restoring Kuma:

1. Monitor Type: `HTTP(s)` → **`HTTP(s) - Keyword`** (`type='keyword'` in the database). The
   Keyword field appears only after the type change.
2. Keyword:

   ```
   "maintenance":false,"needsDbUpgrade":false
   ```

3. Keep the URL, `Accepted Status Codes` at `200-299` and the monitor id. The keyword is checked in
   addition to the status code. Monitor #6 (Immich, keyword `pong`) is a working example.

Kuma matches the string literally; the two fields are adjacent in the live payload:

```json
{"installed":true,"maintenance":false,"needsDbUpgrade":false,"version":"34.0.2.1",…}
```

**Certificates.**

- Kuma TLS-expiry notification is on for 15 of the 18 active HTTPS monitors (off for Prowlarr,
  Sonarr, Radarr); three hostnames have no HTTPS monitor. So Kuma sees 15 of 21 certificates.
- `homelab-health.sh` parses `acme.json` directly and watches all **21**. The push carries e.g.
  `certs 31d/21` (soonest expiry, count).
- It alarms under **21 days**: Traefik renews at 30, so the alarm means renewal has failed for over
  a week. Traefik's WARN log level hides renewal lines, so the log cannot be used.
- An absent `acme.json` alarms on a mounted volume (while `/mnt/data` is locked the disk report
  already says so).

### Host health (push, every 5 min)

`homelab-health.sh` pushes `Pi health` (acute) and `Pi pending action` (waits on the operator). The
third column says what actually evaluates each condition:

| Signal               | Alarms when                                                                                                                                                        | Watched by                            |
|----------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------|
| CPU temperature      | ≥ 80 °C (Pi 4 throttles at ~80-85 °C)                                                                                                                              | netdata `homelab-cputemp`             |
| Undervoltage         | the `rpi_volt` hwmon alarm has latched                                                                                                                             | netdata + the script ¹                |
| Pending reboot       | `/var/run/reboot-required` exists — auto-reboot is disabled by policy, so it waits on the operator                                                                 | `homelab-health.sh`                   |
| Stale libraries      | after a package change since boot, `needrestart` still lists services running replaced libraries — waits on a reboot                                               | `homelab-health.sh`                   |
| Boot record at risk  | this boot's journal starts > 10 min before the machine did and the journal is ≥ **80 %** of its cap, or the kernel's first boot line is already gone               | `homelab-health.sh`                   |
| Security updates     | still pending after **48 h** (age-gated: unattended-upgrades runs daily)                                                                                           | `homelab-health.sh`                   |
| Disk capacity        | `/` or `/mnt/data` ≥ **85 %** full                                                                                                                                 | `homelab-health.sh`                   |
| Available memory     | `MemAvailable` < **800 MiB** sustained over a **5 min** window (`lookup: max -5m`)                                                                                 | netdata `homelab-memory`              |
| Swap occupancy       | > **85 %** of the 4 GiB swap file — provisional threshold, see below                                                                                               | netdata `homelab-swap`                |
| DNS upstream         | a cache-busting query gets no answer, or a non-answer rcode, for **240 s** (shared gate)                                                                           | `homelab-health.sh`                   |
| Unhealthy container  | a container fails its healthcheck for > **10 min**                                                                                                                 | netdata `homelab-container-unhealthy` |
| Container stopped    | a container present in the engine is not running for > **10 min**                                                                                                  | netdata `homelab-container-down`      |
| Container absent     | an expected container is **gone from the engine entirely** — up to **24 h**, this is a daily check                                                                 | goss `posture.yaml` ³                 |
| systemd unit failed  | anything in `systemctl --failed`                                                                                                                                   | goss `units.yaml` ²                   |
| systemd restart loop | a unit stuck in `auto-restart` for **240 s** (shared gate)                                                                                                         | `homelab-health.sh`                   |
| Expected unit down   | docker, containerd, fail2ban, ssh, claude-remote-control or wg-quick@wg0 not `active`                                                                              | goss `units.yaml` ²                   |
| Timer last run       | a `homelab-*` timer whose triggered service did not end in `success`                                                                                               | `homelab-health.sh`                   |
| Timer never started  | a `homelab-*` timer fired but its service has no start time, for **240 s** (shared gate)                                                                           | `homelab-health.sh`                   |
| Git mirror stale     | the mirror's `next_update_unix` is more than **1 h** in the past — so > 9 h since the last completed sync — or its state is unreadable on **two consecutive runs** | `homelab-health.sh`                   |
| Certificate expiry   | the soonest certificate in `acme.json` is under **21 days**, unreadable, or the file is absent                                                                     | `homelab-health.sh`                   |
| Certificates gone    | `acme.json` holds fewer certificates than the highest count it has held — a resolver stopped issuing                                                               | `homelab-health.sh`                   |
| Crash-heal silent    | the heal timer is active but logged no `checked` line in **15 min**, or saw fewer or more services than are declared                                               | `homelab-health.sh`                   |
| Timer disarmed       | a `homelab-*` control timer is present but not `enabled` and `active`                                                                                              | goss `posture.yaml` ³                 |

¹ Both until the netdata alarm has been observed firing (ADR-030); undervoltage cannot be triggered
on demand.
² Evaluated by the goss spec; `homelab-health.sh` reads its TAP, so it arrives on `Pi health`.
³ Evaluated daily by `posture.yaml`, reported on `Pi security posture`.

The table is maintained by hand. To check it, compare against `problems+=(` in
`homelab-health.sh.j2`, `ansible/roles/observability/templates/netdata-health-*.conf.j2` and
`goss-units.yaml.j2`.

**Threshold notes**

- **Memory, 800 MiB**: `MemAvailable`, not free memory (the page cache is reclaimable). Over 19 days
  the hourly minimum never went below 800 MiB; the 5-min window absorbs short dips.
- **Swap, 85 % (provisional)**: the swap file is 4 GiB because at 2 GiB it sat saturated with cold
  pages and occupancy meant nothing. The expected steady state is ~2.1–2.3 GiB (52–57 %). A full
  swap is not memory shortage; it matters only if available memory is also low. If occupancy settles
  above 85 %, raise the threshold rather than delete it.
- **Resizing swap is manual**: `creates:` guards it, so changing `swap_size_mb` alone does nothing.
  Procedure and `swapoff` caveats: `ansible/roles/storage/tasks/swap.yml`.
- **DNS, random name**: Kuma's `Pi-hole DNS` and Pi-hole's healthcheck are answered from cache or
  locally, so a dead `dnsproxy` leaves them green. A random label under the domain must go upstream
  (`forward=127.0.0.1#5053`). `NXDOMAIN` counts as success; `SERVFAIL`, `REFUSED` and silence fail.
  The gate is `gate dns-upstream 240` because the probe has no cache cushion.
- **Restart loop, sub-state**: a unit with `Restart=on-failure` and `StartLimitIntervalSec=0` never
  reaches `failed`; it sits in `activating/auto-restart`, so `systemctl --failed` misses it. 240 s
  lets a single legitimate restart pass.
- **Timers, last result**: timer services rest at `inactive/dead`; the check reads the last run's
  result and enumerates timers, so new ones are covered automatically.
- **Unhealthy container** only covers containers that declare a healthcheck. `socket-proxy` probes
  `/_ping` through the proxy (unhealthy ~105 s after it stops answering) because Traefik keeps
  serving from memory while blind to container changes. `nextcloud-notify-push` has no healthcheck;
  the hourly self-test watches it.

### The weekly Lynis audit

`homelab-lynis-report.sh` pushes `Pi Lynis audit` weekly.

- Alarms below an absolute floor of **65**, checked first.
- Alarms on a fall below the **best index ever recorded** (ratchet), per Lynis version: a new version
  resets the baseline and says so in the message.
- The message names the warning test IDs, and a regression names what is new. The report behind
  each green verdict is kept (`/var/log/lynis-report.dat` is rewritten by every run, manual ones
  included).
- `KRNL-5830` ("reboot … needed") is a legitimate, temporary warning; it clears only at the next
  weekly run after the reboot.
- **`PKGS-7388` is a known false positive; do not skip it.** Lynis 3.0.9 cannot parse the deb822
  source `/etc/apt/sources.list.d/ubuntu.sources` (`Suites: noble-security`); security updates work.
  Skipping it would raise the index and move the ratchet.

### DDNS (push dead-man's switch)

`cloudflare-ddns.sh` (`homelab-ddns.service`, every 15 min) keeps the `vpn.<domain>` A record on the
current public IP.

- Pushes on **every** run. Pushes `down` with a specific reason on each failure: no public IP, and
  for each of the four Cloudflare calls one message for a transport failure and another for an
  unusable answer, with curl's exit code as in `journalctl`.
- Monitor: heartbeat 1080 s, retries **0** (reason in [uptime-kuma.md](../05-services/uptime-kuma.md)).
- Cloudflare calls use `--retry 2`, except the create (a replayed POST can duplicate the A record).
  This is independent of the monitor's retries.
- A failing run is caught within 5 min by the timer check in `Pi health`; this monitor adds the case
  of a timer that stopped running (its last result stays `success`).
- Neither proves the public record is correct; that needs a probe from outside the LAN. The
  WireGuard HTTP monitor does not help: Kuma's `extra_hosts` pins `vpn.<domain>` to the LAN IP.
- A stale record breaks remote access at once and silently.

**Offsite tunnel recovery (ADR-029).** `offsite-wg-reresolve.timer` re-resolves the endpoint name
and calls `wg set` when the peer's handshake goes stale, within four minutes.

- It fires only on a stale handshake, so a working tunnel is never touched.
- It hands the name to `wg set`, so a resolution failure aborts instead of clearing the endpoint.
- It works because the offsite Pi resolves through its own LAN router, not the tunnel.
- After a home address change, only the offsite side can reopen the path through its NAT, so this
  timer is the recovery, not a redundancy. WireGuard roaming covers only an unchanged address.
- The offsite health report carries the handshake age. A tunnel that is truly down shows only as
  silence on the dead-man's switch.

### Backups (push dead-man's switches)

Every leg pushes on success and Kuma alarms on silence: local backup (26 h window), local prune +
check, offsite copy, offsite check, offsite Pi disk/SMART health. See
[backup-monitoring.md](../../knowledge/runbooks/backup-monitoring.md).

## Alerting

Discord webhook on every monitor. Known limitations, accepted (issue #13):

- **Nothing watches the watcher.** Kuma runs on the Pi; a total outage produces silence.
- **Single channel.** A broken or muted webhook means no alerts.
- **Notification storm.** Monitors are not chained (`parent` is null), so a Pi or Traefik outage
  trips nearly every monitor, and each re-notifies about every 6 h (`resend_interval`) for the
  length of the incident.

## Log retention

- Docker: `json-file`, `max-size 10m` × `max-file 3` daemon default
  (`ansible/roles/docker/tasks/install.yml`). `traefik-log-redactor` overrides it with `20m` × `10`
  in `compose.yaml` (ADR-034); its ring empties on every recreation.
- journald: persistent, `SystemMaxUse=1500M` via a drop-in (`ansible/roles/base/tasks/logging.yml`).
  The persistent store is on the encrypted volume, mounted at unlock
  (`ansible/roles/storage/tasks/journal.yml`): before unlock, only the current boot is readable, so
  the "unexplained poweroff" runbook cannot rely on previous boots.

## Reading the UFW log

`UFW BLOCK` lines are the closest thing to an intrusion signal here.

```bash
sudo journalctl --since "24 hours ago" -k | grep "UFW BLOCK" \
  | grep -oP 'SRC=\K[0-9.]+' | sort | uniq -c | sort -rn
```

Normal entries:

| Source        | Port | Why it is there                                                                                   |
|---------------|------|---------------------------------------------------------------------------------------------------|
| `192.168.1.1` | —    | the router's IGMP multicast to 224.0.0.1. Constant, harmless                                      |
| `10.8.0.x`    | 853  | Android Private DNS probing DoT, then falling back to 53 — filtered normally. Do not re-investigate |
| LAN addresses | misc | occasional device chatter                                                                         |

Almost nothing from the internet reaches the host, because almost nothing is forwarded to it
(ADR-013).
