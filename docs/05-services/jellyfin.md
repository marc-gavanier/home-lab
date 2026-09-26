# Jellyfin

Video streaming server — a personal Netflix for films, series and home videos.

## At a glance

| | |
|---|---|
| URL | `https://videos.example.com` |
| Clients | browser, [Jellyfin apps](https://jellyfin.org/downloads/) (mobile, Android TV, Fire TV, Roku…) |
| Backup | config and home/music videos backed up; films and series not (ADR-035) |

| Path                                   | Content                              |
|----------------------------------------|--------------------------------------|
| `/mnt/data/services/jellyfin/config/`  | Jellyfin configuration and metadata  |
| `/mnt/data/services/jellyfin/cache/`   | Transcoding cache                    |
| `/mnt/data/library/movies/`            | Films — importer-writable (ADR-035)  |
| `/mnt/data/library/shows/`             | Series — importer-writable (ADR-035) |
| `/mnt/data/media/videos/home-videos/`  | Personal footage — operator only     |
| `/mnt/data/media/videos/music-videos/` | Music videos — operator only         |

## How it works

- The four host sources above mount into one `/media/videos/...` tree in the container.
- Films and series are torrent-sourced and kept until watched: losing them costs a re-download.
- Transcoding is software only: the container gets no video device, though the host has one
  (`/dev/video19`, `h264_v4l2m2m` / `hevc_v4l2m2m` in Jellyfin's ffmpeg). Prefer direct play; cap
  transcodes at 720p. Passing the device through would be an experiment, not a fix: the H.264
  encoder is quality-limited and HEVC decodes only.

## Common tasks

First setup: open `https://videos.example.com`, follow the wizard, create the admin account, add
libraries pointing to `/media/videos`.

Add a film, then scan from the dashboard (or wait for the periodic scan):

```bash
scp movie.mkv homelab:/mnt/data/library/movies/
```

Restore the config. Use `compose down`, never `docker stop`: the heal timer restarts a non-zero
exit within 2 min (ADR-007).

```bash
cd /opt/homelab
docker compose down jellyfin
restic restore latest --target / --include /mnt/data/services/jellyfin
docker compose up -d jellyfin
```
