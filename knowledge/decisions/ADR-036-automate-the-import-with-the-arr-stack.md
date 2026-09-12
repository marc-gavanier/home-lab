# ADR-036 — Automate the import with Prowlarr, Sonarr and Radarr

**Status**: accepted — 2026-09-12
**Depends on**: ADR-035 (media tree split by who writes to it)
**Related**: ADR-003 (Nextcloud media browsing), ADR-030 (configure the tools, do not write the glue)

## Context

Transmission downloads and Jellyfin reads a library. Nothing connects the two:
a finished download sits in `library/downloads/complete/` under its release
name, and Jellyfin only looks at `library/movies` and `library/shows` under the
naming convention it was configured with. The gap is filled by hand today, and
the manual import of Outlander S08 on 2026-09-12 showed exactly what that
costs: ten episodes, each buried in its own release subdirectory, none with a
name Jellyfin could match, all needing a hard link and a rename one by one.

ADR-030 says configure the tools rather than write the glue. That rule points
here rather than away: this job has mature tools, and the alternative would be a
rename-and-link script that nobody wants to own.

## Decision

Three containers, and only three.

- **Prowlarr** manages the indexers in one place and distributes them to the
  other two, instead of each being configured separately.
- **Sonarr** handles series, **Radarr** handles films.

**Lidarr and Readarr are deliberately absent.** Only films and series are
downloader-fed here — that was decided with the tree split in ADR-035, and it is
why `music` stayed in `media_dir`. Books already have their own ingest path
through Calibre-Web (ADR-025), which is better suited than Readarr, the weakest
member of the family.

## What the layout buys

Sonarr and Radarr mount `library_dir` **whole**, at `/data`. That single mount is
what lets an import be a hard link: `link()` refuses across two bind mounts even
when both resolve to the same filesystem, measured on this host in ADR-035. A
copy would cost each import its own size a second time and break the seed.

What they do NOT mount is `media_dir`. They can write to films, series and the
download directory; they cannot touch photos, music, home videos or the Calibre
library. Transmission's own mount is unchanged and still covers only
`library/downloads`.

## What is measured here, and what is not

Two things are stated as inherited rather than measured, so that nobody reads
them as evidence:

- **The capability set** — CHOWN, SETUID, SETGID, DAC_OVERRIDE, FOWNER — is the
  one that works for calibre-web and transmission, which are linuxserver s6
  images with the same root-init-then-drop-to-PUID shape. It has not been
  narrowed for these three. Narrowing it needs a `docker diff` per container
  after first start, the way ADR-025 did it.
- **`read_only` is not set, and was not attempted.** calibre-web documents an
  image that genuinely cannot run read-only; for these three the honest state is
  "unknown". Same for the 300 s `start_period`, which is a guess until a cold
  boot says otherwise.

The version pins are measured: 2.5.2, 4.0.19 and 6.3.0 were each confirmed to
publish a `linux/arm64` manifest before being written here. Radarr's stable tag
is 6.3.0 — its recent tags on the registry are nightly and develop builds, which
this repository does not run.

## The API keys, which cannot be templated

Each of the three generates its own API key on first start and stores it in its
`config.xml`. Prowlarr needs Sonarr's and Radarr's to push indexers to them. So
the keys cannot be rendered by Ansible in advance: they have to be read off the
containers after the first run and put into the vault, and they are credentials
in the sense the C89 audit means — they belong in the secret-value set used by
future sweeps.

## Consequences

- 29 containers become 32, joining startup wave 3 rather than wave 1: Sonarr and
  Radarr talk to Transmission's RPC and Transmission comes up in wave 2. They
  retry, so an earlier wave would work and simply say so in the journal on every
  boot.
- Three split-DNS names are added, keeping the count reconciled at 21 records
  against 21 `Host()` rules.
- The crash-heal timer needs no change: it derives its container set from the
  compose project label rather than from a list.
- Nothing is exposed publicly. All three sit behind the `vpn-only` middleware
  that the websecure entrypoint applies globally.
- RAM was not estimated. There were 4.8 GiB available with zero memory pressure
  before this change; the footprint will be measured after first start rather
  than predicted.
