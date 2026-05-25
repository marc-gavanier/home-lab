# Navidrome

Music streaming server — personal Spotify.

## Access

- URL: `https://music.example.com`

## What It Does

- Stream your music library from anywhere
- Subsonic-compatible API (works with many third-party apps)
- Scrobbling support (Last.fm, ListenBrainz)
- Playlists, favorites, internet radio

## Client Setup

### Browser
Access directly at `https://music.example.com`.

### Mobile (Android)
- [Subtracks](https://play.google.com/store/apps/details?id=com.subtracks) (recommended)
- [Ultrasonic](https://play.google.com/store/apps/details?id=org.moire.ultrasonic)
- [DSub](https://play.google.com/store/apps/details?id=github.daneren2005.dsub)

### Mobile (iOS)
- [play:Sub](https://apps.apple.com/app/play-sub-music-streamer/id955329386)
- [Amperfy](https://apps.apple.com/app/amperfy-music/id1530145038)

Connect to `https://music.example.com` with your Navidrome credentials.

## First Steps

1. Open `https://music.example.com` — create admin account on first access
2. Music is served from `/mnt/data/media/music/`
3. Navidrome scans every hour automatically (`ND_SCANSCHEDULE=1h`)

## Adding Music

Place music files on the Pi:
```bash
scp -r "Artist - Album/" homelab:/mnt/data/media/music/
```

Organize by `Artist/Album/Track.flac` for best metadata detection.

## Data

| Path                            | Content                                |
|---------------------------------|----------------------------------------|
| `/mnt/data/services/navidrome/` | Database, cache                        |
| `/mnt/data/media/music/`        | Music files (not managed by Navidrome) |

## Restore

```bash
docker stop navidrome
restic restore latest --target / --include /mnt/data/services/navidrome
docker start navidrome
```

Music files in `/mnt/data/media/music/` are backed up daily with the rest of `/mnt/data/media`.
