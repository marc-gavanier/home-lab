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
  worth it. Revisit if a continuous compliance *score* is ever wanted. (goss
  itself was later adopted for the posture spec — ADR-032. What was rejected here
  is ansible-lockdown's unpinnable audit CONTENT, not the tool that runs it.)
- **lynis alone**: kept (complementary), but it is not the full CIS control set.

## Standing lynis warnings that are not findings

The weekly `homelab-lynis-report.sh` push carries a warning count, and a count is
only readable if what it permanently contains is written down. Recorded
2026-08-24, when a run of four warnings sent the monitor DOWN and two of them
turned out to be structural.

The accounting, because it was not what it looked like: **only KRNL-5830 moved
the index** — `Hardening: assigned partial number of hardening points (0 of 5)`
in `/var/log/lynis.log`, for a reboot pending since a kernel update. Fixing the
other two took the run from four warnings to two and left the index at 71,
unchanged. Warnings and hardening points are separate currencies here, and a
warning of weight L buys neither. The count still matters — it is what the Kuma
push carries and what an operator reads to decide whether to look — but a
warning appearing is not evidence that the index fell.

**`PKGS-7388` — "Can't find any security repository in /etc/apt/sources.list or
sources.list.d directory". Cannot be fixed, and must not be.** The security
repository *is* declared, in the deb822 format Ubuntu 24.04 ships:

```
/etc/apt/sources.list                    empty, as the distribution leaves it
/etc/apt/sources.list.d/ubuntu.sources   line 53: Suites: noble-security
apt-cache policy                         500 …/noble-security, a=noble-security
unattended-upgrades                      active, Allowed-Origins includes
                                         ${distro_id}:${distro_codename}-security
```

lynis 3.0.9 greps legacy one-line `.list` files only. Satisfying it means adding
a duplicate legacy entry for a repository that is already configured and already
being pulled from — two sources of truth for the update path, in exchange for a
parser's opinion. The control the test stands for is verified above, by the three
readings that actually answer it.

This is the same operating caveat as the check-mode count in the Consequences
below, arriving from the other tool: a number that cannot reach zero has to be
read rather than zeroed.

**`TIME-3185` was the other one, and it WAS fixed** — see
`roles/security/tasks/hardening.yml`. It is recorded here because the shape is
worth telling apart: lynis warns above 2048 s of clock-file age and systemd's
default poll interval is exactly 2048 s, so the test could not distinguish a
healthy backoff from a stopped synchronisation. Capping the interval at 1024 made
the assertion capable of failing for its stated reason. A warning that flaps is
not automatically a false positive; sometimes it is a detector that was never
able to measure what it names.

## What the hardening index is, and what it is not

**It is a drift detector against a fixed rule set. It is not a statement of
compliance, and it cannot become one.** Written down 2026-08-29, because the
freshness of the *report* is asserted (#145) while the freshness of the *rules
that produced it* is not, and a reader is entitled to assume otherwise.

The distribution profile carries `skip-upgrade-test=yes`
(`/etc/lynis/default.prf:93`). The consequence is not that a check is missing —
it is that one of the report's fields becomes a constant:

```
lynis_version=3.0.9
lynis_update_available=0     <- always 0; the test that would set it is skipped
hardening_index=73
```

`lynis_update_available=0` therefore does not mean "up to date". It means "not
asked". Anything reading it as currency is reading an echo of the installed
version.

The one signal that does carry the age survives, and is thrown away one step
later:

```
suggestion[]=LYNIS|This release is more than 4 months old. Check the website
             or GitHub to see if there is an update available.|-|-|
```

`homelab-lynis-report.sh` reads `^warning[]=` and nothing else — three times, for
the count, the IDs and the new-since-last-run diff. A `suggestion[]` line is
invisible to it by construction. So the tool is telling us its rules are stale,
every week, into a channel nobody reads.

**Deliberately not fixed by promoting the suggestion to a warning.** The rules
going stale is a real fact but a slow one, the package follows the distribution,
and turning it into a weekly warning would put a line the operator cannot act on
into the count that decides whether they look at all — which is the one number
this section exists to keep readable. The correct answer is that the index is
read as *"did this host drift against the same ruler as last week"*, which is
what it can answer, and never as *"is this host current against what is known
today"*, which it cannot.

Identical on both hosts.

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
