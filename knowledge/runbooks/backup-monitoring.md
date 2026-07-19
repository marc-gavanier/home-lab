# Runbook — Backup monitoring (Uptime Kuma push)

The daily Restic backup (`ansible/roles/deploy/files/backup.sh`, run by `homelab-backup.timer`) reports its
outcome to an Uptime Kuma **Push** monitor — a dead-man's switch that goes red both on
failure *and* when no backup ran at all (Pi down, timer broken, repo unreachable).

## How it works

- On exit, `backup.sh` pings the monitor via a `trap`: `status=up` on success,
  `status=down` (with the error) on failure.
- If Uptime Kuma receives no ping within the monitor's interval, it marks the monitor
  down and fires the attached notification.
- The push URL is injected by Ansible: `backup_kuma_push_url` (vault `local.yml`) →
  `backup.env` → `KUMA_PUSH_URL`. Empty value = monitoring disabled (the ping is a no-op),
  so the backup keeps working even if monitoring isn't set up.

## One-time setup (Uptime Kuma UI)

1. **Add New Monitor** → Monitor Type: **Push**.
2. Friendly Name: e.g. `Homelab backup`.
3. **Heartbeat Interval**: `90000` s (25 h) — one daily run plus grace. Retries: `0`.
4. Under **Notifications**, tick your existing notification channel.
5. **Save**, then copy the monitor's **Push URL**. Use the *base* form
   `https://<uptime-kuma>/api/push/<token>` — drop any trailing `?status=up&msg=OK&ping=`
   query string (the script appends its own).
6. Put it in `ansible/inventory/host_vars/homelab/local.yml`:
   ```yaml
   backup_kuma_push_url: "https://<uptime-kuma>/api/push/<token>"
   ```
7. Deploy (from the `ansible/` directory):
   ```
   ansible-playbook playbooks/site.yml --tags deploy \
     --start-at-task "Copy backup script" --ask-vault-pass
   ```
   This redeploys `backup.sh` and regenerates `backup.env` with `KUMA_PUSH_URL`.

## Test

Trigger a run and watch the monitor turn green:

```
ssh homelab 'sudo systemctl start homelab-backup.service'
```

The monitor should go up within seconds of the `=== Backup completed ===` log line. To
exercise the down path, point `RESTIC_REPOSITORY` at a bad path temporarily and run — the
monitor goes red and the notification fires.

## Local maintenance monitor

The weekly local prune+check (`local-maintenance.sh`, `homelab-local-maintenance.timer`,
Sunday 05:00) reports to its own push monitor, same pattern as the offsite check:

| Monitor            | Pinged by                                       | Interval       | Vault variable                                    |
|--------------------|-------------------------------------------------|----------------|---------------------------------------------------|
| Local prune+check  | `local-maintenance.sh` (homelab, Sunday 05:00)  | 700000 s (8 d) | `local_maintenance_kuma_push_url` (homelab local) |

Create the Push monitor first (8 d interval covers a weekly run plus grace), then set
`local_maintenance_kuma_push_url` in `local.yml` and redeploy with the same
`--start-at-task "Copy backup script"` command. This variable is **optional**: empty just
disables the monitor ping — the prune+check timer still runs.

## Offsite monitors (ADR-010)

Three more push monitors follow the same pattern:

| Monitor        | Pinged by                                      | Interval       | Vault variable                                     |
|----------------|------------------------------------------------|----------------|----------------------------------------------------|
| Offsite copy   | `backup.sh` copy step (homelab, nightly)       | 90000 s (25 h) | `offsite_copy_kuma_push_url` (homelab local.yml)   |
| Offsite check  | `offsite-check.sh` (homelab, Sunday 06:00)     | 700000 s (8 d) | `offsite_check_kuma_push_url` (homelab local.yml)  |
| Offsite health | `offsite-health.sh` (offsite Pi, Sunday 08:00) | 700000 s (8 d) | `offsite_health_kuma_push_url` (offsite local.yml) |

Deploy after filling the vault variables: same `--start-at-task "Copy backup
script"` command for the homelab ones; for the offsite Pi:
`ansible-playbook playbooks/offsite.yml --tags offsite-backup --ask-vault-pass`.

"Offsite health" watches the SMART early-warning counters individually (the
overall `smartctl -H` verdict stays PASSED until a drive is nearly dead) and
the result of the monthly long self-test (`offsite-smart-test.timer`, 1st at
04:00), plus SSD/CPU temperature and Pi undervoltage. See the offsite runbook
for the exact DOWN conditions.

Note: the offsite Pi reaches Kuma through the WireGuard tunnel:
`services.<domain>` is pinned to the homelab host's VPN address (10.8.0.5,
where Traefik also listens) in its cloud-init hosts template (deployed by
the `offsite-backup` role). Do NOT route the homelab LAN IP through the
tunnel instead — that breaks direct-LAN traffic while the Pi is prepared at
home. Use the exact same `https://services.<domain>/api/push/<token>` URL
form as the homelab monitors.

## Notes

- Interval 25 h: a missed daily run turns the monitor red ~1 h after the expected time.
  Tighten or loosen to taste.
- The ping is best-effort (`curl ... || true`): a monitoring/network outage never fails
  the backup itself.
- Logs: `/var/log/homelab-backup.log` on the Pi.
