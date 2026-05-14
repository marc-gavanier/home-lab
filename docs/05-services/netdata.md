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

Netdata is stateless — no persistent data. All metrics are kept in RAM and lost on restart. This is by design (limited RAM on Pi 4).

## Restore

No restore needed. Restart the container and metrics start collecting again immediately.
