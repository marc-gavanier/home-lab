# ADR-030 — Configure the installed tools instead of writing the glue

**Date**: 2026-08-22
**Status**: accepted — direction, with a sequenced plan and a defined end
state. Each replacement needs its own change and its own verification; nothing
here authorises a rewrite. Amended 2026-08-22 after a factual error in the
first version, which is documented in Context rather than rewritten away.

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

### The specific thing that made the decision — corrected

**The first version of this ADR got this section wrong, and the correction is
kept in place rather than quietly rewritten, because it changes what the
decision rests on.**

What was written: Netdata defines 57 alarms, no recipient is configured, so the
work "was redone in bash" — framed as an oversight.

What `docs/07-observability/README.md` actually says, and has said all along:

> "Leaving it that way is a **deliberate choice, not an oversight**. The stock
> alarms are tuned for a generic server — the disk-backlog one alone would fire
> on every nightly backup — so wiring them to Discord would produce exactly the
> noise this stack refuses. **Any signal worth acting on gets added to
> `homelab-health.sh` instead**, with a threshold chosen and justified here, and
> travels the push path that demonstrably reaches a human."

That decision is sound, and the README even records the incident that proves its
consequence was understood: `used_swap` sat CRITICAL for 5 days 19 hours in
August 2026 and reached no one.

So the bespoke layer is not an accident. It exists because a real gap exists:
**curated, per-host assertions with justified thresholds, each reaching a human.**
Netdata's stock alarms do not provide that, and Uptime Kuma only answers
reachability. Writing that layer was rational.

**The mistake is not that it was written. It is that it was written six times,
in bash, with no shared runtime.**

### What the correction opens up

The README refuses to route the **stock** alarms. It does not refuse Netdata's
alarm engine — and that distinction, which the first version of this ADR missed,
is the whole direction.

Measured on the running instance:

- **133 go.d collector templates ship with the agent**, including
  `systemdunits` (unit state — the gap #220 A5 reports on the offsite host),
  `x509check` (certificate expiry, today a hand-rolled check), `dns_query`,
  `filecheck`, `sensors`, `docker`, `smartctl`, `wireguard`, `portcheck`,
  `httpcheck`, `chrony`.

  **Corrected 2026-08-23: shipped is not running.** A module only starts once a
  job configuration exists in `/etc/netdata/go.d`, and that directory was
  **empty**. Checked against the live context list: none of `sensors`, `docker`,
  `x509check`, `dns_query`, `smartctl` or `wireguard` was collecting anything.
  Every condition depending on one of them therefore costs a collector to enable
  and verify *before* an alarm can be written on it — work the first version of
  this ADR did not price.
- **Routing is per-role, with arbitrary role names.**
  `role_recipients_discord[<role>]` is an associative array;
  `SEND_DISCORD="YES"` already, while `DISCORD_WEBHOOK_URL` and
  `DEFAULT_RECIPIENT_DISCORD` are empty.
- The 57 stock alarms address `sysadmin`, `dba` and `silent` — and **none of
  them address a role of our choosing.**

Therefore: define a dedicated role, put curated alarms in `health.d/` addressed
to it, and give a Discord recipient to that role **only**. The stock alarms keep
reaching nobody — the README's decision is preserved *by construction* instead of
by omission — while curated signals travel a path that is configured, declarative
and one-alert-per-condition.

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
detected without alerting.

And the sharpest form of the argument does not need Google at all. This
repository's own observability philosophy reads:

> "One alert = one action needed. Anything that is merely interesting belongs on
> a dashboard, not in a notification."

**The stack's written doctrine and its implementation contradict each other, and
the doctrine is right.** That, not an external standard, is what this ADR acts
on.

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

**One engine per job, curated configuration instead of bespoke code, and one
signal per condition.**

The bespoke layer is not deleted because it is bespoke. It is replaced *check by
check*, and only where an installed engine can express the same assertion with
the same justified threshold.

### The target

| Engine | Its one job | What it absorbs |
|--------------------|---------------------------------------------------------|--------------------------------|
| **Netdata** | collection, thresholds, and routing of **curated** alarms | `health.sh`, `disk.sh`, `offsite-health.sh`, `lynis-report.sh`, `notify-push.sh` |
| **Uptime Kuma** | external reachability + dead-man's switch for scheduled jobs | already correct, keep |
| **Goss** | assertions Netdata cannot express (container config) | `posture.sh` |
| **resticprofile** | backup orchestration | `backup.sh`, `local-maintenance.sh`, `offsite-check.sh` |

### The routing design, which is what makes this compatible with the README

- A dedicated notification role — call it `homelab` — that **no stock alarm
  addresses**.
- `DISCORD_WEBHOOK_URL` set from the secret store;
  `DEFAULT_RECIPIENT_DISCORD` left **empty** so no role is routed by default.
- `role_recipients_discord[homelab]` set, and nothing else.
- Curated alarms live in `health.d/*.conf`, rendered by Ansible from this
  repository, each declaring `to: homelab` and each its own condition.

Consequence: the 57 stock alarms keep reaching nobody, exactly as
`docs/07-observability/README.md` decided — but now *by construction* rather than
because a field was left blank. Nothing about the existing Kuma path changes.

### The migration rule — this is the part that guarantees no do-and-undo

> **One check at a time. The bash line is deleted only after its replacement has
> fired at least once, observed.**

Every step is therefore independently reversible and independently verifiable,
and the two layers overlap briefly on purpose. A step that cannot be observed
firing is not ready to be taken — which is the same standard that demoted the
`reresolve` swap below.

### Sequence

**Phase 1 — build the path, prove it end to end, change no behaviour.**
Mount a config directory into the Netdata container (today only `lib` and
`cache` are mounted, so any configuration would be lost on recreate), template
`health_alarm_notify.conf`, set the webhook from the secret store, define the
`homelab` role, and ship **one** curated alarm whose threshold already exists in
`homelab-health.sh`. Observe it fire. Nothing is deleted in this phase.

**Phase 2 — move the checks Netdata already collects.**
One alarm per condition, each replacing one line of `homelab-health.sh`, deleted
only after it has been observed firing, and `x509check` replaces the hand-rolled
certificate check.

This paragraph also claimed `systemdunits` would close #220 A5 on the offsite
host. It would not have: there is no Netdata agent there, and A5 is a unit left
in systemd's failure state for reporting what it was asked to report — a
detector would have surfaced it, not stopped it. Closed directly instead, with
the `SuccessExitStatus=1` the other two health units already carry.

**Phase 3 — split what remains.**
Whatever `homelab-health.sh` still holds after phase 2 becomes independent
checks, one signal each. Issue #216 dissolves as a side effect: there is no
aggregate left to latch.

**Phase 4 — `posture.sh` → Goss, then `backup.sh` → resticprofile.**
In that order: posture is read-only and its failure is visible, whereas backup
sits on the restore path and deserves its own ADR.

### What "converged" means, so this has an end

- `homelab-health.sh`, `homelab-disk.sh` and `offsite-health.sh` are gone, and
  the conditions they carried exist as individually-addressed alarms.
- No signal aggregates more than one condition.
- Every scheduled job has a dead-man's switch owned by one mechanism, not six
  copies of one.
- The bespoke shell surface is under ~1 000 lines, and what remains is what no
  engine expresses: staged startup under the LUKS constraint, the kill switch,
  the USB tamper trigger, and the personal feed digest.

The measure of progress is the line count going down while the number of
*independently addressed* conditions goes up. Both are countable at any moment,
which is what makes this checkable rather than a matter of opinion.

### Ordering, by irreversibility

The operator cannot afford to do and undo, so within each phase the work is
ordered by what cannot become wrong.

**Cannot be invalidated by anything learned later.**

1. Delete the 277-line wg-easy 14→15 migration. It has run; wg-easy is on
   `15.3.0` and the script's own first guard makes it a no-op — as does its
   fresh-install branch. *Shipped 2026-08-22 (PR #223): 322 lines removed.*
2. Phase 1 above, up to and including the single proving alarm: it adds a path
   and changes no existing behaviour, and if it does not work, nothing has been
   removed.

**Revertible in one PR.** `ddclient` in place of `cloudflare-ddns.sh`; Goss in
place of `posture.sh`; each phase-2 alarm.

**`offsite-wg-reresolve.sh` (74 lines) → wireguard-tools' upstream
`reresolve-dns.sh`.** This was drafted as tier 0 and **demoted the same evening,
on inspection**. The upstream script is the better artefact — a real `[Peer]`
parser, maintained by the WireGuard project, same fail-closed property (the
*name* is handed to `wg set`, `set -e` aborts on a resolution failure). But it
fails the "cannot become wrong" test twice:

- the bespoke script is not a naive reimplementation. Its 150 s threshold sits
  28 s above a measured ceiling (60 samples: p50 55 s, p90 112 s, max 122 s),
  where upstream hardcodes 135 s — exactly the observed boundary. Harmless per
  ADR-029's own analysis, but *different*, not neutral;
- and a failure would be **invisible**. ADR-029 is still "pending the
  deliberate-break test", `offsite-health.sh` contains no systemd unit check and
  no mention of `reresolve`, and this sits on the only route to a host nobody
  can reach. The cost of getting it wrong is a car journey, not 74 lines.

Two prerequisites make it cheap and verifiable, in this order: the break test
ADR-029 already owes, then unit-state monitoring on the offsite host — which
phase 2 delivers via `systemdunits`. It is therefore *scheduled*, not shelved.

**Its own decision.** `backup.sh` → resticprofile, phase 4.

### Three limits found on starting phase 2, which move the estimate

Discovered by doing the work, and each takes a chunk of bash out of "cheap":

- **`disk.space` sees only the container's own mounts** — `/tmp`,
  `/run/netdata`, `/var/lib/netdata` — not the host's `/` or `/mnt/data`, since
  only `/proc` and `/sys` are mounted into netdata. The disk checks in
  `homelab-health.sh` and `homelab-disk.sh` cannot move without mounting the
  host root read-only into a container this repository has deliberately
  hardened. That is a security decision of its own, not a migration step.
- **Netdata cannot resolve the public hostnames**: a request from inside the
  container returns 000, the Docker DNS hairpin already documented for this
  stack. `x509check` needs `extra_hosts` before it can check one certificate.
- **The offsite host has no Docker at all**, so nothing there moves to Netdata
  without a native install on a machine nobody can reach physically.
  `offsite-health.sh` (247 lines) should be assumed to stay.

What is cheap to migrate is what `/proc` already provides — memory, swap, load.
What is not cheap is anything needing host filesystems, name resolution or
hardware access. Read the line-count estimate with that in mind.

### What is NOT decided, and must be established before committing

Stated explicitly so that a future session does not read this ADR as a mandate:

- whether Goss can express the assertions `posture.sh` makes about
  `docker inspect` fields (capabilities, read-only rootfs);
- whether resticprofile handles the append-only offsite repository and the
  ordering of database dumps;
- whether Netdata's Discord routing works on this installation. The *mechanism*
  is verified — per-role recipients with arbitrary role names, `SEND_DISCORD`
  already `YES` — but no notification has been sent end to end. That is exactly
  what phase 1's single proving alarm exists to establish, before anything is
  deleted;
- which conditions in `homelab-health.sh` have no collector equivalent. The
  earlier estimate of "60–70 %" was made before the 133 available go.d
  collectors were enumerated and should not be quoted; the honest answer is that
  the mapping has to be done check by check, which is what phase 2 is.

Each of those needs a short spike before any code moves. **Phase 1 is itself
the spike for the biggest one**, which is why it deletes nothing.

## Consequences

- The measure of success is the **line count going down**, not checks going up.
  A change that adds to the 3 358 lines needs to justify why no installed tool
  covers it.
- Some duplication persists during the transition. That is accepted and bounded
  by the migration rule: a bash line is deleted only after its replacement has
  been **observed** firing, so the two layers overlap on purpose and never leave
  a gap.
- **The first version of this ADR contained a factual error** — it read the 57
  unrouted Netdata alarms as an oversight when they are a documented decision.
  The correction is kept visible in the Context rather than rewritten away,
  because the direction now rests on the opposite reading: the bespoke layer was
  rational, and what is wrong with it is that it was written six times instead
  of once.
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
- **`docs/07-observability/README.md`'s existing decision — Netdata as a
  forensic dashboard, Uptime Kuma as the alerting plane.** Not an alternative to
  reject but a constraint to respect, and the first version of this ADR failed
  to read it. It is preserved: the stock alarms still reach nobody. What changes
  is that curated signals stop being written in bash and start being declared as
  alarms on a role that the stock set does not address.
- **Build an open-source tool for this.** Considered and **rejected on
  evidence**. The gap that would have justified it — a declarative engine for
  curated host assertions with routing — is already filled by what is installed:
  133 go.d collectors, a declarative alarm format, per-role routing, and Goss
  for what remains. Writing and maintaining a project would cost more than the
  code it replaces, and would be the same mistake at a larger scale. If the Goss
  spike fails and container-config assertions turn out to be genuinely
  unserved, that narrow question can be reopened on its own — it is roughly 444
  lines wide, not a platform.
- **Prometheus + Alertmanager + Grafana instead of Netdata.** Rejected for this
  host: heavier on a Raspberry Pi 4, and it would mean introducing a second
  metrics engine to replace one that is already collecting, already declarative,
  and already has the collectors this work needs.

## Related

- Google SRE, *Monitoring Distributed Systems* —
  <https://sre.google/sre-book/monitoring-distributed-systems/>
- Issue #216 — both host-health monitors latched on a scheduled item
- Issue #215 — a guard that could detect but never repair
- Issue #217 — a hand-maintained list standing in for a class
- Issue #220 — five one-liners of the silent-disablement shape
