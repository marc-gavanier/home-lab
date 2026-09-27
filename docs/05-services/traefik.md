# Traefik

Reverse proxy: routes each subdomain to its container, terminates TLS with Let's Encrypt
certificates, redirects HTTP to HTTPS and applies the `vpn-only`, rate-limit and header
middlewares ([Network](../04-network/README.md#traefik)).

## At a glance

| Item                | Value |
|---------------------|-------|
| Dashboard           | `https://proxy.example.com` (VPN only) |
| Static config       | `ansible/roles/deploy/templates/traefik.yml.j2` (templated by Ansible) |
| Dynamic config      | `docker/configs/traefik/dynamic/middlewares.yml` |
| Routing             | Docker labels in `docker/compose.yaml` |
| Certificates        | `/mnt/data/services/traefik/acme/acme.json` (account key + every certificate), backed up by restic |
| Access log          | `/run/traefik/access.log`: raw, tmpfs, root-only, not backed up (ADR-034) |
| Access-log redaction | `docker/configs/traefik/redact-access-log.awk`, run by `traefik-log-redactor` (ADR-034) |

## Logs

Traefik's own log and the access log are in two containers:

```bash
ssh homelab "docker logs traefik --tail 20 2>&1"
ssh homelab "docker logs traefik-log-redactor --tail 20 2>&1"
```

- `traefik`: startup, ACME, routing.
- `traefik-log-redactor`: the access log, masked. Credential values in a query string show as
  `***`; the parameter name and the rest of the query are kept.

The unmasked line, for a live incident (RAM only, gone after a reboot or the daily rotation):

```bash
ssh homelab "sudo tail -20 /run/traefik/access.log"
```

## Troubleshooting

**Certificate problem.** Read the health message first: it reports `certs Nd/C`, the days left on
the nearest expiry over the number of certificates in `acme.json`, and names the failing one.

Then read why renewal fails. Most causes live outside `acme.json`: deleting the file fixes none of
them and re-orders every certificate through the same failing path.

```bash
ssh homelab "docker logs traefik 2>&1 | grep -i acme | tail -20"
```

- Cloudflare refuses the DNS challenge (an authentication or permission error from its API):
  rotate the token, see [`cf_dns_api_token`](../../knowledge/runbooks/rotate-a-secret.md#cf_dns_api_token).
- `acme.json` unreadable or not valid JSON: restore it (see [Restore](#restore)).
- Let's Encrypt rejects the account itself (`accountDoesNotExist`): only then delete the file.

**Last resort: delete `acme.json`.** Expect `Pi health` to go DOWN. It deletes the ACME account key
and triggers one ACME order per certificate at once:

```bash
ssh homelab "sudo rm -f /mnt/data/services/traefik/acme/acme.json && docker restart traefik"
```

The health check then reports, in order: `certificate expiry unreadable` (file holds no certificate
yet), then `N certificate(s) gone` until the count is back to its previous high.
`no certificate expiry is being watched` appears only if the file is still absent.

## Restore

Traefik is stateless except for `acme.json`. Restore it from restic with the rest of
`/mnt/data/services`. Letting Let's Encrypt reissue everything also works, but see the warning
above, and rate limits apply if it has to be repeated.
