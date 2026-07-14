# CIS Ubuntu 24.04 audit — homelab, 2026-07-14

Run: `playbooks/cis-audit.yml` (ansible-lockdown UBUNTU24-CIS 1.6.0, `--check`
only). Result: 279 controls evaluated, ~100 rules flagged, 425 skipped
(level-2, disabled sections, check-mode exclusions documented in the playbook).

Reading grid: a CIS gap is not a defect — it is a question. Three answers
below: **assumed** (our architecture answers it differently, documented),
**worth fixing** (real quick wins), **noise** (not applicable here).

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

## 2. Worth fixing — proposed batches

**Batch 1 — network sysctl hardening (base role, zero risk):**
3.3.2-3.3.11: no redirects (send/accept/secure), no source routing, rp_filter,
syn cookies, bogus ICMP ignored, martians logged, no IPv6 RA. All compatible
with Docker/WireGuard (only 3.3.1 forwarding is ours to keep).
Plus 1.5.1 ASLR, 1.5.2 ptrace_scope, 1.5.3 core dumps off, 1.5.5 apport off.

**Batch 2 — kernel module blacklist (attack-surface.yml pattern):**
Rare filesystems 1.1.1.1-.8 (cramfs, freevxfs, hfs, hfsplus, jffs2, udf —
NOT overlayfs) and exotic network protocols 3.2.x (dccp, tipc, rds, sctp).

**Batch 3 — sshd polish (security role ssh.yml):**
Explicit strong Ciphers/MACs/KexAlgorithms (5.1.6/12/15), LogLevel VERBOSE,
LoginGraceTime 60, MaxSessions/MaxStartups, PermitUserEnvironment no,
IgnoreRhosts, GSSAPI off. Skip DisableForwarding (assumed above).

**Batch 4 — files & packages:**
- cron perms 0600/0700 + cron.allow/at.allow (2.4.x)
- /etc/shadow(-)/gshadow(-) perms (7.1.5-8)
- remove avahi-daemon, telnet & ftp clients, rsync package (2.1.x/2.2.x)
- world-writable media files found by 7.1.11 before its FUSE crash:
  `chmod -R o-w /mnt/data/media` (probably Transmission umask — fix at source too)

**To arbitrate (usability trade-offs, not done by default):**
umask 027 (5.4.3.3), shell TMOUT (5.4.3.2), login banners (1.6.x),
lock the 20 shell-less system accounts (5.4.2.8), noexec /dev/shm (1.1.2.2.4),
sudo pty+logfile (5.2.2/3), su restricted group (5.2.7), MTA local-only (2.1.21).

## 3. Noise

PRELIM/apt update, handlers flushes, the role's fact files, UFW sysctl.conf
switch (OPTIONAL), and everything check-mode-skipped that a real lockdown run
would install first (documented rule by rule in the playbook vars).

## Follow-up

Batches 1-2 are one small PR (sysctl + blacklist, both roles already have the
right files). Batch 3 is a second PR (ssh.yml loop entries). Batch 4 file
perms are trivial; package removals need a quick "is rsync used anywhere?"
check first. Re-run the audit after each batch and watch the flagged count drop.
