# ADR-045 — The notes vault is a local directory that Nextcloud serves as external storage

**Date**: 2026-11-25
**Status**: accepted — supersedes the rclone WebDAV mount of ADR-004 (point 3) and ADR-005

## Context

Claude Code reached the notes through an rclone WebDAV mount of `nextcloud:Notes`, so that its
writes went through Nextcloud and needed no `occ files:scan` (ADR-004). With
`--vfs-cache-mode writes`, every read was a WebDAV download through Traefik, PHP and MariaDB.
Measured on 2026-11-24 during one `grep -r` over the 2,059 notes (173 MB): 1,990 WebDAV
requests in 5 minutes, load average 15 on 4 cores, 0 % CPU idle, 91 % I/O pressure, 0.52 s to
open one note against 0.01 s for a local file. The whole Pi slowed down while Claude searched.

## Decision

The notes live in `/mnt/data/services/notes`, a plain directory on the encrypted volume.

- Nextcloud serves it as a **local external storage** named `Notes`, writable, with
  `filesystem_check_changes 1`: it stats the directory on access and indexes what changed
  outside it. That is the vendor's mechanism for files written by another process, already
  used for `Photos`, `Music`, `Papers` and `Inbox`. The WebDAV path `/Notes` is unchanged for
  Obsidian (Remotely Save).
- `~claude/vault` is a bind mount of that directory (`home-claude-vault.mount`, pulled in by
  `mnt-data.mount`). The sandbox still confines Claude's writes to `~/vault`.
- The directory is owned by uid 33 (Nextcloud), mode 0770; POSIX ACLs give `claude` access,
  and default ACLs give both `claude` and uid 33 `rwx` on everything created inside.
- rclone, its unit, its credential and the `drive` host pin are removed.

## Consequences

- Reads are local: a search no longer costs Nextcloud anything.
- Restic covers the notes through `/mnt/data/services`; ACLs are stored as extended
  attributes and restored with the files.
- A write by Claude appears in Nextcloud at the next access to the folder, not as a push
  event. Remotely Save polls, so the sync is unaffected.
- The migration moved the files out of the user's home storage: Nextcloud file ids, versions
  and the trash of the old folder do not follow (no note was shared, checked 2026-11-25).
- A tool that creates a file with an explicit mode narrower than 0660 limits the ACL mask on
  that file; Nextcloud still replaces it (it writes a part file and renames, which needs only
  the directory), but cannot append to it in place.

## Alternatives considered

- **`--vfs-cache-mode full`** — keeps every read going through Nextcloud for the metadata
  check, and the first search after a restart stays slow. Rejected as the fix, it treats the
  symptom.
- **Writing into Nextcloud's own datadir** — Nextcloud does not see the changes without
  `occ files:scan` (the reason ADR-004 chose WebDAV). Rejected.
