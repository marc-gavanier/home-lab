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

## Custom Commands & Subagents

Sessions (mobile/web/SSH) expose project-specific **slash commands** and a **subagent** for
capturing and curating conference notes in the vault. They are **version-controlled in the
role** (`ansible/roles/claude-code/files/{commands,agents}/`) and mirrored into the `claude`
user's `~/.claude` by the Ansible role — *authoritatively*: a file removed from the repo is
purged from the Pi, so the host never drifts from git. New sessions pick changes up with no
restart.

| Command / agent | Purpose                                                              |
|-----------------|---------------------------------------------------------------------|
| `/conf-start`   | Start a conference day's raw note in `Inbox/` from the template      |
| `/forum-start`  | Start an open-space / forum day (no predefined programme)            |
| `/talk-add`     | Add a section for a new talk to the current raw note                 |
| `/session-add`  | Add a section for a new open-space session to the current raw note   |
| `/conf-curate`  | Run the guided post-conference curation cycle (full CODE)            |
| `note-fidelity` | Subagent: audit a `reference` note for strict fidelity to its source |

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
| `/home/claude/.claude/{commands,agents}`            | Custom commands & subagents (role-mirrored)          |
| `/etc/systemd/system/vault-mount.service`           | rclone mount of the vault                            |
| `/etc/systemd/system/claude-remote-control.service` | always-on Remote Control                             |

> **Slow boot is self-healing.** The Remote Control unit *soft-wants* `vault-mount` (not
> `Requires=`) and gates startup on the vault actually being mounted (`ExecStartPre`),
> retrying on failure. The rclone mount waits on Traefik/Nextcloud, so it can be slow at
> boot; the service keeps retrying until it's ready instead of failing permanently (a hard
> `Requires=` dependency-job failure is *not* covered by `Restart=`). See the comments in
> the role's `tasks/main.yml`.

## Restore

Nothing service-specific to restore: the **vault content lives in Nextcloud** (backed up
with the rest of `/mnt/data/services`). Re-running the `claude-code` role rebuilds the user,
sandbox, mounts and services; the only manual step is the one-time `claude` login.

See also: `knowledge/research/obsidian-claude-mobile-workflow.md`,
`knowledge/runbooks/restore-from-backup.md`,
`knowledge/runbooks/cloud-init-hosts-pin.md`.
