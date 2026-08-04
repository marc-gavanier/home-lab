# ADR-024 — IT-Tools, and pinning a project whose releases stopped

**Date**: 2026-08-04
**Status**: accepted — installed and measured on the Pi (2026-08-04)

## Context

Issue #15 shortlisted five services on 2026-07-19. IT-Tools was described there as
the trivial one: ~50 MB, "effort: trivial", a static toolbox of JWT decoders, hash
and base64 converters, cron parsers and the like. The value is a privacy one — the
alternative to a self-hosted toolbox is pasting live tokens into whatever web tool
a search returns.

Two things turned out differently from that description, and both are the reason
this ADR exists rather than the change being a one-line compose block.

## Decision

Deploy **IT-Tools** behind Traefik at `tools.<domain>`, pinned to a **digest on the
`nightly` tag**, running as uid 101 with **zero capabilities** and a read-only
rootfs, gated by `vpn-only` alone.

### Upstream stopped publishing releases, and the stable tag is the unsafe one

The newest tagged release is `2024.10.22-7ca5933` — 21 months old at the time of
writing. The repository itself is alive (40k stars, commits through 2026-07-30),
but the release train stopped. What that means concretely:

| | `2024.10.22-7ca5933` | `nightly` |
|---|---|---|
| Built | 2024-10-22 | 2026-02-13 |
| Base | Alpine **3.20** (past end of support) | Alpine **3.23** |
| nginx | 1.26.2 | 1.28.2 |

The instinct is to prefer the tagged release, because that is what "pin an explicit
version" normally means in this repo. Here it inverts: the stable tag ships an
end-of-support base and a 21-month-old nginx, and this is a service whose entire
justification is *not* trusting stale third-party code with your tokens. Choosing
it would have been consistency at the cost of the point.

So the pin is a **digest on a moving tag**:

```yaml
image: corentinth/it-tools:nightly@sha256:f07d2465...
```

`nightly` in this project is a build of `main`, not an unstable channel — with
releases stalled, it is simply where maintenance lands. The digest restores what
the moving tag gives up: the deployed artefact is immutable, and Renovate raises a
PR when the digest changes. Neither registry has anything fresher; ghcr.io carries
the same tag list, with no nightly at all.

**This pin must be re-read, not merely bumped.** `nightly` was itself last built
2026-02-13. If it goes stale in turn, the honest conclusion is that the project has
stopped being maintained, and the answer is to remove the service rather than pin
it deeper. A toolbox for handling secrets is exactly the wrong place to run
abandoned code.

### Zero capabilities, on port 80, as a non-root user

nginx listens on **:80**, which is privileged, and the image runs as root by
default — so the expected shape was `user: "101:101"` plus `NET_BIND_SERVICE`.

It needs neither. Docker sets `net.ipv4.ip_unprivileged_port_start=0` inside the
container, so binding :80 as uid 101 requires no capability at all. Measured rather
than assumed: with `--cap-drop ALL` and nothing added, the container starts and
serves 200. IT-Tools therefore joins the zero-capability group rather than being
the exception the port number suggested.

One thing does not come free. The three tmpfs mounts need explicit ownership:

```yaml
- /var/cache/nginx:size=16m,uid=101,gid=101
```

A tmpfs mounts root-owned `0755` by default, so uid 101 cannot create
`/var/cache/nginx/client_temp`, and nginx exits 1 at startup with
`mkdir() ... failed (13: Permission denied)`. That message points at the read-only
rootfs, which is not the cause — the cause is ownership, and no other tmpfs in
`compose.yaml` has needed this because no other service drops to a non-root uid
*and* writes to tmpfs.

### One lock, not two

Dozzle (ADR-023) is the one internal service with credentials on top of the network
gate, because it aggregates every other container's stdout. IT-Tools gets no second
lock, and the asymmetry is deliberate.

Every tool here runs in the browser. The container serves static files: it never
parses a token, never stores one, never sees what is pasted into the JWT decoder.
There is no server-side secret behind the gate, so a password would guard an empty
room while adding a credential to manage.

### The monitor watches `/`, which is not a contradiction

ADR-023 established that an availability monitor should probe a function endpoint
and never the root, because a service can serve its page while its backend is dead.
IT-Tools' Kuma monitor targets `https://tools.<domain>/` expecting 200.

That rule presumes a backend that can fail independently. This service *is* the
page — there is nothing behind it. When `/` returns 200, everything it does works.
Stated here because the two ADRs otherwise look like they disagree.

## Consequences

- **4.35 MB of RAM** measured at idle, against the 50 MB the shortlist budgeted —
  the cheapest service in the stack by an order of magnitude.
- Empty `docker diff` write set, so `read_only: true` costs nothing.
- **Nothing to back up**: no volume, no database, no secret, no state. The container
  is its image, and restore is a redeploy.
- A pin that carries an expiry condition: if `nightly` stops moving, remove the
  service. That obligation lives in the compose comment and in
  `docs/05-services/it-tools.md`, not only here.
- Wave 1 of the staged startup gains a member that costs it nothing.

## Alternatives considered

- **The 2024 stable tag.** Rejected above: end-of-support base, 21-month-old nginx,
  on the one service that exists to avoid stale third-party code.
- **Building from source.** Would give a current bundle and full control, at the
  price of a build pipeline on the Pi and a dependency tree to maintain — far more
  than a browser-side toolbox is worth.
- **Not deploying it.** A real option given the release situation, and the one to
  take if `nightly` stops moving. Today the image is six months old, hardened to
  zero capabilities, VPN-only, and strictly better than pasting a JWT into a search
  result.
