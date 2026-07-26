# SearXNG

Private metasearch engine — your own aggregator over Google/Bing/DuckDuckGo… without the tracking.

## Access

- URL: `https://search.example.com` (VPN-only, like the other internal services — the
  subdomain only resolves on the LAN/VPN via Pi-hole split DNS).

## What It Does

- Aggregates results from 70+ search engines and strips tracking from your queries.
- No ads, no profiling; you choose which engines are queried.

## Client Setup

### Browser
- Visit `https://search.example.com`.
- Make it your default search engine: add the search URL
  `https://search.example.com/search?q=%s` (browser Settings → Search engines).

## First Steps

1. Connect to the VPN (WireGuard) — the domain resolves only internally.
2. Open `https://search.example.com`.
3. Preferences (⚙): pick engines, language, safe-search. Preferences are stored in a
   per-device cookie (no account).

## Data

| Path                                        | Content                                           |
|---------------------------------------------|---------------------------------------------------|
| `/mnt/data/secrets/docker/searxng_settings` | Config, templated by Ansible (holds `secret_key`) |

Otherwise stateless — no database. The config lives on the LUKS volume, mounted
read-only into the container at `/etc/searxng/settings.yml`, and is covered by
the backup (`/mnt/data/secrets` is in the restic set). It is **not** a symlink
from `/opt/homelab`: a symlink inside a bind-mounted directory is resolved in
the container's namespace, where `/mnt/data/secrets` does not exist — which is
how this instance spent weeks on a self-generated stub config (issue #27).

## Restore

Nothing service-specific: re-running the deploy role re-renders `settings.yml` and brings
the container up. The config is covered by the `/opt/homelab` backup.

## Notes

- Runs **without** Redis/Valkey (single-user, VPN-only → limiter disabled). Add Valkey
  later for caching / rate-limiting if wanted (e.g. after the 8 GB upgrade).
