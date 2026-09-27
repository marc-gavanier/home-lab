# Rotating a secret

Use this page before changing any secret in the vault. A deploy rotates some
secrets; for others it reports `changed`, restarts the service, and leaves the
old credential in force.

## Which is which

| Secret                         | Consumer                     | Does a deploy rotate it?                                                                   |
|--------------------------------|------------------------------|--------------------------------------------------------------------------------------------|
| `cf_dns_api_token`             | traefik + cloudflare-ddns.sh | **yes**, but the two carriers sit behind different tags; see [below](#cf_dns_api_token)    |
| `transmission_password`        | transmission                 | **yes**, then update the copy in Kuma; see [below](#transmission_password)                 |
| `dozzle_users.yml`             | dozzle                       | **yes** (read at start)                                                                    |
| `forgejo_secret_key`           | forgejo                      | **yes**, but see [below](#forgejo_secret_key)                                              |
| `miniflux_database_url`        | miniflux                     | **yes**, but alone it breaks the app; see [Rotating a database password](#rotating-a-database-password) |
| `pihole_password`              | pihole                       | **yes**                                                                                    |
| `nextcloud_redis_password`     | nextcloud-redis + nextcloud  | **yes** (password file, `redis.conf`, config all notify)                                   |
| `nextcloud_redis.conf`         | nextcloud-redis              | **yes**, rendered from `nextcloud_redis_password`; host edits are overwritten              |
| `searxng_secret_key`           | searxng                      | **yes**, via `searxng_settings`, read at start                                             |
| `restic_password`              | resticprofile, `restic init` | **no, and never rotate it alone**; see [restic](#the-restic-passwords-key-add-first-always) |
| `offsite_restic_password`      | resticprofile (offsite)      | **no, and never rotate it alone**; see [restic](#the-restic-passwords-key-add-first-always) |
| `luks_passphrase`              | cryptsetup / `luks_device`   | **no, and the deploy reports `ok`**; see [LUKS](#the-luks-passphrase-a-green-deploy-is-not-evidence) |
| `wg_password`                  | wg-easy admin UI             | **no**, the deploy never sets it; see [wg-easy](#wg_password-the-deploy-never-sets-it-at-all) |
| `rclone_webdav_pass`           | vault-mount (rclone)         | **yes**, but the old app password stays valid; see [below](#app-passwords-and-api-keys-delete-the-old-one) |
| `miniflux_api_key`             | feed digest                  | **yes**, but the old key stays valid; see [below](#app-passwords-and-api-keys-delete-the-old-one) |
| `vaultwarden_admin_token_hash` | vaultwarden                  | **no**, `config.json` overrides the environment; see [Vaultwarden](#rotating-the-vaultwarden-admin-token) |
| `nextcloud_db_password`        | nextcloud-db + config.php    | **no**, `initdb` only                                                                      |
| `nextcloud_db_root_password`   | nextcloud-db                 | **no**, `initdb` only                                                                      |
| `immich_db_password`           | immich-db + immich-server    | **no**, `initdb` only                                                                      |
| `miniflux_db_password`         | miniflux-db                  | **no**, `initdb` only                                                                      |
| `miniflux_admin_password`      | miniflux                     | **no**, `CREATE_ADMIN` runs once                                                           |
| `forgejo_admin_password`       | forgejo CLI                  | **no**, first deploy only                                                                  |

### `cf_dns_api_token`

Two carriers, written by different tags, and nothing compares them:

- tag `secrets` (`roles/deploy/tasks/secrets.yml`) writes
  `/mnt/data/secrets/docker/cf_dns_api_token` for Traefik;
- tag `ddns` (`roles/deploy/tasks/ddns.yml`) writes
  `/mnt/data/secrets/ddns.env` for the DDNS updater.

The DDNS keeps the `vpn` A record (the WireGuard endpoint) fresh. If it still
holds a revoked token, you lose remote access at the next public-IP change.

1. Rotate with a full deploy, or with both tags.
2. Verify both files hold the new value.
3. Only then revoke the old token in the Cloudflare dashboard.

### The restic passwords: `key add` FIRST, always

`restic_password` and `offsite_restic_password` are the repositories' encryption
keys. Deploying a new value alone makes both backups unreadable, and nothing goes
red until the next run. Add the new key to the repository first.

1. Add the new key while the old one still works:

   ```bash
   restic -r /mnt/data/backups/restic-repo key add
   ```

2. Prove the new key opens the repository:

   ```bash
   RESTIC_PASSWORD='<new>' restic -r /mnt/data/backups/restic-repo snapshots | tail -3
   ```

3. Put the new value in the vault and deploy.
4. Replace any offline copy of this password now (ADR-010): after step 5 an old
   copy opens nothing.
5. After a successful nightly run, remove the old key:

   ```bash
   restic -r /mnt/data/backups/restic-repo key list
   restic -r /mnt/data/backups/restic-repo key remove <old-id>
   ```

The offsite repository is append-only: leave its old key in place unless you
have a reason to remove it.

### The LUKS passphrase: a green deploy is not evidence

Changing `luks_passphrase` in the vault does **not** change the disk.
`community.crypto.luks_device` with `state: opened` returns `ok` on an open
volume without testing the passphrase. The disk has **one keyslot**, and a
mismatch shows up at the next unlock, when `wg0.conf` (on the volume) is not yet
available and nothing can be fixed remotely.

1. Add the new passphrase as a second keyslot:

   ```bash
   sudo cryptsetup luksAddKey /dev/sda1
   ```

2. Prove it opens the volume (safe while mounted):

   ```bash
   sudo cryptsetup luksOpen --test-passphrase /dev/sda1 && echo "new passphrase accepted"
   ```

3. Re-take the header backup ([luks-header-backup](luks-header-backup.md)).
4. Put the new value in the vault and deploy.
5. Only after an attended reboot has unlocked with the new passphrase, remove
   the old keyslot, then re-take the header backup again:

   ```bash
   sudo cryptsetup luksKillSlot /dev/sda1 <old-slot>
   ```

Never merge steps 4 and 5: until an unlock succeeds with the new passphrase, the
old keyslot is the only tested way in.

### `wg_password`: the deploy never sets it at all

The deploy renders the file and only *logs in* with it, so a new value gives a
`changed` file and no rotation. If wg-easy is down, the script exits 0.

⚠️ Do not restart or upgrade wg-easy to force this while nobody is on site: it
is the only path to the host.

1. Change the password in the wg-easy UI.
2. Put the same value in the vault.
3. If the rotation answers a leak or a lost device, end every open session: a
   new password does not
   ([wireguard-peer-revocation](wireguard-peer-revocation.md#end-every-wg-easy-admin-session)).

### App passwords and API keys: delete the old one

Nextcloud and Miniflux accept several credentials at once. Creating a new one
does not retire the previous one: a Nextcloud app password keeps full access to
the account, with no expiry and no second factor.

1. Create the new credential in the app, put it in the vault and deploy
   (`--tags claude-code`).
2. Check the consumer works with it: the vault mount lists files, or the next
   digest run is green.
3. Delete the old credential in the app. Nextcloud: *Settings → Security →
   Devices & sessions*, the older of the two same-named lines. Miniflux:
   *Settings → API Keys*.

### Why the database ones cannot work

`POSTGRES_PASSWORD_FILE` and `MYSQL_PASSWORD_FILE` are read during `initdb` only.
Every later start says so:

```bash
docker logs immich-db   | grep -i "skipping initialization"
docker logs miniflux-db | grep -i "skipping initialization"
```

MariaDB prints `[Entrypoint]: MariaDB upgrade not required` instead; same
behaviour.

### `transmission_password`

The deploy rotates it, but the Uptime Kuma monitor authenticates with its own
copy in `kuma.db`.

1. Deploy.
2. In Kuma: **Transmission → Edit → HTTP Options → Authentication**, set the new
   password. The monitor is red between steps 1 and 2; that is expected.
3. Check the monitor returns `200 - OK, keyword is found`.

Any change that makes a monitor authenticate creates a credential copy in Kuma.
Transmission is currently the only one.

### `forgejo_secret_key`

A deploy applies it, but it encrypts forge data at rest. Rotate it only on an
instance whose data you can lose, or after checking what depends on it.

## Rotating a database password

Deploy the new value first, then change the database, back to back: the service
is broken while the two disagree. This order keeps the password out of any
shell command (a `$` expanded by the local shell once truncated one).

### 1. Vault, then deploy

```bash
ansible-vault edit inventory/host_vars/homelab/local.yml --ask-vault-pass
```

Check the edit saved: `ansible-vault edit` writes nothing if you quit without
saving. This prints the length, not the value:

```bash
ansible-vault view inventory/host_vars/homelab/local.yml --ask-vault-pass \
  | sed -n "s/^immich_db_password: *//p" | tr -d "\"'" | awk '{print "length:", length($0)}'
```

```bash
ansible-playbook playbooks/site.yml --tags deploy -e deploy_services=<svc> --ask-vault-pass
```

### 2. Change it in the database, reading the file the deploy just wrote

The quoted here-doc (`<<'REMOTE'`) keeps the local shell out, and the password
never appears as an argument.

Postgres (`immich-db`, `miniflux-db`). `psql -c` does not interpolate psql
variables, so the literal is built in the shell with single quotes doubled:

```bash
ssh homelab 'docker exec -i immich-db sh' <<'REMOTE'
PW=$(cat /run/secrets/immich_db_password)
[ -n "$PW" ] || { echo "empty secret, aborting"; exit 1; }
ESC=$(printf '%s' "$PW" | sed "s/'/''/g")
psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "ALTER USER \"$POSTGRES_USER\" WITH PASSWORD '$ESC'"
REMOTE
```

MariaDB (`nextcloud-db`). The statement goes in through stdin, never `-e`, so
the new password is not in a command line journald may log:

```bash
ssh homelab 'docker exec -i nextcloud-db sh' <<'REMOTE'
PW=$(cat /run/secrets/nextcloud_db_password)
RP=$(cat /run/secrets/nextcloud_db_root_password)
[ -n "$PW" ] && [ -n "$RP" ] || { echo "empty secret, aborting"; exit 1; }
MYSQL_PWD="$RP" mariadb -u root -N <<SQL
ALTER USER '$MYSQL_USER'@'%' IDENTIFIED BY '$PW';
SQL
REMOTE
```

### 3. Tell the application

- **Immich, Miniflux**: nothing to do. immich-server mounts
  `immich_db_password`; Miniflux's DSN is rebuilt from the same vault variable.
- **Nextcloud**: the credential lives only in `config.php`, and `occ` cannot
  change it here (it fails with `Access denied for user 'nextcloud'` before
  running any command). Edit the file from the deployed secret:

  ```bash
  ssh homelab 'sudo python3' <<'REMOTE'
  import re, shutil, pathlib
  cfg = pathlib.Path('/mnt/data/services/nextcloud/data/config/config.php')
  pw  = pathlib.Path('/mnt/data/secrets/docker/nextcloud_db_password').read_text().strip()
  assert pw, "empty secret, aborting"
  shutil.copy2(cfg, str(cfg) + '.bak')
  esc = pw.replace('\\', '\\\\').replace("'", "\\'")
  new, n = re.subn(r"('dbpassword'\s*=>\s*)'(?:\\.|[^'\\])*'",
                   lambda m: m.group(1) + "'" + esc + "'",
                   cfg.read_text(), count=1)
  assert n == 1, f"expected exactly one dbpassword line, found {n}"
  cfg.write_text(new)
  print("replacements:", n)
  REMOTE
  ```

  It keeps owner and mode, and writes only if exactly one line matches. Check
  the result (a broken `config.php` means Nextcloud will not start):

  ```bash
  ssh homelab "docker exec -u www-data nextcloud php -l /var/www/html/config/config.php
               docker exec -u www-data nextcloud php occ status --output=json"
  ```

  Then restart `nextcloud-notify-push`, which holds the old connection
  (self-test otherwise reports `push server can't load mount info from database`):

  ```bash
  ssh homelab "docker restart nextcloud-notify-push"
  ssh homelab "docker exec -u www-data nextcloud php occ notify_push:self-test"
  ```

⚠️ Suppress the output of any command that touches a secret:
`occ config:system:set` without `-q` prints the password.

⚠️ Never do step 1 without step 2: the deploy succeeds, the handler restarts the
database, and the service is broken until the posture check reports it next
morning.

## Rotating the Vaultwarden admin token

`config.json` overrides the environment, and the admin panel rewrites it in full
on every save. A new hash in the secret does nothing while `config.json` holds
`admin_token`.

1. Change the token through the admin panel, or remove the `admin_token` key
   from `config.json` so the environment takes over.
2. Restart Vaultwarden.

The daily posture check reports `config.json overrides compose [admin_token]`
when the two disagree.

## The acceptance test

The daily posture check (`homelab-posture.service`) proves a rotation landed. It
asserts each secret file still opens its database, and that Miniflux's DSN
matches the database secret. Postgres probes use the container name, because
over 127.0.0.1 `pg_hba.conf` trusts any password; MariaDB's probe uses 127.0.0.1.

Run it now:

```bash
sudo systemctl start homelab-posture.service
sudo journalctl -u homelab-posture.service -n 20 --no-pager
```

- **Pass**: the journal shows only systemd and PAM lines; the Kuma "Pi security
  posture" beat reads `posture OK — N checks (…)`.
- **Fail**: the journal shows `<container>: /run/secrets/<name> no longer opens
  the database`, and the beat turns red.
