# Runbook — Offsite backup Pi (ADR-010)

Use this page to operate, move, repair or recover from the offsite Pi.

The offsite Pi ("backup", `10.8.0.4` on the VPN) receives a nightly `restic copy`
from the homelab and serves the repo through rest-server in **append-only** mode.
The repo password is deliberately **not** stored on it.

## What runs automatically

| When                  | Unit (host)                                    | What                                                                     | Kuma push monitor |
|-----------------------|------------------------------------------------|--------------------------------------------------------------------------|-------------------|
| Daily 03:00           | `homelab-backup.service` (homelab)             | local backup, then copy of **every** snapshot the offsite repo lacks     | "Offsite backup"  |
| Tuesday 02:00         | `homelab-offsite-check.timer` (homelab)        | `restic check` (metadata) of the offsite repo through the tunnel         | "offsite check"   |
| Daily 08:00           | `offsite-health.timer` (offsite)               | disk/SMART/power self-report; asserts rest-server still refuses deletes  | "offsite health"  |
| 1st of month 04:00    | `offsite-smart-test.timer` (offsite)           | SMART long self-test; the daily report reads the result                  | —                 |

- **A red copy monitor that turns green the next night has self-healed.** Every
  night copies all missing snapshots; re-offering existing ones creates no
  duplicates. No manual copy needed.
- The copy beat only says `offsite copy completed`. To see what was copied, compare
  snapshot counts. `sudo` is required on both sides (`snapshots/` is `0700`);
  without it `ls` is denied and `wc -l` prints a small number, not an error.

  ```bash
  sudo ls /mnt/data/backups/restic-repo/snapshots | wc -l
  ssh offsite 'sudo ls /mnt/backup/restic/snapshots | wc -l'
  ```

  The first runs on the homelab (local repo), the second reads the offsite
  filesystem.

### Why "offsite health" is DOWN

Do not keep a list of the DOWN conditions: read the named assertions in the spec.

```bash
ssh offsite 'sudo sh -c "grep -oE \"^  [^ #][^:]*:\" /etc/goss/offsite-health.yaml | sort | nl"'
```

- `sudo sh -c`: `/etc/goss` is `drwx------`, so a glob or redirect outside the
  privileged shell silently returns nothing.
- The character class must match names with `.`, `/` or `@` (`/mnt/backup`,
  `wg-quick@wg0.service`…), the ones everything else depends on. `nl` numbers the
  output: if the count drops, suspect the pattern before the spec.

One condition is outside the spec: security updates still pending after 48 h
(two daily runs), checked by `offsite-health.sh`. There is no reboot condition: the
host reboots itself at 04:00 (ADR-013).

### Why "offsite health" says "No heartbeat"

The host stopped pushing, so every action above needs the tunnel it may have lost. Check the tunnel
from the homelab first:

```bash
ssh homelab 'docker exec wg-easy wg show wg0 | grep -A3 "10.8.0.4"'
```

- A `latest handshake` under ~3 minutes: the tunnel is up, the fault is on the host; `ssh offsite`.
- An old handshake or none: the host, its network or its power is down. Nothing on it restarts on
  its own, so the fix is on site.

## Management access (SSH)

The tunnel is the only way in: the Pi dials out. Go through the homelab, which holds
the peer identity (`homelab-host`, `10.8.0.5`):

```bash
ssh -J homelab -p <ssh_port_hardened> <admin_user>@10.8.0.4
```

Workstation alias, in `~/.ssh/config`:

```
Host offsite
    HostName 10.8.0.4
    User <admin_user>
    Port <ssh_port_hardened>
    IdentityFile ~/.ssh/id_ed25519
    ProxyJump homelab
```

**A refused jump right after a homelab reboot means `homelab-unlock` is pending**,
not that the offsite Pi is down: the homelab's `wg-quick@wg0` config is on the
encrypted volume, pulled in by `mnt-data.mount`.

## Moving day checklist (installing at the relative's home)

1. Shut down cleanly: `ssh offsite sudo poweroff`. No USB tamper on this host; unplug
   once halted.
2. On site: plug ethernet and power. Nothing to configure: the WireGuard client dials
   out to `vpn.<domain>:51820` from any network.
3. From the homelab: `ping 10.8.0.4`, then
   `systemctl start homelab-offsite-check.service`. Expected: Kuma goes green.
4. Confirm Ansible reaches it through the tunnel (`offsite_ip` tracks
   `offsite_wg_ip`): `cd ansible && ansible offsite -m ping --ask-vault-pass`. The
   `cd` matters: `ansible.cfg` points at the inventory relatively; elsewhere the host
   pattern matches nothing. If the Pi is back on a LAN without its WireGuard config
   (maintenance, reflash), add `-e offsite_ip=<lan_ip>` for that run.

## If the offsite Pi is stolen

The backup disk holds only restic ciphertext and the htpasswd hash. The system card
holds two live credentials: the WireGuard client key and the health report's Kuma
push URL.

1. wg-easy UI → delete client `offsite-backup`, following
   [wireguard-peer-revocation](wireguard-peer-revocation.md). This is the one case where an
   infrastructure peer is removed; never disable it instead.
2. Rotate `rest_server_auth_password` (vault). It guards bandwidth, not
   confidentiality.
3. Recreate the Kuma "offsite health" push monitor (a thief could forge green pings
   with its token).
4. Nothing to do for the data: the repo password was never on the Pi.

## First initialisation (once, from the homelab)

resticprofile never initialises a repository (`initialize: false`). Create the offsite one with the
local repo's chunker parameters, or deduplication between the two is lost (ADR-010). As root:

```bash
set -a; . /opt/homelab/backup.env; set +a
export RESTIC_FROM_REPOSITORY="$RESTIC_REPOSITORY" RESTIC_FROM_PASSWORD="$RESTIC_PASSWORD" \
  RESTIC_REPOSITORY="$OFFSITE_RESTIC_REPOSITORY" RESTIC_PASSWORD="$OFFSITE_RESTIC_PASSWORD" \
  RESTIC_REST_USERNAME="$OFFSITE_REST_USER" RESTIC_REST_PASSWORD="$OFFSITE_REST_PASSWORD"
restic init --copy-chunker-params
```

## Never run two copies at once

Two concurrent `restic copy` runs to the append-only repo leave **permanent
duplicate packs** (append-only blocks the cleanup; an interrupted copy also leaves
packs the next run re-uploads). The profile lock
`/run/lock/resticprofile-homelab.lock` covers the whole run, backup and copy; a
second run is refused with "another process is already running this profile".

That lock only works if you go through resticprofile, never `restic` directly. For
a manual copy, as root, load `backup.env` first — without it the Kuma push URLs are
missing and the result is reported nowhere:

```bash
set -a; . /opt/homelab/backup.env; set +a
resticprofile -c /opt/homelab/resticprofile.yaml -n homelab copy
```

For any multi-hour seed, disable the timer and re-enable it after:
`systemctl disable --now homelab-backup.timer`.

## Manual retention (rare — when disk usage approaches 85%)

Append-only means no automatic pruning. Run on the offsite Pi, with the offsite repo
password fetched from outside this host at that moment. Type it at restic's prompt;
never put it in a variable or file on this host.

1. Check restic is installed (the `offsite-backup` role installs it with `sqlite3`):
   `command -v restic`.
2. Prune:

   ```bash
   sudo systemctl stop rest-server
   sudo restic -r /mnt/backup/restic forget \
       --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune
   sudo chown -R rest-server:rest-server /mnt/backup/restic
   sudo systemctl start rest-server
   ```

## Deep integrity check (on demand — never yet performed)

There is no schedule: the weekly `homelab-offsite-check.service` is a **metadata**
check on purpose (reading the data back would pull hundreds of GB over a domestic
uplink). Run this only when you decide to.

### Before you start

- **Disable the backup timer for the duration.** `check` takes an exclusive lock on
  the repo, and the `offsite` profile lock (`resticprofile-offsite.lock`) is not the
  nightly copy's (`resticprofile-homelab.lock`), so nothing stops them colliding.
- **Run it under `tmux` or `screen`.** A dropped SSH session kills the check and
  leaves the lock behind.

### Steps

1. Disable the timer and run the metadata check:

   ```bash
   sudo systemctl disable --now homelab-backup.timer
   sudo systemctl start homelab-offsite-check.service
   ```

2. Read back 2% of the data (several hours over the WAN):

   ```bash
   sudo -i
   set -a; . /opt/homelab/backup.env; set +a
   RESTIC_REPOSITORY="$OFFSITE_RESTIC_REPOSITORY" RESTIC_PASSWORD="$OFFSITE_RESTIC_PASSWORD" \
   RESTIC_REST_USERNAME="$OFFSITE_REST_USER" RESTIC_REST_PASSWORD="$OFFSITE_REST_PASSWORD" \
   restic check --read-data-subset=2%
   ```

3. Re-enable the timer and check it is armed:

   ```bash
   sudo systemctl enable --now homelab-backup.timer
   systemctl list-timers homelab-backup.timer
   ```

### If a lock is left behind

The local stale-lock assertion (`restic-repo-has-no-stale-lock`) covers the local
repo only; the offsite repo has its own in `goss-offsite-health.yaml.j2`.

**List before unlocking.** A lock with a live restic behind it is doing its job.
In the step-2 shell, a bare `restic` reaches the **local** repo (`backup.env`). For the
offsite repo, export its variables first:

```bash
export RESTIC_REPOSITORY="$OFFSITE_RESTIC_REPOSITORY" RESTIC_PASSWORD="$OFFSITE_RESTIC_PASSWORD" \
  RESTIC_REST_USERNAME="$OFFSITE_REST_USER" RESTIC_REST_PASSWORD="$OFFSITE_REST_PASSWORD"
```

```bash
restic list locks
restic unlock
```

`restic unlock` removes stale locks only. Last resort, and only with **no**
restic running anywhere:

```bash
restic unlock --remove-all
```
- A lock from the offsite host's manual prune carries `hostname=offsite`; the homelab
  cannot age it out. Check both hosts before calling a lock stale.

`restic unlock` does not touch resticprofile's **profile** lock, the one behind
"another process is already running this profile":

```bash
ls -l /run/lock/resticprofile-*.lock
pgrep -a resticprofile || rm /run/lock/resticprofile-homelab.lock
```

The `rm` runs only if `pgrep` finds nothing. `/run/lock` is a tmpfs, so a reboot also
clears it. `force-inactive-lock` stays unset on purpose: breaking a lock
automatically hides the failure.

### If `check` tells you to run `restic repair`

restic's own advice (`repair index`, `repair snapshots`, `repair packs`) rewrites or deletes files.
Through rest-server's `--append-only`, as from the homelab, every delete but a lock's is refused.
Run it on the offsite Pi as in [Manual retention](#manual-retention-rare--when-disk-usage-approaches-85):
stop rest-server, run the repair against `/mnt/backup/restic`, `chown` back to `rest-server`, start
rest-server, then run the check again.

## Disaster recovery (homelab lost)

### Before you start

- Use the **offsite** password, the vaulted `offsite_restic_password`, **not** the
  local `restic_password`. They differ by design.
- Keep a copy of that password that survives whatever takes out the homelab, stored
  **apart from** the media carrying the repository: together, one theft yields every
  snapshot in plaintext (ADR-010).

### Steps

1. Read the repo where it stands (faster), or bring back the Pi or its SSD. On the
   relative's LAN, with no tunnel and no homelab:

   ```bash
   ssh -o ProxyJump=none -p <ssh_port_hardened> <admin_user>@<pi-lan-ip>
   sudo restic -r /mnt/backup/restic snapshots
   ```

   - Host-key verification trips: the key is known under the tunnel address. Compare
     the fingerprint with the known one; do not accept blindly.
   - `sudo` is required: the repo belongs to `rest-server`, and restic fails on
     `keys/` without it.

2. Restore, on any machine, with the offsite password:
   `restic -r /mnt/backup/restic restore latest --target /restore`.
3. Re-provision a new Pi from the git repo (`ansible/`) and put back
   `/restore/mnt/data/...`. The `.env` files are in `/restore/mnt/data/secrets`;
   `/restore/opt/homelab` holds only symlinks to them (ADR-011).
4. Follow [Full disaster recovery](restore-from-backup.md#full-disaster-recovery).

See also: ADR-010, [`backup-monitoring.md`](backup-monitoring.md),
[`restore-from-backup.md`](restore-from-backup.md).
