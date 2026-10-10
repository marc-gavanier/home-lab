# Runbook — Backup monitoring (Uptime Kuma push)

Use this to create, wire or test the push monitors of the backup chain. Each is a dead-man's switch:
it goes red on a failed run and when no run happened at all.

## How it works

- `backup-notify.sh` pings the monitor from resticprofile's hooks (`homelab-backup.timer`,
  ADR-031): `status=up` on success, `status=down` with the error on failure.
- No ping within the monitor's interval → Kuma marks it down and notifies.
- Ansible injects the URL: `backup_kuma_push_url` (vault `local.yml`) → `backup.env` →
  `KUMA_PUSH_URL`. Empty = monitoring off; the backup still runs.
- The ping is best-effort (`curl ... || true`): a monitoring outage never fails the backup.

## Monitors

| Monitor               | Pinged by                                            | Interval        | Vault variable                                     |
|-----------------------|------------------------------------------------------|-----------------|----------------------------------------------------|
| Backup                | resticprofile `backup` (homelab, nightly)            | 93600 s (26 h)  | `backup_kuma_push_url` (homelab local.yml)         |
| Pi restic prune+check | `resticprofile -n homelab prune`+`check` (Tue 01:00) | 691200 s (8 d)  | `local_maintenance_kuma_push_url` (homelab local)  |
| Offsite backup        | resticprofile `copy` (homelab, nightly)              | 100800 s (28 h) | `offsite_copy_kuma_push_url` (homelab local.yml)   |
| Offsite check         | `resticprofile -n offsite check` (Tue 02:00)         | 700000 s (8 d)  | `offsite_check_kuma_push_url` (homelab local.yml)  |
| Offsite health        | `offsite-health.sh` (offsite Pi, 08:00 + ≤15 min)    | 93600 s (26 h)  | `offsite_health_kuma_push_url` (offsite local.yml) |

- 26 h on the nightly monitors, counted from the last push: a missed run turns red ~2 h after the
  expected time, later if a manual run pushed since. The offsite copy gets 28 h: a night that ingests
  ~30 GiB ends past 05:00.
- Prune+check (`homelab-local-maintenance.timer`) runs a metadata check weekly and a deep
  read-data check on the run in the first 7 days of the month. Its variable is optional.
- Offsite health alarms on SMART early-warning counters (not the overall `smartctl -H` verdict),
  the monthly long self-test (`offsite-smart-test.timer`, 1st at 04:00 + up to 15 min), SSD temperature ≥ 70 °C,
  CPU temperature ≥ 70 °C, undervoltage, security updates unapplied after 48 h, and package lists not
  refreshed for 72 h. Exact DOWN conditions: the offsite runbook.

## Create a monitor (Uptime Kuma UI)

1. **Add New Monitor** → Monitor Type: **Push**.
2. Friendly Name: e.g. `Homelab backup`.
3. **Heartbeat Interval**: from the table above (`93600` s for the nightly backup). Retries: `0`.
4. Under **Notifications**, tick the existing notification channel.
5. **Save**, then copy the **Push URL** in its base form `https://<uptime-kuma>/api/push/<token>` —
   drop any trailing `?status=up&msg=OK&ping=` (the script appends its own).
6. Put it in the vault named in the table, e.g. `ansible/inventory/host_vars/homelab/local.yml`:
   ```yaml
   backup_kuma_push_url: "https://<uptime-kuma>/api/push/<token>"
   ```
7. Deploy from `ansible/`. For the homelab variables:
   ```
   ansible-playbook playbooks/site.yml --tags deploy \
     --start-at-task "backup | Template backup environment file (encrypted volume)" \
     --ask-vault-pass
   ```
   For the offsite Pi: `ansible-playbook playbooks/offsite.yml --tags offsite-backup --ask-vault-pass`.

Expected: the play runs tasks and regenerates `backup.env`. If it runs no task at all, the
`--start-at-task` name matched nothing — nothing was deployed.

The offsite Pi reaches Kuma through the tunnel: `services.<domain>` is pinned to the homelab's VPN
address (10.8.0.5) in its cloud-init hosts template. Use the same
`https://services.<domain>/api/push/<token>` form. Do not route the homelab LAN IP through the
tunnel instead — it breaks direct-LAN traffic while the Pi is prepared at home.

## Check it worked

```
ssh homelab 'sudo systemctl start homelab-backup.service'
```

Expected: two monitors go green (backup and offsite copy), with two journal lines:

```
[…] notify: pushed up (backup): dumps ok (N checks), snapshot <id>
[…] profile 'homelab': finished 'copy'
[…] notify: pushed up (copy): offsite copy completed
```

To test the down path, point `RESTIC_REPOSITORY` at a bad path temporarily and run: the monitor
goes red and notifies.

## If it fails

| Symptom                           | Action                                                                                                                                |
|-----------------------------------|---------------------------------------------------------------------------------------------------------------------------------------|
| DOWN message                      | It ends with `journalctl -u <unit> -n 50` — the cause is in the journal (`journalctl -u homelab-backup`)                              |
| Looking in the log file           | `/var/log/homelab-backup.log` holds only the notify lines and dump stderr, never restic's output                                      |
| `No heartbeat in the time window` | The job never pushed. `systemctl list-timers 'homelab-*'`, then its journal. `Offsite health`: [offsite-backup.md](offsite-backup.md) |
