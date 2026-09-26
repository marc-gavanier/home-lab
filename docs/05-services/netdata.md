# Netdata

Real-time system monitoring dashboard.

## Access

- URL: `https://system.example.com` (VPN only)

## What It Does

- Real-time metrics: CPU, RAM, disk, network, temperature
- Docker container monitoring
- Per-process resource usage
- Automatic anomaly detection
- Collects out of the box; what this lab adds — `netdata.conf` (retention tiers), the `go.d` Docker collector and six curated `health.d` alarms — is rendered from the repository by Ansible

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

**Netdata has state, and a fair amount of it.** Two bind mounts carry it:

| Path                               | Content                                                                    | In the backup |
|------------------------------------|----------------------------------------------------------------------------|---------------|
| `/mnt/data/services/netdata/lib`   | Registry and agent identity — a few tens of KB                             | yes           |
| `/mnt/data/services/netdata/cache` | The metrics database (`dbengine` tiers 0-2), ML models, context metadata   | **no**        |

`cache/` is about **1.8 GB** and is excluded from restic on purpose: it churned
roughly 400 MiB a night — half the nightly delta — for data that regenerates
itself (commit 78372e1, 2026-08-31).

This page used to say the opposite — stateless, everything in RAM, lost on restart.
That described the state **before** ADR-019, which moved the database off the
container's writable layer precisely because history was being destroyed on every
recreation.

## Restore

**A restore does NOT bring back the metric history.** The metrics database lives
in `cache/`, which no snapshot contains. A restic restore of `/mnt/data/services`
returns `lib/` only — the registry — and re-running the deploy role brings the
container up with an empty history. That costs the graphs, not the service: it
starts collecting again immediately.
