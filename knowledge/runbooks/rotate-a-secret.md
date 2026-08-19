# Rotating a secret

Writing a new value into the vault and running a deploy rotates **some** of the
secrets in this lab. For others it produces a `changed` task, a handler that
visibly restarts the service, and the old credential still in force. This page
says which is which, and what the second kind needs instead.

The trap is recent and self-inflicted. Before 2026-08-16 a rotation of those
secrets silently did nothing. On that day eleven Docker secrets gained restart
handlers, which was correct — a rotated credential the running container never
re-reads is a real defect, and one of them had run 17 h 44 on a stale key. But
for four secrets the restart cannot rotate anything, so the evidence of work got
stronger while the operation stayed impossible (#159).

## Which is which

| Secret | Consumer | Does a deploy rotate it? |
|--------|----------|--------------------------|
| `cf_dns_api_token` | traefik | **yes** — lego re-reads the file on every ACME operation |
| `transmission_password` | transmission | **yes** — read at start |
| `dozzle_users.yml` | dozzle | **yes** — read at start |
| `forgejo_secret_key` | forgejo | **yes**, but see the warning below |
| `miniflux_database_url` | miniflux | **yes** — but on its own it breaks the app; see the database procedure |
| `vaultwarden_admin_token_hash` | vaultwarden | **no** — `config.json` overrides the environment |
| `nextcloud_db_password` | nextcloud-db + config.php | **no** — `initdb` only |
| `nextcloud_db_root_password` | nextcloud-db | **no** — `initdb` only |
| `immich_db_password` | immich-db + immich-server | **no** — `initdb` only |
| `miniflux_db_password` | miniflux-db | **no** — `initdb` only |
| `miniflux_admin_password` | miniflux | **no** — `CREATE_ADMIN` runs once |
| `forgejo_admin_password` | forgejo CLI | **no** — first deploy only, and it has no handler for that reason |

### Why the database ones cannot work

`POSTGRES_PASSWORD_FILE` and `MYSQL_PASSWORD_FILE` are read by the image
entrypoint during `initdb` and never again. Every later start says so:

```bash
docker logs immich-db   | grep -i "skipping initialization"
docker logs miniflux-db | grep -i "skipping initialization"
```

MariaDB says it differently — `[Entrypoint]: MariaDB upgrade not required`,
with no initialisation step — but behaves the same way.

### Warning about `forgejo_secret_key`

It **is** re-read at every start, so a deploy applies it. That does not make it
safe to rotate: it encrypts data at rest in the forge. Rotate it only on an
instance whose data you are prepared to lose, or after checking what depends on
it.

## Rotating a database password

Three moving parts, and the order is the opposite of the intuitive one.

**Deploy the new value first, change the database second.** Doing it the other
way round means typing the password into a shell command, and that is a trap
this runbook was written *into* on 2026-08-19: a `$` in the password was expanded
by the local shell before `ssh` ever saw it, so the database received a truncated
variant while every file on the Pi held the right one. Miniflux spent twenty
minutes unable to authenticate. Deploying first puts the value on the Pi, in the
secret file, where the next step can read it without it passing through a shell
at all.

Both orders break the service for the same short window — the moment the
application and the database disagree — so run the two steps back to back.

### 1. Vault, then deploy

```bash
ansible-vault edit inventory/host_vars/homelab/local.yml --ask-vault-pass
```

**Check that the edit actually saved before deploying.** `ansible-vault edit`
re-encrypts only if the file changed, so leaving the editor without writing
leaves everything as it was and says nothing about it. This prints the length
and not the value:

```bash
ansible-vault view inventory/host_vars/homelab/local.yml --ask-vault-pass \
  | sed -n "s/^immich_db_password: *//p" | tr -d "\"'" | awk '{print "length:", length($0)}'
```

```bash
ansible-playbook playbooks/site.yml --tags deploy -e deploy_services=<svc> --ask-vault-pass
```

### 2. Change it in the database, reading the file the deploy just wrote

Quoted here-doc (`<<'REMOTE'`), so the local shell touches nothing and the
password is never an argument to anything you type.

Postgres — `immich-db`, `miniflux-db`:

```bash
ssh homelab 'docker exec -i immich-db sh' <<'REMOTE'
PW=$(cat /run/secrets/immich_db_password)
[ -n "$PW" ] || { echo "empty secret, aborting"; exit 1; }
ESC=$(printf '%s' "$PW" | sed "s/'/''/g")
psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "ALTER USER \"$POSTGRES_USER\" WITH PASSWORD '$ESC'"
REMOTE
```

`psql -c` does **not** interpolate psql variables, so the obvious `-v pw=… -c
"… PASSWORD :'pw'"` fails with a syntax error — measured. The literal is built in
the shell instead, with single quotes doubled.

MariaDB — `nextcloud-db`:

```bash
ssh homelab 'docker exec -i nextcloud-db sh' <<'REMOTE'
PW=$(cat /run/secrets/nextcloud_db_password)
RP=$(cat /run/secrets/nextcloud_db_root_password)
[ -n "$PW" ] && [ -n "$RP" ] || { echo "empty secret, aborting"; exit 1; }
MYSQL_PWD="$RP" mariadb -u root -N -e "ALTER USER '$MYSQL_USER'@'%' IDENTIFIED BY '$PW'"
REMOTE
```

Both forms were run against the live databases with the value already in force —
a no-op that proves the quoting.

### 3. Tell the application

- **Immich** and **Miniflux** need nothing. immich-server mounts
  `immich_db_password` directly; Miniflux's DSN is rebuilt from the same vault
  variable by step 1, so it follows automatically.
- **Nextcloud** does need it, and `occ` cannot do it. The compose file
  deliberately passes the app no `MYSQL_*`, so its credential lives in
  `config.php` and nothing else carries it — but `occ` bootstraps a database
  connection before running any command, so at this point in the procedure it
  fails with `Access denied for user 'nextcloud'`. Measured on 2026-08-19:
  `occ config:system:set dbpassword` is unusable in the exact situation it would
  be needed. The file is edited directly instead, from the deployed secret.

  ```bash
  ssh homelab 'sudo python3' <<'REMOTE'
  import re, shutil, pathlib
  cfg = pathlib.Path('/mnt/data/services/nextcloud/data/config/config.php')
  pw  = pathlib.Path('/mnt/data/secrets/docker/nextcloud_db_password').read_text().strip()
  assert pw, "empty secret, aborting"
  shutil.copy2(cfg, str(cfg) + '.bak')
  esc = pw.replace('\\', '\\\\').replace("'", "\\'")   # PHP single-quoted string
  new, n = re.subn(r"('dbpassword'\s*=>\s*)'(?:\\.|[^'\\])*'",
                   lambda m: m.group(1) + "'" + esc + "'",
                   cfg.read_text(), count=1)
  assert n == 1, f"expected exactly one dbpassword line, found {n}"
  cfg.write_text(new)
  print("replacements:", n)
  REMOTE
  ```

  It writes through the existing inode, so owner and mode are preserved, and it
  refuses to guess: exactly one match or nothing is written. Check the result
  before moving on — a broken `config.php` is a Nextcloud that will not start:

  ```bash
  ssh homelab "docker exec -u www-data nextcloud php -l /var/www/html/config/config.php
               docker exec -u www-data nextcloud php occ status --output=json"
  ```

  Then **restart `nextcloud-notify-push`**. It reads `config.php` once at start
  and holds the connection, so it survives the rotation in a state where
  `occ notify_push:self-test` reports `push server can't load mount info from
  database` while every other line passes.

  ```bash
  ssh homelab "docker restart nextcloud-notify-push"
  ssh homelab "docker exec -u www-data nextcloud php occ notify_push:self-test"
  ```

  Had `occ -q config:system:set` been usable, the `-q` would still have mattered:
  without it the command prints `System config value dbpassword set to string
  <the password>`, which is how that credential ended up in a terminal
  transcript on 2026-08-19 and had to be rotated for that reason alone. Any
  command that touches a secret gets its output suppressed, whether or not you
  expect it to print one.

**Do not** do step 1 without step 2. The deploy reports success, the handler
restarts the database, and the credential in the file no longer opens it — which
the posture check reports the next morning, but the service has been broken
since the restart.

## Rotating the Vaultwarden admin token

`config.json` takes precedence over the environment, and the admin panel
rewrites that file in full whenever it is saved. So a new hash in the secret is
inert while `admin_token` sits in `config.json` holding the old one.

Change it through the admin panel, or remove the `admin_token` key from
`config.json` so the environment takes over again, and restart. The daily
posture check compares the two and reports `config.json overrides compose
[admin_token]` when they disagree — before #159 it compared nothing at all,
because compose injects `ADMIN_TOKEN_FILE` while the file holds `admin_token`.

## The acceptance test

The daily posture check (`homelab-posture.service`) is the proof that a rotation
landed. It asserts that the password in each secret file still opens its
database, addressing the server **by container name** rather than the loopback —
`initdb` writes `host all all 127.0.0.1/32 trust` into `pg_hba.conf`, so over
127.0.0.1 Postgres accepts any password at all. It also compares Miniflux's DSN
against the database's own secret, since those two can drift apart without
either side noticing until the next restart.

To see the verdict without waiting for the timer:

```bash
sudo systemctl start homelab-posture.service
sudo journalctl -u homelab-posture.service -n 20 --no-pager
```

A clean run pushes `posture OK on N/N containers`. A failed rotation shows up as
`<container>: /run/secrets/<name> no longer opens the database`.
