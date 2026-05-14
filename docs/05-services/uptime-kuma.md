# Uptime Kuma

Service availability monitoring and alerting.

## Access

- URL: `https://services.example.com` (VPN only)

## What It Does

- Monitors HTTP/HTTPS endpoints, TCP ports, DNS, Docker containers
- Sends alerts when a service goes down (email, Telegram, webhook, etc.)
- Status pages (public or private)
- Response time tracking

## First Steps

1. Open `https://services.example.com`
2. Create an admin account on first access
3. Add monitors for each service:

| Monitor Name | Type     | URL/Host                            |
|--------------|----------|-------------------------------------|
| Nextcloud    | HTTP(s)  | `https://drive.example.com`         |
| Vaultwarden  | HTTP(s)  | `https://vault.example.com/alive`   |
| Jellyfin     | HTTP(s)  | `https://videos.example.com/health` |
| Navidrome    | HTTP(s)  | `https://music.example.com/ping`    |
| Immich       | HTTP(s)  | `https://photos.example.com`        |
| HedgeDoc     | HTTP(s)  | `https://notes.example.com`         |
| Pi-hole      | HTTP(s)  | `http://192.168.1.100:53` (TCP)     |
| WireGuard    | TCP Port | `192.168.1.100:51820`               |

4. Configure notifications (Settings > Notifications)

## Data

| Path                              | Content         |
|-----------------------------------|-----------------|
| `/mnt/data/services/uptime-kuma/` | SQLite database |

## Restore

```bash
docker stop uptime-kuma
restic restore latest --target / --include /mnt/data/services/uptime-kuma
docker start uptime-kuma
```
