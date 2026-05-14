# Immich

Photo management and backup — personal Google Photos.

## Access

- URL: `https://photos.example.com`

## What It Does

- Automatic photo/video backup from mobile devices
- AI-powered face recognition and object detection
- Timeline view, albums, sharing
- Map view (GPS metadata)
- Duplicate detection

## Client Setup

### Mobile (Android/iOS)
Install the [Immich app](https://immich.app/download) and connect to `https://photos.example.com`. Enable automatic backup in the app settings.

### Browser
Access directly at `https://photos.example.com`.

## First Steps

1. Open `https://photos.example.com` — create admin account
2. Install mobile app and sign in
3. Enable auto-backup (Settings > Backup > Enable)
4. Choose which albums/folders to back up

## RAM Warning

Immich is the most RAM-hungry service (~1 GB with machine learning). Monitor with:
```bash
ssh homelab "docker stats --no-stream immich-server immich-ml"
```

If RAM is too tight, disable machine learning by stopping the ML container:
```bash
ssh homelab "docker stop immich-ml"
```

## Data

| Path                                  | Content                            |
|---------------------------------------|------------------------------------|
| `/mnt/data/services/immich/upload/`   | Uploaded photos and videos         |
| `/mnt/data/services/immich/db/`       | PostgreSQL database                |
| `/mnt/data/services/immich/ml-cache/` | Machine learning model cache       |
| `/mnt/data/media/photos/`             | External photo library (read-only) |

## Backup

Backed up daily by Restic. Database is dumped before each snapshot (`immich.sql`).

## Restore

```bash
# Stop Immich
docker stop immich-server immich-ml immich-redis immich-db

# Restore from backup
restic restore latest --target / --include /mnt/data/services/immich

# Restore database
docker start immich-db
sleep 10
docker exec -i immich-db psql -U immich immich < /mnt/data/backups/dumps/immich.sql

# Start all components
docker start immich-redis immich-ml immich-server
```
