# ADR-018 — Confine netdata with a scoped AppArmor profile instead of `unconfined`

**Date**: 2026-07-27
**Status**: accepted — deployed and verified on the Pi (2026-07-27)

## Context

Netdata was the one container running with `security_opt: apparmor:unconfined`,
and unlike most such flags it was not carelessness: `apps.plugin` reads
`/host/proc/<pid>/*` for processes that belong to *other* AppArmor profiles, and
Docker's `docker-default` profile denies that cross-profile read. Removing the
flag without replacing it kills the per-application charts.

`unconfined` is a large answer to a small question. It removes every path,
mount, `/sys` and `/proc` write restriction docker-default applies, on the one
container that also holds `SYS_PTRACE`, reads all of `/proc`, and talks to the
Docker socket proxy — i.e. the container where confinement is worth the most.
This was the last item of issue #24, filed separately as #30 once the capability
work was done (ADR-017).

## Decision

Ship a named profile, `homelab-netdata`, which is `docker-default` verbatim plus
**one** grant:

```
ptrace (read),
ptrace (trace,read,tracedby,readby) peer=homelab-netdata,
deny ptrace (trace) peer=unconfined,
```

Reading another process's `/proc` is what the charts need. *Attaching* to a
process — `ptrace trace` — is not, and stays denied. Everything docker-default
denies (mount, writes under `/sys`, `/proc/sysrq-trigger`, `/proc/kcore`, writes
outside the container's own paths) is denied again.

The profile is installed and loaded by the **deploy** role rather than the
security role, and deliberately before `compose up`: Docker refuses to start a
container whose named profile is missing, so the tag that deploys the stack has
to be the tag that guarantees the profile. That failure mode — the container
refuses to start — is the one we want; a typo in the profile name is loud rather
than a silent fall back to unconfined.

`no-new-privileges` stays off for this container. That is a property of the
image, not of this decision: the plugins are setuid-root binaries (4755), and
the flag blocks the elevation outright. A profile cannot change that.

## Verification

Netdata's failures do not appear in container status — the agent stays `healthy`
and its UI keeps answering while a plugin is dead. The change was therefore
measured on three axes against the live unconfined agent, on a throwaway agent
first (same mounts, same capabilities, `DOCKER_HOST` to the socket proxy):

| Axis | Unconfined (before) | `homelab-netdata` (after) |
|-------------------------|------------------------|---------------------------|
| uid of PID 1 | 201 | 201 |
| plugin processes | 10, `NETWORK-VIEWER` included | identical set |
| chart contexts | 278 | 278 |
| per family | app 14, user 14, usergroup 14, cgroup 25, systemd 7 | identical |

One denial appeared and was chased down rather than waved through: `lsns`
requesting `ptrace trace` on host processes at startup. It costs nothing —
`lsns` returns the same nine namespaces confined and unconfined, because what
limits it is the container's namespace and capability set, not this profile. The
profile denies it explicitly so the message stops being logged; a recurring
`DENIED` line that means nothing is worse than no line, because it will be
mistaken for the cause of some future incident.

## Consequences

**Positive**
- The container with the widest read access on the host is now confined by the
  same rules as every other container, minus one narrow read grant.
- The profile is a file in the repo, reviewable and diffable, rather than an
  absence of one.

**Negative / cost**
- A netdata image update can need a new rule. The failure will be an AppArmor
  `DENIED` in `dmesg`, which is at least explicit — unlike the capability
  failures of ADR-017, which were silent.
- One more host-level artefact for a fresh provision to get right. It is
  codified (`ansible/roles/deploy/tasks/apparmor.yml`), and its absence stops
  the container rather than degrading it.

**Not addressed**
- A seccomp profile. Docker's default seccomp filter still applies here (it is
  what blocks `io_uring`, for instance); a netdata-specific one would be a
  further narrowing, with the same measurement cost and much less to gain now
  that the ptrace surface is scoped.

## Alternatives considered

- **Leave `unconfined`** — free, and the state of things until now. Rejected:
  the capability work made this the largest remaining grant on the container
  layer, and it applies to the container best placed to read the host.
- **Run netdata without `apps.plugin`** — would remove the need for the grant
  along with the per-application, per-user and per-group charts, which are the
  reason the agent is there. Rejected.
- **A seccomp profile instead** — different mechanism, does not address the
  path/ptrace mediation that made `unconfined` necessary in the first place.

## Related

ADR-017 (capabilities), issue #30, issue #24, `docs/03-security/` §Containers,
`docs/07-observability/`, `knowledge/runbooks/container-config-changes.md`.
