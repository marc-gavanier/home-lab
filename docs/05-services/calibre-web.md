# Calibre-Web-Automated

The ebook library on the web, and over **OPDS** — so an e-reader can browse and
download from it directly over the VPN, which is the reason it exists. 94 books,
mostly technical, in MOBI/EPUB/PDF.

## Access

- URL: `https://books.example.com` (VPN-only, like the other internal services —
  the subdomain only resolves on the LAN/VPN via Pi-hole split DNS).
- OPDS feed: `https://books.example.com/opds` — point an e-reader at it, with the
  same credentials.
- **Login required**, and see the next section before the first one.

## First login is mandatory, not optional

Calibre-Web ships a live default account. Verified rather than repeated from
documentation — logging in as `admin` / `admin123` returns 302 and the
authenticated page returns 200, against a freshly created `app.db`:

| | unauthenticated | as `admin`/`admin123` |
|---|---|---|
| `GET /` | 302 (login) | **200** |

There is **no environment variable** to set that password: the image exposes
none, and the credential lives in `/config/app.db`, which the application owns.
So this cannot be handled the way Dozzle's is (a bcrypt hash in the vault,
rendered to a file). It is a manual step, and the deployment is not finished
until it is done:

1. Open `https://books.example.com`, log in as `admin` / `admin123`.
2. **Admin → Users → admin → change the password.**
3. Log out, confirm `admin123` is refused.

The built-in password policy applies: at least 8 characters, upper, lower, digit
and special. Store the new password in Vaultwarden.

The rest of the defaults are sound and were checked at the same time:
`config_anonbrowse = 0` (no anonymous browsing), `config_public_reg = 0` (no
self-registration), `config_remote_login = 0`. A `Guest` account exists in the
schema but is inert while anonymous browsing is off.

## Who owns the library

**The Pi does.** `/mnt/data/media/books` is the single source of truth, and CWA
writes to it — it rewrote `metadata.db` on first run (the md5 changes, measured).

That matters: editing the same library from desktop Calibre would fork the two
copies silently, with no conflict and no error, just two divergent truths. The
copy under `~/Storage/Books/calibre` on the workstation is a **cold archive**
from the migration on 2026-08-05 and must not be edited.

New books get in two ways: uploaded through the web UI, or dropped into
`/mnt/data/media/books-ingest`, which CWA imports and then empties.

## Data and Restore

| Path | Content |
|---|---|
| `/mnt/data/media/books` | The Calibre library — books and `metadata.db` |
| `/mnt/data/media/books-ingest` | Drop folder, transient, normally empty |
| `/mnt/data/services/calibre-web` | CWA's own state: `app.db` (users, settings), `cwa.db` |

Both live inside the restic set already (`/mnt/data/media` and
`/mnt/data/services` are backed up), so the library and the accounts are covered
without any change to the backup configuration (`resticprofile.yaml`). It adds
**2.1 GB** to every backup target,
local and offsite.

Restore is the deploy role plus a restic restore of those paths.

## Why It Is Less Hardened Than Its Neighbours

This is the least hardened service in the stack, and the reasons are structural
rather than negligent. Full reasoning in
[ADR-025](../../knowledge/decisions/ADR-025-calibre-web-automated.md); the short
version:

- **No read-only rootfs.** `docker diff` shows **1797** entries — the image
  patches its own source tree and writes bytecode caches under `/app` at every
  start. It does not degrade without a writable layer, it fails to start.
- **Five capabilities**: `CHOWN`, `SETUID`, `SETGID`, `DAC_OVERRIDE`, `FOWNER`.
  This is a linuxserver-style s6 image, so the init runs as root, chowns the
  three mounts, then drops to `PUID`/`PGID`. Exactly the mechanism Transmission
  already uses, and the fifth service in the stack to keep `DAC_OVERRIDE`.
- **`user:` cannot remove the root phase.** Tried and measured: s6's preinit
  refuses a `/run` it does not own, an owned tmpfs is `noexec` by default, and
  with `exec` set s6 finally starts only to find `/app` root-owned in the image.
  It would take an upstream change to fix.

- **Root is not confined to the init phase**, which is where this is worse than
  Transmission and worth stating plainly. The web application does drop —
  `python3 /app/calibre-web-automated/cps.py` runs as uid 1000 — but four s6
  longruns stay root for the container's whole life: `cwa-ingest-service`,
  `metadata-change-detector`, `cwa-auto-zipper` and `svc-cron`. Transmission, by
  comparison, keeps only its s6 *supervisors* as root; `transmission-daemon`
  itself runs as uid 1000.

  The consequence to keep in mind: a file dropped into
  `/mnt/data/media/books-ingest` is untrusted input parsed by root-owned code
  inside the container, with those five capabilities available to it. Treat the
  ingest folder as a trusted path — drop your own books there, not files from
  strangers.

What limits the blast radius: the web application serving the network-facing
surface runs as uid 1000; the container has no access to the Docker socket; it
sits on the `proxy` network only; and it is behind `vpn-only` like everything
else.

## Health

- Healthcheck: `curl -fsS http://127.0.0.1:8083/login`, with a **600 s**
  `start_period`. The 120 s this page claimed until 2026-08-29 came from a warm
  measurement of the s6 init (~90 s); a cold boot with the disk saturated is not
  close to it. Measured 2026-08-27: started 00:14:04, first served 00:21:53 —
  **7 min 49 s**, and the container went unhealthy on that boot and the one
  before it (#258). A container reporting `(health: starting)` for several
  minutes after a cold boot is the design here, not a fault.
- **Not the image's own healthcheck.** During the capability testing, two broken
  variants reported `healthy` while failing to create `/app` caches or to install
  `/config/processed_books/*`. `docker ps` would have said the service was fine.
- Uptime Kuma: HTTP monitor on `https://books.example.com/login`, expecting
  **200**.

  **A green monitor here does not prove the library is readable.** Both broken
  variants above still served the login page, because the web app and the library
  fail independently. Proving the library works needs an authenticated request,
  which a Kuma HTTP check cannot make without storing credentials. This is the
  same limit Collabora hits (see `docs/07-observability/README.md`) — the monitor
  covers reachability and TLS expiry, not function.
