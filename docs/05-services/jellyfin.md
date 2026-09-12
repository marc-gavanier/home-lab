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
scp movie.mkv homelab:/mnt/data/library/movies/
```

Jellyfin scans libraries periodically or you can trigger a manual scan from the dashboard.

## Data

| Path                                   | Content                              |
|----------------------------------------|--------------------------------------|
| `/mnt/data/services/jellyfin/config/`  | Jellyfin configuration and metadata  |
| `/mnt/data/services/jellyfin/cache/`   | Transcoding cache                    |
| `/mnt/data/library/movies/`            | Films — importer-writable (ADR-035)  |
| `/mnt/data/library/shows/`             | Series — importer-writable (ADR-035) |
| `/mnt/data/media/videos/home-videos/`  | Personal footage — operator only     |
| `/mnt/data/media/videos/music-videos/` | Music videos — operator only         |

## Performance Note

Jellyfin transcodes in software here, and that is a configuration choice rather
than a hardware limit — the sentence that used to stand here said the Pi 4 has
no hardware transcoding support, and that is not what the board reports.
Measured on 2026-09-12: the host exposes `/dev/video19`, `bcm2835_codec` and
`rpivid_hevc` are loaded in the running kernel, and Jellyfin's own ffmpeg
carries the `h264_v4l2m2m` and `hevc_v4l2m2m` encoder and decoder wrappers. What
is missing is the device: the container is passed none, so ffmpeg has nothing to
open.

The practical advice is unchanged. Use direct play whenever possible (clients
that support your video formats natively), and limit to 720p when transcoding is
needed — the Pi 4's hardware H.264 encoder is quality-limited and its HEVC block
decodes only, so passing the device through would not make 1080p transcoding a
solved problem. It would be an experiment worth measuring, not a fix worth
assuming.

## Restore

```bash
cd /opt/homelab   # `compose down`, never `docker stop`: a stopped container
                  # is resurrected by the heal timer within 2 min (ADR-007)
docker compose down jellyfin
restic restore latest --target / --include /mnt/data/services/jellyfin
docker compose up -d jellyfin
```

Films and series live under `/mnt/data/library/` and are backed up daily, listed
subdirectory by subdirectory in the restic source so that `library/downloads/`
stays out of the backup structurally (ADR-035). Home videos and music videos are
backed up with the rest of `/mnt/data/media`.

The four libraries Jellyfin was configured with are unchanged: it mounts four
host sources into the same `/media/videos/...` container tree, so nothing inside
Jellyfin had to be re-pointed.
