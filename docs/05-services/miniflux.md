# Miniflux

A feed reader that stays out of the way: no recommendations, no tracking, no mobile app
to install. It fetches feeds, stores them in Postgres, and serves a page.

The reason it is here is less about reading blogs than about **watching this stack**.
Subscribing to the GitHub release feed of each self-hosted service turns Renovate's
version bump into something readable — Renovate says `netdata 2.10.4 → 2.11.0`, the feed
says what changed in it.

## Access

- URL: `https://rss.example.com` (VPN-only, like the other internal services — the
  subdomain only resolves on the LAN/VPN via Pi-hole split DNS).
- Login with the admin account created at first start (see *The admin account* below).
- Feeds can be added by URL, or in bulk by importing an OPML file.

## How It Runs

Two containers: `miniflux` and its own `miniflux-db`.

Miniflux is the lightest well-behaved service in the stack. `docker diff` on a container
that had run all 132 migrations, created the admin account and served traffic came back
with an **empty write set** — so `read_only: true` costs nothing and it carries **no
tmpfs at all**, the only service here with neither. It runs as uid 65534 with **zero
capabilities**; 65534 is already the image's own default, restated in `compose.yaml` so a
base-image change cannot move it silently.

The image is **distroless**: no shell, no `curl`, no `wget`. That is not a limitation to
work around, it decides the healthcheck for us:

```yaml
test: ["CMD", "/usr/bin/miniflux", "-healthcheck", "auto"]
```

The binary's own subcommand issues a real HTTP request against the listener, so a Miniflux
that is up but no longer serving fails it. A `CMD-SHELL` probe could not run in this image
at all.

One setting is easy to miss: `LISTEN_ADDR` defaults to `127.0.0.1:8080`, which inside a
container means the process answers only itself and Traefik gets connection refused. It is
set to `0.0.0.0:8080` explicitly.

## The Database, and the Trap in It

`miniflux-db` is **Postgres 18**, not the 16 `immich-db` pins — this database is
Miniflux's alone, so there is no schema to match.

**Do not copy `immich-db`'s volume line.** Postgres 18 moved its datadir:

```
PGDATA=/var/lib/postgresql/18/docker     # Postgres 18
VOLUME /var/lib/postgresql               # the volume is now the PARENT
```

So the bind mount is the parent directory:

```yaml
- ${SERVICES_DATA_DIR}/miniflux/db:/var/lib/postgresql
```

Mounting `/var/lib/postgresql/data` instead — the path that is correct for Immich's
Postgres 16 — would leave the real datadir *inside* the container. It would survive
restarts and vanish on the first `--force-recreate`, with nothing looking wrong until the
feeds came back empty.

Both of its tmpfs mounts carry `uid=999,gid=999`, which `immich-db` does not need:

```yaml
- /run/postgresql:uid=999,gid=999
- /tmp:size=64m,uid=999,gid=999
```

A tmpfs mounts root-owned `0755`, and the alpine entrypoint chmods its socket directory
before dropping privilege — with zero capabilities there is no root phase left to do it.
Without the uid the container exits on `chmod: /var/run/postgresql: Operation not
permitted`; fix that alone and it exits on `mktemp: : Read-only file system`, because
initdb wants a scratch directory. Both were observed, not anticipated.

## The Admin Account

Created at first start from `CREATE_ADMIN=1`, `ADMIN_USERNAME` and
`ADMIN_PASSWORD_FILE`. The flag stays on across deploys — Miniflux skips creation when the
account already exists, so it is idempotent rather than a first-boot flag someone has to
remember to remove.

**The password must be 72 bytes or fewer.** bcrypt reads no further, and Miniflux refuses
rather than truncating:

```
bcrypt: password length exceeds 72 bytes
```

The container then exits 1, and because the schema migrations have already succeeded by
that point, `miniflux-db` sits there **healthy** while the reader is down — the failure
looks like a database problem and is not one. The heal timer retries the same failure
every two minutes, so the log fills with identical lines rather than one clear error.

This bit on the first deploy (2026-08-13) with a 128-byte password-manager passphrase.
Nothing was corrupted: the `users` table stays empty, so shortening the password and
redeploying creates the account cleanly. Note **bytes**, not characters — accented or
non-Latin characters cost 2-4 bytes each in UTF-8. Same ceiling Dozzle documents.

**Changing `miniflux_admin_password` in the vault does not rotate the account.** Miniflux
only reads that value when the user is absent. To change the password, use *Settings →
Password* in the web UI, then update the vault so a rebuild-from-scratch matches.

## Secrets

Three files rather than the usual one, because Miniflux takes a whole connection string
rather than a password to slot into one — so the string is what has to stay off
`environment:` (ADR-016):

| File under `/mnt/data/secrets/docker/` | Read by | Contents |
|----------------------------------------|---------------|--------------------------|
| `miniflux_db_password` | `miniflux-db` | bare password |
| `miniflux_database_url` | `miniflux` | full DSN, same password |
| `miniflux_admin_password` | `miniflux` | admin account password |

All three are composed by the deploy role from two vault variables
(`miniflux_db_password`, `miniflux_admin_password`) and written `0444`.

## Data and Restore

Everything lives in Postgres under `${SERVICES_DATA_DIR}/miniflux/db`, inside the restic
set like the rest of `/mnt/data`. There is no separate application volume.

The portable escape hatch is **OPML export** (*Settings → Export*): it carries the
subscription list, not the read/unread state or starred entries.

**Do not restore the datadir.** The nightly backup writes a plain-SQL `pg_dump` to
the dump directory, and that is what a restore loads. restic walks
`services/miniflux/db` file by file while Postgres is writing to it, so the copy in
a snapshot can be a torn cluster — it is in the restic set because everything under
`/mnt/data` is, not because it is restorable.

Full procedure: `knowledge/runbooks/restore-from-backup.md` → "Restore Miniflux
(PostgreSQL)". It is not repeated here, for the reason the other service pages give:
a procedure duplicated in two places drifts in one of them.

## Health

- Healthcheck: the binary's own `-healthcheck auto` (see above).
- Uptime Kuma — **one** monitor, following the rule Dozzle established of probing a
  function endpoint rather than `/`:

  | Monitor | Type | Target | Expect |
  |----------|------|---------------------------------------|--------|
  | Miniflux | HTTP | `https://rss.example.com/healthcheck` | 200 |

  A second monitor on `/` was specified and then dropped, because the assumption behind it
  was wrong. The theory was that `/healthcheck` answers from the process alone and would
  stay green with Postgres down. Measured by stopping `miniflux-db`:

  | Endpoint | Database up | Database down |
  |----------------|------------:|--------------:|
  | `/healthcheck` | 200 | **503** |
  | `/` | 200 | 500 |

  Miniflux's healthcheck pings the database, so both endpoints fail together and one
  monitor already covers the process, its storage, Traefik and TLS expiry. The same test
  showed `docker ps` still reporting `healthy` while the service returned 503 — the 30 s
  interval had not re-run — which is the argument for having a Kuma monitor at all.

  It is added by hand in the Kuma UI: Kuma v2 has no supported automation, and the export
  in `ops/kuma-dump.sh` is a read-only snapshot.

## Related

- [ADR-026](../../knowledge/decisions/ADR-026-miniflux-rss.md) — why Postgres 18, the
  moved datadir, and the DSN-as-secret split.
- Issue #15 — services shortlist. The `claude -p` morning digest is part of that entry and
  is **not** built: it is a separate Ansible role with a long-lived OAuth token, out of
  scope here.
