# Jellyfin

Video streaming server — personal Netflix.

## Access

- URL: `https://videos.example.com`

## What It Does

- Stream movies and TV shows from your library
- Transcoding for devices that don't support the source format (limited on Pi 4 — prefer direct play)
- Metadata fetching (posters, descriptions, subtitles)
- Multi-user support

## Client Setup

### Browser
Access directly at `https://videos.example.com`.

### Mobile (Android/iOS)
Install the [Jellyfin app](https://jellyfin.org/downloads/) and connect to `https://videos.example.com`.

### TV
Jellyfin apps are available for Android TV, Fire TV, Roku, etc.

## First Steps

1. Open `https://videos.example.com` — setup wizard appears on first access
2. Create an admin account
3. Add media libraries pointing to `/media/videos`
4. Install mobile/TV apps

## Adding Media

Place video files on the Pi:
```bash
scp movie.mkv homelab:/mnt/data/media/videos/Movies/
```

Jellyfin scans libraries periodically or you can trigger a manual scan from the dashboard.

## Data

| Path                                  | Content                               |
|---------------------------------------|---------------------------------------|
| `/mnt/data/services/jellyfin/config/` | Jellyfin configuration and metadata   |
| `/mnt/data/services/jellyfin/cache/`  | Transcoding cache                     |
| `/mnt/data/media/videos/`             | Video files (not managed by Jellyfin) |

## Performance Note

The Pi 4 has no hardware transcoding support. Use direct play whenever possible (clients that support your video formats natively). If transcoding is needed, limit to 720p.

## Restore

```bash
docker stop jellyfin
restic restore latest --target / --include /mnt/data/services/jellyfin
docker start jellyfin
```

Media files in `/mnt/data/media/videos/` are backed up daily with the rest of `/mnt/data/media`.
