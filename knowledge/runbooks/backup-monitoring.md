# Runbook — Backup monitoring (Uptime Kuma push)

The daily Restic backup (`scripts/backup.sh`, run by `homelab-backup.timer`) reports its
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

## Notes

- Interval 25 h: a missed daily run turns the monitor red ~1 h after the expected time.
  Tighten or loosen to taste.
- The ping is best-effort (`curl ... || true`): a monitoring/network outage never fails
  the backup itself.
- Logs: `/var/log/homelab-backup.log` on the Pi.
