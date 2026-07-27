# ADR-017 — Drop all Linux capabilities, re-add per image

**Date**: 2026-07-26
**Status**: accepted — deployed and verified per service on the Pi, netdata
included (2026-07-27)

## Context

Docker grants every container the same 14 capabilities regardless of what it
runs: `CHOWN`, `DAC_OVERRIDE`, `FOWNER`, `FSETID`, `KILL`, `SETGID`, `SETUID`,
`SETPCAP`, `NET_BIND_SERVICE`, `NET_RAW`, `SYS_CHROOT`, `MKNOD`, `AUDIT_WRITE`,
`SETFCAP`. Most services here touch none of them.

`no-new-privileges` was already set everywhere and the deliberate additions were
documented (`NET_ADMIN`/`SYS_MODULE` for wg-easy, `SYS_PTRACE` for netdata after
`SYS_ADMIN` was removed), but the default grant was never questioned. It was the
last broad item on the container layer after the socket-proxy (PR #10) and the
secrets migration (ADR-016) — the sibling follow-up issue #11 had left open.

## Decision

`cap_drop: ALL` on every service, aliased from one anchor, with each service
re-adding only what it needs and a comment naming the behaviour that needs it.

**Requirements are established empirically, not by reasoning about the image.**
This is the same rule ADR-016 applied to `_FILE` conventions, and it earned its
keep again: three of the requirements were not guessable from the outside.

| Service | Capability | Why it is not guessable |
|---------|-----------|-------------------------|
| pihole | `SETFCAP` | The image runs `setcap` on `pihole-FTL` so the resolver can serve `:53` as uid 1000. Nothing about "a DNS server" suggests it; without it the container exits in 6 s. |
| wg-easy | `NET_RAW` | `wg-quick` shells out to `iptables`, which opens a raw socket to reach netfilter. `NET_ADMIN` looks sufficient and is not. |
| uptime-kuma | `NET_RAW` | `/usr/bin/ping` carries `cap_net_raw` as a **file** capability, so the exec fails outright. |

The Uptime Kuma case defines the verification standard: the container stayed
`healthy`, the web UI kept answering, and only ping monitors failed, reporting
`spawn EPERM`. Container status and an HTTP probe were both green. Verification
therefore has to exercise what a service *does*, per service — a real ACME
issuance for Traefik, a blocked-domain lookup for Pi-hole, an RPC call with both
right and wrong credentials for Transmission, real peer handshakes for wg-easy.

A sweep for file-capability binaries across all containers is part of the
procedure now, since that failure mode is invisible from outside.

### Netdata: dropping capabilities can *raise* privilege

Netdata was done last and turned out to be the instructive case. Its plugins are
**setuid root** (mode 4755: `apps.plugin`, `cgroup-network`, `go.d.plugin`,
`network-viewer`…) — not file-capability binaries, as the compose comment had
claimed for months. A setuid binary still only receives the container's bounding
set, so `cap_drop` governs what those plugins can do.

Two findings, both invisible from the outside:

- **Without `CHOWN` the agent never drops privilege.** It fails to prepare
  `/run`, `/var/cache` and `/var/lib` as `201:201`, gives up on switching user,
  and runs *entirely as root* — the opposite of the intent, and nothing in
  `docker inspect` or a healthcheck says so. Only `awk /^Uid:/ /proc/1/status`
  does.
- **Without `DAC_OVERRIDE` two features die while every chart survives.** The
  setuid-root plugins write into `/run/netdata`, owned by uid 201; without the
  capability `network-viewer`'s spawn server fails to `bind()` and go.d's
  `local-listeners` service discovery dies. Chart contexts stayed at 278 of 279
  either way — the comparison that mattered was the list of running plugin
  processes.

Verification was therefore a diff against production on three axes: uid of PID 1,
plugin processes alive, and chart contexts. `NET_RAW` is deliberately absent
(only `fping` needs it, and no ping collector is configured); `SYS_ADMIN` stays
out as before, which already made `cgroup-network`'s namespace-entering path
inert on this host — the same "Cannot switch to network namespace" lines predate
this change, so `SYS_CHROOT` was left out too rather than moving a log line.

### `DAC_OVERRIDE` — the exception, and what it reveals

Several containers run as root over data directories owned by the host user
(uid 1000, created by Ansible), so root was silently relying on `DAC_OVERRIDE`
to read and write them. Removing it surfaced the dependency: jellyfin fails its
startup sanity check, navidrome reports a read-only database, Traefik cannot
read its own 0640 config and restart-loops.

SearXNG was in that list until the reason it rewrote its settings turned out to
be a defect rather than a requirement (issue #27): a symlink inside a
bind-mounted directory is resolved in the container's namespace, so the instance
saw no settings and generated a stub over the link. Mounting the file itself,
0444 from the LUKS secrets directory, removed both the rewrite and the need for
any capability — searxng now runs with none. Worth noting as the general shape:
a capability that looks required can be the symptom of a broken assumption
somewhere else.

Where only reads are involved, the narrower `DAC_READ_SEARCH` is used instead —
Traefik's config and Nextcloud's push service, whose six self-tests pass with
nothing more.

This is treated as a residual, not a resolution. The clean fix is ownership:
data trees chowned to the uid each container actually runs as would let the
remaining `DAC_OVERRIDE` grants go. `/mnt/data/services/wireguard` is the
clearest case — in-place rewrites work (measured), only creating a new file
would be denied.

## Consequences

**Positive**
- Seven of the twenty-one services hold no capabilities at all; the rest hold
  between one and eight instead of fourteen. `NET_RAW` (packet spoofing/sniffing), `MKNOD`,
  `SYS_CHROOT`, `SETPCAP` and `AUDIT_WRITE` are gone wherever unused.
- Every remaining capability is now a documented, justified line rather than an
  invisible default — a new service starts from zero and has to earn each one.

**Negative / cost**
- Adding a service now includes a capability discovery step. The runbook
  (`knowledge/runbooks/container-config-changes.md`) exists so that step is a
  procedure rather than an improvisation.
- Image updates can change the requirement (a new binary with file
  capabilities, an entrypoint that starts chowning). The file-capability sweep
  is the cheap regression check.
- `DAC_OVERRIDE` survives on six services, which limits the gain there: it is
  the capability that makes root's file access unconditional. Two more make do
  with `DAC_READ_SEARCH`. Jellyfin and Navidrome shed theirs by owning their
  trees as root instead (issue #28) — five paths, all of them directories, were
  enough to require the capability.

**Learned the hard way**
Applying the change to wg-easy against the live container left the VPN — and the
offsite backup link that rides it — down for three hours. Pi-hole's change had an
unattended rollback and wg-easy's had none, for no better reason than that DNS
felt more critical. Both harnesses are mandatory in the runbook now, and the
sandbox-first rule applies to every service on the critical path.

## Alternatives considered

- **Keep the default set** — the status quo grants capabilities nothing uses.
  Rejected: this was the cheapest remaining reduction on the container layer.
- **Chowning every data tree to match each container's uid** — strictly better,
  and started under issue #28: Jellyfin and Navidrome run purely as root, so
  root-owned trees (codified in the storage role, not applied by hand) retired
  their `DAC_OVERRIDE`. It does not generalise. The remaining six run as root
  *and* hand off to a service uid, so root ends up writing files owned by that
  uid whichever way the tree is owned; Postgres additionally refuses a data
  directory it does not own, which rules the pattern out for immich-db. For
  those, running the container **as** the service uid (`user: 999:999`, with the
  data directory already owned by it) is the promising route — it removes the
  root phase altogether, and with it CHOWN/SETUID/SETGID/FOWNER as well.
- **A custom seccomp or AppArmor profile per service** — finer-grained than
  capabilities, and the right tool for netdata specifically (issue #24). Not a
  substitute for this: it is more work per service and does not remove the
  default capability grant.

## Related

ADR-016 (secrets as files), PR #10 (container runtime hardening), issue #24,
`docs/03-security/` §Containers,
`knowledge/runbooks/container-config-changes.md`.
