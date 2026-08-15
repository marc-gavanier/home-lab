# ADR-010 — Offsite backup on a second Pi (3-2-1 completion)

**Date:** 2026-07-12
**Status:** Accepted

## Context

All backups lived on the same WD 5TB HDD as the data (restic repo at
`/mnt/data/backups/restic-repo`). Fire, theft or a controller failure at home
destroys both the data and every backup. The retired Pi 4 (4GB) and a WD Blue
2TB SATA SSD are available; the Pi will be hosted at a relative's home
(~summer 2026) behind a consumer NAT box.

## Decision

A second Pi ("backup", inventory host `offsite`) receives a nightly
`restic copy` of the latest snapshot from the homelab:

| Aspect              | Choice                           | Rationale                                                                                                                                 |
|---------------------|----------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------|
| Transport           | WireGuard client → home wg-easy  | Outbound-only from the relative's LAN: no port forwarding, CGNAT-safe                                                                     |
| Protocol            | rest-server 0.14 `--append-only` | A compromised homelab can write but never delete offsite history                                                                          |
| Replication         | `restic copy` (nightly)          | Independent snapshot chains; local corruption does not propagate                                                                          |
| Offsite repo init   | `--copy-chunker-params`          | Preserves dedup across repos                                                                                                              |
| Disk encryption     | None (ext4)                      | Restic already encrypts; the Pi reboots unattended after power cuts                                                                       |
| Repo password       | NOT stored on the offsite Pi     | A stolen Pi/SSD yields ciphertext only — this replaces LUKS                                                                               |
| Repo passwords      | Distinct per repo                | Homelab repo password is useless against the offsite repo, and vice versa                                                                 |
| rest-server deploy  | systemd binary, not Docker       | Minimal surface: no Docker daemon at all on the offsite Pi                                                                                |
| Homelab → peer path | Host is its own wg-easy client   | wg0 lives in the wg-easy container; the host peers via loopback ("homelab-host", 10.8.0.5) so the path is identical before/after the move |

Consequences of the no-password-on-offsite rule:

- `restic forget/prune` cannot run offsite (append-only blocks it from the
  homelab anyway). Retention is a rare, manual, on-site procedure — growth is
  slow because media is mostly append-only.
- Repo integrity (`restic check`) runs weekly FROM the homelab through the
  tunnel (systemd timer `homelab-offsite-check`, Sunday 06:00).
- The offsite Pi only self-reports disk health (df + SMART) to Uptime Kuma.

## Monitoring

Three Uptime Kuma push monitors (dead-man's switches): nightly local backup
(existing), nightly offsite copy, weekly offsite check. Plus the weekly
disk-health push from the offsite Pi itself.

## Disaster recovery

If the homelab is lost entirely: retrieve the offsite Pi (or just its SSD),
`restic restore` with the offsite repo password, re-provision from the git
repo. **The offsite repo password must therefore exist outside the homelab**, in
at least two independent places — it is the root of the recovery chain.
See `knowledge/runbooks/offsite-backup.md`.

## Hardware notes

- The 52Pi tower enclosure's ASMedia ASM1153 USB-SATA bridge corrupts writes
  in UAS mode on the Pi (I/O errors during the first mkfs). Fixed with
  `usb-storage.quirks=174c:55aa:u` (host var `usb_storage_quirks`).

## Alternatives considered

- **rsync of the repo**: replicates local corruption byte-for-byte; rejected.
- **Second full `restic backup` to the offsite repo**: fully independent
  chains but re-reads all data nightly on the Pi; rejected (CPU/IO cost).
- **Cloud storage (B2/S3)**: recurring cost for ~400GB+, slower full restore;
  the second Pi was already available. May complement later (3-2-1-1).
- **LUKS on the offsite SSD**: requires remote unlock after every power cut
  at the relative's home; restic encryption already covers the threat.
