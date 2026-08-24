# Claude Code (on the Pi)

AI agent running on the Pi that manages the Obsidian notes vault — drivable from the Claude
mobile app. Hardened design: see [ADR-004](../../knowledge/decisions/ADR-004-claude-code-on-the-pi.md).

## Access

- **No URL / no inbound port** — exposed via **Remote Control** (outbound HTTPS only).
- Drive it from the **Claude mobile app** or **`claude.ai/code`** (any browser).
- Runs as a dedicated unprivileged user `claude`, under Claude Code's own sandbox
  (`~claude/.claude/settings.json`). **What that sandbox constrains is writes and
  network, plus an explicit read deny list**: writes are confined to the vault,
  outbound traffic to a single domain, and reads are unrestricted apart from the
  denied paths — the account's own credentials file and the secrets directory
  (widened from a single file on 2026-08-24, #219). There is no `/sandbox` on the
  host — this line used to name one.

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

## Daily Feed Digest

The same `claude` user runs one scheduled job: a daily digest that reads everything unread
in [Miniflux](miniflux.md), has Claude summarise it, and writes a note into the vault
(ADR-027). It exists because the 121 feeds in Miniflux were never meant to be read by a
human — the reader is a corpus, this job is the interface.

| Unit / file | Role |
|---|---|
| `homelab-feed-digest.timer` | daily at 06:30, `Persistent=true` |
| `homelab-feed-digest.service` | oneshot, `User=claude`, `TimeoutStartSec=900` |
| `~claude/.local/share/feed-digest/digest.sh` | Miniflux API → `claude -p` → vault → mark read |
| `~claude/.local/share/feed-digest/prompt.md` | generic English default, Ansible-owned |
| `<vault>/<folder>/prompt.local.md` | personal override — **wins when present** |
| `/mnt/data/secrets/claude/miniflux_api_key` | 0400, claude-owned |

Output lands in `<folder>/YYYY-MM-DD - <suffix>.md`, in two sections:
what changed, and zero to three post angles. Not `Inbox/` — the vault's own `CLAUDE.md`
warns it must not become a dumping ground, which a daily automated note would guarantee.

**No API key and no OAuth token for Claude itself.** Issue #15 specified a long-lived
`claude setup-token`; measuring showed `claude -p` works with the claude.ai session
credentials already in `~claude/.claude`, so the one secret that would have expired
silently once a year does not exist.

**The script writes the note, the model does not.** Claude reads stdin and emits markdown
on stdout; the shell composes the frontmatter and writes the file. The frontmatter stays
deterministic, and the job needs no write tool at all.

**What is capped is reported.** At most 400 entries per run; the rest stay *unread* for the
next run, and the count carried over appears in both the note and the Kuma message. A
digest truncated in silence reads exactly like a complete one.

`TimeoutStartSec=900` is not decorative: on 2026-08-13 six abandoned interactive `claude`
sessions held 1.5 GB of RAM and 525 MB of swap on this host for up to eleven days. Those
were visible. An unattended timer job that never exits would not be.

**Not `RuntimeMaxSec`** — systemd ignores it under `Type=oneshot` (it says so in the
journal, buried among the start lines), and oneshot defaults `TimeoutStartSec` to
*infinity*, so the first version of this unit advertised a ceiling it did not have. A
oneshot service is "starting" for its whole life; the start timeout is the bound.

### Configuration

| File | Encrypted | Published | Holds |
|---|---|---|---|
| `host_vars/<host>/local.yml` | yes | no | the Miniflux API key, the Kuma push URL |
| `host_vars/<host>/private.yml` | **no** | no | folder, note suffix, tags, title, wording |
| `<vault>/<folder>/prompt.local.md` | no | no | the personal prompt |

`private.yml` exists because the inventory otherwise offers only *public and plain* or
*private and encrypted*, and none of these values is a secret — encrypting a label just
means `ansible-vault edit` every time you want to reword it. Ansible loads every file in
`host_vars/<host>/`, so adding it needed nothing but a `.gitignore` line.

### Manual steps

Both are irreducible — neither API supports them:

1. **Miniflux API key** — *Settings → API Keys → Create*, then into `miniflux_api_key` in
   the vaulted `local.yml`.
2. **Kuma push monitor** — type *Push*, then its URL into `feed_digest_kuma_push_url`.

### Operating it

```sh
systemctl list-timers homelab-feed-digest.timer   # next run
systemctl start homelab-feed-digest.service       # run now
journalctl -u homelab-feed-digest.service -n 50   # what happened
sudo -u claude tail -30 ~claude/.local/share/feed-digest/digest.log
```

If a digest reads badly, fix the **prompt**, not the note. Notes are outputs, not sources.

Two ways, and the fast one needs no deploy:

- **Override, in the vault.** `<folder>/prompt.local.md` wins from the
  next run — Ansible never touches the vault, so there is no conflict to resolve, ever. It
  syncs through Nextcloud, so Obsidian edits it from a phone, which is where you are at
  06:30 when a digest reads badly. **This is where anything personal goes**: the stack to
  filter against, the editorial slots, the voice rules. This repository is public.
- **Default, in the repo.** `feed-digest-prompt.md.j2` is deliberately **generic and in
  English** — it must produce a usable digest for anyone running this role, with no override
  present. Edit it for structural fixes, never to add personal context.

The override wins **silently**; nothing warns that the repo default has moved on. The
journal does log which prompt a run used, which is the first thing to check when a digest
suddenly reads differently.

> **Re-running is not free.** The job marks entries read once summarised, so a bad digest
> cannot simply be replayed — the entries have left the unread pool. Resurrecting them
> takes an API call, written down in
> [`knowledge/runbooks/feed-digest.md`](../../knowledge/runbooks/feed-digest.md) along
> with the Kuma setup values, the failure tree and how a backlog drains.

## Restore

Nothing service-specific to restore: the **vault content lives in Nextcloud** (backed up
with the rest of `/mnt/data/services`). Re-running the `claude-code` role rebuilds the user,
sandbox, mounts and services; the only manual step is the one-time `claude` login.

See also: `knowledge/research/obsidian-claude-mobile-workflow.md`,
`knowledge/runbooks/restore-from-backup.md`,
`knowledge/runbooks/cloud-init-hosts-pin.md`,
`knowledge/runbooks/feed-digest.md`.
