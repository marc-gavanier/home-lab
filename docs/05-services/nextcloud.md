# Nextcloud

Personal cloud — file sync, mobile access, and more.

## Access

- URL: `https://drive.example.com`
- Admin credentials: set in `local.yml`

## What It Does

- File storage and synchronization across devices
- Mobile access (photos, documents, files)
- WebDAV, CalDAV, CardDAV support
- Collaborative editing (with optional apps)

## Client Setup

### Desktop (Linux)
```bash
sudo apt install nextcloud-desktop
```
Open the app, connect to `https://drive.example.com`, sign in, and choose which folders to sync.

### Mobile (Android/iOS)
Install the [Nextcloud app](https://nextcloud.com/install/#install-clients) and connect to `https://drive.example.com`.

## First Steps

1. Log in at `https://drive.example.com` with admin credentials
2. Enable 2FA (Settings > Security > Two-Factor Authentication)
3. Install recommended apps (Calendar, Contacts, Notes, etc.)
4. Set up desktop/mobile sync clients

## Data

| Path                                 | Content                      |
|--------------------------------------|------------------------------|
| `/mnt/data/services/nextcloud/data/` | Nextcloud files and app data |
| `/mnt/data/services/nextcloud/db/`   | MariaDB database             |

## Backup

Backed up daily by Restic. Database is dumped before each snapshot (`nextcloud.sql`).

## Restore

```bash
# Stop Nextcloud
docker stop nextcloud nextcloud-db

# Restore from backup
restic restore latest --target / --include /mnt/data/services/nextcloud

# Restore database
docker start nextcloud-db
sleep 10
docker exec -i nextcloud-db mariadb -unextcloud -p nextcloud < /mnt/data/backups/dumps/nextcloud.sql

# Start Nextcloud
docker start nextcloud
```