# Security

Defense in depth: each layer is secured on its own, so if one falls the others
hold. This page lists the controls per layer and where each one is decided.

## Security Layers

### 1. Network (perimeter)

- **ISP router**: forwards only **51820/udp** (WireGuard) and **51413**
  (Transmission's peer port, open by design for seeding). 80/443 are **not**
  forwarded: Traefik serves the LAN and the VPN only.
- **UFW**: deny by default, explicit whitelist. Docker-published ports (53, 80,
  443, 51413, 51820/udp) bypass UFW's INPUT policy, so the internet boundary is
  the **router's forward list**, not UFW.
- **`ufw status` says nothing about container ports**: their packets are
  FORWARDed, where `DOCKER-USER` (1) and `DOCKER-FORWARD` (2) come before the
  `ufw-*-forward` chains (3+). Read exposure from the router and `DOCKER-USER`.
- **Port 53 is decided in `DOCKER-USER`.** It carries eight rules
  (`iptables -L DOCKER-USER -n -v`), a RETURN pair per allowed source and a DROP
  pair to close:

  ```
  RETURN  udp/tcp dpt:53  from 192.168.1.0/24      the LAN
  RETURN  udp/tcp dpt:53  from 10.8.0.0/24         the VPN
  RETURN  udp/tcp dpt:53  from 172.16.0.0/12       the container networks
  DROP    udp/tcp dpt:53  from 0.0.0.0/0           everything else
  ```

  If a client stops resolving, read `DOCKER-USER` first.
- **WireGuard**: the only way in from outside the LAN. A peer key *is* the
  perimeter: `vpn-only` trusts whoever holds one. Four peers, each a named
  device; two are infrastructure (the offsite Pi and the homelab's own host
  tunnel). Revocation:
  [wireguard-peer-revocation runbook](../../knowledge/runbooks/wireguard-peer-revocation.md).
- **Traefik**: mandatory TLS, HTTP → HTTPS redirect.
- **VPN-only by default**: the `vpn-only` middleware sits on Traefik's HTTPS
  entrypoint. Internet traffic gets `403 Forbidden`; only LAN, WireGuard and
  Docker bridge networks pass.

### 2. System (OS)

- **SSH**: key-only, password disabled, non-standard port.
- **SSH reachability**: two independent controls keep it off the internet. The
  router forwards no port to SSH, and the UFW rule is scoped to the LAN and the
  WireGuard subnet (`ssh_allowed_sources`, per host, because the two hosts sit
  on different LANs).
- **Over the VPN, SSH to the homelab's WireGuard address, not its LAN address.**
  wg-easy masquerades clients behind its bridge address, so a LAN-address
  connection arrives with a source the allow-list refuses (and allowing it would
  open sshd to every container on `proxy`). The tunnel address keeps the real
  `10.8.0.0/24` source because this Pi is a peer of its own wg-easy, so traffic
  arrives on `wg0`. The same applies to `offsite`, reached by `ProxyJump`
  through this host.
- **fail2ban**: jails `sshd`, Nextcloud and Vaultwarden (the latter two for a
  compromised VPN or LAN client already past `vpn-only`).
  - Filters are **custom**: fail2ban's `bitwarden` filter never matches
    Vaultwarden.
  - Bans go to **`DOCKER-USER`**: these services' packets never cross `INPUT`.
  - Docker ranges are in `ignoreip`, so a broken `X-Forwarded-For` cannot ban
    Traefik and take the stack offline.
  - A missing `logpath` stops fail2ban entirely (all jails, `sshd` included), so
    Ansible creates the log files.
  - A jail with a broken action or filter is skipped silently. The posture check
    compares jails in `jail.local` against jails loaded.
- **unattended-upgrades**: security updates auto-installed, no auto-reboot on
  the homelab; `needrestart` reloads patched libraries; kernel updates on a
  manual cadence. See
  [ADR-013](../../knowledge/decisions/ADR-013-update-patching-strategy.md).
- **Non-root where the image allows it**: 11 of 32 containers run as a service
  uid. The other 21 start as root; section 3 says why.
- **Audit**: lynis **on the homelab only** (installed where `lynis_scheduled`
  is set, purged elsewhere; its timer and monitor live in the observability
  role). CIS Ubuntu 24.04 via `ansible/playbooks/cis-audit.yml` (read-only);
  findings and accepted deviations in
  [knowledge/research/cis-audit-2026-07.md](../../knowledge/research/cis-audit-2026-07.md).

### 3. Containers (Docker)

- Official images, pinned versions, tracked by Renovate with
  `osvVulnerabilityAlerts` for off-schedule CVE PRs.
- **`no-new-privileges`** on every container except two, where the flag fails
  silently:
  - **Netdata**: setuid-root plugins read other processes' `/proc` (ADR-018).
  - **Collabora**: `coolforkit-caps` has file capabilities; with the flag the
    container stays `running` but no document opens (ADR-021).
- **AppArmor on every container.** All use `docker-default` except netdata,
  which runs under `homelab-netdata`: docker-default plus ptrace **read**,
  attach still denied (ADR-018). The deploy role ships and loads the profile; if
  it is missing the container refuses to start.
- **Docker socket never mounted raw.** Traefik, Netdata and Dozzle use a
  read-only `docker-socket-proxy` (CONTAINERS read-only, POST denied, internal
  network). Netdata uses it for container names, Dozzle for logs.
- **No `privileged`; `cap_drop: ALL` on every service**, each re-adding only
  what it was observed to need. Sixteen of 32 keep no capability. Needs are
  rarely guessable, for example:
  - Pi-hole: `SETFCAP` (its image `setcap`s FTL).
  - wg-easy: `NET_RAW` (`wg-quick` calls `iptables`).
  - Uptime Kuma: `NET_RAW` (`ping` has `cap_net_raw`; without it ping monitors
    fail with "spawn EPERM" while the container stays healthy).
  - Netdata: without `CHOWN` it silently runs as root instead of uid 201.

  Why each cap exists: `git log -S <CAP> -- docker/compose.yaml`. Rationale:
  ADR-017. Changing a container safely:
  `knowledge/runbooks/container-config-changes.md`.
- **`DAC_OVERRIDE`**: read-only needs use `DAC_READ_SEARCH` instead (Traefik's
  config, Nextcloud's push service). Two ways removed it elsewhere:
  - root-owned trees where the container is root throughout (Jellyfin,
    Navidrome);
  - starting as the service uid, `user: "999:999"`, on both databases and both
    redis caches. This drops `CHOWN`, `SETUID`, `SETGID`, `FOWNER` too.

  **Not `nextcloud-cron`**: with `user: "33:33"`, busybox `crond` cannot
  `setgroups()` and never runs `cron.php` while showing `Up`. It runs as uid 0
  with `SETUID`/`SETGID` on purpose (ADR-017).
- **Services that keep `DAC_OVERRIDE`**, all structural (the storage role owns
  their data directories, as the restore runbook says):
  - pihole: its root phase runs `setcap` on FTL;
  - Nextcloud: apache binds `:80` as root;
  - transmission: its s6 init is the root phase (`PUID`/`PGID`);
  - netdata: setuid plugins write to `/run/netdata` in the container;
  - Calibre-Web: same s6 init, but four longruns stay root, including the
    ingest service; the web app runs as uid 1000. `user:` fails; removing this
    needs an upstream change (ADR-025).
- **Radarr, Sonarr and Prowlarr also hold it** (eight in all), inherited from
  the same linuxserver s6 shape. Not narrowed yet: "unmeasured", not
  "structural" (ADR-036).
- **Secrets as files, not environment variables** (ADR-016). The socket-proxy
  allows `GET /containers/{id}/json`, which exposes every container's `Env`.
  Passwords, including the Cloudflare DNS-01 token, mount at `/run/secrets/`
  via each image's convention (`*_FILE`, `FILE__*`). No secret is passed
  inline. The wg-easy admin password is in
  `/mnt/data/secrets/wg-easy-setup.env` (`0600 root:root`), read by the host
  only, plaintext because v15 hashes it itself, and kept out of `homelab.env`,
  which feeds Compose interpolation for every service (ADR-020).
- **Security headers and rate limit** on every HTTPS router: HSTS, SAMEORIGIN,
  nosniff and a per-IP cap at the Traefik entrypoint.
- **Isolated networks**: `proxy`, `internal`, `socketproxy`. Databases live on
  `internal` only.
- **No web UI published directly**; all route through Traefik (vpn-only).
  Published ports: Traefik's 80/443, DNS, WireGuard, Transmission's peer port,
  and wg-easy's admin UI on host loopback only.
- **Read-only rootfs on 23 of 32 services** (ADR-019). Writable paths are
  explicit (sized `tmpfs` or bind mounts), plus an insurance `/tmp` because
  `docker diff` misses code paths never run. Two rules:
  - mount the *leaf* (`/run/mysqld`), never the parent, or the server aborts;
  - Docker mounts `tmpfs` `noexec`, which breaks init systems that stage
    executables there.
- **The nine writable ones** (reasons in ADR-019):

  | Service | Why not read-only |
  |---------|-------------------|
  | pihole | `setcap` on its own binary; read-only leaves it *Up* with the resolver dead |
  | nextcloud | writes `redis-session.ini` among 21 shipped `.ini` files |
  | socket-proxy | writes `haproxy.cfg` beside its template |
  | transmission | stops honouring `PUID`/`PGID` and the CIS `UMASK` |
  | Collabora | works read-only, but copies each document jail (759 MB) into `tmpfs`: 1.257 GiB RAM instead of 573 MiB (ADR-021) |
  | Calibre-Web | `docker diff` shows 1797 entries: it patches `/app` on every start |
  | Radarr, Sonarr, Prowlarr | never attempted, state "unknown" (ADR-036) |


### 4. Application

- Strong passwords generated in Vaultwarden.
- **2FA**:

  | Service     | State                                          |
  |-------------|------------------------------------------------|
  | Nextcloud   | TOTP + backup codes on the admin account       |
  | Vaultwarden | enabled                                        |
  | Uptime Kuma | enabled                                        |
  | Immich      | not available at v3.2.2                        |
  | Jellyfin    | no native second factor                        |

  Outside this stack: **Cloudflare** (DNS, so certificate issuance; the account
  that mints `Zone:DNS:Edit` tokens) and **GitHub** (this repository).
- Secrets rendered by Ansible onto the LUKS volume (ADR-011), never in the repo:
  service passwords as Docker secret files (ADR-016), the rest in `.env`
  (gitignored, symlinked off `/mnt/data/secrets/`).
- **Vaultwarden**: signups off; `/admin` protected by an argon2-hashed
  `ADMIN_TOKEN`, behind vpn-only, version ≥1.33.0 (past CVE-2025-24364).
  Password hints, server-side icon fetching and Sends off. **Never** set
  `DISABLE_ADMIN_TOKEN`: it opens `/admin` without auth.

### 5. Data

- Encrypted backups (Restic).
- Sensitive data encrypted at rest.
- Secret rotation: a deploy rotates only some secrets. Eleven need a written
  procedure, three of them (both restic passwords, the LUKS passphrase)
  destructive if changed in the vault alone:
  `knowledge/runbooks/rotate-a-secret.md`. The daily posture check asserts each
  database secret still opens its database.

### 6. Physical

While the LUKS volume is unlocked, its key is in RAM. Every Pi 4 port is dead,
booby-trapped, or covered by another layer:

| Access                    | Defense                                                                  |
|---------------------------|--------------------------------------------------------------------------|
| USB-A ×4, USB-C (OTG)     | Tamper response: any plug/unplug while armed → immediate poweroff        |
| UART (GPIO 8/10)          | Dead in firmware (`enable_uart=0`), serial console removed, getty masked |
| JTAG (GPIO)               | Off by default; enabling needs an SD edit + reboot, which wipes the key  |
| I2C / SPI (GPIO)          | Off in firmware (unused)                                                 |
| Wi-Fi / Bluetooth         | Off in firmware, not re-enablable at runtime, even by root               |
| HDMI ×2, AV jack, CSI/DSI | Output-only / dedicated buses, no input path to the OS                   |
| Ethernet                  | Not a console: plugging in = being on the LAN (layer 1's job)            |
| SD card slot              | Not coverable; policy: **unexplained poweroff → reflash before unlocking** |
| Local login               | Account password locked; key-based SSH is the only way in                |

Why: [ADR-008](../../knowledge/decisions/ADR-008-usb-tamper-poweroff.md),
[ADR-009](../../knowledge/decisions/ADR-009-physical-attack-surface.md).
Operations: [usb-tamper](../../knowledge/runbooks/usb-tamper.md) (**disarm
before touching any cable**), [boot & unlock](../../knowledge/runbooks/boot-and-unlock.md)
(evil-maid policy), [SSH lockout recovery](../../knowledge/runbooks/ssh-lockout-recovery.md)
(there is no console fallback).

## Offsite parity, and why a list of assertions is not a gate

The offsite runs the same `base` and `security` roles, so a control missing
there is a gap. The rule:

> An absent tool is honest; an installed tool that never runs is not.

So lynis is removed from the offsite rather than left unscheduled; the reasoning,
and how to reverse it, is in `homelab_control_timers` in `group_vars/all.yml`.

Two assertions close on each other:

| Assertion | Host | What it checks |
|-----------|------|----------------|
| `offsite-parity-register-covers-every-control-timer` | homelab | Every deployed `homelab-*.timer` is in the register, with its offsite counterpart or a written reason. Fails both ways: an unclassified timer, or a register entry with no timer |
| `offsite-carries-<unit>` | offsite | One per counterpart named in the register: its timer is armed |

A new control timer fails the first until someone classifies it. It only gates
controls that **are timers**.

## Remote Kill Switch

Powers the Pi off from anywhere without an inbound port. `killswitch.service`
(root) **subscribes outbound** to a secret `ntfy.sh` topic and runs
`systemctl poweroff` when a message body exactly matches a secret keyword.

- **Outbound only**: a long-lived `curl` stream, nothing for UFW to allow.
- **Two secrets**, vault-encrypted in `local.yml`: `killswitch_ntfy_topic`
  (high-entropy, gates who can subscribe) and `killswitch_keyword`
  (exact-match trigger).
- **Trigger**: `curl -d '<keyword>' https://ntfy.sh/<topic>`
- **Recovery is physical**: restore power, then unlock the data volume as on
  any boot.

Why: [ADR-006](../../knowledge/decisions/ADR-006-remote-kill-switch.md). Steps:
[kill-switch runbook](../../knowledge/runbooks/kill-switch.md).

## Hardening Checklist

To be completed during implementation — see Ansible `security` role.
