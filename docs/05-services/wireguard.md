# WireGuard (wg-easy)

The VPN, and the only way into the home lab from outside. Clients get an address in
`10.8.0.0/24`, use Pi-hole as DNS, and reach every `vpn-only` service.

## At a glance

| Item          | Value |
|---------------|-------|
| VPN port      | 51820/UDP, public |
| Admin UI      | `https://vpn.example.com` (LAN or VPN), or `http://localhost:51821` through an SSH tunnel |
| Login         | username `admin` (`WG_ADMIN_USERNAME`) + password |
| Settings      | SQLite, re-asserted by the deploy from `/mnt/data/secrets/wg-easy-setup.env` (ADR-020) |
| Data          | `/mnt/data/services/wireguard/`: `wg-easy.db` (server key, peers), `wg0.conf` |
| Backup        | restic (`/mnt/data/services`) + a SQLite dump of `wg-easy.db` (`backup_sqlite_dumps`, ADR-031) |

> Restart wg-easy only with someone able to reach the Pi physically: it is the only path to this Pi and to the offsite
> one, and `/etc/wireguard/wg0.conf` is a symlink onto the encrypted volume.

## Admin UI

Through an SSH tunnel:

```bash
ssh -L 51821:127.0.0.1:51821 homelab
```

Then open `http://localhost:51821`.

- The login asks for a username: `admin`. Typing the password alone, or letting a password manager
  fill an email, gives `invalid username or password`.
- Passwords are hashed with argon2, which does not truncate at 72 bytes. If a password longer than
  72 characters is rejected, enter its first 72 characters. The deploy never sets this password:
  change it in the UI, then put the same value in `wg_password`. Changing `wg_password` alone makes
  every later deploy fail on the login.

## Adding a client

Mobile (Android/iOS):

1. Install the [WireGuard app](https://www.wireguard.com/install/).
2. In the wg-easy UI, create a client.
3. Scan the QR code with the app.

Desktop (Linux):

1. `sudo apt install wireguard`
2. Create a client in the wg-easy UI and download the `.conf` file.
3. Import: `nmcli connection import type wireguard file client.conf`
4. Connect: `nmcli connection up client-name`

Removing a client: [wireguard-peer-revocation.md](../../knowledge/runbooks/wireguard-peer-revocation.md).

## How it works

**Configuration.**

- Settings live in SQLite, not in the environment. The deploy re-asserts them through the admin
  API on every run (`roles/deploy/tasks/wg_easy_config.yml`), comparing before writing.
- A change made in the UI is reverted by the next deploy. Edit the repository and deploy.
- `wg-easy-setup.env` (`0600 root:root`, encrypted volume) holds a plaintext admin password, which
  is why it is kept out of `homelab.env`.

**Clients.**

- Over the VPN, reach this host by its tunnel address, not its LAN address. wg-easy masquerades
  clients, so a connection to the LAN address arrives from a source the SSH allow-list refuses.
  This also breaks `offsite` (`ProxyJump` through this host).
- Clients use `AllowedIPs = 0.0.0.0/0`, Pi-hole as DNS, and `Endpoint = vpn.example.com`. If the
  tunnel is up but broken, the endpoint name cannot be resolved. Keep the current public IP noted
  somewhere off this network.

**Infrastructure peers: `offsite-backup` and `homelab-host`.**

> Never regenerate or re-download their profile from the UI. The UI stores a full tunnel, the
> hosts run a split one; a fresh profile removes the offsite recovery path, on a machine nobody
> can reach.

| Field                 | Stored in wg-easy | Deployed on both hosts |
|-----------------------|-------------------|------------------------|
| `AllowedIPs`          | `0.0.0.0/0`       | `10.8.0.0/24`          |
| `PersistentKeepalive` | `0`               | `25`                   |
| `Endpoint`            | empty             | set                    |

- The split lets the offsite host resolve names while the tunnel is down, which the re-resolve
  timer needs after a home IP change (ADR-029).
- Every client starts full-tunnel because `WG_ALLOWED_IPS=0.0.0.0/0` is the server default.
- The UI value cannot be fixed: `homelab-wg-easy-config.sh` rewrites every client's `allowedIps` to
  `WG_ALLOWED_IPS` on each deploy, and the repo has no per-client value. The deployed `wg0.conf`
  on each host is the source of truth for these two.

## Backup and restore

- `wg-easy.db` is written live by the container (rollback-journal mode), so a raw copy taken
  mid-write can be torn. Restore the **dump**, not the raw file.
- Restore procedure: [restore-from-backup.md § Restore wg-easy (SQLite)](../../knowledge/runbooks/restore-from-backup.md#restore-wg-easy-sqlite).
  It takes the service `down` first and warns against the old `wg0.json`. Do not restore the raw
  directory over a running container.
- Reaching the backup needs the unlocked volume, which needs the tunnel. The way out of that
  circle is the offline recovery copy: [luks-header-backup.md](../../knowledge/runbooks/luks-header-backup.md).
- If the server keys change, every client must re-import its config.
