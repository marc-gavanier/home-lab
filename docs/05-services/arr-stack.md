# Prowlarr, Sonarr and Radarr

Three containers, one mechanism: Prowlarr finds, Sonarr and Radarr decide and import. One page,
because what matters is how they chain.

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

## At a glance

| Service  | URL                         | Port |
|----------|-----------------------------|------|
| Prowlarr | `https://indexers.<domain>` | 9696 |
| Sonarr   | `https://series.<domain>`   | 8989 |
| Radarr   | `https://films.<domain>`    | 7878 |

| | |
|---|---|
| Access | LAN or VPN only (`vpn-only` middleware on the websecure entrypoint) |
| Data | `/config` per service under `services_data_dir` |
| Media | `library/movies`, `library/shows` — not backed up (ADR-035) |
| Backup | restic (`/mnt/data/services`) + one SQLite dump each (ADR-031) |
| Supervision | healthcheck on each container's `/ping` |
| ADR | [ADR-036](../../knowledge/decisions/ADR-036-automate-the-import-with-the-arr-stack.md), [ADR-035](../../knowledge/decisions/ADR-035-split-the-media-tree-by-who-writes-to-it.md) |

## How it works

- linuxserver s6 images: init runs as root, chowns `/config`, then drops to `PUID`/`PGID`.
  Same five capabilities as calibre-web and transmission — inherited, not measured; narrowing
  them needs a `docker diff` per container. `read_only` not attempted (ADR-036).
- Started in stack-startup wave 3, after Transmission (wave 2), because they call its RPC.
- Sonarr and Radarr mount `library_dir` whole at `/data`. Keep it one mount: `link()` fails
  across two bind mounts, so every import would become a copy and break the seed.
- `media_dir` is not mounted: they cannot touch photos, music, home videos or the Calibre library.
- API keys: each generates its own in `config.xml` on first start. Prowlarr needs the other two
  to push indexers, so keys cannot be templated in advance — read them after the first run and
  put them in the vault. They count as secrets for the C89 audit.
- `config.xml` holds the API key: the file is `0600` and the directory `0700` (set by the deploy
  role, `data_dirs.yml`); the databases beside it stay `0644`.
- Prowlarr replaces its indexer definitions daily from Prowlarr's own server, unpinned and
  unwatched; a definition decides where the tracker API key is sent. Accepted: Prowlarr cannot
  pin them, and a diff monitor would fire on every weekly churn.
- The media is not restorable and needs no restore: torrent-sourced, re-obtainable, kept until
  watched. Losing it costs a re-download.

## Backup and restore

- The databases are live SQLite in WAL mode, so a restic copy of the `.db` can be torn: committed
  data may still sit in the `-wal`. A `backup_sqlite_dumps` entry dumps each one first, via the
  Online Backup API:

  ```sh
  sqlite3 /mnt/data/services/sonarr/sonarr.db ".backup '…/dumps/sonarr.sqlite3'"
  ```

- The `.db` also stays in the snapshot, so `--include services/sonarr` restores a file and exits
  0 — but not necessarily a consistent one. Use the dump.
- `logs.db` files are not dumped: they hold only the application log.
- Restore Prowlarr first (the other two pull indexers from it). Procedure:
  [`restore-from-backup.md` § Restore Sonarr / Radarr / Prowlarr (SQLite)](../../knowledge/runbooks/restore-from-backup.md#restore-sonarr--radarr--prowlarr-sqlite).

## Check it works

`/ping` proves the web app answers, not that imports work. The real test: an imported file has a
link count of 2 and free space did not drop.

## Related

- [Transmission](transmission.md) — the download client they drive
- [Jellyfin](jellyfin.md) — the reader at the end of the chain
