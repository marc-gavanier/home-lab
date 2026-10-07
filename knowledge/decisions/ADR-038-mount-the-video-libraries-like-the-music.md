# ADR-038 — Mount the video libraries on the workstation like the music

**Date**: 2026-10-07
**Status**: accepted, and in place since the same day.
**Related**: ADR-033 (music over sshfs), ADR-035 (media tree split by writer)

## Context

The workstation's `~/Storage/Videos` held a full copy of the Jellyfin libraries:
694 files, 272 GB. All but eight were proven identical to the Pi's by md5 on both
sides, and the copy was deleted. The ask was then the ADR-033 arrangement for
video: `~/Videos` should show the Pi's libraries, not a second copy of them.

ADR-033's constraints all still hold — nothing new exposed, nothing that blocks
when the Pi is down, no passphrase-less key. Two things differ:

- **The videos live under two roots.** ADR-035 put films and series under
  `/mnt/data/library` (written by Radarr and Sonarr) and home and music videos
  under `/mnt/data/media/videos` (written by the operator). One sshfs mount
  covers one remote directory.
- **Two of the four libraries belong to the importers.** Radarr and Sonarr keep
  an inventory of every file they placed. A rename or delete made by hand behind
  their back leaves them tracking files that no longer exist.

## Decision

Mount each Jellyfin library on its own subfolder of `~/Storage/Videos`, with one
templated systemd user unit, `videos-homelab@.service`, and one small environment
file per instance in `~/.config/videos-homelab/`:

| Instance | Local (`~/Storage/Videos/`) | Pi                                    | Mode       |
|----------|-----------------------------|---------------------------------------|------------|
| `films`  | `Films`                     | `/mnt/data/library/movies`            | read-only  |
| `series` | `Séries`                    | `/mnt/data/library/shows`             | read-only  |
| `clips`  | `Clips`                     | `/mnt/data/media/videos/music-videos` | read-write |
| `perso`  | `Perso`                     | `/mnt/data/media/videos/home-videos`  | read-write |

- **Read-only where an importer writes.** `-o ro` on films and series keeps the
  operator from desynchronising Radarr and Sonarr; changes there go through them.
- **Read-write where only the operator writes**, exactly as for the music.
- **Everything else is ADR-033's unit unchanged**: no `Requires=`/`BindsTo=`, the
  keyring agent socket, the `homelab` alias, `Restart=on-failure`.
- **The mounts are excluded from the desktop indexer**, like the music: Tracker
  would otherwise read 270 GB over sshfs.

## Consequences

### Pros

- **One copy.** The workstation holds no video at all.
- **No new attack surface**, for the same reason as ADR-033.
- **Verified, not assumed.** A write on `Films` fails with "Read-only file
  system"; a file written to `Perso` was read back and its deletion confirmed from
  an SSH session independent of the mount.

### Cons

- **Deletion has no undo in `Clips` and `Perso`**, as in `~/Music`.
- **Films and series are in a single copy.** They are outside Restic by ADR-035's
  design; losing them costs a re-download.
- **Playing over the mount is SSH-bound.** Browsing and filing are fine; watching
  goes through Jellyfin.
- **Workstation state, not Ansible's**: a reinstall means recreating the units
  from this document.

## Alternatives Considered

- **One mount of `/mnt/data`** — rejected: it would expose the whole data volume,
  downloads and service data included, for the sake of one unit.
- **Four separate unit files** — rejected: four copies of the same unit to keep
  in step; the template carries only what differs.
- **Read-write everywhere** — rejected: it trades a guard-rail for a convenience
  the importers already provide.

## Appendix — the unit and its instances, verbatim

`~/.config/systemd/user/videos-homelab@.service`. Requires the `sshfs` package;
enable with `systemctl --user enable --now videos-homelab@{films,series,clips,perso}.service`.

```ini
[Unit]
Description=Video library %i from the home lab (sshfs)
Documentation=man:sshfs(1)
After=network-online.target
StartLimitIntervalSec=0

[Service]
Type=simple
EnvironmentFile=%h/.config/videos-homelab/%i.env
Environment=SSH_AUTH_SOCK=%t/keyring/ssh
ExecStart=/usr/bin/sshfs -f homelab:${REMOTE} %h/Storage/Videos/${LOCAL} \
    -o reconnect \
    -o ServerAliveInterval=15 \
    -o ServerAliveCountMax=3 \
    -o ConnectTimeout=10 \
    -o Compression=no \
    -o dir_cache=yes \
    -o idmap=user \
    $MODE_OPTS
ExecStop=/bin/fusermount3 -u %h/Storage/Videos/${LOCAL}
Restart=on-failure
RestartSec=30s

[Install]
WantedBy=default.target
```

`$MODE_OPTS` is unbraced on purpose: systemd splits it into `-o` and `ro`, and
drops it entirely when empty.

`~/.config/videos-homelab/films.env` (the other three follow the table above;
`clips` and `perso` set `MODE_OPTS=` empty):

```bash
REMOTE=/mnt/data/library/movies
LOCAL=Films
MODE_OPTS=-o ro
```

The local mount points must exist: `mkdir -p ~/Storage/Videos/{Films,Séries,Clips,Perso}`.

The indexer exclusion, with the music entries kept:

```bash
gsettings set org.freedesktop.Tracker3.Miner.Files ignored-directories \
  "['po', 'CVS', 'core-dumps', 'lost+found', '$HOME/Music', '$HOME/Storage/Music', '$HOME/Videos', '$HOME/Storage/Videos']"
```
