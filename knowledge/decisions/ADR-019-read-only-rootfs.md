# ADR-019 — Read-only root filesystem per container

**Date**: 2026-07-27
**Status**: accepted — deployed and verified per service on the Pi (2026-07-27)

## Context

Every container could write to its own image layer. A process that gets code
execution could drop a binary, rewrite a script it would later execute, or
persist changes that survive a restart without touching any volume — none of
which any backup or diff would show, since the writable layer is not part of the
data set.

This was the last broad item on the container layer, after secrets as files
(ADR-016), `cap_drop: ALL` (ADR-017), running services as their own uid (#28)
and netdata's AppArmor profile (ADR-018). It was recorded as "identified, not
attempted" on the assumption that it required observing 21 images from scratch.
That assumption was wrong, and the correction is the interesting part.

## Decision

`read_only: true` on every service whose write set allows it, with each writable
path declared explicitly — a sized `tmpfs` for state meant to be lost, a bind
mount for state that is not. **17 of 21 services.** The other four keep a
writable rootfs with the reason written in their block, the same rule applied to
the residual `DAC_OVERRIDE` grants in ADR-017.

**The requirement was measured, not derived.** `docker diff <container>` lists
exactly what a running container has written to its image layer — weeks of real
behaviour, including the paths no one would have predicted. Seven services
turned out to write *nothing at all*; nine needed one or two `tmpfs` mounts. The
work that looked like "observe 21 images" was already done by production.

### Rules that emerged, worth keeping

**Mount the leaf, never the parent.** A `tmpfs` on `/run` erases the
subdirectories the image created there, and the process does not recreate them:
mariadbd aborts with "Bind on unix socket: No such file or directory", Postgres
with "could not create lock file". The fix is `/run/mysqld`, `/run/postgresql`,
`/run/netdata`. Same for netdata's `/var/log/netdata`, where every file is a
symlink to `/dev/stdout` — a `tmpfs` over the directory would replace them with
real files growing in RAM.

**Docker mounts tmpfs `noexec` by default.** Transmission's s6 init copies its
own init binary into `/run` and execs it; the failure reads `exec: /run/s6/basedir/bin/init:
Permission denied`, which looks like a permission bug and is a mount option.
`- /run:exec` is the answer where an init system stages executables.

**A container that writes into a directory the image also populates cannot go
read-only, and the workarounds are worse than the gap.** A `tmpfs` there hides
what the image ships; a pre-rendered host copy silently swallows whatever the
next image version adds. Both trade a visible limitation for an invisible one.

## The four exceptions

| Service | Measured behaviour |
|--------------|-----------------------------------------------------------|
| pihole | Container stays **Up**, `setcap` on `/usr/bin/pihole-FTL` fails, `getcap` returns empty, FTL never starts, `:53` refuses connections. Read-only would convert a loud failure into a silent one |
| nextcloud | Exit 2 — `cannot create /usr/local/etc/php/conf.d/redis-session.ini`, a directory that also holds the 21 `.ini` files the image ships |
| socket-proxy | Exit 1 — `can't create /usr/local/etc/haproxy/haproxy.cfg`, generated from the template beside it |
| transmission | Starts, but the image itself announces that `PUID`/`PGID` and `UMASK` stop having any effect. Both are load-bearing: ownership of the downloads, and the `UMASK 022` that came out of a CIS finding (7.1.11, world-writable downloads) |

Transmission is the one that would have been easy to get wrong: it starts, it
serves, its healthcheck passes — and it silently stops honouring two settings we
depend on. Hardening that quietly disables another hardening is not a gain.

## A side effect worth more than the change

Netdata kept its registry and its **metrics database** in the container's
writable layer. Nothing was configured that way on purpose; it simply was never
given a volume. Every recreate — every capability test, every image bump —
started the history from zero, invisibly. Making it read-only forced the
question, and its state now lives on `/mnt/data`. Read-only rootfs as a
constraint surfaced a data-loss bug that monitoring itself could not report.

## Verification

Per service, and per `knowledge/runbooks/container-config-changes.md`: sandboxed
first for anything on the critical path (wg-easy, both databases, searxng,
netdata), then applied behind a script that rolls back unattended if the
functional probe fails. Probes were the function, never the status — a real
`occ` write, a SQL round-trip, `wg show` peers, `/healthz`, a cron run that must
*advance* `core lastcron`, and netdata's three axes (uid 201, ten plugin
processes, 278 chart contexts).

Two failures came from the harness rather than the change, and both are now
runbook entries: a probe that used a hostname the Pi itself cannot resolve
(internal names live in Pi-hole, which the host does not use as its resolver),
and a rollback whose "backup" already contained the change.

## Consequences

**Positive**
- 17 of 21 containers cannot modify the code they run.
- Every writable path is now declared and sized, rather than being wherever the
  image happened to write.
- Netdata's history survives a recreate.

**Negative / cost**
- An image update can start writing somewhere new. The failure is usually loud
  (the process aborts), which is the good case; pihole is the reminder that it
  is not always.
- `tmpfs` sizes are a judgement call. They are set from observed usage with
  headroom (InnoDB's temporary files get 256 MB, most get 8–64 MB) on a machine
  with 8 GB of RAM.
- Four services are unchanged, and the reason is in their block.

## Alternatives considered

- **Skip it** — the position taken until now, on a cost estimate that `docker
  diff` invalidated.
- **A writable overlay per service** (tmpfs over `/`) — hides the whole image,
  and makes every image update invisible. Rejected.
- **Pre-rendering the contested directories on the host** for nextcloud and
  socket-proxy — would make those two read-only at the price of masking image
  content on every future update. Rejected: the failure mode it introduces is
  silent, which is exactly what this layer of work is trying to eliminate.

## Related

ADR-016 (secrets as files), ADR-017 (capabilities), ADR-018 (AppArmor),
issue #32, `docs/03-security/` §Containers,
`knowledge/runbooks/container-config-changes.md`.
