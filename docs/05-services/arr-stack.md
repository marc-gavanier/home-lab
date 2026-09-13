# Prowlarr, Sonarr and Radarr

One page for three containers, because they are one mechanism: Prowlarr finds,
Sonarr and Radarr decide and import. Splitting them across three pages would
repeat the same layout three times and hide the only thing worth understanding,
which is how they chain together.

```
Prowlarr        indexers, distributed to the two below
   ↓
Sonarr (series) / Radarr (films)    decide what to fetch, search, choose
   ↓
Transmission    downloads into library/downloads/complete
   ↓
Sonarr / Radarr import by HARD LINK into library/shows and library/movies
   ↓
Jellyfin        reads the library it was already configured with
```

## Access

| Service  | URL                        | Port |
|----------|----------------------------|------|
| Prowlarr | `https://indexers.<domain>` | 9696 |
| Sonarr   | `https://series.<domain>`   | 8989 |
| Radarr   | `https://films.<domain>`    | 7878 |

LAN or VPN only — the `vpn-only` middleware applies globally on the websecure
entrypoint, so none of the three is reachable from the internet.

## How It Runs

linuxserver s6 images: the init runs as root, chowns `/config`, then drops to
`PUID`/`PGID`. They carry the same five capabilities as calibre-web and
transmission, and **that set is inherited, not measured** — narrowing it needs a
`docker diff` per container. `read_only` is not set and was not attempted; the
honest state is unknown rather than impossible (ADR-036).

Started by stack-startup **wave 3**, not wave 1: Sonarr and Radarr talk to
Transmission's RPC, and Transmission comes up in wave 2.

## The mount that makes an import free

Sonarr and Radarr mount `library_dir` **whole** at `/data`. That single mount is
the entire point: `link()` refuses across two bind mounts even when both resolve
to the same filesystem, so two mounts would turn every import into a copy — its
own size again on disk, and a broken seed. Measured in ADR-035.

`media_dir` is deliberately **not** mounted. These two can write to films,
series and the download directory, and to nothing the operator produces —
photos, music, home videos and the Calibre library are out of reach.

## Secrets

Each generates its own API key on first start, into its `config.xml`. Prowlarr
needs the other two's to push indexers to them, so **the keys cannot be
templated in advance**: read them off the containers after the first run and put
them in the vault. They are credentials, and they belong in the secret-value set
the C89 audit sweeps.

## Data and Restore

`/config` per service under `services_data_dir`, inside the restic source with
the rest of `/mnt/data/services`. It holds the indexer definitions, the series
and film lists, the quality profiles, the download history — and `config.xml`,
which carries the API key. That is why the directory is `0700`: the file itself
is `0644` and the directory is what keeps the key private.

**A plain file restore is not enough on its own — see `## Backup` below.** The
full procedure is
[`restore-from-backup.md` § Restore Sonarr / Radarr / Prowlarr (SQLite)](../../knowledge/runbooks/restore-from-backup.md#restore-sonarr--radarr--prowlarr-sqlite);
restore **Prowlarr first**, because the other two pull their indexer definitions
from it.

The media itself is not theirs to restore: films and series live in
`library/movies` and `library/shows`, backed up separately and listed
subdirectory by subdirectory so that `library/downloads` stays out of the backup
(ADR-035).

## Backup

No new path: `/mnt/data/services` is already backed up wholesale by restic.

Each of the three databases gets one extra step — a `backup_sqlite_dumps` entry
run from a resticprofile hook (ADR-031), added 2026-09-13 — and the reason is the
same one that applies to Vaultwarden and Forgejo. These are live SQLite
databases in WAL mode, so a restic snapshot of the file can capture a torn
state: the committed transactions sitting in the `-wal` beside it are not in the
file restic copied.

How much data that is, measured on the running host — all three read at the same
instant, because a WAL grows and is checkpointed continuously and figures taken
minutes apart do not belong in the same table:

| File | Committed data outside the main database |
|-------------------|------------------------------------------|
| `radarr.db-wal`   | 310 KB |
| `sonarr.db-wal`   | 286 KB |
| `prowlarr.db-wal` | 20 KB  |

Those are ordinary values, not a worst case. `radarr.db-wal` was measured at
**3.77 MB** on 2026-09-13 — which is the figure that justified adding the dumps,
and the reason to read the table above as "routinely non-zero" rather than as a
bound.

The dump takes each database through SQLite's Online Backup API into the dump
directory first:

```sh
sqlite3 /mnt/data/services/sonarr/sonarr.db ".backup '…/dumps/sonarr.sqlite3'"
```

**These three differ from Uptime Kuma's database in one way that matters during
a restore.** Kuma's `kuma.db` is *excluded* from the snapshot, so restoring
`services/uptime-kuma` visibly gives you no database at all. These are dumped
*and* left in the snapshot, so a plain `--include services/sonarr` hands you a
`.db` and exits 0 — it is just not necessarily the consistent one. Prefer the
dump; the runbook section linked above does.

Their `logs.db` siblings are deliberately not dumped: they hold the application
log, a rescan of the UI rebuilds nothing anyone needs from them, and losing them
costs history rather than state.

## Health

Each container probes its own `/ping`. What that proves is that the web
application answers — not that an import would succeed. The function to watch is
whether a finished download actually lands in the library as a hard link, which
shows up as the link count on the imported file being 2 and the free space not
moving.

## Related

- [ADR-036](../../knowledge/decisions/ADR-036-automate-the-import-with-the-arr-stack.md) — why these three and not Lidarr or Readarr
- [ADR-035](../../knowledge/decisions/ADR-035-split-the-media-tree-by-who-writes-to-it.md) — the layout that makes hard links possible
- [Transmission](transmission.md) — the download client they drive
- [Jellyfin](jellyfin.md) — the reader at the end of the chain
