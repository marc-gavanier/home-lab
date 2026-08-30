# Uptime Kuma

Service availability monitoring and alerting.

## Access

- URL: `https://services.example.com` (VPN-only middleware bypassed for LAN/Docker network)
- Version: `louislam/uptime-kuma:2` (v2.x)

## What It Does

- Monitors HTTP/HTTPS endpoints, TCP ports, DNS, Docker containers
- Sends alerts when a service goes down (Discord, email, webhook, etc.)
- Status pages (public or private)
- Response time tracking

## DNS Configuration

Uses Pi-hole as DNS (`dns: [${PI_LAN_IP}]` in compose) so that domain lookups for homelab services resolve to LAN IPs (split DNS). Without this, Uptime Kuma resolves via Cloudflare → traffic exits to public IP → Traefik blocks it as non-VPN.

## Monitors Configured

| Monitor                   | Type     | Target                                                                                        |
|---------------------------|----------|-----------------------------------------------------------------------------------------------|
| Nextcloud                 | Keyword  | `https://drive.example.com/status.php` — keyword `"maintenance":false,"needsDbUpgrade":false` |
| Vaultwarden               | HTTP(s)  | `https://vault.example.com/alive`                                                             |
| Jellyfin                  | HTTP(s)  | `https://videos.example.com/health`                                                           |
| Navidrome                 | HTTP(s)  | `https://music.example.com/ping`                                                              |
| Immich                    | Keyword  | `https://photos.example.com/api/server/ping`                                                  |
| SearXNG                   | HTTP(s)  | `https://search.example.com/healthz`                                                          |
| Dozzle                    | HTTP(s)  | `https://logs.example.com/healthcheck`                                                        |
| IT-Tools                  | HTTP(s)  | `https://tools.example.com`                                                                   |
| Calibre-Web               | HTTP(s)  | `https://books.example.com/login`                                                             |
| Miniflux                  | HTTP(s)  | `https://rss.example.com/healthcheck`                                                         |
| Collabora                 | HTTP(s)  | `https://office.example.com/hosting/capabilities`                                             |
| Forgejo                   | HTTP(s)  | `https://git.example.com/api/healthz`                                                         |
| Netdata                   | HTTP(s)  | `https://system.example.com/api/v1/info`                                                      |
| Transmission              | Keyword  | `https://share.example.com/transmission/web/`                                                 |
| WireGuard                 | HTTP(s)  | `https://vpn.example.com`                                                                     |
| Traefik HTTPS             | TCP Port | `192.168.1.100:443`                                                                           |
| Transmission BT Peer Port | TCP Port | `transmission:51413`                                                                          |
| Pi-hole DNS               | DNS      | Resolver `192.168.1.100`, query `example.com`                                                 |
| Pi (ping)                 | Ping     | `192.168.1.100`                                                                               |
| Backup                    | Push     | resticprofile `backup`, daily 03:00                                                           |
| DDNS                      | Push     | `cloudflare-ddns.sh`, every 15 min                                                            |
| Netdata — containers      | Push     | `homelab-netdata-kuma.sh` services group, /5 min                                              |
| Nextcloud notify_push     | Push     | `notify_push:self-test`, hourly                                                               |
| Offsite backup            | Push     | resticprofile `copy`, daily 03:00                                                             |
| Offsite check             | Push     | resticprofile `offsite check`, Sun 06:00                                                      |
| Offsite health            | Push     | `offsite-health.sh`, on the offsite Pi                                                        |
| Pi disk health            | Push     | `homelab-disk.sh`, daily 07:00 + jitter                                                                |
| Pi health                 | Push     | `homelab-health.sh`, every 5 min                                                              |
| Pi Lynis audit            | Push     | `homelab-lynis-report.sh`, weekly                                                             |
| Pi pending action         | Push     | `homelab-health.sh` pending group, every 5 min                                                |
| Pi resources              | Push     | `homelab-netdata-kuma.sh` resources group, /5 min                                             |
| Pi restic prune+check     | Push     | resticprofile `prune`+`check`, Sun 05:00                                                      |
| Pi security posture       | Push     | `homelab-posture.sh`, daily 11:00                                                             |
| Veille quotidienne        | Push     | `feed-digest/digest.sh`, daily 06:30                                                          |

Defaults for the active checks: 60s interval, 3 retries, accepted codes `200-299`,
TLS expiry notification on. Since #191 no active monitor accepts anything outside that
set — Transmission's `401` was the last exception. The push monitors are dead-man's switches: the job pushes
on success, and Kuma alarms when the push does not arrive.

Four monitors deviate on purpose. **Forgejo** polls every 300s with 2 retries: it is a
mirror, not an interactive service — nobody is waiting on it, and a minute of downtime
is not worth a Discord message. **Veille quotidienne** waits 25h rather than the
default: the digest runs once a day, so the dead-man window has to clear a full day
plus the slack for a slow run.

**Pi health** (600s) and **DDNS** (1080s) run with retries turned **off**, which is
the opposite of what it looks like. Kuma's push branch raises `"No heartbeat in the
time window"` whenever the *previous* beat is not UP — including for a punctual
`status=down` push — and with one retry it is that raised beat, not the script's, that
notifies. So a retry does not make a push monitor more patient: it replaces the
message the script sent with a generic one, and the alert then names the wrong thing.

Measured over every notifying heartbeat before the change: `Pi health` had alerted
four times and four times the text read `"No heartbeat"` instead of what the script
had pushed, while the monitors already at zero retries kept their own text in six
cases out of seven — the seventh being a genuine dead-man beat, where `"No heartbeat"`
is the correct answer. The cost was not theoretical: on 2026-08-18 a service was
inactive for three hours, thirty-seven pushes named it, and the one alert that left
described a dead host that was in perfect health.

Retries stay at zero so an alert says what was detected. `Pi health` widens from 360s
to 600s because removing the retry removes the slack it was accidentally providing:
excluding real outages, its maximum jitter gap is 340.5s over 360 samples, which left
19.5s of margin — 5% — on a script that spends about twenty seconds running.

`DDNS` keeps its 1080s window, and that is a deliberate reversal of the first proposal
in #179. Re-measurement did not support widening it: the observed maximum gap is
921.4s, so 1080s already carries 17% of margin, and at 1800s the monitor would need
**two** consecutive missed runs to alarm where one is the useful signal. Doubling a
detection window costs sensitivity and should be paid for by a measurement, not by
symmetry with the monitor next to it.

### Every active monitor resends — the rule, and why it is not a preference

Kuma notifies **once**, at the state transition, and never again while the condition
stays red. Measured cost, from `stat_daily` (the right instrument — `heartbeat` prunes
ordinary beats):

```
Pi health | 2026-07-31 |  57 up | 424 down
Pi health | 2026-08-01 |   0 up | 528 down     <- a full day, entirely down
Pi health | 2026-08-02 | 153 up | 236 down
```

Roughly **54 hours of continuous outage of the dead-man's switch itself**, for one
Discord message sent 54 hours earlier. #179 fixed *which text* notifies; nobody had
looked at *how many times*.

Since 2026-08-25 every active monitor carries a `resend_interval`, targeted at a
reminder roughly every **6 hours**. Kuma counts that field in CHECKS, not in seconds,
so the value differs per monitor and is derived rather than chosen:

```
resend_interval = max(1, round(21600 / interval))
```

A 60s HTTP check gets 360; a 600s push monitor gets 36; a push monitor whose own
cadence is a day or a week gets 1, which is the most frequent reminder its interval
allows. Monitors are created by hand — Kuma v2 has no editing API — so a new monitor
starts at `0`, and `kuma-every-active-monitor-resends` in the posture spec fails until
it is set.

## The fuse a restart re-arms, and where it is checked instead

**Kuma schedules a push monitor's first check one full interval after its own
process starts, not one interval after that monitor's last heartbeat.** Every
restart of the container therefore re-arms the fuse of all 15 push monitors from
zero. Proven on recorded data rather than read off the source (#289):

| Silence   | Window   | Kuma restarted in between | Result                |
|-----------|----------|---------------------------|-----------------------|
| 93 474 s  | 90 000 s | yes                       | **no DOWN beat**      |
| 90 001 s  | 90 000 s | no                        | `status = 0`, as designed |

The second row is the positive control: one second over the window, no restart,
and the mechanism fires correctly. What is degraded is the **silence** half — a
job that runs and fails is still reported, because that beat carries its own
verdict. Only "the job stopped running and nobody said so" is affected, and only
until the next long enough quiet stretch burns the fuse for real.

Kuma cannot be corrected from here, so the fuse is checked host-side against a
clock a restart does not touch: `heartbeat.time`, the moment a beat was
*received*, written once and never rescheduled.

| Assertion | What it establishes |
|-----------|---------------------|
| `kuma-no-push-monitor-silent-past-its-own-window` | No active push monitor is silent past the window it declares **while its last beat still says UP**. It asserts the inconsistency, not the outage |
| `netdata-health-engine-has-verdicts` | netdata has actually evaluated an alarm, closing the one way to hide behind the adapter's startup grace |

The `status = 1` half of the first one is load-bearing rather than fussy. A
monitor that is genuinely late carries a last beat saying DOWN and Kuma is
already saying so; re-reporting it here would make "Pi security posture" red for
as long as the outage lasts, and #216 cost a day when a condition that stays red
for days sat in the same signal as the acute checks and muted them. A backup
three days late must not silence this monitor for three days.

**It is the default, not a law: 32 of the 34 active monitors follow it, and two
carry a deliberately different reminder.** Measured 2026-08-29:

| Monitor                | Interval | `resend_interval` | Formula would give | Actual reminder |
|------------------------|----------|-------------------|--------------------|-----------------|
| `Netdata — containers` | 600s     | 6                 | 36                 | **1 hour**      |
| `Pi pending action`    | 900s     | 96                | 24                 | **24 hours**    |

Both land on a round number because both were chosen: container conditions are
worth an hourly nudge, and a pending action that needs a human is worth a daily
one and no more. Check the arithmetic before "correcting" either back to the
formula.

`Netdata — containers` is the **one** Netdata push monitor, at 600s with zero
retries, and it was the first here to carry `resend_interval` — for a reason that
is *not* the rule above. It carries SEVERAL curated alarms (it reports both
container conditions), so without a resend a second alarm firing behind an
unresolved first one reaches nobody (#200). That is the price of sharing a
monitor, and it is what makes the sharing safe: conditions may share a signal
when they share a LIFETIME, never when one of them can wait for a human.

The similarly named `Netdata` is a different thing — an **HTTP** monitor on the
dashboard at 60s with 3 retries, following the formula at 360. Earlier revisions
of this page described "the two Netdata push monitors" sharing "the same 600s
window and zero retries"; there is one push monitor, and the two differ in type,
interval and retries alike.

Both were created by hand, like every monitor here, and `Retries` is the field to get
right. Setting it to 1 was tried on 2026-08-23 and reverted the same evening on the
evidence above: the monitor's first real alert read `"No heartbeat in the time window"`
while the adapter had pushed the name of the alarm that was not loading.

The **Target** column names the endpoint on purpose. A bare `200 on /` would keep a
service green while it is broken — the case measured on Dozzle, which serves its page
unchanged after losing the Docker API and only flips `/healthcheck` to 500 (ADR-023).
Netdata is the same shape: its dashboard is static files that answer 200 whatever the
agent is doing, while `/api/v1/info` is generated by the agent itself, so the check
fails when there is nothing left collecting.

Three entries deserve a note, because they look like exceptions to that rule and are
not the same kind of thing:

- **IT-Tools** is checked on `/`, and that is correct: it is a static page with no
  backend that can fail independently (ADR-024).
- **Calibre-Web** is checked on `/login` because `/` answers 302, which falls outside
  `200-299`. But green here proves reachability only — the library can be unreadable
  while the login page is served, and proving otherwise needs an authenticated request
  Kuma cannot make (ADR-025).
- **Collabora** is checked on `/hosting/capabilities`, which the main process answers —
  so it stays green while no document can open. The real check is the conversion every
  deploy performs, plus the image's own healthcheck flipping the container `unhealthy`
  (ADR-021). The monitor is worth having for reachability and TLS expiry, and is not
  evidence that editing works.

**Miniflux is the counter-example, and it was measured rather than assumed.** A second
monitor on `/` was specified for it on the theory that `/healthcheck` would answer from
the process alone and stay green with Postgres down. Stopping `miniflux-db` disproved
that: `/healthcheck` returns **503** and `/` returns 500 — Miniflux's healthcheck pings
the database, so one monitor already covers both the process and its storage, and the
second was dropped before it was ever created (ADR-026).

Worth noting what the same test showed about container health: `docker ps` still
reported `healthy` while the service was returning 503, because the 30 s interval had
not re-run. That is the argument for having a Kuma monitor at all — not for having two.

**Transmission is the only monitor that authenticates**, and the alternatives were
measured rather than argued (#191). Its accepted set used to carry `401`, which made it
the only one of the thirty-one to count a refusal as success. Through Traefik:

| Request                     | no credentials | as `admin`     |
|-----------------------------|----------------|----------------|
| `/transmission/web/`        | 401            | 200 + the UI   |
| `/transmission/rpc`         | 401            | 409            |
| `/transmission/nonexistent` | 401            | 409            |

Unauthenticated, a path that does not exist is indistinguishable from the interface.
Authenticated, the RPC endpoint's 409 does not distinguish one either — Transmission
answers 409 to *any* authenticated path presented without a session id. The single
response only a serving Transmission produces is the 200 carrying
`Transmission Web Interface`, so the monitor is a Keyword check with HTTP Basic auth,
and its password lives in `kuma.db` alongside the push tokens the file already holds.

Be exact about what the old `401` did and did not prove, because it is easy to
overstate: there is no `basicAuth` middleware on this router, so that refusal could
only have come from Transmission's own listener on :9091 — Traefik with a dead backend
returns 502, not 401. The monitor did prove routing, TLS and a live listener. What it
could not prove is that anything behind the listener works, because the refusal is
issued before the daemon does any of its own work. That is the same argument that moved
the container healthcheck to `transmission-remote -l` in #145, applied to the external
check that survives a container-level failure.

This table is a readable summary, not the source of truth. The authoritative inventory
is Kuma's own database — export it with `ops/kuma-dump.sh` (read-only, WAL-safe), which
is also what this table was rebuilt from. Monitors are added by hand in the UI: Kuma is
v2, and the mature Ansible tooling still targets v1 only.

## Notifications

Discord webhook applied to all monitors. Configuration in **Settings > Notifications**.

## Data

| Path                              | Content                                          |
|-----------------------------------|--------------------------------------------------|
| `/mnt/data/services/uptime-kuma/` | SQLite database with monitors, history, settings |

## Backup

Backed up daily by Restic. Monitors and history persist across container restarts.

## Restore

Restoring the service folder alone is **not** enough, which is why the procedure
is not repeated here: that folder holds the *live* `kuma.db`, and a copy taken
while the service runs misses the write-ahead log — the monitors and heartbeats
recorded since the last checkpoint are simply absent, and the result looks like
a complete database. The nightly backup writes a consistent `sqlite3 .backup`
copy, and that is the file to restore.

Full procedure: `knowledge/runbooks/restore-from-backup.md` → "Restore Uptime
Kuma (SQLite)".
