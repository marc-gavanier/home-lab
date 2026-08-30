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

**The evening run of 2026-08-29 put a number on that weakness, and it is not
reassuring.** Its key was *time* — anything with a period, a window, a deadline
or a clock. It minted **five** classes and reopened two, from a register that had
just been worked down to two OPEN classes. The reason is visible in hindsight:
all 38 classes then on file asked whether something was *configured* correctly.
Not one asked whether it was *timed* correctly. A single new dimension therefore
paid five classes.

The lesson for whoever writes the next key: pick a dimension, not a topic. The
keys that have paid were dimensions the register had no vocabulary for. The next
candidates, unused so far — **order** (what depends on what, and what happens
when the order inverts), **scale** (what breaks at ten times the data), and
**identity** (who exactly is acting, as opposed to what is running).

---

# The register

Reconstructed from `settled.md`, runs of 2026-08-15 through 2026-08-29 (evening).
**43 classes: 4 OPEN, 13 GATED, 24 ENUMERATED, 2 closed by decision, plus the
DECLINED list.** (GATED = C02, C07, C10-C12 and C14-C21;
ENUMERATED = C01, C03, C06, C09, C13, C22-C38, C39 and C43; closed by decision = C04, C08.)
C02 was re-gated and C13 downgraded on 2026-08-30 by #291: the totals are
unchanged and the membership is not, which is the half that matters.

## OPEN — 4

These are the audit's entire remaining perimeter. One survives from the morning;
three of the five minted by the evening run of 2026-08-29 under the search key
**time** are still here. C39 and C43 were enumerated and closed on 2026-08-30
(#290, #292) and have moved to their own section below. **C42 stays open, and
its row records why: the instance it was minted on was misdiagnosed, and the
correction is the result.**

| ID | Property | Space, and its cardinal | Why it is still open |
|-----|--------------------------------------------|--------------------------------------------|----------------------------------------|
| C05 | Something a reader would reasonably assume the posture check asserts, and which it does not | The gap between the posture spec and the security posture documented in `docs/03-security/` | Three instances closed by #285. The class is **not exhaustible by sweeping** — "what a reader would assume" has no cardinal. A standing question for each new service, not a backlog item. Two instances instructed under the time key on 2026-08-29 evening and tracked in **#294**: the lynis *rule set* has no freshness assertion (only the report has one), and no assertion binds the live WireGuard peers to the enrolled clients |
| C40 | A container that begins an ordered shutdown and is killed before finishing it | 28 containers × (signal, grace, real drain time) | Swept 28/28 on the 02:45 reboot, **4 instances**: `immich-db`, `miniflux-db`, `nextcloud-db`, `pihole` all needed crash recovery after a *deliberate* reboot. Structurally invisible: the evidence of a failed shutdown is never in its own log, only in the **next** startup's. Cause is configurational — `StopTimeout=<nil>` on all 28, no `stop_grace_period` anywhere, no `ExecStop` on `homelab-stack-startup`. Tracked as **#288** |
| C41 | A dead-man's fuse that the restart of its own watchdog re-arms from zero | The 15 Kuma push monitors | Kuma schedules a push monitor's first check one full interval after **process start**, not after the last heartbeat. Proven on data, not on code: monitor 30 was silent 93 474 s against a 90 000 s window and emitted **no DOWN**, while a 90 001 s silence on 2026-08-13 — one second over, no restart in between — did emit one. Degrades the *silence* half only; the failure half still works. Tracked as **#289**, together with a C03 instance whose space had been under-scoped to the goss specs. **Kuma is not repairable from here**, so the fuse is checked host-side against `heartbeat.time` — the moment a beat was received, which no restart reschedules — and the assertion fires on the INCONSISTENCY (silent past its window while the last beat still says UP), never on a genuine outage, so a late backup cannot mute the posture monitor for days |
| C42 | A time-ordering mechanism that ranks by a timestamp the machine wrote before its clock was correct | 6 time-ordered mechanisms on the two hosts | **STILL OPEN — mechanism now CONFIRMED, fix shipped, unconfirmed until the next boot.** The instance is exactly as minted. With no RTC and no `/usr/lib/clock-epoch`, systemd advances the clock to the mtime of its own binary — 2026-07-28 17:04:45, measured, identical on both hosts because they carry the same package. On the reboot of 2026-08-30 17:00 the journal recorded boot 0 as beginning `Tue 2026-07-28 17:05:07`, timesyncd started **90 s** into that window, and the segment opened during it became the OLDEST file on the host — ahead of data from 2026-08-15 — ten minutes after being written. journald's vacuum deletes the oldest first, so the first thing it removes is the beginning of the current boot. Both hosts carry a 31-32 day skew; only the homelab has paid for it, because the offsite never vacuums. Fixed with `fake-hwclock` (ADR-030: a packaged tool, not new glue), which cannot make the pre-NTP clock correct but makes it close enough that ordering stops lying. **Recorded because it cost something:** the pass of 2026-08-30 16:00 declared this mechanism refuted — no segment carried a pre-synchronisation timestamp, and deleting the oldest first cannot remove the newest boot's beginning. Both observations were real; the conclusion was wrong. The segments were absent because they had already been vacuumed, and the newest boot's beginning is precisely what a delete-oldest-first vacuum takes when that beginning is stamped older than everything else. **The refutation trusted a timestamp written before synchronisation — it was an instance of the class it was refuting.** The lesson generalises past this row: absence of evidence in a store whose job is to delete things is not evidence of absence, and a class about untrustworthy values cannot be closed on a measurement of those values |

## Settled on 2026-08-30 — C39 and C43

| ID | Property | Cardinal, and outcome |
|-----|--------------------------------------------|--------------------------------------------|
| C39 | An event whose only durable evidence has a retention shorter than the event's own period | **ENUMERATED, cardinal 16** — every periodic job on the two hosts, against the most durable store that records a *distinguishable* result for it. 14 of 16 already correct and not by accident: their Kuma messages carry readings, so a run that did nothing cannot produce the message of a run that did something. **1 instance**, and it was the one that mattered: the weekly `prune + check` has two modes — re-read a twelfth of the repository's bytes, or list metadata — and after ADR-031 both pushed `prune and check completed`. The distinction had EXISTED and was lost in the migration; Kuma still holds the shell job's `local prune + deep check (8/12) passed` from 2026-08-02 beside `local prune + metadata check passed` from 08-09. Restored, richer, and gated from outside by `restic-deep-check-not-stale` (45 days, against a 24-37 day healthy gap) because resticprofile cannot know what ran last month. **A second instance on the cardinal's other axis**: the redacted access log at 6.17 MB/day spanned 4.86 days on the daemon default, against a host whose only trace there is one request a week — given its own 10 x 20 MB block, ~32 days. The 2 jobs whose only evidence is the journal took the retention branch instead: 500M held 16 days against monthly events, raised to 1500M (~48 days), which adds no writes because a cap governs deletion |

| C43 | An address that a deployed configuration hard-codes and a third party assigns | Enumerated: **6**, of which **1** was monitored | **ENUMERATED and closed on 2026-08-30 (#292).** Six addresses, each now pinned, derived, or watched, and the deliverable was stating which per address. 2 derived (the public IPv4 by the DDNS, the offsite endpoint by the re-resolve timer), 4 newly watched: the LAN address against `homelab_ip` — a one-day lease under 19 hardcoded occurrences, including the resolver handed to every VPN client — and the three Docker subnets, which carry no `ipam_config`. One of the four is load-bearing rather than tidy and is asserted against the two AUTHORITIES instead of a remembered value: Traefik's `vpn-only` admits `172.18.0.0/16` because that is where `proxy` happens to live, so the day Docker moves it every VPN client is refused — the assertion compares the live network to the allowlist file. Pinning was rejected on cost, not on principle: `proxy` is `external` and recreating it stops every container on it. Two stale ranges corrected (a C01 instance): one placed `homelab_socketproxy` at 172.21 against a measured 172.20, the other described 172.20 as a phantom's range when it is now a live one |

## Reopened by the run of 2026-08-29 (evening) — 2, plus one downgrade

An ENUMERATED class has no gate; these are what "will reopen" looks like in
practice, and both were reopened by changes made *after* their sweep.

| ID | What reopened it |
|-----|--------------------------------------------------------------|
| C26 | A credential reaching **a trace**. #259 removed the Traefik access log's 400-599 filter on 2026-08-28 so the log could answer who is present, and that filter is exactly what had made this class invisible to the 4-axis sweep of 2026-08-22 — the sweep was correct on the day and a later fix reopened the class underneath it. Two services, both of which can only present the credential where it lands. **The mechanism is not recorded here: this file is public and, until #287 shipped, the condition was live.** It is in the audit report of 2026-08-29, held off-repo. Closed by ADR-034 — masked before the line reaches any durable store, and gated by `traefik-access-log-carries-no-credential`. Tracked as **#287** |
| C27 | The repo is ahead of the host by the four `compose.yaml` changes of PR #286: `uptime-kuma` 960 s→180 s, `forgejo` 420 s→120 s, and both Redis healthchecks still unguarded. **C03 and C06 are therefore closed in the repo and not on the machine.** 12/12 running containers do match the deployed file, so there is no second "deployed but not applied" layer. **Not an issue — deploy #286.** |
| C03 | **Its space, not a change to the code.** Closed on 2026-08-29 as enumerated across the four goss specs; the instance found on 2026-08-30 is in none of them, because the sweep had been scoped to the files it was reading instead of to the property. Nothing regressed — the class had never been swept over the space it names. Restated and re-swept in **#289**; see its row below |
| C13 | **Downgraded GATED → ENUMERATED on 2026-08-30 (#291),** by the re-check C02's downgrade called for. Its gate is `homelab-posture.sh`'s config.json comparison, hardcoded to **vaultwarden** — a list of one presented as a gate on "a declared environment value shadowed by a persisted config file". The check itself is careful (it resolves `*_FILE` indirections, it reports an unreadable secret rather than passing), and none of that makes it derived. Its real space is every container that persists a config file capable of shadowing an injected value, and that has never been enumerated. **No second instance is claimed here** — what is claimed is that nothing would find one |
| C02 | **Downgraded GATED → ENUMERATED.** Its gate is a *list* of seven assertions, not a derivation, so it cannot catch an eighth instance — and there is one: lynis is installed on the offsite with its timer masked and no replacement, last report 2026-08-17. C10 is the shape C02 needs ("derived from the dump variables rather than listed"). Tracked as **#291**, which also re-checks the twelve remaining GATED rows for the same disguise. **Re-GATED on 2026-08-30.** The gate derives the control set from the machine — every deployed `homelab-*.timer` — and requires each to be classified in `homelab_control_timers`, failing in both directions so a stale exemption is as loud as an unclassified timer. The offsite assertions are generated from that register, so they cannot be shorter than it and it cannot be shorter than reality. Proven by removing an entry (`no offsite decision: homelab-lynis`), by adding one for a timer that does not exist (`register names timer(s) that are not deployed`), and by starving the enumeration (`only 0 ... the sweep stopped matching`). The eighth instance was settled by REMOVING lynis from the offsite rather than carrying its schedule across |

## Closed by the runs of 2026-08-29 — eight classes

Seven in the morning, C09 in the evening. C02's row records its downgrade.

| ID | Property | Outcome |
|-----|----------------------------------------------|--------------------------------------------|
| C01 | A documentary statement whose content contradicts the deployed artefact | **ENUMERATED**, not GATED, and the distinction is the honest part. Bounded at last: **472 machine-checkable claim occurrences across 81 files, 218 distinct referents** (121 absolute paths, 29 containers, 26 quoted thresholds, 23 units, 19 goss/alarm names). Twelve instances corrected in #284. Free prose cannot be gated; what replaces a gate is **duplication removal** — where a document lists something the machine owns, print the command that regenerates it instead. Applied three times in #284. Its **temporal slice** was swept to completion on 2026-08-29 evening — N=88 from 389 candidate lines across 63 files, 88/88, 68 exact and **20 contradicted** — and is tracked as **#293** |
| C02 | A control on the homelab with no counterpart on the offsite host | **ENUMERATED, not GATED** — recorded GATED by #285 on 2026-08-29 morning and downgraded the same evening. #285 gave the offsite `rest-server`, `wg-quick@wg0`, `ssh`, `fail2ban`, a `--failed` catch-all, ufw by its rules, and `offsite-wg-reresolve.timer`, and corrected its two SMART assertions. But a list of seven assertions is not a gate on the property, and the eighth instance was found the same day |
| C09 | Work a container schedules for itself, on a period no sweep window catches | **ENUMERATED 28/28**, closed 2026-08-29 evening after being named un-enumerated on 08-22 and sampled by three runs. Four axes: processes by cgroup from the host, cron files including `/etc/crontabs`, application schedulers queried in their own state, clocks. 4 containers carry an internal crond (1 inert), 11 an application scheduler, 4 databases an internal maintenance, 11 schedule nothing. **1 instance**: two Miniflux feeds of 119 reached `parsing_error_count = 3`, which excludes them from the scheduling query while leaving `disabled` false — feed 89 unpolled since 2026-08-20 and unable to recover on its own (tracked as **#294**). Also established: 25 of 28 containers run at UTC, with no job landing in the backup window |
| C03 | A validation whose instrument answers a different question from the one its comment claims | **ENUMERATED, and its space restated on 2026-08-30 (#289).** It had been scoped to *the four goss specs on both hosts* — the directory the first sweep happened to be reading — rather than to the property, which is the scope trap this register already records from 2026-08-22. Restated: **every guard in the repo that decides whether a downstream step may trust a value**, swept as 20 shell artefacts × their guard sites. First sweep (goss specs): `zcat \| tail` swallowing the CRC verdict, and `redis-cli ping` exiting 0 on an error reply. Re-sweep under the restated space, **3 more**: the netdata adapter's retry, guarded on "the body is not empty" while the caller needed "the alarms parsed" — the only one **observed**, one run logging `answered on attempt 3` and `unreachable or unparseable` together; and two latent siblings, `feed-digest.sh` reading a 200 that is not an entries page as "nothing unread" and pushing UP, and `cloudflare-ddns.sh` guarding a raw body for emptiness while consuming a derivation of it, which answers a malformed 200 by creating a duplicate record. All five fixed, all five proven to fail on purpose first |
| C04 | A working detector whose delivery path cannot reach a human | **Closed by decision.** smartd's mail channel was dead — and redundant: every alert it carried was already covered, more carefully, by the daily disk report. Silenced deliberately, with the measurement written into `smartd.conf`. Pi-hole's `gravity.info.updated` gained an assertion |
| C06 | A `start_period` whose real startup cost has never been measured | **ENUMERATED**, 13/13, after the first attempt closed at its instrument's edge. netdata cannot observe the wave that starts before netdata; re-measured from `State.StartedAt` to the first listen line, two more had overshot |
| C07 | A collector whose polling cost is disproportionate to the granularity of what it feeds | **GATED** by #285, and the gate is two assertions because one was a proxy. The floor is now derived from the resolution rather than written twice |
| C08 | A threshold probe that samples at an instant which cannot contain the peak it guards | **Closed by decision.** The homelab reads `Power Cycle Min/Max`, which resets each boot. The offsite keeps the instantaneous reading and reports its peak instead — its only maximum is lifetime, and a threshold on a figure that cannot come back down latches red forever |

## GATED — 12 here, plus C07 recorded above

A finding in any of these is a broken gate, not an audit result.

**C02 left the GATED state on 2026-08-29 evening, and the reason generalises to
every row below: a list of assertions is not a gate on a property.** Before
recording a class as GATED, check that its assertion is *derived* from the thing
it guards — the way C10's is generated from the dump variables and C18's from the
same source — rather than enumerating the instances that happened to be found.
A listed gate closes the instances; only a derived one closes the class.

**Re-checked on 2026-08-30 (#291).** Two rows were read at the code rather than
taken from their description. **C11 is genuinely derived** — the posture spec is
generated from `compose.yaml` and emits the user assertion for every service that
declares one, so "9 services" is a count and not a hand-list. **C13 is not**, and
it was downgraded. The remaining ten were checked against what this register
records of their derivation rather than re-read line by line; that is a weaker
check, and it is stated as one.

| ID | Property | Gate |
|-----|------------------------------------------------------|--------------------------------------------------------|
| C10 | A credential store readable beyond its service | goss posture, **derived** from the dump variables rather than listed, plus a named assertion for the Immich dumps (#217, #272) |
| C11 | A container whose running `Config.User` differs from what compose declares | posture assertion, 9 services (#145) |
| C12 | A rotated secret no consumer restarts to read | one handler per consumer, mapped from the running mounts; 51 notify sites, 0 orphans (#145) |
| C13 | A declared environment value shadowed by a persisted config file | **Left this table on 2026-08-30 — see the downgrade above.** The assertion is hardcoded to vaultwarden (#124, #159); a list of one is not a gate |
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
| C26 | **REOPENED 2026-08-29 evening** — a credential reaching a command line, a child process, a scheduled job or a trace | 4 axes, incl. 3 457 `/proc` sweeps over 140 s with a positive control | 08-22 |
| C27 | **REOPENED 2026-08-29 evening** — a deployed artefact differing from the repo | 12/12 by sha256, 25/25 templates, both hosts | 08-29 |
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
