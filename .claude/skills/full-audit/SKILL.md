---
name: full-audit
description: Fan the eight domain agents out over the live home lab to find defects that neither code review nor green dashboards reveal. Use when asked whether anything is left to fix, after a round of corrections to confirm the findings are gone, or before trusting a "nothing to do" answer.
---

# Full audit

A read-only sweep in which every domain agent audits its own area against the
**running** systems, writes a report, and hands back a summary that the main
session verifies before relaying anything to the operator.

**The unit of progress is the class, not the finding.** `references/classes.md`
holds the register and the termination criterion; read it before anything else.
A run's job is to close OPEN classes by enumeration and to mint the classes that
are missing — not to return a longer list than last time. Counting findings is
what made nine runs look like an infinite loop; counting classes is what lets
this work end.

## Why this exists, and what it is actually for

On 2026-08-15 the operator asked three times whether anything was left to do.
The backlog was short, every container was up, all twelve timer services had
exited 0, and all thirty-one monitors were green. The honest-looking answer was
"nothing".

It was wrong. The daily digest's dead-man's switch had never worked: its push
was a no-op, so a run that failed would have reported success. Nothing on any
dashboard could show that — the monitor was *present*, the service exited 0, the
note was written every morning. It surfaced only by reading the *content* of a
database table and comparing it against the seven sibling scripts.

The audit that followed found four more of the same kind, the worst being an
alerting stack running fifty-seven alarms with no recipient configured. So the
purpose of this skill is narrow and specific:

> **Find the mechanisms that look like they work and do not.**

Not code smells, not aspirational hardening, not a list of things one *could*
add. Those are worth little here and the operator has already declined most of
them. What pays is the gap between what a mechanism claims and what it does.

## Before launching

1. **Read `references/classes.md` and refresh `references/settled.md`.** The
   register is the mandate: its OPEN table is what this run is for, and its
   GATED and ENUMERATED tables are what no agent should spend budget
   rediscovering. `settled.md` carries the decisions already taken and the
   instrument traps already paid for — without it, roughly half of what comes
   back is a re-proposal of something the operator has already turned down, and
   the report loses their trust.
2. **Snapshot the backlog** — open issues and PRs — and list them in the brief
   so agents do not re-report tracked work.
3. **Take a baseline** of the obvious live state (failed units, container
   states, timer exit codes, monitor statuses). Findings are much easier to rank
   when you already know the surface is clean.

## The shared brief

Every agent gets the same preamble, in the operator's language, with only the
mandate and the domain-specific leads changing. Keep all seven rules — each one
exists because its absence cost something.

```
AUDIT — personal home lab. You are READ-ONLY.

CONTEXT
Repo, branch and layout. Hardware, OS, orchestration. Both hosts are
reachable over SSH with passwordless sudo. The real domain is masked as
example.com in this public repo.

MANDATE — close these classes, or say why their space cannot be bounded.
<the OPEN classes from references/classes.md that live in this domain,
each with its defining property and the space it must be swept over>

Closing a class means: state the cardinal N, sweep N/N, record the count.
A partial sweep does not close anything — it is what kept C01 open for
ten days while three runs sampled it.

If you find something that fits NO existing class, that is a MINT, and it
is worth more than an instance. Write the PROPERTY and the SPACE first,
the instance second.

If your domain has no OPEN class, verify instead that its GATED
assertions still fail when they should — read them, do not test
destructively.

RULES — they matter as much as the mandate.

1. "Nothing to do, everything is correct" is a PERFECTLY VALID and welcome
   conclusion. Do not invent findings to justify your existence. An
   evidenced "clean" beats a speculative list. In the session that
   preceded this one, three leads out of four did not survive measurement.
2. VERIFY AGAINST THE RUNNING SYSTEM, not just the repo. The only real bug
   found that day was invisible to code review: the template looked
   correct, and it took querying runtime state to see that the monitoring
   measured nothing. A purely static audit reproduces that blind spot.
3. MEASURE before calling something worth doing. Quantify the impact. A
   lead worth 1.2 GB is not a lead.
4. DO NOT RE-PROPOSE what has been settled — see references/settled.md
   and the DECLINED, GATED and ENUMERATED tables of
   references/classes.md. Nor anything already tracked in an open issue.
   A finding inside a GATED class is a BROKEN GATE: report it as such,
   not as a discovery.
5. CHANGE NOTHING. No deploys, no writes to the repo, no changes on the
   hosts, no test heartbeats, no operations on the append-only offsite
   repository. Read-only.
6. GO EASY ON THE HARDWARE: no `find /`, no heavy scans — seven other
   agents are working on the same small machine in parallel. Targeted,
   short commands.
7. The repo is PUBLIC: never propose writing a secret, a physical
   location, a storage medium or a port number into it. Your own report
   lives outside the repo, so it may be precise.

DELIVERABLE
Write to <scratchpad>/audit/<domain>.md, in this order:

1. PER CLASS you were given: CLOSED (with N/N and the count) or STILL
   OPEN (with what bounds the space and what stopped you).
2. MINTS: the property, the space, the cardinal if you can state it.
3. INSTANCES, grouped under their class: what it is, the measured
   evidence (command + output), the real impact, what you propose.
   Separate CONFIRMED from SUSPECTED.

If nothing: say so, and list what you checked to establish it. An
evidenced "clean" closes a class; a speculative list closes nothing.
Your final answer: 10 lines maximum, opening with the class verdicts.
The detail goes in the file.
```

## Fan out

Launch all eight in a single message so they run concurrently: `system`,
`security`, `network`, `services`, `backup`, `observability`, `ansible-deploy`,
`project-manager` (the last one audits documentation against reality).

Per-domain scope and angles: `references/domains.md`. **The mandate itself comes
from the register**: assign each OPEN class to the agent that owns its space, and
say so in the brief — "close C01 for your domain, or state why its space cannot
be bounded". An agent with no OPEN class in its area verifies that the GATED
assertions in its area still fail on purpose, which is worth more than a fresh
hunt.

Reports go to the **session scratchpad, never into the repo** — an audit
produces exactly what the public-repo rule forbids publishing. Anything worth
keeping becomes an issue or a doc afterwards, written to be public.

## Verify before relaying — not optional

Agent output is a lead, not a finding. Two failures from the first run, both
worth remembering:

- **An agent reported a container holding 2.01 GiB of swap.** It had summed
  `VmSwap` across the process's PIDs, which double-counts pages shared between
  pre-forked children — the total exceeded the entire swap in use, which is
  arithmetically impossible. The cgroup counter, which counts each page once,
  said 478 MB. Two other agents had independently measured ~480 MB. The
  headline survived; the causal claim built on it did not.
- **The main session's own check was worse.** Verifying that two TCP ports were
  unreachable, it also tested a UDP port with `nc` (meaningless) and included no
  known-open control, so a timeout proved nothing. The re-run with a port known
  to be open settled it in one command.

So: re-measure anything load-bearing yourself, prefer counters that cannot
double-count, and always include a control that proves your instrument works.
Where two agents disagree, the disagreement is the finding — resolve it before
writing a word to the operator.

Treat convergence as signal: when independent agents reach the same conclusion
from different angles, it is usually real.

## Synthesise — the report is a register diff

Open with the counter: **how many classes were OPEN, how many closed, how many
minted, how many remain**. That number is the answer to "is this finished yet",
and it is the only part of the report that is comparable between runs.

Then, and only then, the instances. Rank them by *what is happening right now
without anyone knowing*, then by cost the day it matters, then by cost to fix.
Group them **under their class** rather than by domain — eleven findings under
one class is a far more useful thing to report than eleven unrelated corrections,
and it is what tells the operator to fix the class instead of the instances.

Two things must appear explicitly:

- **What you rejected from the agents and why.** It is what makes the rest
  believable.
- **Every mint, with its property and its space.** A mint is the run's real
  output; an instance is a by-product.

State plainly when a finding lands in a GATED class: that is a broken gate, it
does not belong in the audit's count, and it is reported as a red test.

## After the run

1. **Update `references/classes.md` first** — state transitions, new cardinals,
   new classes. A class reaches GATED only once its assertion has been **made to
   fail on purpose**; anything less is ENUMERATED, and will reopen.
2. Move newly settled decisions and newly paid instrument traps into
   `references/settled.md` — both what got fixed and what the operator declined.
3. **Keep state out of `settled.md`.** Counts, cardinals and "still open" tables
   belong to the register. Every stale number that file has carried has
   propagated straight into the next run's eight agent briefs; it has happened
   three times with the same figure.

## What "finished" looks like

Not "a run that found nothing" — that is unfalsifiable, because what a run finds
depends on the search key it was given, and the key is written fresh every time.
The criterion is in `references/classes.md` and it is this:

> **No OPEN class remains, and two consecutive runs, each using a different
> search key, mint zero new classes.**

The first half says the known perimeter is worked down. The second tests whether
the perimeter itself is complete, which is the only defence against measuring
only what someone already thought to look at.

A pass with no *findings* is still a real and expected outcome — it is the point
of re-running after corrections. It is credible when each report says what was
checked to establish it, when the checks were made against running systems, and
when the previously reported defects are verified gone rather than assumed gone.
A sweep that returns "clean" without that evidence has not been run properly.
