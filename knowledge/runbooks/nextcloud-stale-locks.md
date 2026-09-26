# A file has silently stopped syncing (stale Nextcloud lock)

Use this page when `nextcloud.log` grows by tens of MB a day, a WebDAV client
(rclone, desktop) retries one file forever, or `Sabre\DAV\Exception\Locked` fills
the log on one path. Every monitor stays green.

## Before you start

The usual cause: the Nextcloud mobile app locks a `.md` note it opens (`Text`
lock), and killing the app from the task switcher skips the release.

## Steps

1. Find the path filling the log:
   ```bash
   sudo tail -500 /mnt/data/services/nextcloud/data/data/nextcloud.log \
     | python3 -c 'import sys,json,collections
   c=collections.Counter()
   for l in sys.stdin:
       try: d=json.loads(l)
       except: continue
       c[(d.get("method"), d.get("url"), (d.get("userAgent") or "")[:20])]+=1
   for k,v in c.most_common(3): print(v,k)'
   ```
2. List the locks (the password stays inside the container). A `ttl` of `-60`
   never expires. They are database rows: Redis will be empty.
   ```bash
   docker exec -i nextcloud-db sh -c \
     'MYSQL_PWD=$(cat /run/secrets/nextcloud_db_password) mariadb -u"$MYSQL_USER" "$MYSQL_DATABASE"' <<'SQL'
     SELECT l.id, l.file_id, from_unixtime(l.creation) AS placed, l.ttl, l.owner, f.path
     FROM oc_files_lock l LEFT JOIN oc_filecache f ON f.fileid = l.file_id
     ORDER BY l.creation;
   SQL
   ```
3. Release it, naming the **file owner** (`admin`), not the lock owner (`Text`):
   ```bash
   sudo docker exec -u www-data nextcloud php occ files:lock <file_id> --status
   sudo docker exec -u www-data nextcloud php occ files:lock <file_id> admin --unlock
   ```
   The client resumes on its own.

## Check it worked

The lock is gone from step 2, and the expiry is armed (expect `60`, set by
`nextcloud_lock_timeout_minutes`; `-1` or empty means locks never expire):

```bash
sudo docker exec -u www-data nextcloud php occ config:app:get files_lock lock_timeout
```

## If it fails

- `Backends provided no user object` → you passed the lock owner; pass `admin`.
- rclone still silent → it backs off; the next try can be ten minutes away.
- Lock comes back → the app was killed on an open note again; it expires within an hour.

Related: [feed-digest.md](feed-digest.md) (writes into the same vault),
[notify-push-troubleshooting.md](notify-push-troubleshooting.md) (the other
all-green Nextcloud failure).
