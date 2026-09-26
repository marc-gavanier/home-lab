# Architecture Overview

A secure, fully automated self-hosting platform on a single Raspberry Pi 4
Model B. This page shows the layout and the principles every change follows.

## Guiding Principles

1. **Full automation**: one `ansible-playbook` provisions everything, bare metal to running services.
2. **Defense in depth**: OS, network, Docker and application are each hardened independently.
3. **Simplicity**: Docker Compose on one node, no Kubernetes.
4. **Reproducibility**: all configuration is in git; the Pi can be rebuilt from scratch.
5. **Documentation**: every decision is recorded (`knowledge/decisions/`).

## Architecture Diagram

```
┌─────────────────────────────────────────────────┐
│                   Internet                       │
└──────────────────────┬──────────────────────────┘
                       │
┌──────────────────────┴──────────────────────────┐
│              ISP Router (NAT/Firewall)            │
│      Forwarded: 51820/udp (WG), 51413 (peer)     │
│      80/443: NOT forwarded                        │
└──────────────────────┬──────────────────────────┘
                       │ Ethernet
┌──────────────────────┴──────────────────────────┐
│              Raspberry Pi 4 (Ubuntu Server)      │
│                                                  │
│  ┌─────────────┐  ┌──────────────────────────┐  │
│  │  WireGuard   │  │        Traefik           │  │
│  │  :51820/udp  │  │   :80 → :443 (redirect) │  │
│  └──────┬──────┘  └──────────┬───────────────┘  │
│         │                    │                   │
│  ┌──────┴────────────────────┴───────────────┐  │
│  │           Docker Network (proxy)           │  │
│  │                                            │  │
│  │  Nextcloud  Vaultwarden                   │  │
│  │  Jellyfin   Navidrome    Immich           │  │
│  │  Uptime Kuma  Netdata                     │  │
│  └────────────────────────────────────────────┘  │
│                                                  │
│  ┌────────────────────────────────────────────┐  │
│  │        Docker Network (internal)           │  │
│  │  Pi-hole  Databases                       │  │
│  └────────────────────────────────────────────┘  │
│                                                  │
│  ┌──────────────┐  ┌─────────────────────────┐  │
│  │  SD 64 GB    │  │  HDD 5 TB (/mnt/data)   │  │
│  │  OS + config │  │  docker/ services/      │  │
│  │              │  │  media/ backups/        │  │
│  └──────────────┘  └─────────────────────────┘  │
└──────────────────────────────────────────────────┘
```

## Implementation Phases

| Phase                  | Content                               | Status |
|------------------------|---------------------------------------|--------|
| 1 - Foundations        | OS, storage, security, Docker         | Done   |
| 2 - Network            | Traefik, Pi-hole, WireGuard           | Done   |
| 3 - Essential services | Nextcloud, Vaultwarden, Backup        | Done   |
| 4 - Secondary services | Jellyfin, Navidrome, Immich           | Done   |
| 5 - Observability      | Netdata, Uptime Kuma, alerting        | Done   |
| 6 - Media automation   | Prowlarr, Sonarr, Radarr              | Done   |
