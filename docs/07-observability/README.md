# Observability

## Philosophy

Lightweight and actionable monitoring. We watch what requires human intervention, nothing more.

## Stack

| Tool            | Role                                                            |
|-----------------|-----------------------------------------------------------------|
| **Netdata**     | Real-time system metrics (CPU, RAM, disk, temperature, network) |
| **Uptime Kuma** | Service availability monitoring + alerting                      |

## Monitored Metrics

### Infrastructure (Netdata)
- CPU: per-core utilization, load average
- RAM: used, cached, swap
- Disk: free space on SD + HDD, IOPS, throughput
- SoC temperature (alert if > 75°C, throttling at 80°C)
- Network: bandwidth, errors, connections

### Services (Uptime Kuma)
- HTTP check on each subdomain (2xx = OK)
- Response time
- TLS certificates (alert 14 days before expiration)
- Docker health (container healthchecks)

### Security
- fail2ban: banned IPs
- Pi-hole: % of blocked queries
- WireGuard: connected peers

### Backups
- Last backup success/failure
- Restic repository size

## Alerting

Notification channel to be defined:
- Email (via external SMTP)
- Telegram bot
- Custom webhook

Rule: one alert = one action needed. No noise.
