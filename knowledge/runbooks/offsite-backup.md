# Runbook — Offsite backup Pi (ADR-010)

The offsite Pi ("backup", 10.8.0.4 on the VPN) receives a nightly
`restic copy` from the homelab and exposes the repo via rest-server in
append-only mode. The repo password is deliberately NOT stored on it.

## Daily operation (all automatic)

- 03:00 — homelab `backup.sh`: local backup, then `restic copy latest` to
  `rest:http://10.8.0.4:8000/` (Kuma push monitor "offsite copy").
- Sunday 06:00 — homelab `homelab-offsite-check.timer`: `restic check` of the
  offsite repo through the tunnel (Kuma push monitor "offsite check").
- Sunday 08:00 — offsite `offsite-health.timer`: disk/SMART/power self-report
  (Kuma push monitor "offsite health"). DOWN if disk >85%, any SMART
  early-warning counter leaves zero (realloc, grown bad blocks, program/erase
  fail, end-to-end, uncorrectable, CRC), spare blocks <50%, SSD ≥70°C, the
  last self-test failed or is >35 days old (dead-timer detection, compared
  in drive power-on hours), or the Pi logged undervoltage.
- 1st of the month 04:00 — offsite `offsite-smart-test.timer`: SMART long
  self-test (the drive scans its own surface); result read by the Sunday
  health report.

## Moving day checklist (installing at the relative's home)

1. Shut down cleanly: `ssh -p <ssh_port_hardened> backup sudo poweroff` (no USB tamper on
   this host; unplugging is safe once halted).
2. At the relative's home: plug ethernet + power. Nothing to configure — the
   WireGuard client dials out to vpn.<domain>:51820 from any network.
3. Verify from the homelab: `ping 10.8.0.4`, then
   `systemctl start homelab-offsite-check.service` and check Kuma goes green.
4. Update `offsite_ip` in `host_vars/offsite/main.yml` to `10.8.0.4` (the
   VPN IP becomes the management path) and commit.

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
prune. `backup.sh` now guards its copy step with
`flock /var/lock/offsite-copy.lock`; any manual copy/seed MUST use the same
lock:

```bash
flock /var/lock/offsite-copy.lock restic copy ...
```

Also disable the backup timer for the duration of any multi-hour seed:
`systemctl disable --now homelab-backup.timer` (re-enable after).

## Manual retention (rare — when disk usage approaches 85%)

Append-only means no automatic pruning. On site (or via SSH), with the repo
password fetched from Vaultwarden AT THAT MOMENT (never store it on the Pi):

```bash
sudo apt install restic                    # not installed by default here
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

1. Retrieve the offsite Pi or its SSD.
2. On any machine: `restic -r /mnt/backup/restic restore latest --target /restore`
   with the **offsite repo password** (Vaultwarden + offline copy — this
   password is the root of the whole recovery chain).
3. Re-provision a new Pi from the git repo (`ansible/`), reinject
   `/restore/mnt/data/...` and the `.env` files from `/restore/opt/homelab`.
4. Follow "Full disaster recovery" in `restore-from-backup.md`.

See also: ADR-010, `backup-monitoring.md`, `restore-from-backup.md`.
