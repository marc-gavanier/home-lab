# Claude Code (on the Pi)

AI agent on the Pi that manages the Obsidian notes vault, driven from the Claude mobile app or
`claude.ai/code`. Design: [ADR-004](../../knowledge/decisions/ADR-004-claude-code-on-the-pi.md).

## At a glance

| Item         | Value                                                                                  |
|--------------|----------------------------------------------------------------------------------------|
| Access       | Remote Control (outbound HTTPS only) — no URL, no inbound port                         |
| User         | dedicated unprivileged `claude`                                                        |
| Sandbox      | `~claude/.claude/settings.json`: writes confined to the vault, network to one domain, reads denied on the account's credentials file and the secrets directory; there is no `/sandbox` on the host |
| Ansible role | `claude-code`                                                                          |
| Backup       | vault content lives in Nextcloud; `~claude/.claude` is on the SD card                  |

| Path                                                               | Content                                              |
|--------------------------------------------------------------------|------------------------------------------------------|
| `/home/claude/vault`                                               | rclone WebDAV mount of `nextcloud:Notes` (the vault) |
| `/home/claude/.claude`                                             | Claude Code config + credentials                     |
| `/home/claude/.claude/{commands,agents}`                           | Custom commands & subagents (role-mirrored)          |
| `/etc/systemd/system/vault-mount.service`                          | rclone mount of the vault                            |
| `/etc/systemd/system/claude-remote-control.service`                | always-on Remote Control                             |
| `/etc/systemd/system/vault-mount.service.d/10-remote-control.conf` | pulls Remote Control up with the mount (login-gated) |

## How it works

- Installed by Anthropic's installer as the `claude` user (no sudo, no docker group); it updates
  itself and nothing pins or records the version. `autoUpdates=false` does not apply to this
  install type. Accepted.
- It follows the vault's own `CLAUDE.md`. Writes go through WebDAV, so Nextcloud indexes them
  at once (no `occ` scan).
- `claude-remote-control` soft-wants `vault-mount` and gates its start on the vault being
  mounted (`ExecStartPre`), retrying until it is. A slow boot therefore heals itself.
- The two units move together: Remote Control is `PartOf=vault-mount.service` and stops
  before the mount, releasing its working directory; a `Wants=` drop-in on the mount starts
  it again. `vault-mount` clears a stale endpoint before every start and lazy-unmounts on
  stop.

### Custom commands and subagents

Versioned in `ansible/roles/claude-code/files/{commands,agents}/` and mirrored
authoritatively into `~claude/.claude` (a file removed from the repo is removed from the Pi).
New sessions pick changes up without a restart.

| Command / agent | Purpose                                                              |
|-----------------|----------------------------------------------------------------------|
| `/conf-start`   | Start a conference day's raw note in `Inbox/` from the template      |
| `/forum-start`  | Start an open-space / forum day (no predefined programme)            |
| `/talk-add`     | Add a section for a new talk to the current raw note                 |
| `/session-add`  | Add a section for a new open-space session to the current raw note   |
| `/conf-curate`  | Run the guided post-conference curation cycle (full CODE)            |
| `note-fidelity` | Subagent: audit a `reference` note for strict fidelity to its source |

## Client setup

All three drive the same agent:

- **Web**: `claude.ai/code` → the *Homelab* environment.
- **Mobile**: the Claude app → the *Homelab* environment.
- **SSH**: `ssh homelab`, then `sudo -u claude -H bash -lc 'cd ~/vault && claude'`.

Ghost environments: a re-auth can leave a stale duplicate "Homelab" where sessions spin
forever. Use the environment the running `claude-remote-control` service logs, and remove the
other in the app.

## First Steps (one-time, manual)

Manual on purpose: Ansible must not silently enable remote access. The result persists in
`~claude/.claude`.

1. Authenticate: `sudo -u claude -H /home/claude/.local/bin/claude`, then `/login` (claude.ai)
   and exit.
2. Trust the vault and enable Remote Control:
   `sudo -u claude -H bash -lc 'cd ~/vault && /home/claude/.local/bin/claude remote-control --name Homelab'`
   → accept "Do you trust this folder?", answer `y` to "Enable Remote Control?", wait for
   "Connected", then Ctrl+C.
3. Re-run the `claude-code` Ansible role to start the systemd services.

## Daily Feed Digest

The `claude` user runs one scheduled job: it reads everything unread in
[Miniflux](miniflux.md), has Claude summarise it, writes a note into the vault, and marks the
entries read ([ADR-027](../../knowledge/decisions/ADR-027-feed-digest.md)). Operating it,
replaying a digest and the failure tree:
[feed-digest runbook](../../knowledge/runbooks/feed-digest.md).

| Unit / file                                  | Role                                          |
|----------------------------------------------|-----------------------------------------------|
| `homelab-feed-digest.timer`                  | daily at 06:30, `Persistent=true`             |
| `homelab-feed-digest.service`                | oneshot, `User=claude`, `TimeoutStartSec=900` |
| `~claude/.local/share/feed-digest/digest.sh` | Miniflux API → `claude -p` → vault → mark read |
| `~claude/.local/share/feed-digest/prompt.md` | generic English default, Ansible-owned        |
| `<vault>/<folder>/prompt.local.md`           | personal override — **wins when present**     |
| `/mnt/data/secrets/claude/miniflux_api_key`  | 0400, claude-owned                            |

- The note lands in `<folder>/YYYY-MM-DD - <suffix>.md` (not `Inbox/`), with two sections:
  what changed, and zero to three post angles.
- `claude -p` uses the claude.ai session credentials in `~claude/.claude`: no API key or OAuth
  token for Claude.
- The script writes the note and its frontmatter; the model only emits markdown on stdout.
- At most 400 entries per run; the rest stay unread and the carried-over count appears in the
  note and the Kuma message.
- `TimeoutStartSec=900` is the only bound: under `Type=oneshot` systemd ignores
  `RuntimeMaxSec`, and the start timeout defaults to infinity.

Configuration:

| File                               | Encrypted | Published | Holds                                     |
|------------------------------------|-----------|-----------|-------------------------------------------|
| `host_vars/<host>/local.yml`       | yes       | no        | the Miniflux API key, the Kuma push URL   |
| `host_vars/<host>/private.yml`     | **no**    | no        | folder, note suffix, tags, title, wording |
| `<vault>/<folder>/prompt.local.md` | no        | no        | the personal prompt                       |

Manual steps (neither API supports them):

1. **Miniflux API key** — *Settings → API Keys → Create*, then into `miniflux_api_key` in the
   vaulted `local.yml`.
2. **Kuma push monitor** — type *Push*, then its URL into `feed_digest_kuma_push_url`.

## Common tasks

```sh
systemctl list-timers homelab-feed-digest.timer   # next run
systemctl start homelab-feed-digest.service       # run now
journalctl -u homelab-feed-digest.service -n 50   # what happened
sudo -u claude tail -30 ~claude/.local/share/feed-digest/digest.log
```

Fix a bad digest in the prompt, never in the note:

- **Override, in the vault** — `<folder>/prompt.local.md`, applies from the next run, no
  deploy, editable from Obsidian. Anything personal goes here: this repository is public.
- **Default, in the repo** — `feed-digest-prompt.md.j2`, generic and in English. Structural
  fixes only.

The override wins silently; the journal logs which prompt each run used. Re-running is not
free: entries are marked read, so replaying needs the API call in the runbook.

**Restore:** nothing service-specific. Re-running the `claude-code` role rebuilds the user,
sandbox, mounts and services; then redo the [First Steps](#first-steps-one-time-manual).

## Troubleshooting

### "No vault" in the app → Remote Control 401

Symptom: the app shows *Homelab* but sessions never start or the vault seems gone. Cause:
the `claude` user's claude.ai auth expired and `claude-remote-control` crash-loops.

```bash
systemctl status claude-remote-control      # activating (auto-restart), high restart counter
journalctl -u claude-remote-control -n 20   # "Authentication failed (401): Invalid authentication credentials"
```

Fix — re-login the `claude` user:

```bash
sudo systemctl stop claude-remote-control && sudo systemctl reset-failed claude-remote-control
sudo -u claude -H /home/claude/.local/bin/claude   # in the TUI: /login, then exit
sudo systemctl start claude-remote-control
journalctl -u claude-remote-control -f             # expect "Connected · vault" then "Ready"
```

Then pick the environment the service just logged, and remove any ghost.

### Both units loop forever → stale FUSE endpoint

Symptom: Kuma reports the Pi health check down with `restart loop: vault-mount.service` and
`claude-remote-control.service (activating)`. It does not recover on its own.

```bash
journalctl -u vault-mount -n 20            # "Fatal error: directory already mounted"
journalctl -u claude-remote-control -n 20  # status=200/CHDIR, "Transport endpoint is not connected"
grep vault /proc/mounts                    # entry present, but the mount answers ENOTCONN
```

Cause: a stop could not unmount (`EBUSY`) and left a dead endpoint; rclone refuses to mount
over it. The units should now prevent this; if you land here, look at the mount table first.

Fix — `-z` is required, a plain `-u` fails again:

```bash
sudo systemctl stop claude-remote-control vault-mount
sudo fusermount -uz /home/claude/vault
grep vault /proc/mounts || echo CLEAN            # must be CLEAN before restarting
sudo systemctl start vault-mount                 # Remote Control is pulled up with it
sudo -u claude sh -c 'cd ~/vault && ls'          # probe the function, not the unit state
```

See also: `knowledge/research/obsidian-claude-mobile-workflow.md`,
`knowledge/runbooks/restore-from-backup.md`,
`knowledge/runbooks/cloud-init-hosts-pin.md`,
`knowledge/runbooks/feed-digest.md`.
