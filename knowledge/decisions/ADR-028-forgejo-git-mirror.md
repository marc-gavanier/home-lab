# ADR-028 — Forgejo as a GitHub pull-mirror, rootless and on SQLite

**Date**: 2026-08-14
**Status**: accepted — deployed and measured on the Pi 2026-08-14

## Context

Issue #15 shortlisted five services on 2026-07-19. Four shipped over the following
month (IT-Tools ADR-024, Dozzle ADR-023, Calibre-Web ADR-025, Miniflux ADR-026 plus
the digest in ADR-027). Forgejo is the fifth and last.

The need is narrow and worth stating precisely, because it decides most of what
follows: **this is a safety net, not a replacement forge.** GitHub stays the primary
and the showcase. What is missing today is a copy of the repositories that survives
losing the GitHub account — a ban, a DMCA, a mistaken deletion — and a local clone on
a workstation is not that copy, because it holds one branch of one repository at the
mercy of one disk.

Two things come free with the choice and are explicitly *not* the reason for it: a
private container/package registry, and Forgejo Actions for running `ansible-lint`
in-house. Both stay off in this ADR.

Forgejo over Gitea for the non-profit governance and the monthly security releases;
over GitLab because GitLab wants 2.5-4 GB of RAM, which this Pi does not have to give.

## Decision

Deploy **Forgejo 16.0.2, the rootless image**, behind Traefik at `git.<domain>`,
gated by `vpn-only` like everything else, on **SQLite**, with **git-over-SSH
disabled** and the **web installer locked**. Mirrors are created by hand in the UI,
for public repositories only.

### The rootless image, because of capabilities rather than principle

The default Forgejo image starts as root, chowns its data directory and drops to uid
1000 through `su-exec`. On this stack that sequence costs SETUID and SETGID back out
of `cap_drop: ALL` (ADR-017), plus a writable image layer to do it in. The rootless
variant is already uid 1000 at PID 1, so it meets the baseline with nothing added.

The price is paid in paths, and it is the single most common way to get this service
wrong: the rootless image keeps data in **`/var/lib/gitea`**, not the `/data` that
every tutorial mounts. `USER_UID`/`USER_GID` are inert here — the uid is fixed at
build time. A `/data` mount would produce a container that starts, serves, and quietly
stores everything in a layer that the next `compose up` throws away.

The upstream documentation also points at `/etc/gitea` for configuration, and this ADR
originally mounted it. **That was wrong**: `GITEA_APP_INI` is
`/var/lib/gitea/custom/conf/app.ini`, so configuration already lives inside the data
volume. The mount stayed empty through a boot, a 425-commit clone and a fetch, and was
removed. One mount, not two.

Because the container holds no capability to chown anything, the host data directory
must exist as `1000:1000` *before* it starts. They are created in the storage role's
1000-owned loop rather than left to Docker, which would make them root-owned.

### SQLite, and the backup line that makes it honest

One user, one scheduled mirror job, no concurrency: Postgres would buy nothing and
cost ~70 MB plus a container to start, health-gate and back up. SQLite it is.

That choice has one consequence that must not be skipped. `restic` snapshotting a
live `.db` can capture a torn WAL state, so `backup.sh` takes the database through
SQLite's Online Backup API into the dump directory first — exactly as it already does
for Vaultwarden. **For this service the point is sharper than usual**: the whole
reason Forgejo exists here is to be the copy that survives losing GitHub, and a backup
that restores to a corrupt database would defeat the entire exercise. The git object
stores are plain files and need no special handling; only the database does.

### SSH off, installer locked

`DISABLE_SSH=true`: the mirror is a *pull*, driven outbound over HTTPS by Forgejo
itself, and cloning from the LAN works over HTTPS too. Leaving SSH on would publish
port 2222 for a door nothing knocks on. The day this stops being a mirror and becomes
a remote that receives pushes, that is the moment to reconsider — not before.

`INSTALL_LOCK=true`: Forgejo's web installer is a single unauthenticated form that
creates the first administrator. Whoever reaches it first owns the forge. `vpn-only`
already gates the entrypoint, but that is a middleware, and middlewares can be
misconfigured — so the installer is locked before the container ever answers a
request, and the admin account is created by CLI instead. `DISABLE_REGISTRATION=true`
closes the other door.

Forgejo hashes passwords with **pbkdf2** by default, not bcrypt, so unlike Miniflux
and Dozzle there is no 72-byte ceiling to trip over.

### Public repositories only

A pull-mirror of a public repository needs no credential. Mirroring private ones
would require a GitHub PAT living in the vault and rotating on GitHub's schedule —
real ongoing cost, for repositories that were not the reason this service exists.
Decided 2026-08-14: **public only**. Revisit by adding the token, not by changing the
architecture.

Mirrors are created by hand in the web UI, following the same precedent as the Uptime
Kuma monitors: the API exists, but three or four mirrors do not justify the
automation, and a half-automated list is worse than an honestly manual one.

## Consequences

Wave 1 of the staged startup gains one member. Forgejo has no peer to wait for and
nothing gates on it; its 120 s `start_period` covers schema migrations, not a slow
init the wave has to absorb.

Backups need no new path — `/mnt/data/services` is already taken wholesale — only the
`.backup` line above.

`git.<domain>` joins Pi-hole's split-DNS config, without which the name resolves
nowhere on the LAN or VPN. That line has a cost that is easy to miss: templating it
notifies the `Restart pihole` handler, which bounces Pi-hole *and* dnsproxy, and the
task is not scoped by `deploy_services` — so deploying Forgejo costs the house a short
DNS gap even though the deploy is targeted at one unrelated container.

**Both points left open at write time were closed on the first deploy**, measured on
the Pi rather than argued from the workstation:

1. **`read_only: true`.** `docker diff` after a full mirror clone of 425 commits —
   every branch plus the `refs/pull/*/head` refs — returned the *same* seven entries
   as an idle boot, five of them mount points. Git writes exclusively into the bind
   mount. One tmpfs on `/tmp` covers `GITEA_TEMP`, carrying `uid=1000` because a tmpfs
   mounts root-owned `0755` and the container holds no capability to work around it —
   the failure that already bit IT-Tools and both Postgres instances. Re-verified
   *after* enabling it, which is the part that matters: a fetch pulled a real new
   commit, moved the branch and PR refs, and passed `fsck`. That takes the stack from
   21 of 28 services with a read-only rootfs to 22.
2. **busybox `wget` is present**, so the healthcheck is sound: the container came up
   `healthy` on the first deploy, and `/api/healthz` answers 200 through Traefik with
   `database:ping` and `cache:ping` both passing.

**One limitation is worth recording, because it was underestimated when "no token"
was decided.** On GitHub the access token also unlocks the API, so a tokenless mirror
carries the **git repository only** — code, branches, tags and `refs/pull/*/head`.
Issues and pull request discussions are **not** mirrored. For a repository where much
of the reasoning lives in issues (this one included), the safety net catches the code
and drops the argument behind it. Accepted for now; adding a read-only PAT later
changes nothing structural and does not require recreating the mirror.

## Alternatives rejected

**The default (root) image** — costs SETUID/SETGID back and contradicts ADR-017 for
no benefit this deployment needs.

**Postgres** — ~70 MB and a second container for a workload that is one user and a
nightly mirror job.

**Keeping the web installer open behind `vpn-only`** — one misconfigured middleware
away from handing an admin account to the internet, to save one CLI command run once.

**Forgejo Actions runner** — a second container and a second privilege surface for CI
that GitHub Actions already runs for free. Reconsider if leaving GitHub stops being
hypothetical.

## References

- Issue #15 (services backlog), ADR-017 (drop all capabilities), ADR-011 (secrets on
  LUKS), ADR-013 (Uptime Kuma monitors by hand), issue #32 (read-only rootfs)
- `docs/05-services/forgejo.md` — first-run procedure and mirror setup
