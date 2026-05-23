# Obsidian + Claude Code + Mobile Workflow

**Status**: Phase A implemented (2026-05-23) — Obsidian + Remotely Save sync on PC and mobile. Phase B (Claude Code on the Pi) pending.
**Date**: 2026-05-15

## Goal

A markdown-based knowledge system where:
- Notes are organized as a folder hierarchy of `.md` files
- AI (Claude Code) can read/create/organize the structure, like in this very CLI workflow
- The whole thing is accessible from mobile, with the ability to chat with Claude while it reads/writes the homelab's filesystem

## The Popular 2026 Pattern

**Obsidian (editor) + Nextcloud (sync) + Claude Code (agent)**

- The **Obsidian vault is the same folder as the Claude Code project**
- Sync via Nextcloud (Obsidian plugins: `Remotely Save` or `LiveSync`)
- Markdown files act as **persistent memory** for Claude Code (cf. "planning-with-files" pattern)
- Mobile: Obsidian app to read/edit + SSH or Remote Control to drive Claude Code

## Components

### 1. Storage layer — Nextcloud (already deployed)
- Already running on the homelab
- WebDAV endpoint usable by Obsidian sync plugins

### 2. Editor — Obsidian
- Cross-platform (Linux, Windows, macOS, Android, iOS), free for personal use
- Vault = literally a folder of `.md` files (no proprietary DB)
- Mobile app available

### 3. Sync — Obsidian plugin
Two viable options:
- **Remotely Save** — syncs via Nextcloud WebDAV, simple, well-documented
- **LiveSync** — real-time sync via CouchDB; faster and handles concurrent edits gracefully (requires deploying CouchDB on the homelab)

### 4. AI agent — Claude Code on the Pi
- Claude Code supports Linux arm64
- Runs on the Pi, has filesystem access to the vault
- The Pi already has the synced Nextcloud folder available

### 5. Mobile interaction — 3 paths to choose from

#### A. Claude Code Remote Control (official, recommended)
- Start a Claude Code session on PC or Pi
- Continue the session from the Claude.ai mobile app
- Code never leaves the machine; the mobile app is a sync layer
- → https://code.claude.com/docs/en/remote-control

#### B. Power user: mosh + tmux + ntfy
- `mosh` survives network changes and reconnections
- `tmux` keeps the session alive between SSH disconnects
- `ntfy` push notifications when Claude finishes a long task
- `Termius` on mobile for the SSH client
- Reference: Harper Reed's blog

#### C. Simple: SSH from Termius
- Install Claude Code on the Pi
- SSH from Termius (mobile), run `claude`
- Closest to the current PC workflow

## Implementation Plan (when ready)

1. **Configure Nextcloud sync** on PC for a `vault/` folder
2. **Install Obsidian** on PC and create the vault inside the synced folder
3. **Install Obsidian on mobile** and configure the vault sync
4. **Install Claude Code on the Pi** (Linux arm64)
5. **Try Remote Control first** (least friction)
6. **Fallback to SSH + tmux** if Remote Control is limiting

## Sources

- [Self-Hosted Sync Nextcloud WebDAV (Obsidian Forum)](https://forum.obsidian.md/t/self-hosted-sync-iphone-ipad-desktop-using-nextcloud-webdav/112246)
- [Self-hosted Obsidian Sync Server (DEV.to)](https://dev.to/lightningdev123/how-to-set-up-a-self-hosted-obsidian-sync-server-hcn)
- [Claude Code Remote Control](https://code.claude.com/docs/en/remote-control)
- [Self-evolving Claude Code Memory with Obsidian (MindStudio)](https://www.mindstudio.ai/blog/self-evolving-claude-code-memory-obsidian-hooks)
- [Claude Code from the beach — mosh+tmux+ntfy (rogs)](https://rogs.me/2026/02/claude-code-from-the-beach-my-remote-coding-setup-with-mosh-tmux-and-ntfy/)
- [Claude Code is better on your phone (Harper Reed)](https://harper.blog/2026/01/05/claude-code-is-better-on-your-phone/)
- [planning-with-files pattern (GitHub)](https://github.com/othmanadi/planning-with-files)

## Decision

**Remotely Save** chosen (over LiveSync): solo use needs no real-time collaborative
editing, and Remotely Save reuses the existing Nextcloud WebDAV — no extra service
(CouchDB) to deploy.

## Phase A — Implemented (2026-05-23)

Sync working on PC (Linux) and mobile (/e/OS) via the Remotely Save plugin → Nextcloud WebDAV.

### Setup (per device)
1. Install Obsidian; create a vault named **`Notes`** (the name must be identical on
   every device — Remotely Save nests synced content under a folder named after the vault).
2. Community plugins → install & enable **Remotely Save**.
3. Configure WebDAV:
   - Server Address: `https://drive.example.com/remote.php/dav/files/admin`
     (point at the **account root**, not at `/Notes` — Remotely Save appends the vault
     name itself; pointing at `.../Notes` produces a doubled `/Notes/Notes`)
   - Username: `admin`, Password: a Nextcloud **app-password** (Settings → Security)
4. Mobile: enable **auto-run on startup** + scheduled sync (manual trigger is the
   ribbon cloud icon or the "Remotely Save: start sync" command).

### Gotchas hit
- **Doubled folder** `/Notes/Notes`: caused by setting the server address to `.../Notes`
  while the vault is also named `Notes`. Fix: server address = account root.
- **"changing file >= 50% not allowed"**: Remotely Save's mass-change guard trips on a
  near-empty vault. Lower/disable it while the vault is small; restore ~50% once it has
  many notes.
- VPN must be on (services are VPN-only, ADR-002). The `.md` files are stored locally on
  each device, so reading notes works offline; only sync needs the VPN.

### Phase B (pending)
Claude Code on the Pi. The vault already lands on the Pi at
`/mnt/data/services/nextcloud/data/admin/files/Notes` (Nextcloud data volume), so Claude
can read/write there directly. After Claude writes a file, an `occ files:scan` is needed
for Nextcloud to see it, then notify_push propagates it to clients in real time.