# Nextcloud

Personal cloud: file sync, contacts, calendar, tasks, and a read-only view of the
media libraries.

## At a glance

| Item   | Value                                                                                  |
|--------|----------------------------------------------------------------------------------------|
| URL    | `https://drive.example.com` (VPN, ADR-002)                                             |
| Admin  | `admin`. Password only in Nextcloud's database, not the vault (ADR-016): keep it in Vaultwarden |
| Data   | `/mnt/data/services/nextcloud/data/` (files), `/mnt/data/services/nextcloud/db/` (MariaDB) |
| Backup | Restic, daily; `nextcloud.sql` dumped before each snapshot. Redis is cache only        |
| Apps   | Calendar, Contacts, Tasks, Bookmarks, GpxPod, External Sites, [Collabora](collabora.md) (ADR-021), [LibreSign](libresign.md) |

| Container               | Role                                              |
|-------------------------|---------------------------------------------------|
| `nextcloud`             | Apache, the app                                   |
| `nextcloud-db`          | MariaDB                                           |
| `nextcloud-redis`       | Memory cache and transactional file locking       |
| `nextcloud-cron`        | `/cron.sh` every 5 min                            |
| `nextcloud-notify-push` | Real-time push to clients                         |

## How it works

The deploy (`roles/deploy`) re-applies on every run:

- `TRUSTED_PROXIES=172.16.0.0/12`: Traefik and notify_push, both on Docker subnets.
- `trusted_domains` via `occ`: `localhost`, `drive.<domain>`, `nextcloud`.
  `NEXTCLOUD_TRUSTED_DOMAINS` is read only on first install.
- HSTS by the Traefik middleware `nextcloud-headers` (`stsSeconds: 31536000`).
- Redis for `memcache.locking`, APCu for `memcache.local`.
- `backgroundjobs_mode=cron`, `maintenance_window_start=4` (UTC), `default_phone_region=FR`.
- `extra_hosts` pins `drive.example.com` to the Pi's LAN IP (DNS hairpin).
- `richdocuments` (Collabora) is configured by the deploy, not the admin UI.

### Media browsing (read-only External Storage, ADR-003)

| Mount point | Source on disk           | Container path     |
|-------------|--------------------------|--------------------|
| `/Photos`   | `/mnt/data/media/photos` | `/external/photos` |
| `/Music`    | `/mnt/data/media/music`  | `/external/music`  |
| `/Videos`   | four sources             | `/external/videos` |

- `/Videos` = `library/movies`, `library/shows` (importer) + `media/videos/home-videos`,
  `media/videos/music-videos` (operator), ADR-035.
- `filesystem_check_changes: 1`: a folder is revalidated when opened. Unopened
  folders need a scan.
- `/mnt/data/media` is backed up; `/mnt/data/library` (films, series) is not.

## Common tasks

Admin password lost (`-it`: the command prompts for the new password):

```bash
docker exec -it -u www-data nextcloud php occ user:resetpassword admin
```

Media added to a folder nobody opens:

```bash
docker exec -u www-data nextcloud php occ files:scan --path='admin/files/Photos'
```

Clients:

- Desktop (Linux): install with the command below, connect to `https://drive.example.com`.
- Mobile: the [Nextcloud app](https://nextcloud.com/install/#install-clients), VPN on.
- CardDAV/CalDAV (DAVx5): use the general login, not the login-flow button (the
  `.well-known` redirect is http-only). URL `https://drive.example.com/remote.php/dav`,
  user `admin`, an app-password (Settings → Security → "Devices & sessions").

```bash
sudo apt install nextcloud-desktop
```

Major upgrade (a Renovate PR `nextcloud:N` → `N+1`). The deploy keeps the app store off
(`appstoreenabled=false`), so the upgrade cannot fetch a compatible version of an app in
`custom_apps` and disables it instead (35: `richdocuments`, `libresign`, `bookmarks`,
`external`). There is no way back short of a restore.

1. Check each enabled app has a release for `N+1` on apps.nextcloud.com.
2. Take a fresh restore point: `sudo systemctl start homelab-backup.service`.
3. Deploy `nextcloud nextcloud-cron nextcloud-notify-push` together. It stops on the first
   `occ` call if the upgrade is still running; that is expected.
4. List what the upgrade disabled (`docker logs nextcloud | grep 'Disabled incompatible'`),
   then open the store, update and re-enable each, and close it:

   ```bash
   occ() { docker exec -u www-data nextcloud php occ "$@"; }
   occ config:system:set appstoreenabled --type=boolean --value=true
   occ app:update <app> && occ app:enable <app>
   occ config:system:set appstoreenabled --type=boolean --value=false
   ```

5. Deploy again: it converts a document through Collabora and checks LibreSign's binaries.

Restore: the dump is not on disk (the backup deletes `/mnt/data/backups/dumps/`
after each run), and the import needs `maintenance:mode`. Follow
[restore-from-backup.md](../../knowledge/runbooks/restore-from-backup.md) →
"Restore a database".

## Troubleshooting

- File stops syncing, log grows, monitors green:
  [stale locks](../../knowledge/runbooks/nextcloud-stale-locks.md).
- notify_push self-test fails:
  [notify_push](../../knowledge/runbooks/notify-push-troubleshooting.md).
- `Nextcloud` monitor red on its keyword (`maintenance` or `needsDbUpgrade`), usually after an image
  bump: `docker exec -u www-data nextcloud php occ upgrade`, then, if still in maintenance,
  `docker exec -u www-data nextcloud php occ maintenance:mode --off`.
- Posture `nextcloud-php-jit-is-disabled` red: an ini file from the image turns the JIT back on.
  `docker exec nextcloud php --ini` lists them; find the one that sorts after `zz-disable-jit.ini`
  or sets `opcache.jit*`, and extend `docker/configs/nextcloud/zz-disable-jit.ini` to override it.
