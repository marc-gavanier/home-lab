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

All services are **VPN-only**. The `vpn-only` middleware is applied globally on Traefik's `websecure` entrypoint — any request not coming from the LAN (192.168.1.0/24), WireGuard subnet (10.8.0.0/24), or a Docker bridge network (172.16.0.0/12) gets `403 Forbidden`.

| Subdomain              | Service     |
|------------------------|-------------|
| `drive.example.com`    | Nextcloud   |
| `vault.example.com`    | Vaultwarden |
| `videos.example.com`   | Jellyfin    |
| `music.example.com`    | Navidrome   |
| `photos.example.com`   | Immich      |
| `dns.example.com`      | Pi-hole     |
| `services.example.com` | Uptime Kuma |
| `system.example.com`   | Netdata     |
| `vpn.example.com`      | WireGuard   |

### DNS

- **Provider**: Cloudflare (DNS only, not proxied)
- **Records**: individual A records per service (no wildcard — preserves existing site and mail config)
- **Dynamic IP**: if ISP IP changes, update via Cloudflare API (DDNS script planned)

## Traefik

- Entrypoints: 80 (redirect → 443 + ACME HTTP challenge), 443 (TLS, vpn-only middleware applied globally)
- ACME: Let's Encrypt via HTTP challenge (`/.well-known/acme-challenge/*` handled internally before middlewares)
- Middlewares: vpn-only (default on websecure), rate limiting, secure headers, nextcloud-headers
- Dashboard: accessible via LAN/VPN only

## Security Model

**Defense in depth via VPN-gated access:**

- Only WireGuard (51820/UDP) and Traefik (80, 443/TCP) are exposed to the internet
- Traefik returns `403 Forbidden` for all HTTPS traffic that is not from LAN, VPN, or Docker bridge networks
- Internet bots scanning the public IP see only `403` — no service enumeration possible
- Any future CVE in a hosted service requires an authenticated VPN client to exploit
- Adding a new service inherits the protection automatically (default middleware on entrypoint)

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