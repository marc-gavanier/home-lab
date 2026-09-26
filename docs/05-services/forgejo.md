# Forgejo

A private git forge that holds a copy of the GitHub repositories which survives losing the
GitHub account. GitHub stays the primary; Forgejo pull-mirrors it on a schedule
([ADR-028](../../knowledge/decisions/ADR-028-forgejo-git-mirror.md)).

## At a glance

| Item       | Value                                                                    |
|------------|--------------------------------------------------------------------------|
| URL        | `https://git.example.com` (VPN/LAN only, via Pi-hole split DNS)          |
| Container  | `forgejo`, rootless image, SQLite, no database sidecar                   |
| Data       | `/mnt/data/services/forgejo/data` → `/var/lib/gitea`, owned `1000:1000`  |
| Database   | `forgejo/data/data/forgejo.db` on the host                              |
| Git access | HTTPS only; SSH is off, no port 2222                                     |
| Users      | one admin, created by CLI; registration disabled                         |
| Backup     | restic (`/mnt/data/services`) + SQLite dump                              |
| Monitoring | Kuma HTTP monitor on `/api/healthz`                                      |
| Startup    | wave 1, `start_period` 420 s                                             |

## How it works

- **Rootless image**: uid 1000 at PID 1, so it needs no SETUID/SETGID after `cap_drop: ALL`.
- **The paths are not the tutorials' paths.** Mounting `/data` gives a forge that works and
  stores every repository in a layer the next `compose up` discards.

  |                  | Rootless image (verified)            | What tutorials say |
  |------------------|--------------------------------------|--------------------|
  | Data             | `/var/lib/gitea`                     | `/data`            |
  | Config           | `/var/lib/gitea/custom/conf/app.ini` | `/data/gitea/conf` |
  | `USER_UID`/`GID` | inert (fixed at build)               | used               |

- `/etc/gitea` is a red herring: the config already lives in the data volume. There is
  exactly one mount:

  ```
  /mnt/data/services/forgejo/data  ->  /var/lib/gitea
  ```

- The storage role creates it `1000:1000`. The container cannot chown, so a root-owned
  directory leaves it unable to write its database.
- Hand-edit config in `data/custom/conf/app.ini`, but any `FORGEJO__*` variable overwrites
  its setting at every start.
- The doubled `data/data` in the database path is correct: `FORGEJO__database__PATH` is
  `/var/lib/gitea/data/forgejo.db`.
- **Security:** installer locked (`INSTALL_LOCK=true`; it would let anyone reaching it create
  the first admin), `DISABLE_REGISTRATION=true`, SSH disabled, zero capabilities,
  `no-new-privileges`, uid 1000, read-only rootfs with one tmpfs on `/tmp` (`uid=1000`).
- **`SECRET_KEY`** encrypts 2FA and OAuth2 client secrets. The locked installer never
  generates it, so it comes from a mounted secret through `SECRET_KEY_URI` (never the
  environment). An empty value silently falls back to a key shared by every Forgejo install,
  so the argument spec marks it `required: true` and `secrets.yml` asserts it is non-empty.
  Forgejo has no key rotation: never let it be empty.
- For maintenance use `docker compose down forgejo`, never `docker stop` — the heal timer
  restarts a stopped container within two minutes.
- An undersized `start_period` makes Traefik withhold the router, and the service answers 404.

## First Deploy

1. Check `forgejo_admin_password` is in the vaulted `local.yml` (`required: true`: without it,
   any deploy fails validation).
2. Deploy with three tags, from `ansible/`:

   ```sh
   ansible-playbook playbooks/site.yml --tags storage,deploy,stack-startup \
       -e deploy_services=forgejo --ask-vault-pass
   ```

   - Without `storage`, Docker creates the data directory as root and Forgejo cannot write.
   - Without `stack-startup`, Forgejo never comes back after a reboot.
   - Re-running the storage role on a provisioned host is safe.
   - **This run bounces DNS for the whole house**: the new `git.<domain>` split-DNS entry
     fires `Restart pihole` (Pi-hole and dnsproxy), even on a targeted run.

3. On the Pi, create the admin account (no `CREATE_ADMIN` variable exists):

   ```sh
   docker exec forgejo sh -c 'forgejo admin user create \
       --admin --username marc-gavanier --fullname "Marc Gavanier" \
       --email you@example.com --must-change-password=false \
       --password "$(cat /run/secrets/forgejo_admin_password)"'
   ```

   - Keep `sh -c` with single quotes: otherwise `$(cat …)` runs on the host and the account
     gets an empty password, silently.
   - `--must-change-password=false` keeps the vault and the account in sync.
   - The username has no spaces and matches the GitHub handle so mirror paths line up.
   - The password briefly appears in the container process's argv (visible through `/proc`).
     To avoid that, use `--random-password`, then set the real one in the web UI and in the
     vault. Minimum 8 characters; pbkdf2, so no 72-byte limit.

4. Verify by logging into the web UI. Never pass the password to another command to test it:
   BusyBox `wget` echoes `--password=` back in its error.

## Common tasks

### Set up a mirror (web UI)

1. `+` → **New Migration** → **GitHub**
2. Clone address: the repository URL, e.g. `https://github.com/you/home-lab`
3. Under **Migration options**, tick **This repository will be a mirror**
4. Leave the access token empty

Set the interval afterwards in *Settings → Mirror* (default 8h). Without a token the mirror
holds code, branches, tags and `refs/pull/*/head` only — **no issues or PR discussions**. A
token can be added later without recreating the mirror. Nothing pushes to Forgejo or writes
back to GitHub.

### Re-verify read-only after an image change

Re-measure the write set (`docker diff forgejo`) rather than trusting the current tmpfs list,
then check git still works:

```sh
docker inspect forgejo --format '{{.HostConfig.ReadonlyRootfs}}'   # true
docker exec forgejo sh -c 'touch /usr/local/x'                     # Read-only file system
R=/var/lib/gitea/git/repositories/<owner>/<repo>.git
docker exec forgejo sh -c "git -C $R remote update --prune"        # what the sync runs
docker exec forgejo sh -c "git -C $R fsck --no-progress"           # exit 0
```

### Backup

`/mnt/data/services` is backed up by restic. The database is first copied through SQLite's
Online Backup API by a `backup_sqlite_dumps` entry (resticprofile hook), to avoid a torn WAL:

```sh
sqlite3 /mnt/data/services/forgejo/data/data/forgejo.db ".backup '…/dumps/forgejo.sqlite3'"
```

### Monitoring

Add the Uptime Kuma monitor by hand (Kuma is v2; the automation tooling is v1-only):

- Type: **HTTP(s)**, URL `https://git.example.com/api/healthz`
- Accepted status codes: `200`
- Interval: 300s

Upstream docs: <https://forgejo.org/docs/latest/>
