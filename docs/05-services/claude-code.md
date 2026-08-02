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

## Troubleshooting: "no vault" in the app → Remote Control 401

**Symptom** (seen 2026-07-04): the Claude app/web shows the *Homelab* environment but
sessions never start or the vault seems gone. The vault mount is usually fine — the real
cause is `claude-remote-control.service` crash-looping because the `claude` user's
claude.ai auth expired:

```bash
systemctl status claude-remote-control      # activating (auto-restart), high restart counter
journalctl -u claude-remote-control -n 20   # "Authentication failed (401): Invalid authentication credentials"
```

**Fix — re-login the `claude` user** (interactive, like the first-time setup):

```bash
sudo systemctl stop claude-remote-control && sudo systemctl reset-failed claude-remote-control
sudo -u claude -H /home/claude/.local/bin/claude   # in the TUI: /login, then exit
sudo systemctl start claude-remote-control
journalctl -u claude-remote-control -f             # expect "Connected · vault" then "Ready"
```

Then in the app, pick the environment the service just logged — and remove any stale
duplicate (see the ghost-environments warning above).

## Troubleshooting: both units loop forever → stale FUSE endpoint

**Symptom** (seen 2026-07-31, 54h of downtime): Kuma reports the Pi health check down with
`restart loop: vault-mount.service` and `claude-remote-control.service (activating)`. Unlike
the 401 above, this one **never recovers on its own** — the retry loop cannot converge:

```bash
journalctl -u vault-mount -n 20            # "Fatal error: directory already mounted"
journalctl -u claude-remote-control -n 20  # status=200/CHDIR, "Transport endpoint is not connected"
grep vault /proc/mounts                    # entry present, but the mount answers ENOTCONN
```

**Cause.** A stop that could not unmount left a dead endpoint behind: `fusermount -u` fails
with `EBUSY` while any process sits inside the mount, and Remote Control always does — its
`WorkingDirectory` is the vault. rclone then refuses to mount over the corpse, and Remote
Control fails its `chdir` before `ExecStartPre` even runs. On 2026-07-31 the trigger was
unattended-upgrades restarting the unit at 06:38.

**Fix — clear the dead endpoint** (needs root; `-z` is the point, a plain `-u` will fail again):

```bash
sudo systemctl stop claude-remote-control vault-mount
sudo fusermount -uz /home/claude/vault
grep vault /proc/mounts || echo CLEAN            # must be CLEAN before restarting
sudo systemctl start vault-mount                 # Remote Control is pulled up with it
sudo -u claude sh -c 'cd ~/vault && ls'          # probe the function, not the unit state
```

> This should no longer happen. `vault-mount` now clears a stale endpoint before every start
> and falls back to a lazy unmount on stop, and Remote Control is `PartOf=` the mount so it
> is stopped *first*, releasing the working directory. Verified by killing rclone with
> `SIGKILL` (so `ExecStop` never runs): the mount recovers unattended in ~13 s. If you land
> here anyway, the mount table is the thing to look at first.

## Data

| Path                                                               | Content                                              |
|--------------------------------------------------------------------|------------------------------------------------------|
| `/home/claude/vault`                                               | rclone WebDAV mount of `nextcloud:Notes` (the vault) |
| `/home/claude/.claude`                                             | Claude Code config + credentials                     |
| `/home/claude/.claude/{commands,agents}`                           | Custom commands & subagents (role-mirrored)          |
| `/etc/systemd/system/vault-mount.service`                          | rclone mount of the vault                            |
| `/etc/systemd/system/claude-remote-control.service`                | always-on Remote Control                             |
| `/etc/systemd/system/vault-mount.service.d/10-remote-control.conf` | pulls Remote Control up with the mount (login-gated) |

> **Slow boot is self-healing.** The Remote Control unit *soft-wants* `vault-mount` (not
> `Requires=`) and gates startup on the vault actually being mounted (`ExecStartPre`),
> retrying on failure. The rclone mount waits on Traefik/Nextcloud, so it can be slow at
> boot; the service keeps retrying until it's ready instead of failing permanently (a hard
> `Requires=` dependency-job failure is *not* covered by `Restart=`). See the comments in
> the role's `tasks/main.yml`.
>
> **The two units move together.** Remote Control is `PartOf=vault-mount.service`, so it goes
> down *with* the mount — and, thanks to `After=`, *before* it, which is what releases the
> working directory and lets the unmount succeed. `PartOf` never propagates start, so the
> mount carries a `Wants=` drop-in to bring Remote Control back up. Both directions are
> needed: without the first the mount leaks a dead endpoint, without the second Remote
> Control stays silently stopped after a `stop`/`start` of the mount.

## Restore

Nothing service-specific to restore: the **vault content lives in Nextcloud** (backed up
with the rest of `/mnt/data/services`). Re-running the `claude-code` role rebuilds the user,
sandbox, mounts and services; the only manual step is the one-time `claude` login.

See also: `knowledge/research/obsidian-claude-mobile-workflow.md`,
`knowledge/runbooks/restore-from-backup.md`,
`knowledge/runbooks/cloud-init-hosts-pin.md`.
