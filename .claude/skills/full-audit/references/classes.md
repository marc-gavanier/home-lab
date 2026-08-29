# The class register

The audit's unit of progress, and the only object in this skill that can reach
zero.

## Why the unit had to change

Nine runs between 2026-08-15 and 2026-08-29 produced 5, 9, 12, 23, 13, 29, 26,
4 and 23 findings. Counting that way, the work looks endless, and the operator
reasonably asked whether a hundredth run would still return something.

It would. But the number is an artefact of the unit, not a property of the
system. Mapping the 23 findings of the 2026-08-29 afternoon run onto the classes
below gives a different picture:

| Class                                   | Named un-enumerated on | Findings on 2026-08-29 |
|-----------------------------------------|------------------------|------------------------|
| Content of documentary claims           | 2026-08-19             | 11                     |
| The offsite host as a whole             | 2026-08-22             | 3                      |
| Instrument answers a different question | —                      | 3                      |
| Delivery path of a working detector     | —                      | 2                      |
| Posture-check coverage gaps             | —                      | 1                      |
| `start_period` (reopened)               | —                      | 1                      |
| Cost of what feeds the alarms           | —                      | 1                      |
| Sampling instant of a threshold probe   | 2026-08-21             | 1                      |

**Fourteen of the twenty-three fell into two classes this file's predecessor had
already named as un-enumerated, ten and seven days earlier.** They were not
unforeseeable. Nothing obliged anyone to close the class, so each run sampled it,
fixed three instances of eleven, and left it open for the next.

That is the loop. Not a rotting system — a wrong unit of measure. `settled.md`
has carried the correct rule since 2026-08-16 and it has held through four
subsequent runs:

> **Enumeration ends a pattern where sampling makes it recur. Every space
> enumerated once has come back clean and stayed clean.**

A finding is not a countable object: how many exist depends on the search key,
which is written fresh for every run. A **class** is countable, and closing one
is permanent.

## What a class is

Three things, all mandatory. Two of them is not a class, it is a hunch.

1. **A defining property** — the predicate that decides whether an object
   belongs. Written so that someone else applies it and gets the same answer.
2. **An exhaustive space with a cardinal** — the finite set the property can
   live in, and its size `N`. If you cannot state `N`, you cannot close the
   class; you can only sample it forever.
3. **A gate** — the assertion that keeps it closed once swept. Without one, the
   class reopens on the next deploy and the sweep has to be redone by hand.

The scope trap, paid for on 2026-08-22: **define the class by its property, not
by the directory you happen to be reading.** A security agent concluded "exactly
one live instance" from an enumeration of deployed *scripts*, while the worst
instance was a healthcheck in `compose.yaml`.

## The four states

```
OPEN  ──swept N/N, counted──▶  ENUMERATED  ──assertion deployed──▶  GATED
  └──────────────arbitrated by the operator────────────────────▶  DECLINED
```

- **OPEN** — the property is named, the space is not fully swept. Findings here
  are audit results.
- **ENUMERATED** — swept once, completely, with the count recorded. Findings
  here should not recur, but nothing prevents a deploy from reopening it.
- **GATED** — a live assertion fails when the property reappears. **A finding in
  a GATED class is not an audit result; it is a broken gate**, handled like a red
  test.
- **DECLINED** — the operator considered it and said no. Re-raising requires a
  new fact, not a new argument.

## The three rules

1. **A finding is never recorded alone.** It is recorded as an instance of a
   class. If it fits none, **mint a new class** — that is the only move that
   counts as progress against what nobody has thought to look for yet.
2. **A finding in a GATED class is a gate defect.** It leaves the audit's
   perimeter and becomes ordinary maintenance. This is what stops corrections
   from generating audit work forever.
3. **A run does not hunt findings.** It closes OPEN classes by enumeration, and
   mints the classes that are missing. The report to the operator opens with the
   OPEN counter, not with a list.

## The termination criterion

> **The audit is finished when the register holds no OPEN class, and two
> consecutive runs, each using a different search key, mint zero new classes.**

The second half is the real guarantee. "No OPEN class" only says the known
register is worked down; the zero-mint runs test whether the register itself is
complete. Without it you measure only what you already thought to look at.

The honest weakness is the mint rate — it is the one unbounded term. Its defence
is that minting has been driven by new search keys rather than by new territory,
and that the two-run rule makes an incomplete register visible instead of
invisible.

---

# The register

Reconstructed from `settled.md`, runs of 2026-08-15 through 2026-08-29.
**38 classes: 2 OPEN, 7 closed on 2026-08-29, 12 GATED, 17 ENUMERATED, plus the DECLINED list.**

## OPEN — 2

These are the audit's entire remaining perimeter.

| ID | Property | Space, and its cardinal | Why it is still open |
|-----|--------------------------------------------|--------------------------------------------|----------------------------------------|
| C05 | Something a reader would reasonably assume the posture check asserts, and which it does not | The gap between the posture spec and the security posture documented in `docs/03-security/` | Three instances closed by #285 (`docker.sock` exclusivity, host port bindings, `ufw`/`ssh`). The class itself is **not exhaustible by sweeping** — "what a reader would assume" has no cardinal. It stays open as a standing question for each new service, not as a backlog item |
| C09 | Work a container schedules for itself, on a period no sweep window catches | The in-container jobs of 28 containers | Named un-enumerated 2026-08-22. Two checked by hand (Immich's dump, the Nextcloud cron); the set has never been enumerated. **The only class nobody has yet looked at**, and therefore where the next run's yield is |

## Closed by the run of 2026-08-29 — seven classes

| ID | Property | Outcome |
|-----|----------------------------------------------|--------------------------------------------|
| C01 | A documentary statement whose content contradicts the deployed artefact | **ENUMERATED**, not GATED, and the distinction is the honest part. Bounded at last: **472 machine-checkable claim occurrences across 81 files, 218 distinct referents** (121 absolute paths, 29 containers, 26 quoted thresholds, 23 units, 19 goss/alarm names). Twelve instances corrected in #284. Free prose cannot be gated; what replaces a gate is **duplication removal** — where a document lists something the machine owns, print the command that regenerates it instead. Applied three times in #284 |
| C02 | A control on the homelab with no counterpart on the offsite host | **GATED** by #285: the offsite gained `rest-server`, `wg-quick@wg0`, `ssh`, `fail2ban`, a `--failed` catch-all, ufw by its rules, and `offsite-wg-reresolve.timer`. Its two SMART assertions carried both defects `homelab-disk.sh` had already fixed; both corrected |
| C03 | A validation whose instrument answers a different question from the one its comment claims | **ENUMERATED** across all four goss specs on both hosts; one instance (`zcat \| tail` swallowing the CRC verdict) and one latent sibling (`redis-cli ping` exiting 0 on an error reply). Both fixed, both proven to fail on purpose first |
| C04 | A working detector whose delivery path cannot reach a human | **Closed by decision.** smartd's mail channel was dead — and redundant: every alert it carried was already covered, more carefully, by the daily disk report. Silenced deliberately, with the measurement written into `smartd.conf`. Pi-hole's `gravity.info.updated` gained an assertion |
| C06 | A `start_period` whose real startup cost has never been measured | **ENUMERATED**, 13/13, after the first attempt closed at its instrument's edge. netdata cannot observe the wave that starts before netdata; re-measured from `State.StartedAt` to the first listen line, two more had overshot |
| C07 | A collector whose polling cost is disproportionate to the granularity of what it feeds | **GATED** by #285, and the gate is two assertions because one was a proxy. The floor is now derived from the resolution rather than written twice |
| C08 | A threshold probe that samples at an instant which cannot contain the peak it guards | **Closed by decision.** The homelab reads `Power Cycle Min/Max`, which resets each boot. The offsite keeps the instantaneous reading and reports its peak instead — its only maximum is lifetime, and a threshold on a figure that cannot come back down latches red forever |

## GATED — 12

A finding in any of these is a broken gate, not an audit result.

| ID | Property | Gate |
|-----|------------------------------------------------------|--------------------------------------------------------|
| C10 | A credential store readable beyond its service | goss posture, **derived** from the dump variables rather than listed, plus a named assertion for the Immich dumps (#217, #272) |
| C11 | A container whose running `Config.User` differs from what compose declares | posture assertion, 9 services (#145) |
| C12 | A rotated secret no consumer restarts to read | one handler per consumer, mapped from the running mounts; 51 notify sites, 0 orphans (#145) |
| C13 | A declared environment value shadowed by a persisted config file | posture assertion comparing the container's environment to the file it reads (#124) |
| C14 | A certificate with no expiry watch, or a silent ACME failure | `homelab-health.sh` parses `acme.json` directly, 21-day threshold, 18/18 (#157) |
| C15 | The offsite repository losing the one property that makes it a backup | goss assertion on the live rest-server process, proven to fail in both modes (#278) |
| C16 | A read-write bind mount its container cannot create files in | posture assertion, continuous since 2026-08-16 |
| C17 | A filesystem never checked, and boot triggers reset every boot | `passno` plus the daily disk report's `ext4 clean` field (#254, #260) |
| C18 | A database dump absent, stale, or empty | goss `backup-dumps`, 19 checks, generated from the dump variables so a database cannot get a dump without a check (#177, ADR-032) |
| C19 | A failed systemd unit, or a timer whose service did not succeed | goss `units.yaml` plus the health script's last-run check — **homelab only; the offsite half is C02** |
| C20 | A secret that a deploy reports as rotated without rotating it | posture check reports the unrotated secret; case-mismatch bug fixed (#159) |
| C21 | A snapshot that missed its offsite copy and is never retried | time-window filter plus the retention monitor (#158, #168) |

## ENUMERATED — 17

Swept completely at least once. Re-check only after a change that could reopen
them; do not re-derive without a new symptom.

| ID | Property | Swept | When |
|-----|--------------------------------------------------|-----------------|------------|
| C22 | A healthcheck that cannot report the failure it names | 28/28, with negative **and** positive controls | 08-19, re-swept 08-29 |
| C23 | A kernel parameter differing between hot and boot path, or between hosts | 30/30 both hosts | 08-19 |
| C24 | An image that is not genuinely arm64 | 28/28 | 08-21 |
| C25 | A bind mount whose inode differs from what the container sees | 19/19 against `/proc/<pid>/root`; 62 mounts re-checked 08-29 | 08-19 |
| C26 | A credential reaching a command line, a child process, a scheduled job or a trace | 4 axes, incl. 3 457 `/proc` sweeps over 140 s with a positive control | 08-22 |
| C27 | A deployed artefact differing from the repo | 12/12 by sha256, 25/25 templates, both hosts | 08-29 |
| C28 | An operator key no role reads, or a role key the example omits | 123 keys, both directions, 0 and 0 | 08-29 |
| C29 | A construct that disables a feature silently | 81 read one by one; 08-29: 80 `default()`, 22 `failed_when: false`, 5 `creates:`, 3 absent-var gates | 08-19, 08-29 |
| C30 | A proxy router or middleware declared but not applied | 19/19 routers in the live API, headers on 18/18, `vpn-only` proven both ways | 08-29 |
| C31 | A name resolving differently inside and outside | split DNS 18/18, single DoH upstream, 2590/2590 queries | 08-29 |
| C32 | A port reachable from outside that should not be | probed from the offsite uplink with a known-open control | 08-19, 08-29 |
| C33 | A broken relative link or a path that does not exist | 104 links, 123 absolute paths | 08-29 |
| C34 | A service page contradicting its ADR, its runbook or its container | 20 pages × 3 axes | 08-22 |
| C35 | A push monitor carrying a constant instead of its script's message | 12, now 15; all at `maxretries=0` | 08-19, 08-29 |
| C36 | An unsized tmpfs | 37, parsed rather than grepped | 08-21 |
| C37 | A WAL-mode SQLite copied without its `-wal` | 3 dumped / 4 declined / 3 ephemeral | 08-29 |
| C38 | A container log growing without rotation | 28/28, rotation proven applied rather than declared | 08-21, 08-29 |

## DECLINED

The operator considered these and said no. They are in the register so that a
run does not spend budget re-proposing them. Detail and reasoning stay in
`settled.md`.

Live kernel patching · an IPS/reputation layer · a forward-auth SSO portal ·
user-namespace remapping · the kernel audit daemon · additional fail2ban jails ·
reinstalling rkhunter · unmasking the distribution's lynis timer ·
`errors=remount-ro` (a decision, not a finding) · external supervision of the
main host · a timed restore drill · drift detection between the two hosts ·
dumping the media services' metadata databases · expiring the frozen snapshots
of obsolete path sets · memory limits on containers · reopening the DNS-over-HTTPS
investigation · the structural elevated capabilities and writable root filesystems.

---

## Working a run

1. Read this file. The OPEN table **is** the mandate; the number of OPEN classes
   is the headline of the report.
2. Assign each OPEN class to the domain agent that owns its space. An agent's
   job is to close its class by enumeration — state `N`, sweep `N/N`, record the
   count — or to say precisely why the space cannot be bounded.
3. Anything found that fits no class is a **mint**. Write the property and the
   space before writing the instance; an instance without a property is how C01
   stayed open for ten days.
4. Update this file before writing to the operator: state transitions, new
   cardinals, new classes.
5. A class only reaches GATED when the assertion has been **made to fail on
   purpose**. #278 is the reference: it was disbelieved until it failed in both
   modes.

## What this file is not

It is not a findings log — that is the issue tracker. It is not the history of
decisions or the catalogue of instrument traps — that is `settled.md`. It holds
exactly one thing: **which classes are closed, which are open, and what keeps
the closed ones closed.**
