# ADR-042 — Paperless-ngx as the only writer of the papers tree (trial)

**Date**: 2026-10-30
**Status**: in progress — deployed on the Pi for evaluation (#422); adoption decided at the end
of the trial, and this record rewritten then

## Context

The workstation's documents are being reorganised before they move to the Pi, under the rule
"a tool first". Administrative papers are the one family without a tool: the target tree files
them in Nextcloud folders by person, household and company. Paperless-ngx, set aside in #15,
came back with #422 because the filing is now actually being done.

Two constraints from the operator shaped the trial:

- **No double entry**, and no copy of the same papers in two places.
- **Papers stay in a classic file tree**, readable without the tool, and on the workstation as
  they are today through Nextcloud sync.

Paperless cannot index files in place: it keeps its own copy of each document, and its
documentation forbids moving files in its media folder, and no mature tool indexes a tree in
place. Papra was the lighter alternative; it neither learns a classification nor documents
its OCR or storage layout, which are the two things #422 asks to evaluate.

## Decision

Run **Paperless-ngx 3.4.0** (official image) at `papers.<domain>`, VPN-only, as the **only
writer** of the papers tree, and let everything else read it:

- Paperless names and moves the originals with storage paths that reproduce the
  `~/Storage/Documents` tree (`<Person>/<Domain>/<correspondent>/<date> - <correspondent> -
  <title>`). The tree is the classification, so it is never edited by hand.
- Nextcloud mounts the originals **read-only** as `/Papers`, so they sync to the workstation
  like any folder, and the consumption folder **writable** as `/Inbox`, so a file dropped from
  the PC or the phone is imported with no second app.
- The trial covers the operator's personal papers only, imported from a copy; the existing
  folders are untouched until the decision.

### Sized for a Pi that already swaps

SQLite, one task worker, one thread, one web worker, and no Tika/Gotenberg: Office documents are
not part of the papers. 690 MB at idle (cgroup `anon` + swap, before any import).

### Hardened past the stack's usual bar

The image has a non-root mode: started as uid 33 it skips its user remapping and its chowns, so
it runs with **zero capabilities** and a **read-only rootfs** (`S6_READ_ONLY_ROOT=1`). uid 33 is
`www-data`, the uid Nextcloud writes `/Inbox` with, so both containers own the shared folder
without a capability. Two findings while bringing it up:

- s6-overlay execs from `/run`; Docker mounts tmpfs `noexec`, so `/run` carries `exec`.
- `PAPERLESS_CONSUMER_IGNORE_PATTERNS` takes regular expressions in 3.x. The glob `._*` read as
  a regex matches almost any name and would have ignored every drop.

### Nothing queued is lost by a restart

An upload through the web UI or the API waits in the scratch directory with its task in Redis.
Both are on disk — Redis as an append-only file, as `immich-redis`, and the scratch directory
under `/mnt/data`, excluded from the backup. Files dropped in `/Inbox` stay there until
imported, and the consumer picks up whatever it finds at start.

## Consequences

- One more SQLite database dumped by `backup_sqlite_dumps`; originals backed up as files.
- Two more containers in wave 3; one more Kuma monitor, on `/accounts/login/` because `/`
  answers 302. It proves the web process only: a stuck worker leaves it green.
- `paperless/consume` is a declared shared credential store (Paperless and Nextcloud).
- `paperless_admin_password` is read only when the account is created; rotating it means the UI,
  then the vault.

## To settle at the end of the trial

- OCR quality on French scans, and RAM and duration of an import.
- Whether `/Papers` syncs to the workstation read-only as expected, and drops from the PC and
  the phone reach `/Inbox`.
- A restore of the database and the originals together.
- Adopted: papers live in Paperless only and the matching Nextcloud folders are not created.
  Not adopted: papers go into Nextcloud folders, renamed from the metadata Paperless extracted,
  and Paperless is removed.
