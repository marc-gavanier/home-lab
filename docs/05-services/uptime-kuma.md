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

| Monitor       | Type     | Target                                        |
|---------------|----------|-----------------------------------------------|
| Nextcloud     | HTTP(s)  | `https://drive.example.com/status.php`        |
| Vaultwarden   | HTTP(s)  | `https://vault.example.com/alive`             |
| HedgeDoc      | HTTP(s)  | `https://notes.example.com`                   |
| Jellyfin      | HTTP(s)  | `https://videos.example.com/health`           |
| Navidrome     | HTTP(s)  | `https://music.example.com/ping`              |
| Immich        | HTTP(s)  | `https://photos.example.com`                  |
| Traefik HTTPS | TCP Port | `192.168.1.100:443`                           |
| Pi-hole DNS   | DNS      | Resolver `192.168.1.100`, query `example.com` |
| WireGuard     | HTTP(s)  | `https://vpn.example.com`                     |
| Pi (ping)     | Ping     | `192.168.1.100`                               |

Defaults for all monitors: 60s interval, 3 retries.

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