# Runbook: notify_push self-test fails

`occ notify_push:setup https://drive.example.com/push` runs a 6-step self-test.
Each failure points at a specific misconfiguration. This runbook lists the ones
hit on this homelab and their fixes. All fixes live in `docker/compose.yaml` and
`ansible/roles/deploy/tasks/main.yml` — re-deploy with `--tags deploy`.

## Quick diagnosis

```bash
docker exec -u www-data nextcloud php occ notify_push:setup https://drive.example.com/push
```

The test stops at the first failing step. Map the message to a cause below.

## Symptom → cause → fix

### "can't connect to push server: 403 Forbidden"
**Cause:** DNS hairpin. From inside the `nextcloud` container, `drive.example.com`
resolves to the **public IP**, so the self-test leaves the LAN, comes back through
NAT with a public source IP, and notify_push's `/test/*` endpoints reject it.

Check:
```bash
docker exec nextcloud getent hosts drive.example.com   # shows the PUBLIC ip = bug
```
**Fix:** pin the name to the Pi over the LAN in `compose.yaml` (nextcloud service):
```yaml
extra_hosts:
  - "drive.${DOMAIN}:${PI_LAN_IP}"
```
> Note: `dns: ${PI_LAN_IP}` (Pi-hole) does **not** work — UDP/53 hairpin to the
> host's published port fails from the container, while TCP/443 to the LAN IP works.

### "can't connect to push server: Could not resolve host"
**Cause:** a `dns:` override pointing at Pi-hole that the container can't reach.
**Fix:** remove the `dns:` entry, use `extra_hosts` as above.

### "nextcloud is not configured as a trusted domain"
**Cause:** notify_push reaches Nextcloud via `NEXTCLOUD_URL=http://nextcloud`, but
`nextcloud` isn't in `trusted_domains`.
**Fix:** add it to the env in `compose.yaml`:
```yaml
NEXTCLOUD_TRUSTED_DOMAINS: drive.${DOMAIN} nextcloud
```

### "<ip> is not trusted as a reverse proxy by Nextcloud"
**Cause:** the notify_push container's IP (on the internal Docker subnet, e.g.
172.18.x) isn't in `trusted_proxies`, which only covered the proxy subnet.
**Fix:** widen it to cover all Docker subnets in `compose.yaml`:
```yaml
TRUSTED_PROXIES: 172.16.0.0/12
```

### Setup still fails after changing trusted_proxies / trusted_domains
**Cause:** notify_push reads `config.php` **once at startup**. Config changes
aren't seen until it restarts.
**Fix:** restart the container (the deploy playbook does this automatically after
installing apps / changing config):
```bash
docker restart nextcloud-notify-push
```

### Container log stuck on "waiting for notify_push binary"
**Cause:** the companion started before the `notify_push` app (which ships the
binary) was installed. The entrypoint waits for the binary; old log lines are
stale. A restart picks it up.
**Fix:** the playbook installs the app then restarts the container. Manually:
```bash
docker restart nextcloud-notify-push
docker exec nextcloud-notify-push cat /proc/1/cmdline   # should show .../notify_push ...
```

## Success looks like

```
✓ redis is configured
✓ push server is receiving redis messages
✓ push server can load mount info from database
✓ push server can connect to the Nextcloud server
✓ push server is a trusted proxy
✓ push server is running the same version as the app
```

## Reverse proxy reminder

Traefik routes `Host(drive.example.com) && PathPrefix(/push)` to the
notify-push service on port 7867, **stripping the `/push` prefix** (middleware
`notify-push-strip`), priority 100 so it wins over the main Nextcloud router.
