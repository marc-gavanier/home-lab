# ADR-037 — An availability target, so reliability work has a reason to stop

**Status**: accepted — 2026-09-21
**Related**: ADR-030 (configure the tools, do not write the glue), ADR-032 (the
goss posture spec), ADR-008 (USB tamper response)

## Context

Between 2026-08-15 and 2026-09-21 the full audit ran 31 times, 13 of them in
the four days ending this morning. Each run fans eight agents over both hosts;
the last one alone cost 1.65 million tokens in subagents. The work was not
wasted — the estate is measurably better and the severity of what is found has
collapsed — but three facts taken together say the process had no brake:

- **The count of live defects per run is flat.** Over the nine runs where the
  register lists them separately: 6, 9, 7, 7, 0, 3, 3, 6, 6. Nine runs, nine
  different search keys, and the line does not descend. Each new key looks
  along an axis the previous ones had no word for, so the supply does not run
  out.
- **Three stopping rules were written in one evening and two were unreachable.**
  The first needed two consecutive runs minting no new defect class: 4
  occurrences in 31 runs, never consecutive, with an expected wait of 25 to 70
  further runs. The second needed two consecutive runs finding nothing a
  deployed instrument already reported: 0 occurrences in 31, strictly harder
  than the rule it replaced.
- **Nothing in this repository said what "working" means.** Every service had
  monitors; no service had a target. Without a target there is no state in
  which the correct action is to do nothing, so the honest answer to "is there
  anything left?" was always yes.

The SRE literature is direct about all three. A service should be *reliable
enough, but no more reliable than it needs to be*, because the cost of each
increment is not linear — *an incremental improvement in reliability may cost
100x more than the previous increment*. And an objective that cannot be held
*without Herculean effort, excessive toil, and burnout* is an objective to be
relaxed, not an effort to be increased. Thirteen audits in four nights is the
case that rule was written for.

## Decision

Five rules. The first two are new; the last three redirect work that already
happens.

### 1. Four availability targets, in terms of what the household notices

**99 % per calendar month, per service**, on the services someone in the house
would complain about:

| Service | Why it is on the list |
|---|---|
| Pi-hole DNS + split-DNS | Nothing in the house resolves without it |
| Nextcloud | Files and Obsidian notes, on every device |
| Immich | Photo ingest from the phones |
| Jellyfin | The television |

99 % is about 7 h 12 min per month. It is deliberately loose. This is a single
Raspberry Pi with no redundancy, no second operator and no on-call rotation,
and the encrypted volume needs a manual unlock after every reboot — a tighter
target would be consumed most months by ordinary operation, which would mean
the audit runs permanently, which is the situation this ADR exists to end.

**Everything else is not on the list, and that is the point.** Vaultwarden,
Navidrome, the \*arr stack, Forgejo, SearXNG, Calibre-Web, the monitoring
itself: they are watched, they are fixed when they break, and their uptime does
not license or forbid any work.

### 2. The budget decides whether reliability work happens

The gap between 99 % and the month's measured availability is the budget.

- **Budget intact on all four → no audit, no hardening, no new assertions.**
  This is the rule's whole purpose: it makes "do nothing" a defensible answer
  with a number behind it.
- **Budget spent on any of the four → that service is what the next run looks
  at**, and the search key is whatever broke it.

### 3. No fix without its gate

A correction is not finished when the defect is gone. It is finished when
either an assertion exists that fails if the property returns, **or** the
absence of one is written down as accepted.

This is not a new idea here — it is the register's own distinction between a
class that is ENUMERATED and one that is GATED — but it was not being applied.
The weekend of 2026-09-18 to 09-21 fixed some sixty things, deployed 14 new
assertions, made 4 of them fail on purpose, and moved **zero** classes into the
GATED state. The drift-detection literature says the same thing in its own
vocabulary: pairing detection with guardrails is what stops you chasing the
same issues in a loop.

### 4. Incidents choose the search key

The audit's method stays; what triggers it changes. When something breaks, ask
what class of defect it belonged to and sweep that class. The class register
stays as a taxonomy. **The ambition to complete it stops** — that is a research
goal, and the mint-rate data above shows it is unbounded.

An audit is still run on a fixed cadence (below) and after a structural change:
a new service, an OS upgrade, a disk replacement.

### 5. Alerting is pruned to what requires a decision

*Every page should be actionable*, and *over-monitoring is a harder problem to
solve than under-monitoring*. There are 37 Kuma monitors and 66 netdata alarm
names for one person. The prune itself is not done here; the rule that governs
it is: anything that fires must require a judgement. Everything else belongs on
a dashboard.

## Cadence

Monthly, plus on a spent budget, plus after a structural change. Not on demand,
and not thirteen times in a weekend.

## The measurement already exists

No new mechanism, per ADR-030. Uptime Kuma's `stat_daily` table holds the
per-monitor daily up/down counts, so a month of availability is one read-only
query against the live database:

```sql
select m.name, round(100.0*sum(s.up)/(sum(s.up)+sum(s.down)), 3)
from monitor m join stat_daily s on s.monitor_id = m.id
where m.active = 1 and s.timestamp > strftime('%s','now','-30 days')
group by m.id;
```

**Measured 2026-09-21, over 30 days:**

| Service | Availability | Against a 99 % target |
|---|---|---|
| Traefik HTTPS | 99.976 % | intact |
| Pi-hole DNS + split-DNS | 99.973 % | intact |
| WireGuard | 99.952 % | intact |
| Navidrome | 99.952 % | intact |
| Vaultwarden | 99.937 % | intact |
| Jellyfin | 99.858 % | intact |
| Immich | 99.460 % | 54 % consumed |
| **Nextcloud** | **98.882 %** | **spent** |

Seven of eight are comfortably inside the budget on the day the target was
written. **One is not**, and the policy names it in a single query — which
thirteen audit runs, all of them looking elsewhere, never did.

Two caveats on that figure, so it is not read as more than it is. The first
question for Nextcloud is whether the 1.1 % was planned work — it was upgraded
34 → 35 on 2026-09-19 and recreated several times since — because planned
maintenance is not an outage, and the SRE literature treats maintenance windows
as budget spent deliberately rather than as failure. The second is that a
monitor reads DOWN when Kuma itself restarts, which is a property the register
records as C41; a month's figure has to exclude those before it decides
anything.

## What was considered and not adopted

- **A tighter target (99.5 % or 99.9 %).** 99.9 % is 44 minutes a month, which
  single hardware with a manual unlock step will not hold; it would put the
  audit back into permanent session under a new name.
- **No target at all, keeping only the severity floor** written the same
  evening (two consecutive runs finding nothing that would cost data,
  availability or a secret). That rule stays and is complementary — it governs
  when the *cadence* changes. But without a number there is no measurable right
  to do nothing, and the decision to audit reverts to a feeling, which is what
  produced thirteen runs in four days.
- **Per-container targets.** The list is four services because four is what the
  house notices. A target on `socket-proxy` measures nothing anyone experiences.

## Consequences

- **The audit's trigger moves from suspicion to measurement.** "Is there
  anything left to fix?" now has a query behind it instead of a hunt.
- **Nextcloud is the first subject under the new rule**, and the first question
  about it is a measurement (planned versus unplanned), not a sweep.
- **Some defects will now live longer.** A thing below the severity floor, in a
  month where all four budgets are intact, waits for the monthly run. That is
  the trade being made deliberately: the estate has been kept at a standard
  that costs more per night than the failures it prevents.
- **The class register keeps its value and loses its deadline.** It remains the
  best thing the audit produced — a taxonomy that turns one finding into a
  swept space — and it stops being something to complete.
- **Rule 3 changes what "done" means for every future fix**, including the ones
  already carried as accepted-without-a-gate. Those are not retrofitted; they
  are recorded where they are.
