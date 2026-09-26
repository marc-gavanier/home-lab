# ADR-013 — System update & patching strategy

**Date**: 2026-07-19
**Status**: accepted (deployed and verified on both Pis)

## Context

`unattended-upgrades` installs security updates automatically, but on the
homelab it must **never auto-reboot**: a reboot brings the host back with
`/mnt/data` LOCKED and every service down until a manual `homelab-unlock` (the
LUKS key is never stored — ADR-011). That raised a real fear: with auto-reboot
off, could a security fix linger unapplied and *invisible*, leaving the system
exploitable?

Three facts shape the answer:

- A patch has three activation tiers: files read at exec (active immediately),
  **shared libraries mapped by long-running host daemons** (active only when the
  daemon restarts), and the **kernel / core init** (active only on reboot).
- The kernel is `linux-raspi`. **Canonical Livepatch does not support it** (only
  `generic`/cloud flavors), so live kernel patching — the one thing that would
  remove the reboot requirement — is unavailable on both Pis.
- The exposed attack surface is tiny: **51820/udp** (WireGuard, silent drop) and
  **51413** (Transmission's peer port, open by design for seeding — **tcp** as
  well as udp, see the second amendment below). SSH is
  not internet-exposed. The only remotely-reachable pre-auth kernel code is the
  WireGuard module + the netstack; almost every kernel CVE is a local-privilege
  escalation, irrelevant until an attacker already has a foothold.

  > **Amended 2026-08-02 after measuring, not assuming.** This paragraph used to
  > read "**80/443** (Traefik, `vpn-only` → 403 to all internet traffic) and
  > **51820/udp**". Two corrections. First, 80/443 are no longer reachable from
  > the internet at all — the forward was removed in late July, and a probe from
  > the offsite Pi finds 443 filtered while the service hostnames resolve only in
  > split DNS. The `vpn-only` ipAllowList is now defence in depth behind a closed
  > port, not the first line, so the 403 it used to return can no longer be
  > elicited. Second, **51413/udp was missing entirely** and is genuinely open —
  > `transmission-remote -pt` confirms it. An ADR about attack surface that omits
  > an open port is the more serious of the two errors.
  >
  > **Amended again 2026-08-15, and the lesson is about propagation.** Both
  > corrections above were right and both stayed here. `CLAUDE.md`,
  > `docs/00-architecture`, `docs/03-security` and `docs/04-network` went on
  > advertising 80/443 as the exposed surface and omitting 51413 for another
  > fortnight, until an audit probed the ports rather than reading the summaries.
  > Amending the ADR is not the end of the job; the summaries that quote it are
  > where anyone actually looks.
  >
  > One measurement refined: 51413 was recorded here as udp. Probed from the
  > offsite uplink with a control, **tcp is open too** — expected for a BitTorrent
  > peer port, which listens on both, but worth stating rather than inferring.
  > 80 and 443 both time out from the same vantage point in the same second.
  >
  > What this changes for the argument: nothing, and rather in its favour. Over
  > 24 h the host blocked 4 320 packets, of which **two** came from the internet;
  > fail2ban recorded zero failures and zero bans across all three jails, and
  > seven days of SSH logs hold no failed attempt. The reboot-latency exposure is
  > smaller than this ADR claimed, not larger.

## Decision

A layered strategy that keeps patches flowing without ever touching the
deliberate reboot posture.

1. **Auto-install, no auto-reboot** (existing). `20auto-upgrades` installs
   security updates daily; the reboot policy is per-host (`52homelab-reboot-policy`,
   driven by `unattended_automatic_reboot`): **homelab false**, **offsite true**
   (no LUKS there — it self-clears kernel updates at 04:00, after the nightly copy).
2. **`needrestart` in automatic mode** (`$nrconf{restart}='a'`, `docker.service`
   blacklisted). Restarts host daemons still mapping a patched library right
   after the upgrade — closing the userspace window **reboot-free**. Docker is
   excluded so *needrestart* never bounces the ~19 containers (staged startup,
   ADR-007); container userspace is Renovate's lane.

   > **Amended 2026-08-02 — the blacklist is narrower than this claimed.** The
   > sentence used to read "Docker is excluded so it never bounces the ~19
   > containers", which overstates what a needrestart blacklist can do. It stops
   > *needrestart* from restarting `docker.service` after some other package
   > upgraded a library Docker maps. It does nothing when **Docker itself is the
   > package being upgraded**: `docker-ce`'s own postinst restarts the daemon,
   > and every container with it.
   >
   > Observed the same evening. A convergence run upgraded `docker-ce`
   > 29.6.2 → 29.7.1 at 22:13:02; `docker.service` stopped 21 seconds later and
   > took all 22 containers down. `homelab-stack-startup` re-ran the waves
   > unprompted and the stack was fully healthy again by 22:16:27 — 3.5 minutes,
   > no intervention, which is exactly the behaviour ADR-007 exists to provide.
   >
   > **The invariant this ADR relies on still holds, but it comes from
   > elsewhere.** Docker ships from its own repository, which is *not* in
   > `Unattended-Upgrades::Allowed-Origins` — `o=Docker` is marked not allowed
   > and pinned at -32768. So a Docker upgrade, and the stack bounce it causes,
   > can only happen inside a deliberate `apt dist-upgrade`: an Ansible run, with
   > an operator watching. It cannot happen unattended at 06:00. That is the
   > property worth protecting, and it is now in the verification list below
   > rather than being inferred from the needrestart config.

   > **Amended 2026-09-22 — a second exclusion, and the limit of both.**
   > `unattended-upgrades.service` now sits beside `docker.service` in
   > `override_rc`, because the sweep killed the upgrade that invoked it.
   >
   > Measured that morning: the run started at 06:04:09 on eight packages; the
   > four glib packages landed by 06:04:16; at 06:04:28 needrestart restarted
   > the daemons mapping the new glib and stopped
   > `unattended-upgrades.service` among them; the run driving the transaction
   > took its own SIGTERM one second later, spun on "SIGTERM received, will
   > stop" for twenty-five minutes and exited 1 at 06:29:32. `libexpat1`,
   > `libexpat1-dev`, `libxml2` and `rsyslog` were never attempted. No hold and
   > no pin were involved — a simulated `apt-get upgrade` installed all four.
   > So any security update touching glib or a library of that class truncates
   > itself and abandons whatever sorts after it.
   >
   > The exclusion was verified the same day: in the 15:04 sweep the service no
   > longer appears in needrestart's restart list.
   >
   > **It does not close the whole exposure, and the residue is worth naming.**
   > When dbus itself is among the patched libraries, needrestart takes a
   > different path — `restart-dbus.service`, which runs
   > `loginctl terminate-session <ids> ; systemctl restart dbus.service ;
   > daemon-reexec ; systemctl restart <the logind family>`. At 15:04:49 both
   > `unattended-upgrades.service` and `networkd-dispatcher.service` exited
   > `status=1/FAILURE` in that same second, and needrestart restarted neither:
   > they are not on its list, they simply lost their bus. `override_rc` cannot
   > help, because nothing is restarting them — they are killed sideways. Both
   > were left `failed` until an operator cleared them; the Kuma "Pi health"
   > monitor caught the second within seven minutes via
   > `systemd-no-failed-units`.
   >
   > **Not established:** whether that path would truncate an in-flight
   > unattended-upgrades run the way the 06:04 sweep did. On 15:04 there was no
   > such run — the upgrade was manual. The mechanism is plausible, since the
   > blocker's stop is what signals a running upgrade, but it has not been
   > observed and should not be written down as if it had.
   >
   > **Operational consequence, independent of all the above:** a manual
   > `apt upgrade` over SSH terminates the operator's own session as soon as
   > dbus is in scope. It is neither a reboot nor a tunnel failure — check
   > `uptime` before concluding, and `systemctl --failed` afterwards.
   >
   > **Amended 2026-09-26 — the dbus path was ours, and `override_rc` was the
   > cure.** The paragraph above says `override_rc` cannot help. It could: the
   > dbus path was reachable only because our drop-in reassigned the whole
   > `$nrconf{override_rc}` hash instead of adding two keys to it. The package's
   > `needrestart.conf` ships 43 exclusions — `^dbus`, `^systemd-logind`,
   > `^user@\d+\.service`, `^getty@`, `^ModemManager`, `^wpa_supplicant` among
   > them — and reads `conf.d/` last, so our assignment left exactly 2, both of
   > which the vendor list already held. needrestart checks `override_rc` before
   > it looks up `restart.d/`, so with `^dbus` restored, `restart-dbus.service`
   > is never reached. Measured by evaluating the configuration the way
   > needrestart does: 43 entries from the vendor file alone, 2 effective, 44
   > after the fix, with `ssh.service` still restartable as the control.
   >
   > The journals hold nine `restart-dbus.service` runs: six on the offsite
   > (2026-07-28, 08-11, 09-01, 09-12, 09-23, 09-25) and three on the homelab
   > (09-11, 09-22, 09-26). The 09-26 one ran inside an unattended upgrade at
   > 06:24: `unattended-upgrades.service` failed at 06:24:57 and the run still
   > logged "All upgrades installed" at 06:25:54. After a restart of dbus,
   > `systemd-timesyncd` and `systemd-resolved` keep working but stop answering on
   > the bus (`timedatectl show-timesync` and `resolvectl` time out) until the
   > next boot, and `systemctl --failed` cannot see it.
   >
   > The fix assigns key by key. Its cost: services the vendor excludes are no
   > longer restarted after a library update, and wait for the next reboot like
   > the kernel does. Unlike the kernel they write no `reboot-required`, so the
   > homelab's pending monitor also asks `needrestart -b` once a package has been
   > installed since boot. The offsite has no such check: its excluded services
   > wait for its next kernel auto-reboot, accepted.
3. **Bounded-latency reboot policy** for the irreducible kernel/core-lib residue,
   tiered by *reachability*, not raw CVSS:
   - **Routine** kernel/core-lib bump (no active exploitation, or an LPE with no
     reachable foothold): reboot+unlock **≤ 14 days** (next maintenance window).
   - **Actively-exploited AND reachable** (CISA KEV / public PoC in the netstack,
     WireGuard, or an unauth-reachable path): reboot+unlock **≤ 48 h**.
   Recorded in the [boot & unlock runbook](../runbooks/boot-and-unlock.md).
4. **Visibility.** The Pi health monitor (observability role) already pushes DOWN
   on `/var/run/reboot-required`; it now also reports the pending-security-update
   count (via `apt-check`), age-gated to alarm only after 48 h so the daily u-u
   cycle doesn't flash it red. A held/failed/stuck update can no longer hide.
   > **Amended by the monitor split.** Both conditions now wait on a person, so
   > `homelab-health.sh` pushes them to the **`Pi pending action`** monitor, not
   > `Pi health` (which stays UP on a pending reboot — measured 2026-09-24). They
   > fold back into `Pi health` only when the pending push URL is not configured.
5. **Containers** (the bulk of the exposed surface) — Renovate weekly PRs +
   manual merge, plus `osvVulnerabilityAlerts` so an OSV-flagged CVE raises a PR
   off-schedule instead of waiting up to 7 days for the Saturday batch.

## Alternatives rejected

- **Auto-reboot on the homelab**: brings the host back locked, services down
  until a manual unlock — worse than a briefly-deferred, already-installed patch.
- **Canonical Livepatch**: unsupported on the `raspi` kernel. Not an option.
- **Ubuntu Pro / ESM**: deferred (LATER). Free, but livepatch is dead here;
  ESM-infra only matters after 24.04 standard support ends (2029); ESM-apps
  covers `universe`, yet this box's network-reachable software is containerized
  (Renovate's lane). Marginal defense-in-depth, attach when convenient.
- **Running-image CVE scanner (Trivy/Grype)**: SKIP for now — operational
  overhead disproportionate to a two-port homelab; revisit if the surface grows.
- **Auto-merging Renovate PRs**: reckless here — full-stack `compose up` thrashes
  the Pi, staged startup and Immich's one-way DB migrations need a human.

## Consequences

- **Most userspace security fixes activate reboot-free** (needrestart); the
  kernel and the services needrestart excludes need a reboot, and that residue is the *least-reachable* code
  on the box while the *most-reachable* (containers, host userspace) is patched
  fast.
- The reboot-latency window is a **theoretical** exposure on this host, not a
  practical one — bounded by policy and made visible, not eliminated.
- The offsite Pi self-heals kernel updates (auto-reboot), fixing a prior silent
  gap where it neither rebooted nor alerted.
- A stuck/held/failed security update is now surfaced within 48 h.

## Verification

- `needrestart -b` after an upgrade shows no stale services; confirm
  `docker.service` is *not* auto-restarted.
- **Docker must stay outside the unattended lane**, since upgrading it bounces
  every container. The needrestart blacklist does not give this — the origin
  filter does:

  ```bash
  sudo unattended-upgrade --dry-run -d 2>&1 | grep -i docker
  # expected: "Marking not allowed <...o=Docker...> with -32768 pin"
  ```

  If that line ever disappears, a stack-wide restart becomes possible at 06:00
  with nobody watching.
- After any upgrade that touched dbus, `systemctl --failed` must be empty. The
  dbus restart path kills bus clients without restarting them (2026-09-22:
  `unattended-upgrades` and `networkd-dispatcher`), and a failed unit is the
  only trace left.
- `apt-config dump Unattended-Upgrade::Automatic-Reboot` → `false` on homelab,
  `true` on offsite.
- Simulate a held update → Kuma "Pi pending action" goes DOWN after the 48 h threshold.

See also: ADR-011 (secrets off SD / LUKS-unlock), ADR-010 (offsite backup),
ADR-007 (staged startup); [boot & unlock runbook](../runbooks/boot-and-unlock.md);
`docs/03-security/`.
