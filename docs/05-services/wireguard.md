# WireGuard (wg-easy)

VPN for secure remote access to the home lab.

## Access

- VPN port: 51820/UDP (exposed to internet)
- Admin UI: `https://vpn.example.com` from the LAN or over the VPN (Traefik, behind `vpn-only`), or `http://localhost:51821` through an SSH tunnel

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

### Two things every client config gets wrong on its own

Both were measured on the four live clients on 2026-09-13, and neither is a
misconfiguration — they are consequences of the defaults that nothing here had
written down.

**Reach this host by its tunnel address, not its LAN address.** wg-easy
masquerades every client behind its own bridge address before the packet reaches
the host's firewall, so a connection aimed at the LAN address arrives with a
source the SSH allow-list does not contain and is refused. The tunnel address
keeps the client's real source and is accepted. This is why `ssh` to the LAN
address works at home and fails over the VPN, and why `offsite` — reached by
`ProxyJump` through this host — fails with it.

**The endpoint name is resolved through the tunnel it is needed to build.**
Every client carries `AllowedIPs = 0.0.0.0/0` with Pi-hole as its DNS *and* an
`Endpoint` given as a name that only Pi-hole answers. While the tunnel is up
this is invisible. When it is down — the case where a client is being repaired —
the name has no resolver, and the same derivation is already written down for
the offsite host: *"a full-tunnel client could not look the name up."* Nobody had
applied it to the human clients. The configuration was read, not tested: there
is no out-of-band path to this host, so proving the failure would mean causing
it. Keep the current public IP noted somewhere off this network before you need
it.

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
> The stored value **cannot** be corrected in the UI and stay corrected. The
> deploy's `homelab-wg-easy-config.sh` asserts `allowedIps` on every client
> against the single `WG_ALLOWED_IPS` and rewrites any that differ, so a split
> set for these two peers would be put back to full tunnel by the next deploy.
> The repository has no per-client value today; a split tunnel for them would
> first need one. Until then, treat the deployed `wg0.conf` on each client as the
> source of truth for these two, not the UI, and never re-download their profile.

## Data

| Path                            | Content                                     |
|---------------------------------|---------------------------------------------|
| `/mnt/data/services/wireguard/` | `wg-easy.db` (server key, peers), `wg0.conf` |
| `/mnt/data/backups/wg-easy-v14/` | Pre-migration `wg0.json`, kept as a rollback |

## Backup

No new path: `/mnt/data/services` is already backed up wholesale by restic, and
that covers the table above.

`wg-easy.db` gets one extra step on top of that — a `backup_sqlite_dumps` entry
run from a resticprofile hook (ADR-031) — for the same reason as Vaultwarden,
Forgejo and the `*arr` trio. It is a live SQLite database in WAL mode, so a
restic snapshot of the file alone can capture a torn state: the committed
transactions sitting in the `-wal` beside it are not in the file restic copied.
Restoring the dump, not the raw file, is what § Restore below insists on.

What that does **not** cover is the way back in. The tunnel is the only route to
this Pi and to the offsite one, and `/etc/wireguard/wg0.conf` is a symlink onto
the encrypted volume — so reaching this backup at all presupposes an unlocked
volume, which presupposes the tunnel. The backstop for that circle is not here:
it is the offline recovery copy described in
[`luks-header-backup.md`](../../knowledge/runbooks/luks-header-backup.md).

## Restore

**Follow [`restore-from-backup.md` § Restore wg-easy (SQLite)](../../knowledge/runbooks/restore-from-backup.md#restore-wg-easy-sqlite).**
That is the procedure this repository maintains; this page deliberately does not
carry a second copy of it.

The reason the pointer is here rather than a short version: until 2026-09-13
this page carried its own, older recipe — `restic restore … --include
/mnt/data/services/wireguard` followed by `docker restart wg-easy`. It was wrong
in two ways that only matter on the day you use it. It restored the raw data
directory over a **running** container instead of the dump, and `restart` is not
`down`, so the heal timer's behaviour and the live writes underneath were both
ignored. The runbook restores `wg-easy.db` from the dump set, takes the service
`down` first, and warns against the pre-v15 `wg0.json` sitting next to it.

This is the one service where following the wrong page is not a service outage
but the loss of the way back in: the tunnel is the only route to this Pi and to
the offsite one, and `/etc/wireguard/wg0.conf` is a symlink onto the encrypted
volume, so it is also on the path to the unlock.

Clients will need to re-import their config if server keys change.
