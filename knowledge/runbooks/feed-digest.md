# Runbook — Daily feed digest (Miniflux → Claude → vault)

Use this page to set up, tune, replay or repair the daily digest: `homelab-feed-digest.timer`
runs at 06:30, summarises everything unread in Miniflux into one dated vault note, then marks
those entries read. Design: [ADR-027](../decisions/ADR-027-feed-digest.md) and
[docs/05-services/claude-code.md](../../docs/05-services/claude-code.md).

## Before you start

- **The digest consumes its input.** Summarised entries are marked read, so a bad digest
  cannot simply be re-run: see [Replaying a digest](#replaying-a-digest).
- Fix the prompt, never the note: the note is an output.

## Shell prelude

Every API snippet below assumes this, run on the Pi as `claude` (the only account that can
read the key):

```sh
sudo -u claude bash
K=$(cat /mnt/data/secrets/claude/miniflux_api_key)
R="--resolve rss.<domain>:443:<pi-lan-ip>"
mf() { printf 'header = "X-Auth-Token: %s"\n' "$K" | curl -sS $R -K - "$@"; }
```

- Use `-K -`, never `-H "X-Auth-Token: …"`: argv is readable by every account through `/proc`.
- Keep `--resolve`: the Pi's own resolver is not Pi-hole, so `rss.example.com` does not
  resolve on the host.

## One-time setup (Uptime Kuma UI)

A Push monitor, as for [backup monitoring](backup-monitoring.md): Kuma goes red when the job
stops calling.

1. **Add New Monitor** → Monitor Type: **Push**.
2. Friendly Name: `Veille quotidienne` (the live monitor).
3. **Heartbeat Interval**: `100800` s (28 h: one daily run plus grace for
   `RandomizedDelaySec=300`). Retries: `0`.
4. Tick your existing notification channel.
5. **Save**, copy the **Push URL**, keep only `https://<uptime-kuma>/api/push/<token>` (drop
   any `?status=up&msg=OK&ping=`; `notify()` strips it anyway).
6. Put the secrets in the vaulted `local.yml`:
   ```yaml
   miniflux_api_key: "..."
   feed_digest_kuma_push_url: "https://<uptime-kuma>/api/push/<token>"
   ```
   Put the note's look (folder, note suffix, tags, title, wording) in the gitignored,
   plain-text `private.yml`; start from `private.example.yml`.
7. Deploy: `ansible-playbook playbooks/site.yml --tags claude-code --ask-vault-pass`

## Replaying a digest

Mark the last entries unread, re-run, read the result. The same day's note is overwritten.

1. Mark the last 30 entries unread (in the prelude shell):

   ```sh
   IDS=$(mf "https://rss.<domain>/v1/entries?status=read&direction=desc&order=published_at&limit=30" \
         | jq -c '[.entries[].id]')
   mf -H "Content-Type: application/json" -X PUT \
      -d "{\"entry_ids\": $IDS, \"status\": \"unread\"}" https://rss.<domain>/v1/entries
   ```

2. Leave the `claude` shell and run the service as root:

   ```sh
   exit
   sudo systemctl start homelab-feed-digest.service
   ```

3. Read the result:

   ```sh
   sudo journalctl -u homelab-feed-digest.service -n 20 --no-pager -o cat
   sudo -u claude cat "/home/claude/vault/<folder>/$(date +%F) - <suffix>.md"
   ```

### Tuning the prompt

| File | Owner | Survives a deploy |
|---|---|---|
| `~claude/.local/share/feed-digest/prompt.md` — generic, English | Ansible, rewritten every deploy | no |
| `<vault>/<folder>/prompt.local.md` — personal | you | **yes** |

- Edit the override: it wins from the next run, needs no deploy, and is editable from
  Obsidian. Anything personal goes there only (this repository is public).
- The override is not version-controlled, only backed up with the vault.
- Fold structural changes (ordering, grouping, general rules) back into
  `feed-digest-prompt.md.j2`.
- Nothing warns that the default moved on. The journal line
  `using the vault override prompt` tells which prompt a run used.

## The digest did not run (Kuma red, no note)

Run these in order; the expected answer is on each line.

```sh
systemctl list-timers homelab-feed-digest.timer   # NEXT in the future, LAST recent
systemctl is-enabled homelab-feed-digest.timer    # enabled
sudo journalctl -u homelab-feed-digest.service -n 40 --no-pager -o cat
sudo -u claude tail -40 /home/claude/.local/share/feed-digest/digest.log
```

A failed run pushes `status=down` with the message, so the Kuma notification usually names
the cause.

| Symptom in the journal | Cause | Fix |
|---|---|---|
| `the vault is not mounted at …` | vault not mounted | `systemctl status vault-mount`; see the stale-endpoint section of the service doc |
| `the vault … is mounted but unreadable` | credential rejected; `vault-mount.service` still `active (running)`, rclone logs `PasswordLoginForbidden` | `journalctl -u vault-mount -n 30`, renew the Nextcloud app password, then follow [rotate-a-secret](rotate-a-secret.md#app-passwords-and-api-keys-delete-the-old-one): the deploy restarts `vault-mount` (and Claude Remote Control with it, `PartOf` the mount) |
| `ExecStartPre` failed, nothing else | the unit on the host is older than the repo (the gate now lives in `digest.sh`) | redeploy `--tags claude-code` |
| `missing API key at …` | key file absent or unreadable | redeploy `--tags claude-code`; check `miniflux_api_key` is set in `local.yml` |
| `curl … (22)` on `/v1/entries` | Miniflux or Traefik down | `curl $R https://rss.<domain>/healthcheck` → expect 200 |
| `claude -p failed` | claude.ai session expired | re-login the `claude` user, same procedure as Remote Control 401 |
| `claude -p returned an empty digest` | model returned nothing | replay; if it repeats, the prompt is the suspect |
| Timer never fired at all | Pi was off | `Persistent=true` catches up on next boot; nothing to do |

## Kuma is green but the message is always `OK`

The push lands but its parameters are ignored, so `status=down` can never arrive either. A
healthy message reads `N entries summarised` (plus `, M carried over` at the cap), in English
whatever the note's labels:

```
Veille quotidienne | 2026-08-17 04:34:24 | 28 entries summarised
```

1. Check `notify()` still sends with `-G` (without it, Kuma ignores the parameters):

   ```sh
   sudo grep -n 'curl -fsS' /home/claude/.local/share/feed-digest/digest.sh   # must contain -G
   ```

2. Check the push URL in `local.yml` has no `?status=up&msg=OK&ping=` suffix.
3. Check the monitor has received real beats, not just one creation-time `OK`:
   `SELECT datetime(time), status, msg FROM heartbeat WHERE monitor_id=<id> ORDER BY time DESC`
   on the live `kuma.db` opened with `mode=ro` (as `ops/kuma-dump.sh` does), never a copy
   ([uptime-kuma.md](../../docs/05-services/uptime-kuma.md)).

## Draining a backlog

At most 400 entries per run (`feed_digest_max_entries`); the rest stay unread. The carry-over
is reported:

- in the note: `_N entrées lues, M au-delà du plafond, reportées au prochain passage. …_`
  (labels from `feed_digest_label_*` in `private.yml`)
- in the Kuma message: `N entries summarised, M carried over`

To drain faster, start the service repeatedly; each pass takes the next 400 oldest
(`direction=asc`). Remaining count:

```sh
mf "https://rss.<domain>/v1/entries?status=unread&limit=1" | jq -r .total
```

After a long absence, mark the backlog read in the Miniflux UI instead.

## A feed broke

Other feeds keep working. List failing feeds:

```sh
mf "https://rss.<domain>/v1/feeds" \
  | jq -r '.[] | select(.parsing_error_count > 0) | "\(.id) \(.title): \(.parsing_error_message)"'
```

- Reddit feeds are refused (`Access to this website is forbidden. Perhaps, this website has a
  bot protection`, r/selfhosted, 2026-08-13): do not add them.
- A 403 or DNS error for a week: delete the feed in the UI and in your OPML file.
- A timeout: keep the feed, but refresh it by hand. After 15 consecutive errors (`POLLING_PARSING_ERROR_LIMIT`) Miniflux stops
  polling it for good, and the posture check `miniflux-no-feed-silently-unscheduled` stays red
  until a refresh succeeds:

```sh
mf -X PUT "https://rss.<domain>/v1/feeds/<id>/refresh"
```

## Related

- [ADR-027](../decisions/ADR-027-feed-digest.md) — design decisions
- [ADR-026](../decisions/ADR-026-miniflux-rss.md) — Miniflux itself
- [backup-monitoring.md](backup-monitoring.md) — the same Push-monitor pattern
- [docs/05-services/claude-code.md](../../docs/05-services/claude-code.md) — the `claude` user, vault mount, Remote Control
