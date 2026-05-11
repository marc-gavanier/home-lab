# ADR-001: Tech Stack Selection

**Date**: 2026-05-09
**Status**: Accepted
**Deciders**: Owner

## Context

Setting up a home lab on Raspberry Pi 4 (4GB RAM, arm64) to self-host personal services. Main constraints are limited RAM, ARM architecture, and learning objectives in security and automation.

## Decisions

### OS: Ubuntu Server 24.04 LTS arm64
- **Reason**: 10-year LTS, excellent arm64 support on Pi 4, abundant documentation, large community
- **Alternatives considered**: Raspberry Pi OS (less standard), Debian (smaller arm64 community), Alpine (too minimalist for a first home lab)

### Provisioning: Ansible
- **Reason**: Agentless (no daemon on the Pi), declarative YAML, idempotent, large module ecosystem
- **Alternatives considered**: Bash scripts (not idempotent), Terraform (better suited for cloud), NixOS (steep learning curve)

### Containerization: Docker Compose
- **Reason**: Simple, mature, perfect for single-node, single YAML file
- **Alternatives considered**: K3s/K8s (over-engineering for a single node), Podman (less community support for images)

### Reverse Proxy: Traefik v3
- **Reason**: Native Docker integration (labels), automatic TLS via Let's Encrypt, dashboard, lightweight
- **Alternatives considered**: Nginx Proxy Manager (simpler but less flexible), Caddy (also good, matter of preference)

### VPN: WireGuard (wg-easy)
- **Reason**: Modern protocol, performant, low footprint, excellent on ARM, web UI with wg-easy
- **Alternatives considered**: OpenVPN (heavier, older), Tailscale (external dependency)

### Backup: Restic
- **Reason**: AES-256 encryption, deduplication, incremental, lightweight, supports many backends
- **Alternatives considered**: BorgBackup (similar but fewer backends), rsync (no native encryption)

### DNS: Pi-hole
- **Reason**: Ad/tracker blocking, local DNS for split DNS, web interface, lightweight
- **Alternatives considered**: AdGuard Home (also good, matter of preference)

### Monitoring: Uptime Kuma + Netdata
- **Reason**: Lightweight, simple, suited for Pi, no heavy stack like Prometheus/Grafana
- **Alternatives considered**: Prometheus + Grafana (too RAM-hungry for a 4GB Pi)

## Consequences

- Estimated RAM budget ~2.9 GB out of 4 GB — tight but feasible with swap
- Immich (photos) is the most resource-hungry service (~1 GB) — first candidate to disable if RAM is insufficient
- All Docker images must support arm64
- Single-node approach simplifies architecture but creates a SPOF (single point of failure)
