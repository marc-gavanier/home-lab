# Calibre-Web-Automated

The ebook library on the web and over OPDS, so an e-reader can browse and download from it over
the VPN.

## At a glance

| | |
|---|---|
| URL | `https://books.example.com` (VPN-only, Pi-hole split DNS) |
| OPDS | `https://books.example.com/opds`, same credentials |
| Login | required — change the default first, see below |
| Data | `/mnt/data/media/books`, `/mnt/data/media/books-ingest`, `/mnt/data/services/calibre-web` |
| Backup | restic, no extra config (adds 2.5 GB per target) |
| Supervision | healthcheck + Uptime Kuma on `/login` |
| ADR | [ADR-025](../../knowledge/decisions/ADR-025-calibre-web-automated.md) |

| Path | Content |
|---|---|
| `/mnt/data/media/books` | The Calibre library — books and `metadata.db` |
| `/mnt/data/media/books-ingest` | Drop folder, transient, normally empty |
| `/mnt/data/services/calibre-web` | CWA's own state: `app.db` (users, settings), `cwa.db` |

## First login (mandatory)

The image ships a live `admin` / `admin123` account, and no environment variable can change it
(the credential lives in `/config/app.db`). The deploy is not finished until you:

1. Open `https://books.example.com`, log in as `admin` / `admin123`.
2. Admin → Users → admin → change the password (8+ chars, upper, lower, digit, special).
3. Log out, confirm `admin123` is refused.
4. Store the new password in Vaultwarden.

Other defaults are safe: `config_anonbrowse = 0`, `config_public_reg = 0`,
`config_remote_login = 0`. The `Guest` account is inert while anonymous browsing is off.

## How it works

- The Pi owns the library. CWA writes to `/mnt/data/media/books` (including `metadata.db`).
- Never edit `~/Storage/Books/calibre` on the workstation: it is a cold archive, and editing it
  would fork the library silently.
- Add books through the web UI, or drop them into `/mnt/data/media/books-ingest` (imported, then
  emptied).
- Auto-convert is off (Admin → CWA Settings): a book stays in the format it was dropped in. CWA's
  default converts to EPUB and moves the original to `processed_books/converted/`, out of the
  library. The setting lives in `cwa.db`, not in the repo; nothing checks it.
- Restore: run the deploy role, then a restic restore of the three paths.

## Hardening limits

The least hardened service in the stack, for structural reasons (ADR-025):

- No read-only rootfs: the image writes under `/app` at every start and fails without a writable
  layer.
- Five capabilities: `CHOWN`, `SETUID`, `SETGID`, `DAC_OVERRIDE`, `FOWNER` (s6 init as root, then
  drops to `PUID`/`PGID`).
- `user:` cannot remove the root phase — it needs an upstream change.
- Four s6 longruns stay root for the container's life: `cwa-ingest-service`,
  `metadata-change-detector`, `cwa-auto-zipper`, `svc-cron`. The web app
  (`python3 /app/calibre-web-automated/cps.py`) runs as uid 1000.
- So root code parses whatever lands in `books-ingest`: drop only your own books there.
- Limits: no Docker socket, `proxy` network only, behind `vpn-only`.

## Health

- Healthcheck: `curl -fsS http://127.0.0.1:8083/login`, `start_period` 900 s. A cold boot takes
  ~800-830 s to healthy; `(health: starting)` for minutes after a boot is normal.
- The image's own healthcheck is not used: it reported `healthy` on broken builds.
- Uptime Kuma: HTTP monitor on `https://books.example.com/login`, expecting 200.

## Troubleshooting

| Symptom | Cause | Action |
|---|---|---|
| Kuma green, but books do not open | Web app and library fail independently; the monitor proves reachability and TLS only | Log in and open a book by hand |
| `(health: starting)` for several minutes after boot | Slow cold start | Wait up to the 900 s `start_period` |
