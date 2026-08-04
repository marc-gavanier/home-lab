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

| Monitor                   | Type     | Target                                        |
|---------------------------|----------|-----------------------------------------------|
| Nextcloud                 | HTTP(s)  | `https://drive.example.com/status.php`        |
| Vaultwarden               | HTTP(s)  | `https://vault.example.com/alive`             |
| Jellyfin                  | HTTP(s)  | `https://videos.example.com/health`           |
| Navidrome                 | HTTP(s)  | `https://music.example.com/ping`              |
| Immich                    | Keyword  | `https://photos.example.com/api/server/ping`  |
| SearXNG                   | HTTP(s)  | `https://search.example.com/healthz`          |
| Dozzle                    | HTTP(s)  | `https://logs.example.com/healthcheck`        |
| IT-Tools                  | HTTP(s)  | `https://tools.example.com/`                  |
| Calibre-Web               | HTTP(s)  | `https://books.example.com/login`             |
| Transmission              | HTTP(s)  | `https://share.example.com/transmission/web`  |
| WireGuard                 | HTTP(s)  | `https://vpn.example.com`                     |
| Traefik HTTPS             | TCP Port | `192.168.1.100:443`                           |
| Transmission BT Peer Port | TCP Port | `transmission:51413`                          |
| Pi-hole DNS               | DNS      | Resolver `192.168.1.100`, query `example.com` |
| Pi (ping)                 | Ping     | `192.168.1.100`                               |
| Backup                    | Push     | `backup.sh`, daily 03:00                      |
| Offsite backup            | Push     | `backup.sh` copy stage, daily 03:00           |
| Offsite check             | Push     | `offsite-check.sh`, Sun 06:00                 |
| Offsite health            | Push     | `offsite-health.sh`, on the offsite Pi        |
| Pi health                 | Push     | `homelab-health.sh`, every 5 min              |
| Pi Lynis audit            | Push     | `homelab-lynis-report.sh`, weekly             |
| Pi restic prune+check     | Push     | `local-maintenance.sh`, Sun 05:00             |
| Pi security posture       | Push     | `homelab-posture.sh`, daily 11:00             |

Defaults for the active checks: 60s interval, 3 retries, accepted codes `200-299`,
TLS expiry notification on. The push monitors are dead-man's switches: the job pushes
on success, and Kuma alarms when the push does not arrive.

The **Target** column names the endpoint on purpose. A bare `200 on /` would keep a
service green while it is broken — the case measured on Dozzle, which serves its page
unchanged after losing the Docker API and only flips `/healthcheck` to 500 (ADR-023).

Three entries deserve a note, because they look like exceptions to that rule and are
not the same kind of thing:

- **IT-Tools** is checked on `/`, and that is correct: it is a static page with no
  backend that can fail independently (ADR-024).
- **Calibre-Web** is checked on `/login` because `/` answers 302, which falls outside
  `200-299`. But green here proves reachability only — the library can be unreadable
  while the login page is served, and proving otherwise needs an authenticated request
  Kuma cannot make (ADR-025).
- **Collabora** has no row at all: its reachable endpoint stays green while no document
  can open, so the real check is the conversion the deploy performs (ADR-021).

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

```bash
docker stop uptime-kuma
restic restore latest --target / --include /mnt/data/services/uptime-kuma
docker start uptime-kuma
```
