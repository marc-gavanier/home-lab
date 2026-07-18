# ADR-012 — CIS Ubuntu 24.04 benchmark as the audit reference

**Date**: 2026-07-18
**Status**: accepted (deployed and verified on the Pi)

## Context

The homelab had hand-rolled hardening (SSH, UFW, fail2ban, LUKS, cloud-init
redaction, physical-attack-surface work in ADR-008/009) and periodic `lynis`
runs, but no measurement against an external, comprehensive reference. "Are we
missing something?" had no repeatable answer. The CIS Ubuntu 24.04 benchmark
(~300 controls) is that reference, and ansible-lockdown's `UBUNTU24-CIS` role
implements it in Ansible — the ecosystem standard for applying CIS.

The catch: that role is built to **enforce** the benchmark. Run as-is it would
break this host — disable IP forwarding (Docker/WireGuard need it), blacklist
usb-storage (the data disk is USB), require sudo passwords (we lock the account
and go key-only), and more. A generic benchmark cannot be applied blindly to a
deliberately-shaped system.

## Decision

Use the benchmark as a **measuring stick, not an enforcer**.

- `ansible/playbooks/cis-audit.yml` runs the role in **`--check` mode only** —
  an `assert` refuses to run otherwise, so it can read and report but never
  modify. The role is pinned (`requirements.yml`, 1.6.0) and Renovate watches
  it, so a new benchmark release arrives as a reviewable PR (controlled
  freshness, not silent drift).
- Every gap is triaged into one of three answers: **assumed** (our architecture
  answers it differently — documented, silenced in the playbook vars),
  **remediate** (a real gap — fixed in the `base`/`security` roles), or
  **noise/false positive** (verified against ground truth on the Pi).
- Remediation shipped in six batches (sysctl + kernel, module blacklist, sshd
  polish, file perms + packages, /dev/shm + postfix + sudo log, and
  nullok + root umask + NTP + UFW loopback + sshd_config perms).
- Assumed deviations are recorded twice — as a table in the research report and
  per-line comments in the playbook vars — so the reason survives next to the
  switch that acts on it.

The full findings, batch detail, deviation rationale and lessons live in
[knowledge/research/cis-audit-2026-07.md](../research/cis-audit-2026-07.md);
`docs/03-security/README.md` links it from the System-hardening layer.

## Alternatives rejected

- **Enforce mode** (run the role for real): breaks the lab on the deviations
  above. The whole point is that our deviations are deliberate.
- **goss effective-state audit** (`run_audit: true`): measures real state, which
  would clear the check-mode false positives automatically. Tried 2026-07-18 and
  reverted — the ansible-lockdown audit content is a moving git branch with no
  pinnable tag and had drifted ahead of role 1.6.0, erroring on 28 missing
  variables. Pinning to a matching commit kills the Renovate freshness design;
  hand-supplying the vars is whack-a-mole. Upstream version-sync fragility, not
  worth it. Revisit if a continuous compliance *score* is ever wanted.
- **lynis alone**: kept (complementary), but it is not the full CIS control set.

## Consequences

- Reproducible security posture measurement: re-run any time, diff against the
  baseline (135 flagged) — the count trends down as batches land.
- The check-mode count is **not** meant to reach zero: it scores "would the role
  rewrite its files", not effective state, so a bounded floor of role-internal
  noise and role-vs-layout false positives always remains. Read it, don't
  zero it — effective state is verified by direct reads + the `changed=0`
  convergence discipline. This is the key operating caveat (research report §4).
- New hardening ideas arrive through Renovate PRs (role bumps) for review, never
  as surprise enforcement.
- Deviations are now explicit and defensible rather than implicit: a reviewer
  sees exactly where and why the homelab departs from CIS.

See also: ADR-008 (USB tamper), ADR-009 (physical attack surface),
ADR-011 (secrets off SD); `docs/03-security/`.
