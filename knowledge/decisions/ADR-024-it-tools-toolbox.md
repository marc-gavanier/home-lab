# ADR-024 — IT-Tools, and pinning a project whose releases stopped

**Date**: 2026-08-04
**Status**: accepted — installed and measured on the Pi (2026-08-04); the drop
condition below was re-read and replaced on 2026-08-17 (#162)

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

### Re-read on 2026-08-17: that was the wrong test (#162)

The condition above reads a frozen digest as a stopped build. Measured 185 days
later, against Docker Hub and the upstream repository:

| | Measured 2026-08-17 |
|---|---|
| `nightly` digest | `f07d2465…` — unchanged since 2026-02-13, identical to the pin |
| Nightly build workflow | 412 runs, succeeding **every night**, last at 00:03 today |
| Commit it builds | `d505845f` on `main`, every single time |
| Last commit on `main` | 2026-02-12 |
| Last release | `v2024.10.22-7ca5933` (2024-10-22) |
| Repository | not archived, 40k stars, 815 open issues |

Nobody stopped building the tag. The pipeline runs nightly and succeeds; the digest
is stable because its **input** is stable. What froze is the source, not the
publishing — and the condition as written cannot tell those two apart.

It also explains an error in this ADR's own Context. "The repository itself is alive
(commits through 2026-07-30)" came from GitHub's `pushed_at`, which tracks a push to
*any* branch. Renovate keeps it fresh: its lockfile PRs pushed on 2026-08-16, all
with red CI, none merged. Read as project activity that field says the opposite of
what it means — dependency updates arriving, and nobody left to merge them.

### The condition that replaces it

"Has the tag moved" cannot separate a maintained project from an abandoned one, and
this is the case that proves it. It is also checked by nobody: Renovate compares
digests, so a dormant tag and a current one produce the same silence.

What made the original condition feel load-bearing was the phrase *a toolbox for
handling secrets*. That premise is false here, and it is the same fact that already
justifies giving this service no password (below): every tool runs in the browser,
the container serves static files, and it never parses, stores or transmits what is
pasted into the JWT decoder. Six-month-old static assets, behind the VPN, on a
container with zero capabilities and a read-only rootfs, expose nothing that ages.

So the service stays, and the condition to drop it becomes one about **exposure**
rather than freshness — a test that can actually be applied:

- it gains a backend, stores state, or handles a secret server-side;
- or it becomes reachable from anywhere other than the VPN;
- or the nightly build stops **succeeding**, which would mean the image can no longer
  be rebuilt against a patched base — the one freshness signal that does carry
  meaning, and the one the digest cannot express.

Any of those makes stale code disqualifying again. Staleness on its own does not.

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
- A pin that carries an expiry condition — restated 2026-08-17 as a condition on
  *exposure*, not on freshness, because the freshness version could not be checked
  by anything and did not mean what it appeared to. That obligation lives in the
  compose comment and in `docs/05-services/it-tools.md`, not only here.
- Wave 1 of the staged startup gains a member that costs it nothing.

## Alternatives considered

- **The 2024 stable tag.** Rejected above: end-of-support base, 21-month-old nginx,
  on the one service that exists to avoid stale third-party code.
- **Building from source.** Would give a current bundle and full control, at the
  price of a build pipeline on the Pi and a dependency tree to maintain — far more
  than a browser-side toolbox is worth.
- **Not deploying it.** A real option given the release situation, and the one to
  take if the service is ever exposed beyond the VPN or gains something server-side
  to defend. Today the image is six months old, hardened to zero capabilities,
  VPN-only, and strictly better than pasting a JWT into a search result.
- **Removing it on 2026-08-17**, when the original condition came due. Weighed and
  rejected above: the condition was measuring the wrong thing, and what it would
  have cost — a subdomain, a certificate, a monitor, a compose entry — buys no
  reduction in attack surface on a container that serves static files and holds
  nothing.
