# CIS Ubuntu 24.04 audit — homelab, July 2026

Instrument: `playbooks/cis-audit.yml` (ansible-lockdown UBUNTU24-CIS 1.6.0,
`--check` only — the playbook refuses enforce runs).

| Run        | Flagged | Note                                                   |
|------------|---------|--------------------------------------------------------|
| 2026-07-14 | 135     | Baseline (279 controls, 425 skipped)                   |
| 2026-07-15 | 134     | After batches 1-2 — count ~flat, effective (caveat §4) |
| 2026-07-15 | 120     | After batches 3-4 — real drops + role-vs-state residue |

The 135→120 move: batch-3/4 rules that check *real system files* cleared
(cron perms 2.4.x, avahi 2.1.2, and the binary-valued sshd rules 5.1.9/11/13/
18/21). What still flags despite proven-correct state: the sshd crypto lists
(5.1.6/12/15 — `sshd -T` shows our hardened Ciphers/MACs/Kex, the role compares
against ITS own list) and shadow perms (7.1.5-8 — we use Ubuntu's `root:shadow
0640`, the role wants `root:root`; ours is the OS-correct choice). Both are the
§4 caveat again: the count scores the role's expectation, not effective state.

Reading grid: a CIS gap is not a defect — it is a question. Three answers:
**assumed** (our architecture answers it differently, documented), **worth
fixing** (real quick wins), **noise** (not applicable here).

## 1. Assumed deviations — do NOT "fix"

| CIS                         | Wants                          | Why we deviate                                                                                                               |
|-----------------------------|--------------------------------|------------------------------------------------------------------------------------------------------------------------------|
| 3.3.1                       | IP forwarding disabled         | Required by Docker networking and WireGuard routing — the lab IS a router                                                    |
| 1.1.1.6                     | overlayfs module blacklisted   | Docker's storage driver                                                                                                      |
| 1.1.1.9                     | usb-storage blacklisted        | The 5TB data disk is USB; physical USB surface covered by ADR-008 (tamper poweroff)                                          |
| 5.2.4                       | sudo requires password         | Deliberate: account password locked (`password_lock`), SSH key-only — a sudo password would resurrect a crackable credential |
| 5.1.8                       | sshd DisableForwarding         | SSH tunnel is the only admin path to the wg-easy UI (127.0.0.1:51821)                                                        |
| 5.4.1.x, 5.3.x PAM          | password aging/quality/lockout | No active local passwords exist (locked); rules are moot                                                                     |
| Section 6                   | auditd installed + rules       | Accepted absence so far: single-operator host, systemd journal present, SD wear budget. Revisit if threat model changes      |
| Bootloader (1.3.1.2, 1.4.x) | GRUB hardening                 | No GRUB on a Pi (firmware + cmdline.txt); boot integrity addressed by ADR-008/009 instead                                    |
| 2.1.13                      | rsync package removed          | Operator's media-transfer tool (docs/05-services/nextcloud.md) — the binary must exist server-side                           |

The full rule-by-rule list (with check-mode exclusions) lives as commented
vars in `playbooks/cis-audit.yml`.

## 2. Remediation batches

**Batch 1 — network sysctl + kernel hardening — SHIPPED 2026-07-15**
(`base/tasks/system.yml`.) 3.3.2-3.3.11: no ICMP redirects in or out, no
source routing, strict rp_filter, syn cookies, bogus-ICMP/broadcast-echo
ignored, martians logged, no IPv6 RA. Plus 1.5.1 ASLR, 1.5.2 ptrace_scope,
1.5.3 suid core dumps off, 1.5.5 apport purged.
Verified: converged `changed=0` on both Pis; effective state read directly
(`log_martians=1`, `tcp_syncookies=1`, `ptrace_scope=1`, `accept_redirects=0`);
WireGuard tunnel healthy under strict rp_filter (ping 10.8.0.4 + offsite check
green on Kuma).

**Batch 2 — kernel module blacklist — SHIPPED 2026-07-15**
(`base/tasks/attack-surface.yml`, `/etc/modprobe.d/cis-blacklist.conf`.)
Unused filesystems 1.1.1.1-.8 (cramfs, freevxfs, hfs, hfsplus, jffs2, udf)
and network protocols 3.2.x (dccp, tipc, rds, sctp), `install /bin/false` +
blacklist. overlayfs and usb-storage deliberately kept (see §1).

**Batch 3 — sshd polish — SHIPPED 2026-07-15** (security role `ssh.yml`)
Explicit strong Ciphers/MACs/KexAlgorithms (5.1.6/12/15), LogLevel VERBOSE,
LoginGraceTime 60, MaxSessions/MaxStartups, PermitUserEnvironment no,
IgnoreRhosts, HostbasedAuthentication/GSSAPI off. DisableForwarding skipped
(assumed, §1). All entries go through `sshd -t` validation before restart.

**Batch 4 — files & packages — SHIPPED 2026-07-15**
- `security/tasks/permissions.yml`: shadow/gshadow(-) 0640 root:shadow,
  crontab 0600, cron dirs 0700, cron.allow/at.allow root-only (2.4.x, 7.1.5-8)
- `security/tasks/packages.yml`: avahi-daemon, telnet, ftp purged; rsync
  KEPT (deviation, see §1)
- Transmission now runs with UMASK 022 (compose) — root cause of the
  world-writable media. Existing files need a ONE-SHOT (not idempotent-worthy):
  `ansible homelab -m command -a "chmod -R o-w /mnt/data/media" -b`

**Batch 5 — to arbitrate (usability trade-offs, decide per item):**

Quick wins, no downside (candidate lot 5 — verify the noted preconditions first):

| CIS       | Control                      | What it buys                                                                                                   | Reco  |
|-----------|------------------------------|----------------------------------------------------------------------------------------------------------------|-------|
| 1.1.2.2.4 | noexec on /dev/shm           | Blocks the classic "drop payload in RAM and run it" technique                                                  | Do it |
| 5.4.2.8   | lock shell-less sys accounts | Closes an escalation path via service accounts (www-data…) — check none is actually used (e.g. `claude`) first | Do it |
| 2.1.21    | MTA local-only               | Postfix stops listening on the network (no mail server here) — confirm an MTA is even running                  | Do it |
| 5.2.2/3   | sudo pty + logfile           | Logs every sudo command, forces a pty — test an Ansible `become` still works (usually transparent)             | Do it |

Neutral — do only for score/compliance polish:

| CIS   | Control                  | Note                                                       | Reco     |
|-------|--------------------------|------------------------------------------------------------|----------|
| 5.2.7 | restrict `su` to a group | Marginal on a single-operator host (sudo NOPASSWD already) | Optional |
| 1.6.x | login banners            | Legal notice — compliance theatre, zero technical effect   | Optional |

Needs care / not recommended here:

| CIS     | Control           | Why caution                                                                                                                                                    | Reco    |
|---------|-------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------|---------|
| 5.4.3.3 | umask 027 default | Stricter default file perms, but can break cross-service reads (same class as the Transmission umask incident) — deploy watching Nextcloud/Immich media access | Careful |
| 5.4.3.2 | shell TMOUT       | Auto-logout of idle shells — a nuisance on a personal SSH box; `ClientAliveInterval` (already set) covers the real risk                                        | Skip    |

## 3. Noise

PRELIM/apt update, handlers flushes, the role's fact files, UFW sysctl.conf
switch (OPTIONAL), and everything check-mode-skipped that a real lockdown run
would install first (documented rule by rule in the playbook vars).

## 3bis. Silenced in the playbook — making the count mean something

A flagged count that is 90% noise is useless. Two categories are now set
`false` in `cis-audit.yml` so the remaining count is *actionable work only*:

- **Assumed deviations (§1)** — never actionable, silenced with a per-line
  comment pointing here (ip_forward, overlayfs, sudo NOPASSWD, SSH forwarding,
  password aging).
- **False positives (§4)** — effective state is correct (proven by `sshd -T`,
  direct sysctl/stat reads); the role stays red only because it checks its own
  file layout. A permanently-stuck check gives no signal, so silencing loses
  nothing — regression detection lives in the `changed=0` convergence runs and
  direct state reads instead.

After silencing, whatever the audit still flags = genuine undecided work
(batch 5 below + anything not yet categorised). That is the number to watch.

**Engine: goss (adopted 2026-07-18).** Initially the audit ran in `--check` and
silencing was manual. Ground-truth checks then showed the check-mode count is
mostly false positives (the role scores "would I rewrite MY files", not
effective state — packages proven absent, sshd settings proven active via
`sshd -T`, all still flagged). Silencing them by hand was an unbounded,
ever-growing exclusion list. So the playbook moved to the role's goss engine
(`setup_audit`/`run_audit`/`audit_only`), which measures EFFECTIVE state:
- False positives clear themselves — goss checks reality, no manual skip needed.
- Only genuine assumed deviations (report §1) are still skipped via rule vars,
  which the role templates into goss's own vars (`ansible_vars_goss.yml.j2`).
- Safety is `audit_only: true` (end_host before any remediation), not `--check`.
- Footprint accepted: goss binary (pinned+sha256 by the role) + audit content
  at /opt, version tracked by Renovate through the role pin.
Regression detection is preserved (goss re-measures reality each run) on top of
the convergence `changed=0` guarantee.

## 4. Lessons learned

- **The check-mode count does NOT measure effective state** — it measures
  "would the role write ITS files". Batches 1-2 are provably effective
  (direct kernel reads above) yet the flagged count stayed ~flat (135 → 134):
  our sysctl/modprobe layout (`99-homelab.conf`, `cis-blacklist.conf`)
  differs from the role's own file naming, so its tasks always want to write.
  Verify remediations with direct state reads; treat the check-mode count as
  a coarse discovery tool only. For true effective-state scoring, the role's
  goss audit engine (`run_audit: true`) is the option — it installs tooling
  on the host, left out for now.
- **UFW owns a competing sysctl file**: `/etc/ufw/sysctl.conf` (IPT_SYSCTL)
  is re-applied on every ufw reload and silently overrode `log_martians` —
  caught by the changed=0 discipline, fixed by aligning UFW's file from the
  firewall tasks. Any sysctl key managed by the base role must not conflict
  with UFW's file.

See also: ADR-008 (usb tamper), ADR-009, ADR-011 (secrets off SD),
`docs/03-security/`.
