# Transmission

Headless BitTorrent client seeding official resources on a public IPv4. Web UI over
the VPN.

## At a glance

| Item    | Value                                                                        |
|---------|------------------------------------------------------------------------------|
| URL     | `https://share.example.com`, user `admin`, password `transmission_password` (`local.yml`) |
| Port    | 51413 TCP+UDP, forwarded by hand on the SFR box to `<pi-lan-ip>:51413`       |
| Config  | `/mnt/data/services/transmission/config/` (`settings.json`, resume state)    |
| Watch   | `/mnt/data/services/transmission/watch/`: a dropped `.torrent` is added      |
| Data    | `/mnt/data/library/downloads/` (ADR-035)                                     |
| Monitor | Kuma keyword monitor, [uptime-kuma.md](uptime-kuma.md#monitors-configured)   |

## How it works

- Transmission rewrites `settings.json` on shutdown: stop it before editing.
- DHT/PEX/LSD: on for public trackers and WebTorrent; off per torrent on
  semi-private ones; off globally only for private-only use.

### Accepted exposure: RPC password in argv

The image's stop hook, run on every stop, puts the password on a command line
that any local account can read (`/proc` has no `hidepid`):

```
/etc/s6-overlay/s6-rc.d/svc-transmission/finish
    /usr/bin/transmission-remote 127.0.0.1:${PORT:-9091} -n "$USER":"$PASS" --exit
```

`/app/blocklist-update.sh` does the same if `blocklist-enabled` is turned on. Not
fixed: the files are upstream's, and this repo's own calls use `TR_AUTH`. No
assertion: it would pin upstream code (audit class C86). `hidepid` would break
netdata. Re-open if Transmission leaves the VPN or an untrusted local account appears.

## Common tasks

Use `compose down`, never `docker stop`: the heal timer restarts a container that
exited non-zero, and Transmission would overwrite your edit (ADR-007).

Edit settings:

1. Stop it:
   ```bash
   cd /opt/homelab && docker compose down transmission
   ```
2. Edit `/mnt/data/services/transmission/config/settings.json`. Upload cap: ~70 %
   of upstream, 1 Mbps = 125 KB/s (700 Mbps: `700 × 0.70 × 125 ≈ 61 250 KB/s`).
   ```json
   {
     "watch-dir": "/watch",
     "watch-dir-enabled": true,
     "speed-limit-up": <KB/s — see below>,
     "speed-limit-up-enabled": true
   }
   ```
3. Start it:
   ```bash
   docker compose up -d transmission
   ```

Kuma monitor: type **Keyword**, URL `https://share.example.com/transmission/web/`,
keyword `Transmission Web Interface`, HTTP Basic auth. A plain HTTP check proves
nothing: without auth every path answers 401.

Native client: point it at `share.example.com:443` with the admin credentials.

```bash
sudo apt install transmission-remote-gtk
```

Restore (resume state included, torrents resume seeding):

```bash
cd /opt/homelab
docker compose down transmission
restic restore latest --target / --include /mnt/data/services/transmission
docker compose up -d transmission
```
