# ADR-003: Browse Media in Nextcloud via Read-Only External Storage

**Date**: 2026-05-23
**Status**: Accepted. Amended 2026-08-27 — the first con below is resolved,
by the option this ADR guessed at rather than by the cron job it imagined.
**Deciders**: Marc Gavanier

## Context

The media libraries live on the 5TB disk at `/mnt/data/media/{photos,music,videos}`
and are served by dedicated apps: Immich (photos), Navidrome (music), Jellyfin
(video). Each app mounts its folder read-only.

Nextcloud is a convenient file browser (web UI + desktop/mobile clients), and it
would be useful to **browse and download** the raw media files from there — without:

- a second media player (Nextcloud should not duplicate Immich/Jellyfin/Navidrome)
- a second copy of the files (the disk is the single source of truth)
- a second synchronization mechanism (no rsync/clone into Nextcloud's own data)

## Decision

Mount the media folders **read-only** into the Nextcloud container and expose them
through Nextcloud's **External Storage** app (`files_external`) with the *Local*
backend:

```yaml
# compose.yaml — nextcloud service
volumes:
  - ${MEDIA_DIR}/photos:/external/photos:ro
  - ${MEDIA_DIR}/music:/external/music:ro
  - ${MEDIA_DIR}/videos:/external/videos:ro
```

Ansible declares the three mounts idempotently and forces them read-only:
```
occ files_external:create "Photos" local null::null -c datadir=/external/photos
occ files_external:option <id> readonly true
```

They appear as `/Photos`, `/Music`, `/Videos` in every user's file tree.

## Consequences

### Pros
- **Single source of truth**: External Storage is a live view of the same directory
  on disk — zero duplication, zero extra sync.
- **No competing players**: Nextcloud only lists/downloads. Immich/Jellyfin/Navidrome
  remain the players.
- **Read-only safety**: the `:ro` Docker mount physically prevents writes; the
  `readonly` mount option hides write actions in the UI. No risk of corrupting an
  Immich/Jellyfin library from Nextcloud.
- **Works with current permissions**: media files are world-readable, so the
  container (running as root, occ as www-data) can read them with no ownership change.

### Cons
- ~~**Manual scan after additions**~~ — *resolved 2026-08-27.* New files added
  out-of-band were invisible until `occ files:scan --path='admin/files/<Mount>'`
  ran, and this ADR guessed the fix would be a cron job. It became a chore the
  day ADR-033 turned the workstation's `~/Music` into the library itself, and
  the answer turned out to be a mount option Nextcloud already had:
  `filesystem_check_changes: 1` revalidates a directory on direct access, so
  media appears on the next browse. Verified on `/Music` with `/Photos` and
  `/Videos` held back as a control — a folder created outside Nextcloud showed
  up with no scan run. Now set on all three by the deploy role. A manual scan
  remains the tool for a bulk import into a path nobody browses.
- **Preview generation cost**: browsing thousands of photos can trigger thumbnail
  generation (CPU on the Pi). Acceptable for occasional browsing.
- **Read-only by design**: managing files (rename/delete/upload) from Nextcloud is
  not possible. Read/write would require changing file ownership to www-data and
  re-scanning the players — explicitly out of scope.

## Alternatives Considered

- **Nextcloud as the primary media store** (files in Nextcloud's own data dir,
  players reading from there): rejected — couples everything to Nextcloud's storage
  model and its scan/cache, and complicates the players' access.
- **A second synced copy into Nextcloud**: rejected — wastes 100+ GB and needs a
  sync mechanism that can drift.
- **No browsing in Nextcloud at all**: rejected — the user explicitly wants a
  file-browser view of the media from the Nextcloud UI/clients.
