# Traefik

Reverse proxy with automatic TLS certificate management.

## Access

- Dashboard: `https://traefik.example.com` (VPN only, not currently exposed)

## What It Does

- Routes incoming HTTPS traffic to the correct Docker container based on subdomain
- Automatically obtains and renews Let's Encrypt TLS certificates
- Redirects HTTP → HTTPS
- Applies security middlewares (headers, rate limiting, VPN-only access)

## Configuration

- Static config: `docker/configs/traefik/traefik.yml` (templated by Ansible)
- Dynamic config: `docker/configs/traefik/dynamic/middlewares.yml`
- Routing: defined via Docker labels in `docker/compose.yaml`
- ACME storage: `/mnt/data/services/traefik/acme/acme.json`

## Data

| Path                               | Content                    |
|------------------------------------|----------------------------|
| `/mnt/data/services/traefik/acme/` | Let's Encrypt certificates |

## Troubleshooting

Check logs:
```bash
ssh homelab "docker logs traefik --tail 20 2>&1"
```

If certificates fail, clear the ACME cache and restart:
```bash
ssh homelab "sudo rm -f /mnt/data/services/traefik/acme/acme.json && docker restart traefik"
```

## Restore

Traefik is stateless except for ACME certificates. They are re-generated automatically if lost. No restore needed.