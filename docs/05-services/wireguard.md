# WireGuard (wg-easy)

VPN for secure remote access to the home lab.

## Access

- VPN port: 51820/UDP (exposed to internet)
- Admin UI: `http://localhost:51821` via SSH tunnel only

```bash
ssh -L 51821:127.0.0.1:51821 homelab
# Then open http://localhost:51821
```

## What It Does

- Provides encrypted tunnel to the home network from anywhere
- VPN clients get an IP in 10.8.0.0/24 and use Pi-hole as DNS
- Required to access VPN-only services (Pi-hole admin, Netdata, Uptime Kuma)

## Client Setup

### Mobile (Android/iOS)
1. Install [WireGuard app](https://www.wireguard.com/install/)
2. Open wg-easy UI, create a new client
3. Scan QR code with the app

### Desktop (Linux)
1. Install: `sudo apt install wireguard`
2. Create a client in wg-easy UI, download the `.conf` file
3. Import: `nmcli connection import type wireguard file client.conf`
4. Connect: `nmcli connection up client-name`

The VPN appears as a regular network connection in system settings.

## Data

| Path                            | Content                          |
|---------------------------------|----------------------------------|
| `/mnt/data/services/wireguard/` | Server keys, peer configurations |

## Restore

From Restic backup:
```bash
restic restore latest --target / --include /mnt/data/services/wireguard
docker restart wg-easy
```

Clients will need to re-import their config if server keys change.
