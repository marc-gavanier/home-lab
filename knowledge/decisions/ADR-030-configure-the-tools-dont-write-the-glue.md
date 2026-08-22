# ADR-030 — Configure the installed tools instead of writing the glue

**Date**: 2026-08-22
**Status**: accepted — direction only. Each replacement below needs its own
change and its own verification; nothing here authorises a rewrite.

## Context

Six full audits between 2026-08-15 and 2026-08-22 produced a steady yield —
5, 9, 12, 23, 4, ~29, ~22 confirmed findings — with no sign of decay. The
2026-08-22 morning run wrote down the law that fits the data: *the yield tracks
what shipped since the last run, not the residual defect stock*. It called the
second stock "sweep residue", created by the corrections themselves.

The evening run of the same day established **where** that residue lives, and
the number is the reason for this ADR.

### The measurement

```
3 358 lines of hand-written shell across 18 scripts
   70 additional shell blocks embedded in Ansible roles
```

Distribution of the last 43 `bug` issues by layer:

| Layer | Bugs | Share |
|-----------------------------|------|-------|
| **Hand-written code / glue** | 30 | **70 %** |
| Documentation, ADRs | 8 | 19 % |
| Off-the-shelf software | 5 | 12 % |

Traefik: 21 routers, 0 errors, 19/19 middleware chains intact. Docker: 28/28
images pinned, 61/61 mounts used, `RestartCount=0` on all 28. Restic: retention
matches the documented policy, restore runbook accurate on every claim checked
against the machine. Ansible structure: 93 operator keys, zero dead knobs, 30
handlers with no orphan either way.

**The components we did not write are healthy. What breaks, at 70 %, is the
glue we wrote.**

### The specific thing that made the decision

Netdata has been running on this host since the beginning. It defines **57
alarms** covering CPU, RAM, swap, load, file descriptors, disk space across 5
mount points, inodes, and per-container memory and CPU for all 28 containers —
plus ML anomaly detection. Twelve of those alarms are addressed to the
`sysadmin` role, nine to `root`, thirty-six are deliberately `silent`.

**No recipient is configured, so none of them can reach a human.**

Beside them sit 740 lines of `homelab-health.sh` and `homelab-disk.sh`
re-implementing a subset of the same checks and pushing to Uptime Kuma. The tool
was installed, its alarms were written, the recipient line was never filled in,
and the work was redone in bash.

### Six scripts, one pattern, six conventions

`health`, `disk`, `posture`, `offsite-health`, `lynis-report` and `notify-push`
all follow "run checks → aggregate a human-readable message → push to an Uptime
Kuma monitor". The pattern is written six times by hand, which is why
`SuccessExitStatus=1` is present on three units and absent on the fourth — a
finding of the 2026-08-22 evening run.

### What the practice says

This is not a matter of taste. Google SRE's *Monitoring Distributed Systems*
describes the failure mode directly:

> "monitoring can become so complex that it's fragile, complicated to change,
> and a maintenance burden"

> "blending together too many results in overly complex and fragile systems…
> maintaining distinct systems with clear, simple, **loosely coupled** points of
> integration is a better strategy"

> "The rules that catch real incidents most often should be as simple,
> predictable, and reliable as possible."

`homelab-health.sh` aggregates 17 unrelated checks into one signal. On
2026-08-22 that signal was latched DOWN for the whole day on the least urgent
thing it watches — a pending kernel reboot — and the 17 checks behind it,
including the only coverage of the 10 containers with no monitor of their own,
detected without alerting. That is the textbook anti-pattern, not a local bug.

Two more external findings, for the same reason:

- **Ansible.** `shell` and `command` forfeit idempotence: the task runs every
  time, always reports `changed`, and the state check has to be reimplemented by
  hand. This repository does it 70 times.
- **The dead man's switch.** The defect that started this whole audit series on
  2026-08-15 was a no-op push, so a failed run reported success. That is exactly
  the job of a dedicated cron-monitoring tool; Uptime Kuma's push monitor is the
  less mature substitute for it (no cron expression parsing, no real grace
  period semantics).

## Decision

**Prefer configuring an installed tool over writing glue. One brick, one job.**

Concretely, the target shape — each brick with a single responsibility, and
loosely coupled points of integration rather than one aggregate:

| Brick | Its one job | What it replaces |
|--------------------|------------------------------------------------|--------------------------------|
| **Netdata** | host and container metrics, thresholds, alarms | most of `health.sh` + `disk.sh` |
| **Uptime Kuma** | external reachability of the services | already correct, keep as is |
| **cron monitoring** | dead man's switch for scheduled jobs | the push pattern copied 6 times |
| **Goss** | declarative posture assertions | `posture.sh` |
| **resticprofile** | backup orchestration | `backup.sh` + maintenance + offsite-check |

And the rule that follows from it, binding on future work:

> **Before adding a check, a script, or a shell block, establish that no
> installed tool already does it.** If one does and is not routed, route it. A
> new script is the last resort, not the first.

### Ordering, by irreversibility — this is part of the decision

The operator's constraint is that they cannot afford to do and undo. So the work
is ordered by what cannot become wrong, not by what is most valuable.

**Tier 0 — cannot be invalidated by anything learned later.**

1. Route the Netdata alarms to the Discord webhook that already exists: twelve
   already-written alarms become real alerts. Configuration, not code.
2. Delete the 277-line wg-easy 14→15 migration. It has run; wg-easy is on
   `15.3.0` and the task is self-guarding, so it will never fire again.
   *Shipped 2026-08-22 (PR #223): 322 lines removed.*

**Tier 1 — replacement by an established tool, revertible in one PR.**
`ddclient` in place of `cloudflare-ddns.sh`; Goss in place of `posture.sh`.

**Tier 1 also — `offsite-wg-reresolve.sh` (74 lines) → wireguard-tools'
upstream `reresolve-dns.sh`.** This was drafted as tier 0 and **demoted the same
evening, on inspection**. The upstream script is the better artefact — a real
`[Peer]` parser, maintained by the WireGuard project, same fail-closed property
(the *name* is handed to `wg set`, `set -e` aborts on a resolution failure). But
tier 0 means "cannot be invalidated by anything learned later", and this fails
that test twice:

- the bespoke script is not a naive reimplementation. Its 150 s threshold sits
  28 s above a measured ceiling (60 samples: p50 55 s, p90 112 s, max 122 s),
  where upstream hardcodes 135 s — exactly the observed boundary. Harmless per
  ADR-029's own analysis, but *different*, not neutral;
- and a failure would be **invisible**. ADR-029 is still "pending the
  deliberate-break test", `offsite-health.sh` contains no systemd unit check and
  no mention of `reresolve`, and this sits on the only route to a host nobody
  can reach. The cost of getting it wrong is a car journey, not 74 lines.

Two prerequisites make it cheap and verifiable, in this order: the break test
ADR-029 already owes, then watching unit state on the offsite host (#220, A5).
Until both exist, no mechanism on that host is trustworthy — neither the
bespoke one nor the upstream one.

**Tier 2 — a decision of its own, deliberately not taken here.**
`backup.sh` (594 lines) → resticprofile. It sits on the restore path.

### What is NOT decided, and must be established before committing

Stated explicitly so that a future session does not read this ADR as a mandate:

- whether Goss can express the assertions `posture.sh` makes about
  `docker inspect` fields (capabilities, read-only rootfs);
- whether resticprofile handles the append-only offsite repository and the
  ordering of database dumps;
- whether Netdata's Discord routing works on this installation — untested;
- Netdata does **not** natively cover DNS resolution, certificate expiry, mirror
  state or pending-reboot. Roughly 60–70 % of `health.sh`'s checks map onto
  existing alarms; the remainder stays — but as four or five **independent**
  signals, which is what the practice prescribes, instead of one latch.

Each of those needs a short spike before any code moves.

## Consequences

- The measure of success is the **line count going down**, not checks going up.
  A change that adds to the 3 358 lines needs to justify why no installed tool
  covers it.
- Some duplication persists during the transition. That is accepted: removing a
  bash check before its replacement alerts would be a regression, so the order
  is always *route the tool first, delete the script second*.
- Audits keep their value but change their question. `/full-audit` currently
  hunts defects in the glue, which guarantees a yield and feeds the loop it is
  meant to close. The question worth asking next is **what can be deleted**.
- The 1 223 lines of `settled.md` are a symptom, not an asset: they are the
  amount of tacit knowledge now required to touch this machine safely. Shrinking
  the glue should shrink them.

## Alternatives considered

- **Keep writing the glue, with more discipline.** Two rules were drafted on
  2026-08-22 — close on the class rather than the instance, and close on an
  execution rather than an inspection. They are sound and worth applying, but
  they only slow residue production. Rejected as a strategy; retained as hygiene.
- **Build an open-source tool for this.** Considered and rejected: roughly 1 900
  of the 3 358 lines are replaceable by configuring tools that already exist or
  are one package away, and 277 are dead. The real gap — declarative assertions
  over `docker inspect` — is about 444 lines wide, and writing plus maintaining
  a project for it would cost more than it removes. It would be the same mistake
  at a larger scale.
- **Prometheus + Alertmanager + Grafana instead of Netdata.** Rejected for this
  host: heavier than Netdata on a Raspberry Pi 4, and Netdata is already
  installed with its alarms already written. The work is to route them, not to
  replace them.

## Related

- Google SRE, *Monitoring Distributed Systems* —
  <https://sre.google/sre-book/monitoring-distributed-systems/>
- Issue #216 — both host-health monitors latched on a scheduled item
- Issue #215 — a guard that could detect but never repair
- Issue #217 — a hand-maintained list standing in for a class
- Issue #220 — five one-liners of the silent-disablement shape
