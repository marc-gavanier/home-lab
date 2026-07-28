# Collabora Online

Collaborative editing of documents, spreadsheets and presentations inside
Nextcloud — a private alternative to Google Docs, running on the Pi.

## Access

- Not visited directly. It is embedded by Nextcloud: open a `.odt`/`.docx`/
  `.xlsx` in `https://drive.example.com` and the editor loads from
  `https://office.example.com` (VPN required, like everything else).
- The admin console at `https://office.example.com/browser/dist/admin/admin.html`
  is not enabled — no admin credentials are configured.

## Architecture

Two halves that are useless apart:

| Piece | Where |
|-------|-------|
| `collabora` container | the document server (`coolwsd`), one chroot jail per open document |
| `richdocuments` app | the Nextcloud-side connector, enabled and configured by the deploy |

**Both halves address the server as `https://office.example.com`** — Nextcloud
included, even though the container sits one Docker network away. That is
deliberate and is the single least obvious thing about this service: see
"The URL trap" below. Collabora then calls Nextcloud *back* to fetch and save
the file, so each container pins the other's public name to the Pi's LAN IP.

## The URL trap

Setting `wopi_url` to `http://collabora:9980` — the container name, which *is*
how Nextcloud reaches the server — breaks document opening, and every
server-side check stays green while it does.

richdocuments fetches the WOPI discovery from `wopi_url` and hands the browser
the `urlsrc` it finds there **verbatim**. Collabora builds that value from the
`Host` header, so it answers with whatever name it was asked by. The browser
then gets `http://collabora:9980/…` and refuses it against the CSP allowlist,
which comes from `public_wopi_url`:

```
Content-Security-Policy: blocked form-action at https://collabora:9980/browser/…/cool.html
because it violates: form-action 'self' https://office.example.com
```

Symptom: *"Failed to load Nextcloud Office (Collabora)"*, then a plain download
after a hard refresh. Collabora's log stays **empty** — no request ever arrives.
Only the browser console shows it.

Both URLs are therefore the public name, and the `office.example.com` pin on the
Nextcloud container is what lets it reach that name at all.

## Configuration — owned by the repository

`roles/deploy/tasks/collabora.yml` re-asserts `wopi_url` and `public_wopi_url`
on every deploy, comparing before writing. A change made in Nextcloud's admin UI
is reverted on the next deploy, on purpose.

This matters more than it looks: `richdocuments:activate-config` derives
`public_wopi_url` from `wopi_url` by swapping the scheme — which hands the
browser the internal container name — and it **overwrites the stored value even
when that value is already right**. So the deploy sets it *after* running
`activate-config`, never before. Setting it first looks like it worked and is
silently undone in the same run.

If document editing ever fails with the browser trying to reach `collabora:9980`,
this is why. Check it with:

```bash
docker exec -u www-data nextcloud php occ config:app:get richdocuments public_wopi_url
```

## Hardening — and the two exceptions

Established by measurement in the #16 sandbox (ADR-021):

- `cap_drop: ALL` plus exactly **`SYS_CHROOT`, `CHOWN`, `FOWNER`**. Removing any
  one gives `exit 70` at startup. `MKNOD` is **not** required, despite
  Collabora's documentation.
- The image already runs as **uid 1001** and ships **no shell**.
- **No `no-new-privileges`** — the second exception in the stack after netdata,
  for the same reason: `coolforkit-caps` carries file capabilities and must gain
  them after `exec`.
- **No `read_only`** — it works, but costs ~700 MB of RAM instead of 759 MB of
  disk. Full reasoning and numbers in ADR-021.

## The failure mode to recognise

If `no-new-privileges` is ever added back, **the container does not crash**. It
stays `running`, answers `/hosting/discovery`, and loops on:

```
INF  Waiting for a new child for a max of 20000ms
```

No document can open, and `docker ps` looks perfect. The image's healthcheck
does catch it, so the "unhealthy > 10 min" alert covers it — but a human
checking status by eye would not.

Three `ERR` lines about `coolmount` and `CAP_SYS_ADMIN` at every start are
**expected**: they are the bind-mount fallback described in ADR-021.

## Verify it actually works

Status is not the test — a document conversion is. This runs the same path a
user does, jail included:

```bash
printf 'probe\n' > /tmp/p.txt
docker cp /tmp/p.txt nextcloud:/tmp/p.txt
docker exec nextcloud curl -sf -m 90 -o /tmp/p.pdf \
  -F 'data=@/tmp/p.txt' http://collabora:9980/cool/convert-to/pdf
docker exec nextcloud head -c 5 /tmp/p.pdf     # must print %PDF-
```

The deploy runs exactly this and fails if the result is not a PDF.

To check the callback direction (Collabora → Nextcloud), which is the one the
`extra_hosts` pin exists for:

```bash
docker run --rm --network proxy --add-host drive.example.com:192.168.1.100 \
  redis:8.8.1-alpine sh -c 'wget -S -q -O /dev/null https://drive.example.com/status.php'
```

Without the `--add-host`, this returns `bad address` — the name resolves only in
split DNS, and the container is not a Pi-hole client.

## Data

None. Collabora is stateless: documents live in Nextcloud, and the jail trees
under `/opt/cool/child-roots` are rebuilt at every start. **Nothing to back up.**

## Undo

Collabora is additive — no other service depends on it, which is why it carries
no automatic rollback (ADR-021). To remove it:

```bash
docker exec -u www-data nextcloud php occ app:disable richdocuments
cd /opt/homelab && docker compose rm -sf collabora
```

Then drop the `collabora` block from `docker/compose.yaml`, the `office` entry
from the Pi-hole split-DNS template, and the service from wave 3 of
`homelab-stack-startup.sh` — otherwise the next deploy brings it back.
