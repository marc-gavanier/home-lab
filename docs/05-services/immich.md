# Immich

Photo management and backup — a personal Google Photos, with automatic mobile backup, face and
object recognition, timeline, albums, map view and duplicate detection.

## At a glance

| | |
|---|---|
| URL | `https://photos.example.com` |
| Containers | `immich-server`, `immich-ml` (compose service `immich-machine-learning`) |
| Data | see table below |
| Backup | restic daily; database via Immich's own scheduled dump |
| RAM | ~1 GB with machine learning — the heaviest service |

| Path                                  | Content                            |
|---------------------------------------|------------------------------------|
| `/mnt/data/services/immich/upload/`   | Uploaded photos and videos         |
| `/mnt/data/services/immich/db/`       | PostgreSQL database                |
| `/mnt/data/services/immich/ml-cache/` | Machine learning model cache       |
| `/mnt/data/media/photos/`             | External photo library (read-only) |

## First steps

1. Open `https://photos.example.com` and create the admin account.
2. Install the [Immich app](https://immich.app/download) and connect to `https://photos.example.com`.
3. Enable auto-backup (Settings > Backup > Enable).
4. Choose which albums/folders to back up.

## Backup and restore

- The backup hooks do not dump the database. Immich's scheduled DB backup (Admin → Settings →
  Backup) writes `upload/backups/*.sql.gz`, which restic captures. It handles the VectorChord /
  pgvecto.rs extensions correctly; a hand-rolled `pg_dump` does not.
- Check the built-in backup is enabled and `upload/backups/` holds a recent `*.sql.gz`. The
  directory is `0700 root`, so list it with
  `sudo sh -c 'ls -l /mnt/data/services/immich/upload/backups'` (a bare `sudo ls` with a glob
  expands in your shell and finds nothing).
- Restore needs a fresh DB and a `search_path` transform: follow
  `knowledge/runbooks/restore-from-backup.md` → "Restore Immich".

## Common tasks

Check RAM:

```bash
ssh homelab "docker stats --no-stream immich-server immich-ml"
```

Free RAM by removing machine learning. Use `down`, not `docker stop` (the heal timer restarts a
non-zero exit), and the service name, not the container name `immich-ml`. The next boot or deploy
recreates it.

```bash
ssh homelab "cd /opt/homelab && docker compose down immich-machine-learning"
```
