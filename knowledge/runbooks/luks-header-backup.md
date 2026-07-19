# Runbook — LUKS header backup & restore

The 5 TB data disk is a single LUKS container opened at unlock time (ADR-011,
manual SSH unlock). Its **header** (LUKS2 metadata + keyslots, 2–16 MB at the
start of the partition) is what turns the passphrase into the master key. If the
header is corrupted — a bad sector on the aging HDD, or a botched `cryptsetup`
operation — the volume is **unrecoverable even with the correct passphrase**.
That single point of failure would take the live data *and* the local restic
repo (both on `/mnt/data`) at once; only the offsite repo would survive.

A header backup is the cheap backstop for the whole LUKS-unlock model. Take one
now, and again after **any** keyslot change.

## Sensitivity

The header file is **as sensitive as the passphrase**: header + passphrase =
your data. Treat it exactly like the offsite repo password — stored *off* the
volume, never in the repo, never on the Pi long-term.

## Create a header backup

On the Pi, as root:

```bash
sudo /path/to/ops/luks-header-backup.sh        # defaults to /dev/sda1
# or point at another device:
sudo /path/to/ops/luks-header-backup.sh /dev/sdX1
```

Equivalent one-liner if the script isn't to hand:

```bash
sudo cryptsetup luksHeaderBackup /dev/sda1 \
  --header-backup-file /tmp/luks-header-$(date +%Y%m%d).img
```

Then move it off the machine and destroy the working copy:

1. Attach it to a **secure note in Vaultwarden** (your password vault — offsite).
2. Copy it to an **offline USB key** kept off-site (same discipline as the
   offsite repo password: two independent, off-machine locations).
3. Shred the working copy: `shred -u /tmp/luks-header-*.img`.

## When to refresh it

Re-take the backup after any operation that changes the keyslots, otherwise an
old header restore would reinstate a superseded passphrase:

- `cryptsetup luksAddKey` / `luksRemoveKey` / `luksChangeKey`
- `cryptsetup luksKillSlot`
- Any re-encryption or LUKS format change

(No change on ordinary unlock/mount cycles — the header is static then.)

## Restore a damaged header (disaster recovery)

> ⚠️ Overwrites the on-disk header. Only do this when the current header is
> known-bad, and only with a header taken from **this** disk (a mismatched
> header destroys access). The volume must be closed.

```bash
# Retrieve luks-header-*.img from Vaultwarden or the offline USB key first.
sudo cryptsetup luksClose data 2>/dev/null || true    # if mapped
sudo cryptsetup luksHeaderRestore /dev/sda1 \
  --header-backup-file /path/to/luks-header-YYYYMMDD.img

# Then unlock as usual (staged-startup / homelab-unlock path):
sudo cryptsetup luksOpen /dev/sda1 data
```

After restore, unlock through the normal boot procedure and let the staged
startup bring services up. See also: `restore-from-backup.md`, ADR-011 (secrets
off the SD card), `docs/06-backup/README.md`.
