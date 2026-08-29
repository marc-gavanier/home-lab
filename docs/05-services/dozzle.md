# Dozzle

Real-time container logs in the browser. Fills the gap Netdata and Uptime Kuma left:
metrics and uptime were reachable without SSH, logs were not.

## Access

- URL: `https://logs.example.com` (VPN-only, like the other internal services — the
  subdomain only resolves on the LAN/VPN via Pi-hole split DNS).
- **Login required.** Dozzle is the one internal service with its own credentials on top
  of the network gate. See *Why two locks* below.

## What It Does

- Tails every container's stdout/stderr live, with search and multi-container views.
- No agent, no log shipper, no storage: it reads the Docker daemon's log stream on
  demand, so there is nothing to rotate and nothing extra written to the SD card.

## Why Two Locks

Every other service is protected by `vpn-only` alone. Dozzle carries a second lock
because of what it aggregates: one page holding **every other container's stdout** —
session ids, e-mail addresses, whatever an application decided to log. The network gate
is the perimeter, and a stolen WireGuard key or a compromised LAN device is exactly the
case where the perimeter is what failed.

Credentials come from `/mnt/data/secrets/docker/dozzle_users.yml`, rendered by the deploy
role and bind-mounted read-only at `/data/users.yml`. The password is stored **bcrypt-hashed**,
never in clear: bcrypt salts itself at random, so hashing at deploy time would produce a
new string on every run and report `changed` forever. Regenerate the hash with the image's
own CLI and paste it into `dozzle_admin_password_hash` in the vaulted `local.yml`:

```bash
docker run -it --rm amir20/dozzle:v10.6.14 \
  generate admin --email admin@localhost --name 'Admin'
```

Omitting `--password` makes it prompt, which keeps the password out of shell history.

**The password must be 72 bytes or less.** bcrypt consumes only the first 72 bytes, and
Dozzle's Go implementation refuses rather than truncating silently:
`FTL Failed to hash password error="bcrypt: password length exceeds 72 bytes"`. Bytes, not
characters — an accented character costs two in UTF-8. This bites exactly the setup that
should be safest, a long generated passphrase from the password manager next door. It costs
nothing: 72 characters against bcrypt at cost 11 is far beyond reach.

## How It Reads Docker

Through the same read-only `socket-proxy` as Traefik and Netdata — never the raw
`docker.sock`, which is host root regardless of `:ro`.

This required **`INFO=1`** on the proxy, and the failure without it is not subtle: Dozzle
calls `GET /info` at startup, reads the 403 as "no engine at all", logs
`Could not connect to any Docker Engine` and **exits 1**. Measured on a throwaway pair —
same image, same flags, `INFO=0` exits 1 and `INFO=1` reaches `Connected to Docker`. The
cost is shared, since the proxy is shared: Traefik and Netdata gain `/info` too. What that
endpoint returns is daemon metadata (kernel, OS, storage driver, container counts, registry
config) with no `Env` array and no secret in it, and Netdata already reports all of it.

`POST` stays `0`, so the daemon remains read-only to Dozzle. That is also why
`DOZZLE_ENABLE_ACTIONS` and `DOZZLE_ENABLE_SHELL` are left at their default `false`:
either one would add start/stop/restart buttons and an in-browser shell that fail against
the proxy rather than work. This is a log viewer, not a control panel.

**What the container list does not leak.** The event stream carries each container's mounts,
including bind sources like `/mnt/data/secrets/docker/immich_db_password` — the *path*, not
the value, and no `env` key anywhere. That is ADR-016 working as designed under a new
consumer: secrets are files, so a compromised Dozzle reads mount paths rather than
passwords.

## Data

Stateless. Nothing to back up, nothing under `${SERVICES_DATA_DIR}`.

| Path                                          | Content                                     |
|-----------------------------------------------|---------------------------------------------|
| `/mnt/data/secrets/docker/dozzle_users.yml`   | Credentials, templated by Ansible (bcrypt)  |

The credentials file is on the LUKS volume and covered by the backup (`/mnt/data/secrets`
is in the restic set). It is bind-mounted as a **file**, not through its directory: a
directory bind mount is resolved in the container's namespace, which is how SearXNG spent
weeks on a self-generated stub config (issue #27).

`docker diff` on a live container shows an empty write set, which is what makes
`read_only: true` free here. It still carries `/tmp:size=8m` — insurance rather
than a measurement, added to every read-only service by #265 because `docker
diff` only sees paths a container *has* written and Navidrome imported nothing
for a month behind that blind spot. An unwritten tmpfs allocates no page.
It runs as uid 65534
(`nobody`) with every capability dropped: it speaks TCP to the proxy, so it needs no
membership of the `docker` group and no access to a socket file.

## Restore

Nothing service-specific: re-running the deploy role re-renders `dozzle_users.yml` and
brings the container up.

## Health

- Healthcheck: the binary's own `dozzle healthcheck` subcommand, which performs a real HTTP
  request against its listener — a process that is up but no longer serving fails it. It is
  the only option: the image has no shell, no `wget` and no `curl`.
- Uptime Kuma: HTTP monitor on `https://logs.example.com/healthcheck`, expecting **200**.
  It needs no credentials, so the probe is a plain unauthenticated GET.

  **Not the root**, and that is the whole point. Dozzle keeps serving its pages after it
  has lost the Docker API entirely: the container stays `Up`, the UI still loads, and it
  simply shows nothing. Measured on a throwaway pair — stopping the socket-proxy left `/`
  answering exactly as before (200 there, 307 here where auth is on) and flipped
  `/healthcheck` to **500**. A monitor on `/` would stay green through the one failure it
  exists to catch.
