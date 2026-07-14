# CIS Ubuntu 24.04 audit — homelab, July 2026

Instrument: `playbooks/cis-audit.yml` (ansible-lockdown UBUNTU24-CIS 1.6.0,
`--check` only — the playbook refuses enforce runs).

| Run        | Result                                                     |
|------------|------------------------------------------------------------|
| 2026-07-14 | Baseline: 279 controls, ~100 rules flagged, 425 skipped    |
| 2026-07-15 | After batches 1-2: count ~flat (see measurement caveat §4) |

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

**To arbitrate (usability trade-offs, not done by default):**
umask 027 (5.4.3.3), shell TMOUT (5.4.3.2), login banners (1.6.x),
lock the 20 shell-less system accounts (5.4.2.8), noexec /dev/shm (1.1.2.2.4),
sudo pty+logfile (5.2.2/3), su restricted group (5.2.7), MTA local-only (2.1.21).

## 3. Noise

PRELIM/apt update, handlers flushes, the role's fact files, UFW sysctl.conf
switch (OPTIONAL), and everything check-mode-skipped that a real lockdown run
would install first (documented rule by rule in the playbook vars).

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
