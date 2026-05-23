# Nextcloud

Personal cloud — file sync, contacts/calendar, and a browse-only window onto the media libraries.

## Access

- URL: `https://drive.example.com` (VPN required — see ADR-002)
- Admin user: `admin` / password set in `local.yml` (`nextcloud_admin_password`)

## Architecture

Nextcloud runs as **five containers** sharing one data volume:

| Container | Role |
|-----------|------|
| `nextcloud` | Apache web server (the app itself) |
| `nextcloud-db` | MariaDB database |
| `nextcloud-redis` | Redis — memory cache + transactional file locking |
| `nextcloud-cron` | Companion running `/cron.sh` every 5 min (system cron, not AJAX) |
| `nextcloud-notify-push` | Companion running the notify_push binary — real-time update push to clients |

## What It Does

- File storage and sync across devices (desktop client + mobile app)
- **Contacts, Calendar, Tasks** over CardDAV/CalDAV (synced to phone via DAVx5)
- **Browse the media libraries** (photos/music/videos) read-only — see "Media browsing" below
- Real-time client updates via **notify_push** (no more polling)
- Productivity apps: Calendar, Contacts, Tasks, Bookmarks, GpxPod, External Sites

## Hardening & performance

Configured via Ansible (`roles/deploy`) — re-applied on every deploy:

- `TRUSTED_PROXIES=172.16.0.0/12` — trust Traefik **and** the notify_push container (both on Docker subnets) so forwarded headers (HTTPS, real client IP) are honored
- `NEXTCLOUD_TRUSTED_DOMAINS` includes `nextcloud` so notify_push can reach `http://nextcloud` internally
- HSTS set by Traefik middleware `nextcloud-headers` (`stsSeconds: 31536000`)
- Redis for `memcache.locking` + APCu for `memcache.local`
- `backgroundjobs_mode=cron`, `maintenance_window_start=4` (UTC), `default_phone_region=FR`
- `extra_hosts` pins `drive.example.com` to the Pi's LAN IP — avoids DNS hairpin on internal self-calls (see runbook)

## Client Setup

### Desktop (Linux)
```bash
sudo apt install nextcloud-desktop
```
Connect to `https://drive.example.com`, sign in, choose folders to sync.

### Mobile app (files/photos)
Install the [Nextcloud app](https://nextcloud.com/install/#install-clients), connect to `https://drive.example.com` (VPN on).

### Contacts / Calendar / Tasks (DAVx5, e.g. /e/OS or Android)
Use **DAVx5** with the **general login** ("URL and user name"), **not** the Nextcloud login-flow button (the `.well-known` redirect is currently http-only and breaks discovery):
- URL: `https://drive.example.com/remote.php/dav`  ← the `/remote.php/dav` path is required
- User: `admin`
- Password: an **app-password** (Settings → Security → "Devices & sessions" → create)

The same app-password + URL works for any CardDAV/CalDAV client.

## Media browsing (External Storage, read-only)

The media folders are mounted **read-only** into the container and exposed as External Storage so Nextcloud can browse/download them **without duplicating Jellyfin/Navidrome/Immich and without a second copy or sync**:

| Mount point | Source on disk | Container path |
|-------------|----------------|----------------|
| `/Photos` | `/mnt/data/media/photos` | `/external/photos` |
| `/Music`  | `/mnt/data/media/music`  | `/external/music`  |
| `/Videos` | `/mnt/data/media/videos` | `/external/videos` |

After adding new media (e.g. via rsync), run a scan so Nextcloud sees it:
```bash
docker exec -u www-data nextcloud php occ files:scan --path='admin/files/Photos'
```

See ADR-003 for the rationale.

## Data

| Path                                 | Content                       |
|--------------------------------------|-------------------------------|
| `/mnt/data/services/nextcloud/data/` | Nextcloud files and app data  |
| `/mnt/data/services/nextcloud/db/`   | MariaDB database              |

(Redis is a cache only — nothing to back up. Media External Storage points at the existing media libraries, backed up with them.)

## Backup

Backed up daily by Restic. Database is dumped before each snapshot (`nextcloud.sql`).

## Restore

```bash
# Stop Nextcloud (web + companions)
docker stop nextcloud nextcloud-cron nextcloud-notify-push nextcloud-db

# Restore files from backup
restic restore latest --target / --include /mnt/data/services/nextcloud

# Restore database
docker start nextcloud-db
sleep 10
docker exec -i nextcloud-db mariadb -unextcloud -p nextcloud < /mnt/data/backups/dumps/nextcloud.sql

# Start everything
docker start nextcloud nextcloud-cron nextcloud-notify-push
```
