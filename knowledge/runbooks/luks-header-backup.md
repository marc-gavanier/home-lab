# Runbook — LUKS header backup & restore

Use this page to back up the LUKS header of the 5 TB data disk, and to restore it
if it is damaged. Without a good header the volume is unrecoverable even with the
right passphrase, taking the live data and the local restic repo with it; only the
offsite repo would survive (ADR-011).

## Before you start

- **Disarm the USB tamper response before touching any cable.** While
  `/run/homelab/tamper-armed` exists, any plug or unplug powers the Pi off, and
  `wg0.conf` lives on this volume: no tunnel without an unlock, no unlock without
  the tunnel, so someone must be on site. Run `sudo homelab-tamper-disarm` before
  the copy and `sudo homelab-tamper-arm` after (ADR-008).
- **The header is sensitive.** Header + passphrase = your data. The header alone
  exposes nothing, but keep it off the volume, out of the repo, and not on the Pi
  long-term.

## Create a header backup

Take one now, and again after any keyslot change.

1. On the Pi, run the script (deployed to `/usr/local/bin` by the storage role):

   ```bash
   sudo homelab-luks-header-backup                # defaults to /dev/sda1
   sudo homelab-luks-header-backup /dev/sdX1
   ```

   It warns if tamper is armed, and lists leftovers from earlier runs. Without
   the script:

   ```bash
   sudo cryptsetup luksHeaderBackup /dev/sda1 \
     --header-backup-file /root/luks-header-$(date +%Y%m%d).img
   ```

2. Copy it to offline media kept away from the Pi. This is the copy that
   matters. Plaintext is acceptable; if you encrypt it, use a secret you will
   still have in the disaster. Keep a second independent copy if you can (3-2-1).
3. Do not rely on Vaultwarden as the only copy: its data lives on this same
   volume. An attachment there is a convenience extra only.
4. Shred the working copy (mandatory, `/root` survives reboots):

   ```bash
   sudo sh -c 'shred -u /root/luks-header-*.img'
   ```

## When to refresh it

Re-take the backup after any keyslot change, or an old restore brings back a
superseded passphrase:

- `cryptsetup luksAddKey` / `luksRemoveKey` / `luksChangeKey`
- `cryptsetup luksKillSlot`
- any re-encryption or LUKS format change

Unlock and mount cycles do not change the header.

To check a copy you hold: `sudo cryptsetup luksDump <device>` and
`cryptsetup luksDump <copy>` must print the same `Epoch` and keyslots. A
different `Epoch` means the copy is stale: re-take it.

## Restore a damaged header (disaster recovery)

### Before you start

- ⚠️ This overwrites the on-disk header. Only restore when the current header is
  known-bad, and only a header taken from **this** disk.
- The volume must be closed. Restoring over an open volume loses the disk.
- The mapper is `data_crypt` (`luks_mapper_name` in `group_vars/all.yml`);
  `mnt-data.mount` looks for `/dev/mapper/data_crypt`.

### Steps

1. Retrieve `luks-header-*.img` from an offline copy.
2. Check whether the volume is open. Ask the disk, not a name:
   `cryptsetup status <typo>` also prints "is inactive".

   ```bash
   lsblk -o NAME,TYPE,MOUNTPOINTS /dev/sda1
   ```

   A crypt child (`└─data_crypt crypt /mnt/data`) means it is open.
3. If open, close it, and stop if the close fails:

   ```bash
   sudo cryptsetup luksClose data_crypt
   ```

4. Run `lsblk -o NAME,TYPE,MOUNTPOINTS /dev/sda1` again. Go on only if `sda1`
   has no child at all; otherwise stop.
5. Restore:

   ```bash
   sudo cryptsetup luksHeaderRestore /dev/sda1 \
     --header-backup-file /path/to/luks-header-YYYYMMDD.img
   ```

6. Unlock with `homelab-unlock`, never a raw `luksOpen`. A raw open lets units
   with `RequiresMountsFor=/mnt/data` mount the volume within ~0.5 s, so the
   integrity check is skipped (`integrity check SKIPPED: /dev/mapper/data_crypt
   was already mounted when the check was due`) right when the filesystem most
   likely needs `e2fsck`.

   ```bash
   sudo homelab-unlock
   ```

7. Let the staged startup bring services up, as on any boot.

See also: `restore-from-backup.md`, ADR-011, `docs/06-backup/README.md`.
