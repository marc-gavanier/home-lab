# Paperless-ngx

Administrative papers, OCR'd, classified and searchable. Paperless is the only writer of the
papers tree; Nextcloud and the workstation read it. Under evaluation
([ADR-042](../../knowledge/decisions/ADR-042-paperless-ngx-trial.md), #422).

## At a glance

| Item       | Value                                                                 |
|------------|-----------------------------------------------------------------------|
| URL        | `https://papers.example.com` (VPN/LAN only, Pi-hole split DNS)        |
| Containers | `paperless` (uid 33, SQLite), `paperless-redis` (uid 999, task queue) |
| Login      | `admin`, created on first start from `paperless_admin_password`       |
| Ingest     | Nextcloud `/Inbox`, the web UI, or the mobile app                     |
| Read       | Nextcloud `/Papers`, read-only, synced within 10 minutes              |
| Data       | `/mnt/data/services/paperless/{data,media,consume,scratch,redis}`     |
| Backup     | restic (`/mnt/data/services`) + SQLite dump; `scratch` excluded       |
| Monitoring | Kuma HTTP monitor on `/accounts/login/`                               |
| Startup    | wave 3, `start_period` 900 s                                          |

| Path               | Content                                                                      |
|--------------------|------------------------------------------------------------------------------|
| `data/`            | `db.sqlite3`, search index, classifier model                                 |
| `media/documents/` | `originals/` (the tree `/Papers` shows), `archive/` (OCR'd PDFs), thumbnails |
| `consume/`         | `/Inbox`: files waiting to be imported                                       |
| `scratch/`         | uploads and OCR work in progress                                             |
| `redis/`           | the task queue, append-only file                                             |

## How it works

- **Paperless owns the files.** It names and moves every original according to the document's
  storage path, so the tree under `/Papers` is the classification. Never move or rename a file
  there by hand: Paperless remembers each path and reports the document missing. `/Papers` is
  read-only in Nextcloud for that reason.
- **Storage paths reproduce `~/Storage/Documents`**: `<Person>/<Domain>/<correspondent>/<date> -
  <correspondent> - <title>`. They and the workflows live in the database (UI), not in the repo.
  A document no storage path claims lands in `Unfiled/`.
- **What it does on its own:**
  - deletes each file from `consume/` (`/Inbox`) once imported;
  - renames and moves an original whenever its metadata changes;
  - empties its trash 30 days after a deletion (upstream default);
  - retrains its classifier hourly.
- A folder dropped into `/Inbox` is read recursively. Workflows match on the path a file was
  dropped under (`*/Marc/Banque/CIC/*`) and assign its storage path, correspondent and type;
  folder names do not become tags.
- A file name starting with a date (`2024-08-01 - FMA - …`) gives the document its date
  (`PAPERLESS_FILENAME_DATE_ORDER=YMD`); otherwise Paperless takes the first date in the text,
  which can be a birth date.
- Ignored in the inbox: Nextcloud partial uploads (`.part`, `.ocTransferId`) and LibreOffice
  locks, on top of the upstream defaults. The patterns are regular expressions, not globs.
- Sized for the Pi: SQLite, one task worker, one thread, one web worker, no Tika/Gotenberg
  (no Office documents). French OCR ships in the image.
- **Hardening:** zero capabilities, `no-new-privileges`, read-only rootfs, uid 33 at PID 1 (the
  image's non-root mode, `S6_READ_ONLY_ROOT=1`). s6 needs `/run` mounted `exec`.
- **Redis** has no password: Celery messages are HMAC-signed with the secret key
  (`signed-pickle`), so writing to the queue does not run code in Paperless.
- For maintenance use `docker compose down paperless`, never `docker stop`: the heal timer
  restarts a stopped container.

## Common tasks

### Import papers

Copy them into `/Inbox` (Nextcloud web UI or a synced folder). Keep the originals elsewhere until
the import is checked.

### Change the admin password

In the UI (profile → password), then in the vaulted `local.yml`. The deploy only uses the vault
value when the account does not exist yet.

### Restore

[restore-from-backup.md → Restore Paperless](../../knowledge/runbooks/restore-from-backup.md#restore-paperless-sqlite).

## Troubleshooting

| Symptom                                       | Cause                                                      | Action                                                           |
|-----------------------------------------------|------------------------------------------------------------|------------------------------------------------------------------|
| A file stays in `/Inbox`                      | Consumer or task worker stuck; Kuma stays green            | `docker logs paperless`, then `docker compose restart paperless` |
| Document "missing" in the UI                  | A file under `media/documents/originals` was moved by hand | Move it back to the path the UI shows                            |
| `(health: starting)` for minutes after a boot | Slow cold start                                            | Wait up to the 900 s `start_period`                              |
| 404 on `papers.example.com`                   | Container not yet healthy: Traefik withholds the router    | Wait, or read the healthcheck log                                |

Upstream docs: <https://docs.paperless-ngx.com/>
