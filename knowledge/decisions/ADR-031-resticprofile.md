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
  lines** become roughly **296** — the dumps and their assertions — plus about
  50 lines of declarative configuration. Around **420 lines removed**.
- **The assertions are kept deliberately**, and this ADR is where that is
  recorded, so a later reader does not mistake them for glue that was missed.
  resticprofile has no equivalent; they are what #190 left behind.
- The migration is staged, and nothing is deleted before it is observed:
  1. install resticprofile and its profile, change nothing else;
  2. run it by hand against the real repository, and **restore from the result**;
  3. only then point the timer at it;
  4. only then remove the sections it replaced.
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
