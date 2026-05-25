# ADR-004: Run Claude Code on the Pi (hardened, drivable from mobile)

**Date**: 2026-05-24
**Status**: Accepted
**Deciders**: Marc Gavanier

## Context

The notes vault (see [ADR-005](ADR-005-obsidian-notes-system.md)) is meant to be
**managed by an AI agent**: Claude Code creates, organizes and links notes following the
vault's own `CLAUDE.md`. To do this from anywhere (including a phone), Claude Code runs on
the homelab and is driven remotely.

Running an agent that can execute shell commands on the homelab is a real security risk:
**Remote Control exposes a live Claude session to the Claude mobile app**, so a stolen,
unlocked phone could drive it to read secrets, use Docker, or wipe the system. The blast
radius must be contained.

## Decision

Run Claude Code **natively on the Pi** (not in the main user's context), confined on three
axes — all automated by the `claude-code` Ansible role:

1. **Dedicated unprivileged user `claude`** — *no sudo, no docker group*. It cannot read
   `/opt/homelab/.env`, use Docker, or touch other services' data.
2. **Claude Code `/sandbox`** (bubblewrap + socat): the Bash tool is confined to the vault,
   credential reads are denied, and network egress is restricted to `api.anthropic.com`. An
   AppArmor profile allows *only* `bwrap` to use user namespaces (Ubuntu 24.04 restricts
   these globally).
3. **Vault-only view**: Claude sees the notes vault and nothing else of the host. The vault
   is an **rclone WebDAV mount** of `nextcloud:Notes` at `~/vault`, so Claude acts as a
   Nextcloud *client* — writes go through WebDAV and Nextcloud indexes them immediately, with
   no `occ files:scan` needed (unlike writing into the datadir directly).

Exposure is via **Remote Control** as a systemd service (outbound HTTPS only, no inbound
port). Auth is a one-time interactive `claude` login on the Pi (claude.ai), not a token.

A compromised session is therefore confined to the vault (recoverable from backup) — **not**
the system, secrets, Docker, or other data.

## Consequences

### Pros
- **Confined blast radius**: least-privilege user + sandbox + vault-only mount → a misused
  session can at worst scramble the vault, which is backed up.
- **No scan needed**: writing through WebDAV (vs into the datadir) means Nextcloud indexes
  changes immediately — its own sync clients update live via notify_push, Obsidian on its
  next Remotely Save sync.
- **Reproducible**: the whole setup is the `claude-code` Ansible role; only the one-time
  `claude` login is manual (a deliberate security confirmation, not automated).
- **No inbound exposure**: Remote Control is outbound-only; nothing new opened on the firewall.

### Cons
- **Residual DoS risk**: no `MemoryMax`/`CPUQuota`/`TasksMax` on the service (accepted) — a
  misused session could exhaust resources. Mitigation: stop the service via SSH.
- **Manual one-time auth**: the `claude` login can't be automated (by design).
- **Memory**: ~300 MB while working on a 4 GB Pi — viable but adds to the budget.

## Alternatives Considered

- **Run Claude as the main user**: rejected — far too much privilege (sudo, docker, secrets).
- **Docker jail** (Claude in a container): rejected for now — heavier, and to be useful the
  agent still needs broad access inside; the dedicated-user + `/sandbox` combo ("level 1")
  gives strong confinement with less machinery. Revisit if stronger isolation is needed.
- **SSH + tmux only** (no Remote Control): viable fallback (mobile via Termius), less
  integrated than the official app; kept as a documented option.
- **Not running Claude on the Pi**: rejected — defeats the goal of AI-managed notes.

See also: `docs/05-services/claude-code.md`, `knowledge/research/obsidian-claude-mobile-workflow.md`.
