# Network

## Architecture

```
Internet → ISP Router (IPv4 full stack, port forwarding)
               │
               ├─ Port 80/443 → Pi (Traefik)
               └─ Port 51820/udp → Pi (WireGuard)
```

## Domain: example.com

### Subdomains

| Subdomain              | Service     | Access               |
|------------------------|-------------|----------------------|
| `drive.example.com`    | Nextcloud   | Public (via Traefik) |
| `vault.example.com`    | Vaultwarden | Public (via Traefik) |
| `notes.example.com`    | HedgeDoc    | Public (via Traefik) |
| `videos.example.com`   | Jellyfin    | VPN only             |
| `music.example.com`    | Navidrome   | VPN only             |
| `photos.example.com`   | Immich      | VPN only             |
| `dns.example.com`      | Pi-hole     | VPN only             |
| `services.example.com` | Uptime Kuma | VPN only             |
| `system.example.com`   | Netdata     | VPN only             |
| `vpn.example.com`      | WireGuard   | VPN only             |

### DNS

- **Provider**: Cloudflare (DNS only, not proxied)
- **Records**: individual A records per service (no wildcard — preserves existing site and mail config)
- **Dynamic IP**: if ISP IP changes, update via Cloudflare API (DDNS script planned)

## Traefik

- Entrypoints: 80 (redirect → 443), 443 (TLS)
- ACME: Let's Encrypt via HTTP challenge
- Middlewares: rate limiting, secure headers, VPN-only access for admin panels
- Dashboard: accessible via VPN only

## Docker Networks

| Network    | Usage                                    |
|------------|------------------------------------------|
| `proxy`    | Services exposed via Traefik             |
| `internal` | Inter-service communication (DB, cache)  |

## ISP Configuration

### Requirements

- **IPv4 full stack** (not CGNAT) — required for port forwarding. SFR/Red users must request a rollback from CGNAT via support.
- **Static DHCP lease** for the Pi (192.168.1.100)
- **Port forwarding**: 80/TCP, 443/TCP, 51820/UDP → Pi

### Gotchas

- SFR/Red boxes default to CGNAT (WAN IP in 10.x.x.x range). Port forwarding silently fails.
- The box warns "IPv4 configurations may not work due to IPv6 WAN routing" — this is the CGNAT symptom.
- Mobile networks (SFR, Red, Free) block incoming ports even in IPv6 — VPN outbound connections work fine.