# Home Lab

Personal home lab on Raspberry Pi 4 — self-hosted services, full automation, hardened security.

## Goals

- **Automation**: provision the entire system in one command (`ansible-playbook`)
- **Security**: build a digital fortress (hardening, firewall, VPN, encryption)
- **Sovereignty**: self-host personal services (files, media, passwords, notes)
- **Learning**: level up on system administration and security

## Hardware

| Component    | Specification               |
|--------------|-----------------------------|
| Machine      | Raspberry Pi 4 Model B      |
| CPU          | Quad-core Cortex-A72 64-bit |
| RAM          | 8 GB LPDDR4                 |
| OS storage   | 64 GB SD card               |
| Data storage | 5 TB external HDD           |
| Network      | Gigabit Ethernet            |
| Case         | With active fan             |

## Services

| Service           | Tool                  | Purpose                       |
|-------------------|-----------------------|-------------------------------|
| Cloud / Files     | Nextcloud             | File sync, mobile access      |
| VPN               | WireGuard (wg-easy)   | Secure remote access          |
| DNS / Ad-blocking | Pi-hole               | Ad and tracker filtering      |
| Passwords         | Vaultwarden           | Bitwarden-compatible manager  |
| Video             | Jellyfin              | Video library and streaming   |
| Music             | Navidrome             | Music library and streaming   |
| Photos            | Immich                | Photo management and backup   |
| Reverse proxy     | Traefik               | Automatic TLS, routing        |
| Backup            | Restic                | Encrypted incremental backup  |
| Monitoring        | Uptime Kuma + Netdata | Uptime and system monitoring  |

## Network Architecture

```
Internet → ISP Router  (forwarded: 51820/udp, 51413)
               │
               ├─ :51413      → Transmission peer port (tcp+udp, open for seeding)
               │
               └─ :51820/udp → WireGuard VPN
                                  │
                                  └─ LAN → Traefik (:443, TLS via Cloudflare DNS-01)
                                             ├─ drive.example.com  → Nextcloud
                                             ├─ vault.example.com  → Vaultwarden
                                             ├─ proxy.example.com  → Traefik dashboard
                                             └─ ...
```

**Two ports are forwarded, and only two**: WireGuard's `51820/udp`, and
Transmission's peer port `51413` (tcp+udp), open by design for seeding. The VPN
is the only entry point to the *services*, not the only hole in the router —
`51413` reaches a container. See ADR-013 and `docs/04-network/`.

No public HTTP/HTTPS: ports 80/443 are not forwarded. Certificates use the ACME
DNS-01 challenge (Cloudflare), so services need no public DNS record and are
reachable only through the VPN (resolved to the LAN IP via Pi-hole split DNS).
Only `vpn.example.com` stays in public DNS, to bootstrap the tunnel. See ADR-014.

## Quick Start

```bash
# 1. Flash Ubuntu Server 24.04 LTS arm64 to the SD card
# 2. First boot, note the Pi's IP address
# 3. Bootstrap (from your workstation)
./ops/bootstrap.sh <PI_IP>

# 4. Provision the entire system
cd ansible && ansible-playbook playbooks/site.yml
```

## Project Structure

```
├── docs/           # Documentation by domain
├── ansible/        # Full provisioning (Ansible)
├── docker/         # Containerized services (Docker Compose)
├── ops/            # Operator tools (run from the workstation)
├── knowledge/      # ADRs, research, runbooks
└── .claude/agents/ # Specialized AI agents
```

## Domain

`example.com` — subdomains for each exposed service.
