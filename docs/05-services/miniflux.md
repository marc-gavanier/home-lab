# Miniflux

A minimal feed reader backed by Postgres. Here it mainly follows the GitHub release feeds of
the self-hosted services, so each Renovate bump comes with readable release notes.

## At a glance

| Item        | Value                                                                  |
|-------------|------------------------------------------------------------------------|
| URL         | `https://rss.example.com` (VPN/LAN only, via Pi-hole split DNS)        |
| Containers  | `miniflux`, `miniflux-db` (Postgres 18)                                |
| Data        | `${SERVICES_DATA_DIR}/miniflux/db` (datadir, excluded from restic)     |
| Backup      | nightly plain-SQL `pg_dump`; OPML export for the subscription list    |
| Monitoring  | Kuma HTTP monitor on `/healthcheck`                                    |
| Secrets     | three files under `/mnt/data/secrets/docker/` (ADR-016)                |
| ADR         | [ADR-026](../../knowledge/decisions/ADR-026-miniflux-rss.md)           |
| Digest      | [claude-code.md, Daily Feed Digest](claude-code.md#daily-feed-digest) ([ADR-027](../../knowledge/decisions/ADR-027-feed-digest.md)) |

## How it works

- `miniflux`: `read_only: true` (empty write set) with `/tmp:size=8m`, uid 65534, zero
  capabilities. The uid is the image default, restated in `compose.yaml` so a base-image
  change cannot move it.
- `LISTEN_ADDR` is set to `0.0.0.0:8080`: the default `127.0.0.1:8080` makes Traefik get
  connection refused.
- The healthcheck is the binary's own HTTP self-test, which also pings the database:

  ```yaml
  test: ["CMD", "/usr/bin/miniflux", "-healthcheck", "auto"]
  ```

### The database

Postgres 18 (not Immich's 16: this database is Miniflux's alone). **Do not copy `immich-db`'s
volume line** — Postgres 18 moved its datadir:

```
PGDATA=/var/lib/postgresql/18/docker     # Postgres 18
VOLUME /var/lib/postgresql               # the volume is now the PARENT
```

So the bind mount is the parent directory:

```yaml
- ${SERVICES_DATA_DIR}/miniflux/db:/var/lib/postgresql
```

Mounting `/var/lib/postgresql/data` would leave the real datadir in an anonymous volume, lost
on the first `docker compose down` or `rm`.

Both tmpfs mounts need `uid=999,gid=999` (with zero capabilities the entrypoint cannot chmod
its socket directory, and initdb needs a writable scratch dir):

```yaml
- /run/postgresql:uid=999,gid=999
- /tmp:size=64m,uid=999,gid=999
```

### The admin account

Created at first start from `CREATE_ADMIN=1`, `ADMIN_USERNAME` and `ADMIN_PASSWORD_FILE`. The
flag stays on: Miniflux skips creation when the account exists.

- **Password: 72 bytes maximum** (bcrypt). Bytes, not characters: accented characters cost
  2-4 bytes.
- Changing `miniflux_admin_password` in the vault does not change the account.

### Secrets

Miniflux takes a whole connection string, so the DSN is itself a secret:

| File under `/mnt/data/secrets/docker/` | Read by       | Contents                |
|----------------------------------------|---------------|-------------------------|
| `miniflux_db_password`                 | `miniflux-db` | bare password           |
| `miniflux_database_url`                | `miniflux`    | full DSN, same password |
| `miniflux_admin_password`              | `miniflux`    | admin account password  |

The deploy role composes all three from `miniflux_db_password` and `miniflux_admin_password`,
mode `0444`.

## Common tasks

- **Add feeds**: by URL, or in bulk by importing an OPML file.
- **Change the admin password**: *Settings → Password* in the web UI, then update the vault
  so a rebuild matches.
- **Export subscriptions**: *Settings → Export* (OPML; no read/starred state).
- **Restore**: load the `pg_dump`, never the datadir (a snapshot restores `services/miniflux`
  as an empty directory). Procedure: `knowledge/runbooks/restore-from-backup.md` → "Restore
  Miniflux (PostgreSQL)".
- **Monitoring**: one Kuma monitor, added by hand in the UI (Kuma v2 has no supported
  automation; `ops/kuma-dump.sh` is a read-only export). `/healthcheck` fails when the
  database is down, so it covers the process, storage, Traefik and TLS expiry.

  | Monitor  | Type | Target                                | Expect |
  |----------|------|---------------------------------------|--------|
  | Miniflux | HTTP | `https://rss.example.com/healthcheck` | 200    |

## Troubleshooting

| Symptom | Cause | Action |
|---|---|---|
| `miniflux` exits 1 in a loop, `miniflux-db` healthy, log shows `bcrypt: password length exceeds 72 bytes` | admin password over 72 bytes | shorten it in the vault and redeploy; the `users` table is still empty, nothing to clean |
| `miniflux-db` exits on `chmod: /var/run/postgresql: Operation not permitted` or `mktemp: : Read-only file system` | tmpfs without `uid=999,gid=999` | restore the uid on both tmpfs mounts |
| Feeds empty after `compose down` | datadir mounted at `/var/lib/postgresql/data` | mount the parent `/var/lib/postgresql`; restore from the dump |
| Traefik gets connection refused | `LISTEN_ADDR` left at default | set `0.0.0.0:8080` |
| Kuma red, `docker ps` still `healthy` | the container healthcheck has not re-run yet | trust Kuma; check `miniflux-db` |
