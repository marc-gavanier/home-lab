# Network

## Architecture

```
Internet → ISP Router (public IP, possibly dynamic)
               │
               ├─ Port 80/443 → Pi (Traefik)
               └─ Port 51820/udp → Pi (WireGuard)
```

## Domain: example.com

### Planned Subdomains

| Subdomain               | Service       | Access               |
|-------------------------|---------------|----------------------|
| `nextcloud.example.com` | Nextcloud     | Public (via Traefik) |
| `vault.example.com`     | Vaultwarden   | Public (via Traefik) |
| `notes.example.com`     | HedgeDoc      | Public (via Traefik) |
| `media.example.com`     | Jellyfin      | VPN only             |
| `music.example.com`     | Navidrome     | VPN only             |
| `photos.example.com`    | Immich        | VPN only             |
| `dns.example.com`       | Pi-hole admin | VPN only             |
| `monitor.example.com`   | Uptime Kuma   | VPN only             |
| `netdata.example.com`   | Netdata       | VPN only             |
| `vpn.example.com`       | WireGuard UI  | VPN only             |

### DNS

- **Registrar**: A/AAAA records pointing to the router's public IP
- **Pi-hole**: local DNS, resolves subdomains to the Pi's LAN IP (split DNS)
- **Dynamic IP**: if ISP IP changes, set up DynDNS or Cloudflare API

## Traefik

- Entrypoints: 80 (redirect → 443), 443 (TLS)
- ACME: Let's Encrypt via DNS or HTTP challenge
- Middlewares: rate limiting, secure headers, basic auth if needed
- Dashboard: accessible via VPN only

## Docker Networks

| Network    | Usage                                   |
|------------|-----------------------------------------|
| `proxy`    | Services exposed via Traefik            |
| `internal` | Inter-service communication (DB, cache) |

## ISP Router Configuration

To be documented during implementation:
- Port forwarding 80 → Pi
- Port forwarding 443 → Pi
- Port forwarding 51820/udp → Pi
- Static local IP for the Pi (DHCP lease)
