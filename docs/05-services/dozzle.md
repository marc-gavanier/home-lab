# Dozzle

Real-time container logs in the browser, so logs are reachable without SSH like metrics and
uptime already were.

## At a glance

| | |
|---|---|
| URL | `https://logs.example.com` (VPN-only, Pi-hole split DNS) |
| Login | required, on top of `vpn-only` |
| Image | `amir20/dozzle:v11.1.0` |
| Data | none — stateless, nothing under `${SERVICES_DATA_DIR}` |
| Credentials | `/mnt/data/secrets/docker/dozzle_users.yml`, templated by Ansible (bcrypt), in the restic set |
| Supervision | `dozzle healthcheck` + Uptime Kuma on `/healthcheck` |
| ADR | ADR-016 (secrets as files) |

## How it works

- Tails every container's stdout/stderr live, with search and multi-container views. No agent, no
  storage: it reads the Docker log stream on demand.
- Why a login: it shows every other container's output (session ids, e-mail addresses), so a
  stolen WireGuard key or compromised LAN device must not be enough.
- Credentials are rendered by the deploy role and bind-mounted read-only at `/data/users.yml` as a
  file — never through its directory, which would resolve in the container's namespace.
- Reads Docker through the shared read-only `socket-proxy`, never the raw `docker.sock`.
- The proxy needs `INFO=1`: without it Dozzle logs `Could not connect to any Docker Engine` and
  exits 1. Traefik and Netdata gain `/info` too; it returns daemon metadata, no secrets.
- `POST` stays `0`. Keep `DOZZLE_ENABLE_ACTIONS` and `DOZZLE_ENABLE_SHELL` at `false`: those
  buttons would fail against the proxy.
- The container list shows mount paths (e.g. `/mnt/data/secrets/docker/immich_db_password`), never
  secret values.
- `read_only: true` (empty `docker diff`) with `/tmp:size=8m`; runs as uid 65534 (`nobody`) with
  every capability dropped.

## Common tasks

Change the password: generate a bcrypt hash with the image's CLI, then paste it into
`dozzle_admin_password_hash` in the vaulted `local.yml` and redeploy.

```bash
docker run -it --rm amir20/dozzle:v11.1.0 \
  generate admin --email admin@localhost --name 'Admin'
```

- Omit `--password`: it prompts, so the password stays out of shell history.
- Keep the password at 72 bytes or less (an accented character is two bytes).
- Hash in the vault, not at deploy time: bcrypt salts randomly, so a deploy-time hash would
  report `changed` forever.

Restore: re-run the deploy role. It re-renders `dozzle_users.yml` and starts the container.

## Health

- Healthcheck: `dozzle healthcheck`, a real HTTP request to its listener (the image has no shell,
  `wget` or `curl`).
- Uptime Kuma: HTTP monitor on `https://logs.example.com/healthcheck`, expecting 200, no
  credentials. Never monitor `/`: it keeps answering after Dozzle loses the Docker API, while
  `/healthcheck` turns 500.

## Troubleshooting

| Symptom | Cause | Action |
|---|---|---|
| Exits 1 with `Could not connect to any Docker Engine` | `socket-proxy` lacks `INFO=1` | Set `INFO=1` on the proxy |
| `FTL Failed to hash password error="bcrypt: password length exceeds 72 bytes"` | Password over 72 bytes | Use a shorter password |
| UI loads but shows no containers | Docker API lost (socket-proxy down) | Check `socket-proxy` |
