# Forgejo

A private git forge, running here for one reason: to hold a **copy of the GitHub
repositories that survives losing the GitHub account**. GitHub stays the primary and
the showcase. Forgejo pulls from it on a schedule and keeps a full copy — history,
branches, tags — on the encrypted volume, inside the backup set, replicated offsite.

A local clone on a workstation is not that copy. It holds whatever branch was last
checked out, on one disk, with no history of what else existed.

> **Status: not yet deployed.** Written and reviewed on the workstation; the first
> deploy still has to close two open points, marked **VERIFY** below. Nothing in this
> file has been observed on the Pi yet (ADR-028).

## Access

- URL: `https://git.example.com` (VPN-only, like every other internal service — the
  subdomain only resolves on the LAN/VPN via Pi-hole split DNS).
- Login with the admin account created on first deploy (see below). Self-registration
  is disabled: this forge has exactly one user.
- **Git over SSH is off.** Clone over HTTPS from the LAN/VPN. There is no port 2222.

## How It Runs

One container, `forgejo`, on SQLite. No database sidecar.

It runs the **rootless image**, and that choice drives most of what follows. The
default Forgejo image starts as root, chowns its data directory and drops to uid 1000
via `su-exec` — which on this stack would mean handing SETUID and SETGID back after
`cap_drop: ALL`. The rootless image is already uid 1000 at PID 1, so it needs neither.

### The paths are the trap

The rootless image does **not** use `/data`. Everything written about Forgejo on the
internet mounts `/data`, and it will appear to work:

| | Rootless image | What tutorials say |
|-----------------|----------------------|--------------------|
| Data | `/var/lib/gitea` | `/data` |
| Config | `/etc/gitea` | `/data/gitea/conf` |
| `USER_UID`/`GID` | inert (fixed at build) | used |

A `/data` mount produces a container that starts, serves, and stores every repository
in a layer the next `compose up` discards. On the host the two mounts are:

```
/mnt/data/services/forgejo/data    -> /var/lib/gitea
/mnt/data/services/forgejo/config  -> /etc/gitea
```

Both are created `1000:1000` by the storage role, and that is not cosmetic: the
container holds no capability to chown anything, so a root-owned mount leaves it
unable to write its own database.

Note the database path reads `forgejo/data/data/forgejo.db` on the host. The doubled
segment is correct — the host `data` directory is the `/var/lib/gitea` mount, and
Forgejo keeps its own `APP_DATA_PATH` one level below that.

## First Deploy

Deploy targeted, as always:

```sh
ansible-playbook playbooks/site.yml --tags deploy -e deploy_services=forgejo --ask-vault-pass
```

Then, **on the Pi**, create the admin account. Forgejo has no `CREATE_ADMIN`
environment variable — the account cannot be made declaratively the way Miniflux's is,
and the web installer that would normally create it is locked (see below):

```sh
docker exec -u 1000 forgejo forgejo admin user create \
    --admin --username marc --email you@example.com \
    --password "$(cat /run/secrets/forgejo_admin_password)"
```

The password is read from the mounted secret inside the container rather than typed,
so it never reaches the host's shell history. Minimum length is 8 characters. Forgejo
hashes with **pbkdf2**, not bcrypt — there is no 72-byte ceiling here, unlike Miniflux
and Dozzle.

### VERIFY before walking away

Two things could not be settled from the workstation. Both need the running container:

**1. Does the healthcheck's `wget` exist?** The probe assumes busybox `wget` is in the
rootless image. If it is not, the container reports unhealthy forever and the heal
timer fights it every two minutes.

```sh
docker inspect --format '{{.State.Health.Status}}' forgejo   # want: healthy
docker exec forgejo wget --help >/dev/null 2>&1 && echo "wget present"
```

**2. What is the real write set?** `read_only` is deliberately `false` for now.
Once the service has run, served a page and completed a mirror pull:

```sh
docker diff forgejo
```

Then declare the paths it actually writes as `tmpfs` entries and flip `read_only` to
`true`, per issue #32. Do not guess the list from this document — measure it. A guessed
tmpfs is how a `git push` breaks six weeks later, far from the change that caused it.

## Setting Up a Mirror

Mirrors are created **by hand in the web UI**, the same way Uptime Kuma monitors are.
The API exists, but three or four mirrors do not justify automating it.

1. `+` → **New Migration** → **GitHub**
2. Clone address: the repository URL, e.g. `https://github.com/you/home-lab`
3. Tick **This repository will be a mirror**
4. Leave the token field empty — see below
5. Set the mirror interval (`8h` is a reasonable default)

**Public repositories only.** A pull-mirror of a public repository needs no
credential. Mirroring private ones would need a GitHub PAT in the vault, rotating on
GitHub's schedule — decided against on 2026-08-14 (ADR-028). If that changes, add the
token; the architecture does not need to change.

Forgejo pulls on its own schedule from then on. Nothing pushes to Forgejo, and nothing
here writes back to GitHub.

## Security Notes

- **The web installer is locked** (`INSTALL_LOCK=true`). It is a single
  unauthenticated form that creates the first administrator — whoever reaches it first
  owns the forge. `vpn-only` already gates the entrypoint, but that is a middleware
  and middlewares can be misconfigured, so the installer is shut before the container
  ever answers a request. This is why the admin is created by CLI.
- **Registration is disabled** (`DISABLE_REGISTRATION=true`).
- **SSH is disabled**, so no second port is published.
- Zero capabilities, `no-new-privileges`, uid 1000. `read_only` pending (above).

## Backup

No new path: `/mnt/data/services` is already backed up wholesale by restic.

The database gets one extra step in `backup.sh`, and it matters more here than
elsewhere. A live SQLite file snapshotted by restic can capture a torn WAL state, so
the database is taken through SQLite's Online Backup API into the dump directory
first, exactly as Vaultwarden's is:

```sh
sqlite3 /mnt/data/services/forgejo/data/data/forgejo.db ".backup '…/dumps/forgejo.sqlite3'"
```

The point of this service is to be the copy that survives losing GitHub. A backup of
it that restores to a corrupt database would defeat the whole exercise. The git object
stores are plain files and need no special handling.

## Monitoring

Add an Uptime Kuma monitor by hand (Kuma is v2; the automation tooling is v1-only):

- Type: **HTTP(s)**, URL `https://git.example.com/api/healthz`
- Accepted status codes: `200`
- Interval: 300s

## Startup

Forgejo is in **wave 1** of the staged startup, with the other light services. It has
no peer to wait for and nothing gates on it. Its 120s `start_period` covers the schema
migrations on first boot, not a slow init the wave has to absorb.

For maintenance use `docker compose down forgejo`, never `docker stop` — a stopped
container usually reports a non-zero exit code and the heal timer will resurrect it
within two minutes.

## References

- ADR-028 — the decisions behind this deployment and the alternatives rejected
- Issue #15 — services backlog; Forgejo was the last of the five
- Upstream: <https://forgejo.org/docs/latest/>
