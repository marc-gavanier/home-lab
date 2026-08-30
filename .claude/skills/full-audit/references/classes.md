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
keys that have paid were dimensions the register had no vocabulary for.

**The evening run of 2026-08-30 used `order` and minted eleven** — more than
`time` did — which confirms the mechanism rather than the pessimism: eleven
classes existed all along and nothing had a word for them. The clock on the
termination criterion therefore resets, and the two dimensions named and still
unused are **scale** (what breaks at ten times the data) and **identity** (who
exactly is acting, as opposed to what is running).

One caution for whoever writes the `scale` key. `order` and `time` both had a
property this file should not take for granted: every instance was observable
on the machine tonight. `scale` mostly is not, and the mandate's rule 1 —
"an evidenced clean beats a speculative list" — will bite harder there. Prefer
the parts of scale that leave a trace already (retention windows, growth rates
in netdata, a store whose oldest record is younger than its own period) over the
parts that need a thought experiment.

---

# The register

Runs of 2026-08-15 through 2026-08-30 (evening).
**54 classes: 6 OPEN, 14 GATED, 32 ENUMERATED, 2 closed by decision, plus the
DECLINED list.** (GATED = C02, C07, C10-C12, C14-C21 and C41;
ENUMERATED = C01, C03, C06, C09, C13, C22-C40, C42-C45, C47-C49 and C53;
closed by decision = C04, C08.)

## What the run of 2026-08-30 (evening) cost and paid

Its key was **order** — what depends on what, and what breaks when the order
inverts. It closed three of the four OPEN classes and **minted eleven**, which
is the second confirmation of the pattern the `time` key established the night
before: a register of 43 classes all asking whether something was *configured*
correctly had no vocabulary for *sequence*, so a single new dimension paid
eleven times.

The honest reading is not that the system rotted overnight. It is that the mint
rate tracks the number of dimensions never yet applied, and two remain named and
unused: **scale** (what breaks at ten times the data) and **identity** (who
exactly is acting, as opposed to what is running). Expect the next key to pay
similarly, and expect the one after that to pay less.

**The run's own headline was a class it did not mint.** C45 — a reporting path
that cannot report its own failure — is the defect that created this skill on
2026-08-15. It was found then on ONE script, fixed there, and the fix never
reached the nine siblings. Ten push sites, swept: two both detected a failed
push and said so, seven detected it and threw the verdict away with
`2>&1 || true`, one had no `--fail` at all. Measured live, not inferred: after
the 17:29 reboot three runs of `homelab-health` finished green having done their
work, and none reached the dashboard. **A fixed instance is not a closed class,
and this file existed for fifteen days before that sentence had a number.**

## OPEN — 6

| ID | Property | Space, and its cardinal | Why it is still open |
|-----|--------------------------------------------|--------------------------------------------|----------------------------------------|
| C05 | Something a reader would reasonably assume the posture check asserts, and which it does not | The gap between the posture spec and `docs/03-security/` | **Not exhaustible by sweeping** — "what a reader would assume" has no cardinal. A standing question for each new service. The two instances of #294 were verified live on 2026-08-30: the WireGuard gate is deployed, correct (4 live peers == 4 enrolled clients) and fails closed on both degenerate branches |
| C46 | A supervisor's log that declares an act it did not perform | Unbounded as stated; the instance is `dockerd`'s stop path | **1 instance, arbitrated rather than believed.** `journalctl -u docker.service` wrote 17 `failed to exit within Ns — using the force` lines for the 17:29 shutdown; pairing each by container id against `received task-delete event from containerd` gives **8 genuinely killed** (task-delete +103 to +338 ms AFTER the message), **8 already gone** (2.07 to 9.09 s BEFORE it) and **1 undecidable** (`traefik`, 0.074 s). The controls are what make it a finding rather than a hunch: `uptime-kuma`, `navidrome` and `searxng` each wrote their own completion line — `Graceful shutdown successful!`, `Navidrome stopped, bye.`, `Granian shutdown completed, see ya!` — seconds before dockerd claimed to have forced them, and netdata's `killed hard on exit` holds the other end. Open because the space is not bounded: no sweep has asked which OTHER supervisors on these hosts log acts they did not perform |
| C50 | A liveness probe whose subject answers without the component the probe claims to prove | 64 probes (25 healthchecks + 36 monitors + 3 `wait_healthy`) | **2 instances, both on the resolver's back half.** Kuma monitor 8 queries a name whose answer comes from cache: measured 91 of 94 queries in two hours never reached upstream (`forward IS NULL`), against a control showing the denominator artefact this register already documents. Up to ~65 min of green during a real outage. The boot gate is `dig +norecurse @127.0.0.1`, which cannot see `dnsproxy` — a container with no healthcheck at all. Cheapest close: give `dnsproxy` one. Not swept 64/64 |
| C51 | A procedure whose written order differs from the order the machine imposes | 80 sequences (78 runbook sections + 2 instruction-bearing operator scripts) | **79/80 swept, 4 confirmed instances, ALL FOUR FIXED on 2026-08-30** — see the settled section. Still OPEN on two counts: one sequence unswept, and one SUSPECTED instance not established (`container-config-changes.md` step 4 says a capability sweep must precede step 1, which already drops capabilities; proving the cost would mean dropping one on a live container, which the pass would not do) |
| C52 | A safety argument whose premise is a defect that has just been corrected | Unbounded as stated | **1 instance.** `filesystem-checks.yml:176-183` reasoned that the ext4 boot triggers were harmless, and `fake-hwclock` made that premise false the same evening — the kernel logged `checktime reached` for the first time since 1 August. The general shape is worse than the instance: every fix invalidates the safety arguments that rested on the broken behaviour, and nothing enumerates them |
| C54 | A startup list that is neither derived from the machine nor asserted against it | 4 startup lists | **1 SUSPECTED instance, measured with no discrepancy today (29/29).** Only one of the four lists is derived and asserted. Recorded rather than dropped because "no discrepancy today" is exactly what C27 said before it reopened |

## Settled by the run of 2026-08-30 (evening) — three of the four OPEN, and C27

| ID | Property | Outcome |
|-----|----------------------------------------------|--------------------------------------------|
| C41 | A dead-man's fuse that the restart of its own watchdog re-arms from zero | **GATED, 15/15.** The assertion is genuinely DERIVED — it selects `where m.active = 1 and m.type = 'push'`, compares each silence against that monitor's own `m.interval`, fires only on the INCONSISTENCY (silent past its window while the last beat still says UP, so a late backup cannot mute it for days), and starves loudly (`only $n active push monitor(s) with a beat — the query stopped matching`). Verified live at 358/358, and on history: 54 silences past their window with a last beat UP, against 16 with a last beat DOWN where it correctly says nothing |
| C40 | A container that begins an ordered shutdown and is killed before finishing it | **ENUMERATED 29/29, 8 instances**, and the sweep is worth more than the count. **This row previously asserted that the evidence "is never in its own log, only in the next startup's" — that was WRONG**, and it is why the 02:45 sweep found 4. The daemon logs it directly, and the previous instrument (crash-recovery markers in container logs) can only see databases. #288 is verified good: the four DBs drained in 7.6-9.1 s of a 30 s grace and are absent from the 17:29 list. The remaining cause is configurational — 25 containers still sit at Docker's default 10 s |
| C42 | A time-ordering mechanism that ranks by a timestamp the machine wrote before its clock was correct | **ENUMERATED 6/6, 1 confirmed instance**, the journal one, fixed and verified (skew 32 days → 35 s). One residual and one belonging to `backup`. Broke a neighbour on the way out — see C17 below |
| C27 | A deployed artefact differing from the repo | **ENUMERATED 129/129, 0 instances** (108 homelab, 21 offsite), by sha256 and by static-line containment in both directions, and on BOTH layers the reopening of 08-29 distinguished: 0 units awaiting `daemon-reload`, 15/15 container configs re-read at the 17:29 restart, 8/8 host services, 5/5 offsite. Twenty commits in a day and no drift |

## Minted by the run of 2026-08-30 (evening) — 11

Six arrived already enumerated, because the agent that minted them also swept
them. Five are in the OPEN table above.

| ID | Property | Swept | State |
|-----|--------------------------------------------------|-----------------|------------|
| C44 | A verification whose cadence cannot observe the event it guards | 13/13 timers, **12 instances** | ENUMERATED |
| C45 | A reporting path that cannot report its own failure | 10/10 push sites, **8 instances** | ENUMERATED |
| C47 | A PID 1 that cannot act on the signal it is sent | 29/29, **2 instances** | ENUMERATED |
| C48 | A real dependency that nothing declares | 29 services + 18 configs, **1 instance** | ENUMERATED |
| C49 | A hardening applied to an artefact its producer regenerates | 28/28, **1 new instance** (3 prior: #189, #299, the UFW sysctl) | ENUMERATED |
| C53 | A handler whose effect is expected earlier in the play than it occurs | 34 handlers, 1 flush point, **2 instances** | ENUMERATED |

**C44 is the one to act on, and it is not the one with the most instances.**
`homelab-posture.timer` has no boot hook: the spec was written at 17:23:28, the
last scheduled run was 11:09:01, and the next is the following day at 11:06.
Swept, **none of the 13 `homelab-*` timers carries `OnBootSec`**; the 12
calendar timers are `Persistent=yes`, which catches up a MISSED run but does not
fire on a reboot whose day was already served. `homelab-stack-heal` is
monotonic, so its absence is correct — 12 of 13.

C53 sharpens it rather than duplicating it: the deploy role's LAST task is
"Re-assert the container posture", and Ansible runs its 14 handlers at the end
of the PLAY, so the posture check grades the stack **before** the restarts the
deploy just queued. The repo holds exactly one `meta: flush_handlers`, in
`security`. Together the two mean: **the only two occasions on which the posture
could have covered a day's changes both fell at the wrong moment — one before
the handlers, one before the reboot.** The state was in fact good; nothing in
the system established that.

## Reopened by the run of 2026-08-30 (evening) — C03 (fourth time) and C29

| ID | What reopened it |
|-----|--------------------------------------------------------------|
| C03 | **Its fourth reopening, and the fourth is ours.** `homelab-netdata-kuma.sh` pushed with no `--fail`, so Kuma's 404 "Monitor not found or not active" exited 0 and its own `log "ERROR: push failed"` was unreachable — an instrument answering "did the transfer complete" where the comment claimed "did the beat land". Fixed. Then the ASSERTION written to close C45 committed the same error: `journalctl \| grep -c 'kuma-push-failed:'` answers "does the journal contain this string", not "did a push fail", and it counted 7 losses on a host that had lost none — all seven were sudo's log of the audit's own verification commands. **A class that reopens four times does not need a fifth sweep, it needs a gate**, and it has none |
| C29 | `traefik-log-redactor`'s healthcheck is `pgrep -f "tail -F …"`, which matches the command line of the shell running `pgrep` — proven in the container, a pattern naming a nonexistent path returns a vacuous pass. The liveness half can never fail. **Calibrated down against the agent that found it:** PID 1 is the `tail \| awk` pipeline, so either death exits the container and the restart policy plus the container-down alarm already cover it. A real class instance with a one-line fix, not an exposure |

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

## GATED — 13 here, plus C07 recorded above

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
| C41 | A dead-man's fuse re-armed from zero by the restart of its own watchdog | `kuma-no-push-monitor-silent-past-its-own-window`, derived from Kuma's own monitor table and each monitor's `interval`, with a starvation guard; discriminates on 54 historical silences against 16 (2026-08-30) |

### Broken gates found on 2026-08-30 — these are red tests, not audit results

- **C17** (a filesystem never checked). `fake-hwclock` made the premise of
  `filesystem-checks.yml:176-183` false the same evening: the kernel logged
  `checktime reached` for the first time since 1 August, and the offsite retains
  proof that `e2fsck` rewrote (`FIXED.`) the backup disk's superblock from a
  wrong clock. The gate asserts `passno` and `ext4 clean`; it has never asserted
  `Last checked`.
- **C26** (a credential reaching a command line, a child process, a scheduled
  job or a trace). Recorded GATED on the strength of one assertion covering the
  *trace* axis. The *argv* axis has **no live assertion at all** — `grep -niE
  "argv|cmdline|hidepid"` over the deployed spec returns nothing — and carried a
  live instance: `homelab-netdata-kuma.sh` passed the push URL, token included,
  as a curl argv on a `/proc` without `hidepid`. #177 converted eleven scripts to
  the stdin form and #188 the twelfth; this role was the thirteenth and nothing
  would have found it. Fixed 2026-08-30. **The class is GATED on one of its four
  axes and the table said GATED — the same disguise that cost C02 and C13.**
- **C06** (a `start_period` whose real startup cost has never been measured). 14
  declared against a header that reads `THIRTEEN`; the redactor's 30 s was never
  measured, and `/run/traefik/access.log` appears 99 s after its container starts
  while its healthcheck requires the file.

## ENUMERATED — 25 here; the rest (C01, C03, C06, C09, C13, C27, C39, C43) are recorded in their own sections above

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
| C40 | A container killed before finishing an ordered shutdown | 29/29, 8 instances, on the daemon's own log rather than on crash markers | 08-30 |
| C42 | A mechanism ranking by a timestamp written before the clock was right | 6/6, 1 instance | 08-30 |
| C44 | A verification whose cadence cannot observe the event it guards | 13/13 timers, 12 instances | 08-30 |
| C45 | A reporting path that cannot report its own failure | 10/10 push sites, 8 instances | 08-30 |
| C47 | A PID 1 that cannot act on the signal it is sent | 29/29, 2 instances (`SigCgt` masks, not documentation) | 08-30 |
| C48 | A real dependency that nothing declares | 29 services + 18 configs, 1 instance | 08-30 |
| C49 | A hardening applied to an artefact its producer regenerates | 28/28, 1 new instance | 08-30 |
| C53 | A handler whose effect is expected earlier in the play than it occurs | 34 handlers, 1 flush point, 2 instances | 08-30 |

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
