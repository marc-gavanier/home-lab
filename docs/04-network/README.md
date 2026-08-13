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

| Subdomain              | Service      |
|------------------------|--------------|
| `drive.example.com`    | Nextcloud    |
| `vault.example.com`    | Vaultwarden  |
| `videos.example.com`   | Jellyfin     |
| `music.example.com`    | Navidrome    |
| `photos.example.com`   | Immich       |
| `share.example.com`    | Transmission |
| `office.example.com`   | Collabora    |
| `search.example.com`   | SearXNG      |
| `tools.example.com`    | IT-Tools     |
| `books.example.com`    | Calibre-Web  |
| `rss.example.com`      | Miniflux     |
| `dns.example.com`      | Pi-hole      |
| `services.example.com` | Uptime Kuma  |
| `system.example.com`   | Netdata      |
| `logs.example.com`     | Dozzle       |
| `proxy.example.com`    | Traefik      |
| `vpn.example.com`      | WireGuard    |

### DNS

- **Provider**: Cloudflare (DNS only, not proxied)
- **Records**: only `vpn.example.com` needs a public A record (to bootstrap the tunnel).
  Service subdomains use ACME **DNS-01**, so they need no public A record and are kept
  out of public DNS (ADR-014). No wildcard — per-host certs, so subdomains served
  elsewhere (e.g. a static site on GitHub Pages) are unaffected.
- **Dynamic IP**: a systemd timer (`homelab-ddns.timer`, every 15 min) runs
  `cloudflare-ddns.sh`, which keeps the `vpn` A record on the current public IPv4
  via the Cloudflare API (updates only on change; recreates the record if missing).

### Resolver (Pi-hole → encrypted upstream)

- **Pi-hole** is the LAN resolver (ad/tracker blocking, split DNS, lists). Clients
  talk only to Pi-hole.
- **Encrypted egress**: Pi-hole forwards upstream to a **dnsproxy** sidecar
  (`127.0.0.1#5053`, sharing Pi-hole's netns), which proxies to **Quad9 over DoH**.
  It replaced cloudflared on 2026-07-27: Cloudflare **removed** the `proxy-dns`
  feature in 2026.2.0, so the container this depended on stopped existing rather
  than breaking (ADR-015, issue #50). The upstreams are addressed **by IP**
  (`9.9.9.9`, `149.112.112.112`) on purpose — a service that *is* the DNS path
  should not need DNS to start; Quad9's certificate carries IP SANs, so TLS
  validation is unchanged
  (RFC 8484 / HTTP2). Upstream queries no longer leave in cleartext to the ISP.
- The upstream is pinned in `compose.yaml` (`FTLCONF_dns_upstreams`), not the
  manual `pihole.toml` — version-controlled, no drift. See ADR-015.

## Traefik

- Entrypoints: 80 (http→https redirect over VPN), 443 (TLS, vpn-only middleware applied globally)
- ACME: Let's Encrypt via **DNS-01** (Cloudflare API, scoped token) — per-host certs, no inbound
  needed, so no public A record or open :80 is required for issuance (ADR-014)
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
