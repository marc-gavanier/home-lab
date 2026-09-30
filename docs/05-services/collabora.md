# Collabora Online

Collaborative editing of documents, spreadsheets and presentations inside Nextcloud, on the Pi.

## At a glance

| | |
|---|---|
| URL | `https://office.example.com` — not visited directly, embedded by `https://drive.example.com` (VPN) |
| Pieces | `collabora` container (`coolwsd`, one chroot jail per open document) + `richdocuments` Nextcloud app |
| Admin console | `https://office.example.com/browser/dist/admin/admin.html` — disabled, no credentials |
| Data | none — stateless, jails under `/opt/cool/child-roots` rebuilt at every start |
| Backup | nothing to back up |
| Supervision | image healthcheck ("unhealthy > 10 min" alert); deploy runs a conversion test |
| ADR | ADR-021 |

## How it works

- Both Nextcloud and the browser address the server as `https://office.example.com`. Never set
  `wopi_url` to `http://collabora:9980`: the browser receives that name and the CSP blocks it.
- Collabora calls Nextcloud back to fetch and save files, so each container pins the other's
  public name to the Pi's LAN IP (`extra_hosts`).
- `roles/deploy/tasks/collabora.yml` re-asserts `wopi_url` and `public_wopi_url` on every deploy;
  changes made in Nextcloud's admin UI are reverted.
- The deploy sets `public_wopi_url` after `richdocuments:activate-config`, because that command
  overwrites it with the internal name.
- Hardening: `cap_drop: ALL` plus exactly `SYS_CHROOT`, `CHOWN`, `FOWNER` (remove one → `exit 70`;
  `MKNOD` not needed). Runs as uid 1001, no shell.
- No `no-new-privileges` (like netdata): `coolforkit-caps` must gain file capabilities after `exec`.
- No `read_only`: it would cost ~700 MB of RAM (ADR-021).

## Common tasks

Check the public URL Nextcloud hands the browser:

```bash
docker exec -u www-data nextcloud php occ config:app:get richdocuments public_wopi_url
```

Test a real conversion (the deploy runs the same and fails unless it gets a PDF):

```bash
printf 'probe\n' > /tmp/p.txt
docker cp /tmp/p.txt nextcloud:/tmp/p.txt
docker exec nextcloud curl -sf -m 90 -o /tmp/p.pdf \
  -F 'data=@/tmp/p.txt' http://collabora:9980/cool/convert-to/pdf
docker exec nextcloud head -c 5 /tmp/p.pdf     # must print %PDF-
```

Test the callback (Collabora → Nextcloud). Without `--add-host` it returns `bad address`: the
name resolves only in split DNS.

```bash
docker run --rm --network proxy --add-host drive.<domain>:<pi-lan-ip> \
  redis:8.8.1-alpine sh -c 'wget -S -q -O /dev/null https://drive.<domain>/status.php'
```

Remove Collabora (nothing depends on it):

```bash
docker exec -u www-data nextcloud php occ app:disable richdocuments
cd /opt/homelab && docker compose rm -sf collabora
```

Then remove the `collabora` block from `docker/compose.yaml`, the `office` entry from the Pi-hole
split-DNS template, and the service from wave 3 of `homelab-stack-startup.sh`, or the next deploy
brings it back.

## Troubleshooting

| Symptom | Cause | Action |
|---|---|---|
| "Failed to load Nextcloud Office (Collabora)", then a plain download; Collabora log empty | `wopi_url` or `public_wopi_url` points at `collabora:9980`; browser console shows the CSP block below | Check `public_wopi_url`; redeploy |
| Container `running`, discovery answers, no document opens; log loops on `Waiting for a new child` | `no-new-privileges` was added | Remove it; redeploy |
| `ERR` lines about `coolmount` / `CAP_SYS_ADMIN`, about 4 at each document kit spawn, all day | Expected bind-mount fallback (ADR-021) | None |
| `ERR` about `CLONE_NEWUSER unshare failed` / AppArmor user namespaces | Expected: jails built by `coolforkit-caps` | None — do not apply the suggested sysctl |

CSP block seen in the browser console:

```
Content-Security-Policy: blocked form-action at https://collabora:9980/browser/…/cool.html
because it violates: form-action 'self' https://office.example.com
```

Loop seen with `no-new-privileges`:

```
INF  Waiting for a new child for a max of 20000ms
```
