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
3. Navidrome notices new files two different ways, and it is worth knowing which
   one you are waiting for:

   - a **filesystem watcher** fires a scan of the changed folder within seconds.
     Measured 2026-08-27: files landed at 10:27:13, `Watcher: Triggering scan`
     at 10:27:19, folder processed in 280 ms.
   - a **periodic scan** every hour (`ND_SCANNER_SCHEDULE=1h`) catches whatever
     the watcher missed.

   The variable name matters and the wrong one is silent: `ND_SCANSCHEDULE` was set
   here for months, 0.63.2 reads `Scanner.Schedule`, and an unknown `ND_*` warns about
   nothing — so the container logged `Periodic scan is DISABLED` on every start while
   this page said the opposite (#178). Check the boot log, never the variable:
   `docker logs navidrome | grep -i "periodic scan"`.

## Adding Music

The workstation mounts the library over sshfs, so `~/Music` **is** the folder on
the Pi (ADR-033). Copying an album into it writes straight to
`/mnt/data/media/music/`, deleting from it deletes on the Pi, and the watcher
picks the change up within seconds. There is no synchronisation to wait for and
no second copy to keep aligned.

```bash
cp -r "Album/" ~/Music/Artist/
```

From a machine without the mount, `scp` still works:

```bash
scp -r "Artist - Album/" homelab:/mnt/data/media/music/
```

Two notes on beating Navidrome's metadata handling rather than fighting it:

- **Tags decide, not folder names.** A folder called `Decimia/` whose files are
  tagged `artist=excitingopenmics6494` appears under that pseudonym, not under
  Decimia. Fix the tags first; `mid3v2` (shipped with python3-mutagen) writes
  ID3 in place and leaves the frames it does not touch alone, including embedded
  cover art. `exiftool` reads MP3 but cannot write it.
- **Organise as `Artist/Album/Track.ext`**, and drop a `cover.jpg` in the album
  folder — Navidrome prefers it to the per-track embedded art, which is often
  inconsistent across an album.

## /tmp Is Not Optional

Navidrome reads tags through a WASM module that unpacks itself into `/tmp` the
first time it has a new file to parse. Under a read-only root filesystem without
a `/tmp` tmpfs, that unpacking fails — and it fails *once and for all* for the
life of the container:

```
gotaglib: Error reading metadata from file. Skipping
error="init module: get runtime once: create directory /tmp/go-taglib-wasm:
       mkdir /tmp/go-taglib-wasm: read-only file system"
```

Every symptom above the failure looks healthy. The scan completes, the container
stays green, the log line reads `Completed processing folder audioCount=5 ...
tracksImported=0`, and **nothing enters the library**. Between 2026-07-27 (#32,
read-only rootfs) and #265, no track could be imported by any route.

Diagnose it by the database, never by the container's health:

```bash
docker logs navidrome --since 1h 2>&1 | grep gotaglib
docker exec navidrome sqlite3 'file:/data/navidrome.db?mode=ro' \
  "select count(*) from media_file where path like '%<album folder>%';"
```

A folder that scans with `audioCount=N` and `tracksImported=0` is this failure,
not an empty folder.

### Fixing /tmp does not un-stick what the outage touched

The broken scan still recorded the folder in the `folder` table with the
timestamp it had at the time. A later incremental scan compares the two, finds
them equal, and skips a folder from which nothing was ever imported — so the
container is fixed and the album still does not appear. Bump the folder's
timestamp and the watcher does the rest:

```bash
touch "~/Music/Artist/Album"
```

Measured 2026-08-27: `tracksImported=5` a second after the touch, on the folder
that had reported `tracksImported=0` an hour earlier. A full scan fixes it too,
at the price of a pass over the whole library. Only folders written during the
outage are affected — list them with:

```bash
docker exec navidrome sqlite3 'file:/data/navidrome.db?mode=ro' \
  "select path, name, num_audio_files from folder where updated_at > '<outage start>';"
```

## Data

| Path                            | Content                                |
|---------------------------------|----------------------------------------|
| `/mnt/data/services/navidrome/` | Database, cache                        |
| `/mnt/data/media/music/`        | Music files (not managed by Navidrome) |
| `~/Music` on the workstation    | The same folder, over sshfs (ADR-033)  |

## Restore

```bash
cd /opt/homelab   # `compose down`, never `docker stop`: a stopped container
                  # is resurrected by the heal timer within 2 min (ADR-007)
docker compose down navidrome
restic restore latest --target / --include /mnt/data/services/navidrome
docker compose up -d navidrome
```

Music files in `/mnt/data/media/music/` are backed up daily with the rest of `/mnt/data/media`.
