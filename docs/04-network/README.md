# Network

## Architecture

```
Internet → ISP Router (IPv4 full stack, port forwarding)
               │
               ├─ 51820/udp  → Pi (WireGuard)
               └─ 51413      → Pi (Transmission peer port, open for seeding)

  80/443 are NOT forwarded — removed in late July 2026. Traefik listens, but
  only the LAN and the VPN can reach it. See "What is actually reachable" below.
```

## Domain: example.com

### Subdomains

All services are **VPN-only**. The `vpn-only` middleware is applied globally on Traefik's `websecure` entrypoint — any request not coming from the LAN (192.168.1.0/24), WireGuard subnet (10.8.0.0/24), or the `proxy` Docker bridge network (172.18.0.0/16) gets `403 Forbidden`. The docker entry is not decoration: full-tunnel VPN clients are hairpin-NATed back into the bridge and arrive as `172.18.0.1`, never as `10.8.0.x`. The WireGuard entry serves the offsite Pi, whose push to `services.example.com` stays inside the tunnel and reaches Traefik unmasqueraded. See `docker/configs/traefik/dynamic/middlewares.yml` before tightening either.

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
  (RFC 8484 / HTTP2). Queries **that go through Pi-hole** — i.e. the LAN clients
  and the VPN clients — no longer leave in cleartext to the ISP. The host's own
  lookups and the containers' do: they use `/etc/resolv.conf` (`1.1.1.1`,
  `8.8.8.8`) via Docker's embedded resolver, measured 28 of 29 containers — the
  29th, `traefik-log-redactor`, runs on `network_mode: none` and therefore has
  no embedded resolver and no socket to resolve through at all. See
  the consequences section of ADR-015, which used to claim the wider perimeter.
- The upstream is pinned in `compose.yaml` (`FTLCONF_dns_upstreams`), not the
  manual `pihole.toml` — version-controlled, no drift. See ADR-015.

## Traefik

- Entrypoints: 80 (http→https redirect over VPN), 443 (TLS, vpn-only middleware applied globally)
- ACME: Let's Encrypt via **DNS-01** (Cloudflare API, scoped token) — per-host certs, no inbound
  needed, so no public A record or open :80 is required for issuance (ADR-014)
- Middlewares: vpn-only (default on websecure), rate limiting, secure headers, nextcloud-headers
- Dashboard: accessible via LAN/VPN only

## Security Model

### What is actually reachable

Measured from the offsite Pi's uplink on 2026-08-15, with a known-open port as a
control so that a timeout means something:

| Port      | From the internet                                |
|-----------|--------------------------------------------------|
| 80        | not forwarded                                    |
| 443       | not forwarded                                    |
| 51820/udp | WireGuard — the handshake proves it              |
| 51413     | **open** (Transmission peer port, tcp confirmed) |

So the only TCP port an internet scanner can connect to is Transmission's. This
page claimed the opposite in both directions for weeks: it advertised 80/443 as
exposed after the forward had been removed, and never mentioned the one port
that is genuinely open. ADR-013 was corrected on 2026-08-02; this summary was
not, which is why the numbers above now carry the date they were measured.

**Defense in depth via VPN-gated access:**

- Traefik returns `403 Forbidden` for all HTTPS traffic that is not from LAN, VPN, or Docker bridge networks
- That rule is real and verified applied on every router — but note it has never been exercised by internet traffic, since 80/443 are not forwarded. It guards the LAN and the VPN, and it is the safety net if a forward is ever re-added
- Any future CVE in a hosted service requires an authenticated VPN client to exploit — today reinforced by the absence of any path in at all
- Adding a new service inherits the protection automatically (default middleware on entrypoint)

## Docker Networks

| Compose name | Name on the host      | Usage                                   |
|--------------|-----------------------|-----------------------------------------|
| `proxy`      | `proxy`               | Services exposed via Traefik            |
| `internal`   | `homelab_internal`    | Inter-service communication (DB, cache) |
| `socketproxy`| `homelab_socketproxy` | Traefik ↔ docker-socket-proxy only      |

`proxy` is declared `external: true`, so its name is unprefixed; the other two are
created by Compose and carry the project prefix. **The distinction is not
cosmetic**: a bare `internal` network also exists on the host — an empty orphan on
a different subnet, with no container attached — and `docker network inspect
internal` returns it rather than the live one. Address these by the host name when
operating on them.

This line previously claimed the orphan had been removed. It had been, by hand,
and two Ansible tasks rebuilt it thirty-nine minutes later: both looped over
`[proxy, internal]` although only `proxy` needs to pre-exist. Those loops now name
`proxy` only, so removing the orphan finally sticks — but it has to be removed
once, by hand, since nothing deletes a network that no longer gets created:

```bash
docker network rm internal   # verify `docker network inspect internal` shows 0 containers first
```

## Addresses a third party assigns

Six addresses in this lab are decided by somebody else — the ISP, the router's
DHCP server, or the Docker daemon — and written into configuration that assumes
they hold. None of them is wrong today. All six are one third-party decision
away from breaking, and before #292 five of them would have broken silently.

The rule applied, one line per address: **pinned, derived at run time from the
authority that assigns it, or watched.**

| Address | Assigned by | Today | Treatment |
|---------|-------------|-------|-----------|
| Public IPv4 | the ISP | — | **derived** — the DDNS job re-reads it every 15 min and pushes the record |
| The offsite's endpoint | DHCP at the remote site | — | **derived** — `offsite-wg-reresolve` re-resolves the peer name, which is the recovery path a home address change needs |
| homelab LAN address | the router, **one-day lease** | `192.168.1.100`, hardcoded in 19 places including the resolver handed to every VPN client | **watched** — `lan-address-is-the-one-the-configuration-hardcodes` |
| `proxy` network | Docker's default pool | `172.18.0.0/16` | **watched against both authorities** — `traefik-allowlist-covers-the-live-proxy-subnet` |
| `homelab_internal` | Docker's default pool | `172.19.0.0/16` | **watched** — `docker-networks-are-where-the-configuration-expects-them` |
| `homelab_socketproxy` | Docker's default pool | `172.20.0.0/16` | same assertion |

### Why the proxy subnet is the one that matters

Traefik's `vpn-only` middleware admits `172.18.0.0/16` because that is where the
`proxy` network happens to live, and **every VPN client reaches Traefik through
it**. The range was deliberately narrowed from `172.16.0.0/12`, which had also
admitted the Docker socket proxy's network — a good change that makes a
re-allocation fatal rather than harmless. Docker assigns these from a pool with
no `ipam_config`, so a network recreated after the others comes back somewhere
else, and the day `proxy` moves off 172.18 that line refuses every VPN client:
discovered from outside the house, in the worst case.

That one assertion therefore compares the **live network** against the
**allowlist file**, not against a remembered value — those two are the
authorities, and a check that agrees with a third copy of the answer proves
nothing about them.

Pinning with `ipam_config` was the other option and was not taken: it requires
recreating the networks, `proxy` is `external: true`, and recreating it means
stopping every container attached to it. Watching costs three assertions and no
downtime.

### The comment that had gone stale

Two places in the repository named a subnet the machine no longer used — one
placing `homelab_socketproxy` at 172.21 when it sits at 172.20, the other
describing 172.20 as the range a phantom network had taken, which is now a live
one. Both corrected. Where these networks are is a measurement, kept in
`docker_expected_subnets` and asserted; it is no longer prose.

## ISP Configuration

### Requirements

- **IPv4 full stack** (not CGNAT) — required for port forwarding. SFR/Red users must request a rollback from CGNAT via support.
- **Static DHCP lease** for the Pi (192.168.1.100)
- **Port forwarding**: 51820/UDP (WireGuard) and 51413 (Transmission peer port) → Pi.
  **80/TCP and 443/TCP are deliberately NOT forwarded** — the forward was removed in
  late July 2026, and Traefik now serves the LAN and the VPN only. Re-adding them
  after a box reset or an ISP swap would silently re-open the perimeter this lab
  closed on purpose; see the reachability table above.

  **And 53/TCP+UDP must not be forwarded either — that one matters more.**
  Pi-hole publishes the resolver on `0.0.0.0:53` so the LAN can use it, so the
  only thing keeping it off the internet is the box's forward list. It is the
  one published port with **no application-layer guard behind it**: 80 and 443
  reach Traefik, which enforces `vpn-only`, while 53 reaches the resolver
  directly. An open resolver is a reflection amplifier, and it would be found in
  hours. This warning named the web ports and omitted it — checked from the
  offsite uplink with a known-open port as a control, it is closed today.

### Gotchas

- SFR/Red boxes default to CGNAT (WAN IP in 10.x.x.x range). Port forwarding silently fails.
- The box warns "IPv4 configurations may not work due to IPv6 WAN routing" — this is the CGNAT symptom.
- Mobile networks (SFR, Red, Free) block incoming ports even in IPv6 — VPN outbound connections work fine.
