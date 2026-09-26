# Runbook: Boot & Unlock (after any reboot or power cut)

Use this page every time the homelab Pi comes back up: reboot, power cut,
[kill-switch](kill-switch.md) or [usb-tamper](usb-tamper.md) poweroff.

## Before you start

- **The first unlock after a reboot must be typed from the LAN.**
  `/etc/wireguard/wg0.conf` is a symlink onto the encrypted volume (ADR-011), so
  `wg-quick@wg0`, `wg-easy` and `ssh homelab` stay down until the unlock. Do not
  cause a reboot unless someone can reach the LAN.
- Before the unlock there is no Docker, swap, `/mnt/data` or LAN DNS. Point a
  client at `1.1.1.1` for internet meanwhile.
- The offsite Pi has no LUKS volume; it comes back alone in about 50 s.

## Steps

1. **Wait for the boot.** SSH listens on the LAN about 107 s after power-on.
   Check the pre-unlock state; it proves the guards hold:

   ```bash
   systemctl is-active docker.service   # inactive
   systemctl is-active docker.socket    # inactive — see below
   systemctl is-enabled docker.socket   # disabled — this is the deliberate part
   docker ps                            # MUST fail
   swapon --show                        # empty
   ```

   - `docker.socket` is disabled on purpose
     (`roles/docker/tasks/unlock-integration.yml`): socket activation would
     start dockerd on the SD before the unlock (ghost store). A drop-in on
     `docker.service` adds `RequiresMountsFor=/mnt/data`.
   - **Stop if `docker ps` responds**: the guards have regressed. Do not unlock;
     investigate (see [If it fails](#if-it-fails)).

2. **Was the poweroff expected?** The SD is unencrypted and can only be pulled
   while the Pi is off, so an unexplained poweroff means the unlock path may be
   backdoored to capture the passphrase.
   - Expected (your shutdown, a power cut, a kill-switch or usb-tamper trigger
     you remember): go to step 3.
   - Unexplained: **do not unlock.** Reflash the SD and re-provision with
     Ansible (~1 h, nothing is lost), then reboot once so `config.txt` and
     `cmdline.txt` apply (`Pi pending action` flags it until then).
   - The journal cannot decide: before the unlock only this boot's volatile
     journal is readable.

3. **Unlock.**

   ```bash
   sudo homelab-unlock     # asks for the LUKS passphrase
   ```

   - **From now on any USB plug/unplug powers the Pi off.** Disarm before
     touching cables ([usb-tamper runbook](usb-tamper.md),
     [ADR-008](../decisions/ADR-008-usb-tamper-poweroff.md)).
   - The mount starts the units that need the volume
     ([ADR-011](../decisions/ADR-011-secrets-off-sd.md)): `wg-quick@wg0`,
     `vault-mount`, `homelab-ddns`, `homelab-journal-persist`. Authority:
     `ls /etc/systemd/system/mnt-data.mount.wants/`.
   - Every 30 days `Checking data volume integrity...` runs a full scan with a
     progress bar for minutes. **Do not interrupt it.**
   - The command returns at once; the startup waves run in the background
     (~5–8 min):

   ```bash
   journalctl -t homelab-startup -b -f
   ```

4. **Wait for DNS (~1–3 min).** Tier 0 (the services with
   `restart: unless-stopped`) starts with the daemon. To list its members:

   ```bash
   cd /opt/homelab || echo "wrong path — the command below will lie"
   docker compose config --format json | jq -r \
     '.services | to_entries[] | select(.value.restart=="unless-stopped") | .key'
   ```

   **Empty output means a wrong directory, not an empty tier**: `jq` exits 0
   even when `docker compose config` fails. Rerun from `/opt/homelab`.

   Then come light services, the Nextcloud stack, the heavy tier. Done at
   `staged startup complete — all waves dispatched`.

## Check it worked

```bash
docker compose -f /opt/homelab/compose.yaml config --services | wc -l   # expected count
docker ps -q | wc -l                                    # must match
docker ps --filter health=unhealthy --filter health=starting   # must be empty
swapon --show                                         # /mnt/data/swapfile (HDD)
```

## If it fails

### The orchestrator aborts (`FATAL` in the journal)

A FATAL retries twice more, 60 s apart, then the unit stays `failed`. Check
first:

```bash
systemctl status homelab-stack-startup.service   # activating = a retry is pending
journalctl -t homelab-startup -f
```

Transient causes (WAL replay, saturated disk) clear on retry. Structural ones
fail three times:

| FATAL message                              | Meaning & fix                                                              |
|--------------------------------------------|----------------------------------------------------------------------------|
| `... not mounted`                          | Unlock/mount failed — rerun `sudo homelab-unlock`                          |
| `docker not responding`                    | `systemctl status docker` — the daemon failed to start                     |
| `dockerd started before ...` (ghost store) | `systemctl restart docker`, then `systemctl restart homelab-stack-startup` |
| `container X does not exist`               | Store/compose problem — `docker compose up -d X` by hand and inspect       |
| `compose up failed for: ...`               | The compose error is logged right above it                                 |

- Recreating Tier 0 by hand: use the list from step 4. Forgetting
  `traefik-log-redactor` loses Traefik access lines from the durable log.
- The crash-heal only acts on existing containers, and waits while the unit is
  `activating`.

### Ghost store or thinned image list

- **Never wipe `/mnt/data/docker` on a ghost-store diagnosis.** The real store
  is intact; restart Docker after the mount and it comes back.
- A thinned (not empty) list is `homelab-image-retention.timer`
  (`docker image prune -af --filter until=720h`, first Sunday of the month,
  04:30; images in use are kept). Compare `docker images | wc -l` with
  `docker ps -q | wc -l`.

## Maintenance: stopping a container

`homelab-stack-heal.timer` (every 2 min) restarts containers that exited
non-zero or are `created`/`dead` (max once per 10 min), and those unhealthy for
15 min (max once per hour). Exit 0 is left alone. Log:
`journalctl -t homelab-heal`.

**A `docker stop` comes back within 2 minutes** (exit 137/143). Instead:

```bash
docker compose down <svc>                    # removes it — nothing to heal
systemctl stop homelab-stack-heal.timer     # or pause healing (restart after)
```

`docker compose down` with no service also removes Tier 0. `homelab-unlock`
recreates it; restarting Docker alone does not.

## Checking the data volume

**Never run `e2fsck` directly**: if anything mounts the volume mid-scan, it
corrupts it. `homelab-fsck` blocks mounting for the duration.

Before you start: stack down, `/mnt/data` unmounted, LUKS mapper still open.

1. Run the read-only check (~3 min 30 s). Exit code 4 means it found
   something; that is a normal result.
2. Read the output, then repair if needed.

```bash
homelab-fsck            # read-only, forcing: e2fsck -fn (the default)
homelab-fsck -fy        # repair, once you have READ the read-only output
```

The gate clears on exit, even on errors. `homelab-unlock` refuses to run
while it is up.

## Security-update reboot cadence

- Security updates install automatically; the homelab **never auto-reboots**
  (a reboot is an outage until someone on the LAN unlocks).
- `needrestart` restarts most daemons; its exclusions (dbus, logind, docker, …)
  wait for a reboot. Kernel / core-init updates write
  `/var/run/reboot-required`.
- `Pi pending action` goes DOWN on that file, or when `needrestart -b` lists a
  stale service (checked once a package was installed since boot).
- Pending: `cat /var/run/reboot-required.pkgs`.

Schedule by reachability, not raw CVSS, and by when someone can be on the LAN:

| Situation | Reboot+unlock within |
|-----------|----------------------|
| Routine kernel bump — no active exploitation, or an LPE with no reachable foothold | **≤ 14 days** (next maintenance window) |
| Actively exploited **and** reachable — CISA KEV / public PoC in the netstack, WireGuard, or an unauth-reachable path | **≤ 48 h** |

Offsite reboots itself when an update needs it, at 04:00
(`Unattended-Upgrade::Automatic-Reboot "true"`), roughly monthly.

Why: [ADR-007](../decisions/ADR-007-staged-container-startup.md) (staged
startup), [ADR-013](../decisions/ADR-013-update-patching-strategy.md) (patching).

## Related

- [kill-switch runbook](kill-switch.md) — the remote poweroff lands on this boot path.
- [usb-tamper runbook](usb-tamper.md) — the local poweroff (USB events) lands here too.
- `homelab-lock` — stops the target (containers, heal timer, swap), unmounts and
  relocks the volume.
