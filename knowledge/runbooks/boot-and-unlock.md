# Runbook: Boot & Unlock (after any reboot or power cut)

What to expect and do when the Pi comes back up. Design rationale in
[ADR-007](../decisions/ADR-007-staged-container-startup.md).

## Normal sequence

1. **Boot (~1 min).** The Pi boots from the unencrypted SD. SSH is available;
   **nothing else is** — no Docker, no swap, no `/mnt/data`, no LAN DNS (point
   a client at `1.1.1.1` if you need internet meanwhile).

   This is the expected pre-unlock state — worth glancing at, it proves the
   guards hold:

   ```bash
   systemctl is-active docker.service docker.socket   # both: inactive
   docker ps       # MUST fail ("no such file or directory" on the socket)
   swapon --show   # empty
   ```

   > A **responding** `docker ps` before the unlock means the guards have
   > regressed — do NOT unlock; investigate first (see ghost store below).

2. **Before unlocking — was this poweroff expected?** The SD card is
   unencrypted: anyone who can pull it can backdoor the unlock path and capture
   the passphrase you are about to type (evil maid). Pulling the SD requires
   the Pi to be off — so an **unexplained poweroff is the tamper signal**.
   Expected causes: your own shutdown, a power cut, a [kill-switch](kill-switch.md)
   or [usb-tamper](usb-tamper.md) trigger *that you remember* — the journal
   lives on the SD, so it proves nothing. If you cannot account for the
   downtime, do **not** unlock: reflash the SD and re-provision with Ansible
   first (~1 h; all service state lives on the encrypted HDD, nothing is lost).

3. **Unlock:**

   ```bash
   sudo homelab-unlock     # asks for the LUKS passphrase
   ```

   The unlock also **arms the USB tamper response** ([ADR-008](../decisions/ADR-008-usb-tamper-poweroff.md)):
   from this point, any USB plug/unplug powers the Pi off — disarm before
   touching cables (see the [usb-tamper runbook](usb-tamper.md)).

   Mounting `/mnt/data` also pulls in the units whose secrets live on the
   encrypted volume ([ADR-011](../decisions/ADR-011-secrets-off-sd.md)):
   `wg-quick@wg0` (host tunnel to the offsite Pi) and `vault-mount` (claude's
   rclone mount). Neither runs before the unlock — that is by design.

   The command returns immediately; the orchestrator keeps running its
   health-gated waves in the background (~5–8 min). Follow along:

   ```bash
   journalctl -t homelab-startup -b -f
   ```

4. **DNS is back ~1–3 min in** (Tier 0: traefik/pihole/wg-easy/dnsproxy/socket-proxy
   start with the daemon — five containers, enumerated on the host by restart policy,
   not three as this line said until #178). The waves then bring up light services → Nextcloud stack → heavy
   tier, ending with `staged startup complete — all waves dispatched`.

5. **Verify** (optional):

   ```bash
   docker ps --format '{{.Names}}\t{{.Status}}' | sort   # 28 containers, healthy
   swapon --show                                         # /mnt/data/swapfile (HDD)
   ```

## If the orchestrator aborts (`FATAL` in the journal)

The script is fail-fast on purpose; the message says which guard fired:

| FATAL message                              | Meaning & fix                                                              |
|--------------------------------------------|----------------------------------------------------------------------------|
| `... not mounted`                          | Unlock/mount failed — rerun `sudo homelab-unlock`                          |
| `docker not responding`                    | `systemctl status docker` — the daemon failed to start                     |
| `dockerd started before ...` (ghost store) | `systemctl restart docker`, then `systemctl restart homelab-stack-startup` |
| `container X does not exist`               | Store/compose problem — `docker compose up -d X` by hand and inspect       |
| `compose up failed for: ...`               | The compose error is logged right above it                                 |

> **Never wipe `/mnt/data/docker` on a "ghost store" diagnosis.** The real
> store is intact on the HDD; the daemon just started against the bare SD
> directory. Restarting Docker *after* the mount reloads the real store with
> all containers and images (the 2026-07-04 wipe was an avoidable full re-pull).

## Crash recovery & maintenance

While unlocked, `homelab-stack-heal.timer` (every 2 min) restarts any compose
container that exited non-zero — traces in `journalctl -t homelab-heal`.

Consequence: a manually **stopped** container often exits 137/143 and will be
resurrected within 2 minutes. For maintenance, either:

```bash
docker compose down <svc>                    # removes it — nothing to heal
systemctl stop homelab-stack-heal.timer     # or pause healing (restart after)
```

## Security-update reboot cadence

Security updates install automatically but **never auto-reboot** the homelab (a
reboot = locked volume + outage until you unlock — ADR-011/013). `needrestart`
restarts host daemons on a patched library without a reboot, so only **kernel /
core-init** updates leave a pending reboot. When one does, the "Pi health"
Kuma monitor goes DOWN (`/var/run/reboot-required`). Schedule the reboot+unlock
by *reachability*, not raw CVSS:

| Situation | Reboot+unlock within |
|-----------|----------------------|
| Routine kernel bump — no active exploitation, or an LPE with no reachable foothold | **≤ 14 days** (next maintenance window) |
| Actively exploited **and** reachable — CISA KEV / public PoC in the netstack, WireGuard, or an unauth-reachable path | **≤ 48 h** |

A reboot is just power-cycle-then-`homelab-unlock` (this runbook). Check what's
pending with `cat /var/run/reboot-required.pkgs`. The offsite Pi has no LUKS and
auto-reboots at 04:00, so this cadence is homelab-only. Rationale:
[ADR-013](../decisions/ADR-013-update-patching-strategy.md).

## Related

- [ADR-007](../decisions/ADR-007-staged-container-startup.md) — design & alternatives.
- [ADR-013](../decisions/ADR-013-update-patching-strategy.md) — update & patching strategy (reboot cadence).
- [kill-switch runbook](kill-switch.md) — the remote poweroff lands on this boot path.
- [usb-tamper runbook](usb-tamper.md) — the local poweroff (USB events) lands here too.
- `homelab-lock` — stops the target (containers, heal timer, swap), unmounts and
  relocks the volume.
