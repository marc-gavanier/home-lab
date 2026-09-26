# Netdata

Real-time metrics dashboard for the Pi and its containers. Use it to investigate after Kuma has
flagged something; its alarms reach Kuma only through the adapter (see
[observability](../07-observability/README.md)).

## At a glance

| Item       | Value                                                                                                   |
|------------|---------------------------------------------------------------------------------------------------------|
| URL        | `https://system.example.com` (VPN only)                                                                 |
| Config     | `netdata.conf` (retention tiers), the `go.d` Docker collector, six curated `health.d` alarms — all rendered by Ansible |
| Data       | `/mnt/data/services/netdata/lib` and `/mnt/data/services/netdata/cache` (ADR-019)                        |
| Supervision | Kuma HTTP monitor `Netdata` on `/api/v1/info`                                                          |

## Where to look

| Metric          | Where             | Why                                |
|-----------------|-------------------|------------------------------------|
| SoC temperature | Sensors > thermal | Keep < 80°C (throttling starts)    |
| RAM usage       | System > RAM      | Track if Immich is too hungry      |
| Disk space      | Disks > space     | HDD filling up                     |
| Docker CPU      | Containers        | Identify heavy services            |
| Network traffic | Network > eth0    | Unusual activity = potential issue |

## Data and backup

| Path                               | Content                                                                  | In the backup |
|------------------------------------|--------------------------------------------------------------------------|---------------|
| `/mnt/data/services/netdata/lib`   | Registry and agent identity — a few tens of KB                           | yes           |
| `/mnt/data/services/netdata/cache` | The metrics database (`dbengine` tiers 0-2), ML models, context metadata | **no**        |

`cache/` (about 1.8 GB) is excluded from restic because it churns heavily and regenerates itself.

## Restore

A restore does not bring back metric history. Restoring `/mnt/data/services` returns `lib/` only;
re-running the deploy role starts the container with an empty history, and it collects again
immediately.
