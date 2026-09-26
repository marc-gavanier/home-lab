# System

Host configuration of both Pis (Ubuntu Server 24.04 LTS arm64): base settings,
SD-card protection, the missing hardware clock and filesystem checks.

## At a glance

| Setting    | Value                                                     |
|------------|-----------------------------------------------------------|
| Locale     | `fr_FR.UTF-8` generated; system default stays `C.UTF-8`   |
| Timezone   | `Europe/Paris`                                            |
| NTP        | `systemd-timesyncd`                                       |
| Hostname   | set during provisioning                                   |
| Swap       | 4 GiB at `/mnt/data/swapfile` (HDD), `vm.swappiness=10`   |
| Boot args  | `cgroup_memory=1 cgroup_enable=memory` (required for Docker) |
| config.txt | `gpu_mem=16` (no display)                                 |

The swap occupancy alarm (85 %) and the resize procedure live in
`docs/07-observability/`.

## SD write reduction

Every recurring write is moved off the SD card or bounded:

| Write source          | Where it goes                                                          | Role     |
|-----------------------|------------------------------------------------------------------------|----------|
| Docker logs & data-root | HDD; `json-file` logs capped 10 MB × 3                               | `docker` |
| Swap                  | HDD, systemd `.swap` unit                                              | `storage` |
| systemd journal       | persistent, capped (`SystemMaxUse`, drop-in `99-homelab.conf`); stored on the encrypted volume, bind-mounted at unlock | `base`, `storage` |
| `/tmp`                | tmpfs, size-capped                                                     | —        |
| atime updates         | `noatime` on the SD root, `/mnt/data` and the offsite disk             | —        |

`log2ram` is not used: residual `/var/log` traffic is negligible and it loses
the newest logs on a power cut.

## Storage layout

Backup strategy: `docs/06-backup/`.

```
/ (SD 64 GB)
├── /boot/firmware/    # Bootloader, kernel, config.txt
├── /etc/              # System configurations
└── ...                # no Docker store: data-root is /mnt/data/docker

/mnt/data (HDD 5 TB, ext4)
├── docker/            # Docker data-root (images, layers, containers)
├── secrets/           # Credential files, symlinked from their old paths (ADR-011)
├── log/journal/       # Persistent journal, bind-mounted on /var/log/journal
├── library/           # Importer-written media: movies, shows, downloads (ADR-035)
├── services/          # Container persistent data
│   ├── nextcloud/
│   ├── jellyfin/
│   ├── immich/
│   ├── vaultwarden/
│   ├── pihole/
│   ├── wireguard/
│   ├── traefik/
│   └── uptime-kuma/
├── media/             # Operator-written media
│   ├── music/
│   ├── videos/
│   ├── photos/
│   ├── books/
│   └── books-ingest/
├── backups/           # Restic repositories
└── swapfile           # Swap (4 GiB)
```

## The clock this board has before it has a clock

The Pi has no real-time clock, so the first ~142 s of each boot (until NTP)
carry a fallback time.

- Without help that time is the mtime of the systemd binary, weeks old. The
  boot's first journal segment then looks oldest, and the vacuum deletes it
  first: early-boot logs are lost.
- `fake-hwclock` saves the time every 5 min (hourly timer overridden in `base`)
  and at shutdown, and restores it early in boot. Skew drops to about a minute,
  occasionally days.

Three checks watch it:

| Check | Fires |
|-------|-------|
| journal-vs-boot skew over 600 s | reported in `Pi health` from the first second of a bad boot; alarms in `pending` only once the journal reaches 80 % of its cap |
| `Booting Linux on physical CPU` missing from this boot | only once the records are already gone |
| `fake-hwclock-data-is-fresh`, on both hosts | when nothing has saved the time in 15 minutes |

Both hosts carry the skew; only the homelab's journal reaches its cap. A
missing pre-sync segment is not proof of a fix: the vacuum deletes exactly
those.

## Filesystem integrity

| Volume                  | Checked by                                                               | When                                                                                         |
|-------------------------|--------------------------------------------------------------------------|----------------------------------------------------------------------------------------------|
| `/mnt/data` (HDD)       | `e2fsck -p` inside `homelab-unlock`, on the still-unmounted mapper       | every unlock — about a second on a clean filesystem, a real scan after an unclean shutdown   |
| `/` (SD)                | `e2fsck -p` in the **initramfs**, before systemd starts                  | **every boot**, in full — not when a trigger is due. See below                               |
| `/mnt/backup` (offsite) | `e2fsck -p` at boot, which fstab's `passno=2` pulls in                   | clean-flag skip in 0.16 s on normal boots; full check (10.5 s) only on the monthly interval  |
| both                    | the daily disk report reads the superblock error counters (`ext4 clean`) | daily — this catches errors the kernel **already noticed**, which is not a consistency check |

To check the data volume by hand, use `homelab-fsck` (see the
[boot & unlock runbook](../../knowledge/runbooks/boot-and-unlock.md)).

### Why the root filesystem is checked at every boot

`systemd-fsck-root.service` is always skipped, because the initramfs already
checked `/`:

```
systemd-fsck-root.service - File System Check on Root Device was skipped
because of an unmet condition check (ConditionPathExists=!/run/initramfs/fsck-root)
```

The initramfs clock (roughly the previous boot's start) is behind, so every
superblock looks future-dated and gets a full check. `/run/initramfs/fsck.log`
shows:

```
writable: Superblock last write time (Wed Aug 26 20:55:35 2026,
        now = Tue Jul 28 15:04:46 2026) is in the future. FIXED.
```

- **`/` is checked in full at every boot.**
- The `-c`/`-i` triggers never fire (each check resets the mount count and
  `Last checked`); they stay set for when the clock is right. Lowering
  `root_fsck_max_mounts` changes nothing.
- **`Last checked` is not a freshness indicator.**
- `root-was-checked-this-boot` reads `/run/initramfs/fsck.log`; no file means
  `/` was not checked this boot.
- A failed preen drops to an emergency shell, reachable only on site.

### Other controls

- `e2scrub_all.timer` is **masked on both hosts** (LVM only, no LVM here); a
  goss assertion keeps it masked across `e2fsprogs` updates.
- The disk media is covered by the drive's weekly extended self-test, the only
  thing that reads cold bytes. See
  [07-observability](../07-observability/README.md#the-daily-disk-health-report).
