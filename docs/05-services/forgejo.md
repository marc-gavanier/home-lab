# Forgejo

A private git forge, running here for one reason: to hold a **copy of the GitHub
repositories that survives losing the GitHub account**. GitHub stays the primary and
the showcase. Forgejo pulls from it on a schedule and keeps a full copy — history,
branches, tags — on the encrypted volume, inside the backup set, replicated offsite.

A local clone on a workstation is not that copy. It holds whatever branch was last
checked out, on one disk, with no history of what else existed.

> **Deployed 2026-08-14** and verified on the Pi: healthy behind Traefik, read-only
> rootfs, mirroring 425 commits of `home-lab` (ADR-028).

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

| | Rootless image (verified) | What tutorials say |
|------------------|-----------------------------------|--------------------|
| Data | `/var/lib/gitea` | `/data` |
| Config | `/var/lib/gitea/custom/conf/app.ini` | `/data/gitea/conf` |
| `USER_UID`/`GID` | inert (fixed at build) | used |

A `/data` mount produces a container that starts, serves, and stores every repository
in a layer the next `compose up` discards.

**`/etc/gitea` is a red herring.** It is the path the upstream documentation points
at, and mounting it here was a mistake: `GITEA_APP_INI` is
`/var/lib/gitea/custom/conf/app.ini`, so the configuration already lives inside the
data volume. The `/etc/gitea` mount was tried and stayed **empty** through a boot, a
425-commit clone and a fetch, then removed. There is exactly one mount:

```
/mnt/data/services/forgejo/data  ->  /var/lib/gitea
```

It is created `1000:1000` by the storage role, and that is not cosmetic: the
container holds no capability to chown anything, so a root-owned mount leaves it
unable to write its own database.

To hand-edit configuration, edit `data/custom/conf/app.ini` under that mount — but
note that anything also expressed as a `FORGEJO__*` variable is rewritten from the
environment at every start.

Note the database path reads `forgejo/data/data/forgejo.db` on the host. The doubled
segment is correct — the host `data` directory is the `/var/lib/gitea` mount, and
Forgejo keeps its own `APP_DATA_PATH` one level below that.

## First Deploy

Deploy targeted, as always (from `ansible/`) — but **three tags, not just `deploy`**:

```sh
ansible-playbook playbooks/site.yml --tags storage,deploy,stack-startup \
    -e deploy_services=forgejo --ask-vault-pass
```

`deploy` alone is not enough and fails in a way that looks like a permissions bug:
the host data directory is created by the **storage** role, so without its tag
Docker creates it itself as root, and a container that is uid 1000 with no CHOWN
capability cannot write its own database. The **stack-startup** tag installs the
wave script — skip it and Forgejo works now but never comes back after a reboot.

Re-running the storage role on a provisioned host is safe: the mount and swap units
are `state: started` rather than `restarted`, and the LUKS setup is probe-guarded to
first run only.

**This run bounces DNS.** Adding `git.<domain>` to Pi-hole's split-DNS config
notifies the `Restart pihole` handler, which restarts Pi-hole *and* dnsproxy
(dnsproxy runs with `network_mode: service:pihole`). The templating task is not
scoped by `deploy_services`, so this happens even on a targeted run — expect a
short resolution gap for the whole house, and do not run it in the middle of
something that needs DNS.

`forgejo_admin_password` must already be in the vaulted `local.yml` — the deploy
role declares it `required: true`, so the run fails validation without it, and so
does a deploy of any *other* service once this branch has landed.

Then, **on the Pi**, create the admin account. Forgejo has no `CREATE_ADMIN`
environment variable — the account cannot be made declaratively the way Miniflux's is,
and the web installer that would normally create it is locked (see below):

```sh
docker exec forgejo sh -c 'forgejo admin user create \
    --admin --username marc-gavanier --fullname "Marc Gavanier" \
    --email you@example.com --must-change-password=false \
    --password "$(cat /run/secrets/forgejo_admin_password)"'
```

Three details that are each easy to get wrong:

- **`sh -c` with single quotes is required.** Without it the `$(cat …)` expands on the
  *host*, where that path does not exist — the account is created with an empty
  password and nothing warns you.
- **`--must-change-password=false`.** The default forces a password change at first
  login, which desynchronises the vault from the account immediately.
- **The username cannot contain spaces.** `marc-gavanier` matches the GitHub handle so
  mirror paths line up (`git.<domain>/marc-gavanier/home-lab`); the human-readable
  name goes in `--fullname`.

The password is read from the mounted secret inside the container rather than typed,
so it never reaches the host's shell history.

> **It does still reach an argument list, and that one is irreducible.**
> `forgejo admin user create` offers `--password` and nothing else — no stdin,
> no environment variable, checked against the deployed binary. So the value
> lands in the argv of the `forgejo` process inside the container, which `/proc`
> exposes to every local account on the host for the moment it runs (#198).
> Unlike the recurring cases fixed there, this is a **one-time** command run by
> the operator at first deploy. If that moment matters, `--random-password`
> avoids it entirely — create the account with a throwaway, then set the real
> password through the web UI and keep the vault in step. Minimum length is 8 characters. Forgejo
hashes with **pbkdf2**, not bcrypt — there is no 72-byte ceiling here, unlike Miniflux
and Dozzle, so a 128-byte generated password is fine.

> Do **not** try to verify the password by passing it to another command. BusyBox
> `wget` rejects `--password=` and echoes the whole argument back in its error, which
> puts the secret in the terminal and in any session transcript. The verification that
> matters is logging into the web UI.

### What was measured on 2026-08-14

Both points this service was deployed with open are now closed, on the Pi:

**busybox `wget` is present**, so the healthcheck is sound — the container came up
`healthy` on the first deploy and `/api/healthz` answers 200 through Traefik, with
`database:ping` and `cache:ping` both reporting `pass`.

**The write set is `/tmp` and nothing else.** `docker diff` after a full mirror clone
of 425 commits — every branch plus the `refs/pull/*/head` refs — returned the *same*
seven entries as an idle boot, five of them mount points. Git writes exclusively into
the bind mount. Once the redundant `/etc/gitea` mount was removed, the write set
settled at **three entries**, all of them the secret mount.

Hence `read_only: true` with one tmpfs on `/tmp`, carrying `uid=1000` because a tmpfs
mounts root-owned `0755` and the container holds no capability to work around that.

Verified again after enabling it, which is the part that matters — a Forgejo that
*starts* read-only does not prove it can still forge an object:

```sh
docker inspect forgejo --format '{{.HostConfig.ReadonlyRootfs}}'   # true
docker exec forgejo sh -c 'touch /usr/local/x'                     # Read-only file system
R=/var/lib/gitea/git/repositories/<owner>/<repo>.git
docker exec forgejo sh -c "git -C $R remote update --prune"        # what the sync runs
docker exec forgejo sh -c "git -C $R fsck --no-progress"           # exit 0
```

That fetch pulled a real new commit, moved the branch and the PR refs, passed `fsck`,
and left the image layer at five mount-point entries.

If you change the image, re-measure rather than trusting this section: a guessed tmpfs
list is how a `git push` breaks six weeks later, far from the change that caused it.

## Setting Up a Mirror

Mirrors are created **by hand in the web UI**, the same way Uptime Kuma monitors are.
The API exists, but three or four mirrors do not justify automating it.

1. `+` → **New Migration** → **GitHub**
2. Clone address: the repository URL, e.g. `https://github.com/you/home-lab`
3. Under **Migration options**, tick **This repository will be a mirror**
4. Leave the access token empty — see below

The **interval is not on this form**. It is set afterwards in the repository's
*Settings → Mirror*, and defaults to 8h.

**Public repositories only, and know what that leaves out.** A pull-mirror of a public
repository needs no credential — but on GitHub the token also unlocks the API, so
without one the mirror carries the **git repository only**: code, branches, tags, and
the `refs/pull/*/head` refs. **Issues and pull request discussions are not mirrored.**

That is a real gap for this stack, where a good deal of the reasoning lives in issues
rather than in code. It was accepted on 2026-08-14 to avoid a PAT in the vault
(ADR-028); adding one later changes nothing structural and does not require recreating
the mirror.

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
- Zero capabilities, `no-new-privileges`, uid 1000, read-only rootfs (measured above).

### SECRET_KEY, and why locking the installer created a second problem

Locking the installer solved the obvious risk and quietly created another one: the
installer is also what **generates `SECRET_KEY`**, the key that encrypts 2FA secrets
and OAuth2 client secrets at rest. Skipping the installer meant nothing ever
generated it, and Forgejo falls back to a constant compiled into the binary — the
same one in every Forgejo installation in the world.

Found by audit on 2026-08-15, and the shape of the evidence is worth keeping:

```
SECRET_KEY       present=NON longueur=0
JWT_SECRET       present=oui longueur=43
INTERNAL_TOKEN   present=oui longueur=105
```

`JWT_SECRET` and `INTERNAL_TOKEN` are generated by the binary itself on first run,
so they were fine. Only the one the *installer* owns was missing, which is exactly
what makes this easy to miss: the config looks populated.

**Nothing was exposed.** Measured the same day: zero 2FA enrolments, zero access
tokens, zero webhooks, and the three OAuth2 entries are Forgejo's own public
clients (`tea`, `git-credential-oauth`, `Git Credential Manager`), which carry no
secret. There was nothing encrypted under the default key.

That is precisely why it was fixed then rather than later. **Forgejo has no key
rotation.** Anything encrypted under the default would have to be re-enrolled by
hand — and the natural moment to discover the problem is the moment you turn on
2FA, which is the worst possible time to have to turn it off again.

The key is delivered through `SECRET_KEY_URI` pointing at a mounted secret rather
than as a plain value, so it never appears in the container environment where
`docker inspect` would expose it to anything able to read the Docker socket. It is
declared `required: true` in the role's argument spec on purpose: an empty value is
indistinguishable from a working one at runtime, so failing the play is the only
way its absence is ever visible.

`required: true` alone is not enough, and the gap is worth naming because it
almost shipped as a fix that fixed nothing. **It checks that the variable exists,
not that it holds anything** — and `local.example.yml` ships every secret as an
empty string, so a copied-but-unfilled example passes validation cleanly. Most
secrets here survive that: the service refuses an empty password and the container
dies loudly. This one would not. An empty file behind `SECRET_KEY_URI` sends
Forgejo straight back to the default key, with no error, no warning, and now the
appearance of protection. `secrets.yml` therefore asserts the value is non-empty
before writing anything.

## Backup

No new path: `/mnt/data/services` is already backed up wholesale by restic.

The database gets one extra step in the backup — a `backup_sqlite_dumps` entry
run from a resticprofile hook, `backup.sh` until ADR-031 — and it matters more here than
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
no peer to wait for and nothing gates on it. Its `start_period` is **420 s**, raised
from 120 s on 2026-08-29: the figure it replaces was sized for the first-boot schema
migrations, while the real worst case is a cold boot landing on the 03:00 backup.
An undersized one does not merely mislabel the container — Traefik withholds its
router while it is `starting`, so the service answers 404 through the proxy.

For maintenance use `docker compose down forgejo`, never `docker stop` — a stopped
container usually reports a non-zero exit code and the heal timer will resurrect it
within two minutes.

## References

- ADR-028 — the decisions behind this deployment and the alternatives rejected
- Issue #15 — services backlog; Forgejo was the last of the five
- Upstream: <https://forgejo.org/docs/latest/>
