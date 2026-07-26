# ADR-016 — Container secrets as files, not environment variables

**Date**: 2026-07-21
**Status**: accepted — deployed and validated on the Pi (no plaintext left in
any container's `Config.Env`, MariaDB / Immich Postgres / Transmission RPC all
authenticating from the mounted secrets, reconverge `changed=0`)

## Context

Container hardening (PR #10) put the Docker socket behind a read-only
`docker-socket-proxy` (`CONTAINERS=1`, `POST=0`) for Traefik and Netdata. That
closed the container→host-root pivot, but `CONTAINERS=1` still permits
`GET /containers/{id}/json`, and that response carries every container's **`Env`
array**. So a compromised **Traefik or Netdata** could read the plaintext
passwords injected into every other container via `environment:`.

This was never a regression — the previous raw `docker.sock` mount exposed a
strict superset (full Docker API = host root) — but it was the strongest
remaining weakness on the container layer (issue #11).

Affected: Nextcloud's MariaDB password and root password, Immich's Postgres
password, Transmission's RPC password, and Vaultwarden's admin token hash.

## Decision

Inject those secrets as **Docker secrets** (Compose `secrets:` with `file:`),
mounted at `/run/secrets/<name>`, and point each image at them through its own
file convention. `docker inspect` then shows a path, not a value.

Support was **verified per image** rather than assumed, since the images differ:

| Image | Mechanism | Verified by |
|-------|-----------|-------------|
| `mariadb` | `MYSQL_*_FILE` | `_mariadb_file_env` calls in the entrypoint |
| `immich-app/postgres` | `POSTGRES_PASSWORD_FILE` | `file_env` in the entrypoint |
| `immich-server` | `DB_PASSWORD_FILE` | `read_file_and_export` in `start.sh` (also `unset`s the `_FILE` var) |
| `linuxserver/transmission` | `FILE__PASS` | `init-envfile` s6 script |
| `vaultwarden` | `<VAR>_FILE` | empirically: `DOMAIN_FILE` yields the same validation error as `DOMAIN` |

**Nextcloud's own container gets no secret at all.** Its entrypoint reads
`MYSQL_*` and `NEXTCLOUD_ADMIN_*` only inside `if [ "$installed_version" =
"0.0.0.0" ]`. The instance is installed and its credentials live in
`config.php`, so those variables were dead weight that leaked the DB password.
Deleting them beats converting them.

### What stays in `environment:`

| Variable | Why | Exposure |
|----------|-----|----------|
| `PASSWORD_HASH` (wg-easy) | v14 reads `process.env.PASSWORD_HASH` with no file fallback — verified in `src/config.js` at tag `v14.0.0` | a bcrypt hash, so offline-crackable at best, not replayable |
| `CF_DNS_API_TOKEN` (Traefik) | **not** a support limit: lego documents the `_FILE` suffix for every Cloudflare variable. Deferred to issue #23 because verifying it means exercising a real DNS-01 challenge, and this ADR only claims what was verified | plaintext token, `Zone:DNS:Edit` — the largest remaining item on the container layer |

Vaultwarden's Argon2 token was in this category before this change; it now
mounts as a secret, since the image does honour `<VAR>_FILE`.

Two variables were dropped from the rendered env file rather than converted,
because nothing ever read them: `PIHOLE_PASSWORD` (the Pi-hole password reaches
the container through `pihole setpassword`, so rendering it only copied the
secret into one more file) and `TRAEFIK_ACME_EMAIL` (the address is templated
into `traefik.yml`, not passed through Compose).

### File modes

The directory and the files carry deliberately opposite intents:

- `/mnt/data/secrets/docker/` is `0710 root:docker` — **the host-side
  protection**. Other local users cannot traverse into it.
- the secret files are `0444` — **the container-side access**. Container UIDs
  are arbitrary and unmappable (`mysql` 999, `abc` 911, `www-data` 33), and the
  bind mount lands at `/run/secrets/<name>` whose parent directories are inside
  the container, where the host directory mode no longer applies.

Files are written **without a trailing newline**. The linuxserver
`init-envfile` script passes content through verbatim and only *warns* that a
trailing newline "may not work as expected"; mariadb, postgres and Immich all
strip it. No-newline is the single form that satisfies every consumer.

## Consequences

**Positive**
- No plaintext service password is reachable through the socket-proxy's
  inspect endpoint.
- The service passwords also leave `docker/.env` entirely — Ansible renders the
  secret files straight from the vault — so no single file aggregates every
  credential any more. What remains there is the wg-easy hash and the
  Cloudflare token (issue #23), not a password set.
- Adding a service with a secret now has an obvious, uniform pattern.

**Negative / cost**
- Five more files to manage on the LUKS volume, and a per-image convention to
  look up when adding a service (the table above is the reference).
- A from-scratch Nextcloud deployment no longer self-installs; the admin account
  is created once through the web installer. This is not the recovery path —
  the runbook restores `config.php` and the data volume.
- The secret is still readable from **inside** the container that legitimately
  uses it. This defends against a *neighbouring* compromised container, not
  against compromise of the owning service.

## Alternatives considered

- **Keep `environment:` and drop `CONTAINERS=1`** — Traefik's Docker provider
  and Netdata's container-name resolution both need it. Rejected.
- **Docker Swarm secrets** — real secret distribution, but adopting Swarm for a
  single-node Pi is disproportionate. Compose `file:` secrets give the same
  `inspect` outcome here.
- **`0400 root` secret files** — unreadable by the container users, which run as
  arbitrary non-root UIDs. Rejected as unworkable, not as insufficient.

## Related

ADR-011 (secrets off the SD card on LUKS), PR #10 (container runtime
hardening), issue #11, `docs/03-security/`.

Follow-ups left open by this decision: issue #23 (move `CF_DNS_API_TOKEN` to
`CF_DNS_API_TOKEN_FILE`), issue #24 (`cap_drop: ALL` per service), issue #25
(Kuma monitor on the socket-proxy — the component whose failure would otherwise
surface as a diffuse multi-service outage).
