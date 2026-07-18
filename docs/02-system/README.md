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
- 2 GB swap file at `/mnt/data/swapfile`

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
└── swapfile           # Swap (2 GB)
```
