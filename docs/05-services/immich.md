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

If RAM is too tight, disable machine learning by removing the ML container:
```bash
ssh homelab "cd /opt/homelab && docker compose down immich-machine-learning"
```

`immich-machine-learning` is the compose **service**; `immich-ml` is only its
container name, and `compose` answers "no such service" if you pass it.
`docker stop` would not work here either: the heal timer brings a stopped
container back within two minutes, so the RAM never actually frees.

## Data

| Path                                  | Content                            |
|---------------------------------------|------------------------------------|
| `/mnt/data/services/immich/upload/`   | Uploaded photos and videos         |
| `/mnt/data/services/immich/db/`       | PostgreSQL database                |
| `/mnt/data/services/immich/ml-cache/` | Machine learning model cache       |
| `/mnt/data/media/photos/`             | External photo library (read-only) |

## Backup

Backed up daily by Restic. The database is **not** dumped by `backup.sh` — Immich
runs its own scheduled DB backup (Admin → Settings → Backup) to
`upload/backups/*.sql.gz`, which lives under `/mnt/data/services/immich` and is
therefore captured in every Restic snapshot. This produces a correctly-formatted
dump for the VectorChord / pgvecto.rs extensions (a hand-rolled `pg_dump` needs a
`search_path` transform on restore and is easy to get wrong).

Confirm the built-in backup is enabled (Admin → Settings → Backup) and that
`upload/backups/` holds a recent `*.sql.gz`.

## Restore

The DB restore has extension-specific steps (fresh DB + `search_path` transform).
Full procedure: `knowledge/runbooks/restore-from-backup.md` → "Restore Immich".
