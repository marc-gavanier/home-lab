# ADR-035 — Split the media tree by who writes to it

**Status**: accepted — 2026-09-12
**Supersedes nothing. Related**: ADR-003 (Nextcloud media browsing), ADR-033 (music over sshfs)

## Context

Adding an automated importer (Sonarr for series, Radarr for films, fed by
Prowlarr and downloading through the existing Transmission) means something
other than the operator starts writing into the media tree. Two questions fall
out of that, and they have to be answered together.

**The first is a kernel constraint, and it was measured rather than assumed.**
An importer moves a finished download into the library. If it can hard-link, the
file is not copied and Transmission keeps seeding the same bytes; if it cannot,
every import costs a second copy on disk and the seed breaks. Measured on this
host on 2026-09-12, inside the running Transmission container, whose `/config`
and `/downloads` bind mounts both come from host device 64768:

```
ln /downloads/.lntest /config/.lntest
  -> failed to create hard link: Cross-device link
ln /downloads/.lntest /downloads/.lntest2
  -> succeeded            (positive control: the instrument works)
```

So `link()` refuses across two bind mounts **even when both resolve to the same
underlying filesystem**. Sharing a filesystem is not enough; the source and the
destination have to sit under ONE mount inside the container that links them.

**The second is a privilege question.** The obvious fix — mount the whole media
tree read-write into Transmission and drop downloads inside it — would give a
process whose peer port is forwarded from the internet write access to 274 GB of
media, including 20 GB of personal footage. That trade is not worth making for a
convenience.

## Decision

Split by **origin**, not by media type:

```
/mnt/data/library/          an automated importer may write here
    downloads/{complete,incomplete}
    movies/                 42 GB, moved from media/videos/movies
    shows/                 213 GB, moved from media/videos/shows

/mnt/data/media/            the operator alone writes here
    videos/home-videos/     1.9 GB — personal footage
    videos/music-videos/     18 GB — curated by hand
    music/  photos/  books/  books-ingest/
```

Downloads live INSIDE `library/` rather than beside it, which is what satisfies
the kernel constraint: Sonarr and Radarr mount `library/` whole and link within
one mount. Transmission still mounts only `library/downloads`, so its privilege
is unchanged — the downloads moved to the library rather than the library
opening up to Transmission.

Music, photos and books do not move. Only films and series are fed by a
downloader here, and `music` in particular is written by the workstation over
sshfs (ADR-033); moving it would have broken that mount and, worse, would have
silently dropped 28 GB from the backup source.

**No service is reconfigured.** Jellyfin and Nextcloud read four sources into one
container tree — `library/movies` onto `/media/videos/movies`, and so on — so
their library definitions keep the paths they already had. Nested read-only bind
mounts are free for a reader; only a writer that links needs a single mount.

## Backups

`library/` is **never named as a restic source**. Its subdirectories are listed
one by one:

```
- /mnt/data/library/movies
- /mnt/data/library/shows
```

so `downloads/` is outside the backup *structurally*. An `exclude:` would have
worked too and was rejected: an exclusion is a filter that can be mistyped,
forgotten, or defeated by a later edit to the source list, whereas a path that
was never in the source cannot be any of those.

That choice has a symmetric failure, and it is gated rather than trusted. A new
category created under `library/` and not added to the source would go unbacked
in silence, with every check green. `library-categories-are-all-in-the-backup-source`
in the posture spec derives the set from the directory listing, requires each
entry minus `downloads/` to appear in the deployed profile, and carries a floor
so that an empty or missing tree fails instead of passing over nothing. Proven
in four directions before shipping: nominal passes, an unlisted category fails,
a tree holding only `downloads/` fires the floor, and a missing tree fails.

The `.torrent` files Transmission keeps in `services/transmission/config/torrents/`
stay in the backup by decision. Each carries an announce URL containing the
tracker passkey, which is a credential — verified on 2026-09-12 — but the restic
repository is encrypted, and keeping them is what lets a restore resume seeding.
The passkey belongs in the secret-value set of the C89 audit so that future
sweeps see it.

## Alternatives considered

**Mount the media tree read-write into Transmission** and put downloads inside
it. One mount, no move, hard links work. Rejected on privilege: an
internet-reachable process would gain write access to the whole library.

**Keep the current layout and let the importer copy.** Rejected on measurement:
213 GB of series, and every import would cost its size twice and stop the seed.

**A symlink from the old path to the new one.** Rejected on this repository's own
history: a symlink read through a directory bind mount resolves inside the
container's namespace and dangles — the defect that broke SearXNG's secret for
weeks (#27).

**Move photos and books too.** Not done. Photos arrive from phones through
Immich and no acquisition tool writes them; books have their own Calibre ingest
path. Both can move later at the same cost, since a rename on one filesystem is
instant.

## Consequences

- Two renames, no data copied: both trees are on device 64768.
- A short interruption of Jellyfin, Nextcloud and Transmission during the move.
- A second path group appears in the restic repository. Old snapshots keep the
  old paths; nothing is rewritten, and restic deduplicates by content, so no
  data is uploaded twice. Cleaning up obsolete path groups was declined in
  August and this does not reopen it.
- `docs/06-backup/README.md` and the service pages are updated in the same
  change; the restore runbook's paths are unaffected because it restores by
  absolute path from the snapshot.
