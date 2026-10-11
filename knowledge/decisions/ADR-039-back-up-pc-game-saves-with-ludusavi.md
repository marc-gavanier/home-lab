# ADR-039 — Back up the workstation's PC game saves with Ludusavi

**Date**: 2026-10-11
**Status**: accepted, and in place since the same day.
**Related**: ADR-030 (configure, do not write glue), ADR-038 (workstation state kept in an ADR)

## Context

The workstation's Steam games are left out of the storage reorganisation: the
library re-downloads. Their saves do not. Steam Cloud covers some titles, not all,
and nothing covers what a game writes into its Proton prefix or outside Steam's
cloud folder. A dry run found 29 games with saves on this machine, 493 MB, most of
them in Proton prefixes (`compatdata`).

The destination already existed and already reached the Pi:
`~/Storage/Games/Sauvegardes/` is a Nextcloud desktop sync pair with
`/Games/Sauvegardes` on the server, so whatever lands there is in Nextcloud's files
and therefore in the nightly Restic chain. `Sauvegardes/PC/` was empty.

## Decision

[Ludusavi](https://github.com/mtkennerly/ludusavi) backs the saves up into
`~/Storage/Games/Sauvegardes/PC/`, once a day, from a systemd user timer.

- **Ludusavi, not a script (ADR-030).** It reads the PCGamingWiki manifest, which
  knows where thousands of games keep their saves, Proton prefixes and Steam's
  `userdata` included. It finds the Steam client and its libraries by itself.
- **The official release binary, in `~/.local/bin`.** Ludusavi is in neither apt
  nor the Snap Store; Flatpak and Cargo are not installed on the workstation. The
  binary is a single portable file; updates are manual.
- **Nextcloud does the transport.** Ludusavi's own rclone upload is off
  (`cloud.synchronize: false`); its documentation accepts a target folder that
  another tool syncs.
- **Retention is Ludusavi's**: 2 full backups, each with up to 4 differential ones.
  A backup is only written when something changed.
- **The schedule is the documented systemd user timer**, with two additions:
  `Persistent=true`, so a night with the workstation off is caught up at the next
  start, and `RequiresMountsFor=`, so the backup waits for the encrypted `Storage`
  volume.
- **A restore never overwrites live saves.** `ludusavi restore` writes back to the
  original paths; it is tested with a copy of the configuration and a restore
  redirect to an empty folder, never in place.

## Consequences

### Pros

- **Every game is covered the same way**, cloud or not, Proton or native.
- **Off the workstation within minutes**: the first backup (568 files) was on the
  server with identical md5 on both sides.
- **Verified, not assumed.** The timer's service ran unattended and wrote nothing
  when nothing had changed; one game was restored through a redirect and its 14
  files were identical to the live ones.

### Cons

- **Only what the manifest knows.** A game whose save path is missing from
  PCGamingWiki is skipped silently; it needs a custom entry.
- **The first interactive run waits on standard input** (the manifest prompt). Run
  by hand, it needs `< /dev/null`; the service is not affected.
- **Manual updates** of the binary.
- **Workstation state, not Ansible's**: a reinstall means recreating it from this
  document.

## Alternatives Considered

- **A copy script over known paths** — rejected: it is the manifest Ludusavi
  already maintains, rewritten by hand and kept current by nobody (ADR-030).
- **Ludusavi's rclone upload to Nextcloud over WebDAV** — rejected: a second
  transport next to the sync pair that already carries the folder.
- **Flatpak** — rejected: a new packaging system for one program, and its sandbox
  would have to be opened to `~/Storage` and the Proton prefixes.
- **`ludusavi wrap` around each game's launch** — not chosen: a backup right after
  each session, but one launch option per game to maintain; the daily timer covers
  every game at once.

## Appendix — install, configuration and units, verbatim

Install the binary (check the latest release first):

```bash
gh release download v0.31.0 -R mtkennerly/ludusavi -p 'ludusavi-v0.31.0-linux.tar.gz'
tar xzf ludusavi-v0.31.0-linux.tar.gz -C ~/.local/bin ludusavi
ludusavi manifest update < /dev/null
```

`~/.config/ludusavi/config.yaml` is the generated default with four values changed:

```yaml
backup:
  path: /home/marc-gavanier/Storage/Games/Sauvegardes/PC
  retention:
    full: 2
    differential: 4
restore:
  path: /home/marc-gavanier/Storage/Games/Sauvegardes/PC
cloud:
  synchronize: false
```

`~/.config/systemd/user/ludusavi-backup.service`:

```ini
[Unit]
Description=Back up PC game saves with Ludusavi
Documentation=https://github.com/mtkennerly/ludusavi/blob/master/docs/help/backup-automation.md
RequiresMountsFor=%h/Storage

[Service]
Type=oneshot
ExecStart=%h/.local/bin/ludusavi backup --force
```

`~/.config/systemd/user/ludusavi-backup.timer`:

```ini
[Unit]
Description=Daily PC game save backup with Ludusavi

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
```

Enable and check:

```bash
systemctl --user daemon-reload
systemctl --user enable --now ludusavi-backup.timer
systemctl --user list-timers ludusavi-backup.timer
```

Test a restore without touching live saves: copy the configuration, add a restore
redirect to an empty folder, restore one game there and compare.

```bash
mkdir -p /tmp/ludusavi-test/cfg /tmp/ludusavi-test/out
cp ~/.config/ludusavi/{config,manifest,cache}.yaml /tmp/ludusavi-test/cfg/
sed -i "s|^redirects: \[\]|redirects:\n  - kind: restore\n    source: $HOME\n    target: /tmp/ludusavi-test/out|" /tmp/ludusavi-test/cfg/config.yaml
ludusavi --config /tmp/ludusavi-test/cfg --no-manifest-update restore --preview Besiege < /dev/null
ludusavi --config /tmp/ludusavi-test/cfg --no-manifest-update restore --force Besiege < /dev/null
```

The preview must show every path under `/tmp/ludusavi-test/out` before the real
restore is run.
