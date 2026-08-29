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

> **Do not regenerate the `offsite-backup` or `homelab-host` clients from the
> UI.** Both are infrastructure peers, and for both, what wg-easy has stored is a
> **full tunnel** while what is deployed is **split**. Measured 2026-08-29:
>
> ```
> stored in wg-easy      allowed_ips ["0.0.0.0/0"], keepalive 0, endpoint empty
> deployed (both hosts)  AllowedIPs = 10.8.0.0/24, PersistentKeepalive = 25,
>                        Endpoint set
> ```
>
> Three fields diverge, not one, and they diverge **identically for both peers**.
> Earlier revisions of this box named only `offsite-backup` and quoted the stored
> value as `["0.0.0.0/0","::/0"]`; the IPv6 half is no longer there.
>
> The split is what makes the offsite host able to resolve names while the tunnel
> is down — its resolver is its own LAN router over `eth0` — and that is the
> precondition for the re-resolve timer that recovers the tunnel after a home IP
> change (ADR-029, #180). Downloading a fresh profile would hand back the full
> tunnel and remove the recovery path, on the machine nobody can reach to fix it.
>
> It is not a mistake anyone made, which is why it will happen again:
> `WG_ALLOWED_IPS=0.0.0.0/0` in `wg-easy-setup.env` is the server-side default,
> so **every client is born full-tunnel** and both infrastructure peers simply
> kept it. That is the right default for a phone and the wrong one for these two.
>
> The stored value **could** now be corrected — #138 closed on 2026-08-26
> (`ca6d72e`) and wg-easy writes its database again. It has deliberately not
> been: correcting it means a write that regenerates `wg0.conf` and runs
> `wg syncconf` on the only interface that reaches either host, which is work to
> schedule with a rollback armed, not a tidy-up. Until then, treat the deployed
> `wg0.conf` as the source of truth for these two clients, not the UI — and note
> that this is now a deliberate deferral rather than a blocked one.

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
