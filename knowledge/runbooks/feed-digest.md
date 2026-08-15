# Runbook — Daily feed digest (Miniflux → Claude → vault)

`homelab-feed-digest.timer` runs at 06:30 every day: it reads everything unread in
Miniflux, has Claude Code summarise it, writes one dated note into the Obsidian vault, then **marks the summarised entries read**.

Design and rationale live in [ADR-027](../decisions/ADR-027-feed-digest.md) and
[docs/05-services/claude-code.md](../../docs/05-services/claude-code.md). This page is only
about operating it.

## The one thing to understand first

**The digest destroys its own input.** Entries are marked read once summarised, so a bad
digest cannot simply be re-run: the entries are no longer in the unread pool. They are not
lost — Miniflux keeps them — but getting them back takes an API call, which is the reason
[Replaying a digest](#replaying-a-digest) exists.

The second consequence is that the note is the **only** entry point to a day's news. If it
is wrong, fix the prompt and replay; do not edit the note, it is an output.

## Shell prelude

Every API snippet below assumes this, run **on the Pi as the `claude` user** (the only
account that can read the key):

```sh
sudo -u claude bash
K=$(cat /mnt/data/secrets/claude/miniflux_api_key)
R="--resolve rss.example.com:443:192.168.1.100"
mf() { curl -sS $R -H "X-Auth-Token: $K" "$@"; }
```

`--resolve` is not optional: the Pi's own resolver is **not** Pi-hole, so
`rss.example.com` does not resolve on the host even though every LAN client resolves it.
Pinning it sends the request through Traefik, the same path a browser takes.

## One-time setup (Uptime Kuma UI)

Same shape as [backup monitoring](backup-monitoring.md) — a **Push** monitor is passive:
Kuma never calls the job, it waits to *be* called, and goes red when nobody does. That is
the only kind of monitor that can watch a once-a-day job.

1. **Add New Monitor** → Monitor Type: **Push**.
2. Friendly Name: `Feed digest`.
3. **Heartbeat Interval**: `90000` s (25 h) — one daily run plus an hour of grace, which
   absorbs the timer's `RandomizedDelaySec=300` and clock drift. Below 24 h the monitor
   would go red every afternoon simply because the next run has not happened yet.
   Retries: `0` (on a passive monitor, retries only delay the alert).
4. Tick your existing notification channel.
5. **Save**, copy the **Push URL**, and keep only the base form
   `https://<uptime-kuma>/api/push/<token>` — **drop any trailing
   `?status=up&msg=OK&ping=`**, the script appends its own parameters. Since
   2026-08-15 `notify()` strips that suffix itself, so pasting it no longer breaks
   anything — but keep the habit: a URL that says `status=up` in plain text invites
   the next reader to trust it.
6. Two files, because two kinds of value:
   - **`local.yml`** (gitignored, vaulted) for the secrets — the API key and the push
     URL, which carries a token:
     ```yaml
     miniflux_api_key: "..."
     feed_digest_kuma_push_url: "https://<uptime-kuma>/api/push/<token>"
     ```
   - **`private.yml`** (gitignored, plain text) for what the note looks like — folder,
     note suffix, tags, title, wording. None of it is secret, so none of it needs
     `ansible-vault edit` every time you tweak a label; and none of it belongs in the
     public `main.yml` either. Copy `private.example.yml` to start.
7. Deploy: `ansible-playbook playbooks/site.yml --tags claude-code --ask-vault-pass`

## Replaying a digest

The loop you will use most while tuning the prompt. Marking entries unread again is the
whole trick.

```sh
# 1. Resurrect the last N entries (30 is a comfortable test batch)
IDS=$(mf "https://rss.example.com/v1/entries?status=read&direction=desc&order=published_at&limit=30" \
      | jq -c '[.entries[].id]')
mf -H "Content-Type: application/json" -X PUT \
   -d "{\"entry_ids\": $IDS, \"status\": \"unread\"}" https://rss.example.com/v1/entries

# 2. Re-run (as root, the unit runs as claude on its own)
exit
sudo systemctl start homelab-feed-digest.service

# 3. Read the result
sudo journalctl -u homelab-feed-digest.service -n 20 --no-pager -o cat
sudo -u claude cat "/home/claude/vault/<folder>/$(date +%F) - <suffix>.md"
```

The note is **overwritten** for the same day, so replaying does not pile up files.

### Tuning the prompt

The prompt is a separate file precisely so this loop never requires reading shell. There
are two of them, and the override always wins:

| File | Owner | Survives a deploy |
|---|---|---|
| `~claude/.local/share/feed-digest/prompt.md` — generic, English | Ansible, rewritten every deploy | no |
| `<vault>/<folder>/prompt.local.md` — personal | you | **yes** |

Work on the override: no deploy needed, it applies from the next run, and being in the
vault it is editable from Obsidian on any device.

**Anything personal belongs there and only there** — the stack to filter against, the
editorial slots, the writing rules. This repository is public, and the default is
deliberately generic so it stays publishable.

Fold a change back into `feed-digest-prompt.md.j2` only when it is *structural* (ordering,
grouping, a rule that holds for anyone). The override is **not version-controlled**, only
backed up with the vault.

Nothing warns you that the repo default has moved on while an override is in place — that
is deliberate, a daily "your override is old" line would be tuned out within a week. The
journal does say which prompt each run used (`using the vault override prompt`), and that
is the first line to look for when a digest suddenly reads differently.

## The digest did not run (Kuma red, no note)

Work down the list; each command's healthy answer is given.

```sh
systemctl list-timers homelab-feed-digest.timer   # NEXT in the future, LAST recent
systemctl is-enabled homelab-feed-digest.timer    # enabled
sudo journalctl -u homelab-feed-digest.service -n 40 --no-pager -o cat
sudo -u claude tail -40 /home/claude/.local/share/feed-digest/digest.log
```

| Symptom in the journal | Cause | Fix |
|---|---|---|
| `ExecStartPre` failed, nothing else | vault not mounted | `systemctl status vault-mount`; see the stale-endpoint runbook in the service doc |
| `missing API key at …` | key file absent or unreadable | redeploy `--tags claude-code`; check `miniflux_api_key` is set in `local.yml` |
| `curl … (22)` on `/v1/entries` | Miniflux or Traefik down | `curl $R https://rss.example.com/healthcheck` → expect 200 |
| `claude -p failed` | claude.ai session expired | re-login the `claude` user, same procedure as Remote Control 401 |
| `claude -p returned an empty digest` | model returned nothing | replay; if it repeats, the prompt is the suspect |
| Timer never fired at all | Pi was off | `Persistent=true` catches up on next boot; nothing to do |

A run that fails pushes `status=down` to Kuma with the message, so the notification usually
already carries the answer.

## Kuma is green but the message is always `OK`

The dangerous variant, because nothing looks wrong. It means the push is landing but the
parameters the script sends are being ignored, so `status=down` never gets through either:
the monitor can only ever be green, and a broken digest reports success. Read the message,
not the colour — a healthy beat says `N entrées résumées, M reportées`.

```sh
sudo grep -n 'curl -fsS' /home/claude/.local/share/feed-digest/digest.sh   # must contain -G
```

Two causes, both fixed on 2026-08-15 and both worth re-checking if the file was hand-edited:
`curl` without `-G` sends the parameters as a request body that Kuma does not read, and a
Push URL pasted with its `?status=up&msg=OK&ping=` suffix overrides whatever the request
carries. `notify()` now forces `-G` and strips the suffix.

A monitor that has never received a real beat is the same failure one step earlier: a single
`OK` at creation time (the operator's test `curl`) then nothing. Check before trusting it —
`SELECT datetime(time), status, msg FROM heartbeat WHERE monitor_id=<id> ORDER BY time DESC`
against a read-only copy of `kuma.db`, per [uptime-kuma.md](../../docs/05-services/uptime-kuma.md).

## Draining a backlog

At most **400 entries** per run (`feed_digest_max_entries`). Anything beyond stays
**unread** on purpose, so a backlog drains over several runs rather than vanishing. The
carry-over is reported in two places — never silently:

- in the note: `_N entrées lues, M au-delà du plafond reportées au prochain passage._`
- in the Kuma message: `N entrées résumées, M reportées`

To drain faster, run the service repeatedly; each pass takes the next 400 oldest
(`direction=asc`). Check what is left:

```sh
mf "https://rss.example.com/v1/entries?status=unread&limit=1" | jq -r .total
```

After a long absence, consider marking the backlog read in the Miniflux UI instead: a
digest of a two-week pile is not a digest. That is what was done on 2026-08-13 after the
initial OPML import (2443 entries), and it is why the first scheduled run saw a normal day.

## A feed broke

Feeds fail quietly — Miniflux keeps serving the others.

```sh
mf "https://rss.example.com/v1/feeds" \
  | jq -r '.[] | select(.parsing_error_count > 0) | "\(.title): \(.parsing_error_message)"'
```

Known case (2026-08-13): **r/selfhosted** returns `Access to this website is forbidden.
Perhaps, this website has a bot protection` — Reddit blocks Miniflux's user agent. Nothing
to repair on our side.

Rule of thumb: a feed that has failed for a week with a 403 or a DNS error is dead, delete
it. A feed failing with a timeout is worth keeping. Deleting is done in the UI, and the
OPML in your OPML file should be edited to match so a re-import does
not bring the corpse back.

## Related

- [ADR-027](../decisions/ADR-027-feed-digest.md) — design decisions
- [ADR-026](../decisions/ADR-026-miniflux-rss.md) — Miniflux itself
- [backup-monitoring.md](backup-monitoring.md) — the same Push-monitor pattern
- [docs/05-services/claude-code.md](../../docs/05-services/claude-code.md) — the `claude` user, vault mount, Remote Control
