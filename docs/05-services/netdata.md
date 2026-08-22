# Netdata

Real-time system monitoring dashboard.

## Access

- URL: `https://system.example.com` (VPN only)

## What It Does

- Real-time metrics: CPU, RAM, disk, network, temperature
- Docker container monitoring
- Per-process resource usage
- Automatic anomaly detection
- No configuration needed — works out of the box

## First Steps

1. Open `https://system.example.com`
2. Explore the dashboard — metrics are collected automatically
3. Key sections to check:
   - **System Overview**: CPU, RAM, swap
   - **Disks**: SD card and HDD usage, IOPS
   - **Sensors**: SoC temperature (throttling at 80°C)
   - **Docker containers**: per-container CPU/RAM usage
   - **Network**: bandwidth, connections

## Useful Metrics for Home Lab

| Metric          | Where             | Why                                |
|-----------------|-------------------|------------------------------------|
| SoC temperature | Sensors > thermal | Ensure < 80°C                      |
| RAM usage       | System > RAM      | Track if Immich is too hungry      |
| Disk space      | Disks > space     | HDD filling up                     |
| Docker CPU      | Containers        | Identify heavy services            |
| Network traffic | Network > eth0    | Unusual activity = potential issue |

## Data

**Netdata has state, and a fair amount of it.** Two bind mounts carry its registry
and its metrics database:

| Path | Content |
|---|---|
| `/mnt/data/services/netdata/lib` | Registry and the on-disk metrics database |
| `/mnt/data/services/netdata/cache` | Collector caches |

About **2 GB** together, and roughly half the nightly backup delta. Both are inside
the restic set like the rest of `/mnt/data`.

This page used to say the opposite — stateless, everything in RAM, lost on restart.
That described the state **before** ADR-019, which moved the database off the
container's writable layer precisely because history was being destroyed on every
recreation.

## Restore

Nothing service-specific: the two directories come back with a restic restore of
`/mnt/data/services`, and re-running the deploy role brings the container up.
Losing them costs the metric history, not the service — it starts collecting again
immediately either way.
