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
  **51413/udp** (Transmission's peer port, open by design for seeding). SSH is
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
   excluded so it never bounces the ~19 containers (staged startup, ADR-007);
   container userspace is Renovate's lane.
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

- **Userspace security fixes activate reboot-free** (needrestart); only the
  kernel residue needs a reboot, and that residue is the *least-reachable* code
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
- `apt-config dump Unattended-Upgrade::Automatic-Reboot` → `false` on homelab,
  `true` on offsite.
- Simulate a held update → Kuma "Pi health" goes DOWN after the 48 h threshold.

See also: ADR-011 (secrets off SD / LUKS-unlock), ADR-010 (offsite backup),
ADR-007 (staged startup); [boot & unlock runbook](../runbooks/boot-and-unlock.md);
`docs/03-security/`.
