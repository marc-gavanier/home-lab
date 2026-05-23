# Transmission

Headless BitTorrent client.

## Access

- URL: `https://share.example.com`
- Login: `admin` / password set in `local.yml` (`transmission_password`)

## What It Does

- Seeds official ressources on a public IPv4
- Watch folder for auto-add: drop a `.torrent` in `/watch`, it's loaded automatically
- WebUI accessible over WireGuard VPN for management

## Client Setup

### Browser
Connect to `https://share.example.com` (VPN required).

### Native (optional, Linux)
```bash
sudo apt install transmission-remote-gtk
```
Configure to point at `share.example.com:443` (HTTPS) with the same admin credentials.

## First Steps

Transmission writes back to `settings.json` on shutdown, so **stop the daemon before editing**.

1. Stop the container:
   ```bash
   docker stop transmission
   ```

2. Edit `/mnt/data/services/transmission/config/settings.json`:
   ```json
   {
     "watch-dir": "/watch",
     "watch-dir-enabled": true,
     "speed-limit-up": <KB/s — see below>,
     "speed-limit-up-enabled": true
   }
   ```

   **Upload cap calculation** (target ~70% of real upstream). Example for a 700 Mbps fibre:
   `700 × 0.70 × 125 ≈ 61 250 KB/s` (1 Mbps = 125 KB/s).

3. Restart:
   ```bash
   docker start transmission
   ```

4. **Port forwarding (manual, one-time)**: on the SFR box admin, forward TCP+UDP 51413 → `192.168.1.100:51413`.

5. Add an Uptime Kuma monitor on `https://share.example.com` (60s interval, 3 retries).

## Data

| Path                                         | Content                                   |
|----------------------------------------------|-------------------------------------------|
| `/mnt/data/services/transmission/config/`    | `settings.json`, resume state, torrent DB |
| `/mnt/data/services/transmission/watch/`     | Drop zone for `.torrent` files (auto-add) |
| `/mnt/data/services/transmission/downloads/` | Actual data files being seeded            |

## Tracker Notes

- **Semi-private trackers**: consider disabling DHT/PEX/LSD per torrent to keep ratio counting honest. Set them off globally in `settings.json` only if you exclusively use private trackers.
- **Public trackers** and **WebTorrent**: keep DHT/PEX/LSD on for swarm discovery.

## Restore

```bash
docker stop transmission
restic restore latest --target / --include /mnt/data/services/transmission
docker start transmission
```

Resume state (`.resume` files in `config/`) is included — torrents restart seeding from where they stopped.