# SearXNG

Private metasearch engine: queries 70+ engines for you, without tracking, ads or
an account.

## At a glance

| Item   | Value                                                                      |
|--------|----------------------------------------------------------------------------|
| URL    | `https://search.example.com` (VPN only, Pi-hole split DNS)                 |
| Config | `/mnt/data/secrets/docker/searxng_settings` (Ansible template, `secret_key`) |
| State  | None                                                                       |
| Backup | The config, via `/mnt/data/secrets` in restic                              |

## How it works

- The config is bind-mounted read-only at `/etc/searxng/settings.yml`. Never a
  symlink from `/opt/homelab`: it would dangle inside the container, and SearXNG
  would silently run a generated stub.
- No Redis/Valkey: single user on the VPN, limiter off.
- Preferences live in a per-device cookie.
- At every start SearXNG downloads the ClearURLs rules from a third party, unpinned. Accepted:
  they can only strip parameters from result links.

## Common tasks

- Default search engine: `https://search.example.com/search?q=%s`.
- Restore: re-run the deploy role; it re-renders `settings.yml`.
