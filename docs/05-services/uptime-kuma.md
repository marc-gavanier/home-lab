# Uptime Kuma

Availability monitoring and the lab's only alerting channel (Discord). Every monitor is entered by
hand in the UI: Kuma is v2, and the Ansible tooling targets v1 only.

## At a glance

| Item        | Value                                                                                                              |
|-------------|--------------------------------------------------------------------------------------------------------------------|
| URL         | `https://services.example.com` (VPN-only middleware bypassed for LAN/Docker network)                                |
| Image       | `louislam/uptime-kuma:2.5.5` — pinned, bumped by hand; Renovate holds it for approval ([runbook](../../knowledge/runbooks/uptime-kuma-migration-failure.md)) |
| Data        | `/mnt/data/services/uptime-kuma/` — SQLite `kuma.db`: monitors, history, settings, push tokens                     |
| Backup      | Nightly consistent `sqlite3 .backup` copy, then Restic                                                             |
| Inventory   | `ops/kuma-dump.sh` (read-only, WAL-safe) — the database is the source of truth, not this page                      |
| Notification | Discord webhook on every monitor (**Settings > Notifications**)                                                   |

## DNS

- The 21 service names are pinned to the Pi's LAN IP in `extra_hosts` (`x-kuma-hosts` in compose).
  Without the pin a lookup can return the public IP, and Traefik blocks the request as non-VPN.
- The container's resolvers (`dns: [${PI_LAN_IP}, 1.1.1.1]`) only serve names outside that list.
- `Pi-hole DNS + split-DNS` queries Pi-hole explicitly, so it does not depend on either.

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
| Prowlarr                  | Keyword  | `https://indexers.example.com/ping` — keyword `OK`                                            |
| Sonarr                    | Keyword  | `https://series.example.com/ping` — keyword `OK`                                              |
| Radarr                    | Keyword  | `https://films.example.com/ping` — keyword `OK`                                               |
| Calibre-Web               | HTTP(s)  | `https://books.example.com/login`                                                             |
| Miniflux                  | HTTP(s)  | `https://rss.example.com/healthcheck`                                                         |
| Collabora                 | HTTP(s)  | `https://office.example.com/hosting/capabilities`                                             |
| Forgejo                   | HTTP(s)  | `https://git.example.com/api/healthz`                                                         |
| Netdata                   | HTTP(s)  | `https://system.example.com/api/v1/info`                                                      |
| Transmission              | Keyword  | `https://share.example.com/transmission/web/`                                                 |
| WireGuard                 | HTTP(s)  | `https://vpn.example.com`                                                                     |
| Traefik HTTPS             | TCP Port | `<pi-lan-ip>:443`                                                                             |
| Transmission BT Peer Port | TCP Port | `transmission:51413`                                                                          |
| Pi-hole DNS + split-DNS   | DNS      | Resolver `<pi-lan-ip>`, query `drive.example.com`, condition: record = `<pi-lan-ip>`          |
| Pi (ping)                 | Ping     | `<pi-lan-ip>`                                                                                 |
| Backup                    | Push     | resticprofile `backup`, daily 03:00                                                           |
| DDNS                      | Push     | `cloudflare-ddns.sh`, every 15 min                                                            |
| Netdata — containers      | Push     | `homelab-netdata-kuma.sh` services group, /5 min                                              |
| Nextcloud notify_push     | Push     | `notify_push:self-test`, hourly                                                               |
| Offsite backup            | Push     | resticprofile `copy`, daily 03:00                                                             |
| Offsite check             | Push     | resticprofile `offsite check`, Tue 02:00                                                      |
| Offsite health            | Push     | `offsite-health.sh`, on the offsite Pi                                                        |
| Pi disk health            | Push     | `homelab-disk.sh`, daily 07:00 + jitter                                                       |
| Pi health                 | Push     | `homelab-health.sh`, every 5 min                                                              |
| Pi Lynis audit            | Push     | `homelab-lynis-report.sh`, weekly                                                             |
| Pi pending action         | Push     | `homelab-health.sh` pending group, every 5 min                                                |
| Pi resources              | Push     | `homelab-netdata-kuma.sh` resources group, /5 min                                             |
| Pi restic prune+check     | Push     | resticprofile `prune`+`check`, Tue 01:00                                                      |
| Pi security posture       | Push     | `homelab-posture.sh`, daily 11:00 + jitter                                                    |
| Veille quotidienne        | Push     | `feed-digest/digest.sh`, daily 06:30 + jitter                                                 |

Push monitors are dead-man's switches: the job pushes, and Kuma alarms when the push does not
arrive.

### Settings

| Setting                | Value                                                                                     |
|------------------------|-------------------------------------------------------------------------------------------|
| Active-check default   | 60s interval, 3 retries, accepted codes `200-299` — no monitor accepts anything else       |
| Forgejo                | 300s, 2 retries — a mirror nobody waits on                                                |
| Veille quotidienne     | 28h (100 800 s) — one daily run plus slack                                                |
| Pi health              | 600s, retries **0**                                                                       |
| DDNS                   | 1080s (900s period + 180s grace), retries **0**                                           |
| TLS expiry notification | On for 15 of the 18 active HTTPS monitors; off for Prowlarr, Sonarr, Radarr (one click each in the UI). `homelab-health.sh` covers all 21 certificates from `acme.json` anyway |

**Push monitors keep retries at 0.** On a push monitor a retry does not add patience: Kuma raises
its own `"No heartbeat in the time window"` beat, and that generic text replaces the message the
script sent, so the alert names the wrong thing.

### Resend: every active monitor reminds

Kuma notifies once, at the state change, and stays quiet while the monitor stays red. So every
active monitor carries a `resend_interval`, aiming at a reminder every ~6 h (`T` = 21600 s). It
counts **DOWN beats**, not checks. A push monitor that is DOWN gets two kinds: each push its script
sends, and the `No heartbeat in the time window` beat Kuma adds every `interval` anyway. So:

```
active check:   resend_interval = max(1, round(T / interval))
push monitor:   resend_interval = max(1, round(T × (1/push_period + 1/interval)))
```

`push_period` is how often the script pushes. A 60s check gets 360; a daily or weekly push 1,
which reminds at every beat. A new monitor starts at `0`, and the posture assertion
`kuma-every-active-monitor-resends` fails until it is set; it does not check the value.

| Monitor                 | Interval | Pushes every | `resend_interval` | Reminder       |
|-------------------------|----------|--------------|-------------------|----------------|
| `Pi health`             | 600s     | 300s         | 108               | 6 hours        |
| `Pi resources`          | 900s     | 300s         | 96                | 6 hours        |
| `DDNS`                  | 1080s    | 900s         | 44                | 6 hours        |
| `Nextcloud notify_push` | 5400s    | 3600s        | 10                | 6 hours        |
| `Netdata — containers`  | 600s     | 300s         | 18                | **1 hour**     |
| `Pi pending action`     | 900s     | 300s         | 384               | **24 hours**   |

The last two deviate from `T` on purpose — check before "correcting" them.

`Netdata — containers` carries two curated alarms (container down, container unhealthy); without a
resend, a second alarm firing behind the first reaches nobody. Conditions may share a monitor only
when they share a lifetime.

`Netdata` (no suffix) is a different monitor: an HTTP check on the dashboard, 60s, 3 retries,
resend 360.

### Why these endpoints

- A bare `200 on /` stays green while a service is broken. Dozzle serves `/` unchanged after losing
  the Docker API; only `/healthcheck` turns 500 (ADR-023).
- Netdata's dashboard is static files; `/api/v1/info` is generated by the agent, so it fails when
  nothing is collecting.
- **IT-Tools** on `/` is correct: a static page with no backend (ADR-024).
- **Calibre-Web** on `/login` because `/` answers 302. It proves reachability only; the library
  can be unreadable behind a working login page (ADR-025).
- **Collabora** on `/hosting/capabilities` stays green while no document opens. Editing is proven
  by the conversion every deploy runs and by the image healthcheck flipping the container
  `unhealthy` (ADR-021).
- **Miniflux** `/healthcheck` pings the database (503 with Postgres down), so one monitor covers
  both (ADR-026).
- **Transmission** is the only monitor that authenticates: a Keyword check for
  `Transmission Web Interface` with HTTP Basic auth. Unauthenticated, every path answers 401, and
  authenticated the RPC answers 409 to anything, so only that page proves the daemon works. Its
  password lives in `kuma.db` with the push tokens.
- **Pi-hole DNS + split-DNS** queries an internal name and checks the answer is the LAN IP. It
  catches both Pi-hole silent and Pi-hole answering wrong — the case where all 21 `Host()` names
  go NXDOMAIN while every other dashboard stays green.

## How it works: the push fuse after a restart

Kuma schedules a push monitor's first check one full interval after **its own process starts**,
not after the monitor's last beat. Every Kuma restart re-arms all 15 push monitors from zero, so
"the job stopped running" can go unreported for up to one extra window. A job that runs and fails
is still reported, because its beat carries its own verdict.

The posture spec checks this from the host, against `heartbeat.time` (the moment a beat was
received, never rescheduled):

| Assertion                                          | What it establishes                                                                                             |
|----------------------------------------------------|-----------------------------------------------------------------------------------------------------------------|
| `kuma-no-push-monitor-silent-past-its-own-window` | No active push monitor is silent past its declared window **while its last beat still says UP** — the inconsistency, not the outage |
| `netdata-health-engine-has-verdicts`              | netdata has actually evaluated an alarm, closing the one way to hide behind the adapter's startup grace        |

The first one ignores monitors whose last beat is DOWN: Kuma already reports those, and repeating
them would hold `Pi security posture` red for the length of the outage.

## Common tasks

- Add a monitor: in the UI, then set its `resend_interval` from the formula (for a push
  monitor, measure its push period first) and, for a push monitor, retries 0. Export with `ops/kuma-dump.sh` afterwards.
- Upgrade: follow [the migration runbook](../../knowledge/runbooks/uptime-kuma-migration-failure.md#before-any-kuma-upgrade).

## Restore

Do not restore the service folder alone: it holds the live `kuma.db`, and a copy taken while Kuma
runs misses the write-ahead log yet looks complete. Restore the nightly `sqlite3 .backup` copy.

Full procedure: `knowledge/runbooks/restore-from-backup.md` → "Restore Uptime Kuma (SQLite)".
