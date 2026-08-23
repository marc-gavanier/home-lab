# ADR-031 — resticprofile replaces the orchestration half of backup.sh

**Date**: 2026-08-23
**Status**: accepted — proven in a sandbox that touched nothing; migration
staged, and nothing is removed from `backup.sh` before a real backup AND a real
restore have been observed on the machine.

## Context

ADR-030 set the direction — configure the installed tools instead of writing the
glue — and deferred `backup.sh` explicitly, because it sits on the restore path
and deserved its own decision. This is that decision.

`backup.sh` is 594 lines, and the audits have found real defects in it: #190
(the Immich dump guard asserted a directory instead of its content), #198 and
#199 (credentials on the process table, then the copies the sweep missed). It is
the single most defect-producing file in the repository, and it is the one whose
failure costs the most.

But it is not one thing. Measured section by section:

| Section | Lines | Nature |
|-----------------------------------|-------|--------------------------------|
| restic backup, offsite copy, retention, cleanup | ~250 | **orchestration** |
| database dumps (26 application commands) | 96 | application-specific |
| **dump assertions** | **170** | **home-grown quality control** |

Only the first is orchestration. The second is application knowledge no tool
has. The third exists *because* of the audits — it is what turned "the dump file
is present" into "the dump file opens and contains what it should", and
replacing it would be a regression, not a migration.

## Decision

**resticprofile takes the orchestration. The dumps and their assertions stay,
and move into a script of their own invoked as a pre-backup hook.**

`local-maintenance.sh` (72 lines, weekly prune + check) and `offsite-check.sh`
(51 lines, weekly offsite check) become resticprofile commands.

### What the spike established, before any of this was written

Run entirely in containers against a throwaway repository under `/tmp`. No
production repository was opened.

| Criterion | Result |
|-------------------------------------|--------|
| database dumps as `run-before` hooks | pass — both hooks ran, files created |
| copy to a second repository | pass — destination auto-initialised, snapshot copied |
| retention 7 / 4 / 6 | pass — applied after the backup, exact policy |
| a FAILING backup still notifies | pass — `run-after-fail` and `run-finally` fire, `run-after` does not |
| **restore from the offsite copy** | **pass — byte-identical, and again after a `prune`** |
| systemd timer generation | **not verified** — no systemd in the container |

### Three findings from the spike that shape the implementation

**`restic copy` is idempotent.** A second copy with nothing changed wrote
nothing and left the destination at one snapshot. So `backup.sh`'s "last 7 days"
bound — a `restic snapshots --json` piped into Python to compute snapshot ids —
is an *optimisation*, not a correctness requirement. On an append-only
repository, re-offering a snapshot that is already there is a no-op. That
removes the most convoluted part of the script.

**Passwords must be FILES, not inline values.** With `password:` templated from
the environment, `copy` fails with *"an empty password is not allowed"*: the
source password is not forwarded to the secondary repository. With
`password-file:` it works. This is also the better shape — no secret in the
configuration, and none on the process table, which is the #198 class.

**Repository paths CAN come from the environment.** `{{ .Env.RESTIC_REPOSITORY }}`
resolves, so the existing `backup.env` keeps its role and no path is duplicated
into the configuration.

### A fourth finding, from the first run against the real repository

The spike could not have caught this one, because the sandbox had no equivalent:
**the dump directory only exists during a run.** `backup.sh` does `rm -rf` then
`install -d` at the start and `rm -rf` at the end, so between runs
`/mnt/data/backups/dumps` is simply absent.

Listing it as a source without creating it first makes restic skip it, and the
snapshot then carries FOUR paths instead of five. That is not cosmetic:
`restic forget` groups by `host,paths` by default, so a snapshot with a
different path set forms **its own retention group** and receives its own
7 daily / 4 weekly / 6 monthly. The first real run produced exactly that — a
`keep 1 snapshots` group beside the existing ones.

The repository already carries three such groups from earlier changes to the
source list (secrets added, media added), so the mechanism is not new. What
would have been new is a fourth group created every night by the migration
itself.

The profile now creates the directory in `run-before`. The mkdir belongs to the
profile rather than to the dump script, because it is about what this profile
CLAIMS to back up, not about the dumps.

**This is the argument for the staged migration in one paragraph.** The
sandbox passed six criteria; the first contact with the real repository found a
seventh that none of them covered.

### The copy is no longer bounded to seven days, and that was a decision

`backup.sh` computed the last seven days of snapshot ids and offered only those.
This ADR first called that "an optimisation, not a correctness requirement",
**and that was wrong about the consequence**: the bound did not only make the
copy faster, it defined what the offsite repository contained. Everything older
than a week had simply never been replicated.

The first unbounded copy therefore back-filled **18 snapshots** from May, June
and July, in fifteen minutes rather than the seconds predicted. The offsite
repository went from ~50 to **68 snapshots**, against 33 held locally — the
local one applies retention, the remote one never has.

Kept unbounded, deliberately:

- the cost was **one-off**. `restic copy` is idempotent, so with every local
  snapshot now present remotely, nightly copies return to transferring only the
  new one;
- and it turned out to matter the same day. The run that back-filled the history
  is the run during which the local drive produced its first read error inside
  the repository (#207). Far more of the history now sits off that disk.

**No retention is applied to the offsite repository, and none can be.** It is
append-only by design, so that a compromised homelab cannot erase its own
remote backups. Unbounded growth is the accepted price of that protection, not
an oversight: 346 GB of 1.8 TB at the time of writing, with restic's
deduplication behind it.

### resticprofile does NOT manage the schedule

It can generate systemd units, and that is the one criterion the spike could not
verify. It is also the one we do not want: timers on this host are rendered by
Ansible, and letting a second system write into `/etc/systemd/system` would give
two owners to the same files. `homelab-backup.timer` keeps its place; only the
`ExecStart` of its service changes.

That turns an unverified criterion into one without an object.

### The binary

The `no_self_update` arm64 build, installed by Ansible with the published
checksum. A binary that updates itself on a host whose versions are pinned and
reviewed by Renovate would be a hole in that process, not a convenience.

## Consequences

- `backup.sh` 594 + `local-maintenance.sh` 72 + `offsite-check.sh` 51 = **717
  lines** become **296** — the dumps and their assertions — plus **107** of
  notification adapter and ~210 lines of declarative configuration.

  Measured after the fact, across the whole repository: **3348 shell lines in 22
  files → 3061 in 20** (3050 when this was written, before two later fixes). Less than the 420 predicted here, and the gap is the
  adapter: resticprofile's hooks receive `PROFILE_NAME` and `PROFILE_COMMAND` and
  nothing else — no snapshot id, no summary, no status file — so every message
  worth reading has to be rebuilt outside the tool. That is the honest price of
  this migration, and it is recorded rather than rounded away.
- **The assertions were kept deliberately**, and this ADR is where that was
  recorded, so a later reader would not mistake them for glue that was missed.
  resticprofile has no equivalent; they are what #190 left behind.

  **Superseded 2026-08-24, and the reason is worth keeping visible rather than
  rewriting away.** That sentence was true when written and stale within two
  days: ADR-032 installed goss, whose entire job is expressing assertions
  declaratively. The dump COMMANDS became `run-before` hooks and the assertions
  `/etc/goss/backup-dumps.yaml`, both generated from two lists in group_vars.
  373 lines to 19 named checks.

  The lesson is not about goss. A justification for keeping code names the tool
  that was missing at the time, and **nothing re-reads it when that tool
  arrives**. This one survived a search for what to migrate because it had a
  reason attached; it fell to a search for what to DELETE. Any "no tool
  expresses this" in this repository should be read with its date attached.
- The migration is staged, and nothing is deleted before it is observed:
  1. install resticprofile and its profile, change nothing else;
  2. run it by hand against the real repository, and **restore from the result**;
  3. only then point the timer at it;
  4. only then remove the sections it replaced.

  All four steps are done for the three timers.

- **One monitor for `prune` and `check`, and the ordering is what keeps it
  honest.** The two commands run as two `ExecStart` lines under `Type=oneshot`,
  which stops at the first failure, and resticprofile exits 1 on a failed restic
  command (probed: exit 1, only `run-after-fail` fired). So `prune` carries a
  failure hook only: a failed prune pushes DOWN and `check` never runs to
  overwrite it, while a successful prune stays silent so an hour-long deep check
  cannot leave Kuma claiming the maintenance already finished. The combined
  verdict `local-maintenance.sh` computed in shell now falls out of the ordering.
- **`ConditionPathExists` replaces the "not configured" branch.** `offsite-check.sh`
  opened by testing the repository variable and exiting 0. The offsite password
  file is written only when the vault variable is set, so its absence *is* "not
  configured", and systemd skips the unit instead of failing every Sunday.
- Two new password files under the secrets directory, `0400 root:root`, rendered
  from the vault like every other secret here.

## Alternatives considered

- **autorestic, backrest.** Both are credible wrappers. resticprofile was tried
  because it is the one whose hook model — before, after-success, after-fail,
  finally — maps exactly onto the `trap`-based dead-man's switch `backup.sh`
  already implements. Neither of the others was benchmarked, and if
  resticprofile disappoints in use, that comparison is still open.
- **Leaving `backup.sh` alone.** Defensible on the grounds that it works today.
  Rejected because it is the file the audits keep finding defects in, and
  because ~250 of its lines are a thing a maintained tool does better.
- **Letting resticprofile own the schedule.** Rejected above.

## Related

- ADR-030 — configure the installed tools instead of writing the glue
- ADR-010 — the offsite repository
- Issues #190, #198, #199 — the defects found in `backup.sh`
