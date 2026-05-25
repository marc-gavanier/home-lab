# Claude Code (on the Pi)

AI agent running on the Pi that manages the Obsidian notes vault — drivable from the Claude
mobile app. Hardened design: see [ADR-004](../../knowledge/decisions/ADR-004-claude-code-on-the-pi.md).

## Access

- **No URL / no inbound port** — exposed via **Remote Control** (outbound HTTPS only).
- Drive it from the **Claude mobile app** or **`claude.ai/code`** (any browser).
- Runs as a dedicated unprivileged user `claude`, confined by `/sandbox` to the notes vault.

## What It Does

- Reads/creates/organizes the notes vault (`~/vault`, an rclone WebDAV mount of
  `nextcloud:Notes`) following the vault's own `CLAUDE.md`.
- Writes go through Nextcloud (WebDAV), so changes are indexed immediately (no `occ` scan);
  Nextcloud clients update live via notify_push, Obsidian on its next Remotely Save sync.

## Client Setup

Sessions can be started from the web, the mobile app, or SSH — all drive the same agent on
the Pi:

- **Web**: `claude.ai/code` → the *Homelab* environment.
- **Mobile**: the Claude app → the *Homelab* environment.
- **SSH**: `ssh homelab`, then `sudo -u claude -H bash -lc 'cd ~/vault && claude'`.

> **Watch for ghost environments.** A re-auth can leave a stale duplicate "Homelab"
> environment with no live host; a session created on the ghost spins forever (no worker
> spawns). The live one is the environment the running `claude-remote-control` service logs
> — use it and remove the ghost in the app. Details in the research doc.

## First Steps (one-time, manual)

1. Authenticate the `claude` user (claude.ai), then trust the vault + enable Remote Control —
   exact commands in the header of `ansible/roles/claude-code/tasks/main.yml`.
2. Re-run the `claude-code` Ansible role to start the systemd services.

## Data

| Path                                                | Content                                              |
|-----------------------------------------------------|------------------------------------------------------|
| `/home/claude/vault`                                | rclone WebDAV mount of `nextcloud:Notes` (the vault) |
| `/home/claude/.claude`                              | Claude Code config + credentials                     |
| `/etc/systemd/system/vault-mount.service`           | rclone mount of the vault                            |
| `/etc/systemd/system/claude-remote-control.service` | always-on Remote Control                             |

## Restore

Nothing service-specific to restore: the **vault content lives in Nextcloud** (backed up
with the rest of `/mnt/data/services`). Re-running the `claude-code` role rebuilds the user,
sandbox, mounts and services; the only manual step is the one-time `claude` login.

See also: `knowledge/research/obsidian-claude-mobile-workflow.md`,
`knowledge/runbooks/restore-from-backup.md`.
