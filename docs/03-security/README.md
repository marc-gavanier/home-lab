# Security

## Philosophy

Defense in depth — each layer is secured independently. If one layer falls, the others hold.

## Security Layers

### 1. Network (perimeter)
- **ISP Router**: only ports 80, 443, and 51820/udp are open
- **UFW**: firewall on the Pi, deny by default, explicit whitelist
- **WireGuard**: encrypted remote access, only way to reach services from outside the LAN
- **Traefik**: mandatory TLS, HTTP → HTTPS redirect
- **VPN-only by default**: the `vpn-only` middleware is applied globally on Traefik's HTTPS entrypoint. All services return `403 Forbidden` to internet traffic — only LAN, WireGuard, and Docker bridge networks pass through. Internet bots can't enumerate or exploit hosted services.

### 2. System (OS)
- **SSH**: key-only, password disabled, non-standard port
- **fail2ban**: automatic banning after failed attempts
- **unattended-upgrades**: automatic security updates
- **Non-root user**: no service runs as root
- **Audit**: lynis for periodic security audits

### 3. Containers (Docker)
- Official images only, pinned versions
- No `privileged` mode
- Minimal capabilities
- Isolated Docker networks
- Read-only filesystems when possible
- No directly exposed ports (everything goes through Traefik)

### 4. Application
- Strong passwords generated via Vaultwarden
- 2FA enabled on services that support it
- Secrets in `.env` (gitignored), never in config files

### 5. Data
- Encrypted backups (Restic)
- Sensitive data encrypted at rest
- Periodic secret rotation

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
