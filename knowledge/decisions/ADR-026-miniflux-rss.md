# ADR-026 — Miniflux, and a database whose datadir moved

**Date**: 2026-08-13
**Status**: accepted — measured on the Pi, deployed 2026-08-13

## Context

Issue #15 shortlisted five services on 2026-07-19. Miniflux was the fourth: a
privacy-respecting feed reader, ~15-30 MB of Go plus a small Postgres, "effort: low".
Its stated killer use is tracking the **GitHub release feeds** of the ~20 self-hosted
services in this stack — Renovate already raises the version bump, but it hands over a
number, not a changelog. A feed reader is what turns "netdata 2.10.4 → 2.11.0" into a
decision.

The shortlist also carried a sub-project: a morning digest driven by `claude -p` on a
systemd timer, writing into the Obsidian vault. **That is deliberately out of scope
here.** It is a separate Ansible role with a long-lived OAuth token in the vault, and
bundling it would have made this change about token lifetime rather than about a feed
reader. Miniflux is useful without it.

## Decision

Deploy **Miniflux 2.3.3** behind Traefik at `rss.<domain>`, with a dedicated
**Postgres 18** instance, both running with **zero capabilities** and a read-only
rootfs, gated by `vpn-only` alone.

### Everything hard here was in the database, not the application

Miniflux itself was the easiest service this stack has added. Measured on a throwaway
stack that ran the 132 migrations, created the admin account and served traffic:

| | Result |
|-----------------------|--------------------------------------------|
| `docker diff` write set | **0 entries** |
| Default image uid | 65534 (`nobody`), already set upstream |
| Image contents | distroless — no shell, no `curl`, no `wget` |
| Capabilities needed | none |

An empty write set makes `read_only: true` free and means **no tmpfs at all** — the
only service in the stack with neither. Everything Miniflux owns lives in Postgres.

The absence of a shell is what fixes the healthcheck: a `CMD-SHELL` probe cannot run in
this image. The binary ships its own, which is the better probe anyway because it
performs a real HTTP request against the listener:

```yaml
test: ["CMD", "/usr/bin/miniflux", "-healthcheck", "auto"]
```

Same shape as Dozzle (ADR-023), and for the same reason.

### Postgres 18 moved PGDATA, and the old bind mount would have silently eaten the data

This is the finding worth writing down. `immich-db` mounts:

```yaml
- ${SERVICES_DATA_DIR}/immich/db:/var/lib/postgresql/data
```

Postgres 18 does **not** put the datadir there any more:

```
PGDATA=/var/lib/postgresql/18/docker
VOLUME /var/lib/postgresql
```

The volume is now the **parent**. Copying Immich's line would have mounted a path that
is no longer the datadir, leaving the real one inside the container — where it survives
restarts and dies on the first `docker compose up --force-recreate`. Nothing would have
looked wrong until the feeds silently came back empty.

So the mount is the parent, and the 0700 ownership the storage role applies lands on the
bind-mount source rather than on PGDATA itself; Postgres creates `18/docker` underneath
on first start.

### The alpine entrypoint needs its tmpfs to carry a uid

Hardening the database took two measured failures, both invisible from the compose file:

```
chmod: /var/run/postgresql: Operation not permitted   # tmpfs mounts root-owned 0755
mktemp: : Read-only file system                       # initdb wants a scratch dir
```

A tmpfs mounts root-owned `0755`, and the alpine entrypoint chmods its socket directory
*before* dropping privilege — with no `CHOWN` and no root phase left, it cannot. So both
tmpfs mounts carry `uid=999,gid=999`, which `immich-db`'s Debian-based image does not
need. Same trap IT-Tools hit at uid 101 (ADR-024): the message reads like a
read-only-filesystem problem and is an ownership one.

Postgres 18 rather than the 16 Immich pins: this database is Miniflux's alone, nothing
reads it across services, so there is no schema to match — and 18 is what upstream's own
compose ships.

### The DSN is the secret, not a password inside it

Miniflux takes a whole connection string, so ADR-016's rule — secrets as files, never
through `environment:` — applies to the string rather than to a value within it. Three
secret files instead of the usual one:

| File | Read by | Contents |
|--------------------------|-------------|--------------------------|
| `miniflux_db_password` | `miniflux-db` | bare password |
| `miniflux_database_url` | `miniflux` | full DSN, same password |
| `miniflux_admin_password` | `miniflux` | admin account password |

All three are composed from two vault variables and written 0444 by the deploy role, like
every other Docker secret here.

`CREATE_ADMIN=1` stays on permanently rather than being a first-boot flag: Miniflux skips
creation when the account exists. The consequence to know is that **changing
`miniflux_admin_password` in the vault does not rotate the account** — Miniflux only
reads it when the user is absent. Rotation is a web-UI operation.

The admin password is also capped at **72 bytes** by bcrypt, and Miniflux refuses rather
than truncating. The first deploy hit exactly that with a 128-byte password-manager
passphrase, and the failure mode is worth knowing because it misdirects: the migrations
succeed first, so `miniflux-db` reports **healthy** while `miniflux` exits 1 in a loop —
it reads as a database problem and is an input-validation one. Dozzle documents the same
ceiling (ADR-023); the warning now lives in `local.example.yml` for both.

### One Kuma monitor, not two — the second was specified on a wrong assumption

Two monitors were originally specified: `/healthcheck` for the process and `/` for the
database, on the theory that the first answers without touching Postgres. Stopping
`miniflux-db` disproved it:

| Endpoint | Database up | Database down |
|----------------|------------:|--------------:|
| `/healthcheck` | 200 | **503** |
| `/` | 200 | 500 |

Miniflux's healthcheck pings the database. Both endpoints fail together, so one monitor
covers the process, its storage, Traefik and TLS expiry, and the second was dropped
before it was ever created. Recorded because the reasoning was plausible and wrong, and
the same argument will look convincing the next time a service ships a `/healthcheck`.

The same test also showed `docker ps` reporting `healthy` while the service returned 503
— the 30 s interval had not re-run. Container health lags; the monitor is what catches it.

## Consequences

- One more Postgres on the Pi. Measured idle footprint of the pair is well inside the
  budget, and both are in wave 1 of the staged startup.
- The Postgres 18 datadir layout is now a documented trap. **Do not copy `immich-db`'s
  volume line** when adding a Postgres 16+ database.
- Feeds are backed up as part of the restic set through `${SERVICES_DATA_DIR}/miniflux`,
  and OPML export remains the portable escape hatch.
- The `claude -p` digest is still unbuilt and still worth building; it is not blocked by
  anything in this ADR.

## Related

Issue #15 (services shortlist), ADR-016 (Docker secrets), ADR-023 (Dozzle, binary
healthcheck), ADR-024 (IT-Tools, tmpfs ownership), `docs/05-services/miniflux.md`.
