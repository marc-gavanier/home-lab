# ADR-041 — Mount the photo library on the workstation like the music

**Date**: 2026-10-25
**Status**: accepted, and in place since the same day.
**Related**: ADR-033 (music over sshfs), ADR-038 (video libraries over sshfs)

## Context

Moving off Google Drive left a photo to file in Immich. Immich already reads
`/mnt/data/media/photos` as its external library "Photos" (mounted read-only into
`immich-server`, rescanned nightly, inside Restic through `/mnt/data/media`), and
the operator owns that directory on the Pi. What was missing was a way to file a
photo there from the workstation without an Immich API key or a browser upload.

## Decision

Mount `/mnt/data/media/photos` on `~/Storage/Pictures/Photos` with a systemd user
unit, `photos-homelab.service`, identical to ADR-033's music unit apart from the
two paths:

- **Read-write**: only the operator writes there; Immich reads it read-only.
- **A subfolder of `~/Storage/Pictures`**, not the whole of it: wallpapers,
  screenshots and avatars stay local and outside Immich.
- **Excluded from the desktop indexer**, like the music and the videos.
- **Filing rule**: one folder per event, named `YYYY-MM-DD - Event`, as the rest
  of the library. Immich picks a new file up at the nightly scan, or at once with
  *Administration → External libraries → Scan*.

## Consequences

### Pros

- **Filing a photo is a file move**, with no key, token or browser involved.
- **No new attack surface**, for the same reason as ADR-033.
- **Verified, not assumed.** A photo copied through the mount was read back by
  md5 from an SSH session independent of the mount, its date preserved.

### Cons

- **Deletion has no undo on the workstation**, as in `~/Music`; Restic is the
  only way back.
- **A photo without EXIF is dated by its file time**, so a copy must keep it
  (`cp -p`, `mv`).
- **Workstation state, not Ansible's**: a reinstall means recreating the unit
  from this document.

## Alternatives Considered

- **Immich API with a key** — rejected: one more secret to hold for an occasional
  upload.
- **Browser upload** — rejected: lands in Immich's managed upload area, apart from
  the event folders, and needs a browser session each time.
- **Extending the `videos-homelab@` template** — rejected: its `~/Storage/Videos/`
  prefix is fixed; a second copy of the music unit is simpler.

## Appendix — the unit, verbatim

`~/.config/systemd/user/photos-homelab.service`. Requires the `sshfs` package;
create the mount point with `mkdir -p ~/Storage/Pictures/Photos`, then enable with
`systemctl --user enable --now photos-homelab.service`.

```ini
[Unit]
Description=Photo library from the home lab (sshfs on homelab:/mnt/data/media/photos)
Documentation=man:sshfs(1)
After=network-online.target
StartLimitIntervalSec=0

[Service]
Type=simple
Environment=SSH_AUTH_SOCK=%t/keyring/ssh
ExecStart=/usr/bin/sshfs -f homelab:/mnt/data/media/photos %h/Storage/Pictures/Photos \
    -o reconnect \
    -o ServerAliveInterval=15 \
    -o ServerAliveCountMax=3 \
    -o ConnectTimeout=10 \
    -o Compression=no \
    -o dir_cache=yes \
    -o idmap=user
ExecStop=/bin/fusermount3 -u %h/Storage/Pictures/Photos
Restart=on-failure
RestartSec=30s

[Install]
WantedBy=default.target
```

The indexer exclusion, with the music and video entries kept:

```bash
gsettings set org.freedesktop.Tracker3.Miner.Files ignored-directories \
  "['po', 'CVS', 'core-dumps', 'lost+found', '$HOME/Music', '$HOME/Storage/Music', '$HOME/Videos', '$HOME/Storage/Videos', '$HOME/Pictures/Photos', '$HOME/Storage/Pictures/Photos']"
```
