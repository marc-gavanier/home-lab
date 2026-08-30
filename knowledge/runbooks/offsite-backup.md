# Runbook — Offsite backup Pi (ADR-010)

The offsite Pi ("backup", 10.8.0.4 on the VPN) receives a nightly
`restic copy` from the homelab and exposes the repo via rest-server in
append-only mode. The repo password is deliberately NOT stored on it.

## Daily operation (all automatic)

- 03:00 — `homelab-backup.service` runs resticprofile twice: a local backup, then
  an offsite copy of **every** snapshot not already there (Kuma push monitor
  "offsite copy").
  It is a retry window, not a single `restic copy latest`: a night that failed its copy
  is picked up by the following nights instead of being lost (#158). Re-offering
  snapshots already present creates no duplicates — the message reads e.g.
  `1 new, 7 already there`. So a red copy monitor that goes green the next night has
  **self-healed**, and needs no manual copy.
- Sunday 06:00 — homelab `homelab-offsite-check.timer`: `restic check` of the
  offsite repo through the tunnel (Kuma push monitor "offsite check").
- Sunday 08:00 — offsite `offsite-health.timer`: disk/SMART/power self-report
  (Kuma push monitor "offsite health").

  **Do not maintain the DOWN conditions by hand — read them.** This list drifted
  8 assertions behind the spec between 2026-08-21 and 2026-08-29, while
  `backup-monitoring.md` pointed readers here for "the exact DOWN conditions".
  The authoritative list is the named assertions in the spec itself:

  ```bash
  ssh offsite 'sudo sh -c "grep -oE \"^  [a-z0-9-]+:\" /etc/goss/offsite-health.yaml"'
  ```

  Note the `sudo sh -c`: `/etc/goss` is `drwx------`, so a glob or a redirect
  written outside the privileged shell silently returns nothing.

  **The count and the taxonomy that used to sit here have been deleted, and the
  deletion is the fix.** This paragraph said "22 assertions, in five groups" and
  listed them, four lines under its own instruction not to maintain the DOWN
  conditions by hand. It had already been corrected once for drifting eight
  assertions behind the spec between 2026-08-21 and 2026-08-29; it then drifted
  **seven in a single day**, because #291 and #292 added conditions — the clock,
  the control parity, the unit state — that fit none of the five groups. An
  operator diagnosing a DOWN would have read a taxonomy that could not contain
  the assertion which fired, and gone looking for a fault in disk or SMART.
  Run the command above; it is the answer.

  **One condition is not in the spec, deliberately**: security updates still
  unapplied after 48 h. It needs to remember when the count first went nonzero,
  which goss cannot do, so it lives in `offsite-health.sh`. Its 48 h is measured
  against a weekly cadence — read the script's own comment before changing it.

  CPU temperature was reported and never compared until #201, on a host sampled
  once a week.
- 1st of the month 04:00 — offsite `offsite-smart-test.timer`: SMART long
  self-test (the drive scans its own surface); result read by the Sunday
  health report.

## Management access (SSH)

Since the 2026-07-25 move the tunnel is the only way in: the LAN IP the Pi was
prepared on no longer routes, and the Pi dials out rather than accepting an
inbound connection. Reach it through the homelab, which holds the peer
identity (`homelab-host`, 10.8.0.5):

```bash
ssh -J homelab -p <ssh_port_hardened> <admin_user>@10.8.0.4
```

Worth a workstation alias — `~/.ssh/config`:

```
Host offsite
    HostName 10.8.0.4
    User <admin_user>
    Port <ssh_port_hardened>
    IdentityFile ~/.ssh/id_ed25519
    ProxyJump homelab
```

The jump only works once the homelab has been unlocked: its `wg-quick@wg0`
config lives on the encrypted volume, so the tunnel is pulled in by
`mnt-data.mount`, not at boot. A refused jump right after a homelab reboot
means `homelab-unlock` is still pending, not that the offsite Pi is down.

## Moving day checklist (installing at the relative's home)

1. Shut down cleanly: `ssh offsite sudo poweroff` (no USB tamper on
   this host; unplugging is safe once halted).
2. At the relative's home: plug ethernet + power. Nothing to configure — the
   WireGuard client dials out to vpn.<domain>:51820 from any network.
3. Verify from the homelab: `ping 10.8.0.4`, then
   `systemctl start homelab-offsite-check.service` and check Kuma goes green.
4. Nothing to change in the inventory: `offsite_ip` tracks `offsite_wg_ip`
   since the 2026-07-25 move, so Ansible already manages this host through
   the tunnel. Confirm with
   `cd ansible && ansible offsite -m ping --ask-vault-pass` — the `cd` matters,
   `ansible.cfg` points at `inventory/hosts.yml` relatively, so from anywhere
   else Ansible parses no inventory and just warns that the host pattern
   matched nothing.
   The override goes the *other* way now — if the Pi ever comes home for
   maintenance, or is reflashed before its WireGuard config exists, reach it
   on the LAN for that run only: `-e offsite_ip=<lan_ip>`.

## If the offsite Pi is stolen

The SSD holds only restic ciphertext, the htpasswd hash and the WireGuard
client key. The WG key is the only live credential:
1. wg-easy UI → delete/disable client `offsite-backup` (revokes VPN access).
2. Rotate `rest_server_auth_password` (vault) — it only guards bandwidth, not
   data confidentiality.
3. Recreate the Kuma "offsite health" push monitor (its token is in the
   health script — a thief could forge green pings with it).
4. The repo password was never on the Pi: backups remain confidential.

## Never run two copies at once

Two concurrent `restic copy` processes to the append-only repo re-upload
each other's packs as **permanent duplicates** (append-only blocks the
cleanup; interrupted copies also leave unindexed packs that the next run
re-uploads entirely). The 2026-07-12 initial seed collided with the 03:00
nightly copy this way: ~100 GB of duplicates, reclaimed by a one-time manual
prune. The profile now guards the WHOLE run — backup and copy alike — with
`lock: /var/lock/resticprofile-homelab.lock`, which is wider than the
`flock` on the copy step it replaces. A second invocation is refused with
"another process is already running this profile".

That protection only holds if manual runs go through resticprofile rather than
calling restic directly:

```bash
resticprofile -c /opt/homelab/resticprofile.yaml -n homelab copy
```

> **Corrected 2026-08-29.** Until today this block showed
> `flock /var/lock/offsite-copy.lock restic copy ...` — a direct restic call
> holding the narrower lock that ADR-031 replaced, which is exactly what the
> sentence above it forbids. Someone reaching for a manual copy under pressure
> copies the block, not the sentence, and this page is the one that documents
> what that costs.

Also disable the backup timer for the duration of any multi-hour seed:
`systemctl disable --now homelab-backup.timer` (re-enable after).

## Manual retention (rare — when disk usage approaches 85%)

Append-only means no automatic pruning. On site (or via SSH), with the repo
password fetched from outside this host AT THAT MOMENT (never store it on the
Pi):

```bash
# restic and sqlite3 are installed by the offsite-backup role since ddc44c5 —
# they were added the day a real recovery attempt found them missing. Verify
# rather than assume on a freshly rebuilt host: command -v restic
sudo systemctl stop rest-server            # free the repo
sudo restic -r /mnt/backup/restic forget \
    --keep-daily 7 --keep-weekly 4 --keep-monthly 12 --prune
sudo systemctl start rest-server
```

Enter the password at restic's interactive prompt (never export it into a
shell variable or file on this host).

## Deep integrity check (quarterly, manual, from the homelab)

```bash
sudo systemctl start homelab-offsite-check.service   # weekly metadata check
# Deep read of 2% of the data (WAN-heavy once offsite — run overnight):
sudo -i
set -a; . /opt/homelab/backup.env; set +a
RESTIC_REPOSITORY="$OFFSITE_RESTIC_REPOSITORY" RESTIC_PASSWORD="$OFFSITE_RESTIC_PASSWORD" \
RESTIC_REST_USERNAME="$OFFSITE_REST_USER" RESTIC_REST_PASSWORD="$OFFSITE_REST_PASSWORD" \
restic check --read-data-subset=2%
```

## Disaster recovery (homelab lost)

1. Retrieve the offsite Pi or its SSD — **or read it where it stands**, which
   the 2026-08-15 drill proved works and is faster. On the relative's LAN, with
   no tunnel and no homelab:

   ```bash
   ssh -o ProxyJump=none -p <ssh_port_hardened> <admin_user>@<pi-lan-ip>
   sudo restic -r /mnt/backup/restic snapshots
   ```

   Two things bite here. The repository belongs to `rest-server`, so without
   `sudo` restic fails on `keys/` before asking for anything. And the host key
   is known under the tunnel address, so connecting by LAN address trips
   verification — compare the fingerprint against the known one instead of
   accepting blindly.
2. On any machine: `restic -r /mnt/backup/restic restore latest --target /restore`
   with the **offsite repo password** — the vaulted `offsite_restic_password`,
   **not** the local `restic_password`. They differ by design, and the first
   drill attempt failed for exactly that reason. This password is the root of
   the whole recovery chain; make sure a copy of it survives whatever takes out
   the homelab — and keep that copy **physically apart from the media carrying
   the repository**. Stored side by side, they stop being two things: one theft
   hands over the plaintext of every snapshot, and the design's promise that a
   stolen disk yields only ciphertext (ADR-010) quietly stops being true.
3. Re-provision a new Pi from the git repo (`ansible/`), reinject
   `/restore/mnt/data/...` and the `.env` files from `/restore/opt/homelab`.
4. Follow "Full disaster recovery" in `restore-from-backup.md`.

See also: ADR-010, `backup-monitoring.md`, `restore-from-backup.md`.
