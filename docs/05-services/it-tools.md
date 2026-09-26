# IT-Tools

An offline set of developer utilities (JWT decoder, hashes, base64, UUID, cron, regex, YAML↔JSON
and ~80 more). It exists so live tokens are never pasted into third-party web tools.

## At a glance

| | |
|---|---|
| URL | `https://tools.example.com` (VPN-only, Pi-hole split DNS) |
| Login | none — see below |
| Image | `corentinth/it-tools:nightly@sha256:…` (digest pin) |
| Data | none — no volume, database, secret or state |
| Backup | nothing; restore = re-run the deploy role |
| Supervision | healthcheck + Uptime Kuma on `/` |
| ADR | [ADR-024](../../knowledge/decisions/ADR-024-it-tools-toolbox.md) |

## How it works

- Every tool runs in the browser; the container only serves static files and never sees pasted
  data. So `vpn-only` is the only lock: there is no server-side secret to guard.
- Pinned to a digest on the `nightly` tag, the only such pin in the stack:

  ```yaml
  image: corentinth/it-tools:nightly@sha256:f07d2465...
  ```

  The last tagged release ships an end-of-life Alpine 3.20; `nightly` builds `main` on Alpine 3.23
  / nginx 1.28.2. Renovate opens a PR when the digest moves.
- An unchanged digest is normal: upstream `main` is not moving, the nightly build still succeeds.
- Drop the service if it gains a backend, state or a server-side secret; becomes reachable outside
  the VPN; or its nightly build starts failing.
- Static nginx, ~4 MB RAM, `read_only: true` (empty `docker diff`), uid 101, zero capabilities
  (Docker allows unprivileged binds to port 80 inside the container).
- Three tmpfs mounts carry `uid=101,gid=101`: a tmpfs mounts root-owned `0755` otherwise.

  ```yaml
  - /var/cache/nginx:size=16m,uid=101,gid=101
  ```

## Health

- Healthcheck: `curl -fsS http://127.0.0.1/`.
- Uptime Kuma: HTTP monitor on `https://tools.example.com/`, expecting 200. The root is correct
  here: there is no backend behind the page that could fail separately.

## Troubleshooting

| Symptom | Cause | Action |
|---|---|---|
| nginx exits 1 with `mkdir() ... failed (13: Permission denied)` | A tmpfs lost its `uid=101,gid=101` (ownership, not read-only) | Restore the tmpfs options |
