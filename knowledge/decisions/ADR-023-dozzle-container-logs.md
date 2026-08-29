# ADR-023 — Dozzle for container logs, and the socket-proxy permission it forces open

**Date**: 2026-08-04
**Status**: accepted — installed and measured on the Pi (2026-08-03/04)

## Context

Issue #15 shortlisted five services on 2026-07-19. Dozzle was picked first, ahead
of the lighter IT-Tools, because it closes an observability gap rather than
adding a convenience: Netdata answers *how is the host doing* and Uptime Kuma
answers *is the service up*, and neither answers *what did this container just
print*. That question required SSH, and SSH is the tool this lab spends most of
its effort not needing.

## Decision

Deploy **Dozzle 10.6.14** as a container behind Traefik at `logs.<domain>`,
reading the daemon through the existing read-only `socket-proxy`, with its own
password on top of the global `vpn-only` gate.

### `INFO=1` is not optional, and the failure names the wrong cause

Dozzle calls `GET /info` at startup. The proxy's `INFO` defaults to `0`, so it
answers 403 — and Dozzle reads that as *there is no engine here at all*:

```
{"level":"info","message":"Dozzle version v10.6.14"}
{"level":"fatal","message":"Could not connect to any Docker Engine"}
```

Exit code 1. Not a degraded UI, not a missing panel: the container will not
start. Measured on a throwaway pair — a second `socket-proxy` and a second
Dozzle, same image and same flags, differing only in that variable:

| `INFO` | Result |
|---|---|
| `0` | `fatal: Could not connect to any Docker Engine`, **exit 1** |
| `1` | `Connected to Docker`, `Accepting connections on :8080`, **running** |

The message points at the socket path, which is the one thing that was correct.
Written down because the next person to add a socket-proxy consumer will read
that line and check `DOCKER_HOST` first, as this session did.

**The cost is shared**, because the proxy is. Traefik and Netdata gain `/info`
too. That endpoint returns daemon metadata — kernel, OS, storage driver,
container and image counts, registry configuration — with no `Env` array and no
credential in it, and Netdata already collects and displays all of it by design.
A second proxy instance scoped to Dozzle was considered and rejected: it would
add a container, a network and a maintenance surface to withhold a permission
from Traefik that reveals nothing Traefik cannot already infer.

`POST` stays `0`. That keeps `DOZZLE_ENABLE_ACTIONS` and `DOZZLE_ENABLE_SHELL`
at their default `false` as a matter of fact rather than preference: enabling
either would add start/stop/restart buttons and an in-browser shell that 403
against the proxy instead of working. The proxy is the boundary; this is a log
viewer, not a control panel.

### The one service that gets a second lock

Every other internal service is protected by `vpn-only` alone (ADR-002). Dozzle
is the exception, with `DOZZLE_AUTH_PROVIDER=simple`, because of what it
concentrates: a single page holding **every other container's stdout** — session
identifiers, e-mail addresses, whatever an application decided to log at info
level. The network gate is the perimeter, and the case worth defending here is
the one where the perimeter itself failed: a stolen WireGuard key, a compromised
laptop on the LAN.

Verified rather than assumed — an unauthenticated `GET /` returns **307** to the
login page, and a `POST /api/token` with the generated credentials returns 200.

That 307 is evidence for the lock. It is **not** what the availability monitor
should watch, and this ADR first concluded that it was — wrongly. Dozzle goes on
answering `/` unchanged after losing the Docker API altogether: the container
stays `Up`, the page still loads, and it shows nothing. A monitor on `/` would
stay green through the exact failure it exists to catch. Measured on a throwaway
pair — with the socket-proxy stopped, `/` answered as before while
`/healthcheck` turned **500**. The Kuma monitor therefore targets
`/healthcheck` and expects 200 (corrected 2026-08-04).

The password is stored **bcrypt-hashed** in the vault and rendered verbatim.
Hashing at deploy time was the obvious shape and is wrong: bcrypt salts itself at
random, so every run would produce a different string and report `changed`
forever. Vaultwarden solves the same problem in the other direction, with a
pinned salt (ADR-016) — available there because Argon2 accepts one, and not here
because the `dozzle generate` CLI does not expose the bcrypt salt. So the hash
itself is the stored secret.

One constraint travels with that choice, and it surfaced while setting the password:
bcrypt reads only the first 72 bytes, and Dozzle's implementation **refuses** rather than
truncating — `bcrypt: password length exceeds 72 bytes`, fatal. Bytes, not characters. The
trap is that it fires on the most careful setup rather than the sloppiest: a long generated
passphrase pulled from the Vaultwarden instance one subdomain over. Capping at 72 costs
nothing against bcrypt at cost 11.

The file is bind-mounted **as a file**, not through its directory. A directory
bind mount is resolved in the container's namespace, which is how SearXNG ran for
weeks on a self-generated stub config (issue #27).

### Secrets-as-files holds under a new reader

Dozzle's event stream carries each container's full mount list, which was the
thing worth checking before pointing a log viewer at the whole stack. Measured on
the live stream: entries like
`{"type":"bind","source":"/mnt/data/secrets/docker/immich_db_password",…}` — the
**path**, and no `env` key anywhere in the payload.

That is ADR-016 working as designed under a consumer it was not written for: the
socket-proxy permits `GET /containers/{id}/json`, whose `Env` array would have
carried those passwords in clear had they still been injected as environment
variables. A compromised Dozzle reads mount paths instead.

### Free `read_only`, and no docker group

`docker diff` on a live container returns an empty write set — the only entries
are `/data` and the users file, both artefacts of the bind mount itself. Dozzle
is a single Go binary serving from its own image and keeping no state on disk;
the auth session is a cookie. So `read_only: true` costs nothing.

It carries `/tmp:size=8m` all the same. This ADR said it "needs no tmpfs" until
#274, which was true as measured and stopped being the policy with #265: every
read-only service now gets an insurance tmpfs, because `docker diff` only reveals
paths a container *has* written and a code path never exercised leaves nothing
behind. Navidrome is what that blind spot costs. An unwritten tmpfs allocates no
page. (ADR-019 lists the four services that could not reach `read_only` at all.)

It runs as uid 65534 with every capability dropped. It speaks TCP to the proxy,
so unlike the usual log-viewer deployment it needs neither the `docker` group nor
access to a socket file.

The healthcheck is the binary's own `dozzle healthcheck` subcommand, which
performs a real HTTP request against its own listener. It is also the only
option: the image is distroless — no shell, no `wget`, no `curl`.

## Consequences

**A log viewer is a disclosure surface, and it is now one login away.** The
second lock narrows that, and it does not remove it: whoever holds the Dozzle
password reads every service's logs. That is the intended power of the tool, and
the reason it is the only service in the lab with a password of its own.

**`/info` is open to every socket-proxy consumer from now on.** Any future
service added to that network inherits it. The alternative — one proxy per
consumer — remains available if a consumer ever needs a permission that is
genuinely dangerous to share; `/info` is not that permission.

**Nothing to back up.** Dozzle is stateless. Its only file,
`dozzle_users.yml`, lives in `/mnt/data/secrets/docker`, which the restic set
already covers.

**Renovate tracks it**, unlike LibreSign in ADR-022: this is a pinned image tag,
so the version bump arrives as a PR. `DOZZLE_RELEASE_CHECK_MODE=manual` disables
the app's own scheduled call to GitHub for new releases — it duplicates Renovate
and is one more outbound connection from a container that needs none.

**The logs it shows are the Docker json-file logs**, so its window is exactly
what the daemon retains, and nothing here changes that retention. A container
that is recreated starts its log over, and Dozzle will show it starting over.
