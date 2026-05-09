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
| RAM          | 4 GB LPDDR4                 |
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
| Notes             | HedgeDoc              | Collaborative markdown editor |
| Reverse proxy     | Traefik               | Automatic TLS, routing        |
| Backup            | Restic                | Encrypted incremental backup  |
| Monitoring        | Uptime Kuma + Netdata | Uptime and system monitoring  |

## Network Architecture

```
Internet → ISP Router (ports 80, 443, 51820)
               │
               ├─ :80/:443 → Traefik (reverse proxy + TLS Let's Encrypt)
               │                 ├─ nextcloud.example.com
               │                 ├─ vault.example.com
               │                 ├─ notes.example.com
               │                 └─ ...
               │
               └─ :51820/udp → WireGuard VPN
                                 └─ Full LAN access
```

## Quick Start

```bash
# 1. Flash Ubuntu Server 24.04 LTS arm64 to the SD card
# 2. First boot, note the Pi's IP address
# 3. Bootstrap (from your workstation)
./scripts/bootstrap.sh <PI_IP>

# 4. Provision the entire system
cd ansible && ansible-playbook playbooks/site.yml
```

## Project Structure

```
├── docs/           # Documentation by domain
├── ansible/        # Full provisioning (Ansible)
├── docker/         # Containerized services (Docker Compose)
├── scripts/        # Utility scripts
├── knowledge/      # ADRs, research, runbooks
└── .claude/agents/ # Specialized AI agents
```

## Domain

`example.com` — subdomains for each exposed service.
