# ADR-025 — Calibre-Web-Automated, and accepting a fifth `DAC_OVERRIDE`

**Date**: 2026-08-05
**Status**: accepted — installed and measured on the Pi (2026-08-05)

## Context

Issue #15 shortlisted five services on 2026-07-19. Calibre-Web-Automated was the
last of the light ones: 94 books existed on the workstation in a Calibre library
and were the only media in the lab not reachable from a browser, while music,
photos and video had been for months. The concrete want is **OPDS** — an e-reader
browsing and downloading over the VPN.

Two things in that shortlist entry turned out to be wrong, and both are why this
ADR exists.

## Decision

Deploy **Calibre-Web-Automated v4.0.6** behind Traefik at `books.<domain>`,
VPN-only, owning `/mnt/data/media/books` as the single copy of the library, with
five capabilities and no read-only rootfs.

### The Pi owns the library, and that is a one-way door

#15 proposed keeping desktop Calibre as the manager while CWA auto-ingests. Those
two cannot both be true. CWA **writes** to the library: it rewrote `metadata.db`
on first run against a throwaway copy — the md5 changes. Editing the same library
from a desktop Calibre would fork the two silently, with no conflict and no
error, just two divergent truths and metadata lost from whichever side loses.

So the library moved to `/mnt/data/media/books` (2.1 GB, 94 books, 77 author
directories, verified by book count and format breakdown after the copy) and the
Pi is now canonical. The workstation copy is a **cold archive**.

Two side effects worth recording:

- It lands in the restic set for free, since `/mnt/data/media` is already backed
  up — **+2.1 GB** to local and offsite targets, no change to `backup.sh`.
- `rsync -a` faithfully preserved the source's `777` permissions, which came from
  some long-ago copy off a foreign filesystem. Normalised to 755/644. The group
  was then reset by CWA's own init, which chowns its three mounts to
  `PUID`:`PGID` — and Ansible derives `PGID` from `ansible_user`'s primary group
  (1003), not from `gpio` (1000). So the library ends up
  `marc-gavanier:marc-gavanier`, exactly like `transmission/config`, rather than
  matching the `marc-gavanier:gpio` of `music` and `photos`. Fighting the init
  over this would be pointless: it re-applies on every start.

### The hardening bar cannot be met, and the failure is upstream

This is the least hardened service in the stack. Every part of that was measured
rather than assumed.

**No read-only rootfs.** `docker diff` on a running container shows **1797**
entries: the image patches its own source tree and writes Python bytecode caches
under `/app` at every start. Unlike Transmission (ADR-019), there is no quiet
degradation to weigh — it does not start.

**Five capabilities**, and six variants were tried to avoid them:

| Variant | Result |
|---|---|
| `cap_drop: ALL` | `/config/client_secrets.json: Permission denied`, never serves |
| `CHOWN,SETUID,SETGID` | reports **healthy**, `/app` cache missing |
| `+ DAC_OVERRIDE`, no `FOWNER` | reports **healthy**, `install` fails on `/config/processed_books/*` |
| `user: "1000:1000"`, zero caps | s6 preinit: `/run belongs to uid 0 … lacking the privileges to fix it`, exit 100 |
| `+ owned /run tmpfs` | exit 126 — Docker mounts tmpfs `noexec` |
| `+ exec` on the tmpfs | s6 starts, then `/app` is root-owned in the image; never serves |

`CHOWN`, `SETUID`, `SETGID`, `DAC_OVERRIDE` and `FOWNER` are each load-bearing:
the last two fail differently and independently.

The general move recorded in `docs/03-security/README.md` — *start the container
as the service uid, removing the root phase rather than feeding it* — was tried
three ways and does not apply here. It would need the image to ship `/app` owned
by the app uid. That is an upstream change, not a compose setting.

**So this is the fifth service keeping `DAC_OVERRIDE`**, after pihole, Nextcloud,
transmission and netdata. Accepting it is a posture change and is recorded as one
rather than being absorbed quietly.

**It is not quite transmission's case, and the difference was found by looking
rather than reasoning.** Both are linuxserver-style s6 images where `PUID`/`PGID`
is the root-phase mechanism, and in both the network-facing process drops to uid
1000 (`python3 cps.py` here, `transmission-daemon` there). But transmission keeps
only its s6 *supervisors* as root, while this image keeps four working longruns
as root for the container's entire life: `cwa-ingest-service`,
`metadata-change-detector`, `cwa-auto-zipper` and `svc-cron`.

`cwa-ingest-service` is the one that matters. It is a root bash loop watching the
ingest folder and handing files to the Calibre tooling — so **a book dropped into
`/mnt/data/media/books-ingest` is untrusted input parsed by root-owned code**,
with all five capabilities available to it. The ingest folder is therefore a
trusted path by policy, and that is documented for the operator rather than left
implicit.

What bounds the exposure: the network-facing application runs as uid 1000; the
container never sees the Docker socket; it is on the `proxy` network only; and
`vpn-only` gates it like everything else. But "root only during init" would have
been a false claim, and an earlier draft of this ADR made it.

### A live default credential that cannot be automated away

`admin` / `admin123` works — verified against a fresh `app.db`, not repeated from
documentation: the login POST returns 302 and the authenticated page returns 200
where an anonymous one gets 302.

There is no environment variable to set it. The credential lives in
`/config/app.db`, which the application owns, so the Dozzle pattern (ADR-023: a
bcrypt hash in the vault, rendered to a file) has nothing to attach to. It is a
**manual first-login step**, documented in `docs/05-services/calibre-web.md` and
required before the service counts as deployed.

The other defaults were checked at the same time and are sound: anonymous
browsing off, self-registration off, remote login off, and a password policy of
8+ characters with mixed classes.

### The container's own healthcheck is not trustworthy here

Two of the failing capability variants above reached **`healthy`** while broken.
`docker ps` would have reported a working service, and so would an
unauthenticated HTTP probe, because the login page is served by a process that is
fine while the library handling is not.

The compose healthcheck therefore probes `/login` explicitly rather than
inheriting the image's, with a 120 s `start_period` (first boot creates `app.db`
and takes ~90 s). The Kuma monitor is understood to cover reachability and TLS
expiry only — proving the library is readable needs an authenticated request,
which a Kuma HTTP check cannot make without storing credentials. Calibre-Web
joins Collabora (ADR-021) as the second documented place where "probe a function,
not the root" runs out of road.

## Consequences

- **353 MB of RAM** at idle, against the 150-250 MB the shortlist estimated, and
  a **1.74 GB** image — the largest in the stack, because it bundles a full
  Calibre for format conversion. Both land on `/mnt/data`, not the SD card:
  Docker's data root is `/mnt/data/docker`.
- Wave 3 of the staged startup, with the other slow starters.
- The library and CWA's own `app.db` are both already inside the restic set.
- The desktop Calibre library becomes read-only by policy, enforced by nothing
  but this document.
- The lab now has five `DAC_OVERRIDE` services instead of four, and the security
  README says so explicitly.

## Alternatives considered

- **Library read-only, ingest disabled.** Would not reduce the capability set —
  they are needed by the init, not by writing — and would give up the feature
  that makes CWA worth running over a plain file share.
- **Kavita.** A single .NET binary, plausibly far more hardenable, but it does
  not read a Calibre library natively and would mean leaving the ecosystem. Not
  measured; if the hardening cost here ever becomes unacceptable, this is the
  thing to measure next.
- **Not deploying it.** Genuinely on the table given the capability cost. Refused
  because the mitigations are real (non-root app process, no socket, one network,
  VPN-only) and the alternative is either no web access to the books or an
  unmeasured migration to another ecosystem.
