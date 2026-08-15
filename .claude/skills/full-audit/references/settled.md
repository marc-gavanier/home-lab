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

| Finding | Status |
|---|---|
| Alerting stack runs its rules with no recipient configured — nothing is delivered | **settled**: left recipient-less on purpose, its stock thresholds being tuned for a generic server; the signal worth acting on moved to the health push instead, and the docs now say so. Do not re-report the absent recipient as a finding. |
| Health script pushed to monitoring carries no memory or swap signal | **fixed** — available-memory alarm on two consecutive runs, swap reported and deliberately not alarmed on |
| Git service running with the upstream default encryption key (no 2FA, tokens or webhooks exist yet, so exposure is nil today; a key rotation is impossible later) | open |
| Restore runbook uses a container name where the orchestrator expects a service name — the command fails and the next step deletes a database directory | **fixed** |
| Documented network perimeter is wrong in both directions: two ports documented as forwarded are not, and the one port actually reachable is documented nowhere | open |
| A failed database dump degrades to a warning, leaves the exit code untouched, and its trace is deleted | **fixed** — presence and size floor asserted before the snapshot, staleness guard for the service that backs itself up, verdict deferred so a bad dump does not cost the rest of the backup |
| Cloud service log grew to ~91 MB, effectively all one repeated client-side exception | open — client-side, the operator's call |
| Dead configuration knob holding a plausible value that nothing reads | **fixed** |
| Example override file missing two keys, one of which guards seven tasks | **fixed** |
| Orphaned anonymous volume left by a first container start | open — cosmetic, remove by hand; never with a broad prune, the other anonymous volumes are legitimate |
| Comment asserting the host "almost never swaps", contradicted by measurement | **fixed** |
| `mkswap` running unguarded with its failure suppressed | **fixed** — gated on the swap file's prior absence |

A fix is not proof. The next sweep must confirm each "fixed" line **behaves**, not
merely that the code changed: the dump assertions have to be seen firing on a real
nightly run, and the memory signal seen in an actual push message. That is the
whole difference this skill exists to enforce.

Also settled during that run, and **not** to be re-raised: the eleven empty-default
push URLs were all verified populated; the non-empty defaults were verified not to
be overriding the operator's values; and the monitoring push defect found that day
was confirmed not to repeat in any of the sibling scripts.
