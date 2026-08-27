# ADR-033 — Mount the music library from the workstation instead of copying into it

**Date**: 2026-08-27
**Status**: accepted, and in place since the same day.

## Context

Adding music meant `scp -r "Artist - Album/" homelab:/mnt/data/media/music/`, so
the workstation held a second copy of whatever was being filed and the two
drifted the moment either side changed. The ask was the opposite arrangement:
`~/Music` on the workstation should *be* the folder on the Pi — add a file and it
is on the Pi, delete one and it is gone from the Pi.

Three constraints framed the answer:

- **Nextcloud cannot serve this.** ADR-003 mounts `/Music` into Nextcloud as
  read-only External Storage on purpose: the `:ro` Docker mount physically
  prevents writes, and making it writable would mean changing the media files'
  ownership to `www-data` and re-scanning every player.
- **Nothing new may be exposed.** Traefik's 80/443 are not forwarded; only
  WireGuard and Transmission's peer port are. A file-sharing protocol would need
  a new service, a new port and a new UFW rule for a workstation convenience.
- **Nothing may block.** The Pi is reachable through the tunnel, and it is not
  always up. A mount that hangs a file manager when the Pi is unreachable trades
  one annoyance for a worse one.

## Decision

Mount `homelab:/mnt/data/media/music` on `~/Storage/Music` with **sshfs**, held by
a systemd **user** unit, `~/.config/systemd/user/music-homelab.service`. `~/Music`
is a pre-existing symlink to `~/Storage/Music`, so the XDG music directory
follows without touching it.

Four choices carry the weight, and each answers one of the constraints:

- **No `Requires=` and no `BindsTo=`.** When the Pi is unreachable, sshfs exits
  and `~/Storage/Music` is an ordinary empty local directory. Nothing hangs.
  `Restart=on-failure` with `RestartSec=30s` retries in silence until the Pi
  answers; `StartLimitIntervalSec=0` stops systemd giving up on a long outage.
- **`Environment=SSH_AUTH_SOCK=%t/keyring/ssh`.** The SSH key has a passphrase.
  The gnome-keyring agent's socket lives at a path that is stable across logins,
  unlike the `/tmp/ssh-XXXX` socket an interactive shell inherits, so the unit
  authenticates unattended **without** a passphrase-less key existing anywhere.
  Creating one for this would have been a real downgrade for a convenience.
- **The target is the `~/.ssh/config` alias `homelab`**, never a literal host.
  The LAN address and the vaulted SSH port stay in one place.
- **The mount is excluded from the desktop indexer.** `&MUSIC` resolves to the
  mount, so GNOME tracker would pull 28 GB across sshfs at the next login. Both
  `~/Music` and `~/Storage/Music` are in
  `org.freedesktop.Tracker3.Miner.Files ignored-directories`.

Music that is not yet tagged and filed waits in `~/Storage/To Sort/Music/` — off
the mount, so an unsorted heap never reaches the library or Navidrome's scanner.

## Consequences

### Pros

- **One copy.** The disk on the Pi is the only place the music exists. Nothing to
  synchronise, nothing to drift.
- **No new attack surface.** No service, no port, no firewall rule: it rides the
  SSH that already exists, so it works on the LAN and through the tunnel alike.
- **Navidrome reacts on its own.** Its filesystem watcher sees writes made through
  sshfs — they are ordinary writes on the Pi — and scanned a new folder six
  seconds after the copy landed (measured 2026-08-27).
- **Verified, not assumed.** Write-through and delete-through were both checked
  from an SSH session independent of the mount, and an album's five files matched
  by md5 on both sides.

### Cons

- **Deletion has no undo.** `rm` in `~/Music` removes the file from the Pi at
  once. Restic's daily snapshot keeps it only until the retention window passes.
  This is the requested behaviour, not a side effect, and it is the sharpest
  edge of the arrangement.
- **`~/Storage/To Sort/` is outside the backups.** It lives on the workstation's
  own volume, which Restic does not reach — 3.2 GB in a single copy as of this
  writing.
- **The alias points at a LAN address.** Off-site use depends on the tunnel
  routing that subnet; not verified at the time of writing.
- **Latency is SSH latency.** Fine for filing albums and for streaming through
  Navidrome, which reads from local disk. Playing a 28 GB library *locally* over
  the mount is not what this is for.
- **The mount is workstation state, not Ansible's.** Nothing in this repository
  provisions it; a reinstall of the workstation means recreating the unit by
  hand from this document.

## Alternatives Considered

- **NFSv4** — the fastest option on the LAN, rejected for the cost: a new service
  on the Pi, port 2049 in UFW, and uid/gid mapping to reconcile (the workstation
  user is gid 1000, the music directory is group `gpio`/1003). A large permanent
  concession for a convenience that sshfs delivers.
- **Samba/CIFS** — the same costs as NFS and more moving parts. It would earn its
  place if other clients (a TV, a Windows machine) needed the library; none do.
- **Nextcloud External Storage made writable** — rejected: it contradicts ADR-003
  by design, not by accident, and would require re-owning the media files.
- **Syncthing or a scheduled rsync** — rejected on the terms of the request. Both
  keep a second copy and can drift; the point was to stop having one.

## Appendix — the unit, verbatim

`~/.config/systemd/user/music-homelab.service`. Requires the `sshfs` package;
enable with `systemctl --user enable --now music-homelab.service`.

```ini
[Unit]
Description=Music library from the home lab (sshfs on homelab:/mnt/data/media/music)
Documentation=man:sshfs(1)
After=network-online.target
StartLimitIntervalSec=0

[Service]
Type=simple
Environment=SSH_AUTH_SOCK=%t/keyring/ssh
ExecStart=/usr/bin/sshfs -f homelab:/mnt/data/media/music %h/Storage/Music \
    -o reconnect \
    -o ServerAliveInterval=15 \
    -o ServerAliveCountMax=3 \
    -o ConnectTimeout=10 \
    -o Compression=no \
    -o dir_cache=yes \
    -o idmap=user
ExecStop=/bin/fusermount3 -u %h/Storage/Music
Restart=on-failure
RestartSec=30s

[Install]
WantedBy=default.target
```

The indexer exclusion is not part of the unit:

```bash
gsettings set org.freedesktop.Tracker3.Miner.Files ignored-directories \
  "['po', 'CVS', 'core-dumps', 'lost+found', '$HOME/Music', '$HOME/Storage/Music']"
```
