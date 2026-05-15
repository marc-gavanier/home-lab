# Pi-hole

DNS server with ad/tracker blocking and split DNS for the home lab.

## Access

- Admin panel: `https://dns.example.com/admin`
- Accessible from LAN (via split DNS) and VPN
- Password: set by Ansible via `pihole setpassword` (from `local.yml`)

## What It Does

- Blocks ads and trackers at the DNS level for all devices using it as DNS
- Split DNS: resolves homelab subdomains to LAN IP so traffic stays local
- Custom dnsmasq config: `docker/configs/pihole/05-homelab.conf`

## Network-wide Setup

### ISP Router Configuration

Set Pi-hole as the DNS server distributed by DHCP:

1. Router admin (192.168.1.1) > LAN > Characteristics
2. DNS primaire: `192.168.1.100`
3. DNS secondaire: leave empty (prevents devices from bypassing Pi-hole)

### TV Decoder Bypass

The SFR TV decoder breaks when filtered by Pi-hole. Exclude it:

1. Pi-hole admin > **Groups** > create group `bypass` (description: "Unfiltered devices — e.g. TV decoder")
2. Pi-hole admin > **Clients** > add decoder IP (`192.168.1.46`, MAC `B4:E2:65:E3:BF:DF`)
3. Assign the decoder to group **bypass** only (remove from **Default**)
4. Ensure adlists are NOT assigned to the bypass group

## Pi-hole v6 Gotchas

- **Environment variables**: `WEBPASSWORD` and `DNSMASQ_LISTENING` no longer work. Use `FTLCONF_webserver_api_password` and `FTLCONF_dns_listeningMode` instead.
- **Config persistence**: env vars are only read on first start. Once `pihole.toml` exists in the volume, env vars are ignored. Delete `pihole.toml` to force re-read.
- **Listening mode**: must be set to `all` (not `LOCAL`) for Pi-hole to accept DNS queries from the LAN through Docker's NAT.
- **Password**: set via `pihole setpassword` command (Ansible handles this automatically).
- **Custom dnsmasq**: requires `FTLCONF_misc_etc_dnsmasq_d: "true"` to read files in `/etc/dnsmasq.d/`.

## Data

| Path | Content |
|------|---------|
| `/mnt/data/services/pihole/etc/` | Pi-hole configuration (`pihole.toml`) |
| `/mnt/data/services/pihole/dnsmasq/` | Custom dnsmasq configs |

## Restore

From Restic backup:
```bash
restic restore latest --target / --include /mnt/data/services/pihole
docker restart pihole
# Then re-run Ansible deploy to set the password
```