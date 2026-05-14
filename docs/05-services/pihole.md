# Pi-hole

DNS server with ad/tracker blocking and split DNS for the home lab.

## Access

- Admin panel: `https://dns.example.com/admin` (VPN only)
- Password: set in `local.yml` (`pihole_password`)

## What It Does

- Blocks ads and trackers at the DNS level for all devices using it as DNS
- Split DNS: resolves homelab subdomains to LAN IP (192.168.1.100) so VPN clients reach services directly
- Custom dnsmasq config: `docker/configs/pihole/05-homelab.conf`

## Setup — Network-wide DNS

To use Pi-hole for all devices on the network:

1. Set Pi-hole as DNS in the box DHCP settings (LAN > DNS primaire: 192.168.1.100)
2. Exclude the TV decoder from Pi-hole filtering (Pi-hole admin > Groups > create "bypass" group > assign decoder)

Note: VPN clients already use Pi-hole as DNS automatically (configured via `WG_DEFAULT_DNS`).

## Data

| Path                                 | Content                |
|--------------------------------------|------------------------|
| `/mnt/data/services/pihole/etc/`     | Pi-hole configuration  |
| `/mnt/data/services/pihole/dnsmasq/` | Custom dnsmasq configs |

## Restore

From Restic backup:
```bash
restic restore latest --target / --include /mnt/data/services/pihole
docker restart pihole
```