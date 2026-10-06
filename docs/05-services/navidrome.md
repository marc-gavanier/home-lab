# Navidrome

Music streaming server with a Subsonic API. It serves `/mnt/data/media/music/`,
which the workstation mounts as `~/Music`.

## At a glance

| Item     | Value                                                                           |
|----------|---------------------------------------------------------------------------------|
| URL      | `https://music.example.com`                                                     |
| Music    | `/mnt/data/media/music/` = `~/Music` over sshfs ([ADR-033](../../knowledge/decisions/ADR-033-mount-the-music-library-not-copy-into-it.md)) |
| App data | `/mnt/data/services/navidrome/` (database, cache)                               |
| Backup   | Restic, daily (app data, and music with `/mnt/data/media`)                      |
| Clients  | Android: [Subtracks](https://play.google.com/store/apps/details?id=com.subtracks), [Ultrasonic](https://play.google.com/store/apps/details?id=org.moire.ultrasonic). iOS: [play:Sub](https://apps.apple.com/app/play-sub-music-streamer/id955329386), [Amperfy](https://apps.apple.com/app/amperfy-music/id1530145038) |

## How it works

- New files: a watcher scans the changed folder within seconds; a scan every hour
  (`ND_SCANNER_SCHEDULE=1h`) catches misses. A misspelled `ND_*` is ignored
  silently, so check `docker logs navidrome | grep -i "periodic scan"`.
- Tags decide, not folder names. Fix them with `mid3v2` (keeps cover art);
  `exiftool` cannot write MP3.
- Layout: `Artist/Album/Track.ext`, plus `cover.jpg` in the album folder.
- A vanished file keeps its entry (a moved track keeps its play counts).
  `ND_SCANNER_PURGEMISSING=full` purges them on full scans only.
- `media_file` counts dead entries too: filter on `missing = 0`.
- The `/tmp` tmpfs is required: tag reading unpacks a WASM module there.

## Common tasks

Add music (writes straight to the Pi). With the sshfs mount:

```bash
cp -r "Album/" ~/Music/Artist/
```

From a machine without the mount:

```bash
scp -r "Artist - Album/" homelab:/mnt/data/media/music/
```

Purge ghost entries. The first full scan deletes every missing entry with its play
counts, irreversibly. Count them first:

```bash
docker exec navidrome sqlite3 'file:/data/navidrome.db?mode=ro' \
  "select count(*) from media_file where missing = 1;"
```

Stop here if the count is not what you expect. Then:

```bash
docker exec navidrome navidrome scan --full
```

Restore. Use `compose down`, never `docker stop`: the heal timer restarts a
container that exited non-zero (ADR-007).

```bash
cd /opt/homelab
docker compose down navidrome
restic restore latest --target / --include /mnt/data/services/navidrome
docker compose up -d navidrome
```

## Troubleshooting

**Album header shows more tracks than the list.** A rename left a ghost entry.
Purge it.

**Scan ends with `audioCount=5 ... tracksImported=0`, container green.** `/tmp`
is not writable. Restore its tmpfs. The log shows:

```
gotaglib: Error reading metadata from file. Skipping
error="init module: get runtime once: create directory /tmp/go-taglib-wasm:
       mkdir /tmp/go-taglib-wasm: read-only file system"
```

Check the database, not the container health:

```bash
docker logs navidrome --since 1h 2>&1 | grep gotaglib
docker exec navidrome sqlite3 'file:/data/navidrome.db?mode=ro' \
  "select count(*) from media_file where path like '%<album folder>%';"
```

**Album still missing after `/tmp` is fixed.** Incremental scans skip the folder
because its timestamp did not change. Touch it (or run a full scan):

```bash
touch ~/Music/"Artist/Album"
docker exec navidrome sqlite3 'file:/data/navidrome.db?mode=ro' \
  "select path, name, num_audio_files from folder where updated_at > '<outage start>';"
```

The query lists the folders written while `/tmp` was broken.
