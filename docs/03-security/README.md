# Security

## Philosophy

Defense in depth — each layer is secured independently. If one layer falls, the others hold.

## Security Layers

### 1. Network (perimeter)
- **ISP Router**: only ports 80, 443, and 51820/udp are open
- **UFW**: firewall on the Pi, deny by default, explicit whitelist. Note:
  Docker-published ports (53, 51413) insert their own iptables rules that
  bypass UFW's INPUT policy — so the *internet*-exposure boundary is enforced
  by the **ISP router's forward list** (80/443/51820), not by UFW. Published
  ports are only LAN-reachable because the router doesn't forward them.
- **WireGuard**: encrypted remote access, only way to reach services from outside the LAN
- **Traefik**: mandatory TLS, HTTP → HTTPS redirect
- **VPN-only by default**: the `vpn-only` middleware is applied globally on Traefik's HTTPS entrypoint. All services return `403 Forbidden` to internet traffic — only LAN, WireGuard, and Docker bridge networks pass through. Internet bots can't enumerate or exploit hosted services.

### 2. System (OS)
- **SSH**: key-only, password disabled, non-standard port
- **fail2ban**: three jails — `sshd`, plus **Nextcloud and Vaultwarden**
  (issue #35). SSH is not internet-reachable, so its jail guards the least
  exposed door; the two application jails cover the attacker the threat model
  actually expects — a compromised VPN client or LAN device, already inside the
  `vpn-only` gate. Two details make the difference between a jail that works and
  one that reports itself healthy while catching nothing: the filters are
  **custom** (the `bitwarden` filter shipped by fail2ban targets the official
  Bitwarden server and never matches Vaultwarden), and the ban action targets
  the **`DOCKER-USER`** chain — these services are reached through a
  Docker-published port, so their packets never traverse `INPUT`, where a
  default ban would be written, counted, and ignored. Docker's own ranges are in
  `ignoreip`: if `X-Forwarded-For` handling ever broke, the address in the
  application log would be Traefik's, and banning it would take the whole stack
  off the network.
- **unattended-upgrades**: automatic security updates (auto-install, no
  auto-reboot on the homelab; `needrestart` activates patched libraries
  reboot-free; kernel residue on a bounded manual cadence) — strategy in
  [ADR-013](../../knowledge/decisions/ADR-013-update-patching-strategy.md)
- **Non-root user**: no service runs as root
- **Audit**: lynis for periodic security audits; CIS Ubuntu 24.04 benchmark
  via `ansible/playbooks/cis-audit.yml` (read-only) — findings, remediation
  batches and assumed deviations in
  [knowledge/research/cis-audit-2026-07.md](../../knowledge/research/cis-audit-2026-07.md)

### 3. Containers (Docker)
- Official images only, pinned versions — Renovate-tracked, with
  `osvVulnerabilityAlerts` for off-schedule CVE PRs
- **`no-new-privileges`** on every container (one exception: Netdata, whose
  plugins are setuid-root binaries and need that elevation to read other
  processes' `/proc` for per-app charts — the flag blocks it outright) — blocks
  privilege escalation via setuid binaries after an app compromise
- **AppArmor on every container, netdata included.** Every other service runs
  under Docker's `docker-default` profile; netdata ran `unconfined` because
  `apps.plugin` reads the `/proc` of processes belonging to other profiles,
  which docker-default denies. It now runs under `homelab-netdata` — the same
  default profile plus a ptrace **read** grant, with attaching to processes
  still denied (ADR-018, issue #30). The profile is a file in the repo, shipped
  and loaded by the deploy role; if it is missing the container refuses to
  start, which is the loud failure rather than a silent fall back to
  unconfined.
- **Docker socket never mounted raw** — both Traefik and Netdata reach it only
  through a read-only `docker-socket-proxy` (CONTAINERS read-only, POST denied,
  on an internal-only network), so a container RCE can't pivot to host root via
  the socket. (Netdata uses it solely to resolve container names.)
- No `privileged` mode, and **`cap_drop: ALL` on every service**, each re-adding
  only what its image was *observed* to need (issue #24). Docker hands 14
  capabilities to every container by default; twelve of the twenty-one keep none.
  What the exercise showed is that the requirement is rarely guessable from the
  outside: Pi-hole needs `SETFCAP` because its image `setcap`s the FTL binary in
  order to run the resolver as non-root, wg-easy needs `NET_RAW` because
  `wg-quick` shells out to `iptables`, which opens a raw socket, and Uptime Kuma
  needs `NET_RAW` because the `ping` binary carries `cap_net_raw` as a file
  capability — without it the exec fails and every ping monitor reports
  "spawn EPERM" while the container stays healthy and its UI keeps answering.
  Each cap in `compose.yaml` carries a comment naming the behaviour that needs
  it. Netdata is the sharpest example of why this is measured rather than
  reasoned: its plugins are setuid root, so dropping `CHOWN` stops the agent
  from preparing its directories and it silently runs **as root** instead of
  uid 201, and dropping `DAC_OVERRIDE` kills its network-viewer and service
  discovery while all 279 chart contexts stay present. Rationale and the
  per-service findings: ADR-017; procedure for changing any container's
  configuration safely: `knowledge/runbooks/container-config-changes.md`.
- **`DAC_OVERRIDE` was the recurring exception**, and it said something worth
  knowing: several containers ran as root over data directories owned by the
  host user, so root was quietly relying on that capability to read and write
  them. Where only reads are involved the narrower `DAC_READ_SEARCH` is used
  instead (Traefik's config, Nextcloud's push service). Issue #28 took it from
  seven services to **four**, by two different means: owning the tree as root
  where the container is root throughout (Jellyfin, Navidrome), and **starting
  the container as the service uid** where the image would otherwise start as
  root and hand off — `user: "999:999"` on both databases and both redis caches,
  `user: "33:33"` on the Nextcloud cron companion. That second move is the
  general one: it removes the root phase rather than feeding it, so `CHOWN`,
  `SETUID`, `SETGID` and `FOWNER` go with it — five capabilities to zero, per
  service. SearXNG shed its when the defect behind it was fixed (issue #27).
- **The four that keep it are structural, not accidental**: pihole's root phase
  is where `setcap` runs on FTL; Nextcloud's apache must bind `:80` as root, and
  a non-root PID 1 has an empty permitted set, so `user:` would cost the port
  rather than the capability; transmission's s6 init *is* the root phase
  (`PUID`/`PGID` is that mechanism); netdata's setuid plugins write into
  `/run/netdata` inside the container, where no host ownership reaches. The
  price of the change is that those five services can no longer fix their own
  data directory's ownership, so the storage role owns it explicitly and the
  restore runbook says so.
- **Secrets injected as files, not environment variables** — the socket-proxy
  still allows `GET /containers/{id}/json`, whose response carries every
  container's `Env` array, so an env-injected password would be readable by a
  compromised Traefik or Netdata. DB and app passwords are mounted at
  `/run/secrets/` via each image's own convention (`*_FILE`, `FILE__*`), leaving
  only a path in `inspect` (ADR-016). This covers the Cloudflare DNS-01 token
  too — a `Zone:DNS:Edit` token being worth more than any DB password, since
  DNS control means issuing certificates. One value is still passed inline:
  wg-easy's `PASSWORD_HASH`, a bcrypt hash, unavoidable (v14 reads
  `process.env` with no file fallback)
- **Security headers + rate-limit on every HTTPS router** — HSTS, SAMEORIGIN,
  nosniff and a per-IP rate cap applied at the Traefik entrypoint
- Isolated Docker networks (`proxy` / `internal` / `socketproxy`); the DB tier
  lives on `internal` only — never proxied, never published
- No directly exposed service ports — everything routes through Traefik (vpn-only)
- **Read-only rootfs on 17 of the 21 services** (ADR-019, issue #32) — a
  compromised process cannot rewrite the code it runs, drop a binary, or persist
  anything outside the paths we declared. Every writable path is explicit: a
  sized `tmpfs` for state meant to be lost (PID files, sockets, caches,
  temporary files), a bind mount for state that is not. The requirement was
  **measured** with `docker diff` on the running containers — the real write set
  after weeks of production — not guessed from the images: seven services turned
  out to write nothing at all. Two rules earned the hard way: mount the *leaf*
  (`/run/mysqld`), never the parent, or the image's own runtime directories
  disappear and the server aborts; and Docker mounts `tmpfs` `noexec`, which
  breaks any init system that stages executables there.
- **The four exceptions all write into directories the image itself populates**,
  and each is stated in its own block: pihole (`setcap` on its own binary —
  read-only leaves the container *Up* with the resolver dead, the failure mode
  we most want to avoid), nextcloud (`redis-session.ini` among 21 shipped
  `.ini` files), socket-proxy (`haproxy.cfg` beside its template), transmission
  (starts read-only but silently stops honouring `PUID`/`PGID` and the `UMASK`
  that came from a CIS finding). The available workarounds — a `tmpfs` over a
  populated directory, or a host copy of image content — would each mask the
  next image update, trading a visible limit for an invisible one.

### 4. Application
- Strong passwords generated via Vaultwarden
- 2FA enabled on services that support it
- Secrets rendered by Ansible onto the LUKS volume (ADR-011), never in the repo:
  service passwords as individual files consumed as Docker secrets (ADR-016),
  the rest in `.env` (gitignored, symlinked off `/mnt/data/secrets/`)
- **Vaultwarden hardening**: signups off; the admin panel (`/admin`) stays
  **token-protected** — an argon2-hashed `ADMIN_TOKEN`, behind vpn-only, on a
  patched version (≥1.33.0, past CVE-2025-24364). Password hints off,
  server-side icon fetching off (SSRF/egress), Sends off. **Never** set
  `DISABLE_ADMIN_TOKEN` — it *bypasses* the token check (opens `/admin` without
  auth), the opposite of hardening. (Disabling the panel by default was
  evaluated and dropped: the empty-token mechanism doesn't cleanly disable it
  with a vault-rendered token, and token + vpn-only is a solid posture.)

### 5. Data
- Encrypted backups (Restic)
- Sensitive data encrypted at rest
- Periodic secret rotation

### 6. Physical
While the LUKS volume is unlocked, its key lives in RAM — the physical layer
defends that window. Every port of the Pi 4 is either dead, booby-trapped, or
covered by another layer:

| Access                  | Defense                                                            |
|-------------------------|--------------------------------------------------------------------|
| USB-A ×4, USB-C (OTG)   | Tamper response: any plug/unplug while armed → immediate poweroff  |
| UART (GPIO 8/10)        | Dead in firmware (`enable_uart=0`), serial console removed, getty masked |
| JTAG (GPIO)             | Off by default; enabling needs an SD edit + reboot, which wipes the key |
| I2C / SPI (GPIO)        | Off in firmware (unused)                                           |
| Wi-Fi / Bluetooth       | Off in firmware — not re-enablable at runtime, even by root        |
| HDMI ×2, AV jack, CSI/DSI | Output-only / dedicated buses, no input path to the OS           |
| Ethernet                | Not a console — plugging in = being on the LAN (layer 1's job)     |
| SD card slot            | Not coverable (pulling it kills the rootfs the response runs from); offline tampering handled by policy: **unexplained poweroff → reflash before unlocking** |
| Local login             | Account password locked — key-based SSH is the only authentication path |

Rationale: [ADR-008](../../knowledge/decisions/ADR-008-usb-tamper-poweroff.md)
(USB tamper response) and [ADR-009](../../knowledge/decisions/ADR-009-physical-attack-surface.md)
(firmware kills, password lock). Operations: [usb-tamper runbook](../../knowledge/runbooks/usb-tamper.md)
(arm/disarm — **disarm before touching any cable**), [boot & unlock runbook](../../knowledge/runbooks/boot-and-unlock.md)
(evil-maid policy), [SSH lockout recovery](../../knowledge/runbooks/ssh-lockout-recovery.md)
(no console fallback exists — this is the trade-off's escape hatch).

## Remote Kill Switch

An anti-theft / "panic" control to power the Pi off from anywhere — without
opening an inbound port. A root systemd service (`killswitch.service`)
**subscribes outbound** to a secret `ntfy.sh` topic and runs `systemctl poweroff`
when it receives a message whose body exactly matches a secret keyword.

- **Outbound only**: a long-lived `curl` stream — no listener, nothing for UFW to
  allow, no attack surface added.
- **Two secrets** (both vault-encrypted in `local.yml`, never in the repo):
  the **topic** (`killswitch_ntfy_topic`, high-entropy — it gatekeeps who can
  subscribe) and the **keyword** (`killswitch_keyword`, exact-match trigger).
- **Trigger**: `curl -d '<keyword>' https://ntfy.sh/<topic>`
- **Recovery is manual and physical** (no remote power-on): restore power, then
  unlock the encrypted data volume as on any boot.

Rationale and alternatives in [ADR-006](../../knowledge/decisions/ADR-006-remote-kill-switch.md);
trigger + recovery steps in [the kill-switch runbook](../../knowledge/runbooks/kill-switch.md).

## Hardening Checklist

To be completed during implementation — see Ansible `security` role.
