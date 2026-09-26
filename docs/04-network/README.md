# Network

How traffic reaches the home lab: one public VPN port, split DNS on the LAN, and Traefik serving
every service over TLS to the LAN and the VPN only (ADR-002).

## Architecture

```
Internet → ISP Router (IPv4 full stack, port forwarding)
               │
               ├─ 51820/udp  → Pi (WireGuard)
               └─ 51413      → Pi (Transmission peer port, open for seeding)

  80/443 are NOT forwarded. Traefik listens, but only the LAN and the VPN can reach it.
```

## What is reachable from the internet

| Port      | From the internet                  |
|-----------|------------------------------------|
| 80        | not forwarded                      |
| 443       | not forwarded                      |
| 53        | not forwarded                      |
| 51820/udp | WireGuard                          |
| 51413     | open (Transmission peer port, tcp) |

The only TCP port an internet scanner can connect to is Transmission's. Measured from the offsite
Pi's uplink, with a known-open port as a control.

## Subdomains

All services are VPN-only. The `vpn-only` middleware is applied to Traefik's `websecure`
entrypoint: a request that does not come from one of these ranges gets `403 Forbidden`.

| Range            | Why it is allowed                                                         |
|------------------|---------------------------------------------------------------------------|
| `192.168.1.0/24` | LAN                                                                       |
| `10.8.0.0/24`    | WireGuard: the offsite Pi's push to `services.example.com` arrives as-is  |
| `172.18.0.0/16`  | `proxy` bridge: full-tunnel VPN clients are hairpin-NATed and arrive as `172.18.0.1` |

Read `docker/configs/traefik/dynamic/middlewares.yml` before tightening any of them.

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
| `git.example.com`      | Forgejo      |
| `dns.example.com`      | Pi-hole      |
| `services.example.com` | Uptime Kuma  |
| `system.example.com`   | Netdata      |
| `logs.example.com`     | Dozzle       |
| `proxy.example.com`    | Traefik      |
| `vpn.example.com`      | WireGuard    |
| `films.example.com`    | Radarr       |
| `series.example.com`   | Sonarr       |
| `indexers.example.com` | Prowlarr     |

## Public DNS

- Provider: Cloudflare, DNS only, not proxied.
- Of the lab's names, only `vpn.example.com` has a public A record, to bootstrap the tunnel.
  The apex and `www` belong to the external site.
- Service subdomains get certificates through ACME DNS-01, so they need no public record and stay
  out of public DNS (ADR-014).
- No wildcard: certificates are per host, so subdomains served elsewhere (for example a static
  site on GitHub Pages) are unaffected.
- Dynamic IP: `homelab-ddns.timer` runs `cloudflare-ddns.sh` every 15 min. It keeps the `vpn`
  A record on the current public IPv4, updates only on change, and recreates the record if
  it is missing.

## Resolver

- Pi-hole is the LAN resolver (blocking, split DNS). LAN and VPN clients talk only to Pi-hole.
  See [Pi-hole](../05-services/pihole.md).
- Pi-hole forwards to a `dnsproxy` sidecar on `127.0.0.1#5053` (it shares Pi-hole's network
  namespace), which sends queries to Quad9 over DoH (ADR-015).
- The upstreams are IPs (`9.9.9.9`, `149.112.112.112`) so the DNS path needs no DNS to start.
  Quad9's certificate carries IP SANs, so TLS validation still works.
- The upstream is set in `compose.yaml` (`FTLCONF_dns_upstreams`), not in `pihole.toml`.
- Only queries that go through Pi-hole are encrypted. The host and the containers resolve through
  `/etc/resolv.conf` (`1.1.1.1`, `8.8.8.8`) via Docker's embedded resolver, in cleartext.
  `traefik-log-redactor` runs on `network_mode: none` and resolves nothing.
- To check a container's resolver, read its `ResolvConfPath` from the host. Dozzle and Collabora
  ship no `cat`, so reading from inside them gives a false answer.

**Do not diagnose the host with `resolvectl`.** The host resolves through glibc and
`/etc/resolv.conf`; `resolvectl` asks systemd-resolved, which uses Pi-hole from DHCP and answers
like a LAN client (`192.168.1.100` for split-DNS names). Use:

```bash
getent ahostsv4 <name>
```

## Traefik

- Entrypoints: 80 (redirect to https), 443 (TLS, `vpn-only` applied globally).
- Certificates: Let's Encrypt via DNS-01 with a scoped Cloudflare token, per host, no inbound
  port needed (ADR-014).
- Middlewares: `vpn-only` (default on websecure), rate limiting, secure headers,
  `nextcloud-headers`.
- A new service inherits `vpn-only` automatically.

Details: [Traefik](../05-services/traefik.md).

## Docker networks

| Compose name  | Name on the host      | Subnet          | Usage                                   |
|---------------|-----------------------|-----------------|-----------------------------------------|
| `proxy`       | `proxy`               | `172.18.0.0/16` | Services exposed via Traefik            |
| `internal`    | `homelab_internal`    | `172.19.0.0/16` | Inter-service communication (DB, cache) |
| `socketproxy` | `homelab_socketproxy` | `172.20.0.0/16` | Traefik ↔ docker-socket-proxy only      |

- `proxy` is `external: true`, so it has no prefix. The other two carry the project prefix.
- Use the host name: `docker network inspect internal` returns `[]`.
- Expected subnets live in `docker_expected_subnets` and are asserted.

## Addresses a third party assigns

Each one is pinned, derived at run time from whoever assigns it, or watched.

| Address                | Assigned by          | Treatment |
|------------------------|----------------------|-----------|
| Public IPv4            | ISP                  | Derived: the DDNS job re-reads it every 15 min |
| Offsite endpoint       | DHCP at remote site  | Derived: `offsite-wg-reresolve` re-resolves the peer name |
| homelab LAN address    | router, one-day lease | Watched: `lan-address-is-the-one-the-configuration-hardcodes` |
| LAN subnet             | router               | Neither; accepted |
| `proxy` network        | Docker default pool  | Watched: `traefik-allowlist-covers-the-live-proxy-subnet` |
| `homelab_internal`     | Docker default pool  | Watched: `docker-networks-are-where-the-configuration-expects-them` |
| `homelab_socketproxy`  | Docker default pool  | Same assertion |

- **LAN address** (`<pi-lan-ip>`) is hardcoded through `homelab_ip` into every split-DNS record,
  the compose env and the resolver given to VPN clients. If it changes, redeploy, then
  re-download and re-import every client config from wg-easy: each device keeps the old resolver.
- **LAN subnet** (`192.168.1.0/24`) is hardcoded in `host_vars/homelab/main.yml`,
  `security/tasks/firewall.yml` and Traefik's `middlewares.yml`. A new router that changes it
  means editing all three by hand; until then LAN clients get 403, no DNS and no SSH, while the
  VPN keeps working.
- **`proxy` subnet** matters most: every VPN client reaches Traefik through it. Docker has no
  `ipam_config` for it, so a recreated network can move, and `vpn-only` would then refuse every
  VPN client. The assertion compares the live network against the allowlist file.

## ISP configuration

Requirements:

- **IPv4 full stack**, not CGNAT, or port forwarding fails. SFR/Red users must ask support to
  leave CGNAT.
- **Static DHCP lease** for the Pi (`<pi-lan-ip>`).
- **Port forwarding**: 51820/UDP and 51413 → Pi. Nothing else.

Warnings, to check after any box reset or ISP change:

- **Never forward 53/TCP+UDP.** Pi-hole publishes `0.0.0.0:53` with no application guard. The
  host's `DOCKER-USER` rules drop :53 from outside the LAN, the VPN and the container networks,
  and the box is the second guard. An open resolver is a reflection amplifier.
- **Never forward 80/443.** It would re-open the perimeter this lab closed on purpose (ADR-002).

Gotchas:

- SFR/Red boxes default to CGNAT (WAN IP in `10.x.x.x`). Port forwarding then fails silently.
- The box warning "IPv4 configurations may not work due to IPv6 WAN routing" is the CGNAT symptom.
- Mobile networks (SFR, Red, Free) block incoming ports even in IPv6. Outbound VPN works.
