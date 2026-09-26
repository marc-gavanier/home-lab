# Runbook: notify_push self-test fails

Use this page when the notify_push Kuma monitor goes red or `occ notify_push:setup`
fails. Clients silently fall back to 30 s polling.

## Before you start

- Fixes live in `docker/compose.yaml` and `ansible/roles/deploy/tasks/nextcloud.yml`;
  redeploy with `--tags deploy`.
- `homelab-notify-push.timer` runs the self-test hourly; the Discord alert names the
  failing step.

## Steps

1. Run the setup test; it stops at the first failing step:
   ```bash
   docker exec -u www-data nextcloud php occ notify_push:setup https://drive.<domain>/push
   ```
2. Match the message in [If it fails](#if-it-fails) and apply the fix.

## Check it worked

Run the self-test, then re-push the result to Kuma:

```bash
docker exec -u www-data nextcloud php occ notify_push:self-test
sudo systemctl start homelab-notify-push.service
```

Expected:

```
✓ redis is configured
✓ push server is receiving redis messages
✓ push server can load mount info from database
✓ push server can connect to the Nextcloud server
✓ push server is a trusted proxy
✓ push server is running the same version as the app
```

## If it fails

**"can't connect to push server: 403 Forbidden"**: DNS hairpin, the name resolves to
the public IP inside `nextcloud`. Confirm (a public IP is the bug):

```bash
docker exec nextcloud getent hosts drive.<domain>
```

Pin the name in `compose.yaml` (nextcloud service). Not `dns: ${PI_LAN_IP}`: UDP/53
to the host fails from the container.

```yaml
extra_hosts:
  - "drive.${DOMAIN}:${PI_LAN_IP}"
```

**"can't connect to push server: Could not resolve host"**: a `dns:` override points
at an unreachable Pi-hole. Remove it, use `extra_hosts`.

**"nextcloud is not configured as a trusted domain"**: redeploy; the role writes
`localhost`, `drive.<domain>`, `nextcloud` to `trusted_domains`. Editing
`NEXTCLOUD_TRUSTED_DOMAINS` does nothing after first install. Check:

```bash
docker exec -u www-data nextcloud php occ config:system:get trusted_domains
```

**"`<ip>` is not trusted as a reverse proxy by Nextcloud"**: the container's
subnet (e.g. 172.19.x) is outside `trusted_proxies`. In `compose.yaml`:

```yaml
TRUSTED_PROXIES: 172.16.0.0/12
```

**Still failing after a trusted_proxies/trusted_domains change**: notify_push reads
`config.php` only at startup. The deploy restarts it; by hand:

```bash
docker restart nextcloud-notify-push
```

**Log stuck on "waiting for notify_push binary"**: the container started before the
app installed its binary. Restart it as above, then check the command line shows
`.../notify_push ...`:

```bash
docker exec nextcloud-notify-push cat /proc/1/cmdline
```

## Reverse proxy

Traefik routes `Host(drive.example.com) && PathPrefix(/push)` to port 7867, strips
`/push` (middleware `notify-push-strip`), priority 100 over the main Nextcloud router.
