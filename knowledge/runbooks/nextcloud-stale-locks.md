# A file has silently stopped syncing (stale Nextcloud lock)

The symptom never points at the cause. What you notice is a log growing fast, or
a client retrying forever. What is actually wrong is that one file is locked by a
client that died and never released it, and Nextcloud — by default — lets that
lock live forever.

## Recognising it

Any of these, and they usually arrive together:

- `nextcloud.log` growing by tens of MB in a day, or rotating unexpectedly.
- A WebDAV client (rclone, the desktop client) retrying the same file endlessly.
- `Sabre\DAV\Exception\Locked` filling the log, always on the same path.
- **Every monitor green.** Nothing here fails a health check: the server is fine,
  the container is fine, the file is simply frozen.

Measured on 2026-08-15: 94 MB written in 42 hours, 99.75 % of it one exception on
one file, ~770 entries an hour, and a full 100 MB rotation consumed.

## Diagnosis

```bash
# 1. What is filling the log, and on which path
sudo tail -500 /mnt/data/services/nextcloud/data/data/nextcloud.log \
  | python3 -c 'import sys,json,collections
c=collections.Counter()
for l in sys.stdin:
    try: d=json.loads(l)
    except: continue
    c[(d.get("method"), d.get("url"), (d.get("userAgent") or "")[:20])]+=1
for k,v in c.most_common(3): print(v,k)'
```

```bash
# 2. The locks themselves — this is the answer
sudo bash -c 'set -a; . /opt/homelab/backup.env; set +a
docker exec nextcloud-db mariadb -u"$NEXTCLOUD_DB_USER" -p"$NEXTCLOUD_DB_PASSWORD" "$NEXTCLOUD_DB_NAME" -e "
  SELECT l.id, l.file_id, from_unixtime(l.creation) AS placed, l.ttl, l.owner, f.path
  FROM oc_files_lock l LEFT JOIN oc_filecache f ON f.fileid = l.file_id
  ORDER BY l.creation;"'
```

A `ttl` of `-60` is the tell: it is the `-1` default multiplied by the 60 in
`ConfigService`, i.e. **never expires**.

Do not bother looking in Redis. Transactional locks live there and are released in
milliseconds; these are `files_lock` rows in the database, a different mechanism
entirely. An empty Redis scan proves nothing.

## Releasing

```bash
sudo docker exec -u www-data nextcloud php occ files:lock <file_id> --status
sudo docker exec -u www-data nextcloud php occ files:lock <file_id> admin --unlock
```

Pass the **file owner** (`admin`), not the lock owner. The lock says `Text`, which
is the app that placed it, and `occ` cannot resolve it as a user — it fails with
`Backends provided no user object`. That error is misleading: nothing is broken,
you named the wrong party.

The blocked client picks up on its own; no restart is needed. rclone backs off
progressively, so after 40-odd hours of failure its next attempt can be ten
minutes away — silence is not proof it is still stuck.

## Why it happens, and what was changed

The Nextcloud **mobile app** takes a `Text` lock when it opens a `.md` note. That
is normal — it is what stops two people editing the same file. Killing the app
from the task switcher skips the release call, and the lock stays.

Reproduced deliberately on 2026-08-15: zero locks before, note opened in the
mobile app, lock created 15 seconds later with the same signature as the stale
ones, app killed from the switcher, **lock still present six minutes later**. The
browser had not been used for three days, which had already ruled it out.

The fix is a setting, not a script. `files_lock` ships `Cron\Unlock`, which calls
`getDeprecatedLocks()` — and that function returns nothing when `lock_timeout` is
`-1`, its default. The cleanup runs faithfully and finds nothing, forever. The
deploy role now sets `nextcloud_lock_timeout_minutes` (60), so a lock nobody
released expires within the hour instead of never.

That caps the damage; it does not prevent the lock. If you kill the app on an open
note, that file stops syncing for up to an hour.

## Checking it is armed

```bash
sudo docker exec -u www-data nextcloud php occ config:app:get files_lock lock_timeout   # expect 60
```

`-1` or empty means the cleanup is inert again and stale locks will accumulate.

## Related

- [feed-digest.md](feed-digest.md) — the digest writes into this vault through the
  same rclone mount; two of the six stale locks were on its own daily notes.
- [notify-push-troubleshooting.md](notify-push-troubleshooting.md) — the other
  Nextcloud failure mode that leaves every indicator green.
