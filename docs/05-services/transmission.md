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

1. Remove the container — `compose down`, never `docker stop`: the heal timer
   brings a stopped container back within 2 min, and Transmission would then
   rewrite `settings.json` from memory, over the edit being made (ADR-007).
   ```bash
   cd /opt/homelab && docker compose down transmission
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

3. Bring it back:
   ```bash
   docker compose up -d transmission
   ```

4. **Port forwarding (manual, one-time)**: on the SFR box admin, forward TCP+UDP 51413 → `192.168.1.100:51413`.

5. Add the Uptime Kuma monitor — **not** a plain HTTP check on the root. The
   specification is in [uptime-kuma.md](uptime-kuma.md#monitors-configured):
   type **Keyword**, URL `https://share.example.com/transmission/web/`, keyword
   `Transmission Web Interface`, with HTTP Basic auth.

   Unauthenticated, this service answers 401 to every path, so a path that does
   not exist is indistinguishable from a working interface — which is how `401`
   ended up in the accepted status codes in the first place (#191). Recreating
   the bare monitor recreates that pressure.

## Data

| Path                                         | Content                                   |
|----------------------------------------------|-------------------------------------------|
| `/mnt/data/services/transmission/config/`    | `settings.json`, resume state, torrent DB |
| `/mnt/data/services/transmission/watch/`     | Drop zone for `.torrent` files (auto-add) |
| `/mnt/data/library/downloads/`               | Actual data files being seeded (ADR-035)  |

## Tracker Notes

- **Semi-private trackers**: consider disabling DHT/PEX/LSD per torrent to keep ratio counting honest. Set them off globally in `settings.json` only if you exclusively use private trackers.
- **Public trackers** and **WebTorrent**: keep DHT/PEX/LSD on for swarm discovery.

## Known exposure: the image's own stop hook puts the RPC password in an argv

Found by the audit of 2026-09-13, **accepted rather than fixed**, and written
down here so nobody rediscovers it as if it were new.

The image ships its own s6 stop hook, which runs on **every container stop** —
so on every deploy, every crash-heal restart, every `compose down`:

```
/etc/s6-overlay/s6-rc.d/svc-transmission/finish
    /usr/bin/transmission-remote 127.0.0.1:${PORT:-9091} -n "$USER":"$PASS" --exit
```

`$PASS` is the live RPC password. `/proc` carries no `hidepid`, so any local
account can read that command line for the duration of the call. The same form
sits in `/app/blocklist-update.sh`, inert only because `blocklist-enabled` is
false — one checkbox away, and its window is seconds rather than milliseconds.

**Why it is not fixed.** Both files are inside the image. This repository
already removed the `-n` form from everything it controls: the healthcheck in
`compose.yaml` and the Ansible task both use `TR_AUTH`, which puts the value in
the process's environment where `/proc/<pid>/environ` is 0400 owner-only (#198).
What remains is upstream's, and editing a file inside an image is undone by the
next pull.

**Why there is no assertion for it either**, which is the less obvious half.
A check that pins the contents of an upstream script fires on any benign
refactor and tells you nothing about the property you care about — that is audit
class C86, *a configuration value written to restate an upstream default in
order to freeze it*, and this repository has already paid for it three times. A
permanently-red monitor or a tripwire on someone else's code is worse than a
written-down acceptance.

**What would change the decision.** Mounting `/proc` with `hidepid` would close
it, and was rejected on cost: netdata reads `/proc` for every container's
metrics and would need the exemption, which is a larger change than the exposure
warrants on a LAN-only host reached through a VPN. If Transmission is ever
exposed beyond the tunnel, or if an untrusted local account is ever created on
this host, re-open this.

## Restore

```bash
cd /opt/homelab   # `compose down`, never `docker stop`: a stopped container
                  # is resurrected by the heal timer within 2 min (ADR-007)
docker compose down transmission
restic restore latest --target / --include /mnt/data/services/transmission
docker compose up -d transmission
```

Resume state (`.resume` files in `config/`) is included — torrents restart seeding from where they stopped.
