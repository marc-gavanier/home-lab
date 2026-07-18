# CIS Ubuntu 24.04 audit — homelab, July 2026

Instrument: `playbooks/cis-audit.yml` (ansible-lockdown UBUNTU24-CIS 1.6.0,
`--check` only — the playbook refuses enforce runs).

| Run        | Flagged | Note                                                   |
|------------|---------|--------------------------------------------------------|
| 2026-07-14 | 135     | Baseline (279 controls, 425 skipped)                   |
| 2026-07-15 | 134     | After batches 1-2 — count ~flat, effective (caveat §4) |
| 2026-07-15 | 120     | After batches 3-4 — real drops + role-vs-state residue |
| 2026-07-18 | 51      | After batch 5 + ground-truthed silencing               |
| 2026-07-18 | 6       | After batch 6 — CLOSED: the 6 are role internals only   |

**Closed 2026-07-18.** No real security finding remains. The final 6 `changed`
are role-internal mechanics, not findings and not rule-gated (so not
silenceable): `PRELIM Run apt update`, `PRELIM Create journald conf.d dir`,
`PRELIM Ensure auditd installed` (a check-mode would-install; auditd stays out
by design), `OPTIONAL UFW sysctl.conf`, and the two `Create ansible facts`
files. Two manual AUDIT warnings stand, both satisfied by eyeball: **2.1.22**
(only approved services listen — Traefik 80/443, Pi-hole 53, WireGuard 51820,
Transmission 51413, SSH, Postfix loopback) and **4.2.6** (a ufw rule exists for
each open port — it does). The last real gap, 5.4.2.6 root umask, was a literal
`027` vs `0027` mismatch — aligned.

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

**Batch 5 — SHIPPED 2026-07-18** (`security/tasks/hardening.yml`)
Only the REAL gaps confirmed by ground-truth (the rest of the arbitration list
was already satisfied or decided against — see below):
- noexec on /dev/shm (1.1.2.2.4)
- postfix loopback-only (2.1.21 — it was listening on all interfaces)
- dedicated sudo logfile (5.2.3 — use_pty already a Ubuntu default)

**Batch 6 — SHIPPED 2026-07-18** (5 more genuine gaps found while triaging 51)
- remove `nullok` from pam_unix (5.3.3.4.1 — allowed empty-password auth)
- root umask 0027 in /root/.bash_profile (5.4.2.6 — narrower/safer than a
  system-wide default umask; the literal `0027` matches the benchmark)
- authorized NTP servers for systemd-timesyncd (2.3.2.1 — NTP= was empty)
- explicit UFW loopback rules (4.2.4 — allow lo, drop spoofed 127.0.0.0/8 & ::1)
- sshd_config 0600 (5.1.1 — Ubuntu ships 0644)

**Decided against / already satisfied (silenced, not done):**
- Already satisfied (ground-truthed): strong hashing SHA512 (5.4.1.4/5.3.3.4.3),
  no non-root login shells (5.4.2.7), sudo use_pty (5.2.2), AppArmor installed+
  enabled (1.3.1.1), shadow perms our Ubuntu way (7.1.5-8), all batch 1-2 sysctl/
  modules (effective).
- Deviations by design: login banners 1.6.x (theatre), su group 5.2.7, umask 027
  default 5.4.3.3 (cross-service read risk), shell TMOUT 5.4.3.2 (nuisance),
  egress allow-outbound 4.2.5, sudo timeout 5.2.6 (moot, NOPASSWD), PAM
  faillock/pwquality 5.3.x (moot, no local passwords), remote journald
  1.2.1.x (no central log server), user dotfile perms 7.2.10 (low value).

**2 manual AUDIT warnings on the closed run** — the role can't auto-verify
these; both are satisfied by eyeball (see the "Closed" note at the top):
- 2.1.22 "only approved services listening" — open ports are Traefik 80/443,
  Pi-hole 53, WireGuard 51820, Transmission 51413, SSH, Postfix on loopback.
- 4.2.6 "a ufw rule exists for each open port" — it does (each of the above).
(Earlier runs also warned 1.2.1.1/1.2.1.2 remote journald — N/A, no central
log server; now silenced.)

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

**Engine: check-mode + silencing (goss attempted and reverted 2026-07-18).**
The check-mode count is mostly false positives (the role scores "would I
rewrite MY files", not effective state — packages proven absent, sshd settings
proven active via `sshd -T`, all still flagged). goss (`run_audit: true`)
measures effective state and would clear those, so it was tried — and reverted.

Why goss failed here: the ansible-lockdown audit content is a **moving git
branch (`benchmark_v1.0.0`) with no pinnable tag**, and its HEAD had drifted
ahead of the pinned role 1.6.0 — the goss run errored with 28 variables the
role no longer templates (`machine_uuid`, `os_release`, `ubtu24cis_pass_max_days`,
…). Making it work would mean pinning the content to a matching commit (which
Renovate can't track cleanly, killing the controlled-freshness design) or
hand-supplying 28 vars including host facts (whack-a-mole). Not worth it: an
upstream version-sync fragility, not just the footprint I first cited.

So we stay on check-mode + documented silencing. Its false-positive floor is a
known, bounded quantity (verified against ground truth on the Pi); regression
detection lives in the `changed=0` convergence runs + direct state reads. goss
binary/content were removed from the Pi after the test.

## 4. Lessons learned

- **The check-mode count does NOT measure effective state** — it measures
  "would the role write ITS files". Batches 1-2 are provably effective
  (direct kernel reads above) yet the flagged count stayed ~flat (135 → 134):
  our sysctl/modprobe layout (`99-homelab.conf`, `cis-blacklist.conf`)
  differs from the role's own file naming, so its tasks always want to write.
  Verify remediations with direct state reads; treat the check-mode count as
  a coarse discovery tool only. The role's goss engine would score effective
  state directly — tried and reverted (upstream version desync, see the engine
  note above §4).
- **UFW owns a competing sysctl file**: `/etc/ufw/sysctl.conf` (IPT_SYSCTL)
  is re-applied on every ufw reload and silently overrode `log_martians` —
  caught by the changed=0 discipline, fixed by aligning UFW's file from the
  firewall tasks. Any sysctl key managed by the base role must not conflict
  with UFW's file.

See also: [ADR-012](../decisions/ADR-012-cis-benchmark-audit.md) (the decision
this report backs), ADR-008 (usb tamper), ADR-009, ADR-011 (secrets off SD),
`docs/03-security/`.
