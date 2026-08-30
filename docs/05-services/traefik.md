# Traefik

Reverse proxy with automatic TLS certificate management.

## Access

- Dashboard: `https://proxy.example.com` (VPN only)

## What It Does

- Routes incoming HTTPS traffic to the correct Docker container based on subdomain
- Automatically obtains and renews Let's Encrypt TLS certificates
- Redirects HTTP → HTTPS
- Applies security middlewares (headers, rate limiting, VPN-only access)

## Configuration

- Static config: `ansible/roles/deploy/templates/traefik.yml.j2` (templated by Ansible)
- Dynamic config: `docker/configs/traefik/dynamic/middlewares.yml`
- Routing: defined via Docker labels in `docker/compose.yaml`
- ACME storage: `/mnt/data/services/traefik/acme/acme.json`
- Access-log redaction: `docker/configs/traefik/redact-access-log.awk` (ADR-034)

## Data

| Path                               | Content                    |
|------------------------------------|----------------------------|
| `/mnt/data/services/traefik/acme/` | Let's Encrypt certificates |
| `/run/traefik/access.log`          | Raw access log — tmpfs, root-only, not backed up (ADR-034) |

## Troubleshooting

Check logs. **Traefik's own log and the access log are two different containers**
since ADR-034 — the access log is written to a tmpfs, masked, and shipped by
`traefik-log-redactor`, so `docker logs traefik` shows startup, ACME and routing
only:

```bash
ssh homelab "docker logs traefik --tail 20 2>&1"                 # Traefik itself
ssh homelab "docker logs traefik-log-redactor --tail 20 2>&1"    # access log, masked
```

Credential values in a query string read as `***`. That is the redaction, not a
truncation — the parameter name and the rest of the query survive. If you need
the unmasked line for a live incident, it is on the host, in RAM, root-only:

```bash
ssh homelab "sudo tail -20 /run/traefik/access.log"
```

It does not survive a reboot or the daily rotation, and that is deliberate.

**Before reaching for `acme.json`, read the health message.** Since #157 the health
script parses that file directly and reports `certs Nd/18` — the days left on the
nearest expiry. That names the failing certificate without destroying anything.

Deleting the file is a **last resort**, and it is no longer free:

```bash
ssh homelab "sudo rm -f /mnt/data/services/traefik/acme/acme.json && docker restart traefik"
```

It holds the ACME **account key** and all 18 certificates, not a cache. Removing it
triggers 18 simultaneous ACME orders and makes the health check push a problem
(`no certificate expiry is being watched`) until they are reissued, so expect
`Pi health` to go DOWN during the operation.

## Restore

Traefik is stateless except for `acme.json`, which is in the restic set with the
rest of `/mnt/data/services`. Restoring it is the fast path; letting Let's Encrypt
reissue all 18 certificates also works, but it is not free — see the warning above,
and note that rate limits apply to a set this size if it has to be repeated.
