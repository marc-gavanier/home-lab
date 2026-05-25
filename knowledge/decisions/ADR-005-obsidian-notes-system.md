# ADR-005: Obsidian Notes System Synced via Nextcloud WebDAV

**Date**: 2026-05-23
**Status**: Accepted
**Deciders**: Marc Gavanier

## Context

The homelab needs a personal **knowledge/notes system** that is:

- a hierarchy of plain `.md` files (no proprietary database, no lock-in),
- editable on PC **and** mobile, readable **offline**,
- **manageable by Claude Code** (create/organize/link notes), and
- self-hosted, reusing existing services where possible.

This replaces **HedgeDoc** (decommissioned), whose collaborative web pads didn't fit a
personal Markdown vault driven by an AI agent.

## Decision

- **Editor**: **Obsidian** (PC + mobile) — the vault is literally a folder of `.md` files.
- **Sync**: the **Remotely Save** plugin over **Nextcloud WebDAV** (the vault syncs to the
  `Notes/` folder). No extra service to deploy.
- **Agent**: **Claude Code on the Pi** edits the same vault via a rclone WebDAV mount —
  see [ADR-004](ADR-004-claude-code-on-the-pi.md).
- **Organization**: a **PARA** structure governed by the vault's own `CLAUDE.md` (the source
  of truth for naming, frontmatter, links, and Claude's golden rules).

## Consequences

### Pros
- **No lock-in**: plain Markdown files; the vault works without any of the tooling.
- **No new service**: reuses the existing Nextcloud WebDAV endpoint (vs deploying CouchDB).
- **Offline**: `.md` files are stored locally on each device; only sync needs the VPN.
- **AI-manageable**: the same folder is a Claude Code project.

### Cons
- **Not real-time**: Remotely Save syncs on a schedule/trigger, not live — concurrent edits
  of the same note (Obsidian mobile vs Claude) can conflict. Low risk for solo use.
- **Setup quirks**: the vault name must match on all devices; point the WebDAV server at the
  account root (not `/Notes`) to avoid a doubled `/Notes/Notes`; the 50% mass-change guard
  trips on a near-empty vault.

## Alternatives Considered

- **LiveSync (CouchDB)**: rejected — real-time/conflict-free, but needs a dedicated CouchDB
  service; solo use doesn't need collaborative editing.
- **Nextcloud Notes app**: rejected — redundant with Obsidian, weaker editor, not a Claude
  Code project.
- **HedgeDoc**: decommissioned — collaborative pads, not a personal AI-managed markdown vault.

See also: `knowledge/research/obsidian-claude-mobile-workflow.md`.
