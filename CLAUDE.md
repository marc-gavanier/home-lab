# Home Lab — Project Conventions

## Context

Personal home lab on Raspberry Pi 4 (8GB RAM, 64GB SD, 5TB external HDD).
Goals: maximum automation, hardened security, self-hosted services.
Domain: example.com

## Tech Stack

| Layer           | Choice                                               |
|-----------------|------------------------------------------------------|
| OS              | Ubuntu Server 24.04 LTS arm64                        |
| Provisioning    | Ansible                                              |
| Services        | Docker Compose                                       |
| Reverse proxy   | Traefik (auto TLS via Let's Encrypt)                 |
| VPN             | WireGuard (wg-easy)                                  |
| DNS/Ad-blocking | Pi-hole                                              |
| Cloud/Files     | Nextcloud                                            |
| Backup          | Restic (encrypted, incremental)                      |
| Media           | Jellyfin (video), Navidrome (music), Immich (photos) |
| Passwords       | Vaultwarden                                          |
| Notes           | Obsidian (synced via Nextcloud)                      |
| Monitoring      | Uptime Kuma + Netdata                                |

## Project Structure

- `docs/` — Structured documentation by domain (markdown)
- `ansible/` — Ansible playbooks and roles for full provisioning
- `docker/` — Docker Compose stacks and service configurations
- `ops/` — Operator tools run from the workstation (bootstrap, kuma-dump)
- `knowledge/` — Knowledge base (ADRs, research, runbooks)
- `.claude/agents/` — Specialized agents by domain

## Conventions

- All documentation and code comments in English
- Sensitive variables never in plain text — use `.env` (gitignored) + `.env.example` as template
- Every architecture decision documented in `knowledge/decisions/` (ADR format)
- Test on the Pi before documenting as "working"

## Specialized Agents

Use agents in `.claude/agents/` for domain-specific tasks:

| Agent             | Domain                                                |
|-------------------|-------------------------------------------------------|
| `system`          | OS, kernel, performance, filesystem                   |
| `security`        | Hardening, firewall, audit, VPN                       |
| `network`         | DNS, reverse proxy, TLS, routing                      |
| `services`        | Docker service selection and configuration            |
| `backup`          | Data protection, restoration, disaster recovery       |
| `observability`   | Monitoring, logs, alerting                            |
| `ansible-deploy`  | Ansible roles, deployment, idempotence, vault         |
| `project-manager` | Coordination, planning, prioritization, documentation |

## Security — Non-negotiable Rules

- SSH: key-only authentication, password disabled, non-standard port
- UFW firewall: deny by default, explicit whitelist
- fail2ban active on SSH and exposed services
- Automatic security updates (unattended-upgrades)
- Secrets: never in the repo, never in plain text
- Exposed to the internet: WireGuard (51820/udp) and Transmission's peer port
  (51413). Traefik's 80/443 are **not** forwarded — the forward was removed in
  late July 2026, so Traefik only serves the LAN and the VPN
- Everything else accessible only via VPN or authenticated reverse proxy

## Storage

- SD card: OS + configs only
- 5TB HDD mounted at `/mnt/data`: service data, media, backups — **and the Docker
  store** (`docker_data_root: /mnt/data/docker`, so images and layers live there,
  not on the card). Two procedures depend on knowing this: an empty image list
  after a reboot means Docker started before the volume was unlocked, so the
  answer is to restart Docker and never to wipe; and reflashing the SD card
  costs no image, because none of them are on it.
