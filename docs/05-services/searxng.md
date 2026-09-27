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
- Web engines: Google CSE, Bing, `duckduckgo web`. Refused from this address, so disabled:
  `duckduckgo` (CAPTCHA), Brave (429), Startpage (CAPTCHA), Qwant, Mojeek and Presearch (403).
  SearXNG drops a refused engine silently and `/healthz` stays OK: test one with
  `/search?q=test&engines=<name>` and read `docker logs searxng 2>&1 | grep 'ERROR:searx.engines'`.
- Preferences live in a per-device cookie.
- At every start SearXNG downloads the ClearURLs rules from a third party, unpinned. Accepted:
  they can only strip parameters from result links.

## Common tasks

- Default search engine: `https://search.example.com/search?q=%s`.
- Restore: re-run the deploy role; it re-renders `settings.yml`.
