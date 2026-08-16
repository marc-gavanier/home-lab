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

The header is one half of the secret: **header + passphrase = your data**. The
header *alone* does not expose anything (an attacker still needs the passphrase),
so physical control of an offline copy is a legitimate protection. But treat it
as sensitive: stored *off* the volume, never in the repo, never on the Pi
long-term.

## Create a header backup

On the Pi, as root (the script is deployed to `/usr/local/bin` by the storage role):

```bash
sudo homelab-luks-header-backup                # defaults to /dev/sda1
# or point at another device:
sudo homelab-luks-header-backup /dev/sdX1
```

Equivalent one-liner if the script isn't to hand:

```bash
sudo cryptsetup luksHeaderBackup /dev/sda1 \
  --header-backup-file /tmp/luks-header-$(date +%Y%m%d).img
```

Then move it off the machine and destroy the working copy:

1. **Primary — an offline copy, on separate media, kept away from the Pi.** This
   is the copy that matters: independent hardware, survives the loss of the Pi
   and the whole `/mnt/data` volume. Plaintext is acceptable (the header alone
   is not enough without the passphrase); encrypt it if you prefer, but only
   with a secret you will still have *in the disaster* (a symmetric passphrase
   in your password manager, or a GPG key whose private half is itself backed up
   offline — otherwise you lock yourself out). Ideally keep a second independent
   copy on other media — 3-2-1 applies to the header too.
2. **Do NOT rely on Vaultwarden as the (only) copy.** Vaultwarden's own data
   lives on this same LUKS volume, so a damaged header takes Vaultwarden with it —
   a circular dependency. A Vaultwarden attachment can be a *convenience* extra
   (it also rides along in the offsite restic backup), never the primary.
3. Shred the working copy: `shred -u /tmp/luks-header-*.img`. Note `/tmp` is a
   tmpfs (RAM), so the file also vanishes on reboot — but shred it now, and copy
   it off *before* any reboot.

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

The mapper is `data_crypt`, not `data` — `luks_mapper_name` in
`group_vars/all.yml`, and `mnt-data.mount` looks for `/dev/mapper/data_crypt`.
Opening it under any other name gives a volume that `/mnt/data` will not mount.

```bash
# Retrieve luks-header-*.img from one of the offline copies first.

# The volume must be closed before the header is overwritten. Check first:
# "inactive" is the good case; anything else must be closed, and the close
# must succeed — do not swallow its error, a restore over an open volume is
# how you lose the disk.
sudo cryptsetup status data_crypt
sudo cryptsetup luksClose data_crypt      # only if the status showed it active

sudo cryptsetup luksHeaderRestore /dev/sda1 \
  --header-backup-file /path/to/luks-header-YYYYMMDD.img

# Then unlock as usual (staged-startup / homelab-unlock path):
sudo cryptsetup luksOpen /dev/sda1 data_crypt
```

After restore, unlock through the normal boot procedure and let the staged
startup bring services up. See also: `restore-from-backup.md`, ADR-011 (secrets
off the SD card), `docs/06-backup/README.md`.
