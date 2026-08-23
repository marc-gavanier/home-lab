# ADR-032 — The posture assertions become a generated goss spec

- **Status**: accepted
- **Date**: 2026-08-23
- **Supersedes**: nothing. Continues ADR-030.

## Context

`homelab-posture.sh` had grown to 444 lines. It asserted the container security
posture daily: no container privileged, `cap_drop: ALL` everywhere, the exact
capability set each service is allowed to add back, read-only rootfs where
declared, `no-new-privileges`, the `user:` a container runs as, netdata's
AppArmor profile as the kernel actually applied it, the fail2ban jails, and the
modes of the credential stores.

Every one of those is a comparison between what `compose.yaml` declares and what
`docker inspect` reports. In shell that is a loop, a `case`, a variable per
axis, and an array of problem strings — and the loop has to be read in full
before you can answer "is this container's capability set asserted?".

The question that started this was the operator's, and it was the right one:

> je me demande si le maintien d'un yaml déclaratif n'est pas plus simple qu'un
> algo à maintenir

It is. But the honest answer needed measuring rather than asserting, because the
same reasoning produced 444 lines of shell one commit at a time.

## Decision

**Generate a goss spec from `compose.yaml`, and keep in shell only what goss
cannot express.**

goss reads a YAML file of assertions and reports TAP. The spec is not written by
hand — it is an Ansible template that walks `compose.yaml` and emits one
assertion per service per axis. So the source of truth stays the compose file,
exactly as in the script, and the expected values cannot drift from the declared
ones because they are the same text.

`homelab-posture.sh` runs goss first and folds its `not ok` lines into its own
problem list, then adds the checks goss has no vocabulary for.

### What stays in shell, and why

Four things, and they are not leftovers:

| Check | Why goss cannot express it |
|---|---|
| Bind-mount writability | Needs the container's uid **and** the source directory's owner, resolved against each other. A comparison between two runtime lookups, not a value to match. |
| Vaultwarden `config.json` vs compose | Reads a JSON file inside a volume and diffs its keys against the environment. Set comparison, not assertion. |
| Database credential probes | Opens the database with the secret at `/run/secrets/…` to prove the secret still works. An action with a side effect, which is the point — see the rotate-a-secret runbook. |
| Miniflux connection string | Parses a DSN and compares one field against a separate secret. |

These are the checks that catch #190-class defects — the ones where every
individual value is correct and the relationship between them is wrong. A
declarative matcher has nothing to say about a relationship.

### The install

goss 0.4.10, arm64, pinned, with the checksum taken from the project's own
`SHA256SUMS` rather than computed from the downloaded artefact — a self-computed
digest pins whatever you happened to receive, which proves nothing about what
was published. The spec is installed `0400 root`: it names every container's
expected capability set and the modes of the credential stores, which is a map
of where the secrets are and how they are protected.

## Consequences

- `homelab-posture.sh`: **444 → 256 lines**. The spec that replaces the
  difference is a **149-line template** that generates **824 lines** of
  assertions for this host — the ratio is the point, since those 824 lines are
  generated, reviewed as a diff, and never edited.
- **Measured on the real host before any of it was committed**: 326 assertions,
  0 failures, 8.2 s. The spec has changed by one assertion since that run (see
  below) and will be re-measured on the first deploy.
- The per-container coverage counter is gone and not missed. It existed because
  a shell loop can silently skip a container; goss fails the specific assertion
  for the specific container instead of reporting "checked 26 of 28".
- Every assertion of the original was traced to its destination before the old
  code was deleted — 9 kept in the script, 17 moved into the spec, 1 replaced.
  That audit is what caught the two defects below.

### Two defects the migration itself introduced, both caught before deploying

- **`exists: true` on the dump directory.** The script wrapped that check in
  `if [ -d "$dumpdir" ]`, because resticprofile's `run-after` removes the
  directory once the snapshot holds it. Translating a conditional into an
  existence assertion inverted its meaning and would have reported a problem
  every day the backup succeeded. Now a command assertion accepting
  `700 or absent`.
- **`/etc/goss` was never created.** `template` does not create parent
  directories. The deploy would have failed outright — hidden until then because
  every earlier validation copied the spec into `/tmp` by hand.

Both are the same lesson in different clothes: a check that has been *moved* is
not a check that has been *verified*.

## Alternatives considered

- **Leaving the script alone.** It worked. Rejected for the reason ADR-030 gives:
  it is 444 lines of code with no tests, asserting things a maintained tool
  asserts declaratively, and each audit added more.
- **InSpec / Chef Compliance.** More expressive, and it would have covered the
  four shell checks. Rejected on weight: a Ruby runtime and a profile structure
  on a Pi that runs one host's worth of checks, to replace a file goss reads in
  8 seconds.
- **Writing the spec by hand instead of generating it.** This is the tempting
  one, and it is what makes the YAML "simpler to maintain" in the abstract.
  Rejected because it duplicates `compose.yaml`: adding a capability to a service
  would then need editing in two places, and the failure mode of forgetting the
  second is an assertion that quietly agrees with reality.

## Related

- ADR-030 — configure the installed tools instead of writing the glue
- ADR-031 — resticprofile, the same move applied to the backup scripts
- Issue #33 — the daily posture check
