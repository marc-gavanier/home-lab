# The class register

The audit's unit of progress — how the work is organised, assigned and counted
within a run. **It is no longer what says the work is over**: since 2026-09-21
that is the detection ratio, and the termination criterion below explains why
the class count could not do the job.

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

## The stopping rule — REPLACED TWICE on 2026-09-21, and this is the one that holds

> **The audit stops being run on demand and becomes PERIODIC when two
> consecutive runs, each using a different search key, find nothing that would
> have cost DATA, AVAILABILITY or a SECRET.**

Note what it does not say. It does not say the audit ends — a living estate
that deploys, upgrades and grows will keep producing defects, and the data
below says so plainly. It says the audit stops being the thing you reach for
when you want to know whether something is wrong, and becomes a scheduled
sweep. **The question changed from "is it finished?" to "can I stop asking?"**

### The three costs, defined so the judgement is not a matter of taste

Every live defect is scored against these, in the run's report, one line each:

- **DATA** — loss or corruption of something not reconstructible from another
  live copy. A media library a rescan rebuilds is not data loss; a snapshot
  chain that cannot be restored is.
- **AVAILABILITY** — a service unreachable to the operator or the household, or
  a recovery path that would not work on the day it is needed. Noise that
  erodes trust in a monitor is NOT availability, however annoying.
- **SECRET** — a credential readable by something that should not read it, or
  one that left the estate.

Everything else is below the floor and does not block: documentary findings,
blind spots in the audit's own instruments, guards that cannot trip where no
consequence has been observed, cosmetic and structural items the operator has
declined. They are still found, still reported, still fixed. They just do not
decide when the cadence changes.

**The scoring is per finding and it is written down**, the way the detection
ratio is. A run that reports "nothing serious" without scoring its findings one
by one has not been scored.

### The unfalsifiability guard, unchanged and still mandatory

A run qualifies only when every report says what was checked to establish its
conclusion, the checks were made against running systems, and the previously
reported defects were verified gone rather than assumed gone. "Nothing above
the floor" without that evidence is not a qualifying run; it is a run that was
not performed.

### A discipline note, recorded the day the rule was written

**The run that invented this rule did not claim to have passed it.** Of the
twelfth run's six live defects, five are plainly below the floor and one is
arguable — `vault-mount` looped 15 times unseen on 2026-09-20, and the same
unit's failure mode took Remote Control down for hours on 2026-07-31, so
"silent restart loop on the vault mount" has an availability history. It
recovered by itself this time. **Scoring your own run as the first of the two
is exactly the self-serving arithmetic this register exists to prevent**, so
the count starts at the next run.

### Why the two previous rules were retired — the arithmetic, so neither returns

**Rule 1, in force 2026-08-15 to 2026-09-21**: *no OPEN class remains, and two
consecutive runs, each using a different search key, mint zero new classes.*

- **Zero-mint runs: 4 of 31, never two consecutive** (`exclusivity`,
  `granularity`, `commensurability`, `substitution`). The OPEN column reached
  zero once, on 2026-09-20, and refilled at the next run.
- The mint rate decayed and then stopped: 4.5 per run over the first ten keys,
  1.7 over the next eleven, 1.5 over the last ten, whose sequence reads
  1, 1, 2, 2, 3, 3, 0, 1, 1, 1 — a plateau.
- Expected wait for two consecutive zeros at that rate: **25 to 70 further
  runs**, from the Poisson mean and from the observed frequency respectively.
  A lottery, not a criterion. And it measured the REGISTER, an artefact this
  skill writes itself, rather than the estate.

**Rule 2, in force for about an hour on 2026-09-21**: *two consecutive runs
find no live defect that a deployed instrument was not already reporting.*
Proposed by the session, agreed by the operator, then **withdrawn by the
operator on the correct ground that it was strictly harder than the rule it
replaced**, and the session had not noticed:

- A class discovered for the first time is by construction watched by nothing,
  so any run that finds something new scores below 1. **Rule 2 contains rule 1
  and adds a requirement.**
- Occurrences in 31 runs: **0**, against rule 1's 4. Retired before it was ever
  used.
- It survives as an INDICATOR, not a gate — see below. It is worth measuring
  and it is not worth waiting for.

**What the data says about both, and it is the real reason neither works.**
Live defects per run over the nine runs where the register lists them
separately, in order: **6, 9, 7, 7, 0, 3, 3, 6, 6**. The zero is `independence`,
where the operator declined everything. Nine runs, nine different keys, between
three and nine live defects each, **and the line does not descend**. The estate
is not running out of defects, because each new key looks along an axis the
previous ones had no word for. Any rule of the form "a run finds nothing" waits
on an event this data says is improbable.

**What IS converging, and neither retired rule could see it.** The count is
flat; the COST collapsed. The founding defect of 2026-08-15 was a dead-man's
switch that had never worked — a safety mechanism in total silent failure. The
worst of 2026-09-12 was worse. The worst of 2026-09-21 was a blind spot in the
audit's own evidence store, and the second worst was a monitor crying wolf.
Nothing that night would have cost data, availability or a secret. **That is
the convergence, and it is why the floor is set on cost rather than on count.**

### The detection ratio — kept as an indicator, not as a gate

For every live defect, name the deployed instrument that would have surfaced it
WITHOUT this audit, and show the output that would have differed: the assertion
that goes red, the beat that carries it, the alarm that fires. Naming a check
that "covers the area" does not count.

It answers a question the stopping rule does not: **is the estate learning to
police itself, or is each run just fixing instances?** The first measurement,
2026-09-21, is **0 of 6**, and it exposed something the class counter had
hidden for thirteen runs: **zero classes reached GATED over the whole weekend**,
while 14 new assertions were deployed and only 4 of those were ever made to
fail on purpose. The weekend ENUMERATED and did not GATE. That is worth knowing
every run, and it is not worth waiting for.

---

---

# The register

Runs of 2026-08-15 through 2026-09-21 (TWELFTH run, key `durability`).
**121 recorded classes: 3 OPEN — and the membership is C121, C34 and C01,
written as a list because every time this line carried a rule for reconstructing
the count instead, the count was wrong. 9 GATED, 7 closed by decision, plus the
DECLINED list; everything else ENUMERATED.** The ENUMERATED figure is no longer
carried here as a number — it was wrong by two for an unknown length of time and
nobody could check it, because no membership was ever written. Count the rows.

**THE TWELFTH RUN OF 2026-09-21 USED `durability` — does the state a mechanism
relies on outlive what is asked of it? — and it MINTED ONE.** The counter went
4 OPEN in, 3 OPEN out: **C119 and C120 both left, C121 arrived**; the class total
moves 120 -> 121. Seven of eight domains minted NOTHING and three argued the key
independently: its form (a), a question needing more history than the store
retains, is already C39, and its "written depth is the capacity" form is already
C68. What was NOT owned is the mirror — a token that persists past the event that
should have ended it — and that is C121. **The run's structural output is not a
finding but a PREDICATE**: `system` derived `(Burst-1) x RestartSec >= Interval`,
which decides read-only whether a systemd unit can ever reach `failed`, and
thereby settles the 16 units the eleventh run had to leave UNDETERMINED because
their failure cycle could not be obtained without provoking it.

**THE ELEVENTH RUN OF 2026-09-20 USED `tolerance` — how far from the rupture does
the guard actually trip? — and it MINTED ONE.** The counter went 3 OPEN in, 4 OPEN
out; the class total moves 119 -> 120. **The termination clock RESETS**: the tenth
run's zero was the first of the two consecutive zero-mint runs the criterion needs,
and this run's mint breaks the pair at one. That is the honest outcome of spending
a dimension the register had no vocabulary for — all 119 classes asked whether a
mechanism was CONFIGURED, ORDERED, TIMED or COMPARABLE, and not one asked whether
the MARGIN between where it fires and where the guarded thing breaks was right.
**Five of eight domains proposed the same property independently**, which is the
convergence signal this skill treats as evidence. Six live defects shipped and were
verified against the running systems the same night; a seventh was corrected in
words only and its mechanism is an open design decision. **Four of this file's own
statements were contradicting the machine — seventh consecutive run — and one of
them reached an agent brief through the main session before an agent caught it.**

**THE TENTH RUN OF 2026-09-20 USED `substitution` — when the declared component
is absent, what takes its place, and who can tell? — and it MINTED NOTHING.**
The counter went 3 OPEN in, 3 OPEN out: C12 left as ENUMERATED, C01 REOPENED.
The class total does not move. **This is the FIRST of the two consecutive
zero-mint runs the termination criterion needs**, and the zero was not
manufactured — the run's five best findings were handed to two existing classes
rather than minted, and doing so cost a class that this file recorded as closed
on 123/123. Four corrections shipped and were verified against the running
systems the same evening. **Six of this file's own statements were contradicting
each other again — sixth consecutive run — and they are corrected below.**

**THE NINTH RUN OF 2026-09-20 USED `interference` — what does this mechanism do
TO what it observes? — and the counter went 0 -> 1 with ONE mint.** The clock
RESETS. The OPEN column had been empty for one run. C119 arrives OPEN rather
than ENUMERATED **because its sweep was bounded by two mechanisms (pgrep sites,
then one log detector) while its property is not** — the ninth payment of that
trap, declared rather than discovered later. Three live defects shipped and
verified the same day; the sharpest was inside a GATED class and is therefore a
BROKEN GATE, not an audit result. See that run's section.

**THE REGISTER HAD NO OPEN CLASS FOR THE FIRST TIME SINCE 2026-08-15** (eighth
run, superseded by the line above). C44 and
C113 were both swept to a count this run and both had their remedies DECLINED by
the operator. **That is not the termination criterion and must not be read as
it**: the criterion needs no OPEN class *and* two consecutive runs minting zero
new classes. This run minted THREE. **The clock RESETS.**

**A decline is not an absence.** `independence` found three properties the
register had no word for; the operator declined to act on all three. The classes
are recorded as DECLINED, not omitted, because omitting them would show a
zero-mint run — the exact number this file exists to stop anyone from
manufacturing, and the seventh run wrote that warning down before this run
needed it.

**The SEVENTH run of 2026-09-19 used `asymmetry` — does this mechanism work in
BOTH directions? — and the counter went 1 -> 2 while the class total went
112 -> 115.** C44 stays OPEN but its month-long blocker is GONE: the 27 rows
this file had been citing by number without ever writing down are transcribed
below. C113, C114 and C115 were minted. **The termination clock RESETS.**

**The key was taken off the proposed list rather than invented, and the register
had predicted where it would pay: C112 had just measured an instance of its
property without having a word for it.** The prediction was right. Six of eight
domains returned an explicit "no mint", and the three that came back were
reached from three unrelated directions, two of them by two agents with no
contact.

**GATED is 9 and its MEMBERS are C07, C11, C14, C15, C18, C19, C41, C81 and
C03-T.** That list is the count; there is no second counting rule, and the
table's heading "8 here, plus C07" means only that C07's row is recorded above
the table rather than inside it.

**The sentence that stood here from 2026-09-19 to 2026-09-20 was itself wrong,
and it was written to FIX this very defect** — it named C04, C06, C07, C08
"and the four below them", which double-counts C07, includes two classes closed
by decision (C04, C08) and one that is ENUMERATED (C06), and omits all nine real
members. A correction that reproduces the disease it treats is worth recording:
**write the membership, never a rule for reconstructing it.** The residual that
kept the two counts disagreeing is C12, whose row sits in the GATED table saying
"candidate for re-promotion" while the ENUMERATED section calls it "no live
assertion" — which its own row calls FALSE. C12 is ENUMERATED and is not one of
the nine. **C07 is NO LONGER RED — widened and deployed green 2026-09-20
(seventh run); its assertion keys on the plugin, not the context.** C21 left
this table 2026-09-19 (fifth
run). C03-T's NAMED defect is REPAIRED and its SCHEDULED-run residual RETIRED —
read its row before quoting it as red.

**C109 and C110 were ACCEPTED by the operator on 2026-09-19 (sixth run) and are
ENUMERATED.** They had been PROPOSED by the fifth run. **C111 and C112 were
minted by the sixth run.** All four now carry a table row; C108, C109 and C110
had none at all until this run, which is why `grep '^| C10[89] |'` returned zero
against a positive control of ≥1 for all 107 others.

**The fourth run of 2026-09-19 used `staleness` — since when has this value not
changed, and who would have noticed? — and the counter went 2 -> 1 while the
class total went 107 -> 108.** C107 CLOSED by two complementary instrument
bounds that converge on lynis; C108 was minted and arrives ENUMERATED with a gate
that went red on a live defect before it was written down. **The termination
clock RESETS** — the pair of consecutive zero-mint runs has still never been
achieved. Seven of eight domains returned an explicit "no mint".

**The key's yield was in the INSTRUMENTS and in this register, not in the
estate**, which is the same lesson `commensurability` taught. The estate measured
clean nearly everywhere — 113/113 links, 65/65 runbook paths, 136 Ansible keys in
both directions with no dead knob, 34/34 rendered artefacts, 19 databases with no
un-dumped one, 21/21 certificates in a four-way equality, an external perimeter
unchanged in 35 days. Against that, **the firewall's deny-by-default had no
assertion on either host**, no channel could report an Immich CVE, and this file
contradicted itself in four places.

**C107 was MINTED on the operator's arbitration, 2026-09-19.** It arrives OPEN
because its space is not bounded, and the run records the bound worth trying: key
on the INSTRUMENT rather than on the assertion. **The termination clock therefore
RESETS** — `commensurability` was the first of the two consecutive zero-mint runs
the criterion needs, and `aggregation` is not the second.

**The third run of 2026-09-19 used `aggregation` — what does the collapse to one
hide? — and the counter went 1 -> 1 with SEVEN of eight domains returning an
explicit "no mint".** C100 CLOSED on an observed scheduled run; C44 lost a third
sub-space (20/20 host-hardening) and stays OPEN on a space `system` showed is not
mechanically derivable. Five live defects shipped as #368, each made to fail on
purpose before it was written. **The run's headline is that the audit's own
baseline manufactured a false clean for the second consecutive run**, and that two
agent conclusions died to the same trap: a `grep` run under `sudo` writes the
string it is hunting into the log it is reading. **A15's resolution is WITHDRAWN on
that basis — do not record C74's last mechanism as closed.**

**The second run of 2026-09-19 used `commensurability` — same unit, same base,
same frame? — and the counter went 5 -> 1 with ZERO mints.** C20, C103, C105 and
C01 all CLOSED with stated derivations; C44 stays OPEN on a third cadence slice
that was named rather than quietly omitted. The class total does not move. **First
zero-mint run since `exclusivity`, so this is the first of the two the termination
criterion needs.** Three of the eight agents' headline claims did not survive the
main session's re-measurement, and two of the main session's own instruments were
wrong — both recorded in that run's section.

**The run of 2026-09-19 used `collision` — which two distinct states produce the
same reading? — and the counter went 0 -> 5 while the class total went 102 ->
106.** C103, C104, C105 and C106 were minted; C01, C20 and C44 REOPENED, none of
them as a broken gate although three agents reported them that way. **The
termination clock RESETS.** The honest note is the one the register keeps making
about itself: declining the four mints and the three reopenings would have shown
`0 OPEN` and a zero-mint run, which is the number this file exists to stop anyone
from manufacturing.

**The run of 2026-09-18 used `quiescence` — what does this do when nothing
happens? — and the counter went 1 -> 0 while the class total went 100 -> 102.**
C88 CLOSED as ENUMERATED by three slices that between them dissolved its named
blind spot: the git-history walk it was waiting for is not necessary, because
`{files under /etc carrying the Ansible marker} ⊆ {the /etc destinations of the
repo's tasks}` answers the same question and was verified file by file rather
than by counting. C101 and C102 were minted. **The termination clock therefore
RESETS**: no OPEN class remains, but this run minted two, so the two consecutive
zero-mint runs the criterion requires start again from zero.

**The run's headline is that the audit's own baseline was a false clean, and it
took seventeen minutes to become one.** The posture monitor was green when the
eight briefs were written; it had pushed DOWN on each of its three previous
SCHEDULED runs, and a manual run at 21:18 had cleared the last red at 21:18:41.
The key found the shape it was written for: **a check whose verdict depends on
the hour it is observed, and which is always observed at a quiet one.**

**The run of 2026-09-13 (night-second) used `reversibility` — does this have an
inverse, and does the inverse restore the prior state? — and the counter went
2 -> 1.** C37 CLOSED by two property-bounded derivations (65/65 and 31/31, zero
defective). C88 advanced from a bound of 4 to 105 stores swept and stayed OPEN on
a stated blind spot. C100 was minted ENUMERATED. **Zero broken gates, the first
run in some time with none** — C03-T's repair is live and its repaired branch has
actually executed.

**The run's headline is that the remediation of the PREVIOUS night was shipped on
a false premise and deleted a working detector.** Two agents reached it from
opposite ends with no contact. See that run's section.

**The run of 2026-09-13 (late evening) used `repetition` — what if this runs
again? — and the counter went 0 -> 4.** C98 and C99 were minted ENUMERATED; C37
and C88 REOPENED, both because their sweeps were bounded by a MECHANISM while
their properties are not. That is the eighth payment of the same trap.

**C03-T IS RED and it was red on the day it shipped.** The gate promoted to GATED
on 2026-09-13 afternoon, after being made to fail on purpose in six runs, cannot
detect a mute reporter: Kuma fabricates a DOWN beat every interval for any push
monitor that is not UP, and C03-T's clauses count `heartbeat` rows with no
`status` filter. C41 filters `h.status = 1` and is immune. **The six-run proof
ran against a synthetic database, which by construction held only the rows the
test itself wrote** — a gate proven against a fixture is proven against the
fixture's model of the world. See that run's section.

(Before this run, OPEN = **C95 only**. **C92 was CLOSED BY THE OPERATOR'S
ARBITRATION on 2026-09-13 (evening)** — as a review rule, the way C03-R was,
because the run proved its space is not mechanically derivable; see that run's
section. **C01 was CLOSED BY THE
OPERATOR'S ARBITRATION on 2026-09-13**, the way C57 and C66 were: 72/87 verified,
11/11 true on the last batch, and the remaining 15 accepted as outside this
audit's instrument set. **C03 was SPLIT on the operator's arbitration the same
day: C03-T is GATED — its assertion was made to fail on purpose in five
directions plus a discriminating twin — and C03-R, the half that is not
mechanically decidable, is closed by decision as a review rule.** C94 CLOSED by
eight per-domain slices. **C90 CLOSED the evening it was minted,
by six independent derivations of the relation the register asked for.** GATED = C07, C11, C14,
C15, C18, C19, C21, C41 and C81 — **C17 left the table on 2026-09-05 evening,
C10 and C16 on 2026-09-11**; closed by decision = C04, C08, C57, C66 and C77's
non-secret half; everything else ENUMERATED.)

**The run of 2026-09-13 used `concurrency` — what happens when two run at
once? — and the counter did not move: 3 OPEN in, 3 OPEN out.** C26's argv axis
CLOSED by two independent sweeps from opposite sides (340/340 on the repo side,
74 container argv fields + 157 host sites + 8 189 processes on the runtime
side), and C87 CLOSED at 1997/1997 at a stated depth plus an unbounded-depth
pass over 112 895 entries that agreed instance for instance. Against that, C03
REOPENED for the fifth time and C90 was minted OPEN rather than ENUMERATED,
because its two sweeps returned different cardinals (13 and 14) and a third
domain found an instance neither had counted — which is the definition of an
unbounded space.

**The key paid, and the register had predicted where.** `classes.md` has said
since 2026-08-30 that *"a class that reopens four times does not need a fifth
sweep, it needs a gate, and it has none"* — about C03, about this exact script.
The fifth reopening arrived tonight and it is the mirror image of the fourth:
the fourth was an instrument answering "did the transfer complete" where the
comment claimed "did the beat land"; the fifth answers "did my client return
inside its deadline" where the claim is still "did the beat land". The beat was
recorded by Kuma at 01:25:29 and the script wrote `this report reached nobody`
at 01:25:39 — exactly its own `TIMEOUT=10` later, carrying a byte-identical
payload.

**Six of eight domains independently found an instance of C90's property**, from
six unrelated directions, which this register's own rule names as the strongest
evidence available. That is why it is minted rather than folded into C74.

**The run of 2026-09-12 used `residue` — what survived a removal, and does it
still act? — and the counter did not move: 3 OPEN in, 3 OPEN out.** C10 and C86
both CLOSED by exhaustive sweep (29/29 + 32/32, and 363/363 over five domains).
Against that, C26 REOPENED and C87 was minted OPEN rather than ENUMERATED
because the sweep that produced it was bounded by directories while its property
is not. The run found the worst live defect since this skill's founding one: a
Nextcloud app-password written in cleartext into `/var/log/auth.log` 27 times
over 24 days, readable without sudo, behind a pre-commit gate that passes
because its derivation keys on where a secret is *written* rather than where it
is *declared*. **That is the seventh payment of the same trap**, and the shape
is now unmistakable — the derivation is sound, and it keys on the wrong axis.

**The run of 2026-09-11 used `succession` — against WHICH VERSION of its
counterpart — and it closed both OPEN classes and opened three.** The counter
is 2 -> 3 and the termination clock RESETS. Both closures are real and both
were closed by derivation rather than by sampling: C74 at 48/48 by arbiter and
71/71 on its systemd/kernel slice, C82 at 25/25 deployed executables plus 39/39
play-order validations. The three that opened are the honest cost: one genuine
mint, and **C01 and C10 reopened for the same reason for the sixth time** — an
instance of the class's own property sitting outside the space its sweep had
been bounded to. Declining all three would have shown `0 OPEN` and a
zero-mint run, which is the number this register exists to stop anyone from
manufacturing.

**The evening run of 2026-09-05 used `interruption` and the termination clock
RESETS for the second time in one day.** The counter moved 0 -> 2 and the class
total 83 -> 85. That is the honest outcome and, again, it was not the convenient
one: the run's own headline is that the two mints it kept are real and that two
classes recorded ENUMERATED were enumerated over spaces smaller than their own
properties. Declining all four moves would have shown `0 OPEN` and a second
consecutive zero-mint run, which is precisely the number this register exists to
stop anyone from manufacturing.

**The midday run of 2026-09-05 closed C83 by unified sweep — 976/976 across
eight slices — and minted NOTHING. The counter is 1 -> 0, and for the first
time in this register's life a run satisfies BOTH halves of the termination
criterion's first pass: no OPEN class remains, and the key was new.** That is
one of the two consecutive zero-mint runs the criterion requires. The next run
must invent another key and also come back empty; if it does, this is finished.
The key spent here was `exclusivity` and it cannot be reused.

**The run of 2026-09-05 closed C82 (308/308) and minted C83. The counter is
therefore 1 -> 0 -> 1, and the termination clock RESETS.** That is the honest
outcome and it was not the convenient one: declining the mint would have shown
`0 OPEN` and satisfied the first half of the criterion. Five agents converged on
C83's property from five unrelated directions, which this register's own rule
names as the strongest evidence available. Minting it costs the run its clean
sheet; not minting it would have been measuring to the target.

**The OPEN column reached zero on 2026-09-03, for the first time in the
register's life.** The three classes minted that evening were all closed the
same night: C79 by finishing its sweep (13/13), C80 by sweeping its space
(26/26), and C77's secret slice by enumeration with its non-secret slice closed
by the operator's arbitration. That satisfies the FIRST half of the termination
criterion and only the first. The second half — two consecutive runs, each with
a different search key, minting zero new classes — has never been tested, and
`representation` minted four. **The next run's job is therefore not to find
anything. It is to invent a key and come back empty.** If it does, and the one
after it does too, this is finished.

**Both classes that were OPEN going into 2026-09-03 closed by enumeration, and
the counter still went 2 -> 3.** That is the register working, not failing:
C03 — the class this skill's founding defect belongs to, open for nineteen days
across seven runs — closed 107/107, and C75 closed 18/18 with zero live
instances. The three now open are all new, all minted the same evening, and each
arrived with the part of its space that was swept already counted.

**Two corrections to the header this one replaces.** Its GATED list omitted C18
while the GATED table carried it — the count of 13 was right and the enumeration
was short by one, so the true figure was 14. And C12 and C20 were both listed
GATED without being derived; they are downgraded below, which is what takes 14
to 12.

**The counter moved 5 -> 2, and for the first time the reason is arbitration
rather than sweeping.** C46 and C73 closed by enumeration. C57 and C66 were put
to the operator on 2026-09-02 and closed by decision: both had reached the point
where the only remaining move was one the operator declines to make, and
recording that is more honest than leaving them open to be re-sampled forever.

**The counter moved the right way for the first time in four runs: 9 OPEN to 5.**
It started at 9, not the 8 the previous header claimed — see the C03 correction
below. Five closed by enumeration (C05, C56, C58, C60, C62), seven minted after
arbitration, six of which arrived already ENUMERATED because the agent that
minted them also swept them.

**But the termination clock does not merely reset — it has run out of road.**
`scale` was the last dimension this file had named and never applied. It minted
seven, against five for `time`, eleven for `order` and twelve for `identity`.
The mint rate is decaying, which is the encouraging half. The discouraging half
is that **there is no named unused dimension left**, so the next run's key has to
be invented rather than taken off this list. Until one is, a run cannot honestly
claim the second half of the termination criterion.

## What the run of 2026-08-31 cost and paid

Its key was **scale** — what breaks at ten times the data. The register warned
that this key would be harder than its predecessors because `time`, `order` and
`identity` were all observable on the machine that night and most of scale is
not. The warning was right and the mitigation worked: agents were confined to
the forms of scale that already leave a trace, and the result is that **most of
what came back is a closed question with a number on it** rather than a lead.
`/mnt/data` reaches 85 % in 8.8 years; the offsite in 6.3 with 525 days of
warning; SD wear is 11.5 card-writes a year; the forced fsck costs 3 min 27 s
and does not grow with the data because a fixed inode table dominates it. None
of those needed action, and saying so with numbers is the point.

**The run's headline is that the gate written the previous night to close C45 —
the founding defect of this skill — is already failing, and its own comment
predicted it in writing.** Three agents and the main session converged on it from
four directions.

## OPEN — 3 (after the TWELFTH run of 2026-09-21, key `durability`)

| ID | Property | What bounds the space, and what stopped the sweep |
|---|---|---|
| C121 | **A token whose validity ends with an event, kept on a medium that outlives the event, with nothing to expire it** — the exact mirror of C39, which covers evidence that expires BEFORE the event it records | **MINTED 2026-09-21 (twelfth run).** Space: {state the estate writes} x {the event that ends its meaning}, restricted to the pairs where the store outlives the event — lock files, PID files, armed/disarmed flags, `creates:` witnesses, caches read as authoritative. Swept: `backup` **7/7** state carriers of the backup plane, 4 correct, 3 defective and all three the same file. **The mechanism, measured by the main session and stronger than the instance:** `/var/lock` is NOT the symlink to `/run/lock` on either host — `stat` gives dev=45826 (the root filesystem) against `/run/lock`'s dev=28 (tmpfs), while `/usr/lib/tmpfiles.d/legacy.conf:13` declares `L /var/lock - - - - ../run/lock`. The `L` directive does not replace an existing directory and `base-files` ships one, so every token written there is persistent on an image that reads as volatile. Both resticprofile profile locks lived there; **moved to `/run/lock` 2026-09-21** so a reboot expires them, which is the remedy the deliberate refusal of `force-inactive-lock` leaves available. **What stops closure: the backup plane is a DOMAIN bound, not the property.** The route: enumerate by the EVENT (boot, container recreation, service restart, deploy) and ask which stores survive it |
| C34 | **A documentary artefact contradicting the sibling it cites** | **AXIS C IS BOUNDED, and this run read 40 more of it.** Axes A (44/44), B (1/1) and D (23/23) closed earlier. Axis C by the property: **467 occurrences, 333 distinct source->referent relations, 79 referents, 84 citing documents**; swept 110/110 links, 69/69 glosses, 269/357 lexically-supported claims, 88 hand-triaged. This run opened **40 individually** (24 in the `durability` slice, 16 outside): 4 contradicted, 2 partial, 34 clean. **What stops it is no longer reading, it is BOOKKEEPING: the register recorded a residual of "~48 claims never opened one by one" and never wrote down WHICH ones.** A residual without an identity cannot be handed to the next run — the overlap with this run's 40 is unknown, so the remainder is somewhere between 8 and 48. **The run that next measures this residual must publish the LIST, not the count** |
| C01 | **A documentary statement whose content contradicts the deployed artefact** | **TWO MORE STRATA CLOSED, the class is not.** File set: the repo's tracked files that CARRY COMMENTS — 198 files, 13 757 comment lines, 11 666 prose statements. Previously swept: `ansible/` 176/176, `docker/` 10/10, `ops/` 156/156, `usb-tamper`/`killswitch` 121/121 clean, instruction files 123/123. **Added 2026-09-21: the RENDERED stratum 53/53** — 5 552 comment lines reach the hosts, 65 exist only in the rendered artefact, 53 of those are headers (all true: no `force: false`, no `creates:` on a `template:` task) and 12 are substantive, all verified true against the running hosts; offsite 10/10 with zero rendered-only lines outside headers. **And the `durability` slice of `docs/`+`knowledge/` 24/24** — 93 candidate lines, 24 real depth claims confronted with the store that should hold them: 3 contradicted, 1 partial, 20 clean. What remains is the rest of the prose in the documentary stratum |

**C119 LEFT this table, ENUMERATED on its seventh and last plane.** `ansible-deploy`
bounded the deploy plane the way the eleventh run asked — by **(spec, artefact)
pairs, not by tasks** — and swept **31/31**: 30 of the 31 detectors the deploy
renders can be turned green by rewriting the detector instead of the guarded
thing, and exactly 1 cannot (the 6 netdata alarms, because `netdata_alarm_groups`
is a list distinct from `health.d/*.conf`, so the adapter shouts "is not loaded"
rather than passing). The previous 47/47 task classification is not re-derived.
Six planes stood before it: `network` 39/39, `services` 262/262, `system` 19/19,
`observability` 37/37 Kuma + 66/66 netdata, main session 5/5.

**C120 LEFT this table, ENUMERATED on the route the register itself named**, with
the residual declared rather than swept. The route was "enumerate the guards whose
RUPTURE point is already on record — a measured worst case, a declared ceiling, a
retained range". Six domains did exactly that this run: `system` **33/33** systemd
restart limiters on both hosts plus **18/18** non-systemd guards, `security`
**21/21**, `network` **35/35**, `observability` **82/82** (56 netdata thresholds
against the min/max retained over 55 days, 15 dead Kuma windows, 6 `homelab-gate`
graces, 5 isolated guards), `services` **129/129**, `backup` **28/28** from the
eleventh run. **The residual, and it is not a gap but an instrument boundary:**
the guards whose rupture point is NOT on record — `services` counted 70 of them
(41 tmpfs never filled, 25 containers never `unhealthy` in 14 days, 4 budgets
never exceeded) and `observability` 22 active-monitor timeouts. Qualifying those
requires provoking the failure, which rules 5 and 6 forbid. **It does NOT reach
GATED**: no assertion has been made to fail on purpose.

**A WARNING that belongs with C120's closure, and it is this run's sharpest
instrument finding.** The closure rests on METRIC ranges (55 days of netdata
dbengine) and on declared ceilings. It must NOT be read as resting on netdata's
alarm TRANSITION history, which retains `5d` by default and was never overridden:
`system` showed the swap guard's own rupture — 94.55 % measured against an 85 %
threshold, 2026-08-31 to 09-02 — leaves no retained transition, with a positive
control. The main session re-measured the practical bound at 1 000 entries
spanning 0.37 day through `api/v1/alarm_log`. **Any verdict of the form "this
guard has never tripped" drawn from that store is a false negative beyond a few
days.** Raised to `60d` / 5 000 entries on 2026-09-21.

---

## SUPERSEDED — OPEN table of the ELEVENTH run of 2026-09-20, key `tolerance`

### It read: OPEN — 4 (after the ELEVENTH run of 2026-09-20, key `tolerance`)

| ID | Property | What bounds the space, and what stopped the sweep |
|---|---|---|
| C120 | **A guard whose trip point sits at the wrong distance from the rupture it guards** — either OUTSIDE the range the guarded quantity can occupy, so the guard is decorative while appearing armed, or SHORTER than the work the mechanism explicitly permits itself | **MINTED 2026-09-20 (eleventh run), and it arrives OPEN because every bound swept is a DOMAIN bound and none of them is the property.** Space: {deployed guard} x {quantity it guards}, restricted to the pairs where the trip point AND the rupture point are both measurable. Six domains swept six incomparable slices: `system` 13 guards (1 defective), `security` 14 thresholds (1 defective), `backup` **28/28** numeric guards, `network` **22/22** duration budgets in the network plane (1 defective), `ansible-deploy` **117 numeric budgets rendered on the hosts**, of which 31 measured, and the main session **18/18 host units carrying a restart limiter — 2 PROVEN defective, 16 UNDETERMINED**. That last figure is the honest shape of what blocks closure: a guard is only shown sound by exercising the rupture, and 16 of those 18 units have `NRestarts=0`, so their failure cycle cannot be obtained read-only. **The route to bounding it: enumerate the guards whose rupture point is already on record** — a measured worst case, a declared ceiling, a retained range — and treat the rest as a separate, provoked-measurement problem |
| C119 | **A detector whose own act is a member of the set it examines** — so it can read its own trace as data, and its verdict is in part a measurement of itself | **SIX PLANES OF SEVEN NOW SWEPT, and the seventh returned a demonstrated negative that still does not close it.** `network` 39/39 and `services` 262/262 stood before this run. Added 2026-09-20: `system` **19/19** host units (16 `homelab-*` + 3 `offsite-*`, 8 in-scope pairs, 2 defective); `observability` **37/37** Kuma monitors (22 active probes are structurally immune — the probe IS the measurement; 15 push monitors give 6 pairs, 1 defective and it is C29, DECLINED) and **66/66 netdata alarm names over 802 instances** (55 pairs, 0 new defective); and the main session's own plane, **5/5**, 2 defective. `ansible-deploy` classified the deploy plane **47/47** with **0 defective** — 16 `assert` + 7 `fail` + 5 real `failed_when` + 4 `until` + 2 `wait_for_connection` + 2 `validate:` + 11 "NOT applied" reports — and then declared the bound rather than claim the class: **the deploy's real self-reference is not a task, it is that the deploy RENDERS the detectors of every other plane from the repo state it applies.** Bounding that needs (spec, artefact) pairs, not tasks |
| C34 | **A documentary artefact contradicting the sibling it cites** | **AXIS C IS BOUNDED AT LAST, and the 460 it was measured against was derivable from no written rule.** Axes A (44/44), B (1/1) and D (23/23) stood before this run. Axis C re-derived BY THE PROPERTY — the claim-referent pair, not the grep line: **467 occurrences resolved, 333 distinct source->referent relations, 79 referents, 84 citing documents**, plus 12 named tokens that leave the space (execution paths, one URL). Split 110 link-form / 357 prose. Swept: **110/110** links (0 dead), **69/69** glosses against the referent's title (0 divergence), **269/357** claims whose referent carries the vocabulary, and 88 low-support claims hand-triaged with ~40 read individually. **What stops it: ~48 claims were never opened one by one, and lexical support proves the subject is PRESENT, not that the claim is UNCONTRADICTED.** The unit is right now; the remaining work is reading |
| C01 | **A documentary statement whose content contradicts the deployed artefact** | **BOUNDED FOR THE FIRST TIME, and it reopened one level higher in the same run.** The file set is the repo's tracked files that CARRY COMMENTS: **198 files, 13 757 comment lines, 11 666 prose statements** — `ansible/` 176/11 510/9 726, `docker/` 9/1 933/1 673, `ops/` 7/188/156, root 5/103/90, `.github/` 1/23/21. That is ~25x the prose volume of the documentary stratum closed on 81 files. Swept this run: `ansible/` **176/176** (24 confirmed, 8 suspected, 1 reported and REFUTED), `docker/` **10/10** (10 contradicted + 3 stale figures), `ops/` **156/156**, and `usb-tamper`/`killswitch` **121/121 clean** — an evidenced negative. **What reopened it a THIRD time: a comment in a RENDERED file has never been in any space.** `/etc/goss/posture.yaml` and the systemd units are written by templates whose comments reach the host, and 2 instances are visible only there. **Twelfth payment of the wrong-axis shape** (C10, C18, C26, C37, C87, C88, C119) |

**C120's six live instances, all fixed and verified 2026-09-21**, are listed in the
eleventh run's section below. The one that names the class best: `vault-mount`
restarted 15 times on 2026-09-20 and still read `active`/`success`, because its
failure cycle is 15 s against a **default** `StartLimitIntervalSec` of 10 s — the
burst counter resets between attempts, so the unit can never reach `failed`. The
guard was not misconfigured; the DEFAULT sat at the wrong distance.
---

## SUPERSEDED — OPEN table of the TENTH run of 2026-09-20, key `substitution`

### It read: OPEN — 3 (after the TENTH run of 2026-09-20, key `substitution`)

| ID | Property | What bounds the space, and what stopped the sweep |
|---|---|---|
| C119 | **A detector whose own act is a member of the set it examines** — so it can read its own trace as data, and its verdict is in part a measurement of itself | **TWO PLANES SWEPT of seven, both bounded by the SURFACE rather than by a mechanism, which is what the ninth run's minting row asked for.** `network` 39/39 — N derivable by command from five sources (the 3 goss specs' keys, the healthchecks of the 6 network containers, Kuma's monitor table, the 3 report scripts, netdata's `health.d` at 0 network alarms), 6 in-scope pairs, 1 defective and it is C29, DECLINED. `services` 262/262 — 28 healthchecks + 229 posture assertions + 2 stack scripts + 1 log watcher + 2 self-tests, each classified by the surface it reads and then by whether its own execution writes there; the write census is exactly 1 of 262. 3 instances, 1 defective (C29 again), 1 benign (`netdata-plugins-present` sees its own `ps`), 1 fixed 2026-09-20. **What stops the closure is the plane boundary**: both enumeration rules are plane-specific, so the five remaining planes — Kuma monitors, netdata alarms, host units, the deploy itself, and this skill's own method — need the same pass. The audit's own method is still inside this class |
| C34 | **A documentary artefact contradicting the sibling it cites** | **ONE AXIS OF FOUR CLOSED, and it is the axis the register named as the route.** Axis A, code citing a document, **44/44**: 63 raw `grep` hits over `*.yml`/`*.j2`, 19 are runtime paths or globs, 44 are real citations, each claim read against its referent. Axis B (`ops/` + `docker/` scripts) 1/1 clean; axis D (`.claude/agents/` + `CLAUDE.md`) 23/23. **Axis C, document citing document, is what blocks: N=460, swept 33.** The sweep was filtered by an assertion-verb regex — a MECHANISM, not the property — and the agent declared the bound rather than manufacture a closure. The real numerator is 346 prose citations, 114 of the 460 being pure link form. **The unit has to be the claim–referent pair, not the grep line**, and that is the next run's job |
| C01 | **A documentary statement whose content contradicts the deployed artefact** | **REOPENED 2026-09-20 (tenth run).** Was CLOSED 2026-09-19 on 123/123 referents, 472 machine-checkable claim occurrences across **81 files** — and every one of those files is a documentation file. `docs/`, `knowledge/`, then `.claude/agents/*.md` and `CLAUDE.md` when it reopened for a sixth kind of referent. **A comment in `ansible/**/*.yml`, in `ops/*.sh` or in `compose.yaml` is a documentary statement and has never been in the space.** Four instances found this run by four agents with no contact: `secrets.yml`'s header arguing 0400 twenty lines above tasks declaring 0444 and a paragraph calling 0400 the thing that must never be tried again; `deploy/tasks/main.yml` advertising `--tags secrets` as a rotation route that reaches 19 of 31 renders; three of the four worked examples in `ops/kuma-dump.sh`; and `logging.yml` claiming `/var/log/journal` must not exist when systemd creates it as the mount point before the unlock. **Eleventh payment of the wrong-axis shape** (C10, C18, C26, C37, C87, C88, C119). **Route to bounding it: the file set is the repo's tracked files that carry comments, not the ones that end in `.md`** |

**C12 LEFT this table, ENUMERATED by two complementary bounds, neither
containing the other** — the shape that closed C107 and C113. `security` derived
the values from the live host and swept **76/76** (value, consumer) pairs over 39
values, 31 values × 64 carriers = 1 984 tests with a planted positive control
found and a negative control not; `ansible-deploy` parsed the declarations and
swept **52/52** render sites over the 39 `no_log: true` options. The two cardinals
disagree on purpose and reconcile: 39 are declared, some have no persisted
carrier. Zero live divergence on the day. The class leaves with a live
STRUCTURAL defect recorded as an instance, not as an open space — see the tenth
run's section.

**ZERO MINTS, and the zero was not obtained by declining anything.** The five
false rationales this run found split into two families and both already had an
owner: those citing a sibling are C34, those asserting a fact about the system
are C01. Recognising that costs more than minting would have — it reopens a class
this file recorded as closed on 123/123. **This is the FIRST of the two
consecutive zero-mint runs the termination criterion needs.** The second must use
a different key again, and the honest warning stands: a run that mints nothing
because nobody looked in a new direction is not the same thing.

---

## SUPERSEDED — OPEN table of the NINTH run of 2026-09-20, key `interference`

### It read: OPEN — 1 (after the NINTH run of 2026-09-20, key `interference`)

| ID | Property | What bounds the space, and what stopped the sweep |
|---|---|---|
| C119 | **A detector whose own act is a member of the set it examines** — so it can read its own trace as data, and its verdict is in part a measurement of itself | Space: deployed detectors × the surface each examines, restricted to the pairs where the detector's own execution can appear on that surface. **NOT BOUNDED.** Swept 5, 2 defective, by two unrelated mechanisms: `services` enumerated pattern-matching probes searching a shared medium for a literal from their own argv (2 of 28 healthchecks + 2 of 229 posture assertions, 4/4, **1 defective**), and `network` found the access-log credential detector whose only in-scope instances are written by the estate's own 15 push reporters (**1 defective, FIXED 2026-09-20**). Neither bound contains the other and neither is the property. **The route to bounding it is stated rather than attempted: enumerate the deployed detectors, then for each one the surface it reads, then ask whether its own execution reaches that surface.** The audit's own method is inside this class — `sudo grep` writing the string it hunts into `auth.log` is its purest instance and has been paid three times |
| C12 | **A rotated secret a consumer never receives** — the value changes, and one of its carriers is never re-rendered, so two live values coexist under one declaration | **REOPENED 2026-09-20 (ninth run).** Was ENUMERATED with a live gate: `posture.yaml:225 secret-mounts-carry-the-current-value` hashes the host file against `/proc/<pid>/root/run/secrets/<name>` for a pair list GENERATED from `compose.services[*].secrets`, 14/14. **Its space is docker secret MOUNTS; the property is a secret VALUE.** A consumer that reads the same vault variable through a systemd `EnvironmentFile` is outside the derivation by construction — and one was: the Cloudflare token rotated on 2026-09-12 reached Traefik and never re-rendered `/mnt/data/secrets/ddns.env`, which kept its value of 2026-07-20. **Two distinct live tokens under one variable for EIGHT DAYS, with nothing able to notice**, found only because today's rotation made the divergence visible. Both consumers aligned 2026-09-20 14:16. Ninth payment of the wrong-axis shape (C10, C18, C26, C87, C88). **Route to bounding it: enumerate the CONSUMERS of each secret value — docker mounts, systemd EnvironmentFiles, rendered `.env` files, inline script constants — not the mounts** |

**The OPEN column was empty for exactly one run.** Recording C119 as ENUMERATED
over the 5 sites actually swept would have kept it empty and shown a second
consecutive zero-mint run, which is the number this file exists to stop anyone
from manufacturing. Its two sweeps were bounded by MECHANISMS while its property
is not — the ninth payment of the trap that reopened C10, C18, C26, C37, C87 and
C88, and the first time it has been declared in the minting row itself.

---

## SUPERSEDED — OPEN table of the EIGHTH run of 2026-09-20, key `independence`

**Empty for the first time since this register was opened.** C44 and C113 both
left it this run — swept to a count, remedies arbitrated and DECLINED. Read the
run section below before treating the emptiness as progress: three classes were
minted into the DECLINED list on the same day, so the perimeter grew while the
open column emptied.

### C44 — LEFT THE OPEN COLUMN, ENUMERATED, remedy DECLINED

Swept 27/27 subsystems. **The coverage figure this register carried was wrong by
a factor of four: it is 1 of 16 TIER A, not 4.** Measured by `system` and
re-measured by the main session with controls:

    sudo sshd -T -f /dev/null            -> port 22 / permitrootlogin without-password
    sudo sshd -T -o PermitRootLogin=yes  -> permitrootlogin yes  (daemon enforces no)
    /etc/ssh/sshd_config                 -> Port <vaulted> / PermitRootLogin no
    running daemon                       -> pid 1167142, LISTEN :<vaulted>
    /etc/ssh/sshd_config.d/              -> EMPTY

`sshd -T` parses whatever file it is handed; it never interrogates the running
daemon. The same holds for `postconf -h` and for `ufw status`, which renders
from `/etc/ufw/user.rules` (`backend_iptables.py:41,684-686,288-291`; the kernel
is consulted only for the word `active`). **Only `sysctl` reads the executing
system.** The sshd and postfix cases are C111 instances — a tautological oracle,
file compared to a parse of the same file — not a new class.

**Operator arbitration, 2026-09-20: DECLINED.** A simple remedy exists and was
put — assert `mtime(file) < start(daemon)`, six lines, one rule for all sixteen.
It was declined on the correct ground: it would fire every time a file is edited
without restarting the service, which is frequent and legitimate, and a check
that cries for noise gets ignored. **What was accepted instead is one sentence
of documentation**: the four comparators verify that the DEPLOY applied what the
repo declares, and they do not detect an external writer. Do not re-propose the
mtime rule, or any successor to it, without a live drift to point at. Zero drift
in five file/daemon pairs as of 2026-09-20.

Both standing reserves survive and are unchanged: the 16 is not provably the
register's old 16, and rows 15 (`hostname`) / 16 (`swap`) remain contestable
(reject one -> 15 and 26; reject both -> 14 and 25; coverage stays 1).

### C113 — LEFT THE OPEN COLUMN, ENUMERATED by two complementary bounds, remedies DECLINED

Neither bound contains the other, which is why both are recorded — the same
shape that closed C107.

| Bound | Space | Result |
|---|---|---|
| `network` | deployed network-plane mechanisms whose function is to refuse | **16/16** — 3 covered in the deny direction, 4 admit-only, **9 with no assertion at all**. Router NAT is the 17th and is C112 |
| `security` | deployed continuously-evaluated assertions whose subject is a deny-control, over all four carriers (posture 231, units 15, backup-dumps 46, Kuma 37 = 329) | **197/197 deny-subject** — 186 go red if the control is removed, **11 stay green**. Kuma contributes 0 by construction: all 37 monitors are admit-direction |

**The sharpest number is inside the 186: only 2 of 197 assertions verify that a
control REFUSES** (`nextcloud-redis-refuses-an-unauthenticated-caller`,
`traefik-access-log-carries-no-credential`). The other 184 read a declaration or
an inspect field.

The 11 that stay green: 3 Traefik (`vpn-only`), 6 Pi-hole (provisioning only,
nothing asserts `dns.blocking.active`), 2 fail2ban (unit-running and jail-list
equality). Three further deny-controls carry no assertion at all and sit outside
the 197 by construction: the two `DOCKER-USER` DROP rules that stop Pi-hole
(published on `0.0.0.0:53`) being an open resolver, `killswitch.service`, and the
USB tamper armed-state flag. All three measured live and healthy on 2026-09-20.

Verified independently by the main session, with a working control:

    netdata -> socket-proxy:2375/_ping,/version,/containers/json -> 200 200 200
    netdata -> socket-proxy:2375/networks,/secrets,/exec/x/json  -> 403 403 403
    env vars set to 0 (deny): 21        [the agent reported 16 — CORRECTED]
    "socket-proxy" in /etc/goss/posture.yaml: 47 occurrences
    assertions reading any allowlist knob: 0

**Operator arbitration, 2026-09-20: DECLINED** — "je ne trouve pas ça très
pertinent". The remedies not shipped by the seventh run (`vpn-only`,
`dns.blocking.active`) are now formally declined along with the rest. **Do not
re-propose deny-direction assertions.** The sweep stands as the record of what
is and is not covered; a future run may cite the 2-of-197 figure as context, but
not as a proposal.

---

## SUPERSEDED — OPEN table of the SEVENTH run of 2026-09-19, key `asymmetry`

**C44 and C113.** C113 is new and its row is in the class table. C44 is still
open, but **the reason it could never close is gone**: the 27 rows this file had
been citing by number — `#13`, `#15`, `#16` — without ever writing them down are
transcribed below, derived from zero against the repository and the host.

### THE MEMBERSHIP, at last — C44's 27 subsystems

**Predicate**: the subsystem for which this repository owns or modifies a HOST
configuration file, and whose effective state is readable. Out of scope by that
predicate, and stated so nobody re-derives it: configuration internal to a
container (`/etc/pihole`, `/etc/traefik/dynamic`, `/etc/netdata`) and **the goss
specs themselves** — the instrument does not compare itself to itself.

**TIER A — a readout that resolves every declared input (16). Covered: 4.**

| # | Subsystem | Where the estate declares intent | Effective-state readout | Resolves? | Covered |
|---|---|---|---|---|---|
| 1 | sshd | `/etc/ssh/sshd_config` | `sshd -T` | yes, 21 directives | **YES** |
| 2 | sysctl | `/etc/sysctl.d/99-homelab.conf` | `sysctl -n` -> `/proc/sys` | yes, 30 keys, double-floored | **YES** |
| 3 | postfix | `/etc/postfix/main.cf` | `postconf -h` | yes, 22 directives | **YES** |
| 4 | ufw | inventory rules + `/etc/default/ufw` + `after.rules` | `ufw status` | yes | **YES** |
| 5 | apt / unattended-upgrades | 3 files under `/etc/apt/apt.conf.d/` | `apt-config dump` | yes, 5/5 | no |
| 6 | fail2ban | `jail.local`, 2 `filter.d/` | `fail2ban-client get …` / `get actions` | yes, 13 keys — demotion TESTED, SURVIVED | no |
| 7 | apparmor | `/etc/apparmor.d/{homelab-netdata,bwrap}` | `aa-status` | yes, 2/2 | no |
| 8 | wireguard | `/etc/wireguard/wg0.conf` (symlink onto LUKS) | `wg showconf wg0` | yes | no |
| 9 | mounts | `/etc/fstab` + `mnt-data.mount` | `findmnt` | yes, 5/5 | no |
| 10 | Pi firmware (#13) | `/boot/firmware/{config.txt,cmdline.txt}` | `/proc/device-tree/soc/*/status` + `/proc/cmdline` (**not** `vcgencmd get_config`) | yes | no |
| 11 | modprobe / CIS blacklist | `/etc/modprobe.d/cis-blacklist.conf` | `modprobe --showconfig` | yes — 20 declared, 147 resolved, all 20 present | no |
| 12 | sudoers | `/etc/sudoers.d/cis-logfile` | `cvtsudoers -f sudoers /etc/sudoers` | yes — resolves the `#includedir`; `sudo -V` does NOT (negative control) | no |
| 13 | logrotate | 3 files under `/etc/logrotate.d/` | `logrotate -d /etc/logrotate.conf` | yes — reads all 32 includes | no |
| 14 | timesyncd / clock | `/etc/systemd/timesyncd.conf` — `NTP=`, `PollIntervalMaxSec=1024` | `timedatectl show-timesync` | yes, 2/2 | no |
| 15 | hostname | `/etc/hostname` | `hostnamectl --static` | yes, 1/1 | no |
| 16 | swap | `mnt-data-swapfile.swap` + `swap_size_mb` | `swapon --show` | yes, 2/2 | no |

**TIER B — a readout exists but does not resolve every declared key (2).**
17 `docker` (`daemon.json`, `docker info` resolves 3 of 6; `shutdown-timeout`
and `log-opts.{max-size,max-file}` exposed by no daemon readout, re-measured 0
and 0 with `LoggingDriver` as the positive control). 18 `resolved`
(`resolvectl status` does not read `DNSStubListener`, its only declared key).

**TIER C — resolves, but normalisation makes a literal comparison false (1).**
19 the `DOCKER-USER` chain: `iptables-save` normalises `-s` before `-p` and
inserts `-m udp`, giving 8 false positives of 8.

**No readout at all (4).** 20 `pam` — and this is the `pam-auth-update` reserve,
an external writer that rewrites the `/etc` file the estate owns. 21
`needrestart`. 22 `smartd`. 23 `cloud-init`.

**Degraded — the reader reads the file tree, not the daemon (3).** 24 `journald`,
25 `tmpfiles`, 26 `udev`: `systemd-analyze cat-config` and friends re-read the
tree rather than interrogating the running daemon.

**Excluded on normalisation (1).** 27 systemd units: `TimeoutStartSec=600` reads
back as `10min`, and asserting that no unexpected drop-in exists needs a
seven-entry exemption list, which is a list dressed as a derivation.

**16 + 2 + 1 + 4 + 3 + 1 = 27.** No category was adjusted to make it land.

**Two candidates excluded with a reason, so nobody re-opens them**: `zram`
(offsite only, the file is absent on homelab) and `crypttab` (an intent of
ABSENCE — there are not two sides to compare).

**Correction to this file, and it matters.** The clock admission was rejected by
the fifth run against the WRONG PATH: `/etc/systemd/timesyncd.conf.d/` is empty
and does not exist, but `security/tasks/hardening.yml:124,155` writes `NTP=` and
`PollIntervalMaxSec=` into `/etc/systemd/timesyncd.conf` itself, and
`timedatectl show-timesync` resolves both. **The clock IS TIER A**, and it is one
of the six blank rows this run filled, not an addition to a pre-existing 16.

### TWO RESERVES the transcribing agent wrote down rather than leave to be found

**Its 16 is not provably the register's 16.** The old figure counted six members
this file never named; this table is derived from scratch. Both carry the same
number without anyone being able to show they have the same members. If the lost
agent report ever resurfaces naming a subsystem absent here, the cardinal rises.
**That is C44's real residual and it is now written beside the number.**

**Its two thinnest rows are named so they can be contested.** Row 15 `hostname`
(one declared key, a trivial readout) and row 16 `swap` (arguably part of row
27, since the intent is carried by a `.swap` unit; held separate because
`swapon --show` reads effective state without going through systemd's
normalisation). **Reject one: TIER A 15, total 26. Reject both: 14 and 25.**
Coverage stays 4 in every case. Nothing else was moved to compensate.

### WHY C44 STILL DOES NOT CLOSE

The question the register wanted arbitrated — *is every subsystem with a
resolve-everything readout covered* — answers **NO**: 4 of 16, and 12 carry no
comparator. Both reserves recorded with the class still hold: the route compares
`/etc` to effective state, so a writer that rewrites the `/etc` file the estate
owns moves both sides together (the `pam-auth-update` shape); and the route's own
cadence is daily, which is C44 applied to its own output. **Do not re-derive**
TIMER 13/13, DEPLOY-TAG 26/26, HOST-HARDENING 20/20.

**A useful qualification of the "4/16": 3 of the 4 deployed comparators re-read a
FILE rather than the executing process** — only `sysctl` reads `/proc/sys`. No
live drift today (5 file/daemon pairs tested, the file older in all 5).

### TWO LIVE C44 INSTANCES FOUND THIS RUN, both fixed or recorded

1. **The offsite undervoltage detector sampled a <=2 s pulse once a day.** Its
   instrument read `in0_lcrit_alarm`, on the written premise that "the firmware
   latches". False: `raspberrypi-hwmon.c` passes `value = 0xffff` to
   `RPI_FIRMWARE_GET_THROTTLED` under its own comment *"Request firmware to clear
   sticky bits"*, on every poll, polling every `2 * HZ`, and the show function
   returns the last poll only. p(detection) = 2/86400 = **0.002 %** on the host
   holding the only offsite copy of the backups, against ~1 on homelab (chart
   `update_every=1`, alarm `max -1m`, `delay down 15m`). **The main session
   corrected the agent's cadence by a factor of 7** — it had attributed the check
   to `homelab-offsite-check.service` (weekly), which in fact runs
   `resticprofile … offsite check`; the spec is run by `offsite-health.timer`,
   **daily at 08:00**, on the offsite host. **FIXED**: the check now greps the
   kernel journal, with both driver strings read out of the shipped
   `6.8.0-1064-raspi` module binary rather than trusted from upstream source, and
   deliberately without `-k` (it implies `-b`, which would hide an event from
   before the last reboot — and a power problem is a plausible cause of that
   reboot). Made to fail on purpose in four directions. Zero events on either
   host in 30 days.
2. **`docker-shutdown-budget` compares an effective operand to a declared one**,
   because no daemon readout exposes `shutdown-timeout` (re-measured 0/0).
   Conformant today (file mtime < dockerd start). Recorded, not fixed.

---

## SUPERSEDED — OPEN table of the SIXTH run of 2026-09-19, key `oracle`

**C44 only. TIER A is 16, coverage 4/16 = 25 %, and the SIXTH run found why this
class cannot close — it is not the space, it is this file.**

`docker` was demoted TIER A -> TIER B on the #15 predicate: `daemon.json`
declares 6 values, `docker info` resolves 3, and `shutdown-timeout` plus
`log-opts.{max-size,max-file}` are exposed by no daemon readout (measured 0/0/0
with `LoggingDriver`=1 as the positive control; log-opts is per-container
creation-time state, not daemon state). `fail2ban` looked like a second
demotion and SURVIVED: 5 of its 13 keys have no `get <key>` verb, but
`get <jail> action <act> port` and `get actions` resolve them. A clock admission
was tested and REJECTED — `timedatectl show-timesync` resolves everything, but
`/etc/systemd/timesyncd.conf.d/` is empty, so there is no declared intent.

### THE REASON C44 HAS NEVER CLOSED — the register records the cardinal WITHOUT the membership

**This file refers to admissions by NUMBER — `#13`, `#15`, `#16` — into a 27-row
list that does not exist anywhere in it.** Verified: `grep -nE '#1[3-6]\b'`
returns five lines, all of them narration of the fifth run. Of a TIER A of 16,
only **11 are nameable** from this register: the 4 covered (sshd, sysctl,
postfix, ufw), the 6 read on 2026-09-19 (apt, fail2ban, docker, apparmor,
wireguard, mounts) and #13 firmware. The other five exist only as indices in an
agent report that was never carried over.

**That is why the cardinal has moved 19 -> 17 -> 16 across three consecutive
runs: each run re-derives it from scratch against a list it cannot read.** The
space was proven derivable in the third run. What is missing is not a
derivation, it is a transcription. **No run can state N/N until the 27 rows are
written down here**, and any run that claims to have swept C44 without them has
swept something it could not enumerate.

**THE MEMBERSHIP IS THE NEXT RUN'S FIRST TASK, and it is bookkeeping, not
research.** Until it exists, do not close C44 and do not trust a new cardinal.

*(Superseded: after the FIFTH run — TIER A 17, coverage 4/17 = 24 %.)*

**C44 only, and its cardinal MOVED: TIER A is 17, not 19, coverage 4/17 = 24 %.**
Two admissions failed on execution — `resolved` (#15, its resolver does not read
the only key declared) and DOCKER-USER (#16, `iptables-save` normalisation gives
8 false positives of 8). 19/19 TIER A lines now READ, drift 0 of 19; 13 carry no
continuous assertion. **The question still answers NO — do not close by
arbitration.** C109 and C110 were PROPOSED this run and await the operator.

*(Superseded: after the FOURTH run — C44 only, C107 CLOSED, C108 MINTED and arriving ENUMERATED with a gate.)*

| ID | Property | What bounds the space, and what stopped the sweep |
|---|---|---|
| C44 | A verification whose cadence cannot observe the event it guards | **TIMER 13/13, DEPLOY-TAG 26/26, HOST-HARDENING 20/20 closed — do not re-derive.** The general external-writer space is **no longer non-derivable**: `system` derived the comparator route's cardinal on 2026-09-19 — **19 subsystems have a readout that resolves all their inputs, of 27 for which the estate declares an intent, and 4 are covered (21 %)**. So the question the register wanted arbitrated — "is every subsystem with a resolve-everything readout covered" — answers **NO**, and the class must NOT be closed by arbitration. Two reserves recorded with it: the route compares `/etc` to effective state, so a writer that rewrites the `/etc` file the estate owns moves both sides together and stays green (the `pam-auth-update` shape); and the route's own cadence is daily, which is C44 applied to its own output |

### WHAT CHANGED FOR C44, AND WHY IT IS STILL OPEN

The register said this space was "a per-predicate judgement over 337 assertions"
and therefore not mechanically derivable. That was true of the *enumeration*
route and false of the *comparator* route. Bounding by "subsystems whose
effective state is readable by a command resolving all its inputs" yields a
stateable cardinal, and it is **19**.

**Six of the fifteen not yet covered were read on 2026-09-19 with commands
already installed, all conformant**: apt (`apt-config dump`, 5/5), fail2ban
(3 jails), docker (`docker info`, 3 of 5 keys exposed), apparmor (2/2),
wireguard, mounts (5/5). **Four have no resolver at all** — `pam`,
`needrestart`, `smartd`, cloud-init. `journald`/`tmpfiles`/`udev` are a degraded
tier: the resolver reads the tree, not the daemon. systemd is excluded on
normalisation, not oversight.

**Correction to this file's own text, and it matters.** The row that said "Live:
406 assertions, 0 failures" immediately after listing the four comparators reads
as if the 406 were theirs. **406 is goss's plan count for the WHOLE spec** — the
main session made goss count itself (`Count: 406, Failed: 0`, over 227 resource
entries) and the figure is derived, not invented. The four comparators are **4
checks** making ~82 internal comparisons. The sentence made the coverage look
five times wider than it is; `system`'s "406 is false, it is 82" is the right
correction aimed at the wrong target.

## SUPERSEDED — OPEN table of the third run of 2026-09-19, key `aggregation`

**C44 only, and it lost another sub-space without closing.** `security` swept the
host-hardening half **20/20** — security-role in-place edits and mode assertions,
crossed with `dpkg -S` and maintainer-script generators — and found **0 of 20
carrying a continuous assertion**, with drift measured at 0/20 today. The writer
fired live and unattended during the audit window: `pam-auth-update` regenerated
`/etc/pam.d/common-auth` on 2026-08-29, `/var/lib/pam/auth` records the generated
form **with `nullok`** and the live file has none — the hardening survived on
pam-auth-update's three-way merge, not on anything this estate does, and nothing
observed either outcome.

`system` kept the class OPEN and stated why, which is the right call: two clean
derivations (14/14 artefacts named by an assertion that have a non-Ansible writer;
6/6 deferred-effect pairs) plus the demonstration that **the path-spelling
derivation is the wrong bound** — `/usr/lib/sysctl.d` appears in ZERO assertions
yet governs asserted values. The right Factor A is artefacts *reached* through the
16 external tools the checks invoke, and bounding that is a per-predicate judgement
over 337 assertions rather than a machine derivation.

| ID | Property | What bounds the space, and what stopped the sweep |
|---|---|---|
| C44 | A verification whose cadence cannot observe the event it guards | **TIMER 13/13, DEPLOY-TAG 26/26, HOST-HARDENING 20/20 — all closed, do not re-derive.** Still OPEN on the general external-writer space: Factor A is not the set of paths an assertion NAMES but the set it REACHES through the tools it invokes, which no agent could derive mechanically. Named, not swept |
| C107 | **An assertion that consumes its own instrument's output at a COARSER GRAIN than the instrument produced it** — the finer signal is collected, rendered as prose, and never gates | **SUPERSEDED — this is the MINTING row of 2026-09-19 (third run) and it is kept for the derivation only. C107 CLOSED as ENUMERATED in the FOURTH run (32/32 executables + 12/12 supervision-plane instruments); read its row in the class table, not this one.** Its text as written then: **NOT BOUNDED, and the bound to try is stated.** `security` measured 181 of 274 goss checks carrying `stdout:`, but most match a single-valued `docker inspect -f`, so bounding by ASSERTION is 337 per-predicate judgements. **Bound by INSTRUMENT instead**: the checks invoke ~16 external tools, and the question "does this tool emit a finer signal than its readers consume" is asked once per tool, not once per assertion. That is a stateable cardinal and nobody has derived it |

### A ROUTE TO CLOSING C44 THAT DOES NOT NEED THE MISSING INSTRUMENT

**The instrument C44 is waiting for is a provenance map from effective state back
to every writer that can set it**, including writers acting at another time through
another mechanism. Syscall tracing does not supply it: it records that the
assertion read `/proc/sys/...` and stops at the proximate read, never crossing the
boot-time boundary where `systemd-sysctl` applied a file a package had rewritten.
That map would have to be written by hand, per subsystem, which is why `system`
called the space non-derivable and was right to.

**But the class may not need it.** `sshd-applies-the-directives-the-managed-file-sets`,
shipped in #368, names no writer and catches them all: it compares DECLARED INTENT
against EFFECTIVE STATE. Any writer — a package, a hand-dropped `.d` file, one
nobody has imagined — appears as a divergence. That converts an enumeration
problem into a set of comparators, and **the cardinal of THAT set is stateable**:
the subsystems whose effective state is readable by a command resolving all its
inputs.

**Four of the five are now deployed.** sshd (`sshd -T`, 21 directives), sysctl
(`/etc/sysctl.d/99-homelab.conf` against the kernel, 30 keys, double-floored),
postfix (`main.cf` against `postconf -h`, 22 directives), ufw (the inventory's
declared rules against `ufw status`). Live: 406 assertions, 0 failures.

**systemd is the one that resists, and its refusal is recorded rather than
deferred.** Comparing unit files to `systemctl show` founders on normalisation —
`TimeoutStartSec=600` reads back as `10min`, so a literal comparison is all false
positives. Asserting that no unexpected drop-in exists needs a seven-entry
exemption list, which is a list dressed as a derivation. **All seven live drop-ins
were checked and all seven ARE declared in this repository**; six carry no
`ansible_managed` marker because they are deployed by `copy: content:`, which is a
separate correction — **the marker is not a provenance instrument.**

**What closing C44 this way would require is the operator's arbitration**, the way
C92 and C03-R were closed as review rules once their spaces proved non-derivable.
The question to put is not "have all writers been enumerated" but "is every
subsystem with a resolve-everything readout covered". Do not close it silently.

## The run of 2026-09-21 (TWELFTH) — the key was `durability`, and it paid in a PREDICATE

The key: **does the state a mechanism relies on outlive what is asked of it?**
Three forms were put in every brief, all required to name two numbers — the depth
DEMANDED and the depth RETAINED: (a) a question needing more history than its
store keeps, (b) a counter reset by an ordinary event but read as cumulative,
(c) volatile state a consumer believes persistent, or its inverse, persistent
state nobody expires.

### The counter: 4 OPEN in, 3 OPEN out, 1 minted, class total 120 -> 121

C119 and C120 both left; C121 arrived. **Seven of eight domains minted zero and
three of them argued the key rather than stretching it**: `project-manager`,
`system` and `network` each independently placed form (a) inside C39 and the
"written depth is the capacity" shape inside C68, and `network` formulated a
candidate ("the evidence store is emptied by the very event being traced") and
then rejected it as already covered. That is the declared-overlap discipline the
`aggregation` run introduced, working as intended.

### The run's real output is a PREDICATE, not a finding

`system` derived `(Burst-1) x RestartSec >= Interval` (or `Interval=0`): when it
holds, a systemd unit can never reach `failed`, because the burst counter resets
between attempts. **It decides the question from two DECLARED numbers, read-only,
and so retires the eleventh run's blocker** — 16 of 18 units had `NRestarts=0`
and their failure cycle was declared unobtainable without provoking it. The
predicate is written in this repo exactly once, at
`ansible/roles/stack-startup/tasks/startup.yml:57-63`, and was applied nowhere
else. Plane closed 33/33 across both hosts.

Three units satisfy it. **One is DECLINED and was correctly excluded by the main
session, not by the agent**: `killswitch`, arbitrated away 2026-09-02. The other
two were fixed 2026-09-21 — `vault-mount` (rupture on record: 15 restarts on
2026-09-20 while reading `active`/`success`, the eleventh run having fixed the
cause and not the guard) and the offsite `rest-server` (rupture not on record,
C15 is the existing net under it). `vault-mount` was given
`StartLimitIntervalSec=600` and `rest-server` `300`, both with
`StartLimitBurst=5` and both in `[Unit]`. **The two numbers differ because an
attempt does**: `rest-server` is `Type=simple` and an attempt costs `RestartSec`
(50 s for five), while `vault-mount` is `Type=notify` inheriting a 90 s start
timeout, so an attempt on the hang path costs 100 s and five need 500 s. The
main session's first patch put both directives in `[Service]`, where systemd
ignores them, and gave both units 300 s — two errors of the same family, both
caught by re-reading and by writing the derivation down rather than by testing.

### Live defects shipped, ranked by what was happening without anyone knowing

1. **netdata's alarm transition history retains 5 days while its metrics retain
   55.** `system` proved it with the swap guard's own rupture (94.55 % against an
   85 % threshold, 2026-08-31→09-02) leaving no retained transition, plus a
   positive control. Main session re-measured the practical bound at 1 000
   entries over 0.37 day. **This bounds the audit's own method**, and C120's
   closure was written to rest on metric ranges rather than on this store.
   Raised to `health log retention = 60d` and 5 000 in-memory entries.
2. **`STARTUP_GRACE=300` against 787 s of measured startup** in the
   netdata->Kuma adapter. Six DOWN beats on 2026-09-20 saying "netdata up 310s
   and its health engine has evaluated no alarm"; monitors 35 and 37 red for
   7 min 33 and 6 min 17 with nothing wrong, and six such non-incidents in
   fifteen days. The agent derived 900 s; **the operator chose 1 200 s.**
   **The 787 s was a COLD start and nobody had said so.** netdata was restarted
   twice during verification, on a warm host with the stack already up, and
   both times the health engine had real verdicts within 297 s — so neither
   restart entered the grace window and neither exercised the change. The fix
   is justified by the boot case it was measured on and stays UNPROVEN until
   the next full boot, which a read-only audit cannot provoke: a reboot costs
   the tunnel, hence the host. **A measurement of a startup cost that does not
   say which start it measured is, in miniature, the same defect as the class
   this run closed.**
3. **`no-container-came-back-recovering` loops over a hand-written list of
   four** — `immich-db miniflux-db nextcloud-db pihole` — which are exactly the
   four containers declaring `stop_grace_period: 90s`, the only budget never
   exceeded. The one container whose EXPLICIT budget did give way is outside the
   loop. Main session's census of the docker journal over 14 days, in UTC: 114
   "using the force", 87 at 10 s, 5 at 5 s, **1 at 1m0s**, none at 90 s.
   **The operator DECLINED the remedy** — see the arbitration below.
4. **A correction of 2026-09-19 reached three of five carriers.** `0fa9e07`
   fixed "Kuma keeps 180 days" in three template comments;
   `docs/07-observability/README.md:74` and `:124` never received it, and `:124`
   justifies the live 45-day deep-check threshold with a 135-day margin. Measured
   2026-09-21: raw beats on the 5-minute monitor survive **45.6 h**
   (`keepDataPeriodDays` is 180 and true only as configuration), and the real
   margin is **18 days** — 63 days of history on a weekly monitor against a
   45-day threshold. Agreed to the hour by `observability` and the main session;
   `project-manager`'s "30 to 71 days" measured monitor AGE and was discarded.
5. **The profile lock outlived the boot because `/var/lock` is not what it looks
   like.** See C121. Moved to `/run/lock`; the runbook's repair section, which
   taught only `restic unlock` — a command that acts on the repository's `locks/`
   directory and not on the profile lock at all — now names the right file.
6. **Two units that could never be reported `failed`.** See the predicate above.

### Documentary corrections shipped — 9, all measured

The two Kuma carriers; `/etc/goss/posture.yaml` saying "90 s" beside its own
`timeout: 300000` (`6951d9b` wrote the prose, `e1dac8f` raised the value the same
day); `compose.yaml` naming the DoH proxy `cloudflared` four times in the block
that serves as the pihole/dnsproxy namespace runbook, when it has been `dnsproxy`
since 2026-07-27 and line 681 of the same block says so; the resticprofile
comment promising 40 days where the guard reads 45 (born wrong in `0512713`,
22 days, 11 runs, inside the stratum declared `ansible/` 176/176);
`restore-from-backup.md:829` asserting "Retention starts 2026-07-11, anything
older is gone" — 18 of 35 local snapshots predate it, oldest 2026-05-14, and the
sentence was used in its own paragraph to justify deleting the Immich v2.7.5
images; `offsite-backup.md:207` citing a journal "complete back to 2026-05-14"
when the offsite journal starts 2026-07-05 and the homelab's 2026-08-30;
`offsite-health.sh` saying "the sixteen assertions" for a spec that no longer
holds sixteen — replaced by no number at all, which is the only form that cannot
rot; and the journald cap rationale, wrong TWICE in two files
(`inventory/group_vars/all.yml` and `roles/base/tasks/logging.yml`) — "about 48
days" against 21.3 days held and ~59 at saturation, and citing
`restic-deep-check-not-stale` as a journal reader when that assertion reads Kuma
and says so in its own spec.

### Rejected, requalified or corrected — 6, and the biggest was the run's headline

- **`ansible-deploy`'s I1, REFUTED by the main session and withdrawn by its
  author along with its mint.** It claimed `--tags storage` run before
  `homelab-unlock` would `dd` 4 GiB onto the SD card. Three independent blocks:
  `storage/tasks/luks.yml:16-22` opens the LUKS volume unconditionally;
  `storage/tasks/mount.yml:59-63` starts `mnt-data.mount` with no `ignore_errors`
  or `failed_when` anywhere in the role, so a failure aborts four imports before
  `swap.yml`; and `deploy/tasks/main.yml` carries `tags: always`, so its assert
  runs under ANY tag filter — the pivot of the finding was simply false. The
  agent then searched for an escape path and reported `--start-at-task` as the
  only one, while refusing to use it to save the finding. **Its mint was
  withdrawn on the right ground: the property was sound and its instance
  cardinal on this repo is 0.**
- **`backup`'s remedy (`force-inactive-lock: true`) contradicts a deliberate
  decision written in this repo**, at `goss-units.yaml.j2:235`: it authorises a
  run to break a lock it did not create and repairs without reporting, which is
  how #331 went unnoticed for eight and a half hours. Detection first. The
  finding's documentary half survives; the remedy does not.
- **`system` re-reported `killswitch`**, DECLINED 2026-09-02 with the instruction
  never to raise it again. Excluded by the main session on the agent's behalf,
  which is exactly the budget this register exists to protect.
- **`project-manager`'s Kuma retention figure** ("30 to 71 days") measured
  monitor age, not retention. Replaced by 45.6 h.
- **`observability` declared `durability` CLEAN with 0 instances in its own
  domain** while `system` found defect #1 there. Not a contradiction but a
  perimeter gap: the first compared alarm windows to METRIC retention, the second
  thought to interrogate the TRANSITION store. **The divergence is the finding**,
  and it is the fourth time this skill has been paid by resolving one rather than
  picking a side.
- **`system` reported "5 tmpfs mounts, not the 41 this register carries" as a
  register correction. It is not one, and the main session resolved it by
  measuring both**: `mount -t tmpfs | wc -l` gives 5 on the host, while the sum
  of `HostConfig.Tmpfs` over the running containers gives 41 — which is C36's
  space and C36's cardinal, unchanged and correct. Two different spaces with the
  same word. **The register was right and would have been corrupted by believing
  the agent**, which is the precise reason agent output is a lead and not a
  finding.
- **`network`'s pihole `start_period` fix (120 s against the 300 s the staged
  startup grants itself)** is real and was correctly self-limited by its own
  author: the one-line remedy recreates pihole and destroys dnsproxy's network
  namespace, and the measured cost of doing nothing is 0 over 16 days. Deferred
  to a pihole deploy that is already planned for another reason.

### The operator's arbitration — one DECLINED, and its reason generalises

**Alarming on transmission's hard kills is DECLINED, 2026-09-21.** The operator's
words: transmission habitually crashes during downloads, alarms on it are wasted
effort, and *"ce qui m'intéresse c'est qu'au final ça se remet"*. So
`no-container-came-back-recovering` was NOT re-derived from
`compose.services[*].stop_grace_period`, because deriving it is precisely what
would add transmission to it. **The derivation defect stays recorded and
unfixed** — it is the class that is wrong, not this instance that is unaddressed,
the same shape as C18's `logs.db` siblings. Do not re-propose an alarm here. A
proposal that demonstrates RECOVERY rather than alarming on the kill is a
different question and has not been put.

### Instrument traps paid — 4, and TWO were the main session's own

1. **`StartLimitIntervalSec` in `[Service]` is silently ignored** — systemd moved
   it to `[Unit]`. The main session wrote it into the wrong section for both
   units and caught it by re-reading the rendered template, not by testing.
2. **The main session attributed #331 to its own `/var/lock` discovery, and was
   wrong.** #331 is about restic REPOSITORY locks, which live inside the repo on
   `/mnt/data` and survive a reboot because that is what a repository does. The
   `/var/lock` finding concerns resticprofile's PROFILE lock, a different object
   that no assertion watches. Caught by reading the detector
   (`restic-repo-has-no-stale-lock` scans `<backup_dir>/restic-repo/locks`)
   before writing the register. **Two lock objects with similar names is the
   whole trap.**
3. **`resticprofile snapshots` cannot be run outside its unit** — the repository
   comes from an `EnvironmentFile`, so a hand run fails with
   `unable to open config file: stat <no value>/config`. The main session could
   not independently re-measure the snapshot census and SAYS SO rather than
   inheriting it silently; two agents measured it independently and agree. It
   also verified that its own failed attempts left no lock behind.
4. **`services` was nearly caught by `docker diff` reporting bind MOUNTS as added
   files** — two `php/conf.d/*.ini` entries under nextcloud look exactly like the
   `zz-disable-jit.ini` that fell into the writable layer on 2026-08-27 and cost
   six hours. `compose.yaml:885` mounts them. Self-caught.

### The register lied about itself in THREE places — eighth consecutive run

1. **The ENUMERATED heading said "69 rows below" and there were 71.** The two
   extra are C119 and C120, which declare themselves OPEN inside their own row
   while sitting in the ENUMERATED section — the same residual shape as the C12
   row left in the GATED table, diagnosed in prose and not removed. Both rows are
   now redirected the way C34's was.
2. **C03-T's lookback ceiling is 26 h, not 8 days** (`observability`, read off the
   deployed spec, which states its own derivation).
3. **The last SCHEDULED posture run reported 433 checks / goss 410, not 435 /
   412** — those are the MANUAL run of 2026-09-21 00:35, which the main session's
   baseline quoted correctly as manual but which would have propagated as the
   scheduled figure. Ninth consecutive run in which the baseline needed a
   correction from an agent.

### Clean, and measured — the negatives that closed questions

`security`: the sshd jail does not read `auth.log` at all (systemd backend,
600 s demanded against 22 days retained); bans persist across a restart
(`dbpurgeage` 1 day > `bantime` 3 600 s, `nextcloud.log` resumed at `pos=4842`);
no `bantime.increment` and zero consumers of the reset counters; **the
container-clock trap is clean and was verified with an instrument** (`fail2ban-regex`
19/19, positive control on the real ban of 2026-09-13); `/run/homelab/tamper-armed`
cannot be cleared by any tmpfiles entry short of a reboot. `network`: DDNS keeps
no local state (the last IP lives at Cloudflare and is re-read every run); FTL
retains 91.89 days against `maxDBdays 91` with **zero** consumers asking for it;
conntrack peaked at 1 762 over 55 days against 262 144; the pihole/dnsproxy
namespace is intact; Traefik answered its own API rather than its labels — 24
routers, 6 middlewares, 0 errors. `observability`: the deepest netdata question
asks 7 200 s of a store retaining 424 188 s (58.9x, 66/66); the #378 window
recalibration holds, the three weekly monitors outside its scope sit at 9.2 /
12.4 / 13.6 %. `system`: all 7 `creates:` witnesses persistent, every ratchet
under `/var/lib`, zero systemd counters read as cumulative, zero ext4 errors,
`RuntimeMaxUse=300M` worth 161 h at the measured boot rate. `services`: worst probe
0.396 s against 5 s, tmpfs peak 3.8 %, the heal timer reads `FailingStreak` and
not `Health.Log` (which is capped at 5 and would have made its 900 s
unreachable). `backup`: `status.json` overwriting correctly handled, dumps retain
zero by construction and the runbook says so, `locks/` empty on both repositories,
`/run/homelab-backup-dumps.tap` correctly volatile.

---

## The run of 2026-09-20 (ELEVENTH) — the key was `tolerance`, and it minted the distance

The twenty-seventh key, and invented rather than taken off a list: there was no
list left. The six-word question: **how far from the rupture does it trip?**

All 119 classes then on file asked whether ONE thing was correct (`configured`),
whether TWO were distinguishable (`collision`), whether they were comparable at
all (`commensurability`), or when they happened (`time`, `order`). **Not one asked
about the DISTANCE between a guard's trip point and the rupture it guards.**

Three admissible shapes went into all eight briefs so agents returned measurements
rather than philosophy: (a) a threshold the guarded quantity CANNOT reach — the
guard is decorative and looks armed; (b) a margin so tight that normal operation
crosses it; (c) a ceiling, timeout, retry count or window SHORTER than the work
the mechanism explicitly permits itself.

The brief also carried the overlap warning, and it held: C07, C08, C14 and C105
already own threshold INSTANCES, and `commensurability` already owns the threshold
calibrated in a DIFFERENT FRAME. `tolerance` is the same frame and the wrong
DISTANCE. No agent tried to mint over any of them.

### The counter: 3 OPEN in, 4 OPEN out, 1 minted, class total 119 -> 120

**The termination clock RESETS at one.** The tenth run's zero was the first of the
pair the criterion needs; this mint breaks it. That is the correct outcome of
spending a new dimension and it is not a regression — see the note in the
termination section.

### C120 — MINTED, and it is the run's real output

**Five of eight domains proposed the same property with no contact**, which is the
convergence this skill treats as evidence rather than coincidence:

- `system` — "a guard whose trip point sits at the wrong distance from the rupture
  it guards", 13 measured, 1 defective
- `security` — "a guard whose threshold lies outside the range the quantity it
  guards can occupy", 14 measured, 1 defective
- `backup` — "a guard whose trip point is closer to the ORDINARY range of the
  guarded quantity than to the rupture it precedes", 28/28
- `network` — "a TOTAL duration budget that the operation's progress does not
  extend", 22/22 in the network plane, 1 defective
- `ansible-deploy` — the same property, space enumerated at **117 numeric budgets
  rendered on the hosts**, 31 measured
- `observability` proposed a sixth variant and **objected to it itself** (2 of its
  3 members were well calibrated). Not adopted.

**The merge dropped every mechanism clause, deliberately.** `security`'s "because
the threshold is in a unit of the carrier rather than of the thing guarded" and
`network`'s "that the operation's progress does not extend" are MECHANISMS. A class
bounded by a mechanism reopens — this file has paid that twelve times — so C120 is
stated as the distance alone, and the mechanisms are recorded as the shapes that
produced its first six instances.

### Live defects, ranked by what was happening without anyone knowing

1. **`vault-mount` restarted 15 times and reported itself healthy.** `NRestarts=15`
   with `ActiveState=active`, `Result=success`. Its failure cycle is 15 s against a
   `StartLimitIntervalUSec` of **10 s — the systemd DEFAULT, which the unit never
   set** — so the burst counter resets between attempts and `failed` is
   unreachable. Verified with a control: **0 of 59 283 retained Kuma beats** mention
   the unit or a restart loop. Root cause was ordering, not the limiter: it mounts
   over HTTPS while the stack is still coming up and recovered by itself at
   15:50:14 once Nextcloud answered. **Fixed** by `After=homelab-stack-startup.service`,
   which binds only when both units are in one transaction, so nothing is delayed
   when `claude-remote-control` pulls the mount later. Verified: `NRestarts=0`.
2. **`homelab-stack-startup` granted itself more than its own ceiling.** 600 s
   `TimeoutStartSec` against three health gates of 300 + 120 + 240 = **660 s** before
   any dispatch, plus 377 s of measured dispatch. Last cold start used **482 s of
   600** (15:48:42 -> 15:56:44); the register carried 368 s, which was the 2026-09-11
   run and real but superseded. Not hypothetical: the script's own comments record
   2026-08-26, when the pihole gate ran its full 300 s and every remaining wave
   dispatched with no DNS (#252, #253). **Its start limiter could not fire either**:
   3 x (600 + 60) = 1 980 s never fit the 1 800 s window that claimed to span three
   attempts, so the unit could not reach `failed`, and neither the alert nor the
   crash-heal that waits on `is-failed` could run. **Fixed**: ceiling 1 800 s, window
   derived from the attempt cost at 7 200 s.
3. **The credential masker could not reach half of what it exists to redact.**
   `[A-Za-z0-9_]{32,}` counts word characters; base64 uses `+` and `/`, which split
   a key into runs shorter than 32, so whether a key was redacted at all was decided
   by the bytes it drew. `security` measured **11 of 22** live values unmaskable; the
   main session measured **107 of 200** synthetic 32-byte keys passing through
   untouched — two routes, same answer. The two WireGuard server private keys are
   the live case: same generator, same 44 characters, one masked and one not.
   **Live exposure on the day: ZERO**, over 468 043 lines with a positive control at
   3 809/2 699 hits. Latent, not live. **Fixed** with a padded-base64 alternative.
4. **`homelab-netdata-kuma` finished a degraded run 6 s inside its ceiling.**
   234 s against 240 s, measured 15:57:14 -> 16:01:08 — and the context is the
   finding: the same unit had failed at 15:52:07 -> 15:52:38, so the near-miss run
   is the DEGRADED one, exactly the case the retry budget exists for. `TIMEOUT` rose
   from 10 to 30 on 2026-09-13 without the bound moving, and `--retry 2` made each
   push cost 3 x TIMEOUT for a real ceiling of 336 s. **Above 336 s and below the
   timer's 300 s cannot both hold**, so the retry went rather than the bound.
   Filed under C67 by the agent rather than minted — the correct call.
5. **Kuma dead windows guarded the most variable job with the tightest margin.**
   Monitors 15 `Backup` and 16 `Offsite backup` sat at 90 000 s for an 86 400 s job
   whose duration is unbounded (145 s to 31 488 s measured, factor 217), while the
   neighbouring daily job already had 93 600. Longest ORDINARY night 87 272 s ->
   **3.0 % margin**. **Fixed in the Kuma UI** (not in the repo). Verifying the fix
   surfaced three more daily monitors still at 90 000, and two had the same defect:
   30 `Veille quotidienne` had already expired its window **twice** with no
   underlying failure, and its worst ordinary gap of 93 474 s exceeded the window
   outright; 23 `Pi security posture` sat at 3.7 %. Now 93 600 / 93 600 / 100 800;
   18 `Offsite health` was left alone because its red beats are genuine failures.
   All five margins now sit in a 6.8-7.4 % band.
6. **Traefik cut any request body at 60 s regardless of throughput.** No
   `respondingTimeouts` declared anywhere in the tree, so all three entry points
   inherited the v3 default. Proved with a control by `network` (a 1 byte/s POST
   closed at 63.0 s while a complete request answered in 0.0 s). A 10 MB Nextcloud
   chunk crosses it below ~1.4 Mbit/s upstream. **Fixed** at `readTimeout: 600s` on
   `websecure` — bounded rather than disabled, though 80/443 are not forwarded and
   the slowloris rationale for the default does not apply here. Verified
   functionally: a body dripped for **75 s** now completes with HTTP 404, against a
   403 control in 0.25 s proving the instrument reaches Traefik.

### Corrected in words only, and the design decision it leaves open

**The redactor's log ring cannot reach the span it reasons about.** `10 x 20 MB` is
a SIZE bound; a `json-file` ring belongs to the container, so a deploy starts it
empty. Measured 2026-09-20: **1 file of 10, 3.7 MB, 11 h 06 of span — 1.9 % of
capacity**, and short of the 48 h its only consumer asks for. The comment argues
the widening was needed so a WEEKLY offsite writer would be visible; on the day,
that writer appeared **zero times** in the whole retained log. Only the false claim
was fixed. **Making the span real needs the log off the container's lifecycle, and
journald is excluded by construction — it is the one store the masking in the
security role cannot filter.** That is an ADR-034 decision, not a correction, and
it is outstanding.

### Rejected from the agents, and why — 3, one of which was load-bearing

1. **"`.env.example` is missing three secrets, and a from-scratch rebuild brings up
   Pi-hole with no admin password" — NOT REPRODUCIBLE, and it had already been
   relayed to the operator before the main session checked it.** Derived both ways
   against what the deploy actually writes: the gap between `env.j2` and
   `.env.example` is **ONE key**, `LIBRARY_DIR`, without which Jellyfin and Immich
   mount an empty path. The Pi-hole and Redis secrets are docker secrets, not `.env`
   entries, and the file itself states that Nextcloud takes no admin credentials at
   all. The real finding was kept and fixed; the alarming half was withdrawn.
2. **`backup`'s "no false alarm has fired yet — the three recorded DOWNs are
   authentic".** Retained history holds TWO down beats for monitor 15, and the
   second is `No heartbeat in the time window` (2026-09-13 02:10:47 UTC) — the
   90 000 s window expiring. Its authenticity cannot be settled from retained data,
   so the honest statement is "the window has already fired once". This
   strengthened the remedy rather than weakening it.
3. **`observability`'s own C120 variant**, self-objected and not adopted; its
   property is covered by the merged class without the mechanism clause.

### Instrument traps paid — 8, and THREE were the main session's own

1. **Main session: a gap between consecutive UP heartbeats swallows genuine
   outages.** Reported a Kuma window "already exceeded by 30 %", which was false;
   the agent's "ordinary night" framing was the correct one. Re-measured excluding
   spans that contain a DOWN beat — and then again, because **retention prunes old
   DOWN beats, so an old outage still reads as an ordinary night**. Both corrections
   were needed to get 6.8 %.
2. **Main session: comparing a masking result to the literal `***`** scores a
   PARTIALLY masked key as surviving. Fixed by testing whether `sed` changed the
   string at all.
3. **Main session: propagated a false register statement into an agent brief** —
   see the register's own lies below. The agent caught it.
4. `security`: `/etc/apt/apt.conf.d/20auto-upgrades` matches neither `*periodic*`
   nor `*unattended*`, so a glob there reads as "the setting is absent". Ask
   `apt-config dump`. Self-caught.
5. `observability`: **`heartbeat.duration` returns 0 for all 22 active monitors** —
   a zero that looks like data. The real column is `ping`. And raw `heartbeat`
   retention is **~44 h, not the 180 d `keepDataPeriodDays` advertises**; any
   amplitude must come from `stat_daily` (129 d).
6. `services`: a `json-file` log survives a `restart` but not a recreate, which made
   the first throughput calculation wrong — and correcting it produced finding 1 of
   that domain.
7. `ansible-deploy`: reading a COMMENTED-OUT line in a stock Ubuntu file as live
   configuration nearly produced a false finding on the offsite reboot window.
   Self-declared.
8. Main session: **the host resolves through 1.1.1.1, not Pi-hole**, so split-DNS
   names do not resolve from the host itself. A functional probe from the host needs
   `--resolve`, or it fails with `curl` rc=6 and looks like a proxy fault.

### The register lied about itself in FOUR places — seventh consecutive run

And this run is the one where that stopped being an internal tidiness problem:

1. **"`traefik` declares no `start_period`."** FALSE — the live container carries
   `StartPeriod=240000000000` (240 s), shipped in #308. **The main session copied
   this into the `services` brief as established fact**, and the agent had to
   correct it. A false statement in this file reached an agent's mandate and would
   have suppressed a real check had the agent trusted it.
2. **C15 "runs weekly — a 7-day detection window."** FALSE, and it is the THIRD
   consecutive run to find it: the deployed timer is `OnCalendar=*-*-* 08:00` with
   `RandomizedDelaySec=15m`, last fired 2026-09-20 08:04:59. The cadence is DAILY.
3. **"C18 — 26/26 on the TAP."** The deployed spec carries **46**, confirmed three
   ways: `grep -cE '^  dump-' /etc/goss/backup-dumps.yaml` = 46, the live beat
   `dumps ok (46 checks)`, and the main session's own `Count: 46, Failed: 27`.
4. **C34's cardinal of 460 is derivable from no written rule** — the same defect as
   the six preceding runs, and the reason axis C was re-derived from the property.

**The main session's own C119 sweep predicted this and the prediction paid inside
the same run.** The four register files are git-tracked, cite each other **93
times** (SKILL 12, classes 41, settled 29, domains 11), assert facts about the
deployed system constantly, and **nothing grades them**: `grep -rl 'full-audit'`
over every `*.yml`/`*.yaml`/`*.j2`/`*.sh` returns nothing, and `.github/workflows/`
references neither `classes.md` nor `full-audit`. The audit's only quality control
over its own register is the audit. What WAS verified sound tonight: the class ids
run C01..C120 with no gaps, and the OPEN membership agrees between `classes.md` and
`domains.md`.

### A cardinal correction, not a proposal

`network` re-censused C102: it records **1 instance and there are 3** (2026-08-22,
08-23, 09-16, all toward the same upstream, corrected in 46/56/67 s). Full census:
37 764 executions, 120 triggers, 119 writes — **116 rewrite the same address, 3 a
wrong one, and 0 ever repaired a stale endpoint.** The remedy stays DECLINED and
was not re-proposed.

### Clean, and measured — the negatives that closed questions

- **`usb-tamper` + `killswitch`, 121/121 comment lines, ZERO contradictions** — an
  evidenced clean, including four exact timestamps, a systemd error string and a
  udev exit code verified byte-for-byte against the journal.
- **`ansible-deploy`'s C119 plane: 47/47 classified, 0 defective.**
- **`base`/`storage`/`docker`/`security` C01 strata: 37/37 files, zero instances.**
- **41/41 tmpfs** all at 0-2 %; the Docker daemon shutdown budget (150 s within
  240 s); `no-new-privileges` with exactly two exceptions, netdata and collabora;
  21 `Host()` names against 21 certificate pins; 11 of 11 written `start_period`
  targets matching the live containers.
- **Thresholds measured and found correctly placed, which is the other half of this
  key**: CPU temperature 80 °C against a 55-day maximum of 56.478 °C (hardware fact,
  no change proposed); memory 800 MiB against a minimum of 756.62 MiB; swap 85 %
  against a single 94.5 % excursion in 55 days; `/mnt/data` 85 % at +3.89 GiB/day
  gives ~2 years with ~6 months of warning, while `/` is flat at 18 % over 50 days
  and its threshold is a tripwire rather than a gauge; DNS p99.9 at 1.16 s against
  dnsproxy's 10 s; the six network healthchecks at 0.109-0.435 s against 5 s
  (margins 11-46x); `PersistentKeepalive` at 25 s on both carrying peers; DDNS at
  6 040 executions over 62 days with zero IP changes; C14's certificate alarm at
  21 days against a 30-day renewal floor, 9 days below it, live minimum 35 days.
- **`backup`: retention versus detection is MOOT** — nothing ever runs `forget`
  against the offsite (426 G of 1.8 T, 25 %), so the recovery window is unbounded.
  Maintenance-to-backup margin 2 h 03 against 27 min of bounded work.

---
## The run of 2026-09-20 (TENTH) — the key was `substitution`, and it minted nothing on purpose

The twenty-ninth key, **invented**, and chosen by the operator from four
candidates each of which was put with its weakness stated first. The six-word
question:

> **When the declared component is absent, what takes its place, and who can tell?**

The discriminator is what makes it a class rather than a list of defaults:
**the substitute must be INDISTINGUISHABLE from the declared thing in the
estate's own reporting.** If anything goes red, or a log line says so, or a
monitor falls, it is not an instance.

Five admissible shapes went into all eight briefs — (a) the default that fills a
missing value, (b) the mount that did not happen, (c) the fallback path that
takes over, (d) the stand-in artefact, (e) the same name and not the same
object. Six overlaps were declared instance-only in the brief (C111, C105, C45,
C12, C29, C118), and **C118 was named in every brief as the purest instance of
this key already on file and already DECLINED** — the trap the key walks into,
disarmed before the agents met it. None of the eight re-proposed it.

### The counter: 3 OPEN in, 3 OPEN out, ZERO minted, class total 119 -> 119

C12 left as ENUMERATED; C01 REOPENED. The mint rate now reads `commensurability`
0, `aggregation` 1, `staleness` 1, `attendance` 2, `oracle` 2, `asymmetry` 3,
`independence` 3, `interference` 1, `substitution` **0**.

**This is the first of the two consecutive zero-mint runs the criterion needs,
and the zero has to be read with its cost.** Five false rationales were found by
four agents with no contact. They split into two families: those citing a sibling
artefact that contradicts them (C34) and those asserting a fact about the system
that the system denies (C01). Minting a class for the second family would have
been easy and would have shown a mint. **Recognising that C01 already owns it
reopens a class this file recorded as CLOSED on 123/123 referents** — a worse
result to report and the true one. The register has warned five times that
declining mints manufactures zero-mint runs; this is the inverse discipline and
it is worth recording as such.

### The run's real output is that C01's space was a FILE TYPE

C01 was closed on 472 machine-checkable claim occurrences across 81 files. Every
one of those files ends in `.md`. Its property says "a documentary statement",
and a comment in `ansible/roles/deploy/tasks/secrets.yml` is a documentary
statement — it is the first thing a reader of that file meets, it makes a
falsifiable claim, and the deployed artefact contradicts it. **Eleventh payment
of the wrong-axis shape**, and the first time it has been paid by a class that
was closed rather than sampled.

### Live defects, ranked by what was happening without anyone knowing

Nothing was broken. The estate measured clean on every surface any agent
probed — 37/37 monitors, 0 failed units, 32/32 containers, 21/21 certificates
on real leaves, 22/22 routers carrying all three global middlewares (the
register carried 19/19), the perimeter re-proved from the offsite uplink with a
known-open port as control. The ranking is therefore by cost the day it matters.

1. **The rotation route reaches 19 of 31 secret renders, and the comment that
   says otherwise is why nobody looked.** `deploy/tasks/main.yml` stated that the
   `secrets` tag exists so a secret can be "written, **rotated** or re-moded"
   without dragging in compose. The tag reaches `secrets.yml` alone; `configs.yml`
   (searxng_settings), `backup.yml` (7 values), `wireguard.yml` (`wg0.conf`) and
   `ddns.yml` (`ddns.env`) sit behind other tags. **This is the cause of the
   2026-09-12 divergence, and the commit of that morning removed the residue —
   the three live tokens — not the cause.** Reached independently by `security`
   (from the runtime carriers) and `ansible-deploy` (from the render sites), and
   confirmed a third time by the runbook, whose consumer table named Traefik
   alone and had zero occurrences of "ddns". Fixed 2026-09-20.
2. **No deploy-time mount guard anywhere.** `secrets.yml` uses only
   `copy`/`file`/`template`/`assert`/`replace`/`lineinfile` — no `command`, no
   `shell` — and its two asserts check variables. The twelve `mountpoint` guards
   in the tree are all in runtime templates; the `storage` role that mounts the
   volume is tagged `[phase1, storage]`; `site.yml` has no `always` tag and no
   pre_task guard. A tagged deploy against a locked volume writes 22 to 26
   credential files in clear onto the SD card at the mount point's path, reports
   `ok/changed` with `0 failed`, and the next unlock hides them under the mount.
   Reached independently by `system` and `ansible-deploy`. Fixed 2026-09-20 with
   an `assert` in `deploy` and `claude-code` — the two roles that write
   credentials under `/mnt/data` and that run after `storage`; `base` is excluded
   because it runs before the mount on a full provisioning run, and `offsite.yml`
   plays neither role.
3. **85 % of the protected bytes had no existence detector.**
   `/mnt/data/media` is a declared restic source and appears 0 times in the three
   deployed goss specs, against controls of 13 and 12 for `/mnt/data/services`
   and 3 for `/mnt/data/secrets`. restic 0.16.4 skips a missing source and carries
   on — both strings present in the installed binary against a negative control —
   and aborts only when every target is gone. The Kuma beat carries no byte, file
   or path count, so it would be byte-identical. Fixed 2026-09-20.

### The instrument this run produced, and it retires a declined measurement

`sudo debugfs -R "ls -l <path>" /dev/mmcblk0p2` reads the SD substrate **behind a
live mount, read-only**. The operator declined bind-mounting `/mnt/data` on
2026-09-02 as an intrusive measurement, and declined investigating the files
hidden under it. **The question now has a free answer and it is "nothing"**:
seven directories dated 10-May-2026, zero files, no `secrets/`, no `docker/`,
verified by the main session with `/etc/ssh` as a positive control. Recorded as a
closed question, not as a re-proposal.

### Rejected, requalified or corrected — 6, and two were the main session's own

1. **Main session: its own healthcheck measurement answered a different question
   from the claim it was checking.** It counted containers with no health STATE
   (4: `nextcloud-cron`, `nextcloud-notify-push`, `dnsproxy`, `searxng`) against
   a finding about containers whose health TEST comes from the image (4 others:
   `wg-easy`, `collabora`, `immich-server`, `immich-machine-learning`). Two
   distinct sets of four, both real; the finding survived unchanged.
2. **Main session: the four "stale" monitor cadences it flagged in its own
   briefs were the declared cadences.** Killed independently by `backup` and
   `observability`, both with the trigger times and the next-fire times, once
   Kuma's UTC is applied. The main session had put them in the brief as
   suspicious; that was the baseline creating its own lead.
3. **`backup` reported 6 restic sources.** The deployed profile declares 5.
   Does not change its conclusion.
4. **The proposal to widen `secret-mounts-carry-the-current-value` from 14 to 17
   was measured and NOT taken.** The three uncovered files are `volumes:` binds,
   not `secrets:`, so they never land at `/run/secrets/<name>` and the comparison
   path itself would have to change. Measured 0/28 mismatch, both consumers have
   restart handlers. Turning a working gate into a silent green is the larger
   risk.
5. **The DDNS `dig` verification was NOT taken, and only the cardinality guard
   shipped.** In an unattended timer, an unreachable resolver reports the DDNS
   down while the DDNS is fine — the noisy shape the operator has declined
   repeatedly. `.result | length` is unambiguous and cannot produce a false
   positive.
6. **`observability` self-declared a rule-7 exposure**: a derivation over all 120
   monitor columns printed a basic-auth password and two push tokens into its own
   transcript. Nothing reached its report or any file. **The rule it produced: an
   exhaustive derivation is as dangerous as a verbatim paste, and needs a
   credential-column denylist before it prints.**

### Instrument traps paid — 7, all self-caught by the agent that hit them

- **`git log %cd` is the REBASE date in this repository** (rebase-only merges), so
  a drift measured against it is fiction — it manufactured five. Use `%ad`.
- **`docker compose config --hash` is not a drift oracle for
  `network_mode: service:<other>`** — compose resolves the netns to
  `container:<id>` before hashing, so it falsely flags `dnsproxy`. The dry-run is
  the oracle.
- **`grep -oE "\$\{"` through an ssh double-quoted heredoc reports 0** against a
  true 133: `\$` becomes a mid-pattern ERE anchor.
- **An un-`sudo`'d `[ -f ]` fails toward "absent"** — counted 10 file binds
  instead of 28. Sibling of the glob trap, which was paid for the seventh time
  the same evening, with a new symptom: it reads as "the files are missing"
  rather than as an empty result. **Glob and privilege must share one shell.**
- **`docker exec … sqlite3 -cmd …` returns empty with exit 0.**
- **Probing service endpoints from the workstation needs `--resolve`**, or every
  name reads as a total outage on a healthy estate.
- **`include`ing Nextcloud's `config.php` returns 1, not the array**, and
  `ufw status | head -1` picks the wrong rule — two false divergences.

### Clean, and measured — the negatives that closed questions

- **21/21 hosts on real Let's Encrypt leaves, no default certificate**; sniStrict
  refuses unknown or absent SNI with alert 112.
- **6/6 middlewares applied and all three globals on 22/22 routers**, queried
  from `/api/rawdata` rather than read off labels.
- **Pi-hole has one live upstream confirmed from FTL**, blocking active, no stale
  file in the dnsmasq mount, and its 21 `address=` lines equal the 21 `Host()`
  names. All four wg-easy clients carry that resolver alone, so a dead resolver
  fails closed.
- **Both `/etc/hosts` pins survived the 15:43 reboot** because the cloud-init
  template carries them.
- **32/32 containers with no config drift** (`compose --dry-run up`: 32 Running,
  0 Recreate), 31/31 image-tag identity, **0 stale inodes** over 28 binds
  sha256-compared, 133 `${VAR}` references over 17 names all set and non-empty.
- **0 of 2 711 push beats took the adapter's vacuous-UP path.**
- **8 cells of 4 440 qualify** as an operator-set monitor value whose absence
  would leave a working-looking probe testing something else — **and 0 monitors
  are one restore away**, because `kuma-dump.sh`'s `select *` captures all 120
  columns since 2026-09-11.
- **10/10 dump targets have a live restore procedure**; the runbook parameterises
  on `$svc.sqlite3`, so a grep for literal filenames scores 0 and is wrong.
- **63 unit, script and path names cited by the runbooks all resolve on the
  hosts**, and the three ADR-031-deleted scripts are named 25 times, every
  mention past-tense.

---

## The run of 2026-09-20 (NINTH) — the key was `interference`, and it turned on the audit's own method

The twenty-eighth key, **invented**. The file recorded that only `cost` remained
named and that it shared `scale`'s weakness. Three candidates were put to the
operator with each weakness stated first — `interference`, `admission`,
`credulity` — and the operator asked for a recommendation rather than choosing
blind. The six-word question no class among the 118 had asked:

> **What does this mechanism do TO what it observes?**

All 118 asked whether a mechanism REPORTS correctly — at what cadence (C44),
at what grain (C107), from which notion of correct (C111), in which direction
(C113), whether anyone reads it (C85). **Not one asked whether the act of
measuring, checking or healing changes, resets, costs or destroys the state it
is judging.** The register had paid that shape three times without a word for
it: the `sudo grep` that writes the string it hunts into `auth.log`, `udevadm
test` powering the Pi off, the heal timer resurrecting a container stopped for
maintenance.

Five admissible shapes went into all eight briefs — (a) the instrument that
writes to the medium it reads, (b) the probe that destroys the evidence, (c) the
autonomous actor that cannot tell maintenance from failure, (d) the cost borne
by the subject, (e) the measurement that cannot be repeated. **Eleven overlaps
were declared instance-only** (C07, C41, C45, C49, C59, C69, C82, C90, C91,
C111, C116) and the discipline held: six of eight domains returned an explicit
"no mint".

### The counter: 0 OPEN in, 3 OPEN out, 1 minted, 2 REOPENED, class total 118 -> 119

**The termination clock RESETS.** The mint rate now reads `commensurability` 0,
`aggregation` 1, `staleness` 1, `attendance` 2, `oracle` 2, `asymmetry` 3,
`independence` 3, `interference` **1**. The pair of consecutive zero-mint runs
has still never been achieved.

**C119 was minted OPEN rather than ENUMERATED, and that is the run's only
discretionary call.** Two agents reached its property from unrelated directions,
but both sweeps were bounded by a MECHANISM — pgrep call sites on one side, one
log detector on the other — while the property is not. Recording it ENUMERATED
over the five sites actually swept would have kept the OPEN column empty and
shown a second consecutive zero-mint run. That is the number this file exists to
stop anyone from manufacturing.

### The run's real output is that the key turned on the audit itself

Fourth confirmation of the rule that a key which turns on the INSTRUMENT is worth
more than one that only turns on the estate — and the first time the instrument
in question is this skill. Three measurements, none of which anyone had ever
made:

- **143 runs of `homelab-posture.service` in 30 days, of which ~30 are
  scheduled.** One per day when nobody is watching; 9, 11, 13 and 19 on the days
  an audit or a deploy ran. **~79 % of the beats a run reads as evidence are
  produced by runs.** This is the measured cause of a defect the register has
  recorded four times as bad luck — "the audit's own baseline lied" — and it is
  structural, not accidental.
- **91 % of the Traefik access log** (27 775 of 30 525 lines/24 h) is the estate
  observing itself.
- **89.5 % of today's journal** is the observer; 60 362 messages against 14 on a
  quiet day.

**The correct response is NOT to reduce the observation.** It is to stop reading
the most recent verdict as evidence without asking who produced it — which the
baseline rules in this file already say, and which this run is the first to
quantify.

### Live defects, ranked by what was happening without anyone knowing

1. **A BROKEN GATE, and it is the worst of the three.** `/etc/goss/posture.yaml`
   counted lost Kuma reports with `journalctl … -o short-iso --grep … | grep -c .`.
   **`journalctl` writes `-- No entries --` to STDOUT**, so `2>/dev/null` does not
   remove it and a loss-free day counts as ONE loss. The fast path `[ "$lost" -eq
   0 ] && exit 0` was therefore dead; `newest` became `--`; and **`date -d "--"`
   does not fail — it returns today's local midnight** (measured on the host:
   `1789855200`, byte-identical to `date -d "today 00:00"`). Every run judged
   recovery against a fabricated loss and **excluded 9 of the 15 push monitors**
   from the second clause. Live before/after on the host: old form `lost=1`, new
   form `lost=0`, zero real losses in three days. The offsite twin uses `-o cat`
   and was never affected — **the space is 2 sites, 1 defective.** This is a C03
   instance inside the GATED half, so it is a red test, not an audit result, and
   it does not count toward this run's total.
2. **C119's live half** — see the class row. Fixed and verified the same day.
3. **Six writes per deploy reporting `changed=0`.** `roles/deploy/tasks/nextcloud.yml`
   re-applied `readonly` and `filesystem_check_changes` to three external storages
   on every deploy under `changed_when: false`, so the report was byte-identical
   whether it had just silently undone a change made in the web UI or done
   nothing. The listing it already loops over carries each option's current
   value; the write is now guarded by it and declares itself when it fires.
   **Verified by the deploy's own arithmetic**: with `changed_when: true` in
   place, six writes would have made `changed` >= 9 against the three files that
   did change; the recap read `changed=6`.

### The afternoon's second mandate — the operator ordered a sweep of every log store

The run's first report listed the Traefik access-log leak. The operator's answer
was to ask what ELSE was leaking, on both hosts. **8 live secret values across 5
log stores**, 2 024 files plus both complete journals swept, each surface with
its own positive control. What it found, and what the main session re-measured:

- **CONFIRMED and now fixed** — three `*arr` API keys, 17 occurrences in
  `/var/log/auth.log.1`, which is `0640 syslog:adm` and the operator's account is
  in `adm`: **readable without root**, on the unencrypted SD card.
- **CONFIRMED and the reason the whole sweep mattered** — the LIVE Cloudflare DNS
  token, 1 occurrence in `sudo.log.1` and 1 in `auth.log.2.gz`. It is the only
  credential in the estate that works from anywhere on the internet. **The main
  session first reported it as NOT reproduced and was wrong**; see the instrument
  traps.
- **The finding under the findings** — every leak sits on `mmcblk0p2`, while
  ADR-011 says the SD card "yields configuration but no credentials" and the
  card-theft runbook lists none of them. An SD-theft response run that day would
  have left all of it in place.
- **Clean, with evidence**: nothing reaches the backups through a log (the only
  log surface inside a restic source is `/mnt/data/services`, 1 221 files,
  157 MB, 0 hits); the offsite host is clean end to end, re-verified
  independently by the main session (75 513 lines, 0 credential-header shapes);
  both restic passwords, all WireGuard and ACME keys and every service password
  appear nowhere.

**Shipped the same afternoon**: daily rotation and masking for both files that
carry command lines, five weeks of clear text reduced to twenty-four hours, and
the already-written files masked in place (0 occurrences after, 22 359 masks
applied, 142 171 lines preserved, owner and mode unchanged). **The journal is
NOT covered and the code says so** — journald captures `_CMDLINE` itself, in
binary, with no insertion point. Moving it to the encrypted volume is the right
remedy and cannot be validated without a reboot, so it is recorded as a planned
change, not done.

### The rotation revealed a second live defect, and it is C12's

Rotating the Cloudflare token exposed that **three distinct tokens were in play**:
the one Traefik used (leaked, replaced today), the one the DDNS used (rendered
2026-07-20, never leaked), and the new one. The 2026-09-12 rotation had updated
Traefik and never re-rendered `ddns.env`. **Eight days, two live values under one
vault variable, nothing able to notice** — see C12's row. Both are aligned now.

**The near-miss is worth more than the finding.** The operator was about to revoke
"the old token" from the Cloudflare dashboard while the DDNS still depended on a
different one. The DDNS keeps the `vpn` A record fresh; that record is the
WireGuard endpoint; the tunnel is the only route to the Pi. **Revoking blind had a
one-in-two chance of costing remote access at the next public-IP change.** What
prevented it was checking which consumers read the variable before touching the
dashboard — not caution, a lookup.

### The fixture lesson, paid a THIRD time

C03-T's gate was proven to fail on purpose in six runs — against a database the
test itself wrote, which is why the mute-reporter defect survived (recorded
2026-09-13). Tonight's counting defect survived the same six runs **for the
mirror reason: they stubbed `journalctl`**, so the sentinel the real binary
writes was never in the fixture. **A gate proven against a fixture is proven
against the fixture's model of the world.** Both of this class's repairs were
therefore verified differently: the two corrected assertions were executed
VERBATIM from the deployed `/etc/goss/posture.yaml` against the live estate, and
made to fail by injecting a synthetic line into the real pipeline's input rather
than by replacing the pipeline.

### Rejected, requalified or corrected — 5, and two were the main session's own

1. **`services`' mint was not one.** Its instance — the redactor healthcheck's
   `pgrep` matching its own argv — is **C29's vacuous liveness half, DECLINED by
   the operator on 2026-09-02**. The generalised property survived as half of
   C119; the remedy did not, and must not be re-proposed.
2. **`security` overstated its own finding by a wide margin.** It reported that a
   fail2ban ban on the offsite "cuts the backup path AND the only admin path —
   recovery needs physical presence". Measured by the main session: the
   `nftables` action is `type = multiport` on the SSH port alone, `rest-server`
   listens on `*:8000`, and `bantime=3600` with no increment. **The backup is
   untouched and the ban expires by itself in an hour.** The finding survived,
   two orders of severity smaller.
3. **`ansible-deploy` reported 50 posture runs in 30 days, 9 scheduled.** The
   real figures are **143 and ~30**, counted with a control. The correction made
   the finding stronger, not weaker.
4. **Main session: the baseline said `homelab-backup.service` ran 49 s.** It ran
   **4 min 37 s** (`InactiveExitTimestamp` 03:00:08 -> 03:04:45). `backup` caught
   it. See the instrument traps.
5. **Main session: `systemctl show -p A -p B --value`** was read as returning the
   values in the order asked. It does not. A `LastTriggerUSec` dated tomorrow was
   the symptom.

### Instrument traps paid — 3, and TWO were the main session's own

1. **NEW — `systemctl show` with several `-p` and `--value` does not preserve the
   order of the properties asked for.** It prints them in systemd's own order, so
   positional parsing silently transposes fields. Name one property per call, or
   drop `--value` and read the `key=value` form.
2. **NEW, and it invalidated a baseline figure — for a `oneshot` unit with
   several `ExecStart=` lines, `ExecMainStartTimestamp` dates only the LAST
   one.** `homelab-backup.service` has two, so the field understated the unit's
   run by 3 min 48 s. **Read `InactiveExitTimestamp` for a unit's span**; it is
   the counterpart of the trap that says `Result` alone means nothing.
3. **SIXTH payment of the un-`sudo`'d glob**, by `security`, caught by its own
   positive control before it reached a conclusion.

### The register lied about itself in FOUR places — fifth consecutive run

`project-manager` was sent at the register again and it paid again. All four
confirmed independently by the main session before correction:

- **Two rows in the ENUMERATED table carried the state `OPEN`** — C105 and C113 —
  against a header claiming `0 OPEN`. Both were MINTING rows never updated when
  their class closed; C105's own closure row sits 4 200 lines above it saying
  `28/28`. **The mechanism is two rows for one class, which is exactly how this
  happens, and C119 now has two rows as well.**
- **The ENUMERATED heading read "36 here" over 69 rows**, and excluded C27, which
  has a row there.
- **The GATED table still reads as ten members**, because C12's row was left in
  place by the eighth run's fix, which diagnosed it in prose and did not remove
  it. **Third consecutive night this heading has been wrong, twice inside a
  correction written for that same defect.** It now carries the membership as a
  literal list with an instruction not to reconstruct it by counting.

### Clean, and measured — the negatives that closed questions

- **ACME spends nothing.** One resolver, no on-demand knob, `notBefore` spread
  over 10 distinct days: no verification can trigger an issuance.
- **Cache-warming is not happening.** The health probe's 16-hex random label is
  forwarded 288x/24 h (its own cadence), Kuma's DNS monitor forwarded 0 of 1 450,
  and nothing deployed reads a query row, rate or hit-rate anyway.
- **The nightly dumps cost the running services nothing observable.** Kuma beats
  inside the 44 s dump phase are flat (109/80/84/76 ms); the 4-7x latency spike
  lands a minute later on `start scan`.
- **The offsite check does not pollute what it verifies**: `locks/` empty on both
  repositories, and restic's exclusive repo lock — not resticprofile's two
  profile locks — is what serialises them.
- **No lockout counter exists to consume**: `pam_faillock` is not enabled
  anywhere, so shape (e) is empty in the security domain.
- **`homelab-stack-heal` took 0 actions inside any backup window** over 9 runs
  and 5 665 lines, while genuinely acting on three containers outside them.
- **Kuma's heartbeat budget is per-monitor**, so no reporter can evict another's
  history.

---

## The run of 2026-09-20 (EIGHTH) — the key was `independence`, and the operator declined all of it

The twenty-seventh key, **invented** — the file recorded that only `cost`
remained named and that it shared `scale`'s weakness. Proposed to the operator
with three candidates and each weakness stated first (`independence`, `cost`,
`precedence`); `precedence` carried the declared risk of being `order` in new
clothes, and `independence` the risk that a negative property invites a
speculative list. The six-word question no class among the 115 had asked:
**do these two fall together?** All 115 asked whether ONE mechanism is right;
not one asked whether two the estate treats as independent share a cause.

Five admissible shapes went into all eight briefs — shared instrument, declared
redundancy over one substrate, the alarm coupled to its carrier, two assertions
from one reading, and a backstop sharing a cause with what it backs. Eight
overlaps were declared instance-only. **The mint rule was `collision`'s, and it
is what kept the count at three**: a common-mode counted only if the agent
demonstrated the shared cause AND that a single failure of it defeats BOTH
branches.

### The counter: 2 OPEN in, 0 OPEN out, 3 minted and all 3 DECLINED, class total 115 -> 118

**First run ever to empty the OPEN column. The termination clock RESETS anyway**
— three mints. `commensurability` 0, `aggregation` 1, `staleness` 1,
`attendance` 2, `oracle` 2, `asymmetry` 3, `independence` 3. The mint rate is no
longer decaying, and two of the last three keys were invented rather than taken
off a list. The pair of consecutive zero-mint runs has still never been
achieved.

### The operator's arbitration, and it is the run's real output

**Five findings put, five declined, one question answered.** This is the first
run where the estate's answer was "I accept this risk" rather than "fix it",
and the register is more useful for recording that than it would be for
recording five more open remedies. See the DECLINED rows of C116, C117 and C118,
and the C44/C113 sections in the OPEN-table area.

The one substantive change shipped: **documentation**. ADR-010's false
blast-radius claim, the kill-switch verification step that verified nothing, the
certificate comment that had drifted 18 -> 21 while its watched count stood
still, and five self-contradictions in this file.

### The register lied about itself in FIVE places, and one of them was last night's fix

`project-manager` was sent at the register itself this run, and the result
justifies the mandate. The GATED membership sentence written on 2026-09-19 **to
fix exactly this defect** named C04, C06, C07, C08 — double-counting C07,
including two classes closed by decision and one ENUMERATED, and omitting all
nine real members. **A correction that reproduces the disease it treats is the
strongest argument this file has for writing memberships instead of rules for
reconstructing them.** The others: C07's row still read RED two days after
shipping green; C40 was the EIGHTH row frozen at the 28-container estate and the
sweep of seven missed it (26 of 32, not 29/29, measured live); the correction
list itself wrongly moved C22 28 -> 32 when C22's space is healthchecks and 28
was already right; and three dead pointers. All fixed 2026-09-20.

### Rejected, requalified or corrected — 6, and three were the main session's own

1. **`services` refuted its own most promising lead.** The posture spec issues
   169 `docker inspect` calls, not one per container (6 shapes) — two assertions
   agreeing about one container are two readings. Shape (d) refuted by
   measurement, not argued away.
2. **`security` killed the candidate it liked most.** The two ufw assertions are
   NOT one reading twice: `backend_iptables.py:262-286` probes
   `iptables -L ufw-user-<dir>` and returns inactive on a missing chain.
3. **`network` did not report a real single substrate.** Both dnsproxy upstreams
   are Quad9 — but ADR-015 explicitly declined a second provider, so it was
   recorded as context and not as a finding. The rule working.
4. **`backup` rejected a coupling on measurement.** The two backup monitors do
   share `homelab-backup.service` (`Type=oneshot`, a failed backup mutes
   `Offsite backup` rather than reddening it, observed live 2026-09-06) — but
   the exposure is 49 minutes against a 24 h job and the dead-man fuse is proven
   to fire. Not a joint defeat, not a mint.
5. **Main session: "the deployed posture spec has never been graded" is too
   strong.** It was true when `system` measured it and it resolved under
   observation: spec mtime 00:13:56, first run to grade it 11:08:06 -> 11:09:17,
   pushing `posture OK — 433 checks (goss 410) — scheduled run` against the
   13-hour-old `goss 409 — manual run`. **The correct statement is a 10 h 54 min
   window that reopens on every deploy.** Operator arbitration: acceptable, it
   resolves itself. Do not re-raise.
6. **Main session: socket-proxy has 21 deny knobs, not the 16 reported.**

### Instrument traps paid — 6, and THREE were the main session's own

1. **NEW IN DIRECTION — a false GAP where the previous three runs produced a
   false CLEAN.** The main session's baseline reported `homelab-health` as never
   run, having read `ExecMainExitTimestamp` while the unit was mid-run. It runs
   every 5 minutes, 28 003 journal lines. **Fourth consecutive run whose own
   baseline lied.** The control that settles it is `LoadState` plus
   `ExecMainStartTimestamp`, never `Result`.
2. **NEW — a partial read of a multi-line block is a false negative with no
   symptom.** The main session read a `source:` list to line 215, concluded the
   secrets path was absent, and contradicted an agent that was right; the block
   runs to 241 with a long comment in the middle. **Read to the end of the
   block, not to the end of the screen.**
3. **Main session, caught in flight**: an empty `grep` over a netdata config
   with no control. The file did not exist at the path used. Re-run with a
   control (`find`, then a `grep -c` proving 30 matches), which changed the
   finding from "no recipient configured" to "no override exists and the stock
   file's recipient fields are empty" — same conclusion, different evidence, and
   only one of them was measured. The same trap bit a second time on
   `acme.json`, where a wrong path returned "0 certificates"; the real path
   holds 21.
4. **FIFTH payment of the un-`sudo`'d glob.** `observability`: reading the `on:`
   lines of `health.d` through an un-`sudo`'d glob returns EMPTY, and every
   plugin then reads `serves=false` — **indistinguishable from healthy**.
5. **NEW AND DANGEROUS — never run `udevadm test` on a USB device path.** If a
   `RUN+=` rule fires, the Pi powers off and recovery needs physical presence.
   Recorded by `security`, which stopped before running it.
6. **NEW — `journalctl -u <unit>` drops `logger` output that `journalctl -t
   <tag>` shows.** It is why the kill-switch runbook's verification command
   printed nothing; the runbook now says so.

### An honest note on this audit's own independence, since the key demands it

Eight agents converged, but they read ONE brief, written by ONE session, from
ONE register. Their agreement is not eight independent readings, and the key
this run applied to the estate applies to the method. **Convergence counts only
where an agent arrived by an angle the brief did not hand it** — true for the
socket-proxy (reached by `network` and `security` separately) and for the Kuma
coupling (`services` and `observability` separately). Everything load-bearing
was re-measured by the main session, which is the only real control available.

---

## The run of 2026-09-19 (SEVENTH) — the key was `asymmetry`, and it paid in BOTH

The twenty-sixth key, taken off the proposed list rather than invented — the
file had recorded that only `asymmetry` and `cost` remained named. The question:
**does this mechanism work in BOTH directions?** All 112 classes asked whether
ONE thing is right, at what CADENCE (C44), at what GRAIN (C107), whether it
AGGREGATES (C103), where its EXPECTATION comes from (C111). None asked whether a
mechanism is symmetric.

**The register had already paid an instance of it without having the word.**
C112 measured that the estate sees a firewall opening LOST (~25 h) and never one
ADDED. Five admissible shapes went into all eight briefs — detection,
transition, peer coverage, authority, and cost-of-the-two-outcomes — with
`reversibility` EXCLUDED by name as a spent key, and eleven declared overlaps.
Six of eight domains returned an explicit "no mint".

### The counter: 1 OPEN in, 2 OPEN out, 3 minted, class total 112 -> 115

**The termination clock RESETS.** `commensurability` minted 0, `aggregation` 1,
`staleness` 1, `attendance` 2, `oracle` 2, `asymmetry` 3. The pair of
consecutive zero-mint runs has still never been achieved.

**The honest note this register always makes about itself**: declining the three
mints and keeping C113 out of the OPEN column would have shown 1 -> 1 and a
zero-mint run, which is the number this file exists to stop anyone from
manufacturing.

### The run's real output is C44's MEMBERSHIP, not a finding

Written above, 27 rows, 16 + 2 + 1 + 4 + 3 + 1, with the six blank rows filled
(`modprobe`, `sudoers`, `logrotate`, `timesyncd`, `hostname`, `swap`), two
candidates excluded with reasons, and **two reserves the agent volunteered
rather than let anyone discover**: its 16 is not provably the register's 16, and
its two thinnest rows are named so they can be contested. That is the difference
between a transcription and a fourth re-derivation.

### Live defects, ranked by what was happening without anyone knowing

1. **Transmission returned real 404s to real users, and nothing said so.** The
   healthcheck is `transmission-remote -ne -l` with a 5 s timeout; under CPU
   contention it times out, Traefik drops any non-`healthy` container from its
   dynamic config, and the next request hits no router — a proxy 404, 19 bytes,
   0 ms, no backend. **74 unhealthy seconds measured, all inside one hour, zero
   in the other 23**, and the windows cover all five 404s to the second, with
   two further windows producing no 404 because no Kuma beat fell inside them —
   which is the control the mechanism needed. The alarm requires `min -10m`
   against an actuator acting in seconds: **0 alarm transitions over seven
   episodes.** The monitor goes PENDING, which escalates with the wrong text.
   **The operator identified the load as Transmission downloading and declined
   any change** — a better explanation than the audit-load hypothesis the
   session was carrying. Recorded in `settled.md`, not fixed.
2. **Three live secret files were absent from the rotation runbook.** 16 files,
   a table naming 14 of them. **The main session downgraded the finding while
   fixing it**: the agent reported the Nextcloud Redis pair as a rotate-one-
   forget-the-other hazard; reading `secrets.yml` shows both files are rendered
   from ONE vault value with all three writes notifying the same restart, and
   `searxng_settings` is templated from `searxng_secret_key`. The real gap is
   that a reader of that table would not know to rotate them at all. FIXED.
3. **The offsite undervoltage detector** — see C44's instances above. FIXED.
4. **Five files whose only copy sat inside an excluded archive.** The calibre
   staging exclusion rested on "every byte of it is a second copy of a book
   already backed up under media/books" — verified in the direction "these were
   ingested" and never in the other. Measured against the 417 files of
   `media/books`: of 11 PDFs in `converted/`, 6 have their PDF there, 4 exist as
   EPUB only, **and one book is not in the library in any format**. The main
   session's own count is 5, not the agent's 4. FIXED, 96 MB.
5. **Five sites said the wg-easy UI is reachable only through an SSH tunnel**
   while Traefik has served it at `vpn.<domain>` since the router was added
   twenty lines below the comment that denies it. LAN + VPN, not the internet —
   not a perimeter hole, but `ssh-lockout-recovery.md` loses a path and CIS
   5.1.8 was declined on that premise. FIXED; the decision kept, its stated
   reason replaced.
6. **C07 WIDENED and the collector it immediately found.** The gate certified
   ONE collector against a fleet. Keying on CONTEXT was measured not to work
   ((context -> update_every) is not a function). Keying on PLUGIN does, with no
   hand-chosen constant: *no plugin whose charts feed no curated alarm may
   collect more samples/s than the busiest plugin that does*. Made to fail on
   purpose in **five** directions on the live host, including the control that
   matters — a consumer list containing a cgroup context returns OK, proving the
   rule is not structurally stuck red. Retroactive positive control: applied to
   2026-09-17 it marks `apps.plugin`. It found `cgroups.plugin`, 1002 charts at
   1 s = 1002 samples/s against `proc.plugin`'s 536.2, with **zero** consumers.
   Set to 5 s (200.4). **Deployed and green: `ok 316`, goss plan 409 -> 410.**
7. **`homelab-image-retention` was documented nowhere**, and is absent from the
   "16 periodic jobs" census because that census walks the evidence channels —
   a job with no channel cannot appear in it. From October a thinned image list
   has a second, benign cause next to the "never wipe the store" rule. FIXED.
8. Six live sites still carried the pre-2026-09-12 offsite cadence, two of them
   contradicting themselves seventy lines apart; `offsite-backup.md` handed the
   operator an `ls` that cannot read `snapshots/` and does not error visibly —
   `wc -l` still prints a small number, which on a recovery page reads as an
   almost-empty repository. Three ADR citations pointed at the wrong ADR, two on
   the disaster-recovery path. All FIXED.

### Rejected, requalified, or corrected — 6, and three were the main session's own

- **`system`'s cadence for the undervoltage check, wrong by a factor of 7.**
  Corrected above. The finding survives comprehensively; the attribution did not.
- **`system`'s proposed remedy named `dev_notice` and "Under-voltage detected!"**.
  The kernel emits `dev_crit "Undervoltage detected!"` and `dev_info "Voltage
  normalised"`. A grep for the agent's string would have found nothing,
  silently — the exact defect being fixed. Strings were then read out of the
  shipped module binary rather than from upstream source.
- **`services`'s "the 404s cluster on audit days".** The event counts are right;
  the per-day RATES are not comparable, because Kuma retains only `important`
  beats beyond its window, so old days show transitions and not samples. And
  2026-09-18 was an audit day with zero events, which the agent did not mention.
- **`ansible-deploy` correctly rejected its own most spectacular finding**: 180
  of 183 created paths with no removal counterpart, which `roles/base/tasks/
  retired.yml:1-25` writes down word for word as a known weakness. C88, not a
  finding. It also declared an unreconciled count (133 options against the
  brief's 156) rather than adopting the brief's number.
- **`security` declined to propose anything for "nothing observes that a
  fail2ban filter still MATCHES"**, on the ground that the only honest check
  needs a deliberate authentication failure, which the operator has declined —
  and that a frozen sample would be self-certifying. Correct call, recorded.
- **The main session's own secret finding, downgraded while being fixed** (#2
  above).

### Instrument traps paid — 2, and BOTH were the main session's

1. **An un-`sudo`'d glob over a root-only directory expanded to nothing —
   FOURTH payment, by the session whose own brief carries the warning.**
   `sudo grep /etc/goss/*.yaml` returned "No such file"; the glob expands in the
   unprivileged shell before `sudo` runs. Re-done as `sudo sh -c`, with a
   positive control.
2. **A positive control inside the instrument's horizon proves nothing about its
   reach — NEW IN KIND.** Hunting container events in the 404 window, the main
   session read "zero events" and nearly concluded no health transition had
   occurred. Docker's event buffer reaches back **2 min 30 s**; the control
   window was inside it and therefore only proved the instrument works NOW.
   **A control must be comparable to the question in the dimension that matters
   — here age, not validity.** Re-done against netdata, which has memory, and
   the answer inverted: 74 unhealthy seconds, covering all five 404s.

### Register corrections — 4

- **The clock admission was rejected against the wrong path.** See above.
  `timesyncd` IS TIER A.
- **C07's "there is no cheap route" is true of the CONTEXT axis and false of the
  PLUGIN axis.** `netdata.conf` renders `[plugin:X] update every` for 58
  sections, 23.9 KB, 0.23 s.
- **The "per-monitor line budget" this file records as confirmed in the FOURTH
  run's instrument-traps section is REFUTED** (cited by description, not by line
  number, because every insertion above it moves the number). At the same instant, monitor 13 (60 s) holds 2618 lines over 43.6 h
  and monitor 20 (push, 300 s) holds 526 over **43.6 h** — same duration, five
  times fewer lines. The inferred model is a ~43.6 h window floored at ~100
  lines. The deployed comment's CONCLUSION stays true; its MECHANISM is wrong.
- **C30's row says the deny direction has no reproducible instrument. It does.**
  `network` reproduced it: 403, 9 bytes, `Forbidden`, with an admitted source
  returning 200 as the control.

### Clean, and measured — the negatives that closed questions

WireGuard peers 4/4 in BOTH directions, a real set equality with famine guards
on both sides. The external perimeter unchanged, probed from the offsite uplink
after checking `ip route get` (it leaves by the ISP, not the tunnel), with two
positive controls — 51413 open on the target itself and 1.1.1.1:443 — and
443/80/22/53/8080/3001 closed. C14 HOLDS and was widened by measurement: the
three directions `-enddate` does not read (SAN, CN, issuer, chain, key-cert
match) are 21/21 for 5.0 s inside a block already guarded by mtime; zero orphan
certificates. Outbound SSH EMPTY on both hosts — 0 private keys, 0
`known_hosts`, root `authorized_keys` 0 bytes: **the offsite cannot act on the
homelab.** 32/32 container bijection, declared-minus-live and live-minus-
declared both 0. 135 Ansible keys, 0 dead knobs; 41 handlers, 0 orphan
`notify:`; `changed_when: false` INTERSECT `notify:` is EMPTY, verified with a
synthetic positive control because the control on the repo itself returned zero.
The 12 local branches are entirely in `main` — `git branch --merged` says
otherwise only because this repo rebases, and `git cherry` by patch-id shows 0
unapplied commits. 25 of 36 ADRs carry an "alternatives rejected" section, so
the estate does write its negative decisions down: the three agents who reported
ADR-030 and "Netdata notifies nobody" as gaps were not reading the repository.
**Zero broken gates.**

## The run of 2026-09-19 (SIXTH) — the key was `oracle`, and it paid in the ASSERTIONS

The twenty-fifth key, **invented rather than taken off the proposed list** — the
file had recorded that no named candidate remained but `asymmetry` and `cost`.
The question: **where does this check get its notion of CORRECT, and what
updates that notion?** The register had no vocabulary for it. All 110 classes
asked whether a mechanism RUNS, at what CADENCE (C44), at what GRAIN (C107),
whether it AGGREGATES (C103), whether its value has gone STALE, whether anyone
READS it. Not one asked where its EXPECTED VALUE comes from, who owns that
expectation, and what would ever revise it.

Five admissible shapes went into all eight briefs: (a) the literal with an
absent author; (b) the tautological oracle — expected and observed derived from
the same source; (c) the frozen baseline — a list where a derivation belongs;
(d) the borrowed oracle — correctness delegated to a third party that can stop
answering meaningfully; (e) the missing oracle — a quantity published with no
statement of what would be wrong. **Nine overlaps were declared instance-only**
(C107, C103, C83, C13, C93, C45, C76, C39, C109/C110) and the discipline held:
five of eight domains returned an explicit "no mint".

### The counter: 1 OPEN in, 1 OPEN out, 2 minted, class total 110 -> 112

**The termination clock RESETS.** `commensurability` minted 0, `aggregation` 1,
`staleness` 1, `attendance` 2, `oracle` 2. The pair of consecutive zero-mint
runs has still never been achieved.

**C109 and C110 were ACCEPTED by the operator this run** and are ENUMERATED.

### C111 — MINTED, and it is the run's real output

**An assertion whose expected value is regenerated from the same declaration
that produces the state it observes** — so the assertion mirrors the estate's
state rather than its intent, and cannot detect a weakening. Shape (b), on the
most load-bearing spec in the estate.

Space: the four generated specs. Cardinal, measured by `ansible-deploy` and
**re-measured by the main session on the deployed artefact**: `/etc/goss/
posture.yaml` is **226 named checks** (goss's plan count of 406 counts each
`stdout:` pattern separately — both figures are real and this file has conflated
them once already). **108/226 have an oracle independent of any declaration,
115/226 mirror one, 3 are hand-lists.** Of the 171 per-container checks
generated from `compose.yaml`, 64 carry an independent literal intent and **107
mirror compose**.

**The instance that makes it concrete, parsed block by block on the live file:**

    9  -read-only-rootfs checks assert ["/^false$/"]
    23 -read-only-rootfs checks assert ["/^true$/"]
    32 total

Plus 2 `-no-new-privileges` asserting `false` and 16 `-cap-add` asserting a
specific set. **27 checks that can only turn RED if somebody HARDENS a service.**
Remove `read_only: true` from any of the 23 and the assertion regenerates as
`/^false$/`, 226/226 still green.

**Two agents reached it from opposite ends with no contact**, which this
register names as its strongest evidence standard — and both readings are
correct, which is the point. `security` read the mechanism as a VIRTUE (C11 is
DERIVED: the spec carries exactly 9 `-user:` assertions for the 9 services
declaring `user:`, so a new container is picked up with no edit). `ansible-deploy`
read it as a FAULT (those same checks sit inside `{% if %}`; delete the
declaration and the check CEASES TO EXIST, 226 -> 225, with nothing asserting
the count). **Derivation from the declaration is simultaneously what makes the
gate self-maintaining and what makes it self-certifying. That tension is the
class.**

### C112 — MINTED

**A guarantee whose ENFORCER sits outside every host the estate can run a
command on, where the apparently-covering assertion is bound to an internal
proxy and stays green through the enforcer's failure.** Shape (e) applied to
authority rather than to a value. `network` bounded it by naming the enforcer
per guarantee in `docs/` and the ADRs and keeping the off-estate ones:
**5 in network — 2 unfalsifiable, 1 partial, 2 falsifiable.**

The two unfalsifiable: the router's forward table **in the negative direction**
(`ufw-enforces-every-rule-the-inventory-declares` is ALLOW-only, and 80/443/53
are already in its ALLOW set, so a router reset that republished them stays
green), and the Cloudflare zone (DDNS looks up one name; nothing enumerates the
zone). **The honest counterweight, recorded because it bounds the damage: the
POSITIVE direction IS falsifiable** — the offsite's only channel is the tunnel,
so a lost opening reddens Kuma #18 within ~25 h. **The estate can see a lost
opening and never an added one.**

This is the generalisation of C32's standing observation that the perimeter is
an ATTENDANCE and not a derivation, and it explains why C32 could never close.

### A third candidate, PROPOSED and correctly NOT CLAIMED

`backup`'s *a recovery procedure whose success criterion is that its last
command completed, with no stated expected RESULT* — swept **11/11 restore
procedures in `restore-from-backup.md`: 6 carry no post-restore check at all
(Vaultwarden among them), 5 do, and 0 of 11 state an expected VALUE.** The agent
itself declined to claim it: the whole-estate cardinal is not derived, the sweep
covering one file of ~17 runbooks. **Recorded as a property with a bounded
domain sweep, not a class.** It is the next run's cheapest mint if anyone bounds
the remaining runbooks.

### Live defects, ranked by what was happening without anyone knowing

1. **A safety argument falsified 18 hours earlier, by a commit of that morning
   — C52, and its bound was wrong.** Commit `8763306` (2026-09-19 01:55) added
   `TZ: ${TZ}` to vaultwarden; the container now runs CEST. `jail.local:104`
   still carried `logtimezone = UTC`, and **the comment above it stated its own
   premise**: *"its container runs on UTC while this host runs on CEST"*. C52 is
   "a safety argument whose premise is a defect that has just been corrected" —
   this fits word for word. **The exposure was LATENT, not active**, and the
   main session established that where the agent had not: log mtime
   2026-09-18 21:22:49, 3 lines, all pre-change, `Total failed: 0`. The defect
   armed itself at the next line written. **Bound correction that matters: C52
   was swept 9/9 over 151 candidate ARGUMENTS; this is a live DIRECTIVE. The
   class's space was bounded by a MECHANISM while its property is not** — the
   register's recurring trap, paid again. **FIXED.**
2. **A frozen floor with 30 % slack that cannot see a collector die.**
   `netdata_min_contexts: 270` against a live 383, set by #24 in July, revised by
   nothing. Measured distribution: netdata 137, system 43, ipv6 26, cgroup 25,
   ipv4 24, mem 23, usergroup 14, user 14, app 14, ip 13, disk 13, net 11,
   systemd 7, docker 6, disk_ext 6, anomaly_detection 5, netfilter 1, cpufreq 1.
   **The whole container-observability set (cgroup + docker + app + disk = 58)
   could vanish and the count would sit at 325, above the floor** — while the two
   curated alarms that depend on the docker collector stopped evaluating.
   **FIXED, and by a DERIVATION rather than a better literal**: the new check
   reads the `on:` line of every installed curated alarm file and asserts netdata
   still serves that context. Six contexts derived live, all present; made to
   fail on purpose in three directions (absent context, empty API answer,
   substring-vs-exact).
3. **One container can run and do nothing with every indicator green.** The
   agent reported "11 of 32 containers are the subject of no monitor". **The main
   session cut that to 1.** `homelab_container_down` and
   `homelab_container_unhealthy` each cover 32/32 (monitor 37's live beat says
   so), and of the 4 containers declaring no healthcheck — nextcloud-cron,
   nextcloud-notify-push, dnsproxy, searxng — three have a dedicated monitor or
   a daily assertion. **`nextcloud-cron` alone has no healthcheck, no monitor and
   no assertion.** FIXED with a FUNCTIONAL check (`core lastcron` age), not a
   liveness one — made to fail on purpose in three directions, including the one
   that matters: an error string strips to empty and aborts rather than being
   misread as a timestamp.
4. **The observability monitor table named a monitor that does not exist.**
   `docs/07-observability/README.md:154` listed **Pi services**; the live
   enumeration has no such monitor. It also attributed "marginal sector" to
   **Pi pending action** when `homelab-disk.sh` reports it (live beat:
   `pending 2`), and said "three to create by hand" when there are five.
   **Requalified by the main session and the requalification matters: this is a
   documentation error, not a blind spot.** The disk does carry 2 pending
   sectors and they ARE reported daily, by the right monitor, with a deliberate
   implementation referencing #207. FIXED, with a "Fed by" column added so the
   table cannot read as coverage again.
5. **Every repo-authored gate runs on the developer's machine only.**
   `.github/workflows/lint.yml:2` claims it "mirrors the local pre-commit hooks
   so a bypassed hook (`--no-verify`, GitHub web edits) still gets caught on the
   PR". It ran gitleaks, yamllint and ansible-lint — **1 of 10 `repo: local`
   hooks**. Every class GATED on a pre-commit hook was gated locally only, and
   `--no-verify` is this repo's own documented GPG-timeout remedy. FIXED: all
   nine `ops/check-*.py` entry points and the three selftests now run in CI,
   verified passing locally first.
6. **ADR-010 understated the offsite by a factor of seven.** It said the push is
   *weekly* and that the Pi *only* self-reports disk health. Measured:
   `OnCalendar=*-*-* 08:00` (daily since 2026-09-12) and 33 named checks in
   `/etc/goss/offsite-health.yaml`, `append-only` among them. **A recovery reader
   would have accepted a 7-day silence as normal.** FIXED, and the count
   deliberately NOT written into the ADR — it names the file instead.
7. **Dozzle in three versions.** Doc `v10.6.14`, compose `v11.1.0`, running
   `v11.0.1`. `v11.1.0` confirmed latest upstream (published 2026-09-14), so the
   compose↔host half is a pending pin, not a stale pin. Doc FIXED; pin deployed.

### The finding that was REJECTED because the repo had already decided it — and this is the run's discipline result

`ansible-deploy` proposed "~6 lines fix all 11" for the checks that vanish with
their declaration. **The main session read the template before editing and found
the fix already tried and reverted**, with the reasoning in place at
`goss-posture.yaml.j2:548-560`:

> Conditional on purpose, and the reason was learned the hard way on 2026-09-05.
> This assertion was briefly emitted for EVERY service, asserting `/^$/` for
> those declaring no `user:` [...] It is wrong: `Config.User` carries the IMAGE's
> user when compose declares none, and two of ours do — socket-proxy returns
> `root`, collabora returns `1001`. [...] the gap does not close by assertion
> anyway [...] What catches that is the review of compose.yaml, not a probe of
> the result.

**So the "easy fix" for C111 does not exist, and the reason is measured and on
file.** C111's real remedy is an INTENT DECLARATION separate from the
configuration — the `declared intent vs effective state` pattern the estate
already ships for sshd, sysctl, postfix and ufw. That is a design change, it was
put to the operator as such, and nothing was built on a guess.

### Rejected, requalified, or corrected — 6, and two were the main session's own brief

- **`observability`'s headline, "60 alarms evaluate and can reach nobody".**
  Measurement right, conclusion wrong: `group_vars/all.yml:308` states *"Netdata
  notifies NOBODY — stock alarms and curated ones alike"*, ADR-030, with the
  Kuma adapter as the single channel. **Third time an agent has reported a
  written decision as a gap.** The residual that IS the key's shape: the
  MEMBERSHIP of the curated 6 is a hand-written list with no revision event.
- **`observability`'s "9 names / 187 instances are literally decorative".**
  REJECTED. They are intermediate calculation alarms consumed by siblings —
  `disk_fill_rate` -> `disks.conf`, `load_cpu_number` -> `load.conf`,
  `1m_received_packets_rate` -> `net.conf`. They are exactly the alarms whose
  recipient is `root`, which should have prompted the check.
- **`observability`'s disk-coverage gap.** Half true, and the half that mattered
  is false: `homelab-health.sh:234` is `for fs in / /mnt/data`, threshold 85,
  and monitor 20's beat reads `/ 19%, /mnt/data 21%`. The script's own comment
  anticipates the objection.
- **`project-manager`'s pending-sector finding**, requalified from blind spot to
  documentation error (above).
- **`project-manager`'s 24 offsite assertions** — the main session measured 33
  named checks. Different counting rules; the ADR now names the file instead.
- **The main session's own brief, twice.** It labelled Kuma monitor 8 a live
  shape-(d) instance; `network` measured `dns_resolve_server=192.168.1.100` AND
  `conditions=[record equals 192.168.1.100]` and killed it — **the register's
  text describes a hazard of REBUILDING from a dump, not the live state.** And
  the brief said "32 containers, 30 reporting healthy"; `services` corrected it
  to 28 declaring a healthcheck, all 28 healthy, 4 declaring none.

### An agent disagreement, resolved rather than dropped

`services` measured the *arr Kuma keyword `OK` as DISCRIMINATING (0 occurrences
in the UI and in unknown-route final pages, all three). `observability` found
Prowlarr/Sonarr/Radarr all expect the same 2-char `OK`, so a MISROUTE between
them stays green. **Both are true about different failure modes**: `OK`
discriminates a broken service and fails to discriminate a misdirected one.
Recorded as one finding with two halves.

### Instrument traps paid — 4, and three were the main session's own

1. **A `grep -A4` context window on a 5-line block silently truncated the line
   under investigation** and returned a false "`logtimezone` not deployed". **A
   context window is as wrong as a loose regex and it fails silently in the
   direction of a clean result.** New in kind; the fifth run's version was an
   alternation, this one is a window.
2. **A positive control that itself returns zero is not a control.** Hunting a
   root-filesystem assertion in `/etc/goss/*.yaml`, the main session's control
   was `grep -c "title:"` — and those specs do not use `title:`. The null result
   was uninformative, not negative. Re-run with `grep -c "command:"` (=1, file
   192 290 bytes) it finally meant something. The oldest rule in this file, paid
   by the session enforcing it.
3. **An awk that keys on the last-seen name bleeds across block boundaries.**
   Counting `-read-only-rootfs` expectations by proximity gave "1 false + 2 true"
   per service — arithmetically impossible against one check per service. Re-done
   by parsing each block to its own `stdout:` line: 9 false, 23 true, 32 total.

4. **An un-`sudo`'d glob over a root-only directory expands to nothing — third
   payment, and this one by the session that had put the warning in its own
   brief.** Verifying the deployed context check, the main session ran the
   extracted body as the normal user; `health.d/` is root-only, the glob matched
   nothing, and the check reported "no curated alarm declares a context". Under
   root — how goss runs it — all six contexts derive and it exits 0. **The check's
   empty-set floor caught the condition and failed loudly rather than passing
   vacuously, which is a stronger proof that it works than the three deliberate
   controls written before it.**

### Disclosures by agents, all unprompted — 2 of 8

`services` left `/tmp/binds.txt` on homelab and created-then-deleted `/tmp/_ui`
and `/tmp/_unk` inside prowlarr/sonarr/radarr, re-running the measurement
without temp files to the identical result. `system` created and deleted
`/tmp/di.json`. `observability` explicitly did NOT repeat its previous run's
netdata `/tmp` write. **The rule-5 disclosure culture is holding.**

### Clean, and measured — the negatives that closed questions

`argument_specs`: 156 options over 11 roles with **zero** `choices`/`min`/`max`/
`pattern`/`default`, so no value constraint exists and none can be wrong. There
are **no `roles/*/defaults/` at all** — every default sits in one 744-line
`group_vars/all.yml`. All 14 `assert:` tasks read and **none is tautological**;
`stack-startup:28` and `backup.yml:109` are real comparators. 25
`failed_when: false`, all on state-reading probes, no swallowed error. C14
DERIVED and confirmed twice — but **it reads `-enddate` ONLY**, so 21/21 watched
for expiry is not 21/21 verified correct. C15 and C18 both DERIVED (C18 at
46/46, TAP `1..46`). C41 DERIVED. C11 DERIVED 9/9. ADR sweep: **36 ADRs, 30 read
in full, 116 runtime promises, 113 confronted -> 108 HOLD, 0 BROKEN, 5 stale, 3
unverifiable** — and the class the brief sent it hunting is FIXED
(`feed-digest.sh.j2:349` now appends the carried-over count). 113/113 relative
links, 18/18 cited systemd units, 80/80 bind mounts. **The best oracle in the
estate, worth naming: `netdata-apparmor-matches-dockerd` extracts
docker-default's deny rules from the `dockerd` BINARY and requires the local
profile to be a superset — the only check of 226 whose expectation is revised by
an event outside this repository.**

## The run of 2026-09-19 (FIFTH) — the key was `attendance`, and it paid in the ESTATE

The twenty-fourth key, **chosen by the operator from a proposed list**. The
question: **which guarantee depends on a human act that nothing schedules,
nothing records, and whose absence nothing notices?** The register had no
vocabulary for the manual step — all 108 classes describe machines — and that is
exactly why it paid. `staleness` and `commensurability` both bit on the
instruments; **this one bit on the estate.**

Five admissible shapes went into all eight briefs: (a) a manual step whose
absence leaves no trace; (b) an approval or review queue nothing relaunches and
nothing ages; (c) an output produced for a human reader whose readership nothing
measures; (d) state only a UI or a hand can create, absent from every export;
(e) a guarantee assuming human presence within a delay that is neither bounded
nor measured. **Seven overlaps were declared instance-only** (C45, C69, C85,
C101, C102, C103, C107) and the discipline held.

### The counter: 1 OPEN in, 1 OPEN out, 2 mints PROPOSED, class total 108 -> 110

**The termination clock RESETS.** `commensurability` minted 0, `aggregation` 1,
`staleness` 1, `attendance` 2. The pair of consecutive zero-mint runs has still
never been achieved.

### C44 — STILL OPEN, and its cardinal moved the right way

`system` executed the seven TIER A lines the fourth run had named without
running. **19/19 now read, drift 0 of 19.** Two admissions did not survive
execution: **#15 `resolved`** (`resolvectl status` does not read
`DNSStubListener`, its only declared key -> TIER B) and **#16 DOCKER-USER**
(8/8 conformant, but `iptables-save` normalises `-s` before `-p` and inserts
`-m udp`, so a literal comparator gives 8 false positives of 8 — the same
predicate (iii) that excluded systemd -> TIER C). **#13 firmware** keeps its
place with a corrected resolver: `vcgencmd get_config` returns no
dtparam/dtoverlay; `/proc/device-tree/soc/*/status` resolves it.

**TIER A = 17, not 19. Coverage 4/17 = 24 %. The question "is every subsystem
with a resolve-everything readout covered" still answers NO**, so the class must
not be closed by arbitration. 13 TIER A subsystems carry no continuous
assertion, all conformant today. Both reserves confirmed live: `pam` still has no
resolver, and `homelab-posture.timer` is daily, so C44 applies to its own output
over a 24 h window.

### The two mints — PROPOSED, arbitration OUTSTANDING

**Five of eight agents proposed a class and they cluster into two properties.
Neither contains the other**, which is why the main session recommends two
rather than one or three.

**C109 — the channel cannot represent the duty.** *An obligation borne by a
human, whose discharge changes no machine-readable state, and which the estate's
only "awaiting a human" channel therefore cannot represent — so its universal
negative means "none of the six I was told about".* The mechanism is literal:
`homelab-health.sh.j2:820` pushes `up "nothing waiting on a human"`, and
membership is **6 hand-written `pending+=()` sites over 4 machine states**
(reboot-required, journal skew x3, security updates, certificate expiry).
Reached from three unrelated directions — `security` (space bounded by 17
runbooks + 5 operator commands, swept **17/17**, 12 out of space, 5 in),
`backup` (**7/7** in its domain, 3 monitored, 4 not) and `services` (from the
publishing side). **Three independent derivations of one live mechanism is this
register's strongest evidence standard.** Enumerative bound, so it would arrive
ENUMERATED, never GATED.

**C110 — the trigger is stated and nothing watches it.** *A stated trigger — a
deadline or a condition — for an action only a human performs, with no deployed
instrument evaluating it, so "on time", "overdue" and "never done once" come out
identical.* Bounded from both sides independently: `ansible-deploy` on the clock
axis (**N=5** time-bounded operator obligations, swept 5/5, covered **0/5**) and
`project-manager` **and** `network` on the event axis, arriving at the same
property with no contact (**N=15**, 7 mechanically observable, covered **0/7**;
`network` counted 10 statements / 9 distinct conditions / 5 countable / 0
instrumented / **2 already triggered**). Positive control recorded:
`goss-offsite-health.yaml.j2:515` proves the repo knows how to annotate.

**A third candidate was proposed and correctly NOT claimed** by `observability`
— *a discriminant computed and published that no programmatic consumer reads* —
on the honest ground that only 2 of its 48-quantity space were verified. It
proposes attaching to C103 as a residual of C103's own remedy.

### Live defects, ranked by what was happening without anyone knowing

1. **The "nothing waiting on a human" monitor, green over a hand-list of six.**
   C109's exemplar. The sharpest instance: the **USB tamper armed state is
   asserted nowhere** — 0 strict matches across the three goss specs,
   `homelab-health.sh` and all 37 monitors, positive control passed. A disarm
   never followed by a re-arm silences ADR-008 unboundedly. **DECLINED by the
   operator 2026-09-19 — see the DECLINED list.**
2. **C07 still red, and the recorded remedy is invalid** — see C07's corrected
   section above. `cgroups.plugin` 995 charts at 1 s (6.54 % of a core),
   `proc.plugin` 531 charts at 1 s named nowhere.
3. **The offsite deep check advertised "quarterly" has never run once.**
   Requalified by the main session and this matters: the `offsite` profile is
   **deliberately metadata-only and says so in writing**. The defect is the
   runbook heading claiming a cadence nothing implements, on the only repository
   that survives a homelab loss. **Fixed as documentation.**
4. **Renovate: uptime-kuma 2.x pending approval for 24 days** — and the package
   IS the supervision (2.5.0 running, 5 patches behind). The bot rewrites issue
   #8's body continuously (`updatedAt` 2026-09-19 13:43), **so every GitHub
   freshness signal dates the rewrite and never the wait.** 0 references in
   `ansible/`, `docker/`, `ops/`, `.github/`. **Shipped: 2.5.0 -> 2.5.5.**
5. **Nextcloud's app surface — and the finding sharpened under the fix.** See
   the dedicated section below; it is the run's best single result.
6. **The posture provenance field has 0 programmatic consumers** — produced in 2
   places, read by 0, control passed. **DECLINED by the operator 2026-09-19.**
7. **Nothing links the 32 services to the 37 monitors.** 3 clauses read the
   `monitor` table, none reads coverage; the only inventory is a hand-written
   `.secrets/kuma-dump.json` of 09-13 that no timer schedules or ages. Drift
   zero today, so latent.
8. **C108's gate has only ever run manually.** Spec mtime 13:54, last scheduled
   run 11:07, the 14:21:33 run manual. Its promotion condition is unmet; first
   real chance 2026-09-20 11:01. The two divergences themselves are **resolved,
   32/32, 0 divergence**.
9. **No secret rotation is dated.** 23 files, 4 assertions that a rotated secret
   REACHES its consumer, 0 saying one rotated. Sharpest: `cf_dns_api_token`, the
   only credential exploitable from the open internet, whose mtime is the
   signature of a creation and not a rotation.

### The Nextcloud app surface — the finding got SHARPER while being fixed

The operator chose a counter in the existing Nextcloud beat. **Implementing it
proved the counter would have been vacuous by construction**, and that is the
better finding:

- `appstoreenabled` is **false**, set deliberately at
  `ansible/roles/deploy/tasks/nextcloud.yml:78` on 2026-09-18 for a measured
  reason (a nightly failing fetch writing a 10.17 MB Guzzle trace into the file
  the fail2ban jail re-reads).
- So `occ app:update --all --showonly` can **never** find an update. Its
  reassuring sentence — *"All apps are up-to-date or no updates could be
  found"* — is always the second clause. **The tool states its own ambiguity and
  the estate reads it as the first clause.**
- The repo's own comment says apps *"are pinned in the image and the runbook
  updates them with occ"*. **That is false for exactly the two that matter**:
  `richdocuments` 11.1.1 and `libresign` 14.1.0 live in **`custom_apps`** —
  persisted on disk, not in the image — verified inside the container.
- ADR-022:179 already recorded *"Renovate does not see this"*.

**So those two apps are updated by nothing, watched by nothing, and the written
mechanism that would excuse it does not apply to them.** `collabora.yml:80` also
runs `occ app:install richdocuments`, which needs the appstore that is now off —
a rebuild-from-scratch hazard. Arbitration outstanding.

### Rejected, requalified, or corrected — 6, and three were the main session's own

- **The main session's own baseline.** "Last posture run 11:07" was the last
  SCHEDULED run; the last run of any kind was **14:21:33** (manual, 101 s,
  exit 0). Three agents caught it independently. The trap worked as designed.
- **The main session's own tamper measurement.** Its grep alternated
  `tamper|armed|disarm` and matched control-timer and fsck vocabulary, returning
  a misleading 6. On `tamper` strict it is **0**, and `security` was right.
  **An alternation is only as precise as its loosest term.**
- **The main session's own brief**, on one point: it presented C22/C24/C25/C36/
  C38/C40/C47/C48 as GATED assertions. **They are ENUMERATED.** `services`
  corrected it, and its finding stands — none carries a deployed assertion, and
  only C38 is structurally derived.
- **`ansible-deploy`'s and `backup`'s first framing of the offsite check.** The
  missing `--read-data` is a written, deliberate decision, not a gap. Both landed
  on the right remedy; the headline as first stated would have misled.
- **`security`'s lynis date.** 2026-09-15 00:30:30, not 09-14, and scheduled
  (`LastTriggerUSec` agrees). Conclusion unaffected: the naming code deployed
  13:54 today has still never executed, next run 09-22.
- **`observability`'s Kuma-retention framing** was already settled by the fourth
  run and was not re-litigated.

### Instrument traps paid — 7, and two were the main session's own

1. **An alternation regex is as loose as its loosest term** — the main session's
   `tamper|armed|disarm` (above).
2. **The main session broke its own rule 6**: a `journalctl` over four months
   exceeded 120 s on a Pi carrying eight agents. Result discarded; the evidence
   came from the configuration instead.
3. **`git branch --no-merged` lies in a rebase-only repository** — it announced
   10 branches and 48 commits ahead; `git cherry` proved **48/48 already
   landed**, zero unmerged work.
4. **`last -x reboot` is corrupted by the absent RTC** — only lines cross-checked
   against `dpkg.log` are usable.
5. **netdata's light endpoints do not carry `update_every`** — `/api/v1|v2|v3/
   contexts`, 95–130 KB, **383/383 missing**. There is no cheap route; it is
   `/api/v1/charts`, 5.3 MB, 0.74 s.
6. **`grep -c " 429 "` over a CLF log overcounts 2.1x** — the trailing 429 of a
   CLF line is the request count, not the status. The anchored form
   `'" 429 [0-9]+ '` gives the true **14 in 17.7 days** (0.0023 %).
7. **A `sudo grep /etc/goss/*.yaml` fails with "No such file"** — the glob is
   resolved before `sudo`. Re-paid live, already on file.

### A rule-5 violation, self-declared by the agent that committed it

`observability` wrote 5.3 MB into the netdata container's `/tmp` on its first
query, removed it, and re-derived the one result it could have biased. **It
disclosed this unprompted**, which is the behaviour these briefs want. The main
session re-measured the load-bearing conclusion afterwards, and the `/tmp` charts
still read `update_every=5` after the cleanup, so the C07 correction is
structural and not induced.

### The register lied about itself in SIX places — all corrected in this run

And the failure mode is now unmistakable and unchanged from the fourth run:
**cardinal corrections are written into the run narration and never carried into
the tables.**

1. **`(context -> update_every)` is not a function** — reverses the fourth run's
   "decisive new fact". Verified twice, with a reachability control.
2. **C44, the register's ONLY OPEN class, sat in the ENUMERATED table** with a
   stale `13/13 timers` and without the "left this table" pointer C01/C10/C12/
   C17/C20 all carry. Anyone reading that table concluded C44 was closed.
3. **C24, C25, C36, C38, C53 carried pre-correction cardinals** in the ENUMERATED
   table while the corrections sat in prose.
4. **The heading "Instrument traps paid — 2, both new" listed three.**
5. **`settled.md` said "~460 KB"** for a register measured at **658 KB** — and
   that figure is the ARGUMENT of the deferred item about moving the register out
   of the public repository, so the understatement weakened its own case by 43 %.
6. **C21 was GATED and is not a gate.** Measured: of 3 463 lines of deployed
   posture, one assertion opens `resticprofile.yaml` and reads only the
   `library/` categories; nothing reads `copy:`. **Downgraded to ENUMERATED.**

**C50 is flagged rather than corrected**: its Docker half is 28, not 25, but its
Kuma half and its 62 total were not re-derived and must not be quoted until they
are.

### Clean, and measured — the negatives that closed questions

Thermal margin 37 K with `get_throttled = 0x0` sticky bits included; 49 % memory
available; swap flat at 50.4 % (containers never restarted since the boot, so
cold pages, not drift). **The tightest margin is I/O: PSI io `full` at 2.56 % of
wall time over 7 d 16 h — a continuous baseline, not a peak.** 16/16 static
artefacts repo-to-homelab identical. **C14 DERIVED 21/21** and the human gesture
the brief hunted in the TLS chain **does not exist** — the Cloudflare token
carries no expiry. **C30 closed in its second direction for the first time**:
24/24 routers, 22/22 middlewares at the entry point, **6/6 declared middlewares
actually used, 0 orphans**. **C31 is 21/21, not the 18/18 its row carried.**
C15 verified DERIVED. fail2ban clean (3 jails, 0 bans), 4 WireGuard peers all
attributable, 0 paused monitors, 0 without a recipient, log rotation 32/32, no
data outside a backed-up path, 97 offsite snapshots. **Shape (e) has no instance
on the supervision side** — every retry delay is bounded.

### C32 is neither derived nor a list — it is an attendance

`network`'s mandate-2 result, and it is the sharpest negative of the run. The
perimeter was probed from the offsite uplink **with two positive controls**
(51413/tcp OPEN, 51820/udp reachable): 80, 443, **53** and the SSH port all
closed. **But nothing on the estate can produce that measurement.**
`ufw-enforces-every-rule-the-inventory-declares` would stay green through a
router reset that republished 80/443/53, because all three are already in its
ALLOW set. `docs/04-network/README.md:200` states the guarantee as a fact with no
date.

### Two live residuals recorded without a remedy

- **The Pi-hole bypass rule's written remedy is not executable.** It orders
  matching BY MAC, but pihole sits on a Docker bridge with no L2 adjacency:
  **10 known LAN clients, 0 with a learned MAC**, so a MAC rule has nothing to
  compare. Still latent (lease stable 127 days); `ip neigh` is the wrong
  instrument, the FTL database is the right one.
- **The DNS-01 credential exists in two copies in two grammars** (`secrets/
  docker/cf_dns_api_token`, `secrets/ddns.env`), same token verified by identity.
  The assertion covering one derives its list from
  `compose.services[*].secrets`, so the other is **out of scope by
  construction**. Suspected C78; one direction genuinely silent ~9 days.

## The run of 2026-09-19 (FOURTH) — the key was `staleness`, and it paid in the instruments and in the register, not in the estate

The twenty-third key, **chosen by the operator from the proposed list rather than
invented**. The six-word question: **since when has this value not changed, and
who would have noticed?** The register had predicted a low mint yield because
`staleness` overlaps C39, C44 and C76. The prediction held and the reason is the
interesting part: the estate came back measured clean almost everywhere, while
**the audit's own instruments and this register were where the key bit.**

Four admissible shapes went into all eight briefs: (a) a reading served from a
cache whose refresh has stopped, with no way to tell fresh from frozen; (b) a
constant calibrated against a state the estate has left; (c) a derived artefact
older than its source that nothing rebuilds; (d) **an instrument whose own
freshness is asserted nowhere** — the founding defect's shape, and the one four
briefs were told was the likeliest mint. **Nine overlaps were declared
instance-only** (C01, C39, C44, C49, C76, C88, C100, C105, C107) and the
discipline held: **seven of eight domains returned an explicit "no mint".**

### The counter: 2 OPEN in, 1 OPEN out, 1 minted, class total 107 -> 108

**The termination clock RESETS.** `commensurability` minted 0, `aggregation` 1,
`staleness` 1. The pair of consecutive zero-mint runs has still never been
achieved.

### C107 — CLOSED, by two bounds that are complementary rather than redundant

The register said to bound it by INSTRUMENT, not by assertion. Two domains did,
over **different instrument populations**, and that is the closure:

| Bound | Owner | Cardinal | Instances |
|---|---|---|---|
| Executables invoked by deployed checks | `security` | 63 executables -> **N=32**, 32/32 | 2 (lynis, ufw) |
| Instruments of the supervision plane, API included | `observability` | **12/12** | 2 real (lynis, netdata alarm surface) + 1 structural |

**They are not the same set and neither contains the other.** `security` parsed
the goss specs and the nine deployed check scripts against the PATH executable
set; that sweep is blind by construction to netdata's collectors, netdata's
health engine and Kuma's store, because none of them is an executable.
`observability`'s twelve include exactly those three and exclude the twenty host
tools. **C107's space is the UNION, both halves are stated and both are swept.**

**They converge on lynis, found independently from two directions** — this
register's strongest evidence standard. 41 `suggestion[]=` emitted weekly against
one scalar gated, archived into `last-green-report.dat` every week and never
read. The one finer fact the reader does keep is itself a frozen false positive
(`PKGS-7388`, lynis 3.0.9's deb822 gap) while unattended-upgrades ran the same
morning.

**The second instance is the run's operational headline and nobody had named it.**
`ufw status` **does not print the default policy**; only `status verbose` does.
Both `ufw-enforcing` checks read `status`. If the default incoming policy flipped
to ACCEPT, `Status: active` stays true and all declared ALLOW rules still match —
**both hosts stay green with the host open on INPUT.** Deny-by-default is the
project's rule 1 and was the only non-negotiable with no continuous assertion.
Verified by the main session with the control side by side: 0 occurrences of
`Default` in `status`, the policy line present in `status verbose`, 0 deployed
checks reading it, and `DEFAULT_INPUT_POLICY="DROP"` / `Chain INPUT (policy DROP)`
live — an blind spot, not an incident.

### C108 — MINTED, and it arrives ENUMERATED with a gate

**Property**: *a container running an artefact that its own declared tag no
longer designates* — the pin stays satisfied AS A STRING while the registry has
rewritten what the string points at, so two consumers of the same declaration run
different artefacts and nothing compares them.

**Space**: the running containers. **Cardinal 32, swept 32/32**: 31 resolve a
mutable tag, 1 (`it-tools`) is digest-pinned and structurally immune.
**2 instances** — `nextcloud-cron` and `nextcloud-notify-push` on
`sha256:4694b90c…` with `RepoTags=[]`, while `nextcloud`, recreated 2026-09-18,
runs the `93be8a75…` that `nextcloud:34.0.4-apache` designates today. `docker ps`
shows the same tag for all three. **Zero assertions compared image identity to
its pin** (`grep -cE 'RepoTags|\.Image\b|sha256:' /etc/goss/posture.yaml` -> 0).

**Why it is not absorbed.** C97 is the closest — "a name whose referent depends
on where it is resolved" — but its space is documents. C43 — "an address a
deployed configuration hard-codes and a third party assigns" — is about reaching
an address. C99 is about WRITES, and there is no write here. **The essence is
TIME**: two consumers resolved the same mutable name at different moments.

**Arbitration was not under pressure** — C44 stays OPEN regardless, so declining
this mint could not have manufactured the `0 OPEN` the criterion needs. The
operator accepted it on 2026-09-19.

**It arrives with a gate, and the gate went red on a real defect before it was
written down**: `containers-run-the-image-their-tag-designates` compares each
running container's `.Image` against what its `.Config.Image` tag resolves to
locally, skips digest pins, and carries an anti-vacuity floor. Run against the
live estate it reported `n=31` and named exactly the two known divergences. It
is ENUMERATED here and promotes to GATED once a scheduled posture run has
executed it.

### Live defects, ranked by what was happening without anyone knowing

1. **The ufw default policy, unasserted on both hosts.** See C107 above.
2. **No Immich advisory could reach the operator.** `renovate.json` carried
   `"enabled": false` on the three immich packages — a correct manual-pin policy
   that also suppressed security advisories. Pin 2 releases and 75 days behind
   (v3.0.1 of 2026-07-02 against v3.2.2 of 2026-09-15) with no channel able to
   say so.
3. **lynis, 41 suggestions against 1 gated scalar.** C107's exemplar.
4. **The two Nextcloud sidecars.** C108's instances — and they are also 2 of the
   4 containers with no healthcheck, which no agent connected.
5. **"Kuma keeps 180 days of messages", written in THREE live artefacts.** The
   main session measured the mechanism rather than the setting, and the result
   corrects both agents: **`keepDataPeriodDays` IS 180, so the sentence is true
   as configuration and false as a promise.** Heartbeat rows are pruned against a
   **per-monitor row budget**: on the 5-minute health monitor, 290 beats in the
   last day, 124 in the next, then **2 in days 2-7 and both `important=1`**, 30 in
   days 7-30 and all 30 important. An ordinary beat survives ~36 h. The three
   assertions are safe **because their monitor is weekly** — all 13 of its beats
   since 2026-07-19 are present against a 40-day window — **not because of the
   180-day setting**. A premise true by accident, with the wrong reason written
   down. Fail-safe direction.
6. **The audit's own agent file mis-sized its detection window 2.5x.**
   `.claude/agents/observability.md:20` said "(10-min gate)"; the timer is
   `OnCalendar=*:0/5` and every gate is `240` s. Wrong for 60 days — and commit
   `8763306`, made the same morning, rewrote **the other half of that same line**
   and carried the number across. **The edit is what makes it look checked.**
7. Eight statements still said "weekly" for the offsite health cadence that
   became DAILY on 2026-09-12, including two deployed templates and the
   justification of the 8-day lookback cap — which is therefore no longer derived
   from anything.
8. `pihole_bypass_clients` is keyed on an IP while the same block orders matching
   BY MAC "because a DHCP lease moves and the rule silently stops applying".
   Latent: `ip neigh` still returns the declared MAC.
9. `rate-limit.burst: 250` carries its own revisit condition — *"revisit if 429s
   reappear with the house occupied"*. **They reappeared**: 14 in 17.6 days,
   0.0023 % of traffic, and `grep -rn 429` over the estate returns only the three
   comment lines that state the rule. Nothing counts a 429.

### The register lied about itself in four places, all verified by the main session

- **A15 read "RESOLVED" at `settled.md:1489`** while line 124 of the same file
  recorded why that resolution had died. Both are now superseded — see below.
- **C10 carried two opposite verdicts** — GATED row "REOPENED, see the OPEN
  table" against an ENUMERATED row "CLOSED 2026-09-12" — and the pointer named a
  table C10 had left seven days earlier. Corrected.
- **The frozen-snapshot cleanup carried two prices**: 71.7 GiB dated 2026-09-18,
  and "1.218 GiB of 343, i.e. 0.35 %" **undated**. A 58x gap, in the only part of
  `settled.md` with no date. The cleanup stays DECLINED for the fifth time; the
  number is removed rather than restated, because the decision never rested on it.
- **C53's row said 34 handlers / 1 flush point**; two runs have now counted
  **41 / 3** independently. Corrected.

### A15 — RESOLVED, reversing the previous run's withdrawal, and the reversal is the method working

The third run WITHDREW A15 because the control its evidence relied on had never
run: the two `ufw reload`s it cited never happened. **The fourth run ran that
control**, in a throwaway `unshare --net` namespace with the host's own nft
binary: three identical `iptables-restore -n` over a chain re-declared
`:CHAIN - [0:0]` leave **2 rules, not 6**; a manual `-A` makes 3 (positive
control). **A re-declared user chain is flushed, not appended.** Corroborated by
the live chain's counters matching 7.5 days of uptime, so no reload has occurred
since 2026-09-11 23:37 — confirming that the live 8 was never the control.
**C74's last open mechanism closes.** Residual carried: the chain has not been
compared to its source file for 7.5 days and nothing compares it.

### Rejected from the agents, and from the main session — 5

- **`system`'s "406 assertions is false, the number is 82".** Requalified, not
  accepted: 406 is right and derived; the register's SENTENCE is what misleads.
- **The previous run's correction "C22 moves 28 -> 32".** Wrong. C22's space is
  healthchecks and **4 containers have none** (dnsproxy, searxng, nextcloud-cron,
  nextcloud-notify-push), verified by the main session. **C22 = 28**, and the old
  28 becomes right again for the right reason.
- **`observability`'s framing of the Kuma retention**, corrected by measurement —
  see defect 5. Its MECHANISM (row budget, ~33.8 h) was right and is confirmed;
  its implication that the written premise is simply false is not.
- **The main session's first netdata probe.** `curl 127.0.0.1:19999` from the
  host returns `000` — netdata is in a container. The empty result was discarded
  rather than used; re-run with a control (000 host / 200 container).
- **The main session's own brief**, on one point: it told `security` lynis ran on
  a 2-day cadence. The timer is weekly and the Kuma monitor's interval is
  691 200 s = 8 days, so the beat is legitimately fresh. One brief of eight
  carried it.

### Instrument traps paid — 3 (the heading said 2 and listed 3; corrected 2026-09-19, fifth run)

1. **`ufw status verbose` does not print the same rule table as `ufw status`**:
   `ALLOW` becomes `ALLOW IN`. Switching the per-rule check to verbose without
   noticing would have silently broken every SSH-source assertion, which match
   `ALLOW +${src}`. Caught before deploy; the regex is now tolerant of both
   forms. **A format change that only affects the columns you were not reading is
   the cheapest way to break a working check.**
2. **A comparison that reads a file its own script is about to overwrite.** The
   lynis "new since last run" clause lives above the `cp` that refreshes
   `last-green-report.dat`; placing the new green-path comparison after that copy
   would have compared the report to itself and found nothing new, forever.
3. **`docker events` has a retention shorter than any audit window, and its
   silence is not evidence.** `services` queried `--since 2026-09-18T18:00:00Z`
   for container-create events and got nothing back, although `nextcloud` was
   created at 22:19:33Z inside that window. The daemon's event buffer does not
   reach that far. **The agent recorded the empty result as uninformative rather
   than dropping it**, which is the behaviour this file wants: an empty probe
   left unrecorded is re-run later and mistaken for a negative. C108 rests on
   `.Created` from `docker inspect`, which is independent of the event stream and
   was re-measured by the main session.

### C07 — still RED, and widening it is now provably well defined

Measured independently by `observability` and by the main session after a
reachability control. `apps.plugin` is at `update_every=5` over **1942** charts,
so the 2026-09-18 fix landed. **`cgroups.plugin` is still at the stock 1 s over
995 charts** while the gate certifies go.d|docker.

**THE "DECISIVE NEW FACT" RECORDED HERE WAS FALSE, and the fifth run of
2026-09-19 disproved it.** This section used to read: *"`(context ->
update_every)` is a FUNCTION — 375 contexts, ZERO carrying two intervals"*, and
concluded that a floor keyed on that relation was well defined. It is not.
`disk.space` and `disk.inodes` each carry **both 1 and 5**, because the `/tmp`
charts run at 5 s while their siblings run at 1 s — measured by `observability`
and re-measured independently by the main session with a reachability control
(host `000`, container `200`), after the agent's own scratch file had been
removed, so the exception is structural and not induced. **A floor keyed on
context therefore has an exception on day one.**

**The replacement bound is per-plugin**, and it is the one to arbitrate: four
plugins carry more than 100 charts, and a per-plugin floor comes up red on
exactly one member. A naive `>= 5` floor would flag **1712 charts of 3838**.
There is also no cheap route to the data — the light endpoints
(`/api/v1|v2|v3/contexts`, 95–130 KB) **do not carry `update_every` at all**
(383/383 missing), so the cost is `/api/v1/charts`, 5.3 MB, 0.74 s for the full
`curl | jq` pipeline. `proc.plugin`, 531 charts at 1 s, is named nowhere either.

Arbitration, not a fix. This is a broken gate and does not count in the run's
counter.

## The run of 2026-09-19 (third) — the key was `aggregation`, and the estate answered while the audit's own baseline lied again

The twenty-second key, and the first invented rather than taken from the proposed
list. The six-word question: **what does the collapse to one hide?** All 106
classes asked whether ONE thing is correct, whether TWO are distinguishable
(`collision`), or whether two are comparable (`commensurability`). Not one asked
whether a verdict computed OVER N readings preserves the failure of one.

Three admissible shapes went into all eight briefs: (a) a failure-absorbing
reduction — `any`/`all`/`max`/`min`/`avg`, a pipeline exit code, a `&&` chain,
`grep -q` over multi-line output — where one failing reading maps to a passing
verdict; (b) an aggregate that loses identity, reporting "ok on 32 instances"
without stating WHICH 32; (c) an N that varies, so the same verdict means
different coverage on different days.

Five overlaps were declared so agents returned instances rather than mints —
C83, C94, C104, C58, C22 — and the discipline held: **seven of eight domains
returned an explicit "no mint"**.

### The headline is that the audit's own baseline manufactured a false clean for the SECOND consecutive run

The main session wrote into all eight briefs that `homelab-posture.service` had
run ON ITS SCHEDULE at 03:10:17 and that C100's residual was therefore retired.
**False.** `LastTriggerUSec` was `Fri 2026-09-18 11:05:30`, `OnCalendar` is
`11:00`, and the 03:10:17 run was one of **thirteen** hand-runs from the previous
night's remediation, started by Ansible at `deploy/tasks/main.yml:187`.

**Three agents demolished it independently**: `backup` from the timer, `system`
from the journal, `observability` from the beat's own content — it reads
`— manual run` verbatim. The 2026-09-18 provenance fix WORKS and the baseline
simply did not read it. 2026-09-18's false clean was a hand-run 17 minutes before
the briefs; this one was a hand-run 7 hours before.

**Add to the baseline recipe: `systemctl show <unit>.timer -p LastTriggerUSec`,
beside `ExecMainStartTimestamp`.** `Result=success` already could not distinguish
succeeded / never ran / absent; it also cannot distinguish scheduled from manual.

### C100 is CLOSED, by observation rather than by assumption

The main session armed a watch and observed the next scheduled firing.
`LastTriggerUSec=Sat 2026-09-19 11:07:08`, service exit 0 in 66 s, and the beat at
09:08:14 UTC reads **`posture OK — 423 checks (...) — scheduled run`**, against the
01:11:17 beat's `— manual run`. **The first green SCHEDULED posture run this
register has ever recorded.** The residual that stood through three audits retires
on evidence.

### The live defects, ranked by what was happening without anyone knowing

1. **The TAP plan guard shipped eight hours earlier had reached 2 of 4 consumers,
   and not the two largest.** `homelab-posture.sh:180-185` (**400 assertions**) and
   `homelab-health.sh:579-583` (9) still floored at `-eq 0`; `backup-notify.sh` and
   `offsite-health.sh` carry the comparison. With `|| true` and
   `TimeoutStartUSec=infinity`, a goss killed mid-plan yields `posture OK — 423
   checks` green with 400−k security assertions unevaluated, on a host whose own
   comment records 12.4 % of beats timing out from contention. **The main session's
   control was sharper than the finding**: `backup-notify.sh`'s comment claims
   *"Same three-step guard as homelab-posture.sh, homelab-health.sh and
   offsite-health.sh"* — two of the three it names did not have it. **Shipped in
   #368, which makes the comment true rather than correcting it.**
2. **Pi-hole's freshness check could never go red.** `gravity.sh:873-887`: on a
   failed download with a readable cache it prints "using previously cached list",
   sets `adlist.status=3`, **parses the cached copy** and returns normally, so
   `update_gravity_timestamp` at :1210 stamps `updated=now`. `adlist.status` had
   **zero readers** across `ansible/`, `docker/`, `ops/` and the deployed spec, and
   nothing floored the domain count. **One adlist carries all 79 963 domains.**
   `network`'s wording "stamps unconditionally" is imprecise — it is conditional on
   a phase the fallback satisfies — but the consequence is exactly as claimed.
   **Shipped in #368.**
3. **Split-DNS: 21 records, 1 asserted.** `pihole-05-homelab.conf.j2` is a
   hand-written list of 21, not derived from the Traefik labels. Only Kuma monitor 8
   checks DNS, on one name. A 22nd service gets a router, a certificate and
   middlewares automatically and a split-DNS record only if someone remembers —
   otherwise it resolves to the public IPv4 where 80/443 are not forwarded: dead
   from LAN and VPN, 37/37 green. **Shipped in #368**, derived from compose.yaml's
   own `Host()` rules (21 derived = 21 served today).
4. **A fresh provision can lock the operator out.** `ssh_allowed_sources` is
   `required: true` on a `type: list`, which bounds presence and not cardinality —
   `[]` validates with zero errors against ansible-core 2.21.2's own
   `ArgumentSpecValidator`. The allow loop adds nothing while the three retractions
   and `ufw enable` run regardless. The comment above the retraction reasons about
   the order — *"so the v4 path is never absent, not even between two tasks"* —
   while silently assuming the loop produced at least one rule. **Shipped in #368.**
5. **Nothing asserted any of the 22 hardened SSH directives.** The only standing
   check over that surface is the weekly lynis index, and **every SSH finding lynis
   emits is a suggestion** (4x SSH-7408 today, 41 suggestions against 1 warning),
   which the deployed script never parses. **Shipped in #368**, derived from the
   managed file against `sshd -T`, so it also covers a drop-in under
   `sshd_config.d` overriding all 22.

### The key's own instances, not shipped

- **The weekly lynis verdict is the index alone** — the finer signal is collected,
  printed as prose and never gates. This is the exemplar of the proposed mint below.
- **`ufw-enforcing` matches `^Status: active$`** out of the full rule listing; the
  8 `DOCKER-USER` rules are unasserted.
- **`creds_probed` is the one counter in `homelab-posture.sh` with no floor** while
  `containers_seen` and `mounts_seen` have one at :230/:232.
- **`homelab-disk.sh`'s ext4 anti-vacuity floor is 0, not 2** — pre-unlock the daily
  report pushes UP with `ext4 clean (1)`, green over the SD card only.

### C107 — MINTED on the operator's arbitration

**Property**: *an assertion that consumes its own instrument's output at a coarser
grain than the instrument produced it* — the finer signal is collected, rendered as
prose, and never gates. **Space**: NOT BOUNDED. `security` measured 181 of 274 goss
checks carrying `stdout:`, but most match a single-valued `docker inspect -f`, so
the cardinal is not stateable and the class would arrive OPEN. **Exemplars 2/2**:
the lynis index against its suggestion set; `ufw-enforcing` against the rule
listing.

**The arbitration was not under pressure, and that is deliberate**: C44 stays OPEN
regardless, so declining this mint could not have manufactured the `0 OPEN` the
termination criterion needs. Distinct from C03 (what the comment claims), C05 (what
a reader assumes) and C58 (the permitting direction). **The operator accepted it on
2026-09-19; the counter goes 1 -> 2 and the class total 106 -> 107.**

**The bound to try next, and it is not the one that defeated this run.** Bounding by
ASSERTION means 337 per-predicate judgements. Bounding by INSTRUMENT is a different
and much smaller question: the deployed checks invoke roughly sixteen external tools,
and "does this tool emit a finer signal than its readers consume" is asked once per
tool. `lynis` answers yes loudly — 41 suggestions against one index. `docker inspect
-f` answers no, which is why 181 `stdout:` matches inflate the assertion-side count
without belonging to the class.

**One of the two exemplars was partly remedied the same day, and the remedy is not
the class.** `ufw-enforces-every-rule-the-inventory-declares` now reads the rule
LISTING for every declared rule, so the coarse `^Status: active$` grep is no longer
the only reader of that instrument. **The 8 `DOCKER-USER` rules remain unasserted**
— `security`'s P2, not shipped — so the exemplar survives in reduced form. The lynis
exemplar is untouched and is the sharper of the two: a revoked SSH directive is
printed verbatim by the instrument every week and cannot move the number its reader
consumes.

### Rejected from the agents, and why — 4

- **The main session's own baseline.** The largest rejection of the run, and it had
  already reached all eight briefs. See above.
- **`security`'s A15 resolution — WITHDRAWN, and the register must not record it as
  closed.** The claim was that `iptables -L DOCKER-USER | wc -l` reads 8 rather than
  16 "across two `sudo ufw reload`s on 2026-09-13 02:31". **Those two reloads never
  happened.** A `zgrep` for `COMMAND=.*ufw reload` across the whole retained
  rotation, excluding grep lines, returns **nothing**, and the 02:20-02:40 window
  holds only read commands. The control never ran: reading 8 with no reload having
  occurred says nothing about whether a reload appends. **C74's last open mechanism
  stays open.**
- **`security`'s report of a third `ufw reload` at 10:28 inside the audit window,
  attributed to the operator.** The operator confirmed it was not them, and it was
  not anyone: at 10:28:00 the agent ran
  `sudo sh -c 'grep -hE "ufw reload" /var/log/auth.log* | sed -E "s/COMMAND=.*/COMMAND=ufw reload/"'`.
  `sudo` journals the command it runs, so the search wrote the string it was looking
  for, and the `sed` rewrote the tail to read literally `COMMAND=ufw reload`,
  rendering its own record indistinguishable from a real one. **The instrument
  fabricated the measurement it then read.** `/etc/ufw/user.rules` unchanged since
  2026-09-13 19:53:40.
- **The previous run's "C105's twelfth instance is the most consequential of the
  twelve".** `backup` prices it at essentially zero: the deploy recreates the
  directory, both settle idioms treat absence as "not yet", and the deep-check clock
  has a second backed-up source in Kuma. Residual: a ≤8-day window after a reflash.
  Also, the restic source set is **five** entries, not four — `/opt/homelab` is in it.

### Register corrections — 6

- **Seven classes carry cardinals frozen at a 28-container estate; it is 32.**
  Re-counted independently by the main session: **C25 62 → 80** bind mounts,
  **C36 37 → 41** tmpfs, **C50's Docker half 25 → 28** healthchecks. C24/C38 move
  28 → 32. Not a mint — this is the definition of ENUMERATED, which the register
  states explicitly. **CORRECTION 2026-09-20 (eighth run): this list originally
  said "C22/C24/C38" and C22 must NOT move.** Its space is healthchecks, not
  containers, and there are 28 of them — 32 minus the four that carry none
  (`dnsproxy`, `searxng`, `nextcloud-cron`, `nextcloud-notify-push`). C22's row
  already reads 28/28 and was right; C50's row says the same in writing. Counted
  live on 2026-09-20: 28 with a healthcheck, 4 without. **A correction list is
  itself a list, and this one was wrong in one of its three entries — the rule
  that catches it is to re-derive the SPACE before moving a cardinal, not to
  assume every count of 28 was the old fleet.** C40 was the eighth frozen row and
  this sweep of seven missed it; see its row.
- **C53's row records 34 handlers / 1 flush point; counted today 41 / 3.**
- **C21 is neither DERIVED nor a LIST — it is an ARGUMENT.** The guarantee is that
  the deployed `copy:` carries no bound, and **nothing would notice a bound being
  added**. Fourth correction that row has needed.
- **C74's offsite residual, which `settled.md` records as unfixed, is FIXED** —
  30 lines, `eth0 accept_redirects=0`.
- **A15 is NOT resolved.** See the withdrawal above.
- **C100 is CLOSED**, by the observed scheduled run of 11:07:08.

### Instrument traps paid — 5, and three were the main session's own

1. **A `grep` run under `sudo` writes into the log the string it is searching for.**
   Two false conclusions in one run, one of them relayed to the operator as a
   possible intrusion. Worse with a `sed` that rewrites the matched tail into the
   exact form being hunted. **Never count occurrences of a command string in
   `auth.log` without excluding the searching process's own record.**
2. **`systemctl show -p Result --value` returns `success` for a unit that does not
   exist** — paid again, live, when the main session's first baseline probe appended
   `.service` to names that already carried it and fourteen non-existent units all
   answered `success`, exit 0, `LoadState=not-found`.
3. **A grep pattern narrower than the code it is looking for.** The main session
   searched the offsite script for `_total\|_seen` and found nothing, nearly
   contradicting a correct agent: the variables there are `total` and `seen`,
   unprefixed. Always read the block, not the pattern's verdict.
4. **`docker inspect --format` with a mis-shaped range returns 0 silently.** The
   main session's first tmpfs count returned 0; the corrected form returned 41 and
   agreed with `services` exactly. The disagreement between two of one's own probes
   is the control.
5. **Querying the Traefik API from the host without a control.** The main session's
   `curl localhost:8080/api/http/routers` returned 0 routers; `network` had measured
   24 from the live API. The main session's own figure was discarded rather than used
   to contradict, because it carried no control.

## SUPERSEDED — OPEN table of the second run of 2026-09-19, key `commensurability`

**The table holds one class, and it holds it for the right reason: the two
sub-spaces that could be bounded were bounded, and the third was NAMED rather
than quietly left out.** That naming is what stops C44 from closing on a partial
sweep for the second time.

| ID | Property | What bounds the space, and what stopped the sweep |
|---|---|---|
| C44 | A verification whose cadence cannot observe the event it guards | **DEPLOY-TAG sub-space CLOSED 26/26**, by two independent derivations from opposite sides that agreed on the cardinal — `services` from the artefact (25 deploy-time guards + 1 render-time derivation), `ansible-deploy` from the roles (22 guards + 4 rendered goss specs) crossed with the tag lattice. The register's "12" had counted only `assert:`, omitting 7 `fail:` and 6 `failed_when:`. **STILL OPEN on a third cadence slice, named and unswept**: assertions whose artefact is rewritten by an EXTERNAL writer — unattended-upgrades on `/usr/lib/sysctl.d` — which is neither a timer nor a tag, and was outside both agents' mandate by construction |

## The run of 2026-09-19 (second) — the key was `commensurability`, and it minted nothing

The twenty-first key, and the first to be spent after being proposed and passed
over **four times**. It had sat in this file since 2026-09-05 with three unclassed
precedents attached. The six-word question: **same unit, same base, same frame?**
All 106 classes then on file asked whether ONE thing was correct, or — since
`collision` — whether TWO things were distinguishable. Not one asked whether the
two things being compared were comparable at all.

Three admissible shapes went into all eight briefs so agents returned measurements
rather than philosophy: (a) a comparison whose two sides are in different units,
bases or reference frames; (b) a threshold, floor or budget whose constant was
calibrated in a different frame than the value it is compared against; (c) a value
that silently changes frame as it crosses a boundary.

**The stated risk held, and it is why the mint count is zero rather than wrong.**
The brief warned that this key overlaps five instrument traps this register has
already PAID FOR — `docker logs --since` in local time against `-t` in UTC, a
`VmSwap` sum against the cgroup counter, netdata percent-of-a-core against
percent-of-machine, Pi-hole's `forward is not null` denominator, and the `jq -r`
newline in a hash comparison — and that a finding on any of them is an instance or
a re-derivation, never a mint. **Not one domain tried to mint one; six of eight
returned an explicit "no mint".**

### The headline is the counter, and that is the point

**5 OPEN in, 1 OPEN out, 0 minted, class total unmoved at 106.** `collision` paid
four mints from a register of 102; this key paid none from 106. **This is the
first zero-mint run since `exclusivity` on 2026-09-05.** The termination criterion
needs TWO consecutive zero-mint runs with different keys, so this is the first of
the pair and the next key decides. A key that had been deferred four times as
"probably already covered" turned out to be exactly that — which is evidence for
completeness, not against the practice of inventing keys.

### The four closures, each with its derivation

| ID | Cardinal | How the space was derived, and what controlled it |
|---|---|---|
| C20 | **43/43 by VALUE** | The unit is the rotatable secret VALUE (C89), not its carrier, so carriers and derived forms (DSN, Argon2 hash, obscured pass) collapse into their source. Derived twice: the 39 `no_log: true` options across all 11 `meta/argument_specs.yml`, PARSED not grepped; and every secret-shaped identifier referenced under `roles/`, which reproduces those 39 and adds 3 arriving through `group_vars` indirection. +1 because `ssh_port_hardened` holds a distinct value per host. **The three numbers on file were three different bounds**: 16 was `ls /mnt/data/secrets/docker/` (the mechanism bound), 15 was the runbook's table, and **59 could not be reproduced from any stateable bound and is NOT adopted** — it counted carriers, which double-counts every multi-carrier value. 30 rotate correctly, 9 documented non-rotating, 2 new confirmed, 2 suspected |
| C103 | **37/37 monitors, 111 field-reads** | The 22 active monitors are structurally immune — Kuma is the executor, so the beat IS the execution. All 15 push monitors are timer-driven and therefore carry the duality; `origin()` exists in **1 of 15**. 6 of the 14 unprovenanced are measurably hand-run in the retained journal. The systemd slice was already 14/14 and was not re-derived |
| C105 | **28/28, 0 annotated** | Forward 16/16 unchanged, with the detector controlled against 25 substantive red-discussions elsewhere in `docs/` — it is not blind to the word, the repo simply never uses it where a procedure causes one. Inverse bounded by a DIFFERENT first factor, and that is the closure: **{persistent reference an assertion reads back as its own memory} x {documented procedure that erases its medium}**. An assertion has memory in exactly one way — a file it writes and reads back — and that set is small and derivable |
| C01 | **123/123 referents, 12 contradicted** | The newly admitted space: 12 instruction files — 8 agent files, the project and user `CLAUDE.md`, one `SKILL.md`, the memory index. The user-level `CLAUDE.md` and the `SKILL.md` are clean; 6 of the 8 agent files are not |

### C105's inverse cardinal is 12, not 11, and the main session found the twelfth

The agent's table listed 11 references. `/var/lib/homelab-backup/status.json` is
missing from it, and it is read back by an assertion — `posture.yaml:2208` — holds
the last backup's success and time, sits on the SD card, and is **in no restic
source** (the sources are `/mnt/data/{services,media,backups/dumps,secrets}`; no
`/var/lib` anywhere). It is arguably the most consequential of the twelve, since
it is a backup assertion's own memory.

**The sweep is stronger than "0 annotated" and was re-run by the main session with
a working control.** Seven probes over `docs/` + `knowledge/` return zero hits,
while `restic` returns 38 files and `var/lib` 20 hits — so the instrument works and
the documentation does discuss `/var/lib`, just never these. **The state those
procedures erase is not documented to exist at all**, which is why no runbook could
have warned: there is nothing in the documentation to warn about.

### The live defects, ranked by what was happening without anyone knowing

1. **`--tags deploy` ships a service with zero posture checks.** `/etc/goss/posture.yaml`
   — 219 checks, 105 frozen expectations, a 32-name literal list — is generated FROM
   `docker/compose.yaml` by the `observability` role while `deploy` ships
   `compose.yaml`, and **nothing on the host reads `compose.yaml` at run time**. The
   main session's apparent counter-example strengthened it: the host-side references
   are comments and frozen constants (`[ "$read_pairs" -eq 14 ]`, `"$n" -ge 16`).
   Measured: **11 of 14 documented tag forms** are `--tags deploy`, 3 are
   `--tags deploy,observability`, 1 is `--tags storage,deploy,stack-startup`, and
   **no documented form reached both guards**. Live drift on the day: 0.
   **Shipped**: the spec render, its parent directory and the Tier 0 assert are
   `tags: always`.
2. **Rotating `luks_passphrase` produces a green run and changes nothing.**
   `community.crypto.luks_device` with `state: opened` returns `ok` for an
   already-open volume — it never opens the device, so it never validates the
   passphrase. **Exactly one keyslot on the disk** (re-measured by the main session
   with `luksDump`). Discovery point is the next unlock, which is the one moment with
   no out-of-band path. Absent from the rotation runbook. **Shipped as a runbook
   procedure**, in the restic order, with `--test-passphrase` as the proof step and a
   header re-backup after the keyslot change — the header runbook already lists
   `luksAddKey` among the operations that invalidate the stored copy.
3. **`wg_password` is never set by the deploy at all**; the re-assertion script only
   logs in with it, and its "wg-easy not running -> exit 0" guard makes the whole
   deploy report success with the secret file `changed`. Runbook row.
4. **`restic-deep-check-not-stale` was fail-open**: `max(time)` over EVERY monitor's
   messages matching `'%deep check%'`, with no `monitor_id` filter. Latent — one
   reporter matches today — but any other monitor emitting those two words resets the
   45-day clock. **Shipped**: it now fails closed when the pattern stops identifying
   exactly one reporter.
5. **The TAP plan was never compared to the TAP results.** `backup-notify.sh:186`
   and `offsite-health.sh:105` read the plan line and floored it at `-eq 0`. goss
   emits `1..N` BEFORE the results, so a run cut short leaves plan N, k results, zero
   `not ok`, and a green beat with N-k databases unasserted. The count moved 26 -> 31
   -> 46 in twelve days with only a human noticing. The corrected form was already in
   this codebase at `homelab-health.sh:747` — *"The floor is the DECLARED count, not
   one"*. **Shipped to both scripts, and made to fail on purpose**: plan 3 / 1 result
   / 0 `not ok` is caught, plan 3 / 3 results stays green.

### The key's own instances

- **`homelab-health.sh:661`, shape (a), and it is the cleanest of the run.**
  `LastTriggerUSecMonotonic` renders as a **timespan string** (`1w 2h 3min
  53.394959s`) while `ExecMainStartTimestampMonotonic` renders as **raw µs**
  (`612233407772`). Same quantity, same frame, **incommensurable as read back**.
  Correct today only because both sides are tested against the literal `"0"` — and
  the comment directly above asserts the commensurability that would make the
  one-character "improvement" wrong: *"Both fields are monotonic, so the boot resets
  the pair together and there is no clock arithmetic."* Re-measured by the main
  session. **Not shipped**: the fix is a comment correction, and the comment rule
  requires the operator's go-ahead.
- **The `[vaultwarden]` fail2ban jail, shape (a) with cause (c), and LIVE for a
  month.** The container carried no `TZ`, so it timestamped in UTC on a CEST host —
  measured directly at **exactly 7200 s** (`vw 2026-09-18 23:45:12 UTC +0000` against
  `host 2026-09-19 01:45:11 CEST +0200`), and its log lines carry no offset at all.
  fail2ban has been saying so in its own log since 2026-08-17. **Its remedy is what
  does the damage**: re-stamping entries to *now* means `findtime = 600` discriminates
  nothing, and the jail's real policy is "3 failures ever since the last restart".
  `goss` asserts jails are *loaded*, so everything was green. **Shipped**: `TZ: ${TZ}`;
  verified after deploy at CEST +0200, matching the host to the second.
- **C07's gate is the purest statement of the key and stays RED.** A floor rendered
  by one Jinja expression from ONE collector's interval, compared against a fleet.
  `apps.plugin` fell 22.4 % -> 4.50 % of a core against a cadence factor of 5 — the
  2026-09-18 fix landed exactly — but the gate certifies the go.d **docker** collector
  at 0.70 % while **`cgroups.plugin` runs at netdata's stock 1 s for 6.91 % across 995
  charts**, ten times the asserted collector, with no alarm, no goss check and no push
  monitor reading a cgroups context. A derived floor must key on `(chart context) ->
  update_every` from netdata's own `/api/v1/charts`.
- Latent, not shipped: the fsck superblock spelling "disabled" as `-1` against a
  variable spelling it `0` (both sibling sites translate; arms the day anyone uses the
  documented way to disable it); `TimeoutStartSec=600` on the staged startup against
  the script's own 660 s gate ceiling, worst real run 368 s; host `wg0` MTU 65456
  against a tunnel carrying 1420, wg-quick having derived it from `ip route get
  127.0.0.1` because the endpoint is the local wg-easy.

### Rejected from the agents, and why — 5

- **`system`'s headline that the posture provenance probe compares nothing.** FALSE,
  and the main session settled it on the beat's own content: the deployed script does
  compare start against trigger with a 5 s tolerance (`homelab-posture.sh:82-89`), and
  today's beat says **`manual run`** verbatim. The agent had conflated two scripts;
  `services` made the same conflation independently. The 2026-09-18 provenance fix
  WORKS. The real defect is in `homelab-health.sh:661-662`, which is a different
  clause with a different property.
- **`services`' claim that the Traefik access-log rate doubled** to 9.99 MB/day
  against a documented 6.17. Re-measured from the file's own first and last
  timestamps — 429 316 bytes over 1 h 44 — gives **5.95 MB/day**, the documented rate,
  and measured DURING an eight-agent audit that should have inflated it. Not
  established; needs a quiet-period re-measure before anyone edits the constant.
- **`security`'s positive control for the fail2ban instance.** It described
  `[nextcloud]` as carrying `TZ`; **neither container defines `TZ`**. What
  distinguishes them is the log LINE format (an explicit `+00:00` offset), not the
  environment variable. The finding holds; its control was mis-described.
- **`security`'s "once a day since 2026-08-17"** for the fail2ban warning. Counted
  across the whole rotation: **7 occurrences**, not daily.
- **C20's cardinal of 59**, carried from the previous run. Not reproducible from any
  stateable bound, and it counts carriers rather than values.

### Register corrections — 5, and one of them un-reds a gate

- **C03-T's NAMED defect is REPAIRED and the register would have sent the next run
  hunting it.** The row records the gate as blind because its clauses count
  `heartbeat` rows with no `status` filter. Both clauses of the DEPLOYED
  `/etc/goss/posture.yaml` carry `h.status = 1` (`:3240`, `:3255`), verified
  independently by the main session. Two residuals remain and are genuinely open: it
  has never completed a green SCHEDULED run, and a live reporter pushing a genuine
  failure is still indistinguishable from a mute one — which is the fail-safe
  direction.
- **C15's cadence is DAILY** (`OnCalendar=*-*-* 08:00`), not weekly. The "6 days
  unasserted" residue retires with it.
- **C44's deploy-assertion cardinal is 26, not 12.** The old figure counted only
  `assert:`.
- **C105's inverse cardinal is 12, not 11.** See above.
- **C20's cardinal is 43, by value, with the derivation stated.** 16, 15 and 59 were
  three different bounds, and only two of them are reproducible.

### Instrument traps paid — 4, and two were the main session's own

1. **`systemctl show -p Result --value` returns `success` for a unit that DOES NOT
   EXIST**, exit 0, `LoadState=not-found`. Measured with a control. Three states —
   succeeded, never ran, absent — are indistinguishable to anything reading `Result`.
   This is the mechanism `Result=success` on `homelab-image-retention` actually runs
   through, and C101's row names the wrong one: acceptance comes through the `success`
   arm, not the empty one, so anyone "fixing" it by dropping `""` ships a no-op.
2. **GitHub's branch-protection API returns 404 for a branch protected by a
   RULESET.** The main session read that 404 as "not protected at all" and was about
   to contradict a correct agent finding. `repos/:owner/:repo/rulesets` is the
   instrument. `main` carries deletion, linear history, creation, pull_request,
   required_status_checks and non_fast_forward — and **no signature rule**.
3. **`fail2ban.log` must be read across its rotation.** The main session's grep of
   the current file alone returned ZERO occurrences of a warning that has fired seven
   times, and nearly rejected a true finding on that basis. `zgrep` over
   `fail2ban.log*`, always.
4. **A DF ping probe with no reachable control proves nothing.** The main session's
   counter-probe of the `wg0` MTU passed at every size because it targeted an address
   that never leaves the box, and its control returned nothing parseable. The
   disagreement with `network` is recorded UNRESOLVED rather than decided.

## The 2026-09-19 (first run) closure record — was that run's OPEN table, superseded

**Two mints arrive OPEN, two arrive ENUMERATED, and three classes REOPEN — none
of the three is a broken gate, and that distinction is the run's first
correction.** `services`, `security` and `project-manager` each reported one as
a broken gate; C44, C20 and C01 are respectively ENUMERATED, ENUMERATED and
closed-by-arbitration. A finding there reopens a class, it is not a red test.

| ID | Property | What bounds the space, and what stopped the sweep |
|---|---|---|
| C103 | A status field that does not carry which execution produced it | systemd slice **swept 14/14** (+3 offsite). The Kuma slice is not swept: a heartbeat carries no provenance either, and the false clean of 2026-09-18 is that slice's instance. Bounded by the set of status fields an instrument reads — derivable, not yet derived |
| C105 | A documented procedure that produces or erases the state an assertion discriminates on | 16 documentary sites swept, 0 annotated. **Not bounded**: the certificate-ratchet instance is the inverse direction (the procedure erases the discriminator rather than creating the state) and sits outside the 16 by construction |
| C01 | A documentary statement whose content contradicts the deployed artefact | **REOPENED.** Its 472 occurrences / 218 referents were bounded by a DIRECTORY — `docs/` + `knowledge/` — and `.claude/agents/*.md` and `CLAUDE.md` have never been in the space (0 hits for `.claude/agents` in either register file). First probe: `.claude/agents/project-manager.md` told every run that **16 ADRs exist** against 36 on disk, so the agent charged with not re-proposing settled work stopped at ADR-016. **The 9th payment of the scope trap.** Corrected by removing the count, not by updating it |
| C20 | A secret that a deploy reports as rotated without rotating it | **REOPENED.** `security` measured its space at **59 values** against the 16 the register records, and the rotation runbook lists 15. The class was never wrong; its cardinal was |
| C44 | A verification whose cadence cannot observe the event it guards | **REOPENED.** Its 13/13 sweep was bounded by TIMERS while the property is not: the Tier 0 guard lives in the `stack-startup` role and the `compose.yaml` it guards is shipped by the `deploy` role, so `--tags observability,deploy` — the form settled.md records as conventional — ships a Tier 0 drift with the assertion never evaluated. 1 of 12 deploy assertions guards an entry shipped by another role |

### The two mints that arrive ENUMERATED

**C104 — 219/219**, 28 multi-branch checks, cardinal exact and controlled by two
independent methods after the first one agreed with itself for the wrong reason.
**C106 — 2/2**, fix declined, class kept.

## The 2026-09-18 closure record (was that run's OPEN table, superseded)

**The table is empty for the second time in this register's life.** The first was
2026-09-03; this one differs in that the class that closed had been open on a
blind spot the previous run described as needing an instrument that does not
exist. It did not need it.

**C88 — CLOSED as ENUMERATED.** Three slices, each stating its own derivation and
its own blind spot, against the 105 stores the previous run had already swept:

| Domain | Cardinal | How the space was derived |
|---|---|---|
| `ansible-deploy` | 80/80 `/etc` paths + 5 in-file registers | the repo's `/etc` write destinations, closed against the host by two independent set differences: the Ansible-marker set, and a dpkg ownership diff (`*.list` ∪ `*.conffiles`) with a 112-entry distro whitelist |
| `network` | 21/21 | every `Host()` name Traefik's live API serves = every certificate in `acme.json` = every split-DNS record |
| `backup` | 16/16 | the snapshot registers of both repositories, local and offsite |

**What dissolved the blind spot.** The previous run left 61 single-file `/etc`
drop-ins unswept because "the real detector is a git-history walk that does not
exist". It is not the detector the question needs: `{files carrying the Ansible
marker} ⊆ {the repo's /etc destinations}` answers it, and the inclusion was
checked with `comm` file by file — empty output on both hosts — not by comparing
counts. **0 live residue anywhere on either host.**

**The marker cardinal is derivation-relative and the two derivations disagree,
which is recorded rather than resolved.** The agent's regex unions three spellings
and returns 34/18; the main session's single `Ansible managed` returns 23/14 and
is a strict subset. The inclusion that carries the closure holds under both.
**The coverage figure moves with it, and the cautious one is the right one to
quote: 28.7 %, not 42.5 %.** That is why the marker is NOT the gate to build —
the dpkg diff is, since it covers 100 % of the 80.

**Removers are still the weak half**: 2 of 68 + 3 of 15 + 2 of 80 have a remover
DERIVED from the register. Three live instances are recorded below. ENUMERATED,
not GATED: nothing derives the (store, remover) relation continuously.

### The three classes that sit ENUMERATED with live instances

| ID | Property | State after this run |
|---|---|---|
| C100 | A recovery condition asserted from a mechanism's CURRENT STATE when its failure was a property of its CADENCE | **1 NEW live instance, confirmed and re-measured by the main session** — the posture monitor, below. The founding instance is resolved (`homelab-local-maintenance` ran on cadence 2026-09-15 01:01) |
| C98 | A repeated procedure reuses a fixed, run-invariant NAME for the artefact it later reads back as authoritative | **Unchanged: the same 2 of 4 reference points are unrepaired** (`$BEFORE_ASSETS`, the unguarded `compose.yaml.bak`). The 3 shipped repairs have held 5 days. No fifth point exists |
| C99 | A declarative in-place write keyed on the VALUE it writes rather than on the record's IDENTITY | **Unchanged: still the same 4 of 31, 0 live duplicates** on both hosts |

### C101 — MINTED, ENUMERATED 5/5

**Property**: *a component declines a duty on the written ground that a NAMED
sibling asserts it, and the sibling declines it too.*

**Space**: the written delegations between verification artefacts — every comment
that names another artefact as the one asking a question. 5/5 swept by `system`,
4 true with positive controls, **1 false**.

The false one, verified independently by the main session: `goss-posture.yaml.j2`
said *"Whether it is ARMED is C19's question and goss-units.yaml already asks
it"*. `/etc/goss/units.yaml` declares 15 services and no timer, and its own header
records that the timer check *"stays in the script"*. The script
(`homelab-health.sh:640-663`) enumerates the timers and tests each one's LAST
RESULT with `case "$r" in ""|success|exec-condition) continue` — **the empty value
is accepted, and empty is exactly what a unit that has never run reports.** Its
only floor is `timers_seen -eq 0`, so disarming one of fourteen crosses nothing.

**Why it is a mint and not an instance of C05** (*something a reader would
reasonably assume the posture check asserts, and which it does not*, ENUMERATED
104/104): C05's space is what a reader assumes, which is not mechanically
derivable. This one's is, and that is the whole value — an explicit written
delegation is a grep away. This is an arbitration by the main session, recorded
as such, and it can be overturned in one edit.

**Live consequence, measured**: 12 of the 14 control timers would eventually
surface through their own Kuma push, `homelab-smart-test` through its
power-on-hour dead-man, and **`homelab-image-retention` through nothing at all** —
it has never run, its next elapse is 2026-10-04, and no monitor names it.
**Shipped the same evening**: the armed set is now asserted inside the parity
assertion that already built it. 14/14 `enabled` + `active`.

### C102 — MINTED, OPEN space stated, 1 live instance

**Property**: *a repair mechanism whose TRIGGER and whose INPUT share a failure
cause, so it never executes under conditions where its input can be trusted.*

**Space**: the self-healing mechanisms that read an external input. Derivable and
not yet derived — that is the honest state, and it is why this row says so rather
than carrying a cardinal.

**The instance, re-measured by the main session from the offsite journal.** On
2026-09-16 at 11:32:22, `offsite-wg-reresolve.sh` wrote `endpoint now
212.27.38.252:51820` — the wildcard answer the parents' box was returning to every
question — as the endpoint of the only tunnel that reaches that host. At 11:33:29
it re-resolved correctly. **Self-healed in 67 seconds.** The script asserts in
writing that it *"Fails CLOSED by construction"*: true of a resolution that
FAILS, false of one that succeeds and is wrong. The eth0 outage staled the
handshake AND broke the resolver, which is the property.

**Nobody saw it, and that is measured rather than assumed**: `stat_hourly` over
09:00-10:00 UTC gives **2 650 UP and 2 DOWN**, the two being the posture monitor.
No active probe watches the offsite at all — its three monitors are pushes at
90 000 s and 700 000 s. Had the resolver kept lying, the first signal would have
been a missing daily push, up to ~25 h later.

**DECLINED by the operator the same evening**, and the reasoning is recorded in
`settled.md`: it repaired itself, a box fault is the likely cause, and a durable
failure would surface as a backup failure. The class stays; the fix does not.

### C37 — CLOSED, by two derivations that were bounded by the property

The class reopened because its 08-29 sweep counted the databases the DUMP
MECHANISM knows about, so a copy prescribed by a RUNBOOK sat outside it by
construction. Both slices this run were generated from the property itself —
*every place a `.db` is copied or read as authoritative* — and both came back
with zero defective:

| Domain | Cardinal | How the space was derived |
|---|---|---|
| `backup` | 65/65 | 7 dump hooks + 13 restic exclude expressions + 15 operator copies + 28 authoritative reads + 2 delete sites, across `ansible/`, `docker/`, `ops/`, 24 deployed executables and the goss specs on both hosts |
| `project-manager` | 31/31 | every operator procedure in `docs/` and `knowledge/` instructing a human to copy, move, stage or read a `.db` |

**The cardinals differ and that is not a defect** — the property is
derivation-relative, as C74, C90, C95 and C98 all record. Do not quote either as
"the" number.

**What makes it a closure and not a fourth sample.** `backup` proved the
`.backup` path's WAL completeness by an off-host control (the destination
inherits `journal_mode=wal`, fully checkpointed) rather than asserting it, and
measured the predicate on three plausible leads instead of assuming it —
`wg-easy.db`, `gravity.db` and `fail2ban.sqlite3` are all `delete` mode, so they
are not members. `project-manager` verified the late-evening repair landed
(`kuma.db*`, `?immutable=1` gone) and found no sibling.

**Both blind spots are stated, and they are different ones**, which is what makes
the pair worth more than either alone: `backup`'s derivation keys on the
`.db`/`.sqlite` token, so a database addressed only through a variable is outside
it — it bounded that arm from the filesystem instead, 23 stores at depth 6,
trading a construction gap for a depth gap. `project-manager`'s cannot see a
procedure that exists only in the operator's head.

**ENUMERATED, not GATED**: nothing derives the (copy site, journal mode) relation
continuously, so a new runbook or a new `cp` reopens it.

### Why C98 is one class and not two

`project-manager` derived it from runbook reference points — the rollback copy or
before-value a procedure captures from the object it is about to change. `backup`
derived it from shared workspaces — a fixed path a procedure writes and a later
step reads as authoritative. Neither read the other's report.

They are the same property seen from its two ends: **the name does not carry the
run**, so the second run finds the first one's artefact where it expects its own.
PM's `$BEFORE_ASSETS` check passes against its own previous output;
`/mnt/data/tmp/restore` is never cleared and two restore blocks then
`rsync -a --delete` **from** it into live service directories.

Minted once with per-domain slices, on the C90 and C97 precedent. **The cardinals
differ (8 and 12) and that is not a defect** — the property is
derivation-relative, as C74, C90 and C95 all record. Do not quote either as "the"
number.

### Why C37 and C88 reopened rather than being recorded as instances

Both for the reason this file has now paid **eight** times: **the derivation is
sound and it keys on the wrong axis.**

C37's sweep enumerated the databases the DUMP mechanism knows about. The Kuma
repair runbook reads `kuma.db` with `?immutable=1` — which deliberately HIDES the
WAL — and `cp`s the bare file twice as its rollback point. `kuma.db-wal` held
**4 181 832 bytes** while this run was measuring, the base is in `wal` mode, and
the runbook's own premise is a crash-looping Kuma, which is exactly the state
where the WAL has not been checkpointed. The 37 monitors exist only in that
database.

C88's sweep enumerated FILES RENDERED INTO A DIRECTORY. `security` found the ufw
rule set — a register that can shrink, whose retraction is three hardcoded
`delete: true` tasks each written after an instance had already shipped — and
**rejected its own candidate as a re-mint of C88**, filing it as an instance with
the bound named. `services` found the Docker image store — the compose pin list is
a register that shrinks and nothing removes what it stops naming — and offered it
for arbitration as possibly C88 reopened. Two domains, no contact, same property
in two non-file stores. The register's own rule names that as the strongest
evidence available.

**Both agents reached the right answer and neither claimed it**, which is why
this is recorded as their finding rather than the main session's.

### C95 — CLOSED as ENUMERATED, by three derivations that finally share a relation

The three slices, each stating its own derivation and its own blind spot:

| Domain | Cardinal | How the space was derived |
|---|---|---|
| `observability` | 47/47 | by ORIGIN: 10 emitter scripts + 22 Kuma active probes + 15 dead-man expiries + 0 non-Kuma paths. 8 intersections, 4 new |
| `network` | 14/14 | the 6 announcement paths decomposed hop by hop into 14 network preconditions. 8 intersections, 3 live |
| `backup` | 20/20 | 10 hook sites + 4 aggregate channels + 5 dead-man windows + 1 terminal path + 0 `OnFailure=` |

**What makes this a closure and not a fourth sample.** The reason C95 stayed open
was structural and written down: a sweep of the things that DELIVER cannot see an
emitter that never emits. All three derivations are generated from the
preconditions rather than from the sinks, so a mute emitter is a member of the
space by construction. `backup` enumerated five KINDS of mute emitter —
unsatisfied `Requires=`, false `ConditionPathExists=`, lock-wait timeout, host
killed mid-command, and an empty push URL — and `observability`'s p3/p5 cover the
same ground from the other side.

**The cardinals differ and that is not a defect** — C74 and C90 both record it as
expected for a derivation-relative property. Do not quote 47, 14 or 20 as "the"
number.

**ENUMERATED, not GATED**: nothing derives the (path, precondition-set) relation
continuously, so a new emitter reopens it. The gate that would close that gap
does not exist and was not invented here.

**Two arbitrations by the main session, recorded as such** because the operator
delegated the run's execution rather than each verdict, and either can be
overturned in one edit:

1. `network` and `backup` both ended with "the class closes when the three slices
   are re-derived against the same relation, not when one of them reports a
   number". They were re-derived against the same relation, in the same run, by
   the same instruction. That condition is met.
2. `observability`'s row A8 folded the ten resticprofile hook sites into one
   emitter and inherited the DECLINED verdict for all of them. `backup`'s
   instance B — an empty push URL, which fired at 14:41:24 that day — is NOT the
   declined item, and is filed as a live instance rather than under the decline.

### Why C92 closed by decision rather than by enumeration

Five domains closed their slice with a cardinal — `system` 53/53 over 9 derived
populations, `network` 25/25, `ansible-deploy` 13/13 after re-derivation,
`services` 9/9, `security` 7 populations. That is more measurement than C90 or
C94 had when they closed.

It still does not bound the class, and `project-manager` is why. It tested
whether `P(C)` — the population a correction's property defines — is a function
of anything a machine can read from the commit, and it is not: `79d0e3b` touches
five files under `ansible/` and `knowledge/decisions/`, and its four residues
live in three directories it never opened. The directory bound gives **2/203**.
The population bound gives **146/203 fix commits that changed a fact without
touching a documentary file**, with nothing deriving which of those facts has a
consumer.

**The run then produced two fresh instances of the class, one of them inside the
audit's own remediation** — the four media-library pages, where the documentation
pass of 15:35 RE-EMITTED the false row while re-aligning a table; and the three
`*arr` monitors running since 02:13 that the registry never listed, found by
running `ops/kuma-dump.sh` to verify something else.

So the choice was between a sweep that cannot close, and a rule. The operator
took the rule, on 2026-09-13 (evening), and it is recorded in `settled.md`:
**every fix states the population its own property defines, and either sweeps it
or says why it does not.** The five per-domain sweeps stand as evidence; the
class leaves the audit's counter the way C03-R did.

### Why C90 arrived OPEN on 2026-09-13 midday — and what closed it the same evening

Because two competent sweeps of it disagreed, and a third domain produced an
instance that neither space contained. `system` bound it by *arbiter* and got
13/13; `services` bound it by *mutual-exclusion mechanism* and got 14;
`network`'s pihole/dnsproxy instance is in neither, and `backup`'s and
`project-manager`'s runbook instances are in neither. Five domains, three
incompatible bounds.

That is the scope trap this file has now paid **seven** times (C03, C29, C01,
C10 twice, C16, C87). The rule it keeps restating: **define the class by its
property, not by the mechanism you happen to be enumerating.** A sweep of the
things that *provide* mutual exclusion cannot see an object that has none — and
an object that has none is precisely what the property names.

The honest state that morning: the property was named, six domains produced
instances, and no sweep had been bounded by the property itself.

**That is exactly what the evening run fixed, and it is the cleanest closure in
this register's life.** Six domains were sent back with one instruction — bound
it by the (object, mutator-set) relation, not by enumerating the things that
PROVIDE mutual exclusion — and six returned a sweep over their own slice:

| Domain | Cardinal | How the space was derived |
|---|---|---|
| `ansible-deploy` | 191/191 | 234 write tasks → 191 objects, each passed to five mutator generators |
| `services` | 106/106 | 32 lifecycles + 68 bind sources + 1 shared netns + 5 datastores |
| `system` | 31/31 | 19 deployed scripts + 39 role `dest:` + kernel singletons, both hosts |
| `network` | 18/18 | smallest unit of destructive interleaving: the record, not the zone |
| `backup` | 12/12 | backup objects, with restic's in-repo lock as the serialiser |
| `project-manager` | 17 runbooks → 4 | operator procedures as a mutator, which no code sweep can see |

**The cardinals differ and that is not a defect — it is the property being
derivation-relative, exactly as C74's closure recorded on 2026-09-11.** Do not
quote any one of them as "the" number. What makes the closure believable is that
each slice states its own derivation and its own blind spot, and that three
generators nobody had counted turned up: `ansible-deploy`'s G3 (a package or
system generator writing a file Ansible also renders), `network`'s seventh
pihole mutator (`RestartPolicy: unless-stopped`, the only one that acts with no
operator, no timer and no deploy), and `backup`'s finding that the serialiser
for ten of its twelve objects is restic's own in-repo lock, which neither
earlier bound contained.

**Two domains produced no slice — `security` and `observability`.** Their objects
are largely covered by `system` and `services`, but that is an argument, not a
sweep, and it is the residual risk on this closure. C90 is therefore ENUMERATED,
**not GATED**: nothing derives the (object, mutator-set) relation continuously,
so the next deploy can repopulate it.

## The run of 2026-09-19 — the key was `collision`, and the estate answered better than the instruments

The twentieth key, invented, chosen by the operator from three the main session
proposed (`collision`, `asymmetry`, `cost`) with each one's weakness stated
first. The six-word question no class had asked: **which two distinct states
produce the same reading?** All 102 classes then on file asked whether ONE thing
was right; not one asked whether TWO things were distinguishable.

Three admissible shapes went into all eight briefs, and a mint rule with them:
(a) two world-states, one observable; (b) two identities in one slot, one
silently taking the other's place; (c) two causes under one message, so the
remediation is chosen against the wrong one. **A collision counted only if the
agent demonstrated BOTH states producing the identical reading** — measured, or
one measured and the other traced through the exact code path. That rule is what
kept the count at four: six candidates were offered.

### The headline — the estate's collisions were cheap to find, the instruments' were not

Three domains reached the same property from three unrelated directions without
contact: `system` from systemd's `Result` field, `observability` from Kuma's
heartbeats carrying no provenance, `ansible-deploy` from a scheduled run that
reported `Result=success` while carrying a failed assertion. That is C103, and
this register's own rule names independent convergence as the strongest evidence
available.

**The measurement that carries it**, re-taken by the main session with both
controls: `offsite-smart-test` last ran on 2026-09-01, and on the service object
it is byte-identical to `homelab-image-retention`, which has never run in its
life — `Result=success`, `ConditionResult=no`, every timestamp empty. The
negative control (`rescue.service`) matches them; the positive one
(`offsite-health`) carries its timestamp. The field that separates them,
`LastTriggerUSec`, lives on the TIMER, survives the reboot that clears the
others, and had **zero occurrences in the repository**.

### Minted — 4, from 6 proposals

| Candidate | Origin | Verdict |
|---|---|---|
| C103 | `system` (2 shapes), converged with `observability` and `ansible-deploy` | **KEPT.** Its manual-versus-scheduled slice is NOT new — that is C100's instance from the previous run — and the row says so |
| C104 | `observability`, offered with a wrong denominator | **KEPT**, denominator corrected 48 -> **219** by the main session |
| C105 | `project-manager` | **KEPT.** The operator declined the remedy the same night; the class stays, as C102's did |
| C106 | `ansible-deploy` | **KEPT**, fix declined |
| The single SSH key covering four roles | `security` | **NOT a mint — an instance, and the operator has declined the second key**: it is assumed |
| The heal timer's `Interval = 0` skip | `services`, filed as C03-R | **NOT a mint** — correctly filed, and it is the run's worst live defect |

### The live defects, ranked by what is happening right now

1. **`immich-server` and `immich-ml` sit outside the only automatic recovery they
   have.** Both declare `Interval=0s` — compose gives them `start_period` and no
   interval — while the daemon probes them every 31 s, measured in
   `State.Health.Log`. `homelab-stack-heal.sh` did `[ "$iv" -gt 0 ] || continue`,
   silently. The two heaviest containers on the machine would never be restarted,
   for any duration of failure. Detection survived (the netdata unhealthy alarm at
   10 min); recovery did not. **Fixed**: fall back to the daemon's 30 s default
   and log which containers are aged that way.
2. **C104 in production, three days running** — see the row.
3. **The Nextcloud log the fail2ban jail re-reads is 30.5 MB in THREE lines**, the
   longest 10.17 MB, plus a 105 MB rotation: one `appstoreFetcher` cURL-23 failure
   a night, whose Guzzle `Trace` field alone measures 10 163 169 bytes. **Fixed at
   the source** (the app store is disabled — it has failed every night since at
   least 09-01, so it was buying nothing) **and bounded under it** (`log_rotate_size`
   10 MiB against the 100 MB default).
4. **C105's restore instance** — declined, recorded.
5. **One SSH key, four roles**, same fingerprint on both hosts, no restriction
   options, and **0 `sftp-server` lines at VERBOSE**: the sshfs mount and an
   intruder holding the key are the same journal line. **Declined — assumed.**

### Rejected from the agents, and why

- **`observability`'s "48 `exec:` checks"** — the deployed spec holds **219**,
  counted twice by independent methods. The 28 multi-branch figure survived both.
- **Three "broken gate" reports** — C44, C20 and C01 are not GATED. Reopenings.
- **`project-manager`'s "`.claude/agents/services.md` omits 12 of 32 services"** —
  **not reproducible**: that file is 45 lines and carries no service inventory at
  all. Its ADR claim, measured, is right and shipped.
- **`services`' upstream tag drift** — the agent withdrew it itself:
  `docker manifest inspect -v` returns per-platform descriptors, not the list
  digest.
- **`network`'s second C102 instance** — kept SUSPECTED, no proposal, the fix
  being declined.

### Register corrections — 4

1. **C44 is ENUMERATED, C20 is ENUMERATED, C01 is closed-by-arbitration.** None is
   a gate; three agents called them broken gates.
2. **C01's space was bounded by a directory.** `.claude/agents/*.md` and
   `CLAUDE.md` were never in it, and they are what every run's eight agents read
   first. Ninth payment of the scope trap.
3. **C07's cost is halved and the gate is unchanged.** Re-measured by the main
   session over a 44 s window with 32/32 containers enumerated as a control:
   netdata **18.33 %** of a core, fleet **58.29 %**, against 42.7 % and 85.6 % on
   2026-09-18. The agent's own figures (21.2 %, 63.2 %) agree within 15 %. The
   gate still derives one collector's cadence, and `netdata.conf` now carries a
   LITERAL `update every = 5` with no link to `netdata_docker_update_every`, which
   is also 5 — two knobs, one value, one of them asserted.
4. **The posture spec holds 219 `exec:` checks**, 42 without `stdout:`, 28 of them
   multi-branch — the intersection is exact.

### Instrument traps paid — 4, and the first one kills an obvious remedy

1. **goss NEVER prints what a check wrote.** Tested on the host against the
   deployed binary: a failing check renders its exit status, and a declared
   `stdout:` renders the literal `"object: *bytes.Reader"`, never the text. So
   "declare `stdout:` to surface the cause" does not work, and the exit status is
   the only field that reaches the alert. This is what shaped C104's remedy.
2. **`--timestamp=unix` works on `ExecMainStartTimestamp` and NOT on
   `LastTriggerUSec`**, which renders human whatever you ask. The locale-free
   route is the monotonic pair, which resets at boot together — verified on the
   offsite, whose 2026-09-01 trigger reads `0` against a 09-12 boot. That
   verification is what makes the shipped check reboot-safe.
3. **A wrong path returns EMPTY, not an error.** The main session read
   `/mnt/data/services/nextcloud/data/nextcloud.log` where the file is under
   `data/data/`, and got silence — the same family as the un-`sudo`'d glob, and
   one step from "there is no log".
4. **A count that agrees with itself proves nothing.** The first block split of
   the goss spec returned 219 by a route that could not have been right (every
   block containing `exec:`). It was only usable once two independent methods
   returned the same number.

### Disclosures by agents, all unprompted — 4 of 8

`network` printed **the private and preshared keys of all four WireGuard peers**
into its transcript through a fallback `select *`; the key set is recorded
non-rotatable in `settled.md` and #138 is open, so it was reported as a fact and
no rotation was re-proposed. `ansible-deploy` printed `private.yml` whole
(gitignored, unencrypted). `security` reversed four low-entropy values from their
own truncated hashes and printed a live password's punctuation skeleton.
`services` ran a `sudo grep -rln` over `/` until its 120 s timeout, against rule
6, and said so. Nothing was written to either host or to the repository.

## The run of 2026-09-18 — the key was `quiescence`, and the audit's own baseline was a false clean

The nineteenth key, invented rather than taken off a list, chosen by the operator
from three the main session proposed (`commensurability`, an invented
`quiescence`, `staleness`) with each one's weakness stated first. The six-word
question no class had asked: **what does this do when nothing happens?** All 100
classes then on file asked what happens when something ACTS.

Three admissible shapes were written into all eight briefs so agents returned
measurements rather than philosophy: (a) a detector that needs an EVENT to notice
an ABSENCE, (b) a state that decays while IDLE because nothing exercises it,
(c) a branch normal operation never takes, run for the first time on the day it
matters.

**The stated risk held.** The brief warned that the key overlaps C83 (empty-set
floors, GATED), C41 and C44, and that a finding there is an instance or a broken
gate, never a mint. Five domains filed into those classes and not one tried to
re-mint them.

### The headline — the baseline said 37/37 green, and it had been true for seventeen minutes

`Pi security posture` pushed DOWN on **each of its three previous SCHEDULED runs**
— 2026-09-16 09:08:39, 09-17 09:11:03, 09-18 09:06:19 UTC, all the 11:0x CEST
slot — with the same two assertions failing both times:

- `miniflux-no-feed-silently-unscheduled`, and
- `traefik-access-log-carries-no-credential`, **timed out at 30 s**.

It is green because a run started at **21:18:03** by hand, while the timer's last
trigger was 11:05:30. And `/etc/goss/posture.yaml` was replaced at **21:23:31**,
five minutes AFTER that run, so **the green beat does not test the deployed
spec**. The operator had committed the deadline fix at 21:13 the same evening; its
own message reads *"has timed out on every posture run since 2026-09-16"*.

The main session took its baseline at 21:35 and wrote "37/37 green" into all eight
briefs. **That is the founding defect of this skill, committed by the skill
itself**: a mechanism that looks like it works, observed at the one moment it
does. `observability` found it from the monitor side; the main session re-measured
it from the raw beats.

A timeout renders as a FAILURE in goss, so a check that is merely SLOW pushes the
same red as a check that is WRONG. That is the general form, and it is what the
remediation addresses.

### Minted — 2, from 4 proposals

| Candidate | Origin | Verdict |
|---|---|---|
| C101 | `system`, 5/5 swept, offered as "a mint OR a C03 instance" | **KEPT**, and re-verified by the main session in all three artefacts |
| C102 | `network`, offered as a C29 instance with a mint as second choice | **KEPT as the mint.** C29 is *a construct that disables a feature silently*; this is a repair whose trigger and input share a cause, which no class names |
| The single terminal link (the Discord webhook, covered by no assertion) | `observability`, **offered as a candidate and not claimed** | **DECLINED**: no defective instance. The agent proved the link live without writing a test heartbeat |
| The heal timer's asymmetric rate limit | `services`, filed SUSPECTED | **NOT a mint** — it is an instance, and the operator deferred the investigation |

### Instances that matter, all re-measured by the main session

1. **C100 — the posture monitor**, above. Half of it was already fixed by the
   operator at 21:13 and is **deployed but unexercised**; the Miniflux half was
   not covered by that fix and recurs.
2. **C101 — nothing asserted that a control timer is armed**, above.
3. **C102 — the offsite tunnel pinned on a wildcard address**, above.
4. **C07 IS RED — a broken gate, reported as a red test and not as a finding.**
   `services` measured netdata at **41.9 % of a core continuously with the machine
   at rest**, `apps.plugin` alone at 22.4 %, walking `/proc` for 259 processes once
   a second. The main session confirmed it by a different method — an independent
   30 s cgroup window — at **42.74 %, against 85.59 % for all 32 containers**, so
   netdata is about half of the fleet's CPU. Four windows agree. **The gate derives
   the DOCKER collector's cadence only** (`((600 / netdata_docker_update_every) *
   0.833)` renders both the alarm threshold and the goss floor), so `apps.plugin`
   is outside the space it covers. The class is defined by polling cost
   disproportionate to the granularity of what it feeds; the gate is bounded by one
   collector. **Same shape as the eight previous payments: the derivation is sound
   and it keys on the wrong axis.**
5. **C88 instances, 3 live and latent** — `restic forget` groups by `host,paths`
   with no `group-by` in the deployed profile, so changing `source:` freezes the
   old group forever (22 of 34 local snapshots, and the offsite profile carries no
   `retention:` block at all); netdata's group removal is all-or-nothing while its
   install is per group; a sysctl key contains a FACT (`ansible_default_ipv4.
   interface`), so renaming the interface strands the old line.
6. **The heal timer bounds the branch that never ran.** `services` filed it
   SUSPECTED; the main session confirmed it from the journal. On 2026-09-06 between
   01:03 and 01:07+, seven containers including `immich-db`, `miniflux-db` and
   `nextcloud-db` were restarted every ~2 minutes with repeated `ERROR: failed to
   restart`. The `running`+`unhealthy` branch carries a one-restart-per-hour lock
   with a comment explaining it; the `exited`/`created`/`dead` branch carries none,
   and it is the one that executes. **Deferred by the operator for investigation.**
7. **The apt feed has no freshness assertion** (`security`). Both hosts' stamps
   were fresh when measured (10 h and 16 h) and `apt-daily.service` reports
   `Result=success` either way, because `apt.systemd.daily` swallows a failed
   `apt-get update`. A dead update feed and a fully-patched host are the same
   observable. Outside C83's reach by design — its gate keys on ITERATIONS.

### Rejected from the agents, and why

- **`backup`'s proposal to reclaim the frozen snapshot groups.** The instance is
  real and confirmed; the proposal is the FOURTH pass at a declined decision.
  `settled.md` carries three entries and this sentence: *"A third proposal needs a
  new consequence, not a new number."* The agent brought a number — 253 GB — and
  the number was also wrong. Measured by the main session: repo 414.4 GiB, live
  group alone 342.7 GiB, so **71.7 GiB**, which is the figure already declined.
  **Its third proposal survives**: the dual assertion *no path group whose set the
  profile no longer declares*, which would have fired on 2026-05-25, 2026-07-13 and
  2026-09-13. That is the gate C88 has never had.
- **`observability`'s "one of the two assertions fails by timeout".** There are
  two, and the second is Miniflux, which no commit addressed.
- **`services`' "netdata costs more than the other 31 combined".** Measured 42.74
  against 42.85. It is half, not more.
- **`system`'s "units.yaml names six services and no timer".** It names fifteen;
  the "no timer assertion" conclusion holds and is what carries the mint.
- **`ansible-deploy`'s marker cardinal.** Reconciled rather than rejected — see
  the C88 closure. The agent's derivation is broader and its blind spot is worse
  than it reported.

### Register corrections — 3

1. **C19's script half enumerates 14 timers, not the 13 this file recorded**, with
   zero edits to the script, which is positive proof of derivation.
2. **C40 is 26 containers at the 10 s default, not 25** — the fleet went from 29 to
   32 and the three new arrivals came in at the default.
3. **This run's own baseline was wrong in a way that reached all eight briefs**,
   for the fourth time a counter in these files has done so. "15/15 `homelab-*`
   services at `Result=success`" counted `homelab-image-retention.service`, which
   **has never run** — and `Result=success` is also what a unit that has never run
   reports. The measurement that corrects it is C101's.

### Instrument traps paid — 4, all by the main session, and one is aimed at last week's rule

1. **Kuma prunes raw heartbeats after about 48 hours.** 57 295 rows span
   2026-06-22 to now, but the daily counts read 26 189 (today), 30 177 (yesterday),
   then **31 per day** beyond — while `keepDataPeriodDays` is **180**, which reads
   as six months. What survives is `important = 1` plus `stat_minutely` (from
   2026-09-14 22:36), `stat_hourly` and `stat_daily`. **`settled.md`'s rule of
   2026-09-13 — "before recording that a failure was unobserved, query the
   monitor's own beats" — therefore has a shelf life of two days.** Past that, the
   question is answerable at the hour, never at the minute. Every run that asks it
   must say which store it read.
2. **An empty enumeration returned the healthy value, in the main session's own
   instrument.** A per-container CPU loop built the cgroup path from
   `docker ps -q`, which is the 12-character id, while the path needs the full 64.
   It matched nothing and printed `0.00 % over 0 containers`. Only the control line
   (`wc -l` on the collected set) caught it. This is the exact defect C83 exists
   for, committed while measuring.
3. **A wrong field name reads as a zero, not as an error.** Checking whether Kuma
   monitors carry TLS expiry notification, the main session read `expiryNotification`
   where the column is `expiry_notification`, got 0 of 18, and was one step from
   filing a documentary claim of "15 of 18" as false. It is true. **A count of zero
   from a named field must be controlled against a field known to be populated.**
4. **PostgreSQL has the same double-quote misfeature as SQLite.**
   `to_char(checked_at, "YYYY-MM-DD")` fails with `column "YYYY-MM-DD" does not
   exist`. Single quotes in every SQL, in both engines. The SQLite half of this was
   paid on 2026-09-13; this is its sibling.

Two more, lower cost, recorded because they are repeatable: a control chosen on
the homelab (`/etc/goss/units.yaml`) proves nothing on the offsite, where that
file does not exist; and `du` counts a hardlinked file once per path, which is how
71 GB of Transmission downloads looked like reclaimable space.

### Disclosures by agents, all unprompted

`security` printed **two live Kuma push tokens** into its transcript through a
`grep -B4 -A25`, and wrote one ERROR line into `/var/log/fail2ban.log`;
`observability` created and deleted `/tmp/wh.<pid>` holding the Discord webhook
token; `ansible-deploy` left five path-list files under `/tmp` on each host;
`backup` ran `restic snapshots --no-lock` against the LOCAL repository only and
nothing at all against the offsite. All four reported themselves before being
asked, which is why the rest of their reports were believed. The token exposure
falls under the operator's arbitration of 2026-09-12 — LAN- and tunnel-reachable
only — and was reported as a fact, not re-proposed as a rotation.

## The run of 2026-09-13 (night, second) — the key was `reversibility`, and the previous night's fix had deleted a working detector

The eighteenth key, chosen by the operator from three the main session proposed
(`commensurability`, `reversibility`, an invented `indeterminacy`) with each
one's weakness stated first. The six-word question: **does this have an inverse,
and does the inverse restore the prior state?** Three admissible shapes were
written into all eight briefs so agents returned measurements rather than
philosophy: (a) the inverse restores something ELSE, (b) no inverse exists and
one is assumed to, (c) the inverse exists and has never been exercised.

**The stated risk held and it paid the way it was meant to.** The brief warned
that C88 was OPEN on exactly this axis, so a growing store would be an INSTANCE
and not a mint, and that filing it as an instance was worth more to the run than
a mint. **Five domains filed C88 instances and not one tried to re-mint it.**

### The headline — `SuccessExitStatus=1`, shipped the previous night, deleted the detector that made its own justification true

Two agents, no contact, opposite directions, same defect. The register's own rule
names that as the strongest evidence available.

**The premise, written into all three units, is false.** It reads *"This script
REPORTS by pushing DOWN to [Kuma]"*, so a systemd failure is a duplicate worth
suppressing. Measured at the deployed byte:

- **`homelab-feed-digest` (`backup`).** `digest.sh` cannot always reach its own
  reporter: `set -euo pipefail` at line 18, `mkdir -p "$(dirname "$LOG")"
  "$DIGEST_DIR"` at line **60** with `DIGEST_DIR` inside `/home/claude/vault`,
  `notify()` at 109, `fail()` at **157**, `trap ... ERR` at **158**. The vault
  gate moved into the script the previous night "three lines after `fail()`
  exists" is at 162 — **102 lines after the statement that touches the vault
  first.** An EIO there kills the script with no trap and no reporter, and it did
  exactly that at 06:34:01 on 2026-09-13.
- **`homelab-offsite-check` (`security`).** It is the one unit of the ten
  carrying `SuccessExitStatus` whose `ExecStart` is not a repo script at all —
  `resticprofile --lock-wait 2h -c ... -n offsite check`. Its DOWN beat is
  `run-after-fail` (`resticprofile.yaml:452-453`), a hook that does not fire when
  resticprofile aborts BEFORE the command. Demonstrated that same morning on the
  sibling unit: `homelab-local-maintenance` hit its 2 h lock ceiling, exited 1 at
  07:00:01 before the profile started, and monitor 22 got no beat at all.
- **`homelab-ddns` is sound** and the main session checked it rather than
  assuming the pattern: `notify()` is defined at line 26, before anything touches
  the filesystem or the network. Its `SuccessExitStatus=1` is justified.

**What actually reported the failure was not the script**, and this is the part
that turns a documentation error into a regression. Kuma, monitor 20 `Pi health`,
UTC:

```
2026-09-13 04:41:12 | status=0 | units: systemd-no-failed-units;
                      last run failed: homelab-feed-digest.service
```

Failure 04:34:01 UTC, announcement 04:41:12 UTC — **+7 min 11 s, with the cause
named.** Control: 1 665 beats in that window, 1 646 UP and 19 DOWN, so the window
is populated and the filter discriminates. That detector works **because**
`systemctl` said the unit had failed. `SuccessExitStatus=1` makes `systemctl` say
success, and `homelab-health.sh:659` reads
`case "$r" in ""|success|exec-condition) continue`.

### The register's own account of the previous night is WRONG, and the correction matters

That run's second headline reads *"a scheduled job failed at 07:00 and told
nobody"* and *"the failure is silent"*. Measured from the live database:
`Pi health` announced `homelab-local-maintenance.service` **by name at 07:06:04
CEST**, and carried it for **72 DOWN beats over six hours** alongside
feed-digest. Monitor 22's silence is real and remains true; **"told nobody" is
not.**

This is not an argument for re-opening `OnFailure=`, which is permanently
declined and was not raised by any agent. It is worse than that: **the same false
premise drove two decisions the same night.** The decline was made safe by a
detector nobody had noticed, and the other decision deleted it.

### Minted — 1, from 2 proposals

| ID | From | Arbitration |
|---|---|---|
| C100 | `observability`, 20/20, **offered as a candidate rather than claimed** | **KEPT.** Verified end to end by the main session |

`homelab-health.sh:643` reads `systemctl show -p Result`, so the alarm's
clearing condition is *a run succeeded*, not *the schedule works*. Measured, UTC:
at 10:26:16 `local-maintenance` drops out of the message; at **10:40:55 monitor
20 returns status=1**; it is still green at 21:26:28. The hand-run at 12:24 CEST
supplied the success. **The next SCHEDULED run is Tue 2026-09-15 01:00** — about
38 hours of green over a cadence nothing has exercised since it failed.

**This is the machine-side twin of the instrument trap the main session paid the
previous night** — *"a unit's current state is not its cadence's history"* — which
`settled.md` recorded as a human error. It is also a deployed mechanism's error.
`domains.md` says the keys that pay best come from an instrument trap in
`settled.md` that no class has adopted; this is that, with a cardinal and a live
instance.

**Declined — 1**, and it was offered rather than claimed: `observability`'s
second candidate, the certificate ratchet whose only inverse (`rm $CERT_STAMP`)
exists nowhere outside the deployed script. Filed as a latent instance of C88's
property in the `acme.json` store, not minted.

### Register corrections — 5, and the first one reached all eight briefs

1. **The OPEN counter said 4; the genuinely open count was 2.** C98 and C99 were
   minted ENUMERATED, which is not OPEN. A move is not a state.
2. **The previous run's "told nobody" is false** — see above.
3. **C30's row says 19/19 routers and headers on 18/18; it is 24/24 and 22/22**,
   with zero edits in between — the same derivation proof C14 earned going 18 ->
   21. And *"vpn-only proven both ways"* must drop "both ways": the deny
   direction has no instrument anyone can now repeat, and `settled.md` records
   why.
4. **C19's auto-restart half is DERIVED, not a list** — `homelab-health.sh.j2:615-616`
   filters on the systemd sub-state and names no unit. The `:552` comment about
   units being "enumerated and NAMED" is about why it cannot move into goss. The
   goss half is unchanged: 6 `service:` + 9 `command:`, 1 derived.
5. **C14's blind spot is measured EMPTY**, with a control: 21 router names = 21
   `acme.json` certs = 21 split-DNS records, and all 21 serve a real Let's
   Encrypt leaf over SNI. Two uncovered names returned `SSL alert 112
   unrecognized name, no peer certificate`, so the probe discriminates. No name
   is invisible.

### Gates re-read — C03-T is GREEN, and two more are LISTS

**C03-T holds.** `h.status = 1` is live on both clauses
(`/etc/goss/posture.yaml:3121`, `:3133`), it evaluates, and the repaired branch
has actually executed (2 markers in-window, `lost=2`), posture exit 0 in 44 s.
**Residual, and it is stated rather than glossed**: it has never yet completed a
SCHEDULED run — the next is 2026-09-14 11:04, and its 09:05 run timed out at 45 s
alongside three other assertions.

**What the real store holds that a fixture could not, applied as the previous
run's lesson demands**: 75 GENUINE `status=0` pushes today plus 61 PENDING rows,
so a live reporter correctly reporting a failure is, to both clauses,
indistinguishable from a mute one. **That direction is fail-safe** — it over-
reports rather than under-reports — so the gate is not blind; but the sentence it
prints can name the wrong cause.

**C41 DERIVED** (`:2033-2052`), and its correctness is *calibrated against* Kuma's
fabrication rather than independent of it. **C35 and C45 are LISTS**: no assertion
touches `heartbeat.msg`, and C45's 10/10 is repo-bounded. **C17 is a LIST** — 3
assertions hardwired to `/`, 3 of 4 filesystems unasserted. **C23** re-swept 74/74
on both hosts, 0 differing, and its space derives from the files. **C32** was a
hand-list and `network` re-derived it as every `0.0.0.0` TCP listener, 5/5.

### Instances that matter, all re-measured by the main session

- **The fsck trigger documented as permanently inert is not inert.**
  `filesystem-checks.yml:131-142` states the pre-NTP clock "is the mtime of the
  systemd binary and therefore a FIXED date", predicts `Last checked Tue Jul 28
  17:04:59 2026`, and concludes "the interval is never due and never will be".
  Measured on both hosts: the systemd binary mtime has NOT moved (2026-07-28
  17:04:45) while `Last checked` reads **2026-09-05 22:56:03** on homelab and
  **2026-09-06 04:00:00** on offsite. The named source is therefore wrong and the
  conclusion drawn from its fixity falls with it — `Next check after` is
  **2026-10-05 / 2026-10-06**, three weeks out. `system` found it and correctly
  refused to guess the real source; the main session did not identify it either.
- **The Pi-hole restore recipe restores over a running container**
  (`docs/05-services/pihole.md`), then `docker restart`. `wireguard.md:158` states
  the rule it breaks verbatim — *"restored the raw data directory over a
  **running** container instead of the dump, and `restart` is not `down`"*. The
  09-13 correction landed on that one page and stopped. **A C92 instance inside
  the audit's own remediation, for the third time.** The fix is not simply
  `compose down pihole` — dnsproxy shares its netns.
- **Two latent C88 instances where the OPERATOR VARIABLE is the register**
  (`ansible-deploy`, a sub-axis no prior sweep contained). Emptying the Netdata
  push URLs — the documented opt-out — leaves the alarms, adapter and timer in
  place and firing while the run prints "no alarm, adapter or timer was
  installed"; `netdata.yml` contains **zero** `state: absent`. And
  `miniflux_api_key` is skipped-on-empty (`digest.yml:41-47`), so clearing the
  vaulted value leaves the file — verified by metadata only: **64 bytes, mode
  400, owner claude, mtime 2026-08-13 22:58:51** — still read at
  `feed-digest.sh.j2:22`. A revocation that does not revoke.
- **A C78 instance** (`observability`): Prowlarr/Sonarr/Radarr carry
  `expiry_notification = 0` while `uptime-kuma.md:64` and `README.md:589` both
  say every HTTPS monitor watches expiry. No certificate is unwatched — health
  covers 21/21 — so the defect is that the documented *reason* for the gap is now
  wrong for half of it.

### Rejected from the agents, and why

- **`services`' image-retention arithmetic, in both halves.** It reported "42 of
  44 unreferenced images go; 1 of 14 services keeps its previous tag". Re-measured
  per repository: of 18 repos holding an unreferenced previous tag, **6 keep it
  and 12 lose it**; restricted to the comment's own scope — bumped this month —
  **7 qualify and exactly one loses its rollback tag, navidrome**, because 0.63.2
  was *built* 2026-07-11 and stayed in service until 2026-09-12. **The mechanism
  it found is real and is the finding**: `--filter until=` reads the image's
  upstream BUILD date, not the local pull date (`wg-easy:14` carries 2025-06-03 on
  a host born in July 2026; controls `until=1h` -> 73/73 and `until=87600h` ->
  0/73). The comment at `image_retention.yml:22-25` is true by luck this month and
  false as a rule. **Impact bounded and small**: all 8 lost rollback tags checked
  are still pullable upstream, with both controls, so the cost is bandwidth and
  never data. Fix the sentence, not the mechanism — which `services` itself
  concluded after refuting its own escalation.
- **`security`'s stale wg-easy peer claim**, self-refuted (the container has only
  been up 2 days), and the Sunday/Tuesday timer discrepancy (PR #354 rewrote the
  timer at 12:22 that day).
- **`network`'s `udp/50349` with no owner**, self-refuted: it is wg0's kernel
  socket, and its `/proc/*/fd` sweep correctly found the control socket's holder
  and none for this one.
- **`project-manager`'s two near-mints**, both self-rejected as C98 and C92 seen
  from the other end.

### Instrument traps paid — two are NEW and one is aimed at this skill's own brief

1. **`sqlite3 "file:X?mode=ro"` is read-only at the SQL level, NOT at the
   filesystem level.** `project-manager` created a zero-length `-wal` and a 32 KB
   `-shm` beside two dormant Kuma rollback copies at 23:20:28. Impact nil — inside
   the `kuma-pre-*` restic exclusion — but it was a write, and **this skill's own
   observability brief mandates `mode=ro` as the safe form.** It is not sufficient
   on its own.
2. **SQLite's double-quoted-string misfeature** (`observability`, disclosed):
   `type in ("http","keyword")` silently became `type IN ('http', monitor.keyword)`
   because a column of that name exists — 12 rows instead of 18, **and a false
   CLEAN on the very defect it then found.** Use single quotes in every Kuma query.
3. **`docker image prune --filter until=` reads the image's upstream build date**,
   not its local pull date. Anything reasoning about rollback age from it is
   measuring the wrong clock.

**Rule-5 writes — two, both disclosed unprompted.** `services` wrote and deleted
two files under `/tmp` on the host; `project-manager`'s is trap 1 above. Both
agents reported themselves before being asked, which is the standard this register
asks for and the reason the rest of their reports were believed.

## The run of 2026-09-13 (late evening) — the key was `repetition`, and the gate deployed that afternoon was already blind

The seventeenth key, chosen by the operator from three the main session proposed
(`commensurability`, `reversibility`, `repetition`) with each one's weakness
stated first. The six-word question no class had asked: **what if this runs
again?** Note the distinction that was written into all eight briefs, because it
is the one that made the key productive: `concurrency` asked what happens when
two run AT ONCE; this asks what the SECOND run does to the result of the first.

Three admissible shapes were given so agents returned measurements rather than
philosophy: (a) a retry that duplicates rather than replaces, (b) an append where
a rewrite was meant, (c) a second run that consumes what the first produced.

**The stated risk held exactly as written.** The brief warned that Ansible
idempotence is swept ground and that a finding there would be a re-derivation
rather than a mint. Not one of the four register moves came from an idempotence
finding, and `ansible-deploy` re-derived C28, C29 and 21 notify sites clean while
minting on a different axis entirely.

### The headline is a BROKEN GATE, and it is C03 defeated for the sixth time on the same axis

**C03-T** — `no-kuma-report-was-lost-in-silence`, deployed 2026-09-13 14:15:44,
promoted to GATED that same afternoon after being **made to fail on purpose in
six runs including a discriminating twin**. It is blind, and it was blind on the
day it shipped.

Uptime Kuma 2.5.0 (`monitor.js:755-760`) FABRICATES a DOWN beat carrying the
message `No heartbeat in the time window`, once per interval, for any push
monitor whose previous beat is not UP. There is no time term in the disjunct.
C03-T's two clauses both count rows in `heartbeat` with **no `status` and no
`msg` filter**:

```
beats=$(kq "select count(*) from heartbeat h join monitor m ...
            where m.type='push' and m.active=1 and h.time > '$loss_utc';")
silent=$(kq "... left join (select monitor_id, max(time) t from heartbeat ...")
```

So a genuinely mute reporter can never satisfy either clause: Kuma keeps writing
its rows for it. Verified live by the main session — **39 fabricated rows on
2026-09-13, 36 of them for monitor 20 (`Pi health`), all at `status=0`**, against
164 real `status=1` rows for the same monitor the same day. Both kinds coexist,
which is what makes a row count meaningless.

**C41 is immune and the reason is one predicate.** It filters `h.status = 1`
(`posture.yaml:2048`) and the file's own comment at :2016 argues for it. C03-T
does not. That is the whole difference between the two gates.

**Why the six-run proof passed anyway, and this is the lesson worth carrying.**
The fixture was a SYNTHETIC Kuma database, which by construction contained only
the rows the test itself wrote. It could not contain rows the upstream writes on
its own. **A gate proven against a fixture is proven against the fixture's model
of the world, not against the world.** The proof was sincere and the gate is
still blind.

**The remedy is NOT the one first proposed.** Matching the English literal
`'No heartbeat in the time window'` makes the gate depend on an upstream string
a Kuma upgrade can change without warning — the `succession` axis, already paid
here. The correct predicate is `h.status = 1`, which C41 has used since
2026-08-30.

### The second headline: a scheduled job failed at 07:00 and told nobody, and the audit's own baseline said it was green

`homelab-local-maintenance` waited **1h55m** for the resticprofile lock held since
03:00:09, gave up at its 2 h ceiling, and exited 1 at 07:00:01 — **before the
profile started, so no hook ran**. Monitor 22 (`Pi restic prune+check`, push)
received **no beat at all that morning, neither up nor down**. Its only beat since
the previous evening is 10:25:04 UTC — the hand-run at 12:24:27 that also reset
the unit to `Result=success`.

This is **C95's "lock-wait timeout" mute emitter**, one of the five kinds
`backup` enumerated when it closed C95 six hours earlier the same day. The class
predicted the shape and the shape fired.

**`OnFailure=` is empty on 14 of 14 `homelab-*` units**, and exactly one unit on
the whole host declares one. So every scheduled job depends on its own script
reaching its own notification code. When the script dies first, the failure is
silent. C41's silence fuse is the backstop, but it fires on the monitor's own
window rather than on the failure.

> **DECLINED BY THE OPERATOR, 2026-09-13 (late evening), with the instruction
> that it NEVER be raised again** — not with a new number, not with a fresh
> instance, not folded into a larger lot. The measurement above stands as a
> record of the gap; the gap is carried knowingly. See `settled.md`. Every other
> finding in this run's lot was accepted and shipped; this one alone was refused,
> which is why the refusal is recorded next to the evidence rather than only in
> the decline list.

**The main session's baseline was the lying instrument**, and it is recorded here
rather than in `settled.md` because it is evidence about the METHOD:
`systemctl show -p Result` reports the LAST run. The baseline read "14/14 at
`Result=success ExecMainStatus=0`" at 21:25 over a unit whose *scheduled* run had
failed that morning. **A unit's current state is not its cadence's history.**

### Minted — 2, from 5 proposals

| ID | From | Arbitration |
|---|---|---|
| C98 | `project-manager` (8 reference points) + `backup` (12 workspaces) | **MERGED into one class.** Two ends of one property, derived independently with no contact. C90/C97 precedent |
| C99 | `ansible-deploy` (31 in-place writes) | **KEPT.** Distinct from C88: C88 fails to REMOVE, C99 fails to MATCH |

**Declined — 2, and both were offered rather than claimed by their own agents,
which is what makes the other two credible.**

- `system`'s *"a periodic mechanism whose decision to act is read from a record it
  rewrites on every run"*. Swept over logrotate state (22/19), the gate library,
  heal latches, `pending.last`, 23 systemd stamps and 6 apt stamps: **0
  defective, anywhere, ever**. A property with a cardinal and no instance is a
  hunch with arithmetic. Recorded in `settled.md` as a swept-clean property.
- `security`'s *"a declarative apply step that adds but never retracts"*. Its own
  agent rejected it as a re-mint of C88 and filed it as an instance with the
  bound named. Correct — and it became the second derivation that REOPENED C88.

### Rejected from the agents, and why

- **`system`'s `/var/log/sudo.log`** — 88 168 entries, 15.7 MB, no rotated
  sibling, same signature on the offsite. Refuted by its own agent before filing:
  `/etc/logrotate.d/sudo` was born 2026-09-12 15:10 (`8a4c186`), logrotate
  registered it at 00:00:08 today, and it falls due 2026-09-20. It also caught
  itself hitting `settled.md:491` — a single-file `logrotate -d` bypasses the
  global `su root adm`.
- **`network`'s host-side probe of the `vpn-only` allowlist.** `curl --interface`
  from 172.17.0.1 and 172.19.0.1 both returned 200, but the access log shows
  Docker masqueraded them to 172.18.0.1. **The instrument has no discriminating
  power in either direction** and the agent said so rather than reporting a hole.
- **`services`' "no output" disclosure**, corrected by the agent itself after
  filing: its `du -sh /mnt/data/docker` did complete, at exit 0, so the rule-6
  walk ran over the whole store with seven agents on the board. It also refused
  to scale 16.62 GB by the 51 G / 32.4 GB ratio it had just measured, on the
  grounds that the gap is recorded and not attributed. Both refusals are the
  standard this register asks for.
- **The `kuma-pre-2.6.0.db` "no dedup partner" claim** (`project-manager`). The
  exclusion by literal path is verified and real (`resticprofile.yaml.j2:292-293`,
  `data_dirs.yml:316-317`), so the NEXT migration's residue is not excluded. The
  dedup half was not verified and is not relayed.

### Register corrections — 4, and three were rows going stale under a working gate

1. **C19's derived floor is at `homelab-health.sh:665`, not `:592`.** Verified.
2. **C14's cardinal is 21/21, not 18/18.** And the growth from 18 with **zero
   edits to the script** is positive proof of derivation, which is worth more
   than the number. Its "silent ACME failure" half is a PROXY — expiry < 21 d plus
   a one-directional count ratchet. A name that never obtains a certificate is
   invisible by construction, and the script says so itself.
3. **C12's row is STALE and the class is STRONGER than recorded.** "No live
   assertion at all" is false since #333: `posture.yaml:225
   secret-mounts-carry-the-current-value` asserts the property, generated from
   `compose.services[*].secrets`, 14/14, with a live starvation guard. Candidate
   for re-promotion to GATED. Its runtime floor `read_pairs -eq 14` is
   tautological — both sides come from one render — so the floor is decoration.
   Its blind spot is 3 of 17 mounts bind-mounted at arbitrary paths; all 3
   measured MATCH tonight.
4. **C21's description is stale for the THIRD time, and the stale word is
   "monitor"** — there is no retention monitor. The guarantee is structural
   (`copy:` carries no bound, in the deployed file and in `resticprofile show`)
   plus the copy push monitor. 91 offsite / 34 local snapshots, 0 locks.

**And one correction the register should stop needing**: `services` reports the
2026-09-05 "C11 BROKEN" verdict wrong for the **third** time. C11 is derived 9/9,
emitted inside `{% for … compose.services.items() %}`. Retire the comparison.

### Gates re-read — 9, and 8 held

C15 DERIVED (keys on `/proc/<pid>/cmdline` of the live rest-server; evaluated
DAILY, not weekly as its own comments say). C18 DERIVED, the PR #352 repair is
live at 46 assertions, and **no new database has appeared outside the gate** —
20 SQLite stores enumerated at depth 6, all gate members, DECLINED, or migration
residue. C21 sound. C41 DERIVED and immune. C07 DERIVED, confirmed at source —
one Jinja expression over `netdata_docker_update_every`, four consumers. C11
DERIVED 9/9. C14 DERIVED. C81 NOT BROKEN, both blind spots still empty, exercised
in a sandbox with a `.yaml` control that passed on the file the hook was invoked
for. C96 unchanged — homelab 20/20, offsite 9/9, zero orphans.

**C19 is the one that did not hold, and it is not new**: the goss half is A LIST
— 6 named `service:` entries + 8 named `command:` assertions, **1 of 15 derived**,
and that one still exits 0 with the binary absent. Byte-identical to 2026-09-05.
`systemctl --failed` also cannot see an auto-restart loop (`fail2ban` and
`claude-remote-control` both carry `StartLimitIntervalSec=0`), so that half of
the property lives only in the script.

**Template-vs-deployed verified clean in both directions, 317 assertion names
over 4 specs** — posture 221, units 14, backup-dumps 46, offsite-health 36; 0
template names missing from a host, 0 deployed names a template cannot generate.
**Every "derived" verdict in this file that rests on a goss template is therefore
safe.** `--max-concurrent 8` is live.

### The remediation turned a gate red, and the gate was right

`offsite-parity-register-covers-every-control-timer` failed on the first posture
run after the fixes deployed. The new `homelab-image-retention.timer` had no
entry in `homelab_control_timers`, and that assertion derives the set of
controls from the MACHINE — every `homelab-*.timer` with a unit file — refusing
to pass until a decision exists for each.

**It caught this session's own work within the minute.** It is the clearest
demonstration in this register of what separates a gate from a sweep, and it
arrived unprompted, on the people writing the register. The entry added is a
fact about the host and not an opinion about the check — docker absent from the
offsite, re-verified rather than inherited from the line above it.

### Instrument errors by the main session — 2, both caught by a control

1. **The baseline itself** — `systemctl show -p Result` over the last run, read
   as a statement about the cadence. See the second headline.
2. **An un-`sudo`'d glob over a 0700 directory**, paid for the third time in this
   file: `sudo ls -l /mnt/data/services/uptime-kuma/kuma.db*` returned "No such
   file" while `sqlite3` opened the same database in the same second. The glob
   expands in the unprivileged shell. `sudo sh -c '...'` gave 11 436 032 / 32 768
   / 4 181 832 bytes. **The rule was already written in `settled.md` trap 5 and in
   the brief this session wrote**, and it was broken anyway.

## The run of 2026-09-13 (evening, second) — the key was `locality`, and it emptied the OPEN table

The sixteenth key, invented because the register recorded that no named dimension
was left. The six-word question no class asked: **from WHERE is this mechanism
evaluated?** The fifteen before it asked *when*, *in what order*, *by whom*, *how
many*, *against which version*, *what survived removal*, *what if two match*,
*does the remedy need what it fixes*, *at what grain*. None asked whether the
point of evaluation contains the object.

Three admissible shapes were given so agents would not return philosophy: the
same name with two referents; written here and executed there; an object whose
real origin is not the one assumed. All three had unclassed precedents in this
lab — the symlink resolved in a container's mount namespace (#27), the Docker DNS
hairpin, and the 144 SSH connections from a bridge that the previous run had
measured and mis-attributed.

### Minted — 2, from 3 proposals

| ID | Property | Space, and its cardinal | State |
|---|---|---|---|
| C96 | **A rule whose predicate is an ADDRESS, evaluated at a point in the path other than the one that produced the record the address came from** | address allow-lists × evaluation point. **N = 11, swept 11/11, 1 defective.** Stated blind spot: rules carrying no source predicate are outside it | ENUMERATED |
| C97 | **A document instructs the reader to act using a name whose referent depends on where it is resolved, and does not say where** | bounded by GENERATOR, not by directory: the six resolver classes a typed name can go through — DNS, the workstation's SSH config, a mount namespace, the working directory, the user's home, the host identity. **150 sites, swept 150/150, 21 confirmed** | ENUMERATED |

**C97 is minted lab-wide rather than as a documentary class, and the reason is
convergence.** `project-manager` derived it from documents and explicitly put the
scope decision to the main session. Four other domains reached the same property
from unrelated directions in the same run: `services` ("the person who writes
`stop_grace_period` writes it in compose.yaml, the thing it governs happens in
the container, and the record of its failure is in a third place"),
`observability` ("emitters and the notifier use different resolvers and only the
notifier's was ever fixed"), `backup` (a runbook restoring to `/restore` then
pointing at three absolute symlinks that dangle under a staging root), and
`ansible-deploy` (six controller-side `lookup()` calls). Five independent
derivations is this register's own strongest evidence, and C90 is the precedent
for minting once with per-domain slices.

**Declined — 1.** `system` offered "a failure recorded only in the supervisor's
namespace" for arbitration and did not claim it, asking whether it was C03-R
restated. Declined: it proposes no bounded space, and its instances — the
transmission SIGKILL visible only in dockerd's journal — are already members of
C97. Recorded because a declined near-mint is what makes the other two credible.

### The baseline was green and the journal disagreed on four points

0 failed units on both hosts, 32 containers up, 13 `homelab-*` timer services at
`Result=success ExecMainStatus=0`. The 24-hour journal contradicted it four
times, and all four were handed to the agents as leads rather than kept back.
**Three confirmed, one premise refuted — and the refuted one was the main
session's.**

### The run's two headline instances, both re-measured by the main session

**1. SSH over the VPN, and the firewall was right.** `33bda23` scoped ufw's SSH
rule to the LAN and `10.8.0.0/24` that afternoon. wg-easy masquerades every VPN
client behind its own bridge address — `-s 10.8.0.0/24 -o eth0 -j MASQUERADE`, in
the CONTAINER's nat table, which is why it is absent from the host's — so a
client addressing the host's LAN address arrives with a source the allow-list
does not contain. Probed from that exact address with controls in both
directions: 24717 blocked, 443 and 51413 reachable, port 9 refused.

The first reading was "the firewall must be widened", and it was wrong. The host
is a peer of its own wg-easy at `10.8.0.5`, so a client addressing the TUNNEL
address arrives over `wg0` carrying a `10.8.0.0/24` source and matches the rule
as written — verified, reachable, in the same run. **The rule does exactly what
it says; the address used does not.** Widening it would have re-opened what
`host_vars` refuses in writing. Nothing in the firewall changed.

This is C96's one defective member, and the near-miss is the finding: the fix
that a competent reading suggests is the one that removes the protection.

**2. 89 corrupt pieces, and the sample said three.** `services` found transmission
SIGKILLed at 01:25:38 mid-write (dockerd: "failed to exit within 10s of signal
15"), re-hashed a sample of the payload against the SHA-1 list in its own
`.torrent`, and reported 3 bad pieces in one episode — 24 MiB — with ten control
pieces matching. The main session re-hashed the same sample, reproduced all three,
**and found a fourth the sample had not covered: the last piece.** The full
enumeration of all 1579 pieces then returned **89 bad — 712 MiB across six of the
eight files** — with two independent runs producing byte-identical piece lists and
a bit-flip negative control.

**The sample was thirty times off, and the method was sound.** This is the
clearest demonstration this register has of its own founding rule: enumeration
ends what sampling perpetuates. It is recorded here rather than in `settled.md`
because it is evidence about the METHOD, not a decision.

Transmission reports `13.24 GB verified`. The file is hardlinked into
`library/shows` (`nlink=2`), Sonarr imported it, Jellyfin serves it, and ADR-035
removed that path from the restic source at 13:19 the same day — so there is no
copy to restore. The repair is one `--verify` and ~700 MB of re-download.

### Broken gate — 1, reported as a red test and not as a finding

**C03-T.** `no-kuma-report-was-lost-in-silence` did not evaluate on 2026-09-07 or
2026-09-13: `Error Command execution timed out (45s)`. Its own `exec` needs
`docker inspect uptime-kuma` — its precondition set contains the condition whose
loss it exists to detect, which makes it a C95 instance and a broken gate at once.

The general shape is worse than the instance: **380 of 400 goss assertions carry
no `timeout:` and sit on the 10 s default, and 15 of 121 posture beats over 30
days (12.4 %) were red for a timeout, across 13 DISTINCT assertions.** The set
moves run to run, which is the signature of contention rather than of a slow
check. Cause found by the main session: goss defaults to **50 concurrent tests**
on a 4-core board where most assertions shell out to one dockerd. Fixed with
`--max-concurrent 8` rather than by raising thirteen timeouts.

### Rejected from the agents, and why

- **`security`'s "the fail2ban sshd jail is blind".** Its measurement was right —
  `_SYSTEMD_UNIT=sshd.service` returns 1 journal entry in 7 days on a host whose
  unit is `ssh.service`. Its conclusion was not: fail2ban's `+` is a
  DISJUNCTION, and the second group `_COMM=sshd` returns **56 405** entries over
  the same window (control: 2 761 `Accepted publickey`). Half-dead match, jail
  functional, impact nil. Pinned anyway, as a one-line correctness fix.
- **The main session's own premise, written into eight briefs**: "an assertion
  that times out is neither green nor red". Refuted from `kuma.db` — monitor 23
  went `status=0, important=1` at 09:05:10 UTC carrying the timeout message, and
  Discord fired. A timeout IS counted as a failure. The real defect is the
  inverse of the one suspected: red for a reason unrelated to the property.
- **`observability`'s "rclone 401 Unauthorized"**. The string in
  `vault-mount.service`'s journal is `PasswordLoginForbidden`. Mechanism
  survives, label does not.
- **`backup`'s "0 `important=1` beats in the whole window"**. The DOWN transition
  at 06:41:12 CEST was `important=1` and did notify. The instance survives with
  the qualifier that matters and is sharper for it: **a second failure arriving
  while a monitor is already DOWN produces no new notification** — which is what
  happened to the 07:00:01 backup failure.
- **`system`'s 320 force-kills in 14 days vs `services`' 56 in 7.** Not a
  contradiction, different windows. The main session reproduced the 56 with a
  control and relays only that.

### Instrument errors by the main session — three, all caught by a control

1. **A `journalctl --since -7d | wc -l` that drove the Pi to load 10.3** while
   seven agents were working on it — the exact rule 6 the main session had
   written into the brief. Killed, redone bounded.
2. **A probe from a container with no `nc`.** Every "BLOCKED" was the `||` echo
   of a missing binary. The controls exposed it; re-run from wg-easy, which has
   one.
3. **`mountpoint /home/claude/vault` as root answering NO on a perfectly healthy
   mount.** A FUSE mount without `allow_other` denies even root, so `mountpoint`
   returns a false negative. `/proc/mounts` and the live rclone process settled
   it. The instrument error IS an instance of the key being spent — recorded
   because that is the second time this run that a locality trap caught the
   people looking for locality traps.

## The run of 2026-09-13 (late afternoon) — the key was `granularity`, and it minted nothing

The fifteenth key, and the six-word question no class asked: **at what grain does
the mechanism act, and at what grain does the problem occur?** The fourteen
before it asked *when*, *in what order*, *by whom*, *how many*, *against which
version*, *what survived removal*, *what if two match*, *does the remedy need
what it fixes*. None asked whether a mechanism's unit of action is the unit of
the thing it exists to handle.

**The operator was warned before the key was spent** that it sits next to the
meta-trap this register has paid seven times — "the derivation is sound and it
keys on the wrong axis" — and arbitrated to spend it anyway. The warning was
half right: `granularity` paid INSIDE C92 and produced no class of its own.

Mint rate across fifteen keys: 5, 11, 12, 7, 2, 4, 1, 0, 2, 1, 2, 2, 3, 1, **0**.
**Not consecutive with `exclusivity`'s zero** — `dependency` minted one between
them — so the termination clock stands at ONE.

### The two arbitrations

| Class | Outcome | Why |
|---|---|---|
| C92 | **CLOSED by decision, as a review rule** | Its space is not mechanically derivable — proven, not asserted. See the section above the OPEN table |
| C95 | **STAYS OPEN** | Three derivations, three incompatible bounds, and a live instance outside the two that close |

### The baseline that said "clean" over a real outage — and it was the main session's

Taken at 15:37: 0 failed units on both hosts, 13 `homelab-*` timer services at
`Result=success ExecMainStatus=0`, 32 containers up, none unhealthy.

`homelab-local-maintenance.service` exited **1/FAILURE at 07:00:01 that morning**,
after waiting the full two-hour `--lock-wait` on a profile lock the 03:00 backup
had held since 03:00:09. It was relaunched by hand at 12:23 and succeeded, and
systemd reports only the last result. **A timer-exit-code baseline cannot see a
failure that was manually retried**, and this one is the founding shape of the
whole skill: green everywhere, and the job had not run.

### C95's live instance, verified by the main session from the journal

`resticprofile` attaches `run-after-fail` to each COMMAND. A failure before the
first restic command therefore pushes nothing — no Kuma beat, no notification —
and the dead-man's window is the only remaining signal. The precondition of the
alert ("a restic command starts") intersects the object it alerts about ("the
lock stopped a restic command from starting"). That is the property exactly.

### Instances that shipped — PR #354, deployed to both hosts before merge

Grouped under C92, because all five are the same class:

1. **The media library left the backup and four pages did not notice.**
   `79d0e3b` (13:19) took `library/movies` and `library/shows` out of the restic
   source, deliberately, with an ADR and a posture assertion checking the split
   both ways. It corrected its own ADR and nothing else. 325 GiB (57 + 268,
   measured) went on being described as protected. **The sharpest instance this
   register has recorded**: `c967658` at 15:35 — the documentation-correction
   pass — RE-EMITTED the "Library … Restic … Daily" row to re-align the table's
   columns, two hours after its content became false, and did not see it.
2. **The split-DNS detector was removed by the fix that claimed to keep it.**
   The C95 remediation of 15:27 pinned 21 `Host()` names into `uptime-kuma`'s
   `extra_hosts`, removing the only live detector of split-DNS — which nobody had
   designed: the 20 HTTP monitors had been resolving those names through Pi-hole
   on every check. The comment it left asserted the opposite, and `classes.md`
   line 503 repeated it. Measured: 21 `address=` lines, none for the apex;
   monitor 8 `hostname=<apex>`, `conditions=[]`. **The heartbeat table shows the
   before and after**: the old monitor went UP on `104.21.13.100` (Cloudflare),
   the new one goes UP on `192.168.1.100`.
3. **The router was the only thing keeping SSH off the internet.** The doc said
   "not internet-reachable", ufw said `ALLOW IN Anywhere`. Both true at once,
   which is why neither looked wrong. Now scoped per host, values measured over
   30 days of `Accepted publickey`. The comment it replaced claimed every
   connection came from the WireGuard subnet or a LAN; **144 came from a docker
   bridge**, all on 24-25 August.
4. **The `*arr` healthchecks passed on a redirect.** `curl -fsS` fails on 4xx and
   5xx and nothing else; these apps answer 302 to anything they do not route.
   `/ping` -> 200 rc=0, unknown route -> 302 **rc=0**.
5. **Three monitors running, absent from the registry.** Prowlarr, Sonarr and
   Radarr, created 02:13, never recorded — found by running `ops/kuma-dump.sh`
   to verify instance 2. The registry is what disaster recovery rebuilds Kuma
   from.

### Rejected from the agents, and why

- **`observability`'s 5.6x sampling ratio.** The main session found an internal
  contradiction — a 120 s episode cannot raise an alarm whose lookup is
  `min -10m` — and sent it back rather than relaying it. The agent produced the
  raw transitions: the alarm DID reach `raised` for 120 s, because the raised
  window is `(unhealthy - 600 s) + <=60 s`, not the unhealthy duration. **The
  mechanism survived, the figure did not**: 5.6x divided a measured gap by a
  theoretical floor and was withdrawn for the measured 2.8x, and "33 %" became
  "one of the only three episodes retained". Confirmed independently by the main
  session through the netdata MCP rather than the agent's curl: 120 s, 417 s,
  600 s, all transmission, all 2026-09-12.
- **`ansible-deploy`'s five missing required variables** — its own recount by
  YAML parse gave 79 required, 0 missing. Disclosed unprompted.
- **`services`' mandate premise, which was the MAIN SESSION's error.** The brief
  asserted transmission's missing `stop_grace_period` had been corrected. It was
  never corrected — no commit adds one, `StopTimeout=<nil>` on the host. The
  agent refused the premise instead of building on it.

### Instrument errors by the main session — four, all caught, all by a control

1. **A live probe typed with the MASKED domain.** `getent hosts kuma.example.com`
   returned nothing and it proved nothing. `settled.md` has carried the rule
   since August; it still happened.
2. **The three `*arr` tested on sonarr's port.** radarr and prowlarr returned
   rc=7 — connection refused, not evidence. Only the per-port re-run was.
3. **A `sed` that relabelled EVERY port as `<ssh>`**, which turned the offsite
   rest-server's port-8000 rule into an apparent third SSH rule on a host that
   had just been firewalled.
4. **`journalctl -t homelab-luks-header-backup` returning "No entries" with a
   control that ALSO returned nothing** — so the instrument did not discriminate
   and the finding was unsupported until `homelab-heal` (677 entries) replaced
   the control. The finding then held.

The pattern is the one this register keeps recording: **the instrument is wrong
more often than the system, and a negative control is what separates the two.**

### What the operator declined, and it is in `settled.md`

Announcing the maintenance job's pre-restic failures; the short-alarm sampling
gap; reclaiming the stranded snapshot's space. The last one was already declined
in August at 1.2 GiB; the new fact — a stranded group now holds the media
library — was stated rather than re-proposed, and the answer was the same.

## The run of 2026-09-13 (night) — the key was `dependency`, and the register was stale before the agents were sent

The fourteenth key, and the six-word question no class answered: **does the
remedy need what it fixes?** The thirteen before it asked *when*, *in what
order*, *by whom*, *how many*, *against which version*, *what survived removal*.
None asked what must ALREADY BE WORKING for a mechanism to act. A mechanism is
an instance when its precondition set intersects what it exists for.

Mint rate across the fourteen keys: 5, 11, 12, 7, 2, 4, 1, 0, 2, 1, 2, 2, 3,
**1**.

The premise was verified before the agents were sent, with a positive control,
as `plurality` established:

```
sudo ls -l /etc/wireguard/wg0.conf  -> /mnt/data/secrets/wg0.conf   (symlink into the encrypted volume)
sudo ls -l /etc/hostname            -> regular file                  (the control)
```

### The closure — C94, eight per-domain slices

| Domain | Cardinal | How the space was derived |
|---|---|---|
| `system` | 18/18 + extension | scalar read sites, then SMART/journal-cap/`df`/boot-journal |
| `observability` | 26/26 | its own read sites |
| `services` | 12/12 | 2 pattern-based process checks + 10 exact-name reads |
| `backup` | 12/12 | scalar read sites in the backup chain |
| `network` | 5/5 | resolver, router, certificate and route reads |
| `security` | 0/0 | its task files contain no selector-as-scalar site |
| `ansible-deploy` | swept | `ansible/` Jinja + shell; 0 confirmed, 2 latent |
| `project-manager` | n/a | not assigned |

**0 new confirmed instances lab-wide.** The four founding instances were all
fixed by PR #352 except the one that sits in DECLINED territory. The cardinal is
derivation-relative, exactly as C90's and C74's closures recorded — do not quote
one as "the" number. **ENUMERATED, not GATED**: C83's deployed gate guards
cardinality FLOORS; nothing derives ceilings continuously.

### Minted — 1

- **C95 — an alerting path that depends on what it alerts about.** See the OPEN
  table. Reached by `network` from the resolver side and `observability` from
  the delivery side, independently. Verified by the main session end to end:
  `uptime-kuma` has `HostConfig.Dns=[192.168.1.100]` — a single upstream, no
  fallback, with `traefik`'s `[]` as the control proving the probe
  discriminates; the Kuma database holds **1 notification channel (Discord), 37
  active monitors, 37 bindings, 0 monitors without one**; and `Pi-hole DNS`
  (type=dns) is itself one of the 37. So when Pi-hole stops answering, the
  monitor that watches it goes DOWN and the alert cannot be delivered, because
  resolving `discord.com` needs the component that just failed.
  `observability` adds the refinement that makes it precise: Kuma can still
  **detect** the outage, because a DNS-type check bypasses the OS resolver — it
  cannot **deliver**. The limit on the evidence is stated honestly: the
  structural dependency is proven, an actual delivery failure is not, because
  provoking one means taking Pi-hole down, which rules 5 and 6 forbid.

### Register corrections — 3, and the first one propagated into all eight briefs

1. **C03's "the gate is NOT deployed" was stale by eleven minutes.** A deploy
   landed at **14:15:44** (posture spec) and **14:21:20** (offsite sysctl); the
   baseline for this run was taken at 14:33 and did not check either. The brief
   therefore told `observability` to treat deployment as the remaining job, and
   it correctly reported the premise false. This is the fourth time a stale
   figure in these reference files has reached a whole fan-out, and the first
   time the staleness was measured in minutes rather than days.
2. **C74's offsite residual is FIXED.** `net.ipv6.conf.eth0.accept_redirects`
   now reads 0 on offsite and its `99-homelab.conf` is 30 lines, matching
   homelab. **The structural cause is untouched**: `/etc/goss` on offsite holds
   ONE spec (`offsite-health.yaml`) against three on homelab
   (`backup-dumps.yaml`, `posture.yaml`, `units.yaml`), because `offsite.yml`
   never plays the `observability` role. Measured this run.
3. **C18's repair is deployed — 46 assertions — and its wrong-axis defect is
   demonstrated, not merely argued.** `sonarr/logs.db`, `radarr/logs.db` and
   `prowlarr/logs.db` sit under a backed-up path with no dump and no assertion;
   the deployed spec mentions `logs` zero times. They are app logs, so the
   impact is low — the value is that they prove a database outside
   `backup_sqlite_dumps` is invisible to this gate by construction.

### Rejected from the agents, and why

- **`ansible-deploy`'s SUSPECTED "hard `Requires=` contradicting a comment that
  claims soft".** `homelab-feed-digest.service` does resolve to
  `Requires=mnt-data.mount` via `RequiresMountsFor=/mnt/data`. But the comment's
  own cross-reference settles what it means: `claude-remote-control.service`
  reads *"Deliberately NOT `Requires=vault-mount.service`"*, so "the mount" is
  the rclone vault in both files — and feed-digest does exactly what it claims
  for the vault (`Wants=vault-mount.service` plus a `/proc/mounts` gate on
  `/home/claude/vault`). The two units look inconsistent only because
  `RequiresMountsFor=` silently does nothing for a FUSE path with no `.mount`
  unit and everything for `/mnt/data`, which has one. **The main session had
  begun building a C01 space-restatement on this and withdrew it.**
- **`services`' proposal to fix `compose.yaml:425`.** The self-match is real —
  the main session proved it with a stdin-isolated control (pattern via argv on a
  nonexistent process: SELF-MATCH; same pattern via stdin: no-match; a real
  pattern via stdin: MATCH). But **the operator DECLINED this exact defect on
  2026-09-02** ("C29's vacuous liveness half"). The agent's escalation rested on
  "PID 1 is the `tail | awk` pipeline, not `sh`", which is false: `pgrep -f -l
  tail` returns PID 1 `sh`, PID 7 `tail`, and the DECLINED entry says so too.
  The C92 count (N=2, 1/2 reached) stands as class evidence; the proposal does
  not.
- **The main session's own `homelab-ddns.service` lead, written into all eight
  briefs.** It was wrong, and three domains refuted it independently
  (`system`, `security`, `network`, with `ansible-deploy` a fourth). See the
  instrument trap below.

### One instrument error by the main session, and it shaped the whole brief

`systemctl show -p ConditionPathExists --value homelab-ddns.service` returns
**empty on this systemd version even when the unit declares it**. The unit file
carries `ConditionPathExists=/mnt/data/secrets/ddns.env` at line 5, plus
`After=mnt-data.mount`, and is wired into `mnt-data.mount.wants`. The main
session read the empty output as absence, with no control, and shipped it to
eight agents as a live lead. **Read the unit file, or use a property the version
actually exposes; and never promote a null result to a finding without a
positive control.** It is the same shape as the three traps of 2026-09-13
evening: an instrument answering a different question, with nothing to reveal it.


### What the remediation shipped, and what the operator decided

One PR, deployed from the branch before merge and verified by function.

- **C95's fix is two halves and both were needed.** `uptime-kuma` gains a
  fallback resolver so a Discord webhook can still be resolved while Pi-hole is
  down, AND `extra_hosts` pins for the 21 names this stack routes with a
  `Host()` rule — because a bare fallback answers the internal names with the
  public address, and 80/443 are not forwarded, so one true alert would have
  become eighteen false ones. The pin list is **derived from the `Host()` rules
  in the same file**, and its staleness degrades safely: a service added without
  a pin simply resolves through Pi-hole as before. ~~Split-DNS resolution is
  still probed directly, by the `Pi-hole DNS` monitor, rather than inferred from
  an HTTP monitor's side effect.~~
  **FALSE, and corrected by the run of 2026-09-13 (late afternoon).** That
  monitor queried the APEX, which carries no `address=` line, with
  `conditions=[]` — so it answered the public address and could not see a
  split-DNS failure at all. The pins removed the only live detector, which was
  accidental: the 20 HTTP monitors had been exercising split-DNS on every check.
  **This sentence is left struck through rather than deleted**, because it is
  the register propagating a fix's own false claim into the next run's briefs —
  the fifth time a stale figure in these reference files has done that, and the
  first time the file itself authored the error rather than inheriting it.
- **The four documentary gaps are closed.** `wireguard.md`'s stale restore
  recipe is replaced by a pointer to the runbook — not a second copy;
  `restore-from-backup.md` gains a *Restore Sonarr / Radarr / Prowlarr* section
  and its generic completeness claim is corrected; `arr-stack.md` gains a
  `## Backup` section; `docs/06-backup/README.md`'s table goes from 5 databases
  to 10 and is realigned.
- **The generic-restore correction is the one worth carrying.** The old sentence
  — *"every other service is complete from this command alone"* — was not false,
  which is why three sweeps had passed over it. Six services are dumped **and**
  left in the snapshot, so `--include` returns a `.db` and exits 0 having handed
  over whatever WAL state was on disk. The four rows in the table above restore
  *nothing*, which is loud; these six restore *something plausible but possibly
  torn*, which is quiet. **A documentary claim can be true and still mislead,
  and this class of defect is invisible to any check that asks only whether the
  sentence is accurate.**

**Declined by the operator on 2026-09-13 (night), and not to be re-proposed**:
the `logs.db` siblings; see the DECLINED table for that and for the two
arbitrations that closed C01 and split C03.

## The run of 2026-09-13 (evening) — the key was `plurality`, and it closed the class the morning run could not bound

The thirteenth key, and the six-word question no class answered: **what if two
things match instead of one?** `concurrency`, that same morning, asked what
happens when two ACTORS touch one object. This one asks what happens when a
selector that assumes ONE match meets several — or writes as though exactly one
exists and finds none.

Mint rate across the thirteen keys: 5, 11, 12, 7, 2, 4, 1, 0, 2, 1, 2, 2, **3**.
The decay this file hoped for in early September has not continued.

The key's own premise was verified before the agents were sent, with a positive
control, because a false premise would have wasted eight briefs:

```
docker ps --filter name=nextcloud   -> 5 containers
docker ps --filter name=immich      -> 4 containers
docker ps --filter name=^nextcloud$ -> 1        (the control)
```

### The closure — C90, six independent derivations, recorded above

See "Why C90 arrived OPEN" for the table. It is the most-derived closure in this
register and it arrives ENUMERATED rather than GATED.

### Minted — 3

- **C92 — a correction that reached one member of N.** See the OPEN table.
  Reached independently by `system` (C74's sysctl fix on 1 host of 2),
  `observability` (C03's midday fix on 1 emitter of 10) and `services` (netdata's
  `pidof` fix not carried ten lines down to `traefik-log-redactor`). The main
  session verified two of the three and found a fourth in the act: `0a593ec`,
  committed at 12:46 that day with a message reading *"verified on the live
  offsite disk"*, had written an `ExecCondition` into a template whose deployed
  unit on the offsite host still dated from 2026-07-14. **The fix was real, the
  verification was real, and the deploy had not happened** — which is the
  property, stated better than any summary could.
- **C93 — a file whose designed role is to be a TEMPLATE or a BACKUP, and which
  the consuming tool also loads as live input.** See the ENUMERATED table.
  Proposed by `ansible-deploy`, reached from a different direction by `security`,
  and reproduced in isolation by the main session.
- **C94 — cardinality ceilings.** See the OPEN table. The key's own child, and
  the class that unifies four findings nobody had a word for.

### Instances, grouped under their class

**C94 (ceilings) — four, and the first two are causally linked.**

1. **The credential-store gate ends its derivation with `uniq -c | awk '$1 == 1'`**
   (`goss-posture.yaml.j2:116`). Its own comment states the restriction and
   justifies it correctly — a directory three containers write to cannot be
   closed to one uid. What was wrong is that the drop was SILENT. Exactly one
   store is in that set lab-wide: `nextcloud/data`, 0755, mounted by three
   containers. Found by `security` and `services` independently.
2. **And that store held two unmanaged copies of the LIVE Nextcloud database
   password.** `config.php.bak-20260901-022212` and `-022246`, 0640, left by a
   repair, in no commit, verified by the main session by fingerprinting the
   single `dbpassword` line with a positive control (the same line of the same
   file hashed twice). A third copy carried an older password. All three had
   been in every restic snapshot since 2026-09-01, therefore on the append-only
   offsite too. **This is C87's property at depth 4** under `/mnt/data/services`,
   one level past the depth 3 its closure that morning had stated — see the
   register correction below.
3. **`no-new-privileges` was asserted by SUBSTRING on both sides** — Jinja's
   `'no-new-privileges' in optstr` and jq's `test("no-new-privileges")`. Both are
   satisfied by `no-new-privileges:false`, the documented spelling that turns the
   option OFF. Nothing declared `:false`; the assertion could not have said so.
   Found by `security`.
4. **`restic forget` groups by `host,paths`, and `path: false` disables only the
   FILTER, not the grouping.** Found by `backup` (technical) and
   `project-manager` (documentary: the docs describe a 7/4/6 policy applying to
   one repository). Re-derived independently by the main session from
   `restic snapshots --json`: 4 groups of 9 / 12 / 12 / **1**. The group of one
   is the 03:00 snapshot of 2026-09-13, alone in its path set, therefore its own
   daily AND weekly AND monthly — **permanent**. It is the snapshot holding
   `library/movies` and `library/shows`, which ADR-035 removed from scope nine
   hours later. 22 of 34 snapshots are retained forever. ~70 GiB, against the
   1.2 GiB that made the same cleanup DECLINED on 2026-08-15 — **a new fact, not
   a new argument**. Put to the operator, who declined again: there is room.

**C92 (partial remediation) — four, listed under the mint above.**

**C90 (mutators) — the five recorded that morning, plus `network`'s seventh
pihole mutator and `ansible-deploy`'s G3 generator class.**

**C18 (a database dump absent, stale or empty) — BROKEN GATE.** Sonarr, Radarr
and Prowlarr were deployed on the night of 2026-09-13 and backed up LIVE, in WAL
mode: `radarr.db-wal` held 3.77 MB of committed transactions outside the main
file, `sonarr.db-wal` 696 KB, measured by `backup` and re-measured by the main
session with the goss spec as a positive control (313 lines, 10 artefacts named,
none of them these). **The gate's derivation keys on the dump VARIABLES, not on
the databases present** — the same wrong-axis defect that reopened C10 on
2026-09-11. Not covered by the 2026-09-02 DECLINED entry, which named the media
services whose databases a rescan rebuilds; these hold indexer definitions, API
keys and download history.

**C70-adjacent, and it does not fit a class — recorded as an instance of C94's
sibling shape rather than minted.** fail2ban's `[nextcloud]` and `[vaultwarden]`
jails declare `port = http,https` one line above `banaction = iptables-allports`,
which ignores it; the jump sits at position 1 of `DOCKER-USER`, ahead of the
repo's eight rules, so a banned LAN client also lost DNS over TCP to Pi-hole.
Found by `network`, converged on by `security`. The same day, the jail banned
the host's OWN address (12:42:01 → 13:42:01, exactly `bantime`) after an expired
rclone credential produced 8 WebDAV failures; the ban was inert because
`DOCKER-USER` lives in `FORWARD`, which host-emitted traffic never traverses.

### Rejected from the agents, and why

- **`observability`'s "C19 goss is a broken gate".** True, and recorded since
  2026-09-05 (vacuous at zero, rescued by composition). Not a discovery.
- **`network`'s `Currently banned: 1`.** True at the instant of measurement,
  expired at 13:42:01 while the agent was writing. The main session re-read it
  at 0 and the finding was rewritten in the past tense.
- **`project-manager`'s own proposed mint** (an expiry rule whose grouping key
  derives from a modifiable declaration). It argued against its own proposal and
  recommended folding it into C88. The argument was accepted.
- **Not verified, and flagged as such rather than quoted**: `observability`'s
  "139 sites of verdict-on-client-budget" and "9 of 51 posture reds are purely
  instrumental", and `backup`'s suspected `pgrep -x restic` plurality.
- **To `project-manager`'s credit**, as on the morning run: the refusal-to-start
  claims were declared undecidable under the rules rather than guessed.

### Register corrections — 2

1. **C87's closure of 2026-09-13 midday overstated its cross-check.** It records
   "1997/1997 at a STATED depth of 3, cross-checked by a second, *unbounded-depth*
   property-keyed pass over 112 895 entries … both passes returning the same
   instances". The three `config.php.bak-*` files sit at depth 4 under
   `/mnt/data/services`, answer the property word for word, and were in neither
   pass. **An unbounded-depth pass that misses a depth-4 instance was not
   unbounded.** The stated-depth discipline was right; the claim made for the
   cross-check was not.
2. **C74's closure of 2026-09-11 recorded a fix that reached one host of two.**
   The register reads `1 material instance (net.ipv6.conf.eth0.accept_redirects,
   both hosts)` and CLOSED. Verified by `system` and re-verified by the main
   session with the other host as a control: offsite still read `1`, its
   `99-homelab.conf` dated 2026-08-18 at 29 lines against 2026-09-11 at 30. The
   detector that would have caught it, `sysctl-declared-knobs-reach-every-
   interface`, lives only in `posture.yaml`, and `offsite.yml` never plays the
   `observability` role — so `/etc/goss` on the offsite host holds one spec.
   **That residual is unfixed and it is the standing cost of C92**: the offsite
   host has no continuous posture assertion of any kind.

### What the remediation shipped, and what the operator decided

PR #352, three commits, deployed to BOTH hosts from the branch before merge and
verified by function rather than by colour.

- The three `*arr` databases enter `backup_sqlite_dumps` — 15 assertions
  generated, the 6 that are meaningful outside the backup window verified green,
  the full verdict due at the next 03:00 run (31 → 46 assertions).
- The nine other Kuma emitters distinguish `curl` exit 28. `|| rc=$?` rather than
  a bare pipeline read through `PIPESTATUS`, **because two of the ten run under
  `set -e`, where the old `|| echo` was providing a guard by accident** — a
  detail that would have turned a cosmetic fix into an outage.
- The shared-store set is declared and asserted EQUAL, not floored: a floor lets
  a set grow in silence, which is the direction that costs something. Proven
  under `dash` on the host in both directions.
- `no-new-privileges` is asserted by list membership and by an anchored regex.
  Proven in three directions on live containers, including the disabling form,
  where the old expression returned `true`.
- fail2ban: `iptables-multiport`, and the host's own address into `ignoreip` via
  `ansible_default_ipv4` — which the offsite deploy then justified, writing that
  host's own address on a different subnet where a literal would have written the
  wrong one. **Proven by function**: a test ban of a documentation address landed
  a jump reading `multiport dports 80,443` where the old one carried no port
  match at all, and the unban returned the chain to a bare `RETURN`.
- The three `config.php.bak-*` were removed by hand — residue, not state to
  maintain.

**Declined by the operator on 2026-09-13, and not to be re-proposed:**

- **Rotating the Nextcloud database password** after the two copies were found.
  The copies are gone; the snapshots that hold them are encrypted with a key the
  operator controls, and that is accepted.
- **Reclaiming the ~70 GiB pinned by the permanent snapshot group.** "There is
  room." This is the second refusal of the same cleanup and the first one where
  the figure was right; do not raise it a third time without a new consequence.
- **Moving the `*.example.yml` files out of `host_vars/`** (C93's only live
  instance). The file is the reference and must stay current where it is. The
  residual risk is recorded in C93's row and is the operator's to carry.

### Three instrument errors by the main session, all caught, all worth carrying

They are in `settled.md` in full. The one that matters: **running the dump spec
outside the backup window measures nothing**, because `run-before` creates the
dump directory and `run-after` destroys it — the spec is evaluated at line 182 of
the profile, inside the window, into `/run/homelab-backup-dumps.tap`. Reading it
at 14:30 produced 24 red assertions and a false alarm about the whole backup
chain. The last real verdict was **31 ok / 0 not ok**. This is C03's property,
committed by the session auditing C03.

## The run of 2026-09-13 — the key was `concurrency`, and the register had written its own warning

The twelfth key, and the six-word question no class answered: **what happens
when two run at once?** `order` and `succession` asked about sequence,
`interruption` about a run that stops. All 89 classes presumed a single actor
per object. The evidence the key had territory was sitting in `domains.md` as
an unadopted instrument trap: *"the offsite repository is append-only, and a
concurrent operation there creates permanent duplicates."*

Mint rate across the twelve keys: 5, 11, 12, 7, 2, 4, 1, 0, 2, 1, 2, **2**.

### The two closures, both by two independent derivations

- **C26's argv axis**, swept from opposite sides by `ansible-deploy` (repo, 340/340)
  and `security` (runtime, 8 189 processes against 80 derived secret values).
  Neither side could see the other's instances, which is the same lesson
  2026-08-31 recorded: a technical sweep and a documentary sweep of one class
  are not substitutes.
- **C87**, closed at a *stated* depth and then re-run at unbounded depth to
  prove the depth had not chosen the answer. 1997/1997 and 112 895/112 895
  agreeing instance for instance. **Stating the depth limit is what made the
  cardinal believable**, and it is the correction to how C87 was minted.

### The run's two headline instances, both verified by the main session

**1. The heal timer and a deploy mutate the same containers, with no serialiser
— and it has collided twice, both times invisibly.** Reached independently by
`ansible-deploy` and `system`, then verified in the journal by the main session:

```
2026-09-05T22:05:58  container d2834e7137d6_immich-redis (service immich-redis) is created — restarting
2026-09-05T22:06:01  ERROR: failed to restart immich-redis
2026-09-05T22:06:01  homelab-stack-heal.service: Deactivated successfully.
2026-09-12T02:13:39  container da2ce0510d8a_forgejo (service forgejo) is created — restarting
2026-09-12T02:13:41  checked 30 of 29 declared container(s), 1 restarted
```

`da2ce0510d8a_forgejo` is Docker's rename-on-recreate temporary: the healer sees
it mid-`compose up`, calls it a crashed container and restarts it. **Three
instruments were blind at once.** The unit logs `ERROR` and exits 0, so
`Result=success`. The health assertion at `homelab-health.sh.j2:719` fires only
on `heal_n -lt heal_m`, and a collision's signature is `checked 30 of 29` — one
*more* than declared, so the comparison cannot see it by construction. And the
dashboard stayed green. The guard exists only as a runbook sentence for humans.

**2. C03's fifth reopening — a false positive feeding a live assertion.**
`homelab-netdata-kuma.sh` reports a beat lost when its own client times out:

| | |
|---|---|
| Kuma committed the beat | `2026-09-12 23:25:29.334` UTC, status UP |
| Script wrote `this report reached nobody` | `2026-09-13 01:25:39` CEST = 23:25:39 UTC |
| Gap | **exactly `TIMEOUT=10`** |
| Payloads | byte-identical, value for value |

The client's success criterion is "a response arrived inside my budget"; the
beat's landing is decided server-side. Under the load its own aligned schedule
creates (C91), the server commits and the client gives up. `--retry 2` makes it
worse, not better. **This marker is the sole input to the live
`no-kuma-report-was-lost-in-silence` assertion.**

### The C90 population — five domains, one shape

| Instance | Domain | State |
|---|---|---|
| Heal timer vs an Ansible deploy, no lock on the docker path | `ansible-deploy`, `system` | CONFIRMED ×2 in the journal |
| Six actors can restart `pihole`; only two re-attach `dnsproxy`'s netns | `network` | Latent, `restartCount=0`, but the outage has happened twice on this host |
| A restore spanning 03:00 has its restored dumps `rm -rf`'d by the backup's own `run-after` | `project-manager` | CONFIRMED, disaster-recovery path |
| `offsite-backup.md:193` aims a lock-bypassing `restic check` at the copy window | `backup`, `project-manager` | CONFIRMED, two domains independently |
| `offsite-smart-test.service` has no `ExecCondition`; its homelab twin got one 2026-08-26 | `system` | CONFIRMED, one line |

### Minted — 2, after arbitration of 4 proposals

- **C90** — see the OPEN table. Proposed by `ansible-deploy` and, in a different
  bounding, by `services`. **The disagreement between their cardinals is what
  made it a mint rather than an enumeration.**
- **C91** — see the ENUMERATED table. Proposed by `observability`, which offered
  one mint and refused three of its own.
- **DECLINED — `network`'s "no `flock` anywhere in the lab" as a class.** It is
  a true observation and it is already recorded: `classes.md:1191`, 2026-09-05,
  *"the backup locks are real and taken; `flock` has zero live invocations."*
  An absent mechanism is not a property; C90 names the property it gestures at.
- **DECLINED — `services`' immich-db crash as a `concurrency` instance.** The
  event is real and verified by the main session (`server process (PID 13)
  exited with exit code 2` one second after `last known up`, then `automatic
  recovery in progress`). But no concurrent actor was demonstrated, the agent's
  own four exclusions do not establish a cause, and Postgres crash recovery did
  its job. It is carried as an **observability coverage gap** — nothing on this
  host reads a container log for a crash pattern — not as an instance of the key.

### Rejected from the agents, and why

- **`backup`'s timestamps.** It reported that its host work "finished 02:57" and
  that nothing ran in the 03:00 window. It was 02:19. The conclusion was right
  by a wide margin, but the timestamp is invented, so none of that report's
  timings were carried forward without re-measurement.
- **Both `flock` counts.** `network` said none in the lab; `services` said
  `grep -rn flock` returns one hit. The true count is **4 textual occurrences,
  all comments or prose, and 0 live invocations**. Neither number is quotable;
  the property is.
- **Both heal-timer worst cases.** `system` measured 38.3 s over its window, the
  main session 77 s over 14 days. Window-dependent and not load-bearing — both
  are far below the 120 s period, and `Type=oneshot` forbids a second instance
  regardless. Quote neither; state the conclusion.
- **`services`' "the mandate's premise is stale by a day"** on the
  `acme.json.bak*` files. Correct, and the main session nearly recorded the
  opposite: `/mnt/data/services/traefik/` holds no `acme.json` at all, which
  reads as deletion and is simply the wrong path. The store is
  `.../traefik/acme/`. **Verified gone**, which is what a re-run is for.
- **`project-manager`'s 9 refusal-to-start claims**, correctly identified as
  unsettleable read-only rather than quietly guessed. That is the discipline
  this register rewards, and it is why C01's bound is now the rule set.

### One disclosure, made unprompted by the agent that caused it

`project-manager` ran `docker exec wg-easy sh -c '... head -c 400 /etc/wireguard/wg0.json ...'`
to learn the store's SHAPE. `wg0.json` is plain JSON with the **WireGuard server
private key first**, followed by the first client's private key; both are now in
this session's transcript. Nothing was written to disk and nothing left the
machines. **The repeatable rule: never `head`/`cat` a credential store to learn
its shape** — a key-name listing answers the same question and reveals nothing.
This is the eighth trap in the "Handling secrets DURING an audit" family.

## The dedicated secret audit of 2026-09-12 (afternoon) — swept by VALUE, and it is why the earlier sweeps kept missing

The operator asked for this one explicitly, and the reason is in the record:
secrets in cleartext had resurfaced in run after run, and every sweep that went
looking for them had been bounded by a MECHANISM — container mounts (C10), then
`environment:` blocks (C26), then Ansible write sites, then a suffix tuple
inside a derivation. Each mechanism was a real bound and each had a blind spot,
because the class is not defined by a mechanism. **It is defined by a value.**

So the space was inverted: enumerate the secret VALUES the system holds, then
search every surface an octet can rest or transit on. Both factors are
enumerable, and a value-keyed sweep cannot key on the wrong axis — that is the
whole argument for it, and it is the only bound this register has found that
closes rather than samples.

### V — the value set, and the three iterations it took to get right

| Iteration | Cardinal | What was wrong |
|-----------|----------|----------------|
| V_broad | 63 | A YAML branch captured EVERY `key: value` in a structured secrets file, so option names and URLs entered the set. `searxng-settings.yml.j2` matched 11 "secrets" |
| V_strict | 51 | Better — keyed on the NAME of the key — but a file with no extension (`docker/searxng_settings`, 658 B) still fell through to the whole-file branch, so its comment header entered the set and hit four unrelated Ansible task files |
| **V_final** | **36** | A file counts as one value only if it is ONE LINE. Otherwise the key-name filter applies. Noise gone, and six completeness controls pass |

**The lesson is not the numbers.** It is that two of the three iterations looked
correct and produced a sweep whose output was mostly noise — 58 "hits" that
collapsed to 7 once V was clean. A value-first sweep is only as good as V, and V
has to be derived and then CONTROLLED: six known secrets (WireGuard server key,
Vaultwarden admin token, both restic passwords, the Cloudflare token, the
Pi-hole password) were asserted present before the sweep was believed.

### The surfaces, each with its own positive control

| Surface | Result |
|---------|--------|
| `/etc` `/root` `/home` `/opt` `/usr/local` `/srv` `/boot` `/run` `/tmp` `/var/tmp` `/var/lib` `/var/spool` `/var/backups` | **7 files, all in `/root`** — control: 26/26 secret files re-found |
| `/var/log` (text and compressed) | **1 file: `sudo.log`** |
| systemd journal, all boots | 0 |
| Container JSON logs (140 MB) | **0** |
| `/mnt/data/services` | 6 files, **all legitimate homes on the encrypted volume** (Miniflux's postgres, Vaultwarden's config, the three WireGuard stores) |
| Databases — Kuma, Forgejo, Vaultwarden, Immich, Nextcloud, Miniflux | 1 line in `kuma.db`, its own push tokens |
| `/proc/*/cmdline`, 360 processes | **0** |
| `/proc/*/environ` | 14 processes, structural — see below |
| **Git history, 6 919 objects, every branch** | **0** — control: a planted value is found |
| Shared worktrees, session scratchpad | 0 |
| Offsite host: `/etc` `/root` `/home` `/opt` `/usr/local` `/var/log` `/var/lib` `/var/tmp` `/tmp` `/boot`, journal, argv | **0 outside its own `wg0.conf`** — control: the rest-server htpasswd is re-found |

**The git result is the one that mattered most** and it is clean: nothing in the
public repository's history has ever carried a live secret value.

### What it found — 2, both fixed the same afternoon

- **Three hand-made WireGuard stores in `/root`, on the unencrypted card**, each
  holding the server private key that is still live (derived and matched against
  the running interface), four client private keys and four pre-shared keys.
  Root-only, so never an open door — but on the medium ADR-011 and
  `sd-theft-response.md` both describe as carrying none. C87 instances the
  morning's retirement list had not covered.
- **`sudo.log` had no rotation and never had.** `Defaults logfile` ships for
  CIS 5.2.3; Ubuntu provides no logrotate stanza and the sudoers drop-in creates
  none. 14 MB, 241 043 lines, 250 kB/day, oldest entry 18 July, on the card. The
  same command lines go to `auth.log`, which rsyslog expires in about five
  weeks — so **a hardening control had created a permanent copy of what another
  control forgets**, and nine audits had looked at `auth.log` because that is the
  file everyone knows. Six credential values were in it, 12 August to
  6 September, from the `environment:` defect fixed that morning; all six were
  checked against the live set and none is still in use, which is luck and not
  design.

### Minted — C89, and it supersedes the mechanism-bounded sweeps

| ID | Property | Space | State |
|----|----------|-------|-------|
| C89 | **A live secret VALUE present anywhere outside the store meant to hold it** | V × S: 36 derived values against the surfaces tabulated above, each swept with a positive control | ENUMERATED over the swept surfaces; see the unswept slice below |

C89 is not a competitor to C10 and C26 — it is the form they should have taken.
C10 asks where a credential FILE is readable, C26 where a credential REACHES a
channel; both are mechanisms, and a mechanism-bounded sweep re-opens the moment
a new mechanism appears. C89 asks where a VALUE IS, which is the question the
operator was actually asking all along.

**What is NOT swept, stated rather than glossed:**

- **Restic snapshots.** 376 GB across 33 local and 90 offsite snapshots were not
  searched. A secret that was on disk when a snapshot was taken is in that
  snapshot, and the `/var/tmp` credential stores removed this morning had been
  in the backup source since 2026-08-16.
- **Depth-limited subtrees.** Immich, Jellyfin, Navidrome, Transmission and
  Nextcloud were swept to depth 2 and files under 2 MB only.
- **Application passwords are covered by SHAPE, not by value** — the plaintext
  is not recoverable without putting it in an argv, so a generic
  `xxxxx-xxxxx-xxxxx-xxxxx-xxxxx` detector was used. That is stronger for
  finding unknown ones and weaker for proving a specific one absent.
- **`/proc/*/environ` carries secrets by construction.** 14 processes hold one:
  the `_FILE` pattern keeps a value out of `docker inspect`, and the image's
  entrypoint then exports it into the process environment because the
  application needs it. `environ` is readable only by root and the process
  owner. This is structural, it is not a defect, and it should not be
  re-reported.

## The run of 2026-09-12 — the key was `residue`, and it found the worst live defect since the founding one

**What survived a removal, and does it still act?** `time` asked *when*, `order`
*in what sequence*, `identity` *who*, `scale` *how much*, `authority` *on whose
authority*, `representation` *in what encoding*, `vacuity` *what at zero*,
`exclusivity` *what at two*, `interruption` *what at half*, `succession`
*against which version*. **Nothing in 86 classes had asked what happens to a
thing that should no longer exist.** Every one of them asked whether a live
object was correctly configured; not one asked whether a dead object was still
there and still acting.

The key was given three admissible shapes so that agents would return
measurements rather than tidiness: (R1) a live object with **no declaring
source**; (R2) a leftover that **still grants** — a rule, a capability, a
credential, a name, a certificate; (R3) a replacement that **left its
predecessor running**. Everything else had to be refuted with a number. The
precedent that showed the key was not theoretical came from the register itself:
C27 sweeps repo→deployed by sha256, so an artefact Ansible USED to deploy and no
longer does is outside its space by construction — the same shape that had just
reopened C10.

### The two OPEN classes that CLOSED

| Class | Owners | N, and how it was derived | Result |
|-------|--------|---------------------------|--------|
| **C10** | `security` + `ansible-deploy` | **29** declared credential stores (runtime) and **32** write sites (26 module writes + 6 `environment:` blocks, swept across all of `ansible/` rather than one glob) | 29/29 and 32/32, **0 instances**. The two restic passwords that reopened it are `0400` today. All 17 world-readable secrets are Compose bind mounts under a `0700` parent; both `0440` groups are empty |
| **C86** | `security`, `system`, `services`, `ansible-deploy` (+ `network` 5/5 on 09-11) | **12 + 172 + 138 + 36 + 5 = 363** elements over five domains, each domain deriving its own slice | 363/363. **3 confirmed, all with measured impact; 0 of them exploitable today** |

**C86's three instances are worth keeping because each fails differently.**
`sshd`'s `Ciphers` is a *pure* restatement of OpenSSH 9.6p1's default six — zero
policy content, existing only to freeze — proven with
`sshd -T -o "Ciphers=-3des-cbc"`; it excludes nothing today because
`ssh -Q kex | grep mlkem` is empty on 9.6, and it goes wrong silently on the
first upgrade to ≥ 9.9. The netdata AppArmor profile claims of itself
"docker-default, **verbatim**"; read out of the running dockerd 29.8.0 binary,
the frozen block is missing `deny /sys/devices/virtual/powercap/** rwklx,`, the
RAPL/PLATYPUS mitigation — impact **zero**, because `/sys/devices/virtual/powercap`
does not exist on a Pi 4, verified host-side and inside the container.
`ansible.cfg`'s `ssh_args` restates ansible-core 2.21.2's default minus `-C`,
costing 33.7 % on every module payload. **The positive control that makes the
sweep credible: the repo does NOT restate `Unattended-Upgrade::Allowed-Origins`.**

The note this section replaces is still true and still worth carrying: C86 is
not C29, whose construct exists to *suppress*; C86's construct exists to
ASSERT, and the suppression is upstream moving underneath it. Nor is it "a pin
that stopped binding" — the pin binds perfectly; binding it merely became the
weaker choice.

### The run's headline — a credential in the system authentication log, for 24 days, behind a gate that passes

`ansible/roles/claude-code/tasks/vault.yml:57` passes the Nextcloud WebDAV
admin app-password through `environment: P:`. Verified independently by the main
session, value never printed:

```
length 29, 4 dashes, 5 groups of 5   <- Nextcloud's app-password format
27 occurrences, 2026-08-13 22:57:59 -> 2026-09-06 02:26:26
/var/log/auth.log  mode 640  syslog:adm   operator is in adm
readable WITHOUT sudo: YES        /etc/shadow, same user: refused   <- the control
```

Three things make it the worst live defect since the founding one.

1. **The last write is 34 minutes after `23fab2e`**, a commit made that night
   while this very defect was being closed for three other tasks.
2. **The task carries `no_log: true`.** That suppresses Ansible's own output and
   does nothing whatever about sudo's, so the protection is apparent rather than
   real. Eleven lines below sits a comment recording that `rclone config create`
   used to leak the same secret through argv — that half was fixed, this one was
   not, in the same file.
3. **The gate runs, and passes.** `ops/check-secret-in-environment.py` is in
   pre-commit and exits 0, because `derive_secret_vars()` reads
   `ansible/roles/deploy/tasks/secrets.yml` and nothing else: **16 names**,
   against **22** secret-shaped variables the operator declares in the example
   files. `rclone_webdav_pass` is declared at `local.example.yml:152` with the
   comment "A Nextcloud app-password for rclone WebDAV access", and cannot enter
   that set at any point in the future, for any value of the data.

That last point is the **seventh** payment of the same trap, and its shape is now
unmistakable: *the derivation is sound, and it keys on the wrong axis.* C10 keyed
on container mounts, C16 on an owner uid, C01 on five kinds of referent, and this
one keys on where a secret is *written* rather than where it is *declared*.

### The residue population — one class, five domains, one shape

**Three credential stores at mode 0644 in `/var/tmp`, on the SD card, outside
LUKS, readable by every local uid — residue of the repairs of 2026-08-16, 27
days old.** Reached independently by `security`, `observability` and `system`,
which this register's own rule names as the strongest evidence available. All
three verified by the main session with `/etc/shadow` refused as the control:

| File | Holds | Still current? |
|------|-------|----------------|
| `wg-easy-dns-20260816/wg-easy.db.consistent` | WireGuard **server** private key, 4 client private keys, 4 pre-shared keys | **Yes** — the stored server key still derives the live wg-easy server public key, and 4/4 stored client public keys match the 4 live peers |
| `vaultwarden-config.json.bak-20260816` | Vaultwarden `admin_token` | **Yes** — byte-identical to the live secret, 97 chars, same hash |
| `forgejo-repair-20260816/forgejo.db.consistent` | 3 OAuth2 client secrets, user password hashes | **Yes** — both byte-identical to the live database |

The originals are `0600` under `0700` parents on the encrypted volume. ADR-011
and `sd-theft-response.md` both state that the card carries no secrets; it has
carried the whole VPN for 27 days.

**Inert residues, confirmed and ranked below the above because they grant
nothing:** `/usr/local/sbin/homelab-wg-easy-migrate.sh` (0700 root, 12 KB,
survived the deletion of its task by three weeks, still claims "Ansible
managed", no caller anywhere); `/mnt/data/services/netdata/go.d/sensors.conf`
(bind-mounted into netdata 20 days after its template was deleted, **inert** —
go.d v2.11.0 registers no `sensors` module, measured); `/usr/local/bin/homelab-iosample`
(a prior audit's own scratch script, in no commit); an empty directory left by
`6fabf33`; three `acme.json.bak*` files holding 37 certificate+key pairs
including three retired names (`acmetest`, `capdroptest`, `notes`) — but `0600`
root-only on LUKS, so no open door.

### Minted — 2, after arbitration of 3 proposals

- **C87** — see the OPEN table. Proposed by `system`, and it is the run's real
  output: three agents found the instance, one abstracted it into a property
  with a derivation and a control.
- **C88** — *a file rendered into a host DIRECTORY by a loop over a register
  that can shrink, with no counterpart removing what the register no longer
  names.* Space = looped render tasks ∩ directory bind mounts; **cardinal 4**,
  swept 4/4, one carrying residue. It is NOT C87: C87's artefacts are made
  outside Ansible, C88's are made BY Ansible and then orphaned by it. The
  cleanup today is 20 hand-written `state: absent` tasks — 5 removals got one,
  3 did not. **A list, not a derivation**, which is exactly why the class is
  worth having. ENUMERATED.
- **DECLINED — `project-manager`'s "rejection list drawn from memory rather than
  from the tool's option surface"** (27 "Alternatives considered" sections across
  24 of 34 ADRs, 1 of 1 examined failed). The agent argued against filing it
  itself, and the main session agrees: an ADR rejecting an alternative because
  "X cannot do Y" *is* C01's restated property applied to a new stratum. It is
  folded into C01's 87 as a **high-yield stratum to sample first**, not minted.
  The discipline is worth naming for the second run running: the agent that
  found the property argued against minting it.

### Rejected from the agents, and why

- **`network`'s `wg0.json` finding.** Verified: it does hold the live server
  private key and 4 client private keys. Downgraded anyway — it is `0640` under
  a `0700` parent on LUKS, and it is documented in **14 places**, including
  `knowledge/runbooks/wireguard-peer-revocation.md:34` ("Do not read
  `wg0.json`") and `docs/05-services/wireguard.md:102`, which records the
  rollback copy deliberately. A known, documented, root-only artefact is not
  residue nobody knows about.
- **`security`'s peer-match evidence, corrected not rejected.** It reported the
  4 stored public keys matching "the peers on the live interface". They match
  **wg-easy's own container interface**; the host's `wg0` is the offsite tunnel
  and carries 1 peer. The conclusion stands and is in fact stronger than
  reported — the stored *server* key still derives the live server identity —
  but the instrument as worded would have failed a re-run.
- **The main session's own first Vaultwarden measurement**, which said the
  backup token *differed* from the live one. It did not. `jq -r` appends a
  newline and the other side of the comparison had been stripped, so two hashes
  of different strings were compared. Re-measured with both sides stripped and a
  control: byte-identical. **Recorded because this is the second run in a row
  where the main session's own instrument was the weakest one used.**
- **`ansible-deploy`'s count of 24 declared secret variables** — the main
  session measures 22 by its own regex. The direction, the mechanism and the
  remedy are identical, and neither figure is load-bearing; the load-bearing
  number is 16, which both agree on.
- **`ansible-deploy`'s proposal to reopen C27 instead of minting.** Rejected:
  C27's property is *a deployed artefact differing from the repo*, which
  presumes a repo counterpart. An artefact with no declaring source has none.
  C87 is the correct home and its space is larger than C27's in the one
  direction that matters.

### Register corrections — 3, and one had already propagated into eight briefs

- **`world_readable_secret_writes()` is NOT deleted.** This file recorded it as
  removed by `23fab2e` with `grep -c` returning 0, and that sentence was written
  into this run's `security` and `ansible-deploy` briefs. It was **restored by
  `b761450`** ("two repository passwords world-readable, and the gate that left
  with them"); `grep -c` returns 3, and the two passwords are `0400`. The
  register was one commit behind the repo, for the fourth time.
- **C18's cardinal is 31, not 26.** `wg-easy` joined `backup_sqlite_dumps` on
  09-11 and acquired all five checks with no spec edit — visible in the log as
  `dumps ok (26 checks)` → `dumps ok (31 checks)` one night apart, and confirmed
  verbatim by the main session. That is not a stale number so much as **positive
  evidence that C18's generator genuinely derives**, which is worth more than
  the correction.
- **C14 is derived but ONE-DIRECTIONAL.** Its only reconciliation, `cert_high`,
  is a high-water ratchet that fires solely when the certificate count *drops*.
  A residue raises the count invisibly *and* raises the mark, arming a permanent
  false alarm on the day a name is legitimately retired. Measured clean today
  (18 certificates = 18 live `Host()` = 18 split-DNS records, three-way set
  equality), so this is a shape note, not a finding.

### Gates re-read — C15, C18, C21, C41, C07 DERIVED; C19 still half vacuous; C30 and C31 have none

`C15` sound but all three recorded residues hold: the assertion is **syntactic**
(it greps `/proc/<pid>/cmdline`, it never sees a delete refused), it takes
`head -1` of `pgrep`, and it runs **DAILY — the word `weekly` stood here until
2026-09-20 and was wrong for three consecutive runs.** `OnCalendar=*-*-* 08:00`
with `RandomizedDelaySec=15m` on the live offsite timer, last fired 2026-09-20
08:04:59, so the unasserted interval on the single property that makes the
offsite a backup rather than a mirror is a day, not six. `C41` derived over Kuma's own monitor table, 15/15 live, 0 silent.
`C07` derived, character-identical Jinja on both sides. `C19`'s goss half is
**still byte-identical and still exits 0 with the binary absent** (positive
control `PATH=/nonexistent`) — a red test, not a discovery, and the script half
is now derived. `C45` holds at 10/10 push sites with no new site since 08-30.
**`C30` and `C31` have no live assertion at all** — consistent with their
ENUMERATED state, recorded so nobody reads them as gated.

### What the remediation of 2026-09-12 changed, and what it deliberately did not

Shipped the same day on `fix/secret-in-sudo-log-and-residue`, deployed from the
branch before merge.

**C26's trace axis now carries a derived gate, proven in both directions — and
the class is recorded ENUMERATED, not GATED.** The widening is real: the secret
set went from 16 names to 38, and it is unioned from three independent sources
rather than one, the third being every secret-shaped variable the operator is
asked to supply in the example inventories. That third source is the axis the
old derivation lacked, and it is what makes a secret covered from the moment it
is *declared* rather than from the moment a task writes it somewhere the gate
knew to look. Run against the repo before the fix it flagged exactly one site —
the defect — and nothing else; after, it is green; and the selftest gained a
MUST-FLAG control carrying a `_pass` suffix, which fails if the widening is
reverted.

It is **not** recorded GATED, and the reason is the one that cost C02, C13, C20
and C17: C26 has four axes and this gates one. The argv axis has had no live
assertion since 2026-08-30 and still has none. A table that said GATED here
would be the same disguise, one run after this file described it.

**C86 closes with one of its three instances gated.** `netdata-apparmor-matches-dockerd`
re-derives the difference between the deployed profile and the running daemon's
own binary on every posture run, is directional on purpose (it fails when
dockerd has a rule the profile lacks, and stays silent when the profile denies
more), and carries a floor that fires if fewer than ten deny rules parse out of
the binary. Proven in three directions before shipping: the old profile fails
naming its four missing rules, the synced profile passes, the floor fires on an
empty input. The sshd and `ansible.cfg` instances are corrected but ungated —
nothing derives "this value restates a default" in general, and nothing here
claims otherwise.

**C87 stays OPEN, and the shipped work does not close it.** The three credential
stores were removed by hand the same morning, and thirteen paths now ship as a
retirement list. The list is explicitly a LIST: nothing in it fails when a new
artefact is orphaned tomorrow. What would close the class is a sweep of the
service data directories — the slice the mint's own bound excluded — and that is
not done.

**One correction was made to this file before it was committed.** It recorded
the character-class shape of the live app-password, which narrows the search
space for a secret in a PUBLIC repository. The rule the briefs carry as rule 7
applies to this register too, and it was broken by the session that wrote the
rule into eight briefs that morning.

### C76, observed rather than estimated — a fact for the next run, not a proposal

C76 was enumerated 2026-09-02 as "197 + 43 assertions; 15 within 2x of budget",
and no action was requested on it. The remediation of 2026-09-12 produced the
observed figure that the proximity measure was standing in for, and it belongs
here so that nobody re-derives it: **183 of the 201 posture assertions run on
goss's 10 s default**, and over the seven days to 2026-09-12 six timeouts were
journalled across roughly twenty service runs.

The important half is the breakdown, because the raw count misleads. Only ONE
was a genuine growing cost — `traefik-access-log-carries-no-credential`, which
re-read the whole rotation window nightly (323 071 lines, 9.12 s isolated) and
is now bounded and measured at 4.87 s. The others cluster in periods when
somebody was working on the machine: two during the previous session's evening,
one caused by the audit's own new assertion, and one caused by the main session
running goss three times back-to-back to measure concurrency, which put the Pi
at load 5.8 — a check costing 0.32 s isolated then exceeded 10 s.

So the shape is not "183 fragile assertions". It is that the posture check is
load-sensitive and the operator's own work is the load. `--max-concurrent` is
not the lever: measured at 50, 8 and 4 on an idle machine, wall time was 28.0 s,
27.3 s and 27.8 s with zero failures at every setting.

**Nothing is proposed.** The main session's first reading — "a shape problem,
not instances" — was stated to the operator on the strength of three timeouts in
three runs, one of which it had caused itself, and it is corrected here rather
than left in the record.

### Disclosures — four agents wrote, all four said so unprompted

`system` wrote `/tmp/.k1` and `/tmp/.k2` (a public key) and removed them in the
same command, verified absent. `observability` wrote a 6-line throwaway goss
spec to `/run/goss-c01-probe.yaml` (tmpfs), `rm -f` in the same command, twice.
`project-manager` wrote `/tmp/rp-schema.json` (resticprofile's own schema, no
secret). `security`'s `sqlite3` read created two zero-content sidecars beside the
Forgejo copy. **`services` wrote `/tmp/insp.json` and did NOT remove it** — 412 KB
of `docker inspect`, mode 0664, world-readable, still on the host. Its 13
secret-shaped matches are `*_FILE=` **paths** and public GPG key ids, no values,
so nothing leaked. It is nonetheless a fresh C87 instance created by the audit
that minted C87, and it is left in place because the run is read-only.


## The run of 2026-09-11 — the key was `succession`, and it cost the clean sheet again

**Against WHICH VERSION of its counterpart?** `time` asked *when*, `order` *in
what sequence*, `identity` *who*, `scale` *how much*, `authority` *on whose
authority*, `representation` *in what encoding*, `vacuity` *what at zero*,
`exclusivity` *what at two*, `interruption` *what at half*. **Nothing in 85
classes had asked against WHICH VERSION** — every one of them asked whether a
thing was configured, timed, ordered or sized correctly, and not one asked
whether the counterpart it was configured against still exists in that shape.

The key was given three admissible shapes so that agents would not return
thought experiments: (1) **ignored input** — a key the deployed config sets and
the running version does not read; (2) **silent parse decay** — a parse of
another component's output that degrades to empty/zero/OK rather than to an
error; (3) **a constraint that stopped constraining**. Everything else was to be
refuted with a number. The precedents that showed the key was not theoretical
came from the operator's own history: `pihole reloaddns` at Pi-hole v6,
`autodetection_retry: 0` in the netdata docker collector, v1-only Kuma tooling
against a v2 install.

### The two OPEN classes, both CLOSED, and both by derivation

| Class | Owner | N, and how it was derived | Result |
|-------|-------|---------------------------|--------|
| **C74** | `security` | **48** sites over **14 arbiters**, derived by arbiter rather than by rule: every component to which a deployed artefact hands a decision. The two prior slices (7 UFW rules, 5 systemd sites) are sites A1-A8 and B1-B5 — **the old union of 12 was a quarter of the space** | 48/48. 1 confirmed (fail2ban `[sshd]` names a `logpath` the systemd backend does not read), 1 mechanism left explicitly unresolved (A15, `iptables-restore --noflush` on `DOCKER-USER`), 0 live exposure in the packet slice |
| **C74** | `system` | **71** sites over 10 arbiter-decision categories on both hosts (59 homelab + 12 offsite); `OnFailure=` and cgroup-double-writer both **empty, not unswept** | 71/71. **1 material instance**, below |
| **C82** | `observability` | **25** deployed shell executables (23 homelab + 2 offsite, 1 725 code lines), not the register's "~10". 20 compose healthchecks and 264 goss `exec:` blocks excluded **by measurement** — both populations contain zero mutating statements, so neither can hold the pair | 48/48 (check, later-statement) pairs. **0 confirmed, 48 refuted.** The register's live instance is DEAD, verified: `homelab-lynis-report.sh` now reads `lynis show version` before the mtime stamp, and `last-green-report.dat` is 59 407 B with an index and a warning line, against 695 B / 0 / none on 09-05 |
| **C82** | `ansible-deploy` | **39** validations across 433 + 135 + 1 expanded tasks (4 `validate:` + 11 `assert` + 7 `fail` + 17 command verdicts), each swept against every later task AND every later flush | 39/39. 1 confirmed, 1 suspected, 35 refuted |

**The two C74 derivations disagree on N by a factor of 1.5, and the
disagreement is itself worth recording.** `security` counts "ufw's `IPT_SYSCTL`
override vs `/etc/sysctl.d`" as ONE site covering nine keys; `system` counts
twenty knob-host pairs. Both swept their own derivation exhaustively and both
verdicts stand. The lesson for the next reader: **C74's cardinal is
derivation-relative, and that is acceptable for a class closed by two
independent sweeps whose instance sets are disjoint.** What is not acceptable is
quoting one of the two numbers as "the" cardinal.

**And the two sweeps disagreed on a verdict, which resolved cleanly.**
`security` reported ufw's nine `IPT_SYSCTL` keys "clean, 9/9", reading the keys
as the ufw file names them — `.all.` and `.default.`. `system` read every
interface and found `net.ipv6.conf.eth0.accept_redirects = 1`. Both readings are
correct; the finer instrument won, and the reason it won **is the class's own
property**: checking the declared object instead of the governed one.

### C74's material instance — the hardening that never reached the interface

Verified independently by the main session, with the IPv4 twin as the control
that proves the instrument:

```
net.ipv6.conf.all.accept_redirects     = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv6.conf.eth0.accept_redirects    = 1   <- the only physical interface
net.ipv4.conf.eth0.accept_redirects    = 0   <- the same declaration DID reach it
net.ipv6.conf.docker0.accept_redirects = 0   <- created after the write, inherits default
```

`eth0`'s `inet6_dev` is a copy taken at `NETDEV_REGISTER`, before
`systemd-sysctl` runs. The later write to `.all.` lands in a different struct and
does not retro-apply; `.default.` governs only devices created afterwards. Both
hosts, identical. Exposure is modest — `eth0` carries only a link-local address
and there is no IPv6 default route — but **the CIS deviation register records
this control as enforced, on the one interface where redirects arrive.**

Nothing could have detected it: the repo's only sysctl guard compares
*declarations against declarations*, and `grep -c sysctl` over the deployed goss
posture template returns **0**. A previous run's "30/30 sysctls clean on both
hosts" compared each declared key to itself.

**Convergence.** `ansible-deploy` reached the same blind spot from the other
end and never saw the instance: the collision detector at `base/system.yml:189`
runs at play position 10 of 433, cannot see `/etc/ufw/sysctl.conf` (outside its
glob), and **still returns zero when the path is appended**, because ufw writes
`net/ipv4/conf/all/log_martians` in slash notation while `/etc/sysctl.d` uses
dots and the awk keys on the literal string. Two agents, two directions, one
missing instrument.

### Minted — 1, after arbitration of 2 proposals

`backup` proposed a class and then declined it itself, correctly: *a design
justified by a capability the counterpart's own machine-readable schema says it
has* is C01's property applied to a new kind of referent, not a new class. That
is what reopened C01 instead. **The discipline is worth naming: the agent that
found the property argued against minting it.**

C86 was minted because it fails the opposite test — it is not a documentary
claim at all. See the OPEN table above for the property, the space, and why it
is neither C29 nor "a pin that stopped binding".

### Reopened — 2, and both bounds were DERIVATIONS rather than directories

This is the sixth time the scope trap has been paid, and its shape has changed
in a way the next run should carry: the bound that failed was not a directory
someone happened to be reading. **It was a correct, derived gate whose
derivation keys on the wrong axis.**

- **C10** derives its set from `docker inspect` — bind sources a container
  declares. A credential file that **no container mounts** cannot enter that set
  at any point in the future, for any value of the data. The two restic
  repository passwords are exactly that.
- **C01** enumerated 218 referents of five machine-checkable kinds. A claim
  about a third party's capability is a sixth kind and was never in the space.

### The broken-gate accounting, and one gate that lived for a day

The 0444 secrets are **not** scored as a broken gate, and the reason matters:
the gate that would have caught them — `world_readable_secret_writes()`, which
derives its population from the `dest:` of every task writing under the secrets
directory, i.e. **exactly the restated space C10 now needs** — was added by
`c75d473` and deleted wholesale by `23fab2e` the next day, together with the
mode change that created the instance. `grep -c world_readable_secret_writes
ops/check-secret-in-environment.py` returns 0. The correct gate existed for one
day and left with the defect it was written for.

### Downgraded from GATED — 1, for the reason that already cost C02, C13, C20, C26 and C17

**C16 leaves the GATED table.** Its enumeration is genuinely derived — every
running container, every `.Mounts[] | select(.Type=="bind" and .RW)` — but its
**predicate is a proxy**: `[ "$owner" = "$OPERATOR_UID" ] || continue`. Measured
tonight: of 27 read-write bind mounts, 11 are skipped for `CAP_DAC_OVERRIDE` and
1 for a matching uid; **15 pairs reach the test and not one of their owners is
1000**, so zero of fifteen can ever reach the `problems+=` line. `mounts_seen`
is 15, so the anti-vacuity floors do not fire either. The check is not silent at
zero — **it is silent at every value the machine can produce.** The class itself
is CLEAN: `services` swept the real property (uid/gid/capabilities against
owner/group/mode, no `test -w`, no `docker top -o uid`) at **27/27**.

### Gates re-read and CONFIRMED derived — 6

Recorded so the next run does not re-derive them. **C07** — both constants come
from the same Jinja expression that writes the alarm floor; live 120 samples
against a floor of 100. **C11** — 9 `user:` in compose, 9 `-user:` assertions,
9 live `Config.User` matching; the 2026-09-05 midday "BROKEN" verdict is
confirmed wrong for the second time and should stop being re-litigated.
**C14** — names no host and no resolver, and its cardinal reconciles exactly
with the demand side: 18 distinct `Host()` in the live routers, 18 certificates,
0 either way; the parse re-run against the live `acme.json` returns the cached
stamp, so Traefik 3.7.13's schema still matches. **C41** — re-run read-only
against the live database: 15 push monitors against a floor of 10, 0 silent past
their own window, 0 at `resend_interval = 0`. **C15** — `--append-only` is still
0.14.0's flag grammar, on the live argv, and rest-server exits on an unknown
flag, so it cannot be ignored rather than refused. **C18** — 26/26 on the TAP
the backup itself wrote, and both halves the register records are confirmed on
the deployed spec. **CORRECTED 2026-09-20 (eleventh run): the deployed spec now
carries 46, not 26** — `grep -cE '^  dump-' /etc/goss/backup-dumps.yaml` = 46,
the live beat reads `dumps ok (46 checks)`, and a hand-run answers
`Count: 46, Failed: 27`. Derive it; do not carry the number.

Three residues, none a downgrade. **C10's** derived core is supplemented by two
named assertions that *are* a list, because the derivation structurally cannot
see what they cover. **C15's** assertion is syntactic (it proves the string is in
argv, not that a delete is refused), takes `head -1` of `pgrep`, and runs
**DAILY — this line said `weekly` until 2026-09-20 and it was the third
consecutive run to find it so.** The deployed timer is `OnCalendar=*-*-* 08:00`
with `RandomizedDelaySec=15m`. It is a 1-day detection window on the single
property that makes the
offsite a backup rather than a mirror, two weeks after the operator moved the
restic-lock detector to a 5-minute cadence for a strictly less consequential
property. **C19's** goss half is byte-identical to what the register recorded and
still exits 0 with the binary absent; its script half is derived.

### C84 and C85 — both minted 09-05, both verified FIXED, one with a false rationale left behind

**C85 is fixed**, host and repo agree: `homelab-unlock` journals the `e2fsck`
verdict on all four `rc` cases of the RUN branch, symmetric with the SKIP
branch. **C84 is fixed in deployment and wrong in the spec that exempts it**:
`immich-redis` now runs `--appendonly yes --appendfsync everysec` with a live
55 MB AOF, while `/etc/goss/posture.yaml` still exempts Redis on the ground that
"both instances run with persistence off… and never will". That sentence is a
C01 instance of the newly restated kind — a claim about a component's behaviour,
contradicted by that component.

### Rejected from the agents, and why

- **`backup`'s mint proposal** — declined by the agent that made it, and the
  main session agrees. Folded into C01's restated space.
- **`network`'s `cap_add: SYS_NICE` instance, as a succession finding** — kept
  as a finding, reclassified. The capability grant is not "an input the running
  version no longer reads": the grant is real, it is in the bounding set, and it
  MUST stay, because the binary carries the three capabilities as file
  capabilities with the effective bit set and the kernel refuses to `exec` such
  a binary when any of them is outside the bounding set. What is wrong is the
  sentence in `compose.yaml` explaining why it is there. **C01 instance, and the
  reclassification is load-bearing**: read as a succession finding, the obvious
  remedy is to delete the capability, which kills the container at exec.
- **`security`'s A15** — left unresolved rather than guessed at, and that is the
  right call. Resolving it costs one command after the next deploy that touches
  `after.rules`: `iptables -L DOCKER-USER -n | wc -l`. If it reads 16 rather
  than 8, `--noflush` is appending.
- **`system`'s 3.5 residual** (the tamper `poweroff` merged into a live
  `reboot.target` transaction) — recorded, not proposed. Testing it requires a
  reboot on the host that must not be rebooted, and the security outcome of
  "rebooted" and "powered off" is nearly identical here because both leave the
  volume locked.

### Two agents wrote something, both disclosed it unprompted

- `system` wrote a five-line throwaway unit to `/run/ctl-test.service` (tmpfs) to
  give `systemd-analyze verify` a positive control, and removed it in the same
  command. The control worked — the tool reported the bogus directive — and the
  sweep it validated came back clean on both hosts.
- `security` ran `sudo ufw --dry-run reload`, then verified `DOCKER-USER` still
  held exactly 8 rules with monotonically increasing counters. Nothing was
  applied, and the command printed no ruleset, which is why A15 is unresolved.

Both are recorded because the rule says change nothing and both are writes in
the strict reading. Neither is a repeat of the 2026-09-02 breach, and in both
cases the disclosure came from the agent rather than from the verification.

### One instrument trap worth carrying

**An un-`sudo`'d recursive `grep` silently skips root-only files.** It cost
`system` three of five output parsers on its first pass and `grep` said nothing.
Any sweep of `/usr/local/bin` on these hosts must run as root or state that it
did not.

## The run of 2026-09-05 (evening) — the key was `interruption`, and it cost the clean sheet

**For every mechanism that changes state in more than one step, what does it
leave behind if it stops BETWEEN two of them, and can anything tell that remnant
apart from a finished result?** `time` asked *when*, `order` *in what sequence*,
`identity` *who*, `scale` *how much*, `authority` *on whose authority*,
`representation` *in what encoding*, `vacuity` *what at zero*, `exclusivity`
*what at two*. **Nothing in 83 classes had asked what at HALF** — the words
`interruption` and `crash-consistency` appeared zero times in 280 KB of
reference files, and `atomic` once in each.

The key was given three admissible shapes so that agents would not return
thought experiments: (1) the half-remnant is INDISCERNIBLE from a finished
result for its consumer; (2) it BLOCKS the next pass in silence; (3) the resume
REDOES or SKIPS work silently. Everything else was to be refuted with a number.

### The eight sweeps, and the five that came back empty

| Domain | N | How N was derived | Result |
|-----------------|-----|--------------------------------------------------------|--------------------|
| ansible-deploy | 155 | 573 module sites -> 396 state-changing -> 69 multi-step + 61 write/handler pairs + 25 resume decisions | 120/120 in scope, 1 latent, 0 mint |
| system | 82 | 35 timer-driven services + 37 non-timer units on the boot/shutdown path + 10 system executables, both hosts | 82/82 classified, 31 read at code or disk, 1 instance |
| services | 62 | 29 shutdown paths + 19 persistent-artefact writers + 8 work queues + 6 host lifecycle mechanisms | 62/62, 1 instance |
| project-manager | 59 | 82 files -> 855 sections -> 92 machine candidates -> 59 after arbitration, +2 by hand for a disclosed instrument miss | 59/59, 4 instances, **24 already handle interruption** |
| backup | 31 | 5 resticprofile sequences + 2 multi-`ExecStart` units + 6 dump producers + the goss->TAP->push chain + 4 offsite mechanisms + 2 LUKS-header + 11 restore procedures | 31/31, **0** |
| network | 30 | 8 network executables + 4 pihole crons + 1 access-log rotation + 6 Ansible operations + 8 daemon-internal sequences + 3 state fingerprints, both hosts | 30/30, **0** |
| security | 30 | 7 multi-step executables/units + 7 enforcement transitions + 8 handler sequences + 8 documented manual procedures | 22/30 deep, 8 handed to ansible-deploy, 2 instances |
| observability | 22 | 8 reporting chains + 10 durable state writes + 4 stores re-read afterwards | 22/22, **0 interruption instance** |

**Five domains returned an evidenced empty space with a stated cardinal, and
that is the run's most reusable output.** Recorded so nothing re-derives them:
Ansible writes through `atomic_move` at 160 of 163 sites with `unsafe_writes`
nowhere in the repo, and the 61 write/handler pairs were compared against
`StartedAt`/`ActiveEnterTimestamp` on both hosts with **zero** stale pairs;
`pihole -g` writes `info.updated` into the TEMPORARY database, so an interrupted
gravity build cannot refresh the timestamp its guard reads, and the swap `mv` is
atomic; all five dumps write in place, but the C18 floor is a COMPLETION MARKER
rather than a size and it runs after every dump and before the snapshot, so a
truncated dump can neither survive nor be certified; an interrupted offsite copy
has been caught and retried twice in the historical record (07-20 empty -> 2
snapshots on 07-21; 23 on 08-23); `dpkg --audit` is empty and
`/var/lib/dpkg/updates/` is empty on both hosts; and no `.tmp`, `.new` or
`.part` residue exists anywhere that was looked.

**None of the eight reporting chains pushes "up" for its own first half.** All
push once, on the last line.

### Minted — 2, after arbitration of 4 proposals

Two proposals were refused, and the reason they were refused is the same
sentence the register has used four times: *define the class by its property,
not by the directory you happen to be reading.* Applying it symmetrically is
what turned them into reopenings instead of mints, and the security agent had
already applied it against its own second proposal before the main session saw
it.

| ID | Property | Space | Cardinal | State on arrival |
|-----|-------------------------------------------------------------|-------------------------------|-----|------------|
| C84 | A work queue whose only record of what REMAINS to do is destroyed by the same interruption that leaves the work unfinished | Every store in the estate holding outstanding work | **8** — 7 durable, verified on disk; 1 volatile | ENUMERATED 8/8 |
| C85 | A verification whose verdict is delivered only to an EPHEMERAL channel — the operator's interactive terminal — so that afterwards nothing distinguishes "ran and passed", "ran and repaired" and "did not run" | Operator-launched system verifications that produce a verdict | **6** — 2 produce an INTEGRITY verdict | ENUMERATED 6/6, 1 instance |

Both arrived with their space already swept, which is why neither is OPEN.
**They are adjacent and deliberately not merged**: unifying them would give
"any record whose consumer needs it after an interruption", whose space spans
all eight domains and has no derivable cardinal — the exact shape this file
calls "you can only sample it forever". A later run may merge them once both
have been closed; it must not merge them to make one sweep look bigger.

### C84's instance, verified by the main session rather than relayed

`immich-redis` runs `redis-server --save ""` with `appendonly no`
(`docker inspect` on `.Config.Cmd`, plus `config get save` returning empty and
`config get appendonly` returning `no`). It is **not** a cache: Immich's BullMQ
queues live in it — the keyspace carries `immich_bull:*` across
`thumbnailGeneration`, `smartSearch`, `videoConversion`, `storageTemplateMigration`
and `workflow`, 51 keys at the time of reading, all `meta` / `stalled-check` /
`id` / `events` with no `:wait` or `:failed` list, i.e. the queues are empty at
this instant.

The faulty reasoning is written into the deployed assertion:
`/etc/goss/posture.yaml:2336` exempts Redis because it "has nothing to recover"
— true of the Nextcloud cache, and false in consequence for a queue. No monitor
and no goss spec looks at it.

Live residue, re-measured by the main session on the deployed database rather
than taken from the agent: **2 of 9 474 active assets have no `thumbnail` row in
`asset_file`** (`asset_file` holds 9 512 thumbnail and 9 512 preview rows).
The agent's further counts — 28 never face-detected, 37 never
duplicate-checked — were not independently re-derived and are recorded as its
measurement, not the session's.

**The doubt is recorded because it is real and it belongs to the instance, not
to the class**: a job that FAILED and was then evicted leaves the same residue
as a job that was interrupted, and nothing retained can separate them. The class
does not depend on that: the volatility is a configuration fact, and
`journalctl -u docker` holds **220 SIGKILL-at-grace-expiry events since
2026-08-15 across 18 of the 29 containers**, the most recent this evening at
15:56 — so the interrupting event is frequent rather than hypothetical.

### C85's instance, and the asymmetry is in the deployed script

The shutdown of boot `fdbfd00114b84b75a75ee32503450ebf` did not unmount
`/mnt/data`: four `Unmounting timed out. Terminating.` on the docker overlay2
mounts and a `Deactivation timed out` on the swapfile, at 2026-09-01 01:47:39-41,
against 1 clean unmount / 0 timeouts on boots -1 and -3. The 4.6 TB volume went
down dirty.

`homelab-unlock` ran at 02:02:46 — and the **only** trace that it ran at all is
the `sudo` line in `auth.log`. Read on the deployed script:

- line 92: `logger -t homelab-unlock -p daemon.warning "$SKIP"` — the SKIP
  branch IS journalled.
- line 110: `rc=0; e2fsck -p -C 0 "/dev/mapper/$MAPPER" || rc=$?` — the RUN
  branch is **not**.

And the superblock cannot substitute for it: `tune2fs -l /dev/mapper/data_crypt`
still reads `Last checked: Wed Aug 26 21:22:20 2026`, because `e2fsck -p` on a
filesystem it deems clean exits without rewriting the field. So "repaired",
"had nothing to do" and "was skipped" are indistinguishable one hour later, on
the volume that carries the data, the Docker store and the local restic
repository. The remedy is one `logger` line symmetric with the one already on
the SKIP branch — not a new script, so ADR-030 is not engaged.

### Broken gates — red tests, not audit results

**C26 (a credential reaching a command line, a child process, a scheduled job or
a TRACE) — the trace axis, which is the one axis it was ever GATED on.**
`roles/deploy/tasks/backup.yml:67` passes `RESTIC_PASSWORD` through
`environment:` under `become`, so Ansible builds a `sudo ... /bin/sh -c
'RESTIC_PASSWORD=<value> ...'` command line and **sudo logs the command line**.

Re-measured by the main session, without `sudo`, from the operator's own shell,
and then RE-measured a second time because the first pass counted the variable
NAME rather than the leak:

    ls -l /var/log/auth.log   -> syslog:adm 0640 ; id -> ...,4(adm),...
    grep -ah 'RESTIC_PASSWORD=' auth.log auth.log.1 | grep -ac BECOME-SUCCESS   -> 82
    grep -ah 'RESTIC_PASSWORD=' auth.log auth.log.1 | grep -avc BECOME-SUCCESS  -> 2

**82 lines carry the value**, spread over twelve days from 2026-08-23 to
2026-09-05 (14 on the worst day, 6 today). The 2 remaining matches are earlier
audit agents' own `grep` patterns, which is also the whole explanation of the
other three variables the first pass reported: **`WG_ADMIN_PASSWORD`,
`KILLSWITCH_KEYWORD` and `CF_DNS_API_TOKEN` are NOT leaked.** Their occurrences
are `awk -F= '/^WG_ADMIN_PASSWORD=.../'` and similar audit commands logged by
`sudo`. Those three secrets live in `.env` files and never reach a command line.
**The counting method was the defect**: matching `NAME=` finds the pattern of a
command that searches for the secret exactly as readily as the secret itself.
Any future sweep of this class must require a value, and the discriminator that
works here is `BECOME-SUCCESS` — because the leak is Ansible's become wrapper.

**And that narrows the mechanism usefully**: the nightly backup reads its
password from `backup.env`, a FILE, so it leaks nothing. The 82 lines are all
`ansible-playbook` runs. The exposure is per-DEPLOY, not per-night, which is why
it starts on 2026-08-23 rather than at the beginning of the journal.

**The systemd journal is a second store** and `journalctl` needs no `sudo` for
the same `adm` reason — 11 matching lines in the current boot alone (4 days) and
2 in boot -1. A purge would have to cover two stores with independent rotations,
which is the argument for fixing the SOURCE first.
**Do not carry the figure of 123 that an agent reported for the whole journal**:
the session's own per-boot samples run at a few per day and do not extrapolate
to it, the total was not completed within budget, and the finding does not
depend on it. The `auth.log` figure of 82, which the same agent reported, DID
reproduce exactly. The privilege gain is nil — the reader is already in
`sudo` — but the secret ADR-011 places on the LUKS volume is duplicated in
cleartext **on the SD card**, which is the medium `sd-theft-response.md` assumes
carries none. Space enumerated at 4 tasks. The remedy is
`RESTIC_PASSWORD_FILE`, **not** `no_log`, which `settled.md` already forbids.

### Downgraded from GATED — 1, for the reason that already cost C02, C13, C20 and C26

**C17 (a filesystem never checked, and boot triggers reset every boot).** Its
three assertions are hardwired to `/`: **one filesystem out of four**, and
`Last checked` is still asserted nowhere — the same omission this file recorded
on 2026-08-30 and which has now survived six days. A list of one is not a gate.
It goes to ENUMERATED. **Nothing is proposed**: its only live instance is the
offsite root, nine days past its interval with a frozen trigger, and the
operator DECLINED that on 2026-09-02 (`offsite.yml` never plays the
`observability` role).

### Register corrections — five, and three were the register being behind the repo

1. **C11 is NOT broken, and this morning's line is stale by one day.** The
   numbers are unchanged — 9 assertions against 11 containers with a non-empty
   `Config.User` — but the deployed template now carries the written arbitration
   of exactly that gap (`goss-posture.yaml.j2:322-340`, re-read by the main
   session): `Config.User` returns the IMAGE's user when compose declares none,
   so asserting the complement would mean writing upstream's values into this
   repo, and a service that loses its `user:` is answered by review of
   `compose.yaml`, not by a probe of the result. Under its own property the gate
   is derived 9/9. **Correct the register, not the spec.**
2. **C18 carries 26 checks, not 22**, and the derivation defect recorded this
   morning is FIXED: `-container-present` is generated in the same loop
   (2x3 + 3x5 + 5 = 26, counted on the deployed spec). The residue is a list of
   one, Immich.
3. **C19's script half is no longer vacuous at zero** — the `timers_seen -eq 0`
   floor shipped 2026-09-05 (`homelab-health.sh:592`). Only the goss half still
   is (positive control: `PATH=/nonexistent` -> exit 0). Two agents said this
   independently.
4. **C14, C15, C21, C41 and C16 were each re-read at the code and are genuinely
   DERIVED.** C14 iterates `store.values()` and names no host, so a certificate
   added tomorrow is covered without an edit (18/18 live, 33 days to the nearest
   expiry against a 21-day threshold). C41 selects `active=1 and type='push'`,
   compares against each monitor's own `interval`, and starves below n=10; killed
   mid-evaluation it fails loudly. C21's description was re-verified for a third
   time and holds.
5. **C81's gate is active but its path filter is a LIST OF ONE**:
   `ASCII_STRICT_PREFIXES = ("/etc/ufw/",)`. Its `marker:` half is derived, the
   hook is wired in `.pre-commit-config.yaml` and was made to fail on purpose in
   a sandbox with both negative controls passing, and its two blind spots
   (`*.yaml`, `.j2` into `/etc/ufw/`) are empty today. Recorded, not downgraded:
   unlike C17 the class has never had a live instance outside the listed prefix.

### Rejected from the agents, and why

- **"4 truncation points out of 4 load a partial Immich database silently."**
  Re-measured by the main session on the runbook's exact pipeline against a
  disposable Postgres 16 on the workstation: **12 of 30 truncation points commit
  silently with exit 0** (3 159 to 19 399 rows of 20 000); the other 18 are
  caught by `ON_ERROR_STOP` and roll back. The headline survives, the generality
  does not — whether it is caught depends on where the cut falls inside the
  `COPY` block. The agent's own negative control (a truncation inside an
  `INSERT`, which errors cleanly) was correct and is what made the difference
  visible.
- **"The tamper was refused while armed"** was very nearly rejected by the main
  session and turned out to be RIGHT. `fake-hwclock` makes boots -1 and -2
  overlap in wall-clock time, so a `ConditionPathExists` skip at 01:44:44 looks
  like it precedes the refusals at 01:47-01:48 and belongs to the same boot. It
  does not. Per-boot: `armed` at 2026-08-30 17:31:56 in boot -2, no disarm, and
  the three refusals are the last lines of that boot. **Check the boot id before
  reasoning about any timestamp on this host.**
- **Three refusals, not two.** 01:47:38 (`systemd-tmpfiles-setup-dev-early`
  stop), 01:48:17 (`systemd-tmpfiles-setup-dev` stop), 01:48:20 (`reboot.target`
  start), each with `exit code 4` from the udev worker.
- **And the window is 8 boots, not 6** — a `--list-boots | tail -6` truncated the
  list on the first pass; the retained journal runs from 2026-08-16 22:09,
  boots -7 to 0. The correction ENLARGES the evidence. Over those 8 boots
  `usb-tamper.service` appears exactly **5 times, every one of them "skipped
  because of an unmet condition check"** — the coldplug replay at boot, before
  arming. **So in the whole observable window the unit has never once passed its
  own condition, and its only recorded opportunity to fire ended in `exit code
  4`.** The main session verified the 5 skips independently before this was
  written.
- The `journalctl --grep=TRIGGER` over the entire retained journal, with no tag
  filter, returns zero real occurrences — and it carries its own positive
  control for free, because `sudo` journals the `COMMAND=` of the grep itself,
  which is the only line that matches. That is instrument trap #4 of
  `settled.md` satisfied without extra work, and it is worth reusing: **a grep
  meant to return zero can be controlled by the audit line of its own
  invocation.** It costs ~30 minutes on this host and belongs in the
  background.
- **The restic `locks/` directory is NOT empty**, contrary to this morning's
  entry: 2 stale locks from 11:28 today, almost certainly a midday agent's
  restic commands killed by a tool timeout. No consequence — restic expires them
  at 30 minutes, and the `--lock-wait 2h` recorded this morning is
  *resticprofile*'s lock, not the repository's.

### Two near-mints declined, and one instrument miss disclosed by the agent that made it

`CERT_STAMP` is rewritten in place and a torn read would freeze the ACME ratchet
low for ~60 days — zero trace and a microsecond-wide window, so a thought
experiment. And the `Restart pihole && restart dnsproxy` handler interrupted
between its two commands costs LAN DNS with two green containers — real, but
**detected in 5-9 minutes** by the random-label DNS probe, so neither form 1 nor
form 2.

The documentary agent disclosed that its mutating-verb pattern missed two whole
runbooks (`kill-switch.md`, `usb-tamper.md`) because their commands are
in-house executables — *a sweep by verb list is a list, not a derivation*, which
is the same criticism this file levels at enumerative gates. Both were
reinstated by hand and the cardinal of 59 includes them.

## The run of 2026-09-05 (midday) — the key was `exclusivity`, and it minted nothing

**For every mechanism that touches shared state — a file, a database, a
repository, a lock, a container, a package database, an interface, a systemd
unit, a git branch — what happens when a SECOND actor touches the same object
while the first is still working? What makes that impossible, and does anything
assert it?** `time` asked *when*, `order` *in what sequence*, `identity` *who*,
`scale` *how much*, `authority` *on whose authority*, `representation` *in what
encoding*, `vacuity` *what at zero*. **Nothing in 83 classes had ever asked what
happens at TWO.** The register's previous header said the next key would have to
be invented; this is the invention, and its yield is zero classes.

**That zero is the run's result, and it is worth more than the 92 instances.**
Eight domains swept eight independent concurrency spaces and every one of them
dissolved on measurement rather than on argument:

- **No timer can overlap itself.** All 13 homelab units measured against their
  own periods; the worst ratio is `homelab-health` at 45-58 s of 300 s, taken
  under load average 8.06 with eight agents on the machine. `homelab-stack-heal`
  is `OnUnitActiveSec`, so overlap is unreachable by construction, and systemd
  merges a tick that lands on an active oneshot. Nothing logs that merge, but
  C41's derived dead-man catches the consequence, so the gap is already gated.
- **The backup locks are real and taken.** `flock` has zero live invocations
  anywhere in the estate except `resticprofile.yaml.j2`, where both profile
  locks are declared and the `locks/` directory is empty. The one true collision
  the journal still holds — 2026-08-17 03:12:53, the old `backup.sh` degrading a
  lost lock to a WARNING and then printing "Backup completed" — is structurally
  impossible under ADR-031. Weekly units carry `--lock-wait 2h` against a
  measured 2m25s-21m37s backup and a 1h38m margin.
- **`ufw reload` cannot eat a fail2ban ban.** `delete_chains` is a hardcoded
  list, every restore is `-n`, `MANAGE_BUILTINS` is unset and `flush_builtins`
  is unreachable from a reload. The two jails use distinct `f2b-*` chains.
- **One writer per object, everywhere it mattered.** 15/15 Kuma push tokens have
  exactly one producer; four state directories, one writer each; one Traefik,
  one resolver, one `acme.json` writer, and a torn ACME read fails loudly and
  self-heals; 60 bind sources yield exactly one two-writer path (`nextcloud` +
  `nextcloud-cron`), which is guarded by `memcache.locking=\OC\Memcache\Redis`;
  five internal-writer/external-dump pairs, all guarded by `--single-transaction`,
  `pg_dump` MVCC or `sqlite3 .backup` — and Nextcloud is **177/177 InnoDB**, so
  that guard is load-bearing rather than decorative.
- **The apparent WireGuard address collision dissolved**: the homelab Pi is
  itself one of wg-easy's four clients, so there is one allocator for the
  subnet, not two.
- **Two Ansible runs have no lock and need none here**: no fact cache, atomic
  `rename(2)` writes, no `serial`/`throttle`, one host per play. The only shared
  objects are four fixed-name temp paths, where run A's cleanup deletes run B's
  probe input — and that fails loudly, which is below the mint bar.
- **The heal-loop-versus-operator shape has no interlock**, only a convention.
  It is documented in five places and settled via #126, and it belongs to C44
  and C69. Refined, not minted.

**Two near-mints were declined on the evidence, and recording why is the point.**
The shared git worktree carries no `local.yml`, so a deploy launched from one
would run against `local.example.yml` — real, but an operational note rather
than a class, and the extra checkouts are clean and unmerged. And systemd's
silent merge of a coalesced timer tick is a genuine unobserved event whose
consequence is already caught elsewhere.

### C83 — CLOSED, 976/976, and the sweep is worth more than the count

**One question asked over the whole estate**: if the set this site iterates, or
the output it consumes, or the artefact it certifies, had ZERO elements, would
its report be distinguishable from the healthy one? Last night five domains
asked five different questions and no cardinal could be stated; this is what
changed.

| Slice | N | How N was derived | Instances |
|-----------------|-----|------------------------------------------------------------------|-----|
| observability | 401 | 254 `exec:` blocks re-parsed off 4 deployed specs on both hosts (267 resources, +3 = a31b1d6's `-content` checks) + 147 verdict sites in 9 deployed shell artefacts | 36 + 1 susp |
| system | 162 | 134 report/log/exit/marker sites in the 12 INSTALLED executables + 25 homelab unit artefacts + 3 offsite; derived from what is installed and executable, so the extensionless `homelab-luks-header-backup` is in it | 1 |
| ansible-deploy | 124 | scripted: 90 task files, 568 tasks, derived-name set built per role to fixpoint -> 89 `when:` + 10 Jinja loops + 25 predicates | 5 |
| project-manager | 113 | 82 files -> 228 fenced blocks -> 159 bash/sh -> 386 statements, plus 221 inline prose spans (89 in the 48 files with no code block at all) | 14 / 13 shapes |
| services | 55 | 25 live healthcheck commands (4 of 29 containers run none) + 30 in-container self-reports, bounded three ways: cgroup-mapped process tables 29/29, crontabs 4/4, log streams 29/29 | 16 |
| security | 48 | posture derivations + every fail2ban/UFW/lynis/apt reporting path over a derived set | 13 + 1 susp |
| network | 38 | 7 deployed populations on both hosts; two spaces provably EMPTY of sites (nothing consumes the Traefik API, nothing asserts the split-DNS record set) | 4 + 1 susp |
| backup | 35 | 48 periodic units forward, intersected with every automated certifier backward — the backward pass is what catches the 6 non-timer producers | 0 new |

**976 sites, 92 instances, 884 refuted with reasons.** The 92 is a misleading
number and the register should not carry it as one: **32 of them are two
families of 16**, and 12 more are upstream scan lines nobody reads and for which
`services` deliberately proposed nothing. The material count is closer to
**thirty, in about a dozen shapes.**

C83 is **ENUMERATED, not GATED.** No assertion derives the set of unbounded
reporters, and nothing stops the next commit from adding one — the same C45
problem that C82 carries. The gate, if one is ever written, is the floor
assertion the repo has already written six times by hand.

### Instances that matter, verified by the main session rather than relayed

1. **Sixteen backup-dump assertions go green when their container disappears.**
   `docker inspect <svc> >/dev/null 2>&1 || exit 0` opens all four assertions
   for each of vaultwarden, forgejo, uptime-kuma and **immich-server**, and none
   of the four carries a `stdout` matcher, so the early exit satisfies
   `exit-status: 0` exactly. Read on the deployed spec, not the repo. The idiom
   is deliberate — it lets one spec cover a host where a service is not deployed
   — and its defect is that it cannot tell "not deployed" from "vanished". **The
   severity is concentrated on one of the four**: Immich's datadir left the
   backup source set on 2026-08-31, so its dump is the only copy, while the
   other three still have their datadirs backed up. The SQL dumps (miniflux,
   nextcloud) carry no such guard and fail loudly. Antidote: `homelab-posture.sh`'s
   absent-vs-unresolvable distinction.
2. **Sixteen `*-cap-add` posture checks pass on an absent container.** Control
   taken by the main session: `docker inspect no-such-container | jq -r
   '[.[0].HostConfig.CapAdd[]?] | sort | join(" ")'` prints an empty line and
   exits 0 — byte for byte the healthy output of `socket-proxy`, because the
   pipeline's status is `jq`'s. Rescued by composition: the 29 sibling
   `cap-drop` checks fail on the same absence. Low severity, high count.
3. **Three of five SMART early-warning counters are not on this drive.**
   `homelab-disk.sh:109-115` loops over `5 184 187 198 199`; the drive's
   attribute table holds `1 3 4 5 7 9 10 11 12 192 193 194 196 197 198 199 200`.
   **184 and 187 are absent and their absence reads as zero** — `system`
   reported four of five, and the main session's re-measurement makes it three
   of five. The antidote (`ext4_seen`, a count carried into the message) is 200
   lines below in the same file. `197` at 2 is NOT a finding: it is deliberately
   excluded from that loop, reported always, and alarmed on a RISE (#207).
4. **The Nextcloud background-jobs alarm names the one thing it cannot see.**
   Verified at the source inside the running container:
   `core/Service/CronService.php:113` sets `lastcron` AFTER `runCli()` returns,
   unconditionally and outside every per-job loop. The script's own comment is
   accurate — it does detect the documented #177 failure, crond dead — but its
   DOWN text reads "background jobs have stopped", which a frozen queue behind a
   living `cron.php` cannot trip. C83 and C22 both. 67 jobs, 0 reserved tonight.
5. **The posture script's missing floor occurs five times; its misplaced
   counter, once.** Confirmed at the code by the main session:
   `homelab-posture.sh:140` `checked=$((checked + 1))` sits inside the
   `docker ps` loop and outside the inner mount loop, so `checked` counts
   containers, never (container, mount) pairs — 23 increments over 0 surviving
   pairs. The same absent floor recurs in the rw-mount loop, the Vaultwarden env
   loop, the Miniflux DSN gate and the final verdict. C10's `n >= 12` runs the
   same `docker inspect` over the same set 200 lines away.
6. **`no-undeclared-published-ports` exits 0 over an empty port list** — found
   independently by `network`, `observability` and `security`, which is the
   strongest form of evidence this register recognises. Its own comment names
   C10's derivation as its model and omits C10's floor.
7. **An empty `wg0.conf` passes `wg-generated-config-carries-no-ipv6`.**
   `grep -cE ... ` with `exit-status: 1` and `stdout: /^0$/`: an empty file
   prints `0` and exits 1, which is the pass condition exactly; a MISSING file
   exits 2 and fails. Latent and low — the peers assertion carries `[ -n "$live" ]`
   and is the real guard on that path.
8. **`homelab-wg-easy-config.sh:179`**: an empty `/api/client` logs "per-client
   values already match the repository" and exits 0, identical to four correct
   clients. It is the guard against a recurrence of #125, and its antidote is
   written over the same population in `posture.yaml`.
9. **Two documented commands are wrong on the machines right now.**
   `offsite-backup.md:28`, the command the page calls "the answer" for every
   offsite DOWN condition, lists **30 of 35** units — its character class drops
   `rest-server`, `wg-quick@wg0`, `ssh`, `fail2ban` and `/mnt/backup`, the five
   whose own comments say every other assertion depends on them. And
   `obsidian-claude-mobile-workflow.md:152`, the diagnostic the page says "makes
   it obvious", returns nothing today: 126 journal lines, zero containing `env_`.
10. **Five Ansible sites gate work on a derived fact with no else-branch** —
    netdata's second alarm derivation, Nextcloud's external-storage read-only
    loop, the credential-file 0600 loop (whose identical population IS floored
    in `goss-posture.yaml.j2:141`), the offsite disk `failed_when: false` whose
    `''` sits in the pass set of a refuse-to-format guard, and collabora's three
    `.rc | default(0)` guards.

### Broken gates — red tests, not audit results

- **C16 still broken, unchanged**, and now with the sharper statement above: one
  misplaced counter, five missing floors, in one script.
- **C11 broken, now with a number**: 9 `-user` assertions deployed against **11**
  running containers with a non-empty `Config.User`. `socket-proxy` (root) and
  `collabora` (1001) sit unasserted. The same `{% if %}` defect repeats twice
  more in that loop — `apparmor` (1 assertion) and `pinned-port` (1).
- **C19 is one word sharper than recorded**: BOTH halves are vacuous at zero,
  not just one. The goss half exits 0 with the binary absent (three controls).
- **C18's derivation half is the defect, and its emptiness half is now FIXED** —
  see the register correction below.

### Register corrections

- **C18's row no longer overstates itself.** Its property said "absent, stale or
  **empty**" and the gate did not assert empty; as of 10:39:27 on 2026-09-05 all
  six dumps carry an emptiness assertion, and `backup` verified the floor is
  **derived** — generated inside `{% for d in backup_sql_dumps %}` and
  `{% for d in backup_sqlite_dumps %}` over `group_vars/all.yml:114,125`, with
  2x3 + 3x4 + 4 = 22 matching the host exactly. That is C10's shape, not C13's
  hand-list, which is what keeps it in the GATED table. **What is defective is
  its derivation half: the 16 `|| exit 0` above.**
- **The `sshd` journalmatch entry is half REFUTED.** The `_SYSTEMD_UNIT=sshd.service`
  half is confirmed dead on both hosts (0 matches). The `sshd-session` half is
  wrong: both hosts run OpenSSH **9.6p1**, not 9.8, and `_COMM=sshd` returns
  217 337 / 10 351 matches. The consequence is measured at **zero**, with a
  positive control that the register's newest instrument trap demands: the same
  failure patterns over the whole journal since 2026-08-16, grouped by `_COMM`,
  return 7 real authentication failures elsewhere (2 polkit, 5 sudo) and 0 from
  any sshd process. The zero is a true zero, not a failed grep.
- **The `_up` gates protect ONE password enforcement, not two.** Transmission
  only reads its secret for `TR_AUTH`, and wg-easy gates on
  `wg_easy_db.stat.exists`. The four gates shipped as `debug`, so a PLAY RECAP
  still reads `failed=0`; with all four containers up the reports never fire and
  all 58 gated tasks run, so the change is inert today and its value is entirely
  on the next deploy taken with a container down.
- **The heal floor is `>= 1`, not `>= 29`.** Read by the main session at
  `homelab-health.sh:634`. It catches total blindness and not partial
  blindness, while `docker compose config --services` = 29 is available and
  free. The filter is also still `status=exited`, which cannot see `created` or
  `dead`.
- **C53's row** was corrected last night and stands: two explicit flush points
  plus the implicit end-of-play in each play.

### Verified fixed, and not re-reported

- **Both documentary fixes discriminate rather than reword**, re-run in both
  directions: `lsblk /dev/sdaX` returns `not a block device`, exit 32, so a typo
  can no longer produce the go-ahead `cryptsetup status` printed verbatim; and
  the Tier 0 list run faithfully from `$HOME` lands the operator in
  `/opt/homelab` and returns its six names. One cause is misattributed on that
  page — a dangling `/opt/homelab/.env` while `/mnt/data` is locked also yields
  zero names with exit 0 — but the decision rule is safe at zero regardless.
- **The heal fix is real and both negative branches fire.** `journalctl -t
  homelab-heal -b` returns 19 lines of `checked 29 container(s), 0 restarted`;
  the count is outside the loop in the deployed file; the missing-report branch
  and the `checked 0` branch were both exercised without creating or deleting
  anything; `f8c547c`'s producer-mtime guard is armed.
- **The dumps fix is deployed but has NOT executed yet, and the number this
  entry first carried was already stale when it was written.** The TAP on disk
  reads `1..19` from the 03:00 run that preceded the 10:31 deploy. The spec now
  holds **26** assertions, not 22: the afternoon's `-container-present` addition
  put one more on each of vaultwarden, forgejo, uptime-kuma and immich-server.
  First execution **2026-09-06 03:00**, and the beat must read `dumps ok (26
  checks)`. Nothing about the floor itself is proven before then — the four
  container assertions pass today because they do not need the dump files, which
  exist only between resticprofile's `run-before` and its `run-after`. Running
  that spec by hand at any other hour reports thirteen failures and means
  nothing; that is the shape of the check, not a defect.

  This correction is the register's own warning working: a cardinal written down
  in the afternoon and read the next morning is how the same figure has
  propagated into eight agent briefs three times.
- **`/boot/firmware/config.txt` on the homelab still carries em-dash markers**
  and is the ONLY one of the twenty corrections from 09-03/04/05 that is not
  true on the machines. It self-converges: `base/tasks/attack-surface.yml:29-30`'s
  repair regexp was tested against the real deployed bytes and matches both
  lines without duplicating the block.

### The gate, built the same day — and what it does NOT cover

`ops/check-empty-set-floors.py`, in pre-commit, refuses an iteration over a
run-time-derived set that carries no floor: `for x in $(...)`, `for x in $VAR`,
`while read` fed by a pipe, a process substitution or a here-document. It is
**derived, not listed** — it walks every goss spec template and every shell
artefact rather than naming the instances found on 2026-09-05, so a new one
written tomorrow is inside it without an edit.

Where a floor legitimately lives elsewhere, the loop declares it:

    # floor: credential-stores-derivation-nonempty

and in a goss spec **the named assertion must exist in the same file**, which
the script checks. Deleting a floor therefore breaks the commit that deletes it
— the property a comment alone would not have. That annotation is the answer to
the objection this register raises against every lint: an opt-out that only has
to be typed is a blind spot with a name.

**Made to fail on purpose, which is what this register requires before the word
GATED is used.** Six controls ship inside the script and run as their own
pre-commit hook; three must FLAG, and two of those three are real defects taken
off the machine — the published-port derivation exactly as it stood that
morning, and the crash-heal loop exactly as it stood through the 2026-08-26
outage. The sixth control is the script's own first false positive: prose
containing "... is read once a night", which matched `while ... read` before it
learned to strip comments.

**Now the part that must not be glossed.** The gate covers TWO of C83's three
faces — goss specs and shell artefacts. **The Ansible face is not covered at
all**: a `when:` gating a task group on a derived fact with no else-branch is
invisible to it, and that face carried five of this run's instances. C26 sat in
the GATED table for a week on the strength of one axis out of four and cost this
register a broken gate; C83 is therefore recorded as PARTIALLY GATED, in those
words, and the missing axis is named rather than left to be discovered.

### The floor that had been one below the truth since 2026-08-25

Applying the second half of the same decision — derive the floors where the
spec is already generated — retired `credential_store_min_count`, a cardinal
kept by hand in group_vars. Its own comment carried the evidence: "measured at
12 on 2026-08-24, then 11 on 2026-08-25 when pihole/etc moved to the
exemptions". The population before that exemption was **13**, not 12. The number
was decremented from a base that was already stale, so the floor has sat one
below the live population for eleven days: a credential store could have stopped
being derivable and `credential-stores-derivation-nonempty` would still have
passed. The assertion that exists to make a vacuous pass impossible was itself
one store away from one.

`goss-posture.yaml.j2` now derives it from `compose.yaml` over the same set the
runtime side builds — bind sources under the services data directory, kept when
exactly one service declares them, minus the declared exemptions. Verified
against the host: it produces **the twelve names the machine reports, name for
name**, and renders `-ge 12`. The exemptions stay in group_vars, because a
reason cannot be derived.

One instrument note, caught before it shipped rather than after: the first
version computed a prefix offset with `len()`, which python's Jinja has and
**Ansible's does not**. It rendered perfectly in the local test because the test
had handed Jinja a `len` it would not have on the host. The test now renders
with no globals beyond what Ansible provides, and the template uses `replace`.

### Rejected from the agents, and why

- **`system`'s "four of five SMART counters"** was optimistic by one. The main
  session read the drive's actual attribute table: 184 AND 187 are both absent.
  The finding survives, its number did not.
- **The main session's own near-miss**: `Current_Pending_Sector: 2` on the 5 TB
  drive looked like a live untold fault and was checked before being reported.
  It is deliberately excluded from the counter loop, always reported, and
  alarmed on a rise (#207). Nothing to do. The repo was right before the audit
  was.
- **`network`'s Pi-hole healthcheck headline** was killed by its own control:
  `@127.0.0.99` is not a dead DNS target, because `listeningMode: all` binds all
  of 127/8. **New instrument trap.**
- **`services`' twelve Jellyfin/Navidrome/calibre-web scan lines** are real
  instances of the property and are excluded from the material count: upstream,
  read by nothing, no action proposed. That restraint is correct.
- **Three `ansible-deploy` refutations were taken with a positive control rather
  than by reading**, including a Jinja sandbox showing that a `regex_search` miss
  yields `['None']` and not `[]`, so the Tier 0 assert fails loudly and cannot go
  vacuous.
- **Two rule-5 deviations are disclosed rather than hidden**: two read-only
  `restic dump` calls on the LOCAL repository, and three scratch files created
  and removed on the homelab by a documentation sub-sweep. Nothing touched the
  offsite repository.

## The run of 2026-09-05 — the key was `vacuity`, and it was invented

**For every mechanism that consumes or produces a set, a list, a string, a file
or a command's output: what does it do when that thing has ZERO elements, and is
that outcome DISTINGUISHABLE from the healthy one?** `time` asked *when*, `order`
*in what sequence*, `identity` *who*, `scale` *how much*, `authority` *on whose
authority*, `representation` *in what encoding*. `scale` asked what breaks at ten
times the data; **nothing in 82 classes had ever asked what happens at zero.**

Six already-paid facts were the tell, and none had a class: the offsite
`stdout: []` that emitted no assertion, `'REMOTE_MATCH' not in ''` opening its
own guard, the `pass = ` an empty rclone stdout would have written, the
`restic restore` that restores an empty directory and exits 0, the unprivileged
`grep` whose empty result was read as an absence, and the empty image list that
reads as a destroyed store.

**Sweep totals, eight domains: 1 216 sites.** system 126/126, security 272/272,
network 24/24, services 116/116, backup 75/75, observability 251/251 (goss
`exec:` blocks, 264 resources parsed off both live hosts), ansible-deploy 125/125
plus C82's 308, project-manager 80/80.

### C82 — CLOSED, 308/308, and the shape that produced it is still there

308 write-sites (`site.yml` 230 + `offsite.yml` 78, `import_tasks` expanded),
plus 77/77 binary-use sites and 34/34 handlers across 3 flush points.
**12 (writer, earlier-consumer) pairs, 2 instances, 10 refuted with reasons.**

The two instances are the known one, and the finding is that **the ordering is
unchanged**: `firewall.yml` still `blockinfile`s into `/etc/ufw/after.rules` at
lines 186 and 199, while `Set UFW default deny incoming` reads that file at line
49. What shipped heals the BYTE (the task-1 `replace`, `0cb8ef7`) and gates the
CAUSE (C81 in pre-commit). Neither touches the shape. The structural fix is one
edit: move the two `blockinfile` tasks above the default-policy task. Verified on
the hosts: 0 non-ASCII bytes across all six ufw files, markers rewritten 23:20 /
23:22 on 09-04.

**C81's gate is bounded, not broken**: its marker half is derived, its
`ASCII_STRICT_PREFIXES` half is a hand-kept list of one. Recorded so the next run
does not mistake the second half for a derivation.

**A THIRD instance appeared the same morning, and the change that closed C82
introduced it.** The corrections of this run added an assertion to
`homelab-health.sh` that reads the output of `homelab-stack-heal.sh`.
`observability` is a phase-1 role and `stack-startup` is phase-5, so the deploy
installed the check at 10:31:39 and its producer at 10:41:08; the health run at
10:41:08 pushed a DOWN for a mechanism that was working, the first `checked`
line arrived at 10:42:14, and the monitor cleared itself at 10:45:58.

Two things follow, and the second is the more important.

- The instance is fixed by starting the window at the later of "15 minutes ago"
  and "when the producer was installed" — an assertion must not demand a window
  longer than the producer has existed. Reordering the roles would fight the
  phase structure for one check.
- **C82 is ENUMERATED and that is not enough.** The sweep was correct when it
  ran; nothing stopped the very next commit from adding a pair. A class whose
  space can be re-populated by any deploy needs a gate, and C82 has none — no
  assertion derives the (writer, earlier-consumer) set. This is the C45 problem
  wearing a different coat, and it is why the class must not be read as settled
  merely because 308/308 came back clean.

### Minted — 1, after arbitration of 3 proposals

`backup` proposed "a verification that certifies an artefact's form and never
bounds its content from below" (9 artefacts, 6 unbound, 4 material). `services`
proposed "a repair loop whose success report is identical whether the set was
empty because nothing broke or because the query was blind" (0 live occurrences,
offered not asserted). `project-manager` proposed "a documented verification
whose empty output is the same observable as its success" (80/80) and said
plainly it might be the documentary face of the key rather than a class.

They are one property, and three more domains hit it without proposing anything:
`security`'s C16 derivation that increments `checked` 23 times over 0 surviving
pairs, `network`'s gravity gate that asserts a timestamp and never a domain
count, `observability`'s `self-test ok (0 checks)`, `system`'s timer loop with no
cardinal, `ansible-deploy`'s `_up` gates skipping 58 tasks with no else-branch.
Merged as **C83**; the merge is the run's real output and the convergence is
stronger evidence than any single route.

**Why it was minted rather than folded into the key.** `vacuity` is a dimension,
not a class — the same way `time` was a dimension that produced C67, C68 and C69.
C83 is one bounded defect shape inside it, with an enumerable space and an
obvious gate (a floor assertion), and it is distinct from C22, C03 and C29 for
the reasons in the OPEN table. The cost of minting it is that this run fails the
zero-mint half of the termination criterion. That cost was accepted rather than
shaved.

### Instances, grouped under C83, ranked by what is true right now

1. **Three of six dumps are certified complete and never certified non-empty.**
   `goss-backup-dumps.yaml.j2` asserts the completion marker for
   `backup_sql_dumps` and the zcat-carried marker for Immich. Both tools write
   that marker on a database with no rows. Measured against tonight's dumps:
   `miniflux.sql` 38 922 556 B against **670 B** header-only, `nextcloud.sql`
   26 916 653 B against **1 353 B**; Immich's figure is INFERRED, not measured,
   because measuring it would mean creating a database and rule 5 forbids it.
   Since 2026-08-31 those three datadirs are excluded from the source set, so the
   dump is the only copy, and Immich's `keepLastAmount=7` rotates out the last
   good dump after seven empty-but-valid nights. **The same file's SQLite half
   already carries the floor** — `select count(*) from sqlite_master >= 1` — with
   its reasoning stated verbatim: "a ZERO-BYTE file passes quick_check […]
   Restoring an empty Vaultwarden is not a lesser disaster than restoring a
   corrupt one." It was not carried across. The SQL half's comment explains why
   it dropped a BYTE FLOOR (10240 B was 0.037 % of miniflux.sql, #127) and that
   reasoning is correct — but a row-count floor is not a byte floor.
2. **The crash-heal timer cannot distinguish a clean stack from a blind query.**
   Every `logger` call in `homelab-stack-heal.sh` sits inside the `while read`
   loop over `docker ps --filter status=exited`. Verified on the host tonight:
   `Result=success`, `ExecMainStatus=0`, `journalctl -t homelab-heal -b` ->
   `-- No entries --`. **The script's own comment records that this exact string
   was the observable throughout the 2026-08-26 outage**, when 15 containers sat
   stopped and the timer fired every two minutes into an empty `exit 0`. #241
   fixed one cause; two remain (`status=exited` cannot see `created` or `dead`,
   and a never-created service is invisible). 23 of 29 containers are
   `restart: "no"` and have no other recovery path. One line: log the count
   outside the loop.
3. **The LUKS header restore is licensed by a word a typo produces.**
   `luks-header-backup.md:100-106` tells the operator to read `cryptsetup status
   data_crypt` and treat "inactive" as the good case, one line above what its own
   comment calls "how you lose the disk". Measured with a positive control:
   `cryptsetup status data_cryptX` prints `/dev/mapper/data_cryptX is inactive.`
   — the literal go-ahead. Exit is 4, but the page directs a human to read the
   text, not `$?`. Disaster-recovery path, one-sentence fix.
4. **The Tier 0 rebuild list yields zero from anywhere but `/opt/homelab`.**
   `boot-and-unlock.md:86-89` deliberately replaced a hardcoded list of six with
   a derived command — good instinct, and the page says why. But `docker compose
   config --format json | jq …` returns **6 lines from `/opt/homelab` and 0 lines
   with exit 0 from `$HOME`**, because the pipeline's status is `jq`'s. Measured
   both ways tonight. The section "If the orchestrator aborts" sends the operator
   to that list to rebuild missing Tier 0 containers by hand, during a boot
   failure.
5. **Four `_up` liveness facts gate 58 tasks with no else-branch.**
   `nextcloud_up` / `collabora_up` / `transmission_up` / `pihole_up` in
   `roles/deploy/tasks/`. A container that is not Running silently skips the
   files_lock timeout, the external-storage read-only flags, all of LibreSign and
   **two password enforcements** — the last being a C20 instance by a route its
   four probes cannot see. All four containers are up tonight. The antidote is in
   this same repo at `observability/tasks/main.yml:43`, with the comment "The run
   was correct; its silence was not."
6. **Pi-hole gravity is gated on its timestamp and never on its content.**
   `pihole-gravity-not-stale` reads `info.updated`; a `grep -rn` for any
   domain-count assertion returns nothing. `gravity.sh` calls
   `update_gravity_timestamp` unconditionally after the download step, which
   returns 0 even when every list ends at `status=4` — so a rebuild yielding zero
   blocked domains refreshes the very timestamp the gate reads. Healthy tonight
   (79 747 domains). Latent; privacy and comfort, not availability.
7. **`homelab-notify-push.sh:82` counts checkmarks with no floor**, so a
   self-test producing neither glyph pushes UP as `self-test ok (0 checks)`, and
   the same event silences the failure detector. Latent (6 checks parse today).
   Recorded under C22 as well as C83.
8. **`homelab-health.sh:558`** iterates `homelab-*` timers with no cardinal in
   the message; 13 tonight, and at zero it reports what 13 clean timers report.
   12 of 13 carry an independent derived dead-man, so impact is small.

### Broken gates — red tests, not audit results

- **C16 is broken and sharper than recorded.** Its predicate
  `owner == OPERATOR_UID` is a proxy, and `security` simulated the derivation
  live: 23 containers reach the mount loop and **0 (container, mount) pairs
  survive**, while `checked` increments 23 times and the report says "posture OK
  — N checks". Confirmed at the code by the main session:
  `checked=$((checked + 1))` sits outside the inner loop. C16's own recorded
  instance is GONE — `nextcloud-notify-push` now mounts `/var/www/html`
  `rw=false` — and the sweep under the real property is 26/26 with 0 instances.
  **The class is clean; the gate is not.**
- **C17 still broken**, both hosts, unchanged: every `Last checked` /
  `Next check after` in the repo is a comment, zero assertions. Root reads
  `Last checked Sun Aug 30 17:28:54 2026`, which is to the second the start of
  boot -2. Not re-proposed.
- **C11 is derived in form but has no floor**: 9 of 29 services declare `user:`
  and the assertion is emitted per declaration, so dropping a declaration removes
  its own check. `socket-proxy` (root) and `collabora` (1001) already sit
  unasserted. This is C83 applied to a gate.
- **C19 holds, but the register's row overstates it.** Positive control on the
  homelab: `[ -z "$(systemctl --failed … 2>/dev/null)" ]` exits 0 in the healthy
  case, in the `--machine=doesnotexist` case, AND with the binary absent. It is
  rescued by six neighbouring assertions that also go through systemd —
  composition, not assertion.

### Verified fixed, and not re-reported

- **C02's remedy is deployed and confirmed by three independent agents.**
  `offsite-health.yaml:77` now carries `[ -z "$(systemctl --failed …)" ]`, and
  `stdout: []` appears **zero times in the 227-251 deployed assertions across
  both hosts**. The vacuous form is gone from the estate.
- **13 of 14 corrections from 2026-09-03/04 verified GONE against the running
  system**, not against git: C78's restore table re-derived on today's snapshot
  (six `--include` paths, six matches), `DOCKER-USER` carrying exactly the eight
  rules the README claims, `logtimezone = UTC` under `[vaultwarden]` and nowhere
  else, the C81 gate clean over 112/112 `ansible/*.yml` with pre-commit
  installed. The exception is harmless and self-converging:
  `/boot/firmware/config.txt` on the homelab still carries em-dash markers
  because the `base` role has not run since; the repo fix exists.
- **C35 re-verified on CONTENT**: 15/15 push monitors carry a live measured
  message, 0 empty, 0 constant. The empty case is provably reachable in that
  database — 55 empty UP heartbeats across 5 monitors between 2026-06-06 and
  2026-07-19, none since.
- **C45's coverage hole is fixed** (both stragglers emit the marker) and it is
  **still not derived**. Unchanged verdict.
- **C15 holds and already fails closed on an empty `pgrep`** — the one gate in
  the estate written against this run's key before it had a name.
- **C10 holds and is the only gate carrying an explicit anti-vacuity floor.**

### Rejected from the agents, and why

- **`services`' "empty datadir, healthy service"** died on measurement: all 61
  bind sources sit under the single `/mnt/data` mount, so an independently empty
  datadir is not reachable. 2 empty by design, 0 unexpected.
- **`observability`'s three leads** did not survive: the absent dumps directory,
  monitor 22's lost `deep check` phrase, and Forgejo's healthz body.
- **`security`'s near-headline was killed by its own control.** `fail2ban-regex`
  in FILE mode reported zero date-template hits over 4 892 Nextcloud lines, which
  looked like a dead jail; a real line from that same file, re-tested singly,
  returns one hit. **New instrument trap: file-mode date-hit counting in
  `fail2ban-regex` is unusable.**
- **Immich's header-only dump size is inferred, not measured**, and the agent
  said so unprompted rather than quoting a number it had not taken.
- **`services`' and `project-manager`'s mint proposals** were merged into C83
  rather than counted separately.

### Register corrections

- **C53's row says "1 flush point"; there are two explicit plus the implicit
  end-of-play in each play.** Found while sweeping C82.
- **C21's row is stale a THIRD time, on a different word.** The `copy:` has no
  bound (correct, re-verified), but the row names a *"retention monitor"* that
  does not exist; the gate is the unbounded `copy` plus the `Offsite backup`
  push monitor.
- **C18's derivation claim is TRUE** — 19 checks generated by two Jinja loops
  over the group_vars lists, TAP plan line = 19 — but its property says "absent,
  stale, or **empty**" and the gate does not assert empty. The row overstates
  itself by one word, and that word is this run's key.
- **The `sshd` jail's `journalmatch` is half-dead on both hosts**:
  `_SYSTEMD_UNIT=sshd.service` is `not-found` under Ubuntu 24.04, so the jail
  survives only on `_COMM=sshd`, which OpenSSH 9.8 renames to `sshd-session`.
  Latent; it would report 0 bans forever while looking healthy. Recorded here
  rather than as a C83 instance because the mechanism is upstream naming, not a
  missing floor.

## The run of 2026-09-03 — the key was `representation`, and it was invented

The register had recorded that no named dimension was left. This key was
invented to fill that gap: **for every value that crosses a boundary between two
components, in what encoding does the producer write it, in what encoding does
the consumer read it, and what detects the mismatch?** `time` asked *when*,
`order` *in what sequence*, `identity` *who*, `scale` *how much*, `authority`
*on whose authority*; none had ever asked *in what*.

Three already-paid facts were the tell that the register had no word for it: the
Nextcloud/Redis outage of 2026-09-01 (a password with special characters
concatenated into a session URL), the `docker logs --since` timezone trap, and
C03's own live instance — `?immutable=1` against `?mode=ro`, which is a
representation defect wearing a validation class's clothes.

**It minted 4** — against 3 for `authority`, 7 for `scale`, 5 for `time`, 11 for
`order` and 12 for `identity`. Six mint proposals came back and four agents each
numbered theirs C77; the arbitration is below, because an unmerged mint list
inflates the counter and hides the convergence, which is the run's best evidence.

### Closed by enumeration — 2, and both were the ones that mattered

| ID | Property | Outcome |
|-----|----------------------------------------------|--------------------------------------------|
| C03 | A validation whose instrument answers a different question from the one its comment claims | **ENUMERATED 107/107, 99 true / 8 false — and the cardinal in this file was wrong for the fourth time.** 107, not 104: 21 shell artefacts + 86 `exec:` blocks. The 21st, `ansible/roles/storage/files/homelab-luks-header-backup`, carries a shebang and no extension, so every `*.sh` sweep in this register's history has missed it. The shell half was swept at **198 guard sites** rather than 21 files, 193 of them true. This class was open for nineteen days across seven runs; it is the one the founding defect of this skill belongs to |
| C75 | An authority held by a principal that the mechanism meant to govern it does not know exists | **ENUMERATED N=18, 18/18, 37 principals read, 0 live instances.** 18 of 29 containers hold their own account table. The "Ansible believes it governs, with no effect" axis is empty: Miniflux's repair is proven by its own log (`Skipping admin user creation`, last login 09-03) and the only other candidate matches its deployed value. Five populations with no claimed governance are recorded so they are not re-sampled: 6 Nextcloud app passwords (2 dormant, not revoked by a password change), 4 image-created MariaDB accounts, calibre-web's inert `Guest`, the 4 wg-easy peers, and `immich-redis` on `nopass` (already C56) |

### Minted — 4, after arbitration of 6 proposals

**Three agents proposed the same class and did not know it.** `security` wrote
"a secret written into its consumer's grammar with no escaping, alphabet
unconstrained"; `ansible-deploy` wrote "a value rendered into a consumer whose
grammar gives meaning to some of its characters, with no escaping and no shape
assertion"; `services` wrote "a value composed in a syntax where a character of
its own alphabet is a delimiter". Three routes, one property. They are merged as
C77, and the convergence is stronger evidence than any of the three alone.

**Two more merged for the same reason.** `network` found the same set of 18
service names enumerated by hand in four machine-readable grammars with nothing
comparing the copies; `backup` found a set defined by *subtraction* at the
producer and by *enumeration* at the consumer, with nothing comparing the two.
Both are one property: a set with two or more independent definitions and no
reconciliation. They are merged as C78, and that merge is what explains the
run's most expensive finding and C14's blind spot with a single sentence.

| ID | Property | Space swept | State |
|-----|--------------------------------------------------|-----------------|------------|
| C77 | A value rendered into a consumer whose grammar gives meaning to characters of the value's own alphabet, with no escaping and no constraint on the alphabet | secret slice 37/37, 3 defects | ENUMERATED on the secret slice; non-secret slice **closed by decision** |
| C78 | A set of which two or more components each hold their own definition, in different grammars, with nothing comparing the definitions | 4/4 name grammars (18/18/18, Kuma 15/18) + 21/21 restore expressions against 13 exclude patterns | ENUMERATED |
| C79 | A statement recording a deliberate non-action, which survives the reversal of that decision | **13/13** | ENUMERATED |
| C80 | A timestamp crossing a boundary without its timezone | **26/26** | ENUMERATED |

### C81, minted and GATED the next evening by the deploy itself

| ID | Property | Gate |
|-----|------------------------------------------------------|--------------------------------------------------------|
| C81 | A byte written into a file whose consumer reads it back through a NARROWER encoding than the producer's | `ops/check-ascii-system-files.py`, in pre-commit. **Made to fail on purpose on the three live markers before they were changed**, and made to fail again on a deliberately re-introduced em dash after they were fixed — both directions, which is what the C58 lesson asks for |

Distinct from C77, and the difference is the useful part. C77 is about a
character the consumer's GRAMMAR gives meaning to — a `$` in a shell source, a
delimiter in a DSN. C81 is about a byte the consumer's CODEC cannot represent at
all, whatever it means. `ufw` rewrites `/etc/ufw/after.rules` line by line
through `os.write(fd, bytes(out, 'ascii'))`, so one em dash in a blockinfile
marker made the whole security role unrunnable — at the fourth task, before it
could reach a single rule.

The gate's two learned boundaries are what make it derived rather than a
denylist, and both were measured rather than assumed:

- **`state: absent` names a marker to FIND, not one to write.** A check that
  forbade that would forbid its own remedy.
- **A ufw RULE COMMENT is hex-encoded** into `user.rules`
  (`comment=426974...c2b5...`), so any byte survives there by construction. The
  live `µTP/DHT` comment is safe and must not be "fixed". Verified on the host:
  no rule file contains a raw non-ASCII byte.

### How the three closed, the same night they were minted

The operator's instruction was to do whatever avoided another pass. Two closed
by sweeping, because their spaces turned out to be cheap once stated; one closed
by arbitration, because its remaining half is the kind of unbounded hunt this
register has twice recorded as not worth a run.

- **C79 — 13/13, one false, and it is the one that was fixed.** The space is
  every statement in `docs/` and `knowledge/` recording a deliberate
  non-action; a single grep on the phrasings bounds it. Twelve still hold, each
  checked against the machine rather than against the repository: 80/443 still
  not forwarded (probed from outside with a known-open control), `NET_RAW` still
  absent from netdata's caps, still exactly one socket-proxy, still no wildcard
  in `acme.json`, and Pi-hole's log genuinely unpersisted — 14.7 MB inside the
  container's writable layer, no bind mount, no tmpfs, exactly as its page says.
  The thirteenth was the security README's claim that `DOCKER-USER` is empty.
- **C80 — 26/26, one instance, fixed.** The space is every site where one
  component writes a timestamp another parses: 26 across both hosts' scripts and
  specs. **Fourteen are `date +%s`** — epoch, so the question cannot arise — and
  of the twelve real parse sites, eleven carry an explicit offset or an epoch:
  `docker logs --since "$started"` is fed the `Z`-suffixed `StartedAt`, and both
  `journalctl --since` calls use the `@epoch` form. The twelfth was fail2ban
  reading Vaultwarden's naked UTC log as local time. **The sweep is the useful
  half of this class**, not the instance: it shows the codebase had already
  converged on the two safe forms everywhere it wrote them deliberately.
- **C77 — the secret slice is enumerated, the rest is closed by decision.**
  37/37 interpolation sites, 3 defects, 1 live and fixed. The non-secret slice is
  a finite set of template sites but sweeping it means reading every Jinja
  interpolation in the tree against its consumer's grammar, for a class whose
  only demonstrated cost has been in secrets. That is C66's tail wearing new
  clothes, and it is closed the way that one was. **The fact that makes this
  defensible is also the one that makes it uncomfortable**: `| quote` and
  `| urlencode` appear zero times in the entire tree, so nothing prevents the
  next instance — only the password generator's undocumented alphabet does.

### C78 is the run's headline, and it lands on the disaster-recovery path

`knowledge/runbooks/restore-from-backup.md:70-73` gives the generic recipe
`restic restore latest --target / --include /mnt/data/services/<service>`. Since
2026-08-31 the live datadirs are excluded from the source set. Verified on
tonight's snapshot `9e99f3fa` with `restic ls` on the local repository:

    /mnt/data/services/miniflux                 <- the directory, and nothing else
    /mnt/data/services/nextcloud
    /mnt/data/services/nextcloud/data           <- no db
    /mnt/data/backups/dumps/{forgejo,miniflux,nextcloud,uptime-kuma,vaultwarden}

**Nothing is lost — the dumps are in the snapshot and the backup is complete.**
What is wrong is the procedure: for Miniflux, whose service directory holds only
`db`, that command restores an empty directory **and exits 0**. For Nextcloud and
Immich it restores the files without the database, silently producing an
inconsistent pair.

The sharp part is that `resticprofile.yaml` states the safety rule that should
have caught it, in its own comment: *"exclude nothing that a documented restore
procedure reads […] `restore-from-backup.md` already restores all of them from
the dump — each of its procedures resets the datadir."* The rule was checked
against the per-service procedures and not against the generic one in the same
file. `78372e1` touched exactly one file.

### Broken gates found on 2026-09-03 — red tests, not audit results

- **C02** (a failed unit on the offsite host). `/etc/goss/offsite-health.yaml:68-71`
  is `exec: systemctl --failed --no-legend --plain` with `exit-status: 0` and
  `stdout: []`. `systemctl` returns 0 whether the list is empty or not — control
  taken on the host, `list-units --state=active` prints **433 lines with exit=0**
  — and `stdout: []` emits no assertion at all. The check is vacuous. The homelab
  has the correct form at `units.yaml:88`, `[ -z "$(systemctl --failed …)" ]`,
  which turns the output into an exit code. **The right pattern exists, on one of
  the two hosts.** The offsite Pi, with no physical access and probed weekly, has
  no net under failed units.
- **C16** (a read-write bind mount its container cannot create files in).
  `nextcloud-notify-push` mounts `/var/www/html` rw, runs as uid 0 with
  `cap_drop: ALL` and only `CAP_DAC_READ_SEARCH`. Measured with a positive
  control at the same uid: `HTML_NOT_WRITABLE` against `TMP_WRITABLE`. The
  deployed assertion cannot see it — its predicate is `owner == OPERATOR_UID`, a
  proxy for the property rather than the property. Full sweep under the property:
  27/27 rw mounts, this one case.
- **C17** (a filesystem never checked). Still broken, and **the model written
  into the gate is wrong**: the initramfs clock is not frozen at one date, it is
  late by a variable amount, and `e2fsck` in preen mode branches at 24 h. Both
  branches observed the same evening, one per host: homelab, skew 21 h 28 min,
  "in the future … by less than a day", no rewrite; offsite, skew ~37 days,
  **`FIXED.`**, superblock rewritten. The loop is intermittent with a measurable
  margin — the homelab escaped it by **2 h 32 min**. Its "good" `Last checked
  Aug 30 17:28:54` is, to the second, the start of boot -2 (`journalctl
  --list-boots`): a boot instant, not a check instant. `Last checked` /
  `Next check after`: **zero assertions in the entire repository.**
- **C26** (a credential reaching a command line). `ansible/roles/claude-code/tasks/vault.yml:69`
  puts `pass={{ rclone_webdav_pass }}` in the argv of an `ansible.builtin.command`,
  on a `/proc` with no `hidepid`, while the sibling task **eleven lines above**
  passes the same value through `environment:`. `no_log: true` hides it from
  Ansible's output, not from `/proc` — false reassurance. Its guard opens instead
  of closing: `failed_when: false` plus `default('')` means a failed probe makes
  `'REMOTE_MATCH' not in ''` true, so the task runs. **Two agents disagreed here
  and the disagreement was the finding**: `security` swept the property with `ps`
  on both hosts plus every `compose.yaml` healthcheck and correctly found zero
  live instances, because a process that only exists during a deploy cannot be
  seen at audit time.

### Downgraded from GATED — 2, for the reason that already cost C02, C13 and C26

| ID | Property | Why it is not a gate |
|-----|----------------------------------------------|--------------------------------------------|
| C12 | A rotated secret a consumer never receives | **STALE ROW, kept only as history: "No live assertion at all" has been FALSE since #333.** Read the ENUMERATED row of 2026-09-20 |
| C20 | A secret that a deploy reports as rotated without rotating it | **Cardinal corrected 2026-09-19 (second run): the space is 43 by VALUE, not 16 secret files — 16, 15 and 59 were three different bounds and 59 is not reproducible.** As written then: 4 hand-written probes over a space of 16 secret files. A list of four is not a gate |

### Also verified, and worth not re-deriving

- **C21's row in the GATED table is stale, again.** The time-window filter it
  describes no longer exists: `copy:` carries no bound and every snapshot is
  re-offered nightly (31 local / 81 offsite, no gaps). The class holds; the
  description does not.
- **C15 holds, and its space was widened rather than re-swept.** Three surfaces
  (process, unit, alternative write path), 3/3: `--append-only` on both the live
  cmdline and `ExecStart`, and the surface that would have voided the argument —
  a private key on the main host, or an `authorized_keys` under the offsite root
  — **does not exist**.
- **C18 holds and is genuinely derived**, 19 checks re-derived from the two
  group_vars lists. It belongs in the GATED header count, which omitted it.
- **The two dated predictions left by the 2026-08-31 run are closed, pre-empted.**
  `4685e74` bounded both windows on 08-31 19:23 and is deployed on both hosts
  (26 h and 8 d caps, `timeout: 60000`). The 09-01 posture run passed without
  overrun.
- **C47's count is confirmed at 2/29 and its instrument corrected**: `SigCgt`
  alone gives 6; `s6-svscan` (x2) and `tini` (x2) handle SIGTERM through
  `SigBlk`/signalfd. **C40's "24 at the 10 s default, not 25" is a
  configuration count only** — it comes from `Config.StopTimeout` and not from
  observed kills. The agent disclosed this itself: its cross-check against the
  daemon log (`failed to exit within … — using the force`), which this register
  names as the correct instrument for C40, overran 120 s under the fleet's load
  and was killed without producing anything. It was deliberately not retried,
  rule 6 outranking a cross-check the conclusion did not depend on. **The
  "how many were actually force-killed" axis is still the 2026-08-30 sweep,
  8 instances, and has not been refreshed.**
- **C11 intact, 9/9. C41 holds and is genuinely derived** (the `type='push'` set,
  each monitor's own `interval` as the window, starvation guard at 10/15).
  **C35 swept 15/15 with zero constants. C45 must stay ENUMERATED**: the 10 sites
  emit the marker, but nothing derives the set of emitters.

### One disclosure, made unprompted by the agent that caused it

`services` reports that the cleartext value of Nextcloud's Redis `save_path`
transited its context — its own redaction filtered `auth[]=` and not `auth=`. The
value was not written anywhere and was not transmitted to anything. It is
recorded here for the same reason last run's rule-5 violation was: an audit that
handles secrets has to say when it mishandles one.

## The run of 2026-09-02 — the key was `authority`, and it was invented

The register had recorded that no named dimension was left and that the next key
would have to be invented. This one was: **for every fact the machine acts on,
how many places state it, which one binds when they diverge, and what detects the
divergence?** `time` asked *when*, `order` *in what sequence*, `identity` *who*,
`scale` *how much*; none had ever asked *on whose authority*. C13 ("an
environment value shadowed by a persisted config file") and C27 ("a deployed
artefact differing from the repo") were the tell: the register had words for two
narrow cases of the dimension and none for the general one.

**It minted 3 against `scale`'s 7, `time`'s 5, `order`'s 11 and `identity`'s 12.**
The decay is real and this is the first key to produce a single-digit yield.

### Closed by enumeration — 2

| ID | Property | Outcome |
|-----|----------------------------------------------|--------------------------------------------|
| C46 | A supervisor's log that declares an act it did not perform | **ENUMERATED 34/34, 0 confirmed instances — and the blocker was a stale cardinal in this file, not a real gap.** The "6 mute supervisors" did not exist: re-derivation found **4** candidates, of which **3 were merely mis-searched** — their claims are durably corroborated under the systemd units' own transition logs rather than under their own tag. Verified live: `journalctl -t homelab-unlock` is indeed empty (the register's observation, reproduced as a negative control), while `mnt-data.mount` carries the same events with real timestamps. The 4th closes by source argument (`set -euo pipefail` + immediate `$rc` capture makes divergence unreachable). **The four `logger -t` lines this file called for were never needed** |
| C73 | A documented duration extrapolated from an unrepresentative sample | **ENUMERATED N=20, 20/20** — 11 correctly derived, 2 extrapolated across 3 live sites, **6 of untraceable origin**, and that third bucket's size is itself the result. Two further instances of its own defect: `ADR-021-collabora-online.md:220` and `homelab-stack-startup.sh:157-158` still cite warm-boot figures (~80 s/~90 s) that `compose.yaml`'s own comments already say are 6-12x low (real: 7 min 49 s - 16 min 33 s). **Note the arbitration**: `project-manager` also reported C73 closed, on the grounds that its single instance had been fixed by `241d504`. That closes the instance, not the class. Same verdict, one valid reason |

### Closed by the operator's decision — 2

| ID | Property | Decision |
|-----|----------------------------------------------|--------------------------------------------|
| C57 | An authentication failure recorded without an identity | `security` moved it — space independently re-derived at **N≈21** (the prior 24 was an aggregate whose item list was never preserved), 4 more decided by upstream source reading, 3 known instances re-confirmed. The remainder needs a **deliberate-failure drill**, and the operator declined it on 2026-09-02. The class is therefore closed by decision rather than left open to be re-sampled |
| C66 | A correction applied to the instance that revealed it, whose siblings were never enumerated | Cut in two, on `project-manager`'s proposal and the operator's approval. The **historical half is ENUMERATED and closed for good** (128/128 + 188/188): `git log` structurally cannot see hand-fixes, so re-sweeping it forever asks an instrument to do what it cannot. The **unbounded tail is DECLINED**. What survives is not a class but a method — compare live populations against what is written, which bounds without history, and which is exactly this run's key. It produced three instances that evening by that route alone |

### Minted — 3

| ID | Property | Space swept | State |
|-----|--------------------------------------------------|-----------------|------------|
| C74 | A rule whose decision is pre-empted by another component acting earlier on the same object, with nothing detecting the pre-emption | 7 UFW inbound rules, 7/7 | ENUMERATED, **fix shipped** |
| C75 | An authority held by a principal the mechanism meant to govern it does not know exists | not swept — see the OPEN table | **OPEN** |
| C76 | A verification whose expiry is reported through the same channel, and in the same terms, as the condition it watches | 197 homelab + 43 offsite assertions | ENUMERATED, no action requested |

### C74 is the run's headline, and three agents reached it independently

`network` and `security` proposed it from different routes — chain order, and
Pi-hole's `FTLCONF_dns_listeningMode: all` — and the main session verified it on
the chains. **`FORWARD` places `DOCKER-USER` at 1 and `DOCKER-FORWARD` at 2; the
six `ufw-*-forward` chains only start at 3. `DOCKER-USER` is empty.** The `DOCKER`
chain then holds `ACCEPT udp 0.0.0.0/0 -> 172.19.0.2 dpt:53` with no source
filter, and that ACCEPT terminates the traversal.

Meanwhile ufw displayed `53 ALLOW IN 192.168.1.0/24 # DNS (Pi-hole, LAN only)` —
a rule on the INPUT path, which a packet bound for a container never takes.
**Six of the seven inbound rules were in that position; only one had its written
intent violated**, the other five saying "Anywhere" and being honest. No live
exposure: probed from the offsite uplink with a known-open control (51413 open,
80/443/53 closed). **The protection came entirely from the router, and nothing on
the host knew it.**

Note the shape: C74 is the **inverse** of C70 ("a rule inert today that would be
a fault if enforced"). Here, a rule believed to be enforced that is inert. That
is what made it a mint rather than an instance.

### The load confound, caught by the main session

`observability` reported two assertions timing out during the audit
(`container-health-sample-floor-reachable`,
`only-socket-proxy-mounts-the-docker-socket`, both on the 10 s default).
**Re-measured at near-idle, two passes: 27.68 s and 24.55 s for the whole spec,
zero `not ok`, zero timeouts.** They do not time out normally — they timed out
under eight concurrent agents, which is instrument trap #1 of `settled.md`
reproduced exactly. What survives is sharper than either version: these
assertions are **load-sensitive**, and the machine demonstrably has real
contention episodes. That is C76, and it is why the three "went red for being
slow" commits of that week were treating one class one instance at a time.

### One agent broke the read-only rule

`security` provoked a real authentication failure against the offsite
`rest-server` while investigating C57, and disclosed it unprompted. Impact nil —
nothing persisted, the append-only repository untouched. Recorded because it is
precisely the act the register classes as out of scope, and because the operator
declined that same drill hours later.

## Closed by the run of 2026-08-31 — 5

| ID | Property | Outcome |
|-----|----------------------------------------------|--------------------------------------------|
| C05 | Something a reader would reasonably assume the posture check asserts, and which it does not | **ENUMERATED, and the cardinal was wrong: N=104, not 53.** Swept 104/104 on both hosts under a stated criterion — one proposition per verifiable predicate rather than one per bullet, so the disagreement with the previous count is explicit rather than silent. **7 FALSE, and of the 97 true, 37 asserted / 60 unasserted.** Six of the seven false are drifted counts and **in three the deployed posture is STRONGER than the prose** — 16 zero-capability containers where the document claims 15, and so on. No exposure among them. The load-bearing unasserted statements are unchanged in nature: SSH key-only (the only access path, ~6 lines per host against `sudo sshd -T`) and 80/443 not forwarded (~12 lines, endpoint derived from the offsite's own `wg0.conf`, both positive controls inside the assertion). **Correction to this file: `unattended-upgrades` IS asserted on both hosts**, at the outcome level — both health scripts alarm if security updates stay pending past 48 h |
| C56 | An authorization or an attribution decided after the caller's identity has already been lost | **CLOSED on both halves, and both cardinals are derived from the running machine rather than from compose.** Network half **19/19, 6 instances** (4 UFW source rules, 1 scoped DNAT, 2 deciding middlewares, 0 of 21 routers with their own auth, 2 attribution fields, 1 Pi-hole client rule, 2 shared-secret logins, 4 WG peers, 3 jails). Container half **32/32, 5 instances** — the space being every non-loopback listening socket another container can reach, enumerated with `ss` inside each network namespace. 4 endpoints authorize with no caller identity at all; 1 shares a principal across three callers. The socket proxy's grant set was measured rather than argued: **103 069 requests over 22 h**, netdata 92.9 %, dozzle 3.9 %, traefik 0.6 %, and no caller uses more than 3 of the 5 grants |
| C58 | A control all of whose assertions test the direction that permits | **CLOSED 14/14, and it closed by REFUTING its own blocking premise**, which is worth more than the count. 3 permitting-only (the three already on file — there is no fourth), 5 refusing-only, 5 bidirectional, 1 presence-only. The register recorded the refusing direction as "unobservable from any address on this machine". **It is observable**: `curl --interface 172.20.0.1 --resolve ...` returns **403** against a **200** positive control, reproduced on three routers. Every other host address fails as a control because POSTROUTING launders 172.17/172.19 into the allowlisted 172.18.0.1, and `homelab_socketproxy` escapes only because it is `internal: true` — so an assertion must pin `%{local_ip}` and treat 000 as control failure rather than as a pass |
| C60 | A copy whose scope is a list of fields facing a third party's schema | **ENUMERATED 12/12, 1 instance, and the register's own numbers were wrong.** Live: **21 of 114 columns**, not 22 of 118. `dns_resolve_server` on the Pi-hole DNS monitor and the Transmission basic-auth triple are the omissions that carry intent. **The register also overstated the impact and that is corrected**: nothing restores from the JSON — the documented path is the whole-file `.sqlite3` — so the cost is not a silently wrong restore but **review blindness in the very instrument used to review monitoring**, which is live today |
| C62 | An announced exclusion that the mechanism does not enforce | **CLOSED 21/21** (25 candidates, 4 rejected as capability statements rather than exclusions), **2 instances, the same sentence at two sites**. **The register's description of the mechanism was wrong**: the guard is NOT read only by `homelab-unlock` and itself — `AssertPathExists=!/run/homelab/unlock-fsck-in-progress` is deployed on `mnt-data.mount`, so every systemd path is blocked. The real gap is `mount(8)`, which nothing consults. The worse of the two sites prints "nothing else can mount it either" immediately after `e2fsck` has declined to repair a damaged filesystem. **The fix on file — "one sentence" — was wrong twice over**: it is a reworded sentence *or* a real interlock, and the choice is the operator's |

## Minted by the run of 2026-08-31 — 7, after arbitration of 11 proposals

**Four agents proposed a class numbered C67 and they were not the same class;
three of those four were.** The arbitration below is part of the run's output,
because an unmerged mint list inflates the counter and hides the convergence.

| ID | Property | Space swept | State |
|-----|--------------------------------------------------|-----------------|------------|
| C67 | A verification whose deadline was sized against an input that was empty or small when it was measured, and which grows without bound | 13 constructs across both hosts' verification layer, 13/13 | ENUMERATED, **not gated** |
| C68 | A store whose declared retention is overridden by a limit that is not the one written down | 7 stores + 31 container log rings | ENUMERATED |
| C69 | A periodic control whose own runtime is a fraction of its period that nothing measures | 16 periodic controls, 16/16 | ENUMERATED |
| C70 | A rule that is inert today and would be a fault if it were enforced | 19 UFW rules, 19/19 | ENUMERATED |
| C71 | A recurring cost driven by rewrite rate rather than by information carried | 22 backup subtrees, 22/22 | ENUMERATED |
| C72 | A remedy that enlarges a window, and therefore takes effect only after a delay equal to the enlargement | 2 windows enlarged since 08-29 | ENUMERATED |
| C73 | A documented duration extrapolated from an unrepresentative sample | 1 instance, space unbounded | **OPEN** |

**C67 absorbed three independent proposals** — `ansible-deploy`'s "cost grows
against a fixed budget", `observability`'s "timeout sized while its store was
near-empty" and `backup`'s "deadline sized against an input that had just been
emptied". Three agents, three routes, one class. **C69 was kept separate on
purpose**: it is not about a deadline being crossed but about a runtime nothing
measures at all, and its instance (`homelab-health` going 6 s to 24 s at the
08-30 reboot and holding, load controlled for) would be invisible to C67.

**C68 absorbed two** — `services`' "two limits where the binding one is not the
one written down" and `observability`'s "declared retention silently overridden
by a size cap" — and `system`'s "retention window whose binding limit is an
unrelated routine event" is its third face: no container on the host is older
than 4.96 days, so **29 of 29 log rings have never reached their configured
size**, including the 200 MB ring sized at ~32 days five days earlier whose log
is 19 hours old.

### C67's instance is the run's headline, and the gate predicted its own failure

`no-kuma-report-was-lost-in-silence` — written on 2026-08-30 to close C45, the
defect that created this skill — scans the journal from Kuma's start, and Kuma's
uptime is what bounds the window. Measured by the main session at idle:

    6 h  -> 5.63 s      12 h -> 6.54 s
    25 h -> 20.04 s     48 h -> 52.90 s      against a 45 s budget

`backup` measured it under the load the spec itself creates: **34.5 / 35.9 /
40.6 s of 45 s at one day of Kuma uptime.** The spec's comment claims an 11x
margin; **it is 1.2x**. Its twin `offsite-no-report-was-lost-in-silence`
declares no `timeout:` at all and runs against goss's 10 s default, proven
empirically (`sleep 11` -> `timed out (10s)`).

**The comment on the assertion states the failure and the remedy in advance:**
*"The scan grows with the window, which is bounded by Kuma's uptime rather than
by anything here. If this ever times out again, that is the reason, and the fix
is to bound the window — not to raise the number."* Written 2026-08-30, true
2026-08-31.

When it trips, goss reports a timeout as `not ok`, indistinguishable from a
failed assertion — so **the gate built to catch "a report was lost" will
announce that reports were lost, for having got slow.** `backup` left two dated,
falsifiable predictions: the posture run of 2026-09-01 11:09 and the offsite run
of 2026-09-06 08:00.

**A compounding term nobody had connected, found in halves by two agents.**
C39's remedy raised the journal cap 500M -> 1500M on 2026-08-30 to lengthen
RETENTION. This gate's cost is linear in journal bytes scanned. The fix for one
class is the load term of another. That interaction is C72.

### The `-p err` remedy was REJECTED by the main session, and the rejection matters more than the finding

`backup` offered a 22x speedup: the same query with `-p err` falls from 34.5 s
to 1.56 s, reproduced by the main session at 20.59 s -> 1.57 s.

**It would make the gate blind.** The marker is emitted as `echo
"kuma-push-failed: ..." >&2` at 10 of its 11 sites; the units run
`StandardError=inherit` with `SyslogLevel=6`; and the positive control is
decisive — a line that is unmistakably script stderr, `curl: (28) Operation
timed out after 10001 milliseconds`, sits in the journal at **priority 6**. So
an empty `-p err` sweep over 45 days is not evidence that no push has failed; it
is evidence that the filter cannot see the marker.

Applying it would have made the assertion 22x faster and **permanently,
silently green** — a C03 instance installed inside the gate for the class that
created this skill, and one that would pass review because the check keeps
saying `ok`. **If a priority filter is ever wanted, the marker must be EMITTED
at that priority first, in the same change.**

### Two agents disagreed, and the disagreement was the finding

- `project-manager`: the restore-time claim is fine — the repository is 352 GiB
  against 343 documented, +2.6 %, so "around 7 hours" still holds.
- `backup`: "around 7 hours" was extrapolated from a 243 MiB / 18 s sample; the
  true range is 7.4-33 h.

Not a contradiction. They tested different axes: one asked whether the number had
DRIFTED, the other whether it had ever been DERIVED. The second is the deeper
question and its answer stands as C73. **The first is correct on the question it
asked and must not be reported as clearing the claim** — which is precisely how
a negative result becomes a false all-clear.

### Rejected by the main session — one agent claim, re-measured

`network` asked to overturn `settled.md`'s retraction *"VPN clients appear in the
clear as 10.8.0.x"*, concluding that fail2ban's jails cannot ban a VPN client.
Its evidence was a correlation: one device seen as `10.8.0.2` to Pi-hole and
`172.18.0.1` to Navidrome one second apart.

Measured directly on the live access log instead: the 22 993 laundered requests
are **Uptime Kuma's own probes** — `/healthcheck`, `/ping`, `/alive`,
`/healthz`, `/status.php` — exactly as `settled.md` recorded, and **14 requests
arrive with `10.8.0.x` preserved**, an address in no ignored range. The
correlation had no base-rate control: Kuma probes 34 monitors on ~60 s cycles,
so a one-second coincidence is the expected case. **Rejected.** What survives is
narrower: both paths exist and nothing establishes which one a given request
takes.

## Reopened and broken gates found on 2026-08-31 — red tests, not audit results

- **C38** (a container log growing without rotation). **REOPENED, and it is the
  most immediately actionable thing the run found.**
  `/opt/homelab/configs/pihole/logrotate` is owned `marc-gavanier:docker`, so
  logrotate refuses the entire file — *"file owner is wrong"*, nightly. The
  `copytruncate` fix of 2026-08-25 has therefore **never been in effect**, and it
  silently killed the two rules in that file that WERE working. `pihole.log` is
  23.8 MiB with no rotated copy, growing **14.4 MB/day**. One word — `owner: root`
  on a single Ansible task. This is also a C49 instance: a hardening applied to
  an artefact whose producer regenerates it.
- **C63** (a recovery destination that cannot hold what it restores). Two live
  instances, and they are the same shape found independently by two agents.
  `restore-from-backup.md` restores Immich's dump directory — **595 MiB
  measured, 7 files of 89 MiB** — into `/tmp`, which is `tmpfs size=1048576k`.
  It fits today with 429 MiB of headroom and fails at roughly 16 000 assets
  against today's 9 489. **State that horizon in assets, never in dates**: the
  dumps grew 13.5 KB in six days, so a calendar projection gives decades and is
  meaningless. Separately, `offsite-backup.md:189` restores ~343 GiB into the
  offsite root's 221 GiB free, on the path taken when the homelab is lost.
- **C06** (`start_period` never measured) and **C29** (a construct that disables
  a feature silently) were not re-swept tonight. C29's calibration was corrected
  in `settled.md` on 2026-08-31: the redactor's PID 1 is `sh`, not the pipeline,
  so if `tail` dies the container stays `Up` with a vacuous `pgrep` healthcheck.
  It is an exposure, not a tidy-up.

## The run of 2026-08-30 (night) — the key was `identity`

Four of the six OPEN classes closed, twelve minted. The key asked **who is
acting**, as opposed to what is running, and it paid the way `time` and `order`
did before it — which is now three consecutive confirmations that the mint rate
tracks unused dimensions rather than a rotting system.

### Closed by enumeration — 4

| ID | Property | Outcome |
|-----|----------------------------------------------|--------------------------------------------|
| C50 | A liveness probe whose subject answers without the component the probe claims to prove | **CARDINALS FROZEN AT A 28-CONTAINER ESTATE — re-derive before quoting (flagged 2026-09-19, fifth run).** The Docker half is **28**, not 25: 32 running containers minus the 4 with no healthcheck (`dnsproxy`, `searxng`, `nextcloud-cron`, `nextcloud-notify-push`), which is the same 28 that C22 carries. The Kuma half (34) and the 62 total are NOT re-derived here and must not be quoted until they are — 37 monitors exist today, but how many are liveness probes in this class's sense was never re-counted. Historic text follows. ENUMERATED 62/62, ~19 instances. The cardinal was wrong: recorded as 64, it is 62 — 25 Docker healthchecks (taken from the machine, not the repo: three services inherit their `test:` from their image), **34** Kuma monitors (not 36) and 3 `wait_healthy`. Three agents swept disjoint thirds. The instances that matter are not the resolver ones this row was opened on: `pg_isready -d <db> -U <user>` returns the same output and exit 0 for a database and a role that **do not exist** (verified with a control against the real call), so the arguments are decorative on two databases; Kuma's own healthcheck greps `entryPage`, which is the FIELD NAME in `{"type":"entryPage","entryPage":null}` — and Kuma is the only container no external monitor watches; `miniflux -healthcheck auto` performs **zero** transactions over 30 probes. The suspicion worth more than its instances: if `/mnt/data` disappears while the containers run, calibre-web serves `/login`, jellyfin `Healthy`, navidrome `.`, immich `pong` — four dead services, four green probes, four routers kept |
| C51 | A procedure whose written order differs from the order the machine imposes | **ENUMERATED 80/80, 6 instances** (the 4 fixed on 08-30 plus 2). The 80th sequence was found by dropping the title index and taking the two candidates invisible to it: `sd-theft-response.md` is clean on 6 machine-verified claims, and `ops/bootstrap.sh` carries one instance — its connectivity check and its final command omit `-e homelab_ssh_port=22`, which `hosts.yml` states in writing, and `--ask-vault-pass`; proven, `ansible-inventory --host homelab` answers `Attempting to decrypt but no vault secrets found`. **The suspected instance is CONFIRMED without dropping anything**, and it is worse than an inversion: step 1 prints an unfilled `--cap-add`, whose only source is step 4, and step 4's instrument is **blind on 25 containers of 29** (24 without `getcap`, 2 without a shell). The blind set contains Collabora, and the rule "empty sweep ⇒ the flag is safe" therefore authorises the drop |
| C52 | A safety argument whose premise is a defect that has just been corrected | **ENUMERATED, bucket swept 9/9 of 151 candidate arguments, 1 confirmed instance.** `observability/handlers/main.yml` refuses `netdatacli reload-health` on the grounds — stamped **"Measured, not assumed"** — that `/run/netdata/` is empty. Measured tonight inside the container (the right namespace): `netdata.pipe` is present and `netdatacli ping` answers `pong`. The direct cost is one netdata restart per deploy instead of a reload; the value is that **a measurement stamped "measured" expired and nothing noticed**, which is the property itself. A second material: `homelab.env` is argued about as "group-readable and mounted into the containers" when it is 0600 and mounted nowhere — right decision, false reasons |
| C54 | A startup list that is neither derived from the machine nor asserted against it | **ENUMERATED 4/4.** Tier 0, wave 1, wave 2, wave 3; only the Tier 0 list is both derived (from `compose.yaml`) and asserted. Coverage 6+9+6+8 = 29 = the 29 services, no discrepancy. **The suspected instance is DISCARDED with proof**: a service no wave starts fails the goss assertions generated for it (`docker inspect <absent> | jq` -> `null`, positive control `traefik` -> `false`) — real detection, but at 24 h and under a misleading name. **1 confirmed latent instance**: the Tier 0 assertion covers one of the three `restart:` values, so an `always`/`on-failure` would pass it in both directions and short-circuit the staged startup. Measured 0 today (6 `unless-stopped`, 23 `no`, 29/29 compliant). ~10 lines turn the equality into a partition assertion and **C54 would reach GATED** |

### Minted — 12

| ID | Property | Swept | State |
|-----|--------------------------------------------------|-----------------|------------|
| C55 | A container uid that is a real login account on the host | 5/29, 4 inert, 1 assumed | ENUMERATED |
| C56 | An authorization or attribution decided after the caller's identity is lost | 3 surfaces | **OPEN** |
| C57 | An authentication failure recorded without an identity | 1 instance | **OPEN** |
| C58 | A control all of whose assertions test the permitting direction | 3 assertions | **OPEN** |
| C59 | A verification whose subject supplies its own instrument | 12/12, 1 instance | ENUMERATED |
| C60 | A copy whose scope is a field list facing a third party's schema | 1 instance | **OPEN** |
| C61 | A numeric identifier used where a name was meant | 17/17, **4 wrong** | ENUMERATED |
| C62 | An announced exclusion the mechanism does not enforce | 1 SUSPECTED | **OPEN** |
| C63 | A recovery destination that cannot hold what it restores | 13 destinations, 9 instances | ENUMERATED |
| C64 | Data whose owner is no process's identity | 27/29 clean, 2 instances | ENUMERATED |
| C65 | A mounted file whose identity no task declares | 3, cost measured zero | ENUMERATED, DECLINED candidate |
| C66 | A correction applied to the instance that revealed it, whose siblings were never enumerated | 3 instances on file | **OPEN** |

**C55's cardinal deserves its footnote, because the loose predicate is useless.**
Fourteen of the 29 containers run PID 1 as host uid 0 and one as 65534; counting
those as "a real host account" would give 15 and mean nothing. The property is a
collision with a *non-system* account, and on that reading it is 5. The sharp
instance is **Collabora**: `Config.User` 1001 with no userns remapping, so its
PID 1 runs as host uid 1001 = `claude`, the login account that carries
`claude-remote-control.service` and an rclone mount of the Nextcloud vault — and
host gid 1001 = `spi`, an unrelated group. Nothing allocated that uid; it is the
image's default. Mitigation measured: Collabora declares **no bind mount**, so
no shared write path exists today. The day someone adds one, they add it with
`claude`'s rights.

**C61 is the cheapest class on this table and the one most likely to bite.**
`gid 1000` is `gpio`, not the operator's group, which is 1003; `gid 999` is
`systemd-journal` on the homelab while `uid 999` is `rest-server` on the offsite.
`docker/.env.example` ships `PGID=1000` where the deployed value is 1003 — it
only bites on a rebuild from the example, and then it hands the containers the
`gpio` group. The offsite-restore step of `offsite-backup.md:189` ("on any
machine") would hand the Postgres datadirs to the network daemon's account.

### Broken gates — red tests, not audit results

- **C06** (`start_period` never measured). Confirmed broken on **four** points, one
  of them new: 14 declared against a header reading `THIRTEEN`; the redactor's
  30 s measured at **99 s**; it survives only by accident (30 + 3x60 = 210 s of
  tolerance); and the upstream cause as it stood then — **`traefik` declared no
  `start_period` at all** and takes 98 s to load its configuration. **CORRECTED
  2026-09-20 (eleventh run): it does now, `StartPeriod=240 s`, shipped in #308.
  This sentence was still read as current and the main session copied it into an
  agent brief as established fact before the agent measured the live container.**
- **C29** (a construct that disables a feature silently). Still broken, uncorrected
  in repo and on the machine. Calibrated: the test is
  `pgrep -f ... && [ -f .../access.log ]`, so the FILE half works; only the
  liveness half can never fail. Do not present the probe as wholly vacuous.
- **C26** (a credential reaching argv, a child, a job or a trace). **Downgraded
  GATED -> ENUMERATED.** The instance is genuinely gone (`-K -` deployed, 0
  credentials in argv across the 4 re-swept axes), but `grep -ciE
  "argv|cmdline|hidepid"` over the deployed spec returns **0**: one assertion of
  193 covers this class and it is the *trace* axis. `/proc` carries no `hidepid`.
  Same disguise that cost C02 and C13.
- **C18** (a database dump absent, stale or empty). **Downgraded GATED ->
  ENUMERATED.** Derived on one axis — a database on the list cannot escape its
  check, 19/19 verified — and **listed on the other**: nothing derives the list
  from the machine. 11 SQLite stores exist; `wireguard/wg-easy.db` is classified
  nowhere.
- **C17** (a filesystem never checked). **Red test NEGATIVE — the gate is not
  broken.** `/run/initramfs/fsck.log` is a tmpfs file written at tonight's 17:29
  boot and dated `Tue Jul 28 15:05:07 2026`: the initramfs clock is frozen,
  e2fsck runs a full check every boot and antedates the superblock. Not
  asserting `Last checked` is therefore correct. **What is real**: the offsite
  has no assertion on its root at all — three lines to copy into
  `goss-offsite-health.yaml.j2`, and C02, being derived from timers, cannot see
  it.
- **C41** re-read at the code: **genuinely derived.** Nothing to do.
- **C21**: the register's own description is **stale** — ADR-031 removed the time
  window filter and the replacement is better. 77 snapshots, one per day from
  01-08 to 30-08, no gap, `locks/` empty.

### C45 must NOT be promoted to GATED — and this is the run's headline

`no-kuma-report-was-lost-in-silence` is a careful assertion: its floor is
**derived** (the first beat Kuma itself recorded since its own start, rather than
the 434 s observed), its controls were run in both directions, and it refuses to
judge rather than pass vacuously. Its defect is **coverage**. It reads a marker
that **8 of the 10 push sites emit**. The two that do not are the two that do not
live in `/usr/local/bin/`:

    /opt/homelab/scripts/backup-notify.sh:179       || log "push failed"
    /home/claude/.local/share/feed-digest/digest.sh:133  || log "WARNING: Kuma push failed"

Both **detect** the failure — the C45 fix reached them — and neither emits the
marker. So a lost push from the **entire backup chain** is invisible to the gate
written to catch exactly that. Three independent sources reached it
(`observability`, `backup`, and the main session's own re-measurement), and the
main session's first enumeration fell into the same hole and saw only 7 sites.

**The mechanism is the scope trap**, the one this register has recorded since
2026-08-22: an enumeration scoped to a DIRECTORY (`/usr/local/bin/`,
`roles/*/templates/`) instead of to the PROPERTY. It bit the gate itself, the day
after the gate was written. One line fixes the two scripts; the class stays
ENUMERATED until the marker's emitters are derived rather than listed.

### C03 — designed, not deployed

The gate is designed and **derived**: 104 units — the 20 shell artefacts **plus 84
goss `exec:` blocks**, two of the seven instances living outside the 20 — with its
five deliberate-failure controls. Measured before being proposed: pipefail 0
defects of 20, curl 0 defects of 22 (4 derived exemptions), and the "proxy guard"
family **established not gateable** (44 flags over 63 correct sites, 70 % noise).
C03 stays OPEN until the assertion is deployed and made to fail on purpose.

---

## Settled by the run of 2026-08-30 (evening) — three of the four OPEN, and C27

| ID | Property | Outcome |
|-----|----------------------------------------------|--------------------------------------------|
| C41 | A dead-man's fuse that the restart of its own watchdog re-arms from zero | **GATED, 15/15.** The assertion is genuinely DERIVED — it selects `where m.active = 1 and m.type = 'push'`, compares each silence against that monitor's own `m.interval`, fires only on the INCONSISTENCY (silent past its window while the last beat still says UP, so a late backup cannot mute it for days), and starves loudly (`only $n active push monitor(s) with a beat — the query stopped matching`). Verified live at 358/358, and on history: 54 silences past their window with a last beat UP, against 16 with a last beat DOWN where it correctly says nothing |
| C40 | A container that begins an ordered shutdown and is killed before finishing it | **ENUMERATED — 26 of a 32-container fleet, 8 instances** ("29/29" here and at the summary row were both frozen at the 28-container estate; re-measured live 2026-09-20: 26 `<nil>`, 4 at 90, 1 at 60, 1 at 5. C40 is the EIGHTH frozen row and the sweep of seven missed it), and the sweep is worth more than the count. **This row previously asserted that the evidence "is never in its own log, only in the next startup's" — that was WRONG**, and it is why the 02:45 sweep found 4. The daemon logs it directly, and the previous instrument (crash-recovery markers in container logs) can only see databases. #288 is verified good: the four DBs drained in 7.6-9.1 s of a 30 s grace and are absent from the 17:29 list. The remaining cause is configurational — 25 containers still sit at Docker's default 10 s |
| C42 | A time-ordering mechanism that ranks by a timestamp the machine wrote before its clock was correct | **ENUMERATED 6/6, 1 confirmed instance**, the journal one, fixed and verified (skew 32 days → 35 s). One residual and one belonging to `backup`. Broke a neighbour on the way out — see C17 below |
| C27 | A deployed artefact differing from the repo | **ENUMERATED 129/129, 0 instances** (108 homelab, 21 offsite), by sha256 and by static-line containment in both directions, and on BOTH layers the reopening of 08-29 distinguished: 0 units awaiting `daemon-reload`, 15/15 container configs re-read at the 17:29 restart, 8/8 host services, 5/5 offsite. Twenty commits in a day and no drift |

## Minted by the run of 2026-08-30 (evening) — 11

Six arrived already enumerated, because the agent that minted them also swept
them. Five are in the OPEN table above.

| ID | Property | Swept | State |
|-----|--------------------------------------------------|-----------------|------------|
| C44 | A verification whose cadence cannot observe the event it guards | 13/13 timers swept; **1 instance**, not 12 — see below | ENUMERATED, remedy shipped, **not gated** |
| C45 | A reporting path that cannot report its own failure | 10/10 push sites, **8 instances** | ENUMERATED |
| C47 | A PID 1 that cannot act on the signal it is sent | 29/29, **2 instances** | ENUMERATED |
| C48 | A real dependency that nothing declares | 29 services + 18 configs, **1 instance** | ENUMERATED |
| C49 | A hardening applied to an artefact its producer regenerates | 28/28, **1 new instance** (3 prior: #189, #299, the UFW sysctl) | ENUMERATED |
| C53 | A handler whose effect is expected earlier in the play than it occurs | **41 handlers, 3 flush points** (re-counted 2026-09-19 by two runs independently; the 34/1 this row carried was frozen at 2026-08-30), **2 instances, 1 fixed** | ENUMERATED, **not gated** |

### C44's cardinal was wrong, and the error is the one this file warns about

It was recorded as **12 instances of 13**. That was a count of `homelab-*`
timers lacking `OnBootSec`, which is a *proxy* for the property, not the
property — the scope trap this register already documents from 2026-08-22:
**define the class by its property, not by the enumeration that was convenient
to run.**

Re-read against the property — *a verification whose cadence cannot observe the
event it guards* — the answer is **1**. `homelab-health` runs every five
minutes, so it observes any post-boot state on its own. `homelab-disk`,
`homelab-lynis` and the weeklies guard facts a reboot does not change. Only the
posture check both guards state that a reboot and a deploy alter, and ran on a
cadence that could see neither. **Do not carry the 12 forward as if it were
instances.**

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
deploy just queued. The repo held exactly one `meta: flush_handlers`, in
`security`. Together the two mean: **the only two occasions on which the posture
could have covered a day's changes both fell at the wrong moment — one before
the handlers, one before the reboot.** The state was in fact good; nothing in
the system established that.

**Both were fixed the same evening, in two lines** (PR #307): a
`meta: flush_handlers` before the re-assertion, and `OnBootSec=30min` on the
timer — 30 rather than 0 because `/mnt/data` is unlocked by hand and the staged
startup then takes ~9 minutes, and the script already exits 0 with
`/mnt/data locked — posture not checked` if the volume is not up. Verified on
the machine: `OnBootUSec=30min` live, and the post-flush re-assertion ran at
21:45:28 with `Result=success`, its monitor carrying a real reading rather than
a constant.

**Corrected is not gated, and the distinction is the whole point of this file.**
Nothing stops a future timer from shipping without a boot hook, or a future role
from putting a verification ahead of its own handlers. C53's SECOND instance is
untouched: `Restart Docker` still lands after the deploy role has configured the
entire stack against the old daemon, and the flush moves when it fires without
changing that ordering. The founding defect of this skill survived fifteen days
on nine scripts *after* being fixed on the tenth — which is exactly what
"corrected, not gated" costs when nobody writes it down.

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
| C01 | A documentary statement whose content contradicts the deployed artefact | **REOPENED 2026-09-20 (tenth run) — read the OPEN table, not this row. It had been CLOSED 2026-09-19 (second run), 123/123 referents, 12 contradicted — it is in NO summary table, so read this row, not a pointer. The words "see the OPEN table" stood here after C01 had left it; corrected 2026-09-20.** Previously ENUMERATED, not GATED, and the distinction is the honest part. Bounded at last: **472 machine-checkable claim occurrences across 81 files, 218 distinct referents** (121 absolute paths, 29 containers, 26 quoted thresholds, 23 units, 19 goss/alarm names). Twelve instances corrected in #284. Free prose cannot be gated; what replaces a gate is **duplication removal** — where a document lists something the machine owns, print the command that regenerates it instead. Applied three times in #284. Its **temporal slice** was swept to completion on 2026-08-29 evening — N=88 from 389 candidate lines across 63 files, 88/88, 68 exact and **20 contradicted** — and is tracked as **#293** | **What reopened it**: all 218 referents are of five machine-checkable kinds (paths, containers, thresholds, units, goss/alarm names). A claim about a THIRD PARTY'S CAPABILITY is a sixth kind and was never in the space; three instances were found on 2026-09-11 by three domains using three different instruments. **What reopened it the SECOND time**: all 81 files of its space are DOCUMENTATION files — `docs/`, `knowledge/`, then `.claude/agents/*.md` and `CLAUDE.md`. A comment in `ansible/**/*.yml`, `ops/*.sh` or `compose.yaml` is a documentary statement and was never in the space; four instances were found there on 2026-09-20 by four agents with no contact. Bounded by a FILE TYPE while the property is not — eleventh payment of that shape | **UPDATED 2026-09-20 (eleventh run): BOUNDED AT LAST — the file set is the repo's tracked files that CARRY COMMENTS: 198 files, 13 757 comment lines, 11 666 prose statements. Swept `ansible/` 176/176, `docker/` 10/10, `ops/` 156/156, `usb-tamper`+`killswitch` 121/121 CLEAN. REOPENED a THIRD time: a comment in a RENDERED file (`/etc/goss/posture.yaml`, the systemd units) has never been in any space, and 2 instances live only there. Twelfth payment of the wrong-axis shape. Read the OPEN table.**
| C02 | A control on the homelab with no counterpart on the offsite host | **ENUMERATED, not GATED** — recorded GATED by #285 on 2026-08-29 morning and downgraded the same evening. #285 gave the offsite `rest-server`, `wg-quick@wg0`, `ssh`, `fail2ban`, a `--failed` catch-all, ufw by its rules, and `offsite-wg-reresolve.timer`, and corrected its two SMART assertions. But a list of seven assertions is not a gate on the property, and the eighth instance was found the same day |
| C09 | Work a container schedules for itself, on a period no sweep window catches | **ENUMERATED 28/28**, closed 2026-08-29 evening after being named un-enumerated on 08-22 and sampled by three runs. Four axes: processes by cgroup from the host, cron files including `/etc/crontabs`, application schedulers queried in their own state, clocks. 4 containers carry an internal crond (1 inert), 11 an application scheduler, 4 databases an internal maintenance, 11 schedule nothing. **1 instance**: two Miniflux feeds of 119 reached `parsing_error_count = 3`, which excludes them from the scheduling query while leaving `disabled` false — feed 89 unpolled since 2026-08-20 and unable to recover on its own (tracked as **#294**). Also established: 25 of 28 containers run at UTC, with no job landing in the backup window |
| C03 | A validation whose instrument answers a different question from the one its comment claims | **ENUMERATED, and its space restated on 2026-08-30 (#289).** It had been scoped to *the four goss specs on both hosts* — the directory the first sweep happened to be reading — rather than to the property, which is the scope trap this register already records from 2026-08-22. Restated: **every guard in the repo that decides whether a downstream step may trust a value**, swept as 20 shell artefacts × their guard sites. First sweep (goss specs): `zcat \| tail` swallowing the CRC verdict, and `redis-cli ping` exiting 0 on an error reply. Re-sweep under the restated space, **3 more**: the netdata adapter's retry, guarded on "the body is not empty" while the caller needed "the alarms parsed" — the only one **observed**, one run logging `answered on attempt 3` and `unreachable or unparseable` together; and two latent siblings, `feed-digest.sh` reading a 200 that is not an entries page as "nothing unread" and pushing UP, and `cloudflare-ddns.sh` guarding a raw body for emptiness while consuming a derivation of it, which answers a malformed 200 by creating a duplicate record. All five fixed, all five proven to fail on purpose first |
| C04 | A working detector whose delivery path cannot reach a human | **Closed by decision.** smartd's mail channel was dead — and redundant: every alert it carried was already covered, more carefully, by the daily disk report. Silenced deliberately, with the measurement written into `smartd.conf`. Pi-hole's `gravity.info.updated` gained an assertion |
| C06 | A `start_period` whose real startup cost has never been measured | **ENUMERATED**, 13/13, after the first attempt closed at its instrument's edge. netdata cannot observe the wave that starts before netdata; re-measured from `State.StartedAt` to the first listen line, two more had overshot |
| C07 | A collector whose polling cost is disproportionate to the granularity of what it feeds | **GREEN since 2026-09-20 (widened and deployed; see the note below the table). It read RED here for two days after the fix shipped — corrected 2026-09-20, eighth run.** The gate is genuinely derived, and it is bounded by ONE COLLECTOR: `((600 / netdata_docker_update_every) * 0.833)` renders both the alarm threshold and the goss floor, for the docker collector. `apps.plugin` is outside it and was never declared at all — measured at 22.4 % of a core inside netdata's 42.7 %, machine at rest, against 85.6 % for all 32 containers. The ninth payment of the same trap: the derivation is sound and it keys on the wrong axis. `update every = 5` shipped 2026-09-18; the gate was then widened onto the PLUGIN axis and deployed green on 2026-09-20 — `no plugin whose charts feed no curated alarm may collect more samples/s than the busiest plugin that does`, both sides derived live. Re-verified 2026-09-20 (eighth run): evaluates OK, discriminates on three controls, `cgroups.plugin` 1002 -> 200 samples/s |
| C08 | A threshold probe that samples at an instant which cannot contain the peak it guards | **Closed by decision.** The homelab reads `Power Cycle Min/Max`, which resets each boot. The offsite keeps the instantaneous reading and reports its peak instead — its only maximum is lifetime, and a threshold on a figure that cannot come back down latches red forever |

## GATED — the nine members are **C07, C11, C14, C15, C18, C19, C41, C81 and C03-T**

**That list IS the membership. Do not reconstruct it by counting unstruck rows in
the table below — doing so gives ten, because C12's row is still there.** C12 is
ENUMERATED and is not a member; its row is kept for its derivation only. C07 is
recorded above the table rather than inside it, and is GREEN since 2026-09-20.
C21 left on 2026-09-19 (fifth run), C10, C13, C16, C17 and C20 earlier; each
struck row says so.

**This heading has now been wrong three nights running, each time in a different
way, and twice in a correction written to fix the previous error.** 2026-09-19
named four classes of which two were closed by decision and one ENUMERATED;
2026-09-20 (eighth run) replaced it with the correct nine but left the table
readable as ten; this is the third attempt. The residual that survived both
earlier fixes was C12's row, which the eighth run diagnosed in prose and did not
remove.

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
| C10 | A credential store readable beyond its service | **Left this table on 2026-09-11 — REOPENED, then CLOSED as ENUMERATED on 2026-09-12; see its ENUMERATED row, NOT the OPEN table.** This pointer said "see the OPEN table" for seven days after C10 had left it, which is a C01 instance inside the register itself — corrected 2026-09-19 (fourth run). The gate is genuinely derived and it still holds over the space it derives: the runtime set from `docker inspect`, plus a floor derived from `compose.yaml` since 09-05, plus two named assertions that are a list because the derivation cannot see what they cover. What reopened the class is that the derivation keys on **container mounts**, so a credential file no container mounts is outside it by construction — and two are |
| C11 | A container whose running `Config.User` differs from what compose declares | posture assertion, 9 services (#145). **NOT broken — the "BROKEN" verdict of 2026-09-05 midday measured a property C11 does not state, and was corrected the same evening.** The figures stand (9 assertions, 11 containers with a non-empty `Config.User`), but `socket-proxy` and `collabora` DECLARE nothing, so there is nothing for the assertion to disagree with: `Config.User` carries the IMAGE's user when compose is silent, and asserting the complement would write upstream's values into this repo. The deployed template argues exactly this at `goss-posture.yaml.j2:322-340`. Under its own property the gate is derived 9/9. A service that loses its `user:` is caught by review of `compose.yaml`, not by a probe of the result |
| C12 | A rotated secret a consumer never receives | **ENUMERATED 2026-09-20 (tenth run) by TWO COMPLEMENTARY BOUNDS, neither containing the other — the shape that closed C107 and C113.** `security` derived the VALUES from the live host and swept **76/76** (value, consumer) pairs over 39 values: 31 values × 64 carriers = 1 984 tests, planted positive control found, negative control not; 39 pairs are single-consumer, 28 are self-detecting Kuma push URLs, and 8 of the 9 remaining redundant copies are already gated. `ansible-deploy` parsed the DECLARATIONS and swept **52/52** render sites over the 39 `no_log: true` options; 66 notify targets, 0 orphans, 7 `creates:` and none on a secret. The two cardinals disagree on purpose and reconcile: 39 declared, some with no persisted carrier. **Zero live divergence on the day** — 6 multi-carrier values hash-compared on the host, all matching. **The live defect it leaves behind is STRUCTURAL and was fixed on 2026-09-20**: `deploy/tasks/main.yml` advertised `--tags secrets` as a rotation route while that tag reaches 19 of the role's 31 secret renders, missing `configs.yml`, `backup.yml` (7 values), `wireguard.yml` (`wg0.conf`) and `ddns.yml`. That is what let the 2026-09-12 Cloudflare rotation reach Traefik and not the DDNS for eight days. The old gate remains what it was — `posture.yaml secret-mounts-carry-the-current-value`, 14 pairs derived from `compose.services[*].secrets` against 17 file binds under the secrets directory, a coverage asymmetry measured at 0/28 mismatch and deliberately NOT widened (the three uncovered files are `volumes:` binds that never land at `/run/secrets/<name>`, so the comparison path would have to change, and the risk of turning a working gate into a silent green outweighed the gain) | **ENUMERATED** |
| C13 | A declared environment value shadowed by a persisted config file | **Left this table on 2026-08-30 — see the downgrade above.** The assertion is hardcoded to vaultwarden (#124, #159); a list of one is not a gate |
| C14 | A certificate with no expiry watch, or a silent ACME failure | `homelab-health.sh` parses `acme.json` directly, 21-day threshold. **21/21 live, not the 18/18 this row carried — and the growth from 18 with ZERO edits to the script is positive proof of derivation, which is worth more than the number.** Three-way set equality holds at 21 (acme.json = Traefik `/api/overview` = distinct `Host()` names = split-DNS records) and it is delivered (Kuma monitor 20 read `certs 30d/21` at 21:31:43). **The "silent ACME failure" half is a PROXY only**: expiry < 21 d plus a one-directional count ratchet. A name that never OBTAINS a certificate is invisible by construction, and the script says so in its own comment (#157). **That blind spot was MEASURED EMPTY 2026-09-13 night-second, with a control**: all 21 names serve a real Let's Encrypt leaf over SNI (correct subject, issuer CN YR1/YR2), while two uncovered names returned `SSL alert 112 unrecognized name, no peer certificate` — the probe discriminates, and no name is invisible. One real ACME failure did occur (2026-09-11T21:44:28Z, missing `_acme-challenge` TXT, 403) and self-healed; it is verbatim the case `homelab-health.sh.j2:384` says it deliberately does not report, so it CONFIRMS the design rather than breaching it |
| C15 | The offsite repository losing the one property that makes it a backup | goss assertion on the live rest-server process, proven to fail in both modes (#278) |
| C16 | A read-write bind mount its container cannot create files in | **Left this table on 2026-09-11 — downgraded to ENUMERATED.** The enumeration is derived; the PREDICATE is a proxy (`owner == OPERATOR_UID`). 15 of 27 mounts reach the test and 0 of the 15 can ever fail it |
| C17 | A filesystem never checked, and boot triggers reset every boot | **Left this table on 2026-09-05 evening — downgraded to ENUMERATED.** The three assertions are hardwired to `/`: one filesystem of four, and `Last checked` is asserted nowhere, six days after this file first recorded that omission. Nothing is proposed — the only live instance is the offsite root, and the operator DECLINED it on 2026-09-02 |
| C18 | A database dump absent, stale, or empty | **BROKEN on 2026-09-13 and repaired the same evening — see the run section.** Its derivation keys on the dump VARIABLES rather than on the databases present, so three services deployed that night were backed up live, in WAL mode, with no dump and no assertion. PR #352 adds them (15 assertions, 31 → 46). **The wrong-axis defect itself is untouched, and 2026-09-13 night DEMONSTRATED it rather than arguing it**: `sonarr/logs.db`, `radarr/logs.db` and `prowlarr/logs.db` sit under a backed-up path with no dump and no assertion, and the deployed spec mentions `logs` zero times (46 assertions live, verified). They hold app logs, so the impact is low — their value is as proof that a database outside `backup_sqlite_dumps` is invisible to this gate by construction, which is the same shape that reopened C10. goss `backup-dumps`, now **26** checks (2x3 + 3x5 + 5, counted on the deployed spec 2026-09-05 evening), generated from the dump variables so a database cannot get a dump without a check (#177, ADR-032). **The `empty` word is no longer an overstatement** — the derived `-content` floor shipped 2026-09-05 10:39 and 2x3+3x4+4 = 22 matches the host. The derivation half recorded as defective that morning is **FIXED**: `-container-present` is now generated in the same loop, and the residue is a list of one (Immich) |
| C19 | A failed systemd unit, or a timer whose service did not succeed | **CORRECTED 2026-09-13 (night-second): the AUTO-RESTART half of the script IS DERIVED, not a list** — `homelab-health.sh.j2:615-616` filters on the systemd sub-state and names no unit; the `:552` comment about units being "enumerated and NAMED" explains why that half cannot move into goss. Swept the same night for CONSEQUENCE: **33/33 units with `Restart!=no` across both hosts at `NRestarts=0`, zero auto-restart loops**, with a positive control (`vault-mount` genuinely reached restart counter 4 at 12:41:39 that day and reads 0 now). **QUANTIFIED 2026-09-13 (late evening): the goss half is A LIST — 6 named `service:` entries + 8 named `command:` assertions, 1 of 15 DERIVED (`systemd-no-failed-units`, from `systemctl --failed`), and that one still exits 0 with the binary absent, byte-identical to 2026-09-05.** The script half is genuinely derived and its floor fires (`timers_seen` 13 healthy, 0 under `PATH=/nonexistent`) — **at `homelab-health.sh:665`, not the `:592` this row used to give.** Also structural: `systemctl --failed` cannot see an auto-restart loop, and `fail2ban` and `claude-remote-control` both carry `StartLimitIntervalSec=0`, so that half of the property lives only in the script. goss `units.yaml` plus the health script's last-run check — **homelab only; the offsite half is C02**. **Only the GOSS half is vacuous at zero** — corrected 2026-09-05 evening by two agents independently: the script half now carries a derived floor (`timers_seen -eq 0`, `homelab-health.sh:592`, shipped 2026-09-05). The goss half still exits 0 with the binary absent (positive control: `PATH=/nonexistent`), rescued by composition rather than by assertion |
| C20 | A secret that a deploy reports as rotated without rotating it | **Left this table on 2026-09-03 — downgraded to ENUMERATED.** 4 hand-written probes over a space of 16 secret files; a list of four is not a gate (#159 fixed the case-mismatch bug, which is a different question) |
| C21 | A snapshot that missed its offsite copy and is never retried | **LEAVES THE GATED TABLE 2026-09-19 (fifth run) — DOWNGRADED TO ENUMERATED.** It is an ARGUMENT, not a gate, and that is now measured rather than suspected: over the 3 463 lines of deployed posture, **exactly one assertion opens `resticprofile.yaml` and it reads only the `library/` categories**; `grep snapshot` returns a single comment. Nothing reads `copy:`, and nothing compares the two snapshot sets — so a bound added to the deployed `copy:` would pass unnoticed and the copy would stay green. A structural guarantee plus a push monitor is not an assertion on the property. Historic text follows. **ROW STALE FOR THE THIRD TIME, and the stale word is "monitor" — there IS no retention monitor.** The guarantee is STRUCTURAL (`copy:` carries no bound, verified in the deployed file AND in `resticprofile show`) plus the copy push monitor. 91 offsite / 34 local snapshots, 0 locks on either, 2026-09-13. The class holds; the description has now been wrong three times. Formerly cited as the retention monitor (#158, #168). **The "time-window filter" this row used to name no longer exists** — re-verified 2026-09-03: `copy:` carries no bound, every snapshot is re-offered nightly, 31 local / 81 offsite with no gaps. The class holds; the description was stale for the second time |
| C81 | A byte written into a file whose consumer reads it back through a narrower encoding than the producer's | `ops/check-ascii-system-files.py` in pre-commit, proven to fail in both directions (2026-09-04); re-exercised 2026-09-05 evening in a sandbox, 3 flags with both negative controls passing. **Its `marker:` half is derived; its path filter is a LIST OF ONE** — `ASCII_STRICT_PREFIXES = ("/etc/ufw/",)`. Kept GATED rather than downgraded because, unlike C17, no live instance has ever existed outside that prefix; its two blind spots (`*.yaml`, `.j2` into `/etc/ufw/`) are empty today |
| C41 | A dead-man's fuse re-armed from zero by the restart of its own watchdog | `kuma-no-push-monitor-silent-past-its-own-window`, derived from Kuma's own monitor table and each monitor's `interval`, with a starvation guard; discriminates on 54 historical silences against 16 (2026-08-30) |
| C03-T | A validation whose instrument answers a different question from the one its comment claims — **the decidable half, where the instrument can name its own "unknown"** | **REPAIRED AND RE-PROVEN 2026-09-13 (late evening): `h.status = 1` on both clauses, deployed and verified evaluating on the host (posture exit 0, no timeout). Re-proven off-host against a database that CONTAINS fabricated rows — five scenarios, old and new side by side: the mute reporter goes exit 0 -> exit 1, the discriminating twin stays exit 0 on both. The gate is GATED again.** It had been **RED SINCE THE DAY IT SHIPPED — see the run of 2026-09-13 (late evening). Kuma fabricates a DOWN beat every interval for any push monitor that is not UP; both clauses count `heartbeat` rows with NO `status` filter, so a mute reporter can never satisfy either. Verified live: 39 fabricated rows on 09-13, 36 for monitor 20, all `status=0`, against 164 real `status=1` rows the same day. The six-run fail-on-purpose proof used a SYNTHETIC database that by construction held only the rows the test wrote. Fix is `h.status = 1` — what C41 has used since 08-30 — NOT a match on the upstream English literal.** **RE-VERIFIED LIVE 2026-09-13 (night-second) and GREEN**: `h.status = 1` present on both clauses (`:3121`, `:3133`), the assertion evaluates, and the repaired branch has ACTUALLY EXECUTED (2 markers in-window, `lost=2`), posture exit 0 in 44 s. **Residual, stated rather than glossed: it has never yet completed a SCHEDULED run** — next 2026-09-14 11:04; its 09:05 run timed out at 45 s alongside three other assertions. And the fixture lesson re-applied to the REAL store: 75 GENUINE `status=0` pushes plus 61 PENDING rows that day mean a live reporter correctly reporting a failure is, to both clauses, indistinguishable from a mute one — **the direction is fail-safe, so the gate is not blind, but the sentence it prints can name the wrong cause.** `no-kuma-report-was-lost-in-silence`, `/etc/goss/posture.yaml:2995`, deployed 2026-09-13 14:15:44. Derived: the floor comes from Kuma's own `StartedAt`, the lookback cap from the timer's own period, and the silence test from each monitor's own `interval` — the same source C41 uses. **Made to fail on purpose 2026-09-13, off-host, against the deployed script verbatim with `docker`/`journalctl`/`sqlite3` stubbed and a synthetic Kuma database — six runs**: no marker -> exit 0; loss fully recovered -> exit 0; loss with nothing since -> exit 1, naming it; loss with a reporter past its own cadence -> exit 1, naming the reporter; **the discriminating twin — same clock, that reporter recovered -> exit 0**; floor unreadable -> exit 1, "refusing to judge" rather than passing. Nothing was written on either host and no heartbeat was sent |

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

## ENUMERATED — **do not count these rows and do not trust a number here**. The heading carried "69 rows below" against 71 present until 2026-09-21; the two extra were C119 and C120, declaring themselves OPEN inside their own row while sitting in this section, which is the C12-row shape a third time. A class's state lives in ONE place: the OPEN table if it is open, this table otherwise, and a row that has moved says so instead of keeping its text. C03, C06, C09, C13, C39, C43 and C75 are recorded in their own sections above and have no row here; **C27 DOES have a row here and the old heading wrongly excluded it**. **C01 left this table on 2026-09-11, was REOPENED, and CLOSED 2026-09-19 at 123/123 — its state lives in its own row above, not in any summary table (pointer corrected 2026-09-20).**

**The heading said "36 here" over 69 rows, for an unknown length of time.** It
was found by `project-manager` on 2026-09-20 and confirmed by the main session
with a count. The rule this file keeps re-learning, and keeps breaking in its own
prose: **write the membership, or write nothing — never a number a reader cannot
check without recounting.** The number above is a count of rows in the table
immediately below it and nothing else; if you add a row, recount it.

Swept completely at least once. Re-check only after a change that could reopen
them; do not re-derive without a new symptom.

| ID | Property | Swept | When |
|-----|--------------------------------------------------|-----------------|------------|
| C22 | A healthcheck that cannot report the failure it names | 28/28, with negative **and** positive controls | 08-19, re-swept 08-29 |
| C23 | A kernel parameter differing between hot and boot path, or between hosts | 30/30 both hosts | 08-19 |
| C24 | An image that is not genuinely arm64 | **32/32** (was 28/28 — the estate grew to 32 containers; corrected 2026-09-19, fifth run) | 08-21 |
| C25 | A bind mount whose inode differs from what the container sees | 19/19 against `/proc/<pid>/root`; **80 mounts**, not the 62 this row carried (corrected 2026-09-19, fifth run) | 08-19 |
| C26 | A credential reaching a command line, a child process, a scheduled job or a trace | **CLOSED 2026-09-13 — all four axes.** The ARGV axis was swept from both sides independently: `ansible-deploy` 340/340 over six derived sub-populations (103 Ansible `command`/`shell`/`raw`, 6 `environment:`, 30 compose `test`/`command`/`entrypoint`, 31 systemd `Exec*=`, 70 deployed scripts, 100 goss `exec:`, 0 cron), `security` over 74 container argv fields + 157 host sites + 13 in-container cron entries + 8 189 processes against 80 derived secret values. **3 CONFIRMED instances, and 2 of the 3 are in a sub-space no prior sweep had enumerated: the argv the IMAGES ship** — invisible to any grep over this repo. Trace axis closed and gated 2026-09-12; residue is 2 of 55, not 6. **ENUMERATED, not GATED**: the proposed assertion (two literal greps in `homelab-posture.sh`) is not deployed, and the argv axis has had no live assertion since 2026-08-30 | 08-22, 09-12, 09-13 |
| C27 | **REOPENED 2026-08-29 evening** — a deployed artefact differing from the repo | 12/12 by sha256, 25/25 templates, both hosts | 08-29 |
| C28 | An operator key no role reads, or a role key the example omits | 123 keys, both directions, 0 and 0 | 08-29 |
| C29 | A construct that disables a feature silently | 81 read one by one; 08-29: 80 `default()`, 22 `failed_when: false`, 5 `creates:`, 3 absent-var gates | 08-19, 08-29 |
| C30 | A proxy router or middleware declared but not applied | **ROW CORRECTED 2026-09-13 night-second: it is 24/24 routers and headers on 22/22, not 19/19 and 18/18 — with ZERO edits in between, the same positive proof of derivation C14 earned going 18 -> 21.** Derived from the mechanism: `traefik.yml.j2:47-57` attaches the three middlewares and the cert resolver to the ENTRY POINT, so a router cannot opt out. 0 API errors. **The words "proven both ways" are struck** — the deny direction has no instrument anyone can now repeat, because probing `vpn-only` from the host is meaningless (Docker masquerades the source into the allow-list; see `settled.md`) | 08-29, 09-13 |
| C31 | A name resolving differently inside and outside | split DNS **21/21** (was recorded 18/18 — corrected 2026-09-19, fifth run, and the deployed dnsmasq confirms 21), single DoH upstream, 2590/2590 queries | 08-29, 09-19 |
| C32 | A port reachable from outside that should not be | probed from the offsite uplink with a known-open control | 08-19, 08-29 |
| C33 | A broken relative link or a path that does not exist | **113 links** (was recorded 104 — re-measured 2026-09-19, sixth run), 123 absolute paths; the sixth run also read 108 absolute paths with 25 absent and **0 defects**, all container-internal, offsite-only, conditional or documented-ephemeral | 08-29, 09-19 |
| C34 | A documentary artefact contradicting the sibling it cites | **LEFT THIS TABLE — it is in the OPEN table, and that row is the one to read, not this one.** This row said `REOPENED 2026-09-20 (ninth run, evening)` while sitting in the ENUMERATED section with the state `OPEN`, and the OPEN table did not carry the class at all — the defect this file recorded about itself on the ninth run, paid a third time, and the mechanism is always the same: two rows for one class. The ninth run reopened it on a rationale in `roles/base/tasks/logging.yml` refuted by `boot-and-unlock.md:70`. The tenth run closed its axis A at 44/44 and left axis C at 33 of 460. | **See the OPEN table** | **UPDATED 2026-09-20 (eleventh run): axis C re-derived BY THE PROPERTY — 467 occurrences, 333 distinct source->referent relations, 79 referents, 84 citing documents. Swept 110/110 links, 69/69 glosses, 269/357 supported claims; ~48 never opened individually, which is what still blocks. The cardinal 460 this file carried was derivable from NO written rule. Read the OPEN table.**
| C35 | A push monitor carrying a constant instead of its script's message | 12, now 15; all at `maxretries=0` | 08-19, 08-29 |
| C36 | An unsized tmpfs | **41**, not 37, parsed rather than grepped; re-measured 41/41 with 0 unsized (corrected 2026-09-19, fifth run) | 08-21 |
| C37 | A WAL-mode SQLite copied without its `-wal` | **CLOSED 2026-09-13 night-second by two derivations bounded by the PROPERTY**, after the 08-29 sweep's dump-mechanism bound had reopened it: `backup` 65/65 (7 dump hooks + 13 exclude expressions + 15 operator copies + 28 authoritative reads + 2 delete sites) and `project-manager` 31/31 over the operator procedures in `docs/`+`knowledge/`. **0 defective on either.** The cardinals differ and that is derivation-relative, not a defect. `.backup` WAL completeness proven by an off-host control rather than asserted; `wg-easy.db`/`gravity.db`/`fail2ban.sqlite3` measured as `delete` mode and so not members. Blind spots stated and DIFFERENT: `backup`'s keys on the `.db`/`.sqlite` token (bounded from the filesystem instead, 23 stores at depth 6), `project-manager`'s cannot see a procedure that exists only in the operator's head. **ENUMERATED, not GATED** — nothing derives the (copy site, journal mode) relation | 08-29, 09-13 |
| C38 | A container log growing without rotation | **32/32**, not 28/28; rotation proven applied rather than declared, and **structurally derived** from `daemon.json` (31 at 10m/3, 1 deliberate at 20m/10, 0 unbounded) though carrying no deployed assertion (corrected 2026-09-19, fifth run) | 08-21, 08-29 |
| C40 | A container killed before finishing an ordered shutdown | **26 of a 32-container fleet, 8 instances** (was 29/29 — frozen at the 28-container estate; the correction recorded at the `aggregation` run never reached this row, and the seven-class sweep of 2026-09-19 missed it. Re-measured 2026-09-20: `docker inspect -f {{.Config.StopTimeout}}` over 32 -> 26 `<nil>`, 4 at 90, 1 at 60, 1 at 5), on the daemon's own log rather than on crash markers | 08-30 |
| C42 | A mechanism ranking by a timestamp written before the clock was right | 6/6, 1 instance | 08-30 |
| C44 | A verification whose cadence cannot observe the event it guards | **LEFT THE OPEN COLUMN 2026-09-20 (eighth run), ENUMERATED 27/27, remedy DECLINED — read the eighth run's section, NOT the OPEN table, which has not carried C44 since.** The words "see the OPEN table" stood here until 2026-09-20 and sent the reader to a table the class had already left — a C34 instance inside the register itself. (It said "C44 IS THE REGISTER'S ONLY OPEN CLASS" from the fifth run until 2026-09-20; C113 joined it as OPEN in the seventh run and was closed in the eighth.) It sat here with a stale `13/13 timers` while being OPEN, and without the "left this table" pointer C01/C10/C12/C17/C20 all carry, so this table read as if C44 were closed (corrected 2026-09-19, fifth run) | 08-30 |
| C45 | A reporting path that cannot report its own failure | 10/10 push sites, 8 instances | 08-30 |
| C47 | A PID 1 that cannot act on the signal it is sent | 29/29, 2 instances (`SigCgt` masks, not documentation) | 08-30 |
| C48 | A real dependency that nothing declares | 29 services + 18 configs, 1 instance | 08-30 |
| C49 | A hardening applied to an artefact its producer regenerates | 28/28, 1 new instance | 08-30 |
| C53 | A handler whose effect is expected earlier in the play than it occurs | **41 handlers, 3 flush points** — not the 34/1 this row carried; two runs counted 41/3 independently, and the correction had been written in the run narration without reaching this table (corrected 2026-09-19, fifth run) | 08-30 |
| C67 | A verification whose deadline was sized against an input that has since grown | 13/13 both hosts, 2-4 instances | 08-31 |
| C68 | A store whose declared retention is overridden by a limit that is not the one written down | 7 stores + 31 log rings | 08-31 |
| C69 | A periodic control whose own runtime nothing measures | 16/16, 1 material instance | 08-31 |
| C70 | A rule inert today that would be a fault if enforced | 19/19 UFW rules, 2 instances | 08-31 |
| C71 | A recurring cost driven by rewrite rate rather than information carried | 22/22 backup subtrees, 6 instances | 08-31 |
| C72 | A remedy that enlarges a window, effective only after a delay equal to the enlargement | 2 windows | 08-31 |
| C74 | A rule whose decision is pre-empted by another component acting earlier on the same object | **CLOSED 2026-09-11 by two independent derivations**: 48/48 over 14 arbiters (`security`) and 71/71 over 10 arbiter-decision categories on both hosts (`system`). The cardinal is derivation-relative — do not quote either as "the" number. 1 material instance (`net.ipv6.conf.eth0.accept_redirects`, both hosts), 1 immaterial (`use_tempaddr`), 8 masked (`lo`), 1 harmless (fail2ban `[sshd]` `logpath` under `backend = systemd`), 1 mechanism left unresolved (A15, `iptables-restore --noflush` on `DOCKER-USER`) | 09-02, 09-11 |
| C76 | A verification whose expiry is reported through the same channel, and in the same terms, as the condition it watches | 197 + 43 assertions; 15 within 2x of budget | 09-02 |
| C12 | A rotated secret a consumer never receives | **ENUMERATED 2026-09-20 (tenth run), 76/76 and 52/52 — read the detailed row, which is the only copy of the sweep.** This row and the one above it disagreed for months about whether a live assertion existed; it does, and the class is neither OPEN nor one of the nine GATED |
| C20 | A secret that a deploy reports as rotated without rotating it | **Cardinal corrected 2026-09-19 (second run) to 43 by VALUE.** As written then: 4 probes over 16 secret files — **downgraded from GATED 09-03** | 08-19, 09-03 |
| C78 | A set of which two or more components each hold their own definition, in different grammars, with nothing comparing the definitions | 4/4 name grammars (18/18/18, Kuma 15/18) + 21/21 restore expressions against 13 exclude patterns | 09-03 |
| C82 | A fault whose only detector runs earlier in the same sequence than the step that introduces it | **CLOSED 2026-09-11.** 25/25 deployed executables (1 725 code lines, both hosts) and 48/48 (check, later-statement) pairs — 0 confirmed, 48 refuted, the register's live instance verified dead. Plus 39/39 play-order validations, 1 confirmed (the sysctl detector), 35 refuted. 20 healthchecks and 264 goss `exec:` blocks excluded BY MEASUREMENT: 0 mutating statements in either population. **ENUMERATED, not GATED** — nothing derives the (check, later-mutator) set, so the next commit can repopulate it | 09-05, 09-11 |
| C83 | A mechanism that reports success, health or completion after producing or examining a set, without bounding that set's cardinality from below | **976/976 across 8 slices**, each slice's N derived and stated; 92 instances of which 32 are two families of 16 and 12 are no-action upstream, 884 refuted. **PARTIALLY GATED 09-05** — `ops/check-empty-set-floors.py` in pre-commit derives the space rather than listing it, and its six controls run beside it, three of which must FLAG. **The Ansible face is NOT gated** — see the note below before writing GATED anywhere | 09-05 |
| C17 | A filesystem never checked, and boot triggers reset every boot | **Downgraded from GATED 09-05 evening** — 3 assertions hardwired to `/`, 1 filesystem of 4, `Last checked` asserted nowhere. Its only live instance is DECLINED | 08-30, 09-05 |
| C84 | A work queue whose only record of what REMAINS to do is destroyed by the same interruption that leaves the work unfinished | 8/8 stores — 7 durable, verified on disk; 1 volatile (`immich-redis`, `--save ""`, `appendonly no`, holding Immich's `immich_bull:*` queues). 1 instance, 2 of 9 474 assets with no thumbnail row | 09-05 |
| C85 | A verification whose verdict is delivered only to an EPHEMERAL channel, so that afterwards nothing distinguishes "ran and passed", "ran and repaired" and "did not run" | 6/6 operator-launched system verifications; 2 produce an INTEGRITY verdict. **CORRECTED 2026-09-13 — 2 instances, not 1, and they are the two members of that same pair**: `homelab-unlock`'s `e2fsck -p` (logged on the SKIP branch, not the RUN branch) and `/usr/local/bin/homelab-fsck`, which runs `e2fsck` on the LUKS volume and echoes its verdict to the terminal only, so afterwards nothing distinguishes clean / found-errors / repaired / never-ran. The space was right; the verdict on one member was wrong | 09-05, 09-13 |
| C16 | A read-write bind mount its container cannot create files in | **Downgraded from GATED 09-11** — the enumeration is derived, the PREDICATE is a proxy (`owner == OPERATOR_UID`): 11 of 27 mounts skipped for `CAP_DAC_OVERRIDE`, 1 for a matching uid, **15 reach the test and 0 of the 15 can ever fail it**. The CLASS is clean — 27/27 swept under the real property (uid/gid/caps against owner/group/mode, no `test -w`) | 08-16, 09-11 |
| C10 | A credential store readable beyond its service | **CLOSED 2026-09-12** — 29/29 declared runtime stores (`security`) and 32/32 write sites, 26 module writes + 6 `environment:` blocks swept across all of `ansible/` (`ansible-deploy`). 0 instances; the two restic passwords that reopened it are `0400`, all 17 world-readable secrets are Compose bind mounts under a `0700` parent, both `0440` groups empty. Its gate is restored (`b761450`), not deleted as this file once recorded | 08-16, 09-05, 09-12 |
| C86 | A configuration value written to RESTATE an upstream default in order to freeze it, which therefore silently excludes every element that default has GAINED since | **CLOSED 2026-09-12** — 363/363 over five domains, each deriving its own slice: 5 `network` (09-11) + 12 `security` + 172 `system` + 138 `services` + 36 `ansible-deploy`. 3 confirmed, 0 exploitable today: sshd `Ciphers` (pure restatement, latent until OpenSSH ≥ 9.9), the netdata AppArmor profile (missing dockerd 29.8.0's powercap denial; `/sys/devices/virtual/powercap` does not exist on a Pi 4), `ansible.cfg` `ssh_args` (33.7 % payload cost). Positive control: the repo does NOT restate `Unattended-Upgrade::Allowed-Origins` | 09-11, 09-12 |
| C88 | A store that ADDS on each run with no counterpart removing what its register no longer names | **CLOSED 2026-09-18** as ENUMERATED, by three slices over the 105 stores of the previous run: `ansible-deploy` 80/80 `/etc` paths + 5 in-file registers, `network` 21/21 on `acme.json`, `backup` 16/16 on the two snapshot registers. The named blind spot dissolved rather than being swept: the git-history walk is unnecessary, because the marker set is INCLUDED in the repo's `/etc` destinations, checked file by file with `comm` (empty on both hosts). **0 live residue anywhere.** Marker coverage is derivation-relative — 42.5 % on the agent's three-spelling regex, **28.7 % on the stricter single string, and the cautious figure is the one to quote** — which is why the gate to build is the dpkg diff, not the marker. Removers derived from the register: 2 of 68 + 3 of 15 + 2 of 80. 3 live-or-latent instances | ENUMERATED |
| C101 | A component declines a duty on the written ground that a NAMED sibling asserts it, and the sibling declines it too | **MINTED 2026-09-18, 5/5** written delegations between verification artefacts, 4 true with positive controls, 1 false. The false one cost the estate any assertion that a control timer is ARMED; `homelab-image-retention` was the one instance with no other detector. Gate shipped for the instance — the armed set is asserted inside the parity assertion that already builds it, 14/14 green. ENUMERATED and not GATED: nothing derives the (claim, sibling) relation, so a new comment reopens it | ENUMERATED |
| C102 | A repair mechanism whose TRIGGER and whose INPUT share a failure cause, so it never runs under conditions where its input can be trusted | **MINTED 2026-09-18. Space stated and NOT derived**: the self-healing mechanisms that read an external input. 1 live instance, measured end to end from the offsite journal — `offsite-wg-reresolve.sh` installed a resolver's wildcard answer as the endpoint of the only tunnel to that host on 2026-09-16 11:32:22, and re-resolved correctly 67 s later. Nobody saw it: `stat_hourly` gives 2 650 UP / 2 DOWN over the hour, the 2 being the posture monitor. **The fix is DECLINED by the operator**; the class stays | ENUMERATED, space unbounded |
| C87 | A hand-made artefact that outlives its operation — created outside Ansible by a repair, a migration or a measurement, maintained by nothing, and invisible to C27, C10 and C16 BY CONSTRUCTION | **CLOSED 2026-09-13.** 16/16 admin+scratch (09-12) plus the service-data slice: **1997/1997 at a STATED depth of 3**, cross-checked by a second, *unbounded-depth* property-keyed pass over **112 895/112 895** entries across `/mnt/data/services`, `/mnt/data/tmp`, `/mnt/data/backups` — both passes returning the same instances, which is what makes the number believable. Offsite control still 0. Derivation: `zero occurrences in the entire git history` ∩ `present on the host`. **5 instances, 1 ACTING**: `jellyfin/config/iptv-fr.m3u`, the `<Url>` of Jellyfin's only Live TV tuner, in no commit and no doc — the container layer's one reproducibility gap. Inert: `/mnt/data/tmp/nextcloud-db-pre12/` (235 MB full MariaDB datadir, 48 days, 0700 uid 999), `backups/pre-navidrome-0.64.0/navidrome.db` (20 MB, made 8 min before the upgrade), `/mnt/data/tmp/dnsprobe.sh` (an empty DIRECTORY named like a script), pihole's logrotate decoy. **The three `acme.json.bak*` are gone** — last run's finding was acted on | 09-12, 09-13 |
| C91 | **A set of periodic mechanisms whose schedules are ALIGNED, so their executions coincide and the contention degrades what each measures past its own fixed budget** | **13/13**, derived: every `homelab-*` timer's `OnCalendar` falls on a 5-minute boundary, so alignment is structural rather than accidental. Two units sharing `OnCalendar=*:0/5` measured overlapping on **43 of 77 runs (56 %)**. 1 material instance, and it is C03's fifth reopening: Kuma push latency went 274 ms → 10.9 s / 12.0 s / 3.3 s against a fixed `--max-time 10`. **NOT C67** (a deadline sized against an input that has since grown) — nothing grew; the mechanism's own schedule creates the load that breaks its own budget. **NOT C69** (a periodic control whose own runtime nothing measures) — the runtimes are measured; it is their coincidence that is not | 09-13 |
| C90 | Two or more independent mutators of the same object, with nothing establishing mutual exclusion between them | **CLOSED 2026-09-13 evening by SIX independent derivations** of the (object, mutator-set) relation: 191/191 (`ansible-deploy`), 106/106 (`services`), 31/31 (`system`), 18/18 (`network`), 12/12 (`backup`), 17 runbooks → 4 (`project-manager`). The cardinal is derivation-relative — do not quote one as "the" number; what makes it believable is that each slice states its own derivation and its own blind spot. 3 mutator generators nobody had counted turned up. **ENUMERATED, not GATED**: nothing derives the relation continuously. Residual: `security` and `observability` produced no slice | 09-13 |
| C93 | **A file whose designed role is to be a TEMPLATE or a BACKUP, and which the consuming tool also loads as LIVE INPUT** | **3/3** — the `*.example.yml` files live INSIDE `inventory/host_vars/homelab/`, and Ansible loads every file in a host_vars directory regardless of its name. Reproduced in isolation by the main session: a key present only in the example surfaces with its placeholder value; a key present in both is won by the real file, which loads later alphabetically. Consequence measured by `ansible-deploy`: **31 of 78 `required: true` options can never fail**, 24 are protected by nothing — including `ssh_port_hardened: 22` and `luks_passphrase: ""`. Zero live placeholders today, verified. **The operator DECLINED moving them on 2026-09-13**: the file is the reference and stays where it is. The class is swept; its one live instance is accepted | 09-13 |
| C94 | **A mechanism that reads a selector's result as a scalar without bounding its cardinality from ABOVE** | **CLOSED 2026-09-13 night by eight per-domain slices**: 18/18 + extension (`system`), 26/26 (`observability`), 12/12 (`services`), 12/12 (`backup`), 5/5 (`network`), 0/0 (`security` — no selector-as-scalar site in its task files), `ansible/` swept with 0 confirmed and 2 latent (`ansible-deploy`). 0 new confirmed instances; the 4 founding instances were fixed by PR #352 except the one in DECLINED territory. The cardinal is derivation-relative — do not quote one as "the" number. **ENUMERATED, not GATED**: C83's deployed gate guards cardinality FLOORS, and nothing derives ceilings continuously, so the next commit can repopulate it | 09-13 |
| C100 | **A recovery condition asserted from a mechanism's CURRENT STATE when its failure was a property of its CADENCE — so one out-of-band run clears the alarm while the schedule stays unrepaired** | **20/20**, derived by `observability` over the recovery conditions of the deployed health paths. 1 live instance measured end to end: `homelab-health.sh:643` reads `systemctl show -p Result`, the 12:24 hand-run supplied a success, monitor 20 returned `status=1` at 10:40:55 UTC and is still green, and the next SCHEDULED run of the unit that failed is Tue 2026-09-15 01:00 — ~38 h of green over an unexercised cadence. The machine-side twin of the `settled.md` instrument trap *a unit's current state is not its cadence's history*. **ENUMERATED, not GATED**: nothing asserts that a clearing condition names the same mechanism as the failing one | 09-13 |
| C103 | **A status field read as the current verdict that does not carry WHICH execution produced it, nor whether one occurred at all** | **MINTED 2026-09-19, systemd slice swept 14/14 control timers + 3 offsite, Kuma slice NOT swept.** Four histories read `Result=success`: never started in this unit's life, started before the last boot (the service timestamps are cleared by it, the timer's `LastTriggerUSec` is not), started and ended non-zero under `SuccessExitStatus=1` — **7 of the 14** carry it deliberately — and started a minute ago and passed. Proven with a negative control (`rescue.service`) and a positive one (`offsite-health`): `offsite-smart-test` ran 2026-09-01, and on the service object it is byte-identical to `homelab-image-retention`, which has never run. The discriminator exists and had **0 occurrences in the repo**. Shipped: the health script now reports a timer that FIRED SINCE THIS BOOT whose service never started (monotonic pair, reboot-safe, verified on the offsite), and the posture beat carries `scheduled run` / `manual run` | **ENUMERATED — CLOSED 37/37 monitors, 111 field-reads, in the second run of 2026-09-19; this row still read OPEN until the sixth run corrected it.** The sixth run completed its remaining residual at **54/54**: exactly **1** published quantity has a programmatic consumer (`msg like '%deep check%'`, goss :1235/:1246). The rest are informational by construction — the decision is taken producer-side before the beat is built — which is a true measurement and a weak defect, consistent with the operator's decline |
| C104 | **A harness that publishes the cause when the cause is its OWN and discards it when the cause belongs to the assertion** | **MINTED 2026-09-19, ENUMERATED 219/219.** goss never prints what a check wrote — verified against the deployed binary, a declared `stdout:` renders the literal `"object: *bytes.Reader"` — while goss's own timeout renders as `Error Command execution timed out (30s)`. **28 of the 219** `exec:` checks carry ≥2 `exit 1` branches with distinct messages and no `stdout:`; the intersection is exact, every multi-branch check is in it. Live proof: `miniflux-no-feed-silently-unscheduled` pushed `Expected 1 to be numerically eq 0` on three consecutive scheduled runs for one of three causes it could not name, two of which are repaired at the probe and one at the estate. Remedy shipped on the 5 branches of the 3 checks that have fired this month: `exit 2` = could not measure, `exit 1` = property violated, the only field that survives into the alert | ENUMERATED |
| C105 | **A documented procedure that produces — or erases — exactly the state an assertion discriminates on, with neither side saying so** | **MINTED 2026-09-19, space NOT bounded.** 16 documentary sites derived from both ends (12 `docker compose down <svc>`, 4 timer disarms), **0 annotated**, against 2 pre-announcements of red in the whole repo. The instance that bites: `restore-from-backup.md:652` disarms `homelab-backup.timer`, the assertion deployed 2026-09-18 22:58 then prints `control timer(s) present but not armed` every day of a 7-33 h restore, and the boxed warning three lines above says that re-arming that timer `rm -rf`s the dumps being restored — **the red invites the forbidden act**. The inverse direction sits outside those 16 by construction: the certificate ratchet keeps its reference on the SD card and its referent on LUKS, so a reflash — a routine recovery here — re-seeds `cert_high` at the current count and a real loss can never fire. **Annotating the 16 is DECLINED by the operator** (a restore is exceptional; a surveillance outage is acceptable there); the class stays | **ENUMERATED — CLOSED 28/28 in the second run of 2026-09-19; this MINTING row still read OPEN until 2026-09-20 (ninth run), contradicting the header and its own closure row above. The remedy — annotating the 16 sites — is DECLINED.** |
| C106 | **A parameter whose "not supplied" sentinel and whose "supplied but empty" value normalise to the same object, so two opposite intents produce one argv** | **MINTED 2026-09-19, ENUMERATED 2/2** — the parameters fed by `{{ x … if x is defined else omit }}`, `compose.yml:75` and `:120`. Demonstrated on a local fixture: `-e deploy_services=` gives `defined=True value=[]`, then `docker_compose_v2.py:479` folds `None` and `[]` together and the argv is **byte-identical to a full-stack deploy** — which arms every pending image pin. `rotate-a-secret.md:149` hands the operator that exact line with `<svc>` to fill in. **The fix is DECLINED by the operator**; the class stays | ENUMERATED |
| C107 | **An assertion that consumes its own instrument's output at a COARSER GRAIN than the instrument produced it** — the finer signal is collected, rendered as prose, and never gates | **CLOSED 2026-09-19 (fourth run), ENUMERATED** by two complementary bounds that converge on lynis: 32/32 deployed executables and 12/12 supervision-plane instruments. Neither bound contains the other. **Do not re-derive; do not quote the "NOT BOUNDED" text that its minting row still carries above** | ENUMERATED |
| C108 | **A container resolving a MUTABLE tag, where the running image and the tag's current referent can diverge with nothing observing it** | **MINTED 2026-09-19 (fourth run), ENUMERATED 32/32** — 31 containers resolve a mutable tag, 1 is digest-pinned. Its gate is `containers-run-the-image-their-tag-designates` (`posture.yaml:198`). **Gate promotion still UNMET as of the sixth run**: the spec's mtime is 13:54:02, the timer's `LastTriggerUSec` is 11:07:08 — BEFORE the spec — and the 17:39 run was manual. Next scheduled chance 2026-09-20 11:09:12 (not 11:01, which this file carried in error). The two divergences it found are resolved, 32/32, 0 divergence. **This row did not exist until the sixth run** | ENUMERATED, gate unpromoted |
| C109 | **An obligation borne by a human, whose discharge changes no machine-readable state, and which the estate's only "awaiting a human" channel therefore cannot represent — so its universal negative means "none of the six I was told about"** | **PROPOSED by the fifth run, ACCEPTED by the operator 2026-09-19 (sixth run). ENUMERATED.** The mechanism is literal: `homelab-health.sh.j2:820` pushes `up "nothing waiting on a human"`, and membership is **6 hand-written `pending+=()` sites over 4 machine states** (reboot-required, journal skew x3, security updates, certificate expiry). Reached from three unrelated directions — `security` (17/17 over 17 runbooks + 5 operator commands, 12 out of space, 5 in), `backup` (7/7, 3 monitored, 4 not) and `services`. Enumerative bound, so it can never be GATED. **The USB-tamper instance is DECLINED — do not re-raise it.** **This row did not exist until the sixth run** | ENUMERATED |
| C110 | **A stated trigger — a deadline or a condition — for an action only a human performs, with no deployed instrument evaluating it, so "on time", "overdue" and "never done once" come out identical** | **PROPOSED by the fifth run, ACCEPTED by the operator 2026-09-19 (sixth run). ENUMERATED.** Bounded from both sides independently and with no contact: `ansible-deploy` on the clock axis (**N=5** time-bounded operator obligations, 5/5 swept, covered **0/5**) and `project-manager` **and** `network` on the event axis (**N=15**, 7 mechanically observable, covered **0/7**; `network` counted 10 statements / 9 distinct conditions / 5 countable / 0 instrumented / **2 already triggered**). Positive control: `goss-offsite-health.yaml.j2:515` proves the repo knows how to annotate. **This row did not exist until the sixth run** | ENUMERATED |
| C111 | **An assertion whose expected value is regenerated from the same declaration that produces the state it observes** — so it mirrors the estate's state rather than its intent, and cannot detect a weakening | **MINTED 2026-09-19 (sixth run), key `oracle`, shape (b).** Space: the four generated specs. `/etc/goss/posture.yaml` = **226 named checks** (goss's plan count is 406 — each `stdout:` pattern counts separately; do not conflate them). **108/226 independent, 115/226 mirroring, 3 hand-lists**; of 171 per-container checks, 64 carry independent intent and **107 mirror compose**. Measured on the deployed file by the main session: **9 of 32 `-read-only-rootfs` assert `/^false$/`**, plus 2 `-no-new-privileges` asserting `false` and 16 `-cap-add` asserting a set — **27 checks that can only turn red if somebody HARDENS a service**. Two agents converged from opposite ends: `security` read the derivation as a virtue (C11 DERIVED, 9/9), `ansible-deploy` as a fault (11 checks sit in `{% if %}` and CEASE TO EXIST with their declaration, 226 -> 225, nothing asserting the count). **Both are right; the tension is the class.** **The "easy fix" does NOT exist** — emitting the complement was tried on 2026-09-05 and reverted, reasoning at `goss-posture.yaml.j2:548-560` (`Config.User` carries the IMAGE's user; socket-proxy `root`, collabora `1001`). The remedy is an INTENT DECLARATION separate from the configuration, the pattern already shipped for sshd/sysctl/postfix/ufw | ENUMERATED, remedy outstanding |
| C112 | **A guarantee whose ENFORCER sits outside every host the estate can run a command on, where the apparently-covering assertion is bound to an internal proxy and stays green through the enforcer's failure** | **MINTED 2026-09-19 (sixth run), key `oracle`, shape (e) applied to authority.** Space rule: per guarantee in `docs/` and the ADRs, name the enforcer and keep the off-estate ones. **5 in network — 2 unfalsifiable, 1 partial, 2 falsifiable.** Unfalsifiable: the router's forward table in the NEGATIVE direction (`ufw-enforces-every-rule-the-inventory-declares` is ALLOW-only and 80/443/53 are already in its ALLOW set, so a router reset republishing them stays green), and the Cloudflare zone (DDNS looks up one name, nothing enumerates). **Counterweight recorded because it bounds the damage: the POSITIVE direction IS falsifiable** — the offsite's only channel is the tunnel, so a lost opening reddens Kuma #18 in ~25 h. **The estate can see a lost opening and never an added one.** This is the generalisation of C32's attendance and explains why C32 never closed. Whole-estate cardinal NOT derived — bounded in network only | ENUMERATED in network, space open elsewhere |
| C113 | **A control whose FUNCTION is to refuse, whose only deployed verification exercises it in the direction where it ADMITS** — so the predicate is satisfied as fully by "it works" as by "it is gone" | **MINTED 2026-09-19 (seventh run). OPEN — bounded to 4 in `network`, overflows into `security`, whole-estate cardinal NOT derived.** Two instances on two independent mechanisms. `vpn-only`: its 3 deployed assertions all pass if the middleware disappears (`!= 403` x2, a `grep` of the FILE x1); the deny direction WAS reproduced live, against the register's own C30 row which says it no longer can be — `docker exec netdata curl --resolve ...:172.20.0.3` returns **403, 9 bytes, "Forbidden"**, with an admitted source returning 200 as the control. Pi-hole: 6 assertions cover provisioning (gravity 79 963, adlist status, freshness, the dnsproxy namespace) and `grep -c "blocking.active\|0.0.0.0"` on the deployed spec returns **0**, so `dns.blocking.active=false` leaves everything green. Converged on from the other side by `security`, which measured the Traefik allowlist guarded by 3 assertions all in the "wide enough" direction and **0** in the "not too wide" one. Remedies NOT shipped | **ENUMERATED 2026-09-20 (eighth run) by two complementary bounds, 16/16 and 197/197; remedies DECLINED the same day. This row still read OPEN until the ninth run corrected it.** |
| C114 | **A documentary enumeration of a live, machine-derivable set, verified only in the direction `{listed} subset-of {live}`** | **MINTED 2026-09-19 (seventh run), ENUMERATED 13/13** — 5 clean, 8 with a gap, **28 live objects absent from the table that enumerates their kind**. A month of documentary sweeps had measured nothing else: 113/113 links, 65/65 runbook paths, 18/18 cited units, 34/34 rendered artefacts, 80/80 bind mounts, 116 ADR promises — every one an inclusion. Not C01 (an omission is not a contradiction), not C32, not C111 (these tables regenerate from nothing). The sharpest instance is also a lesson about method: `homelab-image-retention` is absent from the "16 periodic jobs" census **because that census walks the evidence channels**, so a job with no channel cannot appear in it — the same shape that reopened C10 and that produced C18's axis defect. Shipped: the three missing secrets, the five wg-easy sites, the retention job in two places, 3 ADR citations, subdomains 18 -> 21, phases 5 -> 6, the RAM budget, and the sidecars named as having no page | ENUMERATED |
| C115 | **A recovery procedure whose success criterion is that its last command completed, with no stated expected RESULT** | **MINTED 2026-09-19 (seventh run), ENUMERATED 19/19.** PROPOSED by the sixth run and correctly not claimed then — the space was one file of ~17 runbooks. `backup` bounded it: **19 executable procedures** (11 in `restore-from-backup.md`, 4 service pages of 18 sections, LUKS, offsite recovery, compose, the Kuma repair). **11 of 19 carry no post-restore check at all**, Vaultwarden among them, and **2 of 19 state an expected value** — correcting the sixth run's "0 of 11", since Immich states one (66 tables, 9 283 assets). The asymmetry measured in both directions: 46 named assertions by failure mode on the WRITE path, 2 written expectations on the READ path. The values already exist — the 2026-08-15 drill recorded 591 ciphers, 168 tables, 1 repo/1 user — and are never carried into the procedures. **Remedy NOT shipped**: documentary, no timed drill, no script | ENUMERATED |
| C116 | **A detector whose only delivery channel terminates inside the subject it detects** | **MINTED 2026-09-20 (eighth run), key `independence`, shape (c). DECLINED by the operator the same day — "je m'en fiche complètement", never raise again.** Space: per alerting path, the components a verdict must traverse ∩ the subjects that path covers. Remediable cardinal **1**. Netdata instantiates `homelab_container_down` on uptime-kuma; its only consumer is `homelab-netdata-kuma.sh:364` pushing to Kuma. Main session verified the last link with a control: `/etc/netdata/health_alarm_notify.conf` does not exist, the stock file carries `SEND_DISCORD="YES"` with `DISCORD_WEBHOOK_URL=""` and `DEFAULT_RECIPIENT_DISCORD=""` (control: the same grep matches 30 `SEND_*` lines), Kuma holds 1 notification row bound to 37 monitors, and `grep -c uptime-kuma /usr/local/bin/homelab-health.sh` = 0. A single failure of uptime-kuma defeats that alarm's delivery, all 15 push reporters, **both gated fuses C41 and C03-T**, Kuma's 22 probes and the single Discord notification. Bounded by heal every 2 min. **NOT to be confused with "60 netdata alarms can reach nobody", measured and rejected in the sixth run** — the adapter IS the path; what is new is that the path terminates in the subject | **DECLINED** |
| C117 | **A declared credential separation where each credential is stored inside the store the other protects** | **MINTED 2026-09-20 (eighth run), key `independence`. DECLINED by the operator the same day** — an independent offline copy exists outside the estate, so the residual risk is accepted; never raise again. ADR-010:37 claimed "Homelab repo password is useless against the offsite repo, and vice versa". The two values are genuinely distinct (hash-compared, env == file on both). But `/mnt/data/secrets` is a backup `source:` (deployed `/opt/homelab/resticprofile.yaml:240`) with no exclude covering it, and the profile's second `ExecStart` copies those snapshots offsite, so the property holds in both directions. Availability untouched — append-only still refuses deletes; what was void is the blast-radius claim. **The documentary half WAS shipped**: ADR-010's row now reads "NOT a blast-radius guarantee", with the reasoning and a generic recommendation to keep an offline copy, cross-referencing the LUKS header runbook which already argues the identical circular dependency. **Main-session note: the session contradicted the agent here and was WRONG** — it read the `source:` block to line 215 when the block runs to 241 | **DECLINED**, documentary half shipped |
| C118 | **A guard that demands a value and a fallback that supplies one, sitting in the same resolution chain — so the guard can never observe the absence it exists to detect, and the fallback propagates into both the configuration and the assertion that would check it** | **MINTED 2026-09-20 (eighth run), key `independence`, shapes (e)+(d). DECLINED by the operator the same day** on the ground that coherence is what matters and a port number is weak security either way; never raise again. Adjacency to C29 was declared by the minting agent rather than hidden. Space: 99 `required: true` options over 11 `meta/argument_specs.yml`; 0 defeated by a role default (no role has `defaults/main.yml`), 69/99 pre-satisfied by a committed inventory file, **5 whose committed fallback is a value no host should run with** — `domain: example.com`, `ssh_port_hardened: 22`, `traefik_acme_email: ''`, `hostname: homelab`, `extra_fsck_filesystems: []`. Joint defeat measured on the guard branch (synthetic role: with the fallback `ok=2 changed=0 failed=0`; delete the fallback only -> `fatal: missing required arguments`) and traced on the other four consumers: `ssh.yml:11`, `firewall.yml:122/134/146`, `fail2ban.yml:180`, `goss-posture.yaml.j2:1569` — which asserts the variable it just rendered. **LATENT, never live**: the deployed spec asserts the vaulted port and the daemon listens on it, not on 22. **The sharpest part is documentary and survives the decline**: `group_vars/all.yml:8-16` argues in four sentences that `homelab_ip` gets no default, citing C29 by name — and line 20 is `ssh_port_hardened: 22` | **DECLINED** |
| C119 | **A detector whose own act is a member of the set it examines** — so it can read its own trace as data, and its verdict is in part a measurement of itself | **LEFT THIS TABLE — ENUMERATED 2026-09-21 (twelfth run) on its seventh and last plane, `ansible-deploy` 31/31 by (spec, artefact) pairs. Read the twelfth run's section, not this row.** Until 2026-09-21 this row carried the NINTH run's state ("swept 5, the space is NOT bounded") while the OPEN table carried the eleventh's, so an agent reading the row re-derived work already done. |
| C120 | **A guard whose trip point sits at the wrong distance from the rupture it guards** — either OUTSIDE the range the guarded quantity can occupy, so the guard is decorative while appearing armed, or SHORTER than the work the mechanism explicitly permits itself | **LEFT THIS TABLE — ENUMERATED 2026-09-21 (twelfth run)** on the route this register named, six domains, with the provoked-measurement residual declared rather than swept. Read the twelfth run's section, not this row. |

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

**Added by the operator's arbitration of 2026-09-02**, all with the instruction
that they never be proposed again:

- **The Docker daemon stall of 2026-09-01** — 146 daemon-level healthcheck
  timeouts in one episode, 18 more on 08-25, an ~11.5 h Kuma push blackout, cause
  never established. Not to be investigated.
- **`killswitch.service` cannot reach `failed`** — `Restart=always` +
  `RestartUSec=10s` against `StartLimitIntervalUSec=10s`/`Burst=5`, and the unit
  is in no goss spec. Sole remote-poweroff mechanism.
- **The offsite restore that cannot fit** — `offsite-backup.md:189`, ~353 GiB into
  221 GiB free, unconditional ENOSPC on the disaster path. Half of C63, the other
  half having been fixed by `241d504`.
- **C29's vacuous liveness half** — the redactor's PID 1 is `sh`, `pgrep` matches
  its own static argv even if `tail` dies. The file half works.
- **The offsite root having no fsck assertion** — `offsite.yml` never plays the
  `observability` role, so C17's assertions cannot deploy there.
- **The files hidden under `/mnt/data`** — written while the volume was unmounted,
  masked by the mount.
- **Both intrusive measurements**: bind-mounting `/mnt/data` to measure what the
  mount hides, and provoking a deliberate authentication failure. The second is
  what makes C57 permanently undecidable, and that is accepted.

**Added by the operator's arbitration of 2026-09-19 (fifth run, key `attendance`),
both with the instruction that they never be proposed again:**

- **Asserting that the USB tamper guard is ARMED.** C109's sharpest instance and
  the cheapest remedy the run found — one `file:` line in `goss-units.yaml.j2`.
  The operator's answer was *"je m'en fiche, ne me le propose plus"*. The gap is
  real and stays measured: 0 strict matches across the three goss specs,
  `homelab-health.sh` and all 37 monitors, so a disarm never followed by a
  re-arm silences ADR-008 unboundedly and nothing observes it. **The operator
  carries this knowingly. Do not raise it again.**
- **A derived counter for the posture's scheduled-vs-manual provenance.**
  Produced in 2 places, read by 0 — so "the 430-assertion check runs by itself
  every day" rests on a human eye, demonstrated live on 2026-09-19
  (`LastTriggerUSec` 11:07:08 against `ExecMainStartTimestamp` 14:21:33). The
  operator judged it unimportant. **Do not re-propose.** The register keeps the
  measurement because C103's residual refers to it.

**Added by the operator's arbitration of 2026-09-04:**

- **C77's non-secret slice** — every Jinja interpolation of a NON-secret value
  into a consumer whose grammar gives meaning to its characters. The secret half
  is enumerated 37/37 and its live defect is fixed; the rest is an unbounded read
  of the whole template tree for a class whose only demonstrated cost has been in
  secrets. Closed the way C66's tail was. Do not re-open it without an instance.

**Added by the operator's arbitration of 2026-09-13 (night):**

- **C01 is CLOSED by decision**, the way C57 and C66 were. 72/87 verified and
  11/11 true on the last batch; the remaining 15 are accepted as outside this
  audit's instrument set — 9 are claims about a REFUSAL TO START, 2 were
  reclassified into that set, 4 are out of the space, and the only instrument
  that settles a refusal to start is a start, which rules 5 and 6 forbid.
  **Re-raising requires a NEW FACT** — one of them exercised incidentally in
  normal operation, or a deliberate out-of-band verification commissioned — not
  a new argument. A disposable off-Pi test instance is recorded as a standing,
  discretionary option that would genuinely settle the 9+2; it is explicitly NOT
  audit-scope work and never a blocker.
  *The main session attempted to widen C01's space before putting the decision,
  looking for a sixth kind of referent beyond the five it was bounded to. The
  candidate dissolved on verification — see the rejected leads. That failure is
  part of the evidence for closing.*
- **C03 is SPLIT.** **C03-T**, where the instrument can name its own "unknown",
  is GATED. **C03-R** — the half that is not mechanically decidable in general —
  is closed by decision as a review rule, the way C66's unbounded tail was. Do
  not re-open C03-R without an instance.
- **The `logs.db` siblings stay undumped.** `sonarr/logs.db`, `radarr/logs.db`
  and `prowlarr/logs.db` are outside C18's gate by the same construction that
  makes the class's wrong-axis defect real. They hold the application log, a
  rescan rebuilds nothing anyone needs from them, and the operator's decision is
  that losing them costs history rather than state. **Do not re-propose.** The
  wrong-axis defect itself remains recorded against C18 — it is the class that
  is unfixed, not this instance that is unaddressed.

**Added by the operator's arbitration of 2026-09-13 (evening):**

- **Rotating the Nextcloud database password.** Two unmanaged copies of the live
  value had been in every restic snapshot since 2026-09-01, offsite included.
  The copies were removed; the snapshots are encrypted with a key the operator
  controls, and that is accepted. Do not raise it again.
- **Reclaiming the ~70 GiB pinned by the permanent snapshot group.** The second
  refusal of this cleanup and the first where the figure was right (1.2 GiB on
  2026-08-15, ~70 GiB now). "There is room." A third proposal needs a new
  CONSEQUENCE, not a new number.
- **Moving the `*.example.yml` files out of `host_vars/`** — C93's only live
  instance. The file is the reference and must stay current where it is. The
  residual risk is recorded in C93's row and the operator carries it knowingly.

**C76** is on this list in effect rather than in form: it was minted and
enumerated on 2026-09-02 and no action was requested on it.

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
