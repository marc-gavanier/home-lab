# Settled

Living document. Paste it into every agent brief, and update it after every run
— both what got fixed and what was declined. Its whole value is being current:
an agent that re-proposes something already turned down burns the report's
credibility along with its own budget.

Two kinds of entry, and the distinction matters:

- **Declined** — the operator considered it and said no. Not an oversight, not
  an opening for a better-argued version. Do not raise it again. If a later
  change makes the underlying gap materially worse, state the new fact; do not
  repeat the old proposal.
- **Measured and rejected** — it was investigated and the numbers killed it.
  Re-raising it requires new numbers, not new enthusiasm.

---

## Declined — hardening

Live kernel patching, an IPS/reputation layer, a forward-auth SSO portal, user
namespace remapping, and the kernel audit daemon. All assessed, all declined.

The remaining containers with an elevated capability, and the remaining
writable root filesystems, are **structural** — they were examined one by one
and cannot be removed without breaking the service. Do not re-report them as
findings.

Additional fail2ban jails for recently added web forms: rejected after
measurement — the existing jails show zero failures and zero bans since they
were deployed.

## Declined — supervision

- **External supervision of the main host.** Every dead-man's switch terminates
  in a push monitor running on the very machine it watches. The gap is real,
  confirmed, and the operator does not want it closed that way.
- **A timed restore drill.** The existing drill record stands as it is.
- **Drift detection between the two hosts.** They are provisioned by different
  roles and nothing checks that the second keeps up. Verdict: too little
  configuration involved to be worth machinery.

## Declined — backup scope

- **Dumping the media services' metadata databases.** They hold play counts,
  watch and reading progress, shelves and query history — a rescan rebuilds all
  of it. The media files themselves are covered, which is what matters. This is
  a decision, not an oversight: do not re-audit it.

## Measured and rejected

- **Expiring the frozen snapshots left by obsolete path sets.** Grouping the
  retention policy by host would drop them, but deduplication already shares
  their chunks: 1.218 GiB of 343, i.e. 0.35 %. Not worth a repository-wide
  prune, still less on the append-only offsite copy.
- **Memory limits on containers.** The absence is real. Adding them would
  create an OOM kill that does not exist today: working set is well under
  capacity and memory pressure sits near zero over a fortnight.
- **The DNS-over-HTTPS connection investigation.** Closed with no action — the
  upstream retires connections on a timer, and every per-query rate computed
  during the investigation turned out to be an artefact. Do not reopen.

## Tooling constraints, not preferences

- Uptime Kuma is **v2**. The widely cited automation tooling is v1-only and does
  not speak v2; monitors are entered by hand in the web UI. Do not propose it.
- **No git worktrees.** Work in the operator's directory, on their branch, and
  announce any branch switch — a checkout changes what their next deploy ships.
- The photo service's version pins are explicit and deliberate; its migration
  is one-way. Do not propose bumping components independently.

## Deferred, not declined

- **Marking the internal container network as internal.** Correct in principle;
  two services currently reach out through it and would break. A real piece of
  work to be scoped, not a quick fix, and not an audit finding to repeat.

---

## Findings from the run of 2026-08-15

Kept here so the next run can verify them **gone** rather than rediscover them.
Move each to a settled section once resolved, or delete it once confirmed fixed
and verified in a later sweep.

**Read the third column before believing the second.** Merged is not deployed and
deployed is not proven — that distinction is the entire reason this file exists.
Something can be correct in `main`, absent from the machine, and still look fixed
in a commit log.

| Finding | Status | Proven how |
|---|---|---|
| Alerting stack runs its rules with no recipient configured — nothing is delivered | **settled** — left recipient-less on purpose, its stock thresholds being tuned for a generic server; the signal worth acting on moved to the health push instead. Do not re-report the absent recipient as a finding. | decision, nothing to prove |
| Health script pushed to monitoring carries no memory or swap signal | **fixed in main, NOT DEPLOYED** as of 23:20 — available-memory alarm on two consecutive runs, swap reported and alarmed only above its threshold | not yet: the live script predates the change and its push still carries no `mem`/`swap` field. Check the message, not the file. |
| Git service running with the upstream default encryption key | **fixed and deployed** — key delivered through a URI-mounted secret, empty values now refused by an assertion | config in place and readable; that the URI wins over the empty verbatim key is **not** established — it becomes free to check the day 2FA is enabled |
| Restore runbook uses a container name where the orchestrator expects a service name — the command fails and the next step deletes a database directory | **fixed** | service names checked against compose, and the same error class swept for elsewhere with a dry run |
| Documented network perimeter wrong in both directions | **fixed** — corrected everywhere, including the instructions the security agent itself reads | probed from an off-network uplink with a known-open control |
| A failed database dump degrades to a warning, leaves the exit code untouched, and its trace is deleted | **fixed and deployed** | assertion logic tested against ok/truncated/missing fixtures; **the first real nightly run is still pending** |
| Cloud service log grew to ~91 MB, effectively all one repeated client-side exception | **root cause found and capped** — a mobile client leaves a permanent file lock; the shipped cleanup was disabled by its own default. Runbook written. Caps the damage at ~72 min, does not prevent the lock. | reproduced deliberately end to end, then the cleanup was observed removing a backdated lock |
| Dead configuration knob holding a plausible value that nothing reads | **fixed** | single occurrence in the repo, read nowhere |
| Example override file missing two keys, one of which guards seven tasks | **fixed** | key sets compared in both directions |
| Orphaned anonymous volume left by a first container start | **open** — cosmetic, ~48 MB. Remove by hand; never with a broad prune, the other anonymous volumes are legitimate | — |
| Comment asserting the host "almost never swaps", contradicted by measurement | **fixed** | — |
| `mkswap` running unguarded with its failure suppressed | **fixed and deployed** | the swap file was recreated and activated, which only succeeds on a real `mkswap` |

A fix is not proof. The next sweep must confirm each "fixed" line **behaves**, not
merely that the code changed. That is the whole difference this skill exists to
enforce, and the run of 2026-08-15 supplied its own illustration: three of these
were merged and never deployed until someone read the live artefact rather than
the commit log. One of them — the memory signal — was still missing from the
machine hours after its PR landed, and only the *content of a push message* showed
it. A green deploy proves the play ran, not that the change reached anything.

Three things are owed to the next sweep specifically:

1. **The memory and swap fields in the health push.** If the message still reads
   `cpu …, / …%, /mnt/data …%` with no `mem`, the role was never deployed.
2. **The dump assertions firing on a real nightly run** — the logic was tested
   against fixtures, never against the 03:00 job.
3. **The digest's monitoring message carrying real counts** rather than a constant.

One deliberate loose end, so it is revisited rather than re-reported. The swap
file was doubled and an occupancy alarm added at **85 %**, and that percentage is
an inference, not a measurement — every observation available was capped by the
previous size. It is the one threshold in the health script without history
behind it. A later sweep should check the settled occupancy against it and say
whether it wants raising; finding it un-calibrated is expected, not a finding.

Also settled during that run, and **not** to be re-raised: the eleven empty-default
push URLs were all verified populated; the non-empty defaults were verified not to
be overriding the operator's values; and the monitoring push defect found that day
was confirmed not to repeat in any of the sibling scripts.
