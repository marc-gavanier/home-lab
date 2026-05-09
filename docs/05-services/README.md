# Services

## Overview

All services run as Docker containers, orchestrated by Docker Compose. Persistent data is stored on the 5TB HDD.

## Deployed Services

| Service                       | Description                    | Priority       | Phase   |
|-------------------------------|--------------------------------|----------------|---------|
| [Traefik](traefik.md)         | Reverse proxy, automatic TLS   | Infrastructure | Phase 2 |
| [Pi-hole](pihole.md)          | Local DNS, ad/tracker blocking | Infrastructure | Phase 2 |
| [WireGuard](wireguard.md)     | VPN remote access              | Infrastructure | Phase 2 |
| [Nextcloud](nextcloud.md)     | Cloud files, sync, mobile      | Essential      | Phase 3 |
| [Vaultwarden](vaultwarden.md) | Password manager               | Essential      | Phase 3 |
| [Jellyfin](jellyfin.md)       | Video streaming                | Secondary      | Phase 4 |
| [Navidrome](navidrome.md)     | Music streaming                | Secondary      | Phase 4 |
| [Immich](immich.md)           | Photo management               | Secondary      | Phase 4 |
| [HedgeDoc](hedgedoc.md)       | Markdown notes                 | Secondary      | Phase 4 |
| [Netdata](netdata.md)         | System monitoring              | Observability  | Phase 5 |
| [Uptime Kuma](uptime-kuma.md) | Availability monitoring        | Observability  | Phase 5 |

## Estimated RAM Budget

| Service               | Estimated RAM |
|-----------------------|---------------|
| OS + system           | ~500 MB       |
| Traefik               | ~50 MB        |
| Pi-hole               | ~100 MB       |
| WireGuard             | ~30 MB        |
| Nextcloud + MariaDB   | ~400 MB       |
| Vaultwarden           | ~30 MB        |
| Jellyfin              | ~300 MB       |
| Navidrome             | ~50 MB        |
| Immich + PostgreSQL   | ~1000 MB      |
| HedgeDoc + PostgreSQL | ~200 MB       |
| Netdata               | ~150 MB       |
| Uptime Kuma           | ~80 MB        |
| **Total**             | **~2.9 GB**   |

With 4GB RAM and swap on the HDD, this is feasible but tight. If needed, Immich will be the first to disable.
