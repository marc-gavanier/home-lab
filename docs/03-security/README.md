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

## Hardening Checklist

To be completed during implementation — see Ansible `security` role.
