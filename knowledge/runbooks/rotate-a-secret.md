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

Three moving parts, and the order matters. Postgres and MariaDB differ only in
the `ALTER` statement.

**1. Change it in the database itself**, which is the step the deploy cannot do.

```bash
# Postgres (immich-db, miniflux-db)
docker exec -it immich-db psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
  -c "ALTER USER \"$POSTGRES_USER\" WITH PASSWORD 'the-new-one'"

# MariaDB (nextcloud-db)
docker exec -it nextcloud-db mariadb -u root -p \
  -e "ALTER USER 'nextcloud'@'%' IDENTIFIED BY 'the-new-one'"
```

**2. Put the same value in the vaulted `local.yml`** and deploy, so the secret
file on disk matches. This is what a future re-initialisation would use, and
what the daily posture check compares against.

```bash
ansible-playbook playbooks/site.yml --tags deploy -e deploy_services=<svc> --ask-vault-pass
```

**3. Tell the application**, because for two of the three the connection string
lives somewhere else:

- **Nextcloud** keeps `dbpassword` in `config.php`
  (`/mnt/data/services/nextcloud/data/config/config.php` on the host). The
  compose file deliberately passes no `MYSQL_*` to the app, so nothing else
  carries it.
  ```bash
  docker exec -u www-data nextcloud php occ config:system:set dbpassword --value 'the-new-one'
  ```
- **Miniflux** takes a whole DSN, `miniflux_database_url`, which contains the
  password. Step 2 rewrites it from the same variable, so it follows
  automatically — but only if you changed `miniflux_db_password` and not the DSN
  by hand.
- **Immich** reads `immich_db_password` directly, so step 2 covers it.

**Do not** do step 2 without step 1. The deploy will report success, the
handler will restart the database, and the credential in the file will no longer
open it — which the posture check will report the next morning, but the service
will have been broken since the restart.

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
