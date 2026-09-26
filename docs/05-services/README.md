# Services

Every service runs as a Docker container from one Docker Compose file. Persistent data lives on the 5 TB HDD.

## Deployed Services

| Service                         | Description                       | Category       |
|---------------------------------|-----------------------------------|----------------|
| [Traefik](traefik.md)           | Reverse proxy, automatic TLS      | Infrastructure |
| [Pi-hole](pihole.md)            | Local DNS, ad/tracker blocking    | Infrastructure |
| [WireGuard](wireguard.md)       | VPN remote access                 | Infrastructure |
| [Nextcloud](nextcloud.md)       | Cloud files, sync, mobile         | Essential      |
| [Collabora](collabora.md)       | Collaborative document editing    | Productivity   |
| [LibreSign](libresign.md)       | PDF signing (Nextcloud app)       | Productivity   |
| [Vaultwarden](vaultwarden.md)   | Password manager                  | Essential      |
| [Jellyfin](jellyfin.md)         | Video streaming                   | Secondary      |
| [Navidrome](navidrome.md)       | Music streaming                   | Secondary      |
| [Immich](immich.md)             | Photo management                  | Secondary      |
| [Transmission](transmission.md) | BitTorrent client                 | Secondary      |
| [Netdata](netdata.md)           | System monitoring                 | Observability  |
| [Uptime Kuma](uptime-kuma.md)   | Availability monitoring           | Observability  |
| [Dozzle](dozzle.md)             | Container logs in the browser     | Observability  |
| [Claude Code](claude-code.md)   | AI agent for the notes vault      | Productivity   |
| [SearXNG](searxng.md)           | Private metasearch engine         | Productivity   |
| [IT-Tools](it-tools.md)         | Offline developer toolbox         | Productivity   |
| [Calibre-Web](calibre-web.md)   | Ebook library, OPDS               | Secondary      |
| [Miniflux](miniflux.md)         | RSS reader, release tracking      | Productivity   |
| [Forgejo](forgejo.md)           | Self-hosted git, GitHub mirror    | Secondary      |
| [Prowlarr](arr-stack.md)        | Indexer manager for the two below | Secondary      |
| [Sonarr](arr-stack.md)          | Series: search and import         | Secondary      |
| [Radarr](arr-stack.md)          | Films: search and import          | Secondary      |

- Three infrastructure sidecars have no page here: `dnsproxy` (DoH upstream, shares Pi-hole's
  network namespace), `socket-proxy` (filtered Docker API for Traefik, Netdata and Dozzle) and
  `traefik-log-redactor`. See `docs/04-network/` and `docs/03-security/`.
- Notes live in Obsidian (client app, synced via Nextcloud), managed by Claude Code on the Pi —
  see [ADR-005](../../knowledge/decisions/ADR-005-obsidian-notes-system.md).

## RAM Budget

The host has 8 GB. Figures with `~` are estimates; the others were measured at idle. Re-measure
on the host rather than trust the sum.

| Service                 | RAM         |
|-------------------------|-------------|
| OS + system             | ~500 MB     |
| Traefik                 | ~50 MB      |
| Pi-hole                 | ~100 MB     |
| WireGuard               | ~30 MB      |
| Nextcloud + MariaDB     | ~450 MB     |
| Vaultwarden             | ~30 MB      |
| Jellyfin                | ~300 MB     |
| Navidrome               | ~50 MB      |
| Immich + PostgreSQL     | ~1000 MB    |
| Transmission            | ~80 MB      |
| Netdata                 | ~150 MB     |
| Uptime Kuma             | ~80 MB      |
| Claude Code             | ~300 MB     |
| SearXNG                 | ~200 MB     |
| Collabora Online        | 573 MB      |
| Dozzle                  | 30 MB       |
| IT-Tools                | 4 MB        |
| Calibre-Web             | 353 MB      |
| Miniflux + PostgreSQL   | 77 MB       |
| Forgejo                 | 101 MB      |
| Prowlarr                | 85 MB       |
| Sonarr                  | 143 MB      |
| Radarr                  | 87 MB       |
| **Total**               | **~4.8 GB** |

- Collabora grows with the number of open documents (ADR-021). Dozzle holds no logs, it streams
  them. IT-Tools is static nginx (ADR-024). Miniflux's Go binary is 14 MB of its 77.
- The three `arr` figures are cgroup `anon` plus `memory.swap.current`. Their reclaimable page
  cache (82-96 MB each) is not counted, and `docker stats` would understate them (resident
  pages only).
- LibreSign has no line: its JVM exits after each signature. It costs 185 MB of disk on
  `/mnt/data` for its JRE and jars (ADR-022).
- Calibre-Web (1.74 GB unpacked) and Uptime Kuma (1.75 GB) are the two largest images. Images
  live on `/mnt/data/docker`, not the SD card.
