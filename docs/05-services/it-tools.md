# IT-Tools

An offline collection of developer utilities — JWT decoder, hash and base64, UUID, cron
parser, regex tester, YAML↔JSON, colour and date conversions, and around eighty more.

The point is not convenience, it is where the data goes. Reaching for a random web tool
to decode a JWT means pasting a live token into someone else's server. This is the same
toolbox on the LAN, and the tokens stop leaving.

## Access

- URL: `https://tools.example.com` (VPN-only, like the other internal services — the
  subdomain only resolves on the LAN/VPN via Pi-hole split DNS).
- No login. See *Why only one lock* below.

## Why Only One Lock

Dozzle carries its own credentials on top of the network gate; this does not, and the
difference is worth stating rather than looking like an oversight.

Every tool here runs **in the browser**. The container serves static files and nothing
else: it never parses a token, never stores one, and never sees what is pasted into the
JWT decoder — that work happens in the page, on the client. So there is no server-side
secret behind the gate to defend, and a second lock would guard an empty room.

What `vpn-only` does buy is that the page itself cannot be reached from the internet,
which matters because the *page* is the sensitive part: a compromised bundle would be a
compromised bundle regardless of who could load it, but a page nobody outside can request
is a page nobody outside can attack.

## The Image, and Why It Is Pinned Oddly

This is the one service in the stack pinned to a **digest on a moving tag**:

```yaml
image: corentinth/it-tools:nightly@sha256:f07d2465...
```

Upstream stopped cutting releases. The newest tagged version is `2024.10.22-7ca5933`, and
its image ships **Alpine 3.20 — past end of support — with nginx 1.26.2**. The repository
is alive (commits through 2026-07), so `nightly` is not an unstable channel here, it is
simply where the maintenance went: **Alpine 3.23, nginx 1.28.2**.

Serving a 21-month-old base in order to stop using third-party web tools would defeat the
purpose of self-hosting this at all. The digest restores what the moving tag gives up:
the deployed artefact cannot change underneath us, and Renovate raises a PR when it moves.

**This pin needs re-reading, not just bumping.** `nightly` itself was last built
2026-02-13. If it goes stale too, that is the signal to drop the service rather than pin
it deeper — see [ADR-024](../../knowledge/decisions/ADR-024-it-tools-toolbox.md).

## How It Runs

Static nginx, and cheaper than anything else in the stack: **4.35 MB** of RAM measured at
idle, against the ~50 MB the service shortlist assumed. `docker diff` shows an **empty
write set**, which is what makes `read_only: true` free.

It runs as uid 101 with **zero capabilities** — including `NET_BIND_SERVICE`, even though
nginx listens on port 80. Docker sets `net.ipv4.ip_unprivileged_port_start=0` inside the
container, so the bind needs no capability at all. Measured, not assumed: it serves 200
with `--cap-drop ALL` and nothing added.

Three tmpfs mounts carry `uid=101,gid=101`, which no other tmpfs in `compose.yaml` needs:

```yaml
- /var/cache/nginx:size=16m,uid=101,gid=101
```

A tmpfs is mounted root-owned `0755` by default, so uid 101 cannot create
`/var/cache/nginx/client_temp` and nginx exits 1 at startup with
`mkdir() ... failed (13: Permission denied)`. The message reads like a read-only-filesystem
problem and is not one — it is ownership.

## Data and Restore

There is none. No volume, no database, no secret, no state of any kind: the container is
its image. Nothing is in the restic set, and restoring means re-running the deploy role.

## Health

- Healthcheck: `curl -fsS http://127.0.0.1/` — the image is Alpine and carries both `curl`
  and `wget`.
- Uptime Kuma: HTTP monitor on `https://tools.example.com/`, expecting **200**.

  The root is the right target **here**, which looks like it contradicts the rule Dozzle
  established (probe a function endpoint, never `/`). It does not. That rule exists because
  a service with a backend can serve its page while the backend is dead. This service *is*
  the page — there is nothing behind it that can fail independently. When `/` returns 200,
  everything IT-Tools does is working.
