# WireGuard (wg-easy)

VPN for secure remote access to the home lab.

## Access

- VPN port: 51820/UDP (exposed to internet)
- Admin UI: `http://localhost:51821` via SSH tunnel only

```bash
ssh -L 51821:127.0.0.1:51821 homelab
# Then open http://localhost:51821
```

**Logging in takes a username since v15: `admin`.** v14 had a password field and
nothing else, so the reflex is to type the password alone — which returns
`invalid username or password` and looks like a wrong password. The username is
`WG_ADMIN_USERNAME` in `/mnt/data/secrets/wg-easy-setup.env`, and a password
manager autofilling an email address into that field produces the same error.

The password itself did not change across the migration — same vault variable,
argon2 instead of bcrypt. One consequence of that swap: **bcrypt silently
truncated at 72 bytes and argon2 does not**, so a stored password longer than 72
characters used to work in v14 and will now be rejected. If that is the case,
enter its first 72 characters, or set a shorter `wg_password` and redeploy.

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

## Configuration — where it lives, and why it is not in `.env`

Since v15 (ADR-020) wg-easy keeps its settings in **SQLite**, not in the
environment: `WG_HOST`, `PASSWORD_HASH`, `WG_DEFAULT_DNS` and `WG_ALLOWED_IPS`
no longer exist. To keep this repository the source of truth rather than the web
UI, the deploy re-asserts them through the admin API on every run
(`roles/deploy/tasks/wg_easy_config.yml`), comparing before writing.

The values come from `/mnt/data/secrets/wg-easy-setup.env` (`0600 root:root`,
encrypted volume). It carries a **plaintext** admin password: v15 hashes with
argon2 itself and takes no precomputed hash. That is why it is not in
`homelab.env`, which is group-readable by docker and mounted into containers.

Changing a setting means editing the repository and deploying — a change made in
the web UI is reverted on the next deploy, on purpose.

> **Do not regenerate the `offsite-backup` client from the UI.** What wg-easy has
> stored for it is a **full tunnel** (`0.0.0.0/0`, `::/0`), while what is deployed
> on the offsite host is **split**:
>
> ```
> stored in wg-easy      ["0.0.0.0/0","::/0"]
> deployed on offsite    AllowedIPs = 10.8.0.0/24
> ```
>
> The split is what makes that host able to resolve names while the tunnel is
> down — its resolver is its own LAN router over `eth0` — and that is the
> precondition for the re-resolve timer that recovers the tunnel after a home IP
> change (ADR-029, #180). Downloading a fresh profile would hand back the full
> tunnel and remove the recovery path, on the machine nobody can reach to fix it.
>
> It is not a mistake anyone made, which is why it will happen again:
> `WG_ALLOWED_IPS=0.0.0.0/0` in `wg-easy-setup.env` is the server-side default,
> so **every client is born full-tunnel** and the offsite one simply kept it.
> That is the right default for a phone and the wrong one for this host.
>
> The stored value cannot simply be corrected: writing to wg-easy's database is
> what #138 is about. Until that is fixed, treat the deployed `wg0.conf` as the
> source of truth for this one client, not the UI.

## Data

| Path                            | Content                                     |
|---------------------------------|---------------------------------------------|
| `/mnt/data/services/wireguard/` | `wg-easy.db` (server key, peers), `wg0.conf` |
| `/mnt/data/backups/wg-easy-v14/` | Pre-migration `wg0.json`, kept as a rollback |

## Restore

From Restic backup:
```bash
restic restore latest --target / --include /mnt/data/services/wireguard
docker restart wg-easy
```

Clients will need to re-import their config if server keys change.
