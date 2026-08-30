# Runbook: Boot & Unlock (after any reboot or power cut)

What to expect and do when the Pi comes back up. Design rationale in
[ADR-007](../decisions/ADR-007-staged-container-startup.md).

> **A reboot cannot be undone from outside the LAN — plan for that before you
> cause one.** `/etc/wireguard/wg0.conf` is a symlink onto the encrypted volume
> (ADR-011). Before the unlock it dangles, so `wg-quick@wg0` cannot start and
> neither can `wg-easy` — and `ssh homelab` travels through that tunnel. There
> is no unlock without the tunnel and no tunnel without the unlock, so **the
> first `homelab-unlock` after any reboot has to be typed from the LAN**, at the
> machine or from something already inside the network. Everything below assumes
> you are.
>
> The offsite Pi is not in this position: it has no LUKS volume, and it comes
> back on its own — 50 seconds, measured 2026-08-26, WireGuard rejoined without
> help. "Reboots on its own at 04:00" used to be written here and reads as
> nightly; it is not. It is `Unattended-Upgrade::Automatic-Reboot "true"` with
> `Automatic-Reboot-Time "04:00"` — it reboots *when an update requires one*, at
> that hour. Measured boot durations: 28, 24, 42 and 23 days. Roughly monthly.

## Normal sequence

1. **Boot (~1 min).** The Pi boots from the unencrypted SD. SSH is available
   **on the LAN**, and only there — the VPN is down until step 2 finishes, for
   the reason in the box above. **Nothing else is up either** — no Docker, no
   swap, no `/mnt/data`, no LAN DNS (point a client at `1.1.1.1` if you need
   internet meanwhile).

   This is the expected pre-unlock state — worth glancing at, it proves the
   guards hold:

   ```bash
   systemctl is-active docker.service   # inactive
   systemctl is-active docker.socket    # ACTIVE — see below, this is correct
   docker ps                            # MUST fail
   swapon --show                        # empty
   ```

   > This block used to say "both: inactive", and that was wrong — measured on
   > 2026-08-26. `docker.socket` is active before the unlock and is supposed to
   > be: it is how Docker gets activated at all. What holds Docker back is a
   > drop-in on the SERVICE, `RequiresMountsFor=/mnt/data`, so an activation
   > attempt cannot succeed while the volume is locked. Reading the socket as a
   > regression would send you looking for a fault that is not there.

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

4. **DNS is back ~1–3 min in.** Tier 0 starts with the daemon rather than with a
   wave; the members are the services carrying `restart: unless-stopped`, and
   the list is not repeated here on purpose — read it from the source of truth:

   ```bash
   docker compose config --format json | jq -r \
     '.services | to_entries[] | select(.value.restart=="unless-stopped") | .key'
   ```

   This line used to name five containers and claim they had been "enumerated on
   the host by restart policy", which made prose read as a derived fact. It was
   six: `traefik-log-redactor` joined Tier 0 and neither this runbook nor
   ADR-007 followed. That omission is expensive precisely here — §"If the
   orchestrator aborts" below tells you to recreate a missing Tier 0 container
   by hand, and an operator rebuilding the tier from a list of five brings
   Traefik back **without its redactor**. `tail -F` opens the file where it is,
   so every access line written in the meantime is gone from the durable log,
   silently, during the part of boot that #252, #253, #260 and #292 were all
   opened about.

   The waves then bring up light services → Nextcloud stack → heavy tier, ending
   with `staged startup complete — all waves dispatched`.

5. **Verify** (optional):

   ```bash
   docker ps --format '{{.Names}}\t{{.Status}}' | sort   # all healthy, none missing
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

Since #241 a FATAL is no longer terminal: the unit retries **twice more, 60 s
apart**, then stays `failed`. So before intervening, check whether it is still
trying:

```bash
systemctl status homelab-stack-startup.service   # activating = a retry is pending
journalctl -t homelab-startup -f
```

A transient cause — a database still replaying its WAL, a disk still saturated
by the previous wave — is usually gone by the second attempt. A structural one
(the table above) will fail all three times and needs the fix in the table.

Do not confuse the retries with the crash-heal: `homelab-stack-heal` only
restarts containers that **exited** non-zero, so it can do nothing about a wave
that never dispatched and whose containers therefore do not exist. That was the
gap on 2026-08-26, and the retry is what closes it. Heal deliberately stays out
of the way while the unit is `activating`, and starts working once it is
`failed`.

## Crash recovery & maintenance

While unlocked, `homelab-stack-heal.timer` (every 2 min) restarts any compose
container that exited non-zero — traces in `journalctl -t homelab-heal`.

Consequence: a manually **stopped** container often exits 137/143 and will be
resurrected within 2 minutes. For maintenance, either:

```bash
docker compose down <svc>                    # removes it — nothing to heal
systemctl stop homelab-stack-heal.timer     # or pause healing (restart after)
```

`docker compose down` (no service named) also removes the Tier 0 containers, and
a restart policy cannot bring back a container that no longer exists. The
orchestrator recreates the missing ones itself since #253, so the stack comes
back from `homelab-unlock` unaided — but nothing recreates them if you only
restart Docker.

## Checking the data volume

`e2fsck` on a mounted filesystem corrupts it, so every check below needs the
stack down and `/mnt/data` unmounted, with the LUKS mapper still open.

Never run `e2fsck` directly. Use the wrapper, which raises the mount gate so
nothing — systemd, a queued Docker job, or someone else's `homelab-unlock` —
can mount the volume underneath the scan:

```bash
homelab-fsck            # read-only, forcing: e2fsck -fn (the default)
homelab-fsck -fy        # repair, once you have READ the read-only output
```

Budget about 3 min 30 s (measured 2026-08-26: 4.6 TB, 730 GB used, metadata
only, over USB). The gate is cleared on exit, including when the check reports
errors — `-fn` exits 4 whenever it finds anything, which is a normal result and
not a reason to leave the volume unmountable.

Running `e2fsck` by hand without the gate is what destroyed a diagnosis on
2026-08-26: `homelab-unlock` was started mid-scan, mounted the volume
read-write underneath it, and the resulting Pass 5 output was read as real
corruption for half an hour. `homelab-unlock` now refuses to start while a gate
it did not place is up.

**Automatic checks.** Since #254 the volume carries a 30-day interval in its
superblock, honoured by the `e2fsck -p` that `homelab-unlock` already runs. On
the first unlock past that interval, `Checking data volume integrity...` takes
minutes instead of a second and shows a progress bar. That is expected — DNS
returns later than the usual 1–3 minutes on that boot, and interrupting it is
the one thing not to do.

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

A reboot is power-cycle-then-`homelab-unlock` (this runbook) — but it is not
*just* that: it can only be finished from the LAN, so the window is bounded by
someone being able to reach the machine, not only by the CVSS. Schedule it
accordingly. Check what's pending with `cat /var/run/reboot-required.pkgs`. The offsite Pi has no LUKS and
reboots itself when an update needs it (unattended-upgrades, at 04:00 — roughly
monthly, not nightly), so this cadence is homelab-only. Rationale:
[ADR-013](../decisions/ADR-013-update-patching-strategy.md).

## Related

- [ADR-007](../decisions/ADR-007-staged-container-startup.md) — design & alternatives.
- [ADR-013](../decisions/ADR-013-update-patching-strategy.md) — update & patching strategy (reboot cadence).
- [kill-switch runbook](kill-switch.md) — the remote poweroff lands on this boot path.
- [usb-tamper runbook](usb-tamper.md) — the local poweroff (USB events) lands here too.
- `homelab-lock` — stops the target (containers, heal timer, swap), unmounts and
  relocks the volume.
