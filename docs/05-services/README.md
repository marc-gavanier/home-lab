# Services

## Overview

All services run as Docker containers, orchestrated by Docker Compose. Persistent data is stored on the 5TB HDD.

## Deployed Services

| Service                         | Description                    | Priority       | Phase   |
|---------------------------------|--------------------------------|----------------|---------|
| [Traefik](traefik.md)           | Reverse proxy, automatic TLS   | Infrastructure | Phase 2 |
| [Pi-hole](pihole.md)            | Local DNS, ad/tracker blocking | Infrastructure | Phase 2 |
| [WireGuard](wireguard.md)       | VPN remote access              | Infrastructure | Phase 2 |
| [Nextcloud](nextcloud.md)       | Cloud files, sync, mobile      | Essential      | Phase 3 |
| [Vaultwarden](vaultwarden.md)   | Password manager               | Essential      | Phase 3 |
| [Jellyfin](jellyfin.md)         | Video streaming                | Secondary      | Phase 4 |
| [Navidrome](navidrome.md)       | Music streaming                | Secondary      | Phase 4 |
| [Immich](immich.md)             | Photo management               | Secondary      | Phase 4 |
| [Transmission](transmission.md) | BitTorrent client              | Secondary      | Phase 4 |
| [Netdata](netdata.md)           | System monitoring              | Observability  | Phase 5 |
| [Uptime Kuma](uptime-kuma.md)   | Availability monitoring        | Observability  | Phase 5 |
| [Claude Code](claude-code.md)   | AI agent for the notes vault   | Productivity   | Phase 5 |
| [SearXNG](searxng.md)           | Private metasearch engine      | Productivity   | Phase 5 |

> Notes live in **Obsidian** (a client app on PC/mobile, synced via Nextcloud), managed by
> Claude Code on the Pi — see [ADR-005](../../knowledge/decisions/ADR-005-obsidian-notes-system.md).

## Estimated RAM Budget

| Service               | Estimated RAM |
|-----------------------|---------------|
| OS + system           | ~500 MB       |
| Traefik               | ~50 MB        |
| Pi-hole               | ~100 MB       |
| WireGuard             | ~30 MB        |
| Nextcloud + MariaDB   | ~450 MB       |
| Vaultwarden           | ~30 MB        |
| Jellyfin              | ~300 MB       |
| Navidrome             | ~50 MB        |
| Immich + PostgreSQL   | ~1000 MB      |
| Transmission          | ~80 MB        |
| Netdata               | ~150 MB       |
| Uptime Kuma           | ~80 MB        |
| Claude Code           | ~300 MB       |
| SearXNG               | ~200 MB       |
| **Total**             | **~3.3 GB**   |

With 4GB RAM and swap on the HDD, this is feasible but tight. If needed, Immich will be the first to disable.
