# Architecture Overview

## Summary

This home lab is built on a Raspberry Pi 4 Model B with the goal of providing a secure, fully automated, and documented self-hosting platform.

## Guiding Principles

1. **Full automation**: a single `ansible-playbook` provisions everything, from bare metal to running services
2. **Defense in depth**: each layer (OS, network, Docker, application) is hardened independently
3. **Simplicity**: Docker Compose on a single node, no Kubernetes, no over-engineering
4. **Reproducibility**: all configuration is version-controlled, the Pi can be rebuilt from scratch
5. **Documentation**: every decision is explained and documented

## Architecture Diagram

```
┌─────────────────────────────────────────────────┐
│                   Internet                       │
└──────────────────────┬──────────────────────────┘
                       │
┌──────────────────────┴──────────────────────────┐
│              ISP Router (NAT/Firewall)            │
│         Open ports: 80, 443, 51820/udp           │
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
│  │  Nextcloud  Vaultwarden  HedgeDoc         │  │
│  │  Jellyfin   Navidrome    Immich           │  │
│  │  Uptime Kuma                              │  │
│  └────────────────────────────────────────────┘  │
│                                                  │
│  ┌────────────────────────────────────────────┐  │
│  │        Docker Network (internal)           │  │
│  │  Pi-hole  Netdata  Databases              │  │
│  └────────────────────────────────────────────┘  │
│                                                  │
│  ┌──────────────┐  ┌─────────────────────────┐  │
│  │  SD 64 GB    │  │  HDD 5 TB (/mnt/data)   │  │
│  │  OS + Docker │  │  services/ media/        │  │
│  │  images      │  │  backups/                │  │
│  └──────────────┘  └─────────────────────────┘  │
└──────────────────────────────────────────────────┘
```

## Implementation Phases

See the `project-manager` agent for the detailed plan.

| Phase                  | Content                               | Status |
|------------------------|---------------------------------------|--------|
| 1 - Foundations        | OS, storage, security, Docker         | Done   |
| 2 - Network            | Traefik, Pi-hole, WireGuard           | Done   |
| 3 - Essential services | Nextcloud, Vaultwarden, Backup        | Done   |
| 4 - Secondary services | Jellyfin, Navidrome, Immich, HedgeDoc | Done   |
| 5 - Observability      | Netdata, Uptime Kuma, alerting        | Done   |
