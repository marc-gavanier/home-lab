# Runbook — Restore from backup (Restic)

Use this page to get files, a service, a database or the whole host back from the
local Restic repository. Last tested 2026-08-15 (see [Drill record](#drill-record)).

What the backup covers: [`docs/06-backup/README.md`](../../docs/06-backup/README.md).
When the homelab itself is lost, start with *Disaster recovery* in
[`offsite-backup.md`](offsite-backup.md).

## Before you start

Rules that apply to every procedure on this page:

- **Stage in `/mnt/data/tmp/restore`, never `/tmp`.** `/tmp` is a 1 GiB RAM disk
  (`tmpfs size=1048576k`); the Immich dumps alone are about 595 MiB. `/mnt/data/tmp`
  is not cleared at reboot, so delete the scratch directory when you are done.
- **Delete `/mnt/data/tmp/restore` before every `restic restore`, even if you think
  it is empty.** Restic does not remove files the snapshot lacks, so a second restore
  into the same tree mixes two snapshots — and the `rsync -a --delete` steps below
  then copy that mix into production. An interrupted, restarted restore is the usual
  way this happens.
- **`docker compose down <service>`, never `docker stop`.** The heal timer restarts,
  every two minutes, any container that exited non-zero, is `created` or `dead`, or
  has been unhealthy for 15 minutes (ADR-007). `down` removes the container from its view.
- **`<service>` is the compose service name.** It matches the container name
  everywhere except `immich-machine-learning` (container `immich-ml`).
- **An `--include` that matches nothing restores zero files and exits 0.** No
  output means nothing was restored. Check the path with `restic ls` first.
- Run `ansible-playbook playbooks/site.yml --tags storage --ask-vault-pass` after every restore: see
  [Ownership after a restore](#ownership-after-a-restore).

Open the repository, as root on the Pi:

```bash
sudo -i
set -a; . /opt/homelab/backup.env; set +a
export HOME=/root
restic snapshots
```

Expected: a list of snapshots, the newest from last night's 03:00 run or from a later manual run.

## Restore a single file or folder

1. Find the exact path in the snapshot. The listing is not recursive: one line per
   album, named `YYYY-MM-DD - Title`.

   ```bash
   restic ls latest /mnt/data/media/photos | grep -F 2019-08-15
   ```

2. Restore into staging, then copy out what you need:

   ```bash
   sudo rm -rf /mnt/data/tmp/restore
   restic restore latest --target /mnt/data/tmp/restore --include /mnt/data/services/vaultwarden
   ```

   Or restore in place. This **overwrites** existing files:

   ```bash
   restic restore latest --target / --include "/mnt/data/media/photos/2019-08-15 - Bretagne"
   ```

3. Check it worked: restic reported restored files. No output means the path matched
   nothing — go back to step 1.

## Restore one service

```bash
cd /opt/homelab
docker compose down <service>
restic restore latest --target / --include /mnt/data/services/<service>
docker compose up -d <service>
```

Each service's own doc lists its exact path.

**This is not a complete restore for a service with a database, and it exits 0
either way.** The live database directories are excluded from the snapshot (the
dump is the consistent copy):

| `--include` path       | What comes back                          | Then also do                                                  |
|------------------------|------------------------------------------|---------------------------------------------------------------|
| `services/miniflux`    | the empty directory only                 | [Restore Miniflux](#restore-miniflux-postgresql)              |
| `services/nextcloud`   | `data/` (web root + user files), no `db` | [Restore a database](#restore-a-database)                     |
| `services/immich`      | `upload/`, `ml-cache`, no `db`           | [Restore Immich](#restore-immich-postgresql--vectorchord--pgvectors) |
| `services/uptime-kuma` | the directory, no `kuma.db`              | [Restore Uptime Kuma](#restore-uptime-kuma-sqlite)            |
| `services/pihole`      | config, gravity, lists, no query history | nothing: it rebuilds                                          |
| `services/netdata`     | config, no `cache/`                      | nothing: it regenerates                                       |

For Vaultwarden, Forgejo, wg-easy, Sonarr, Radarr and Prowlarr the command does
restore a `.db`, but it is the **live** file, possibly with committed transactions
still in its `-wal`. Use the dump instead: each has its own section below.

## Ownership after a restore

Run this **after every restore**. Restic returns the ownership and modes the files
had in the snapshot, not what the current configuration expects.

These containers run as uid 999 with no `CHOWN` capability (ADR-017), so they
cannot fix their own data directory:

| Service           | Data directory                      |
|-------------------|-------------------------------------|
| `nextcloud-db`    | `/mnt/data/services/nextcloud/db`   |
| `immich-db`       | `/mnt/data/services/immich/db`      |
| `miniflux-db`     | `/mnt/data/services/miniflux/db`    |
| `nextcloud-redis` | none (no bind mount)                |
| `immich-redis`    | `/mnt/data/services/immich/redis`   |

A directory recreated by hand (`mkdir`, `cp -r`, `rsync` without `-a`) ends up owned
by root: Postgres then refuses to start ("data directory has wrong ownership") and
MariaDB fails on its first write. Fix it by hand:

```bash
chown -R 999:999 /mnt/data/services/nextcloud/db /mnt/data/services/immich/db /mnt/data/services/miniflux/db /mnt/data/services/immich/redis
chmod 700        /mnt/data/services/nextcloud/db /mnt/data/services/immich/db /mnt/data/services/miniflux/db /mnt/data/services/immich/redis
```

Or let Ansible do it, from `ansible/`:

```bash
ansible-playbook playbooks/site.yml --tags storage --ask-vault-pass
```

`--tags storage` owns the three database directories; `immich/redis` belongs to the
`deploy` role (`--tags deploy`).

`nextcloud-cron` runs as root; it needs nothing.

## Restore a database

The dumps live in `/mnt/data/backups/dumps/`. They are deleted from disk after each
successful run (a failed run leaves them, and then they are the newest copy), so
normally you restore them from a snapshot first.

Ten databases are dumped. Nextcloud is restored here; every other one needs more than
an import and has its own section:

| Database                           | Section                                                                          |
|------------------------------------|----------------------------------------------------------------------------------|
| Vaultwarden (SQLite)               | [Restore Vaultwarden](#restore-vaultwarden-sqlite)                               |
| Immich (PostgreSQL)                | [Restore Immich](#restore-immich-postgresql--vectorchord--pgvectors)             |
| Miniflux (PostgreSQL)              | [Restore Miniflux](#restore-miniflux-postgresql)                                 |
| Forgejo (SQLite)                   | [Restore Forgejo](#restore-forgejo-sqlite)                                       |
| Uptime Kuma (SQLite)               | [Restore Uptime Kuma](#restore-uptime-kuma-sqlite)                               |
| wg-easy (SQLite)                   | [Restore wg-easy](#restore-wg-easy-sqlite)                                       |
| Sonarr / Radarr / Prowlarr (SQLite) | [Restore Sonarr / Radarr / Prowlarr](#restore-sonarr--radarr--prowlarr-sqlite) |

A service missing from this table is not dumped: the snapshot holds only its files as
they were on disk.

Nextcloud (MariaDB), in maintenance mode:

```bash
sudo rm -rf /mnt/data/tmp/restore
restic restore latest --target /mnt/data/tmp/restore --include /mnt/data/backups/dumps

docker exec -u www-data nextcloud php occ maintenance:mode --on
docker exec -i nextcloud-db sh -c \
  'MYSQL_PWD=$(cat /run/secrets/nextcloud_db_password) mariadb -u"$MYSQL_USER" "$MYSQL_DATABASE"' \
  < /mnt/data/tmp/restore/mnt/data/backups/dumps/nextcloud.sql
docker exec -u www-data nextcloud php occ upgrade
docker exec -u www-data nextcloud php occ maintenance:data-fingerprint
docker exec -u www-data nextcloud php occ maintenance:mode --off
docker exec -u www-data nextcloud php occ files:scan --all
```

- `upgrade` replays the migrations a dump older than the image misses; it says
  "already latest version" otherwise. The container does not run it: `version.php`
  did not change.
- `data-fingerprint` tells the sync clients the server went back in time. Without
  it they treat the server as authoritative and delete, on the desktop, every file
  created since the dump.
- `files:scan` re-indexes the files still on disk that the older dump does not list.

## Restore Vaultwarden (SQLite)

Restore the dump `vaultwarden.sqlite3`, not the live `db.sqlite3`, which can carry a
torn WAL. Attachments, sends and RSA keys sit beside the database in
`/mnt/data/services/vaultwarden`, so the directory comes back first and the dump last.

1. Get the dumps and the service directory:

   ```bash
   sudo rm -rf /mnt/data/tmp/restore
   restic restore latest --target /mnt/data/tmp/restore \
     --include /mnt/data/backups/dumps \
     --include /mnt/data/services/vaultwarden
   ```

2. Stop the service:

   ```bash
   cd /opt/homelab
   docker compose down vaultwarden
   ```

3. Restore attachments, sends and keys (skip if only the database was lost):

   ```bash
   rsync -a --delete /mnt/data/tmp/restore/mnt/data/services/vaultwarden/ /mnt/data/services/vaultwarden/
   ```

4. Drop the WAL/SHM, copy the dump over the database, start:

   ```bash
   rm -f /mnt/data/services/vaultwarden/db.sqlite3-wal /mnt/data/services/vaultwarden/db.sqlite3-shm
   cp /mnt/data/tmp/restore/mnt/data/backups/dumps/vaultwarden.sqlite3 \
      /mnt/data/services/vaultwarden/db.sqlite3
   docker compose up -d vaultwarden
   ```

## Restore Immich (PostgreSQL — VectorChord / pgvecto.rs)

Immich writes its own DB dump (Admin → Settings → Backup) to
`/mnt/data/services/immich/upload/backups/*.sql.gz`, which is in the snapshot.
The datadir is not: the dump is the **only** copy.

### Before you start

- **Never `docker compose down -v`.** The stack is one shared `compose.yaml`; `-v`
  targets every service's volumes. Reset only the Immich DB directory.
- The dump must load into a **fresh** database, through the `search_path` `sed`
  transform (mandatory for the vector extensions).
- `--single-transaction --set ON_ERROR_STOP=on` stops on a SQL error but **not** on a
  truncated input: psql can commit a partial table and exit 0. That is why step 2
  tests the file, and why steps 4 and 6 are gated on its result — a pasted block
  cannot then delete or overwrite the live database with a bad dump.

### Steps

1. Pick the newest dump, from disk or from a snapshot. Use `sudo sh -c`, not
   `sudo ls`: the directory is `0700 root`, so your own shell cannot expand the glob
   and you get "no matches".

   ```bash
   sudo rm -rf /mnt/data/tmp/restore
   restic restore latest --target /mnt/data/tmp/restore \
     --include /mnt/data/services/immich/upload/backups
   DUMP=$(sudo sh -c 'ls -t /mnt/data/services/immich/upload/backups/*.sql.gz' | head -1)
   ```

   Or, from the restored copy:

   ```bash
   DUMP=$(sudo sh -c 'ls -t /mnt/data/tmp/restore/mnt/data/services/immich/upload/backups/*.sql.gz' | head -1)
   ```

2. Prove the dump is complete (`sudo`: an unprivileged `gzip -t` fails with
   "permission denied", which looks like corruption):

   ```bash
   sudo gzip -t "$DUMP" && DUMP_OK=yes || DUMP_OK=no
   echo "dump integrity: $DUMP_OK  ($DUMP)"
   ```

   Expected: `dump integrity: yes`. If `no`, stop here.

3. Record the current asset count, to compare after the restore:

   ```bash
   BEFORE_ASSETS=$(docker exec immich-db psql -U immich -d immich -tAc \
     'select count(*) from asset;' 2>/dev/null || echo unknown)
   echo "asset rows before restore: $BEFORE_ASSETS"
   ```

4. Remove the Immich containers and empty the DB directory, so the container re-runs
   `initdb`:

   ```bash
   cd /opt/homelab
   [ "$DUMP_OK" = yes ] && docker compose down immich-server immich-machine-learning immich-db immich-redis
   [ "$DUMP_OK" = yes ] && rm -rf /mnt/data/services/immich/db/*
   ```

5. Start the empty database and wait for it:

   ```bash
   docker compose up -d immich-db
   until [ "$(docker inspect -f '{{.State.Health.Status}}' immich-db)" = healthy ]; do sleep 2; done
   ```

6. Load the dump:

   ```bash
   [ "$DUMP_OK" = yes ] && sudo gunzip --stdout "$DUMP" \
   | sed "s/SELECT pg_catalog.set_config('search_path', '', false);/SELECT pg_catalog.set_config('search_path', 'public, pg_catalog', true);/g" \
   | docker exec -i immich-db psql \
       --dbname=immich --username=immich \
       --single-transaction --set ON_ERROR_STOP=on
   ```

7. Start the rest:

   ```bash
   docker compose up -d immich-server immich-machine-learning immich-redis
   ```

### Check it worked

Count first — a partial database still shows a working timeline:

```bash
docker exec immich-db psql -U immich -d immich -tAc 'select count(*) from asset;'
docker exec immich-db psql -U immich -d immich -tAc \
  "select count(*) from information_schema.tables where table_schema='public';"
```

Expected: the asset count matches `$BEFORE_ASSETS`. If the old database was already
gone, compare with the 2026-07-19 drill: 66 tables, 9 283 assets. Then log in and
check the timeline and search.

The photos and videos themselves are in `services/immich/upload` and `media/photos`:
restore those too if they were lost.

## Restore Miniflux (PostgreSQL)

Restore the dump `miniflux.sql`. The datadir `services/miniflux/db` is excluded from
the snapshot. The dump has no `--clean`, so it loads into a fresh database.

1. Get the dumps:

   ```bash
   sudo rm -rf /mnt/data/tmp/restore
   restic restore latest --target /mnt/data/tmp/restore --include /mnt/data/backups/dumps
   ```

2. Check the dump ends the way `pg_dump` output ends (ON_ERROR_STOP does not catch a
   truncated file):

   ```bash
   tail -c 200 /mnt/data/tmp/restore/mnt/data/backups/dumps/miniflux.sql
   ```

3. Remove both containers, so nothing writes during the load:

   ```bash
   cd /opt/homelab
   docker compose down miniflux miniflux-db
   ```

4. Empty the datadir so the entrypoint re-runs `initdb`. Clear the parent, not
   `db/18/docker`: Postgres 18 keeps PGDATA one level below the mount.

   ```bash
   rm -rf /mnt/data/services/miniflux/db/*
   ```

5. Start the empty database and wait for it:

   ```bash
   docker compose up -d miniflux-db
   until [ "$(docker inspect -f '{{.State.Health.Status}}' miniflux-db)" = healthy ]; do sleep 2; done
   ```

6. Load the dump:

   ```bash
   docker exec -i miniflux-db psql \
       --dbname=miniflux --username=miniflux \
       --single-transaction --set ON_ERROR_STOP=on \
     < /mnt/data/tmp/restore/mnt/data/backups/dumps/miniflux.sql
   ```

7. Start the reader:

   ```bash
   docker compose up -d miniflux
   ```

Role and database are both `miniflux` unless `miniflux_db_user` / `miniflux_db_name`
are overridden in `local.yml`.

Check it worked: count entries, then log in at `https://rss.<domain>` and check the
feed list and unread counts. Miniflux keeps all its state in Postgres; nothing else
to restore.

```bash
docker exec miniflux-db psql -U miniflux -d miniflux -tAc 'select count(*) from entries;'
```

## Restore Forgejo (SQLite)

Restore both halves: the database (`forgejo.sqlite3` dump: users, repository list,
mirror settings) and the repositories (files under
`services/forgejo/data/git/repositories`). One without the other gives a forge that
lists repositories it cannot serve, or the reverse.

1. Get the dumps and the service directory:

   ```bash
   sudo rm -rf /mnt/data/tmp/restore
   restic restore latest --target /mnt/data/tmp/restore \
     --include /mnt/data/backups/dumps \
     --include /mnt/data/services/forgejo
   ```

2. Stop the service:

   ```bash
   cd /opt/homelab
   docker compose down forgejo
   ```

3. Restore repositories and config (skip if only the database was lost):

   ```bash
   rsync -a --delete /mnt/data/tmp/restore/mnt/data/services/forgejo/ /mnt/data/services/forgejo/
   ```

4. Restore the database. `data/data` is the rootless layout, not a typo.

   ```bash
   rm -f /mnt/data/services/forgejo/data/data/forgejo.db-wal \
         /mnt/data/services/forgejo/data/data/forgejo.db-shm
   cp /mnt/data/tmp/restore/mnt/data/backups/dumps/forgejo.sqlite3 \
      /mnt/data/services/forgejo/data/data/forgejo.db
   ```

5. Fix ownership (`git` is uid 1000 in the rootless image) and start:

   ```bash
   chown -R 1000:1000 /mnt/data/services/forgejo
   docker compose up -d forgejo
   ```

Check it worked: log in at `https://git.<domain>`, then Repository → Settings →
Mirror Settings → *Synchronize Now*. Only git objects come back: the mirror is
tokenless (ADR-028), so issues and pull requests were never mirrored.

## Restore Uptime Kuma (SQLite)

Restore it **early**: every dead-man's switch ends in a Kuma push monitor, so nothing
watches the recovery until Kuma is back. The database is the only copy of the
monitors (Kuma v2 has no config export).

1. Get the dumps and the service directory **from the same snapshot**. The push
   tokens are in the database; an older database than the config leaves every push
   monitor silently DOWN.

   ```bash
   sudo rm -rf /mnt/data/tmp/restore
   restic restore latest --target /mnt/data/tmp/restore \
     --include /mnt/data/backups/dumps \
     --include /mnt/data/services/uptime-kuma
   ```

2. Stop the service, drop the stale WAL/SHM, copy the dump in, start it:

   ```bash
   cd /opt/homelab
   docker compose down uptime-kuma
   rm -f /mnt/data/services/uptime-kuma/kuma.db-wal \
         /mnt/data/services/uptime-kuma/kuma.db-shm
   cp /mnt/data/tmp/restore/mnt/data/backups/dumps/uptime-kuma.sqlite3 \
      /mnt/data/services/uptime-kuma/kuma.db
   chown root:root /mnt/data/services/uptime-kuma/kuma.db
   docker compose up -d uptime-kuma
   ```

Check it worked: log in at `https://services.<domain>`, check the monitor count, and
check the notification channel is still attached (Settings → Notifications).

## Restore wg-easy (SQLite)

### Before you start

The tunnel is the only way into this Pi, into the offsite Pi, and into the unlock
itself (`/etc/wireguard/wg0.conf` links to `/mnt/data/secrets/wg0.conf`). A wrong
restore loses the way back in. Do it with someone able to reach the machine
physically, or accept that as the fallback.

- The store is `wg-easy.db`, **not** `wg0.json` beside it (the pre-v15 peer store).
  Using `wg0.json`, or leaving the database missing, rebuilds the wrong peers.
- `wg-easy.db` holds the peers wg-easy serves. The Pi's own tunnel config
  (`/mnt/data/secrets/wg0.conf`) comes back with the secrets, not with this database.
  You need both.

### Steps

1. Get the dumps:

   ```bash
   sudo rm -rf /mnt/data/tmp/restore
   restic restore latest --target /mnt/data/tmp/restore \
     --include /mnt/data/backups/dumps
   ```

2. Stop the service, drop the stale WAL/SHM, copy the dump in:

   ```bash
   cd /opt/homelab
   docker compose down wg-easy
   rm -f /mnt/data/services/wireguard/wg-easy.db-wal \
         /mnt/data/services/wireguard/wg-easy.db-shm
   cp /mnt/data/tmp/restore/mnt/data/backups/dumps/wg-easy.sqlite3 \
      /mnt/data/services/wireguard/wg-easy.db
   ```

3. Set ownership (the image runs as uid 0) and start:

   ```bash
   chown root:root /mnt/data/services/wireguard/wg-easy.db
   chmod 600 /mnt/data/services/wireguard/wg-easy.db
   docker compose up -d wg-easy
   ```

### Check it worked

Before closing the session you still have: `docker exec wg-easy wg show wg0 peers | wc -l`
matches the number of clients in the UI, and one client completes a handshake.

## Restore Sonarr / Radarr / Prowlarr (SQLite)

One procedure for the three. **Restore Prowlarr first**: Sonarr and Radarr get their
indexers from it.

- The database holds indexers, the series or film list, quality profiles, download
  history and root-folder paths.
- The API key is in `config.xml`, at `/mnt/data/services/$svc/config.xml` on the host
  (`/config/config.xml` only inside the container).
- The media is **not** backed up (`/mnt/data/library`, ADR-035): it is re-acquired
  from the lists in the database, not restored.
- A plain `--include services/<svc>` restores the live `.db`, possibly with
  transactions still in its `-wal`. Use the dump.

1. Choose the service and get the files:

   ```bash
   svc=sonarr
   sudo rm -rf /mnt/data/tmp/restore
   restic restore latest --target /mnt/data/tmp/restore \
     --include /mnt/data/backups/dumps \
     --include /mnt/data/services/$svc
   ```

   Set `svc` to `sonarr`, `radarr` or `prowlarr`.

2. Stop the service:

   ```bash
   cd /opt/homelab
   docker compose down $svc
   ```

3. Restore config and everything but the database, `config.xml` included (skip if
   only the database was lost):

   ```bash
   rsync -a --delete /mnt/data/tmp/restore/mnt/data/services/$svc/ /mnt/data/services/$svc/
   ```

4. Restore the database from the dump:

   ```bash
   rm -f /mnt/data/services/$svc/$svc.db-wal \
         /mnt/data/services/$svc/$svc.db-shm
   cp /mnt/data/tmp/restore/mnt/data/backups/dumps/$svc.sqlite3 \
      /mnt/data/services/$svc/$svc.db
   ```

5. Set ownership (PUID=1000 / PGID=1003) and a `0700` directory (it keeps the API key
   private), then start:

   ```bash
   chown -R 1000:1003 /mnt/data/services/$svc
   chmod 700 /mnt/data/services/$svc
   docker compose up -d $svc
   ```

Check it worked:

- **Prowlarr**: Indexers is populated and *Test All* passes.
- **Sonarr / Radarr**: the Series (or Movies) list is there, and Settings → Media
  Management shows the root folder as `/data/...`. A missing root folder means the
  directory is absent: recreate it and let the *arr re-acquire what it lists.
- **All three**: Settings → General → the API key matches what the reverse proxy and
  clients hold. A regenerated `config.xml` means a new key to give every client.

## Full disaster recovery

### Before you start

- Plan on **2 to 9 hours** for the 90.9 GiB snapshot of 2026-09-26; see [Drill record](#drill-record)
  for the rates and how to recompute it.
- **Disable the timers first.** The nightly backup `rm -rf`s
  `/mnt/data/backups/dumps` at its first step, even if it then fails, so a 03:00 run
  destroys the dumps step 2 restores — and step 3 finds an empty directory that looks
  like success. The heal timer restarts whatever crashes mid-restore.

  ```bash
  sudo systemctl disable --now homelab-backup.timer homelab-stack-heal.timer
  ```

### Steps

1. **Re-provision the OS.** Flash Ubuntu, then run **phase 1 only**, from `ansible/`.
   The full playbook would start the whole stack on empty data (fresh databases) and
   write secrets from `local.yml` that the restored ones then replace. The LUKS disk is
   passphrase-based and hardware-independent.

   ```bash
   ansible-playbook playbooks/site.yml --tags phase1 --ask-vault-pass
   ```

2. **Restore the data.** Point Restic at the local repo, or at the offsite one
   ([`offsite-backup.md`](offsite-backup.md)). Secrets first, on their own:
   `/opt/homelab` holds symlinks into `/mnt/data/secrets` (ADR-011). This path does
   not need `local.yml` (gitignored, not backed up), and it brings back `wg0.conf`,
   so the tunnel. The dumps exist only in the snapshot, and step 3 needs them.

   ```bash
   restic restore latest --target / --include /mnt/data/secrets
   restic restore latest --target / \
     --include /opt/homelab \
     --include /mnt/data/services \
     --include /mnt/data/media \
     --include /mnt/data/backups/dumps
   ```

3. **Import the DB dumps** (sections above), then bring services up with the rest of
   the playbook. This is the first step that should start any container.

   ```bash
   ansible-playbook playbooks/site.yml --ask-vault-pass
   ```

   > ⚠️ **This order cannot be followed as written, and the fix is untested.**
   > The imports above `docker exec` into `nextcloud-db`, `immich-db` and the
   > other database containers, which nothing has started at this point. The
   > likely order is: start only the database containers, let them initialise,
   > import, then run the full playbook. It has never been run on the Pi — treat
   > it as a lead, not a procedure, and check each database before going on.

4. **Sanity-check services.** Check that the Nextcloud import ran `upgrade` and
   `maintenance:data-fingerprint` ([Restore a database](#restore-a-database)) before any
   desktop client reconnects. Run the [ownership fix](#ownership-after-a-restore).

5. **Re-enable the timers** and check they are armed, not just enabled:

   ```bash
   sudo systemctl enable --now homelab-backup.timer homelab-stack-heal.timer
   systemctl list-timers homelab-backup.timer homelab-stack-heal.timer
   ```

   Expected: both show a next run. Until they do, the host has no backups, and the
   "Pi security posture" monitor goes red at its next run.

## Verify a backup without restoring

```bash
restic check
restic snapshots --latest 1
```

Expected: no errors, and a snapshot from last night.

To see every snapshot that exists — older ones survive the retention policy (see
[the backup README](../../docs/06-backup/README.md#retention)), so ask the repository,
not the policy. The `-c` is required: without it resticprofile fails with
"configuration file 'profiles' … was not found".

```bash
sudo -i
set -a; . /opt/homelab/backup.env; set +a
resticprofile -c /opt/homelab/resticprofile.yaml -n homelab snapshots --compact
```

## Drill record

Every drill verifies by **loading** the data, never by listing it.

| Date       | Source                                                     | Result                                                                                                                                                             |
|------------|------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 2026-08-15 | Offsite repo, on site with the tunnel down, and through it | Same 22.819 MiB both ways. `vaultwarden.sqlite3`: integrity ok, 1 user, 591 ciphers. `forgejo.sqlite3`: ok, 1 repo, 1 user. `nextcloud.sql`: 168 tables.          |
| 2026-07-27 | Offsite repo, through the tunnel                           | `vaultwarden.sqlite3`: ok, 587 ciphers. Nextcloud datadir started MariaDB under the hardened config (18 899 filecache rows); the SQL dump gave the same counts.   |
| 2026-07-19 | Local                                                      | Immich dump into a throwaway VectorChord postgres: 66 tables, 9 283 `asset`, 9 247 `smart_search`. Vaultwarden `.backup`: integrity ok. Local prune+check timer run. |
| 2026-07-11 | Local                                                      | `restic check --read-data-subset=2%`, Vaultwarden scratch restore, Nextcloud dump into a throwaway MariaDB (156 tables).                                         |

Full-restore duration through the tunnel, for the 90.9 GiB / 95 440-file snapshot of
2026-09-26 (the rates were measured when it held 343 GiB):

| Rate       | Source                                   | Time   |
|------------|------------------------------------------|--------|
| 13.5 MiB/s | burst, small files                       | ~1.9 h |
| 3.13 MB/s  | sustained nightly tunnel rate, 7 nights  | ~8.7 h |

The current size is the last `scan finished … GiB` line of
`journalctl -u homelab-backup`; divide it by both rates.

To narrow it on the day: restore one large directory first, time it, and
extrapolate from that.

At each drill, re-verify that the offsite repo password can be reached from at least
two independent places outside the homelab, one of them with no network and no other
secret. That path breaks silently.

**Next drill: 2027-07** (annual). Bring it forward if the storage layout, the uid
model or the repository backend changes.

See also: [`docs/06-backup/README.md`](../../docs/06-backup/README.md),
[`backup-monitoring.md`](backup-monitoring.md).
