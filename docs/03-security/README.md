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
- **fail2ban**: automatic banning after failed attempts
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
  `apps.plugin` must gain `cap_sys_ptrace`/`cap_dac_read_search` via file
  capabilities for per-app charts — the flag would block that) — blocks
  privilege escalation via setuid binaries after an app compromise
- **Docker socket never mounted raw** — both Traefik and Netdata reach it only
  through a read-only `docker-socket-proxy` (CONTAINERS read-only, POST denied,
  on an internal-only network), so a container RCE can't pivot to host root via
  the socket. (Netdata uses it solely to resolve container names.)
- No `privileged` mode; explicit capabilities only where required (wg-easy:
  NET_ADMIN/SYS_MODULE; netdata: SYS_PTRACE only — SYS_ADMIN dropped, it only
  powered eBPF charts)
- **Security headers + rate-limit on every HTTPS router** — HSTS, SAMEORIGIN,
  nosniff and a per-IP rate cap applied at the Traefik entrypoint
- Isolated Docker networks (`proxy` / `internal` / `socketproxy`); the DB tier
  lives on `internal` only — never proxied, never published
- No directly exposed service ports — everything routes through Traefik (vpn-only)
- Per-service `cap_drop` / read-only rootfs: incremental defense-in-depth,
  tracked as a follow-up (needs per-image testing)

### 4. Application
- Strong passwords generated via Vaultwarden
- 2FA enabled on services that support it
- Secrets in `.env` (gitignored), never in config files
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
