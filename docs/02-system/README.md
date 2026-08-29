# System

## OS: Ubuntu Server 24.04 LTS arm64

Chosen for its stability (10-year LTS), excellent ARM64 support on Raspberry Pi 4, and abundant documentation.

## Base Configuration

- Locale: `fr_FR.UTF-8`
- Timezone: `Europe/Paris`
- NTP: synchronized via `systemd-timesyncd`
- Hostname: defined during provisioning

## Raspberry Pi Optimizations

### Swap
- Swap on HDD (not SD) to preserve the card
- Reduced swappiness (`vm.swappiness=10`) — use swap as last resort
- 4 GiB swap file at `/mnt/data/swapfile` — doubled from 2 GiB before the
  occupancy alarm could be set against it (`docs/07-observability/`, which owns
  the 85 % threshold and the resize procedure)

### SD Write Reduction
The SD card has limited write endurance, so every recurring write is pushed
off it or bounded:
- **Docker logs & data-root** on the HDD (`json-file`, capped 10 MB × 3) — the
  biggest hidden write source on a Docker Pi (`docker` role)
- **Swap** on the HDD, never the SD (systemd `.swap` unit, `swappiness=10`)
- **systemd journal** kept persistent but capped (`SystemMaxUse`, drop-in
  `99-homelab.conf`) — bounds growth without losing boot logs (`base` role)
- **`/tmp` on tmpfs** (RAM), size-capped — removes the temp-file write surface
- **`noatime`** on every write surface (SD root, `/mnt/data`, offsite disk)

`log2ram` was evaluated and deliberately **not** used: once the journal is
capped and Docker logs are off-card, the residual `/var/log` traffic is
negligible, and log2ram's RAM buffer loses the newest logs on a power cut —
working against the "unexplained poweroff → reflash" diagnosis policy.

### Kernel
- `cgroup_memory=1 cgroup_enable=memory` in boot parameters (required for Docker)
- `gpu_mem=16` in config.txt (minimum GPU, no display needed)

## Storage Layout

See `docs/06-backup/` for backup strategy.

```
/ (SD 64 GB)
├── /boot/firmware/    # Bootloader, kernel, config.txt
├── /etc/              # System configurations
├── /var/lib/docker/   # Docker images (or moved to HDD)
└── ...

/mnt/data (HDD 5 TB, ext4)
├── services/          # Container persistent data
│   ├── nextcloud/
│   ├── jellyfin/
│   ├── immich/
│   ├── vaultwarden/
│   ├── pihole/
│   ├── wireguard/
│   ├── traefik/
│   └── uptime-kuma/
├── media/             # Media files
│   ├── music/
│   ├── videos/
│   └── photos/
├── backups/           # Restic repositories
└── swapfile           # Swap (4 GiB)
```

### Filesystem integrity — what checks what

| Volume                  | Checked by                                                               | When                                                                                         |
|-------------------------|--------------------------------------------------------------------------|----------------------------------------------------------------------------------------------|
| `/mnt/data` (HDD)       | `e2fsck -p` inside `homelab-unlock`, on the still-unmounted mapper       | every unlock — about a second on a clean filesystem, a real scan after an unclean shutdown   |
| `/` (SD)                | `e2fsck -p` in the **initramfs**, before systemd starts                  | **every boot**, in full — not when a trigger is due. See below                               |
| `/mnt/backup` (offsite) | `e2fsck -p` at boot, which fstab's `passno=2` pulls in                   | every boot, same reason — measured 10.5 s, +1.6 s on total boot (2026-08-29)                 |
| both                    | the daily disk report reads the superblock error counters (`ext4 clean`) | daily — this catches errors the kernel **already noticed**, which is not a consistency check |

Neither root filesystem had ever been checked before 2026-08-25. `Last checked`
read `Tue Feb 10 04:01:10 2026` on **both** hosts — the mkfs timestamp baked
into the Ubuntu image, not a date anyone verified anything on.

**What actually runs the check, corrected 2026-08-29 (#260).** This section said
`systemd-fsck-root.service` consulted the `-c`/`-i` triggers and checked when one
was due. That service never runs. It is skipped at every boot:

```
systemd-fsck-root.service - File System Check on Root Device was skipped
because of an unmet condition check (ConditionPathExists=!/run/initramfs/fsck-root)
```

The initramfs has already done it — and the initramfs runs before any time sync
on a host with no RTC, so its clock reads a frozen value. On both Pis that value
is `2026-07-28 17:04`, which is also what four consecutive boots stamp as their
first journal entry. Every superblock therefore looks future-dated to it, and
`/run/initramfs/fsck.log` says so on every boot:

```
writable: Superblock last write time (Wed Aug 26 20:55:35 2026,
        now = Tue Jul 28 15:04:46 2026) is in the future. FIXED.
```

Three consequences, and the first is the one that matters:

1. **The root filesystem is checked in full at every boot** — more often than
   either trigger would ever have asked for. The gap this section was written to
   close is closed, by an accident rather than by the triggers.
2. **Neither trigger can fire.** A full check resets the mount count and rewrites
   `Last checked` backwards to the frozen value, which is why both hosts read
   `Last checked: Tue Jul 28` and `Mount count: 1` after three and four boots.
   Lowering `root_fsck_max_mounts` would change nothing.
3. **`Last checked` is not a freshness indicator here.** Do not read it as one.

The `-c`/`-i` values are still set and still asserted, so the configuration is
right the day the clock is; `passno` is what does the work today. What tests
capability rather than configuration is `root-was-checked-this-boot`, which
reads `/run/initramfs/fsck.log` — that file lives in `/run`, so it is this
boot's and no other, and its absence means nothing checked the root filesystem
when the host came up.

It changes a failure mode, which is the part worth knowing before a reboot:
`e2fsck -p` fixes only what is unambiguously safe and systemd turns anything
else into an emergency shell. On a host whose only route in is a tunnel that
needs the encrypted volume unlocked, that means physically present or not at
all. That is the right outcome for a root filesystem that fails to preen, and it
is why the first firing was scheduled for a supervised on-site reboot rather
than left to happen on its own.

`e2scrub_all.timer` is **masked on both hosts** and is not part of that table.
It scrubs LVM logical volumes; neither host has LVM, so it ran green every week
over zero bytes. A goss assertion now keeps it masked, because the unit ships
with `e2fsprogs` and a package update could put the green no-op back.

The table covers **filesystem** consistency. The media underneath it is a
separate question and has its own control — the drive's weekly extended
self-test, which is the only thing here that reads cold bytes. See
[07-observability](../07-observability/README.md#the-daily-disk-health-report)
for why it was briefly removed and what that cost.
