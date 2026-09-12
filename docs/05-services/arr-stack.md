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
the rest of `/mnt/data/services`. A restore brings back the indexer definitions,
the series and film lists, and the quality profiles.

The media itself is not theirs to restore: films and series live in
`library/movies` and `library/shows`, backed up separately and listed
subdirectory by subdirectory so that `library/downloads` stays out of the backup
(ADR-035).

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
