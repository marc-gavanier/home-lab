# Settled

Living document. Paste it into every agent brief, and update it after every run
— both what got fixed and what was declined. Its whole value is being current:
an agent that re-proposes something already turned down burns the report's
credibility along with its own budget.

Two kinds of entry, and the distinction matters:

- **Declined** — the operator considered it and said no. Not an oversight, not
  an opening for a better-argued version. Do not raise it again. If a later
  change makes the underlying gap materially worse, state the new fact; do not
  repeat the old proposal.
- **Measured and rejected** — it was investigated and the numbers killed it.
  Re-raising it requires new numbers, not new enthusiasm.

---

## Declined — hardening

Live kernel patching, an IPS/reputation layer, a forward-auth SSO portal, user
namespace remapping, and the kernel audit daemon. All assessed, all declined.

The remaining containers with an elevated capability, and the remaining
writable root filesystems, are **structural** — they were examined one by one
and cannot be removed without breaking the service. Do not re-report them as
findings.

Additional fail2ban jails for recently added web forms: rejected after
measurement — the existing jails show zero failures and zero bans since they
were deployed.

**rkhunter is gone, deliberately.** It had been installed since the beginning
and had never run once on either host — no log, `CRON_DAILY_RUN=""`, signatures
frozen at 2026-05-10. It was removed rather than scheduled on 2026-08-16:
scheduling it would mean adding an alerting path and a false-positive budget for
machinery nobody asked for, next to an already-declined reputation/IPS layer. Do
not propose reinstalling it. `roles/security/tasks/audit.yml` records how to go
the other way if the decision ever changes.

**The distribution's `lynis.timer` is masked, deliberately.** It ran daily at
5 min 45 s of CPU for a report nobody read, and its freshness made the weekly
report script's only guard unable to fire. Our own weekly run is the one with a
reporting path attached. Do not report the masked timer as a gap.

**`errors=remount-ro` on the ext4 volumes was raised and deliberately left
alone** on 2026-08-16. Both volumes are on `Continue`. Turning a data volume
read-only mid-incident on a host serving media and backups is a real trade-off,
not an obvious win, and it deserves its own decision rather than riding along
with an instrumentation change. Raise it as a decision if you raise it at all —
not as a finding.

## Declined — supervision

- **External supervision of the main host.** Every dead-man's switch terminates
  in a push monitor running on the very machine it watches. The gap is real,
  confirmed, and the operator does not want it closed that way.
- **A timed restore drill.** The existing drill record stands as it is.
- **Drift detection between the two hosts.** They are provisioned by different
  roles and nothing checks that the second keeps up. Verdict: too little
  configuration involved to be worth machinery.

## Declined — backup scope

- **Dumping the media services' metadata databases.** They hold play counts,
  watch and reading progress, shelves and query history — a rescan rebuilds all
  of it. The media files themselves are covered, which is what matters. This is
  a decision, not an oversight: do not re-audit it.

## Measured and rejected

- **Expiring the frozen snapshots left by obsolete path sets.** Grouping the
  retention policy by host would drop them, but deduplication already shares
  their chunks: 1.218 GiB of 343, i.e. 0.35 %. Not worth a repository-wide
  prune, still less on the append-only offsite copy.
- **Memory limits on containers.** The absence is real. Adding them would
  create an OOM kill that does not exist today: working set is well under
  capacity and memory pressure sits near zero over a fortnight.
- **The DNS-over-HTTPS connection investigation.** Closed with no action — the
  upstream retires connections on a timer, and every per-query rate computed
  during the investigation turned out to be an artefact. Do not reopen.

## Tooling constraints, not preferences

- Uptime Kuma is **v2**. The widely cited automation tooling is v1-only and does
  not speak v2; monitors are entered by hand in the web UI. Do not propose it.
- **No git worktrees for work that DEPLOYS.** Work in the operator's directory,
  on their branch, and announce any branch switch — a checkout changes what
  their next deploy ships. Documentation-only work may use one; the operator
  asked for that explicitly, and there the worktree protects the shared tree
  rather than endangering it.
- **The operator deploys from the PR branch, BEFORE merging** — so that anything
  the deploy turns up becomes another commit on the open PR instead of a second
  PR. Never sequence instructions as merge-then-deploy. It earned its keep the
  same evening: masking a timer left a unit permanently failed, and the fix went
  onto the branch before anything was merged.
- **Ansible commands are run from `ansible/`, on ONE line.** `ansible.cfg`
  already sets the inventory, so `-i` is never needed, and the playbooks live in
  `playbooks/`. Multi-line commands break the operator's copy/paste.
- The photo service's version pins are explicit and deliberate; its migration
  is one-way. Do not propose bumping components independently.

## Deferred, not declined

- **Marking the internal container network as internal.** Correct in principle;
  two services currently reach out through it and would break. A real piece of
  work to be scoped, not a quick fix, and not an audit finding to repeat.

---

## Closed by the run of 2026-08-16 — proven, not assumed

The 2026-08-15 table is retired: every line in it is resolved, and the four
items that run left owed to its successor were confirmed **on the machines**,
from the live artefact rather than the commit log.

| Owed item | Proven how |
|---|---|
| Memory and swap in the health push | The pushed message now reads `cpu 41C, / 18%, /mnt/data 17%, mem 4705Mi free, swap 52%, dns ok`. Read from the monitor, not the template. |
| Dump assertions on a real nightly run | The five `check_dump` assertions and the Immich freshness guard all fired at 03:00:38, each logging a real byte count. The dumps are in the snapshot with matching sizes and intact terminators. |
| The digest's message carrying real counts | Sends `20 entries summarised`; it was still the constant `OK` on 08-15. |
| Git service encryption key, restore-runbook service names, capped cloud-service log, recreated swap file | `SECRET_KEY` empty in `app.ini` with only `SECRET_KEY_URI` populated; service names checked against compose; kernel took the full 4 GiB swap file. |

Also established that day, and not to be re-derived: both hosts are
**byte-identical to `main`** (12/12 verbatim artefacts by sha256, 8 templates
structurally identical); the offsite host's `toolbox` role, unreachable since
2026-07-19, finally converged at 16:02; and the offsite backup path came back
unaided after a reboot.

**The swap threshold: keep 85 %, but the 53 % figure was misread.** Occupancy
sat at 53 % all through 2026-08-16 and was described here as a steady state
projecting to 59–64 %. That reading is **wrong**, and the evening of the same day
disproved it by accident: an `apt upgrade` restarted the Docker daemon at 21:37,
all 28 containers came back, and swap fell to **3 %**. So 53 % was not an
equilibrium but cold pages accumulated since the previous restart — long-lived
container memory that had simply never been touched again.

The conclusion survives, the reasoning does not. Swap is cold parking rather
than thrashing (+6 pages in, 0 out over 60 s; 20-day averages of 2.9 / 5.9
KiB/s), so **keep 85 %**. But the recheck around 2026-08-30 now starts from 3 %
after a known restart, which makes it a real measurement of the refill rate
instead of a reading of an unknown accumulation. Do not quote 53 % as a baseline.

## Measured and rejected — added 2026-08-16

- **Excluding the metrics store from the nightly backup.** 1.9 GB at 380 MiB/day
  of churn, roughly half the nightly delta. Buys ~108 s of copy time and no
  space that is needed: the offsite copy grew 7 GB in 35 days.
- **Kernel RCU stall messages.** 226 over 14 days, 204 of them at 21 jiffies
  (~84 ms), maximum 85. Informational on a preempt kernel. Not a defect.
- **Thermal and hardware margin.** `throttled=0x0` on both hosts — sticky bits,
  so never throttled or under-volted in 19 days. Zero USB, ext4, I/O or OOM
  events in the retained journal. Do not re-audit without a new symptom.

## Two agent claims that did not survive verification

Recorded because the next run will be tempted by both.

- **"The Nextcloud healthcheck is a façade that keeps its monitor green."**
  Refuted. The Kuma monitor is `type=keyword` on
  `"maintenance":false,"needsDbUpgrade":false` — it goes red on exactly the
  state alleged to slip past. Only the container's own `curl -f` cannot fail in
  maintenance mode, and nothing acts on that column: the heal timer triggers on
  exits, not on health. Cosmetic.
- **Kernel ring-buffer line counts.** An agent reported 16 334 retained lines,
  74 % of them repeaters. That is `journalctl -k`, not `dmesg`. The real ring
  holds **904 lines / 128 KiB**, of which 646 are `[UFW BLOCK]` and 623 are the
  router's IGMP query. The wrap is real — a 21.6-hour window against 19 days of
  uptime — but journald is **persistent**, so nothing is lost. The defect is the
  documentation line pointing at `dmesg`; use `journalctl -k -b`.

The lesson generalises: check which instrument produced a number before
believing what it implies.

## One operational note, learned the hard way during the #123 repair

A raw `cp` of a WAL-mode SQLite file is **not a backup**. The first copy taken
of the Forgejo database captured the `.db` alone while a 4 MB `-wal` sat beside
it, so everything since the last checkpoint was missing — and it looked like a
complete backup, right size, right name. Use `sqlite3 ".backup"`, which merges
them, and check `integrity_check` on the result. The nightly script already
does this correctly; hand work is where it slips.

---

## Findings from the run of 2026-08-16

All nine are tracked. Verify them **gone** rather than rediscover them, and
remember that merged is not deployed and deployed is not proven.

| # | Finding | Status |
|---|---|---|
| #123 | Forgejo mirror dead 22 h behind a healthy container; the `SECRET_KEY` fix sealed its remote address | **fixed and verified** — mirror level with `main`, both HEADs `881005b`, 0 decrypt errors since. Repaired by clearing the undecryptable blob so Forgejo's own recovery branch could re-read the address from git config; the settings form **cannot** do it, it 500s on the same decrypt. See the issue for the sequence. |
| #132 | Nothing detects a mirror that stops mirroring — follow-up to #123 | **fixed in main, pending deploy** — and the check the issue proposed was **impossible**: `mirror.updated_unix` moves on every ATTEMPT (00:56 UTC in the 03:00 dump taken four hours into the outage), and Forgejo records no last-successful-sync at all. `next_update_unix` is the real signal: it only advances on completion, so it sat 2 h 30 in the past and sinking during that same outage. |
| #124 | Vaultwarden's whole `environment:` block shadowed by a May `config.json`, three settings inverted | **fixed and verified** — three keys removed, icon probe returns the built-in fallback with zero outbound fetches. A posture assertion now compares the container's environment against the file it reads, and names the three keys exactly when replayed against the pre-fix backup. Deploy idempotent (`changed=1` then `0`). |
| #125 | Every re-downloaded VPN client config carries Cloudflare DNS; split DNS dies on a re-paired device | **fixed** — all four clients now serve the Pi-hole address in the configuration a device would download, `wg0.conf` byte-identical throughout. Applied as a direct SQLite `UPDATE`, **around** the API, because of #138. The issue's IPv6 aside was wrong: clients do have ULA v6 addresses. |
| #126 | Three restore procedures still say `stop` where the heal timer resurrects | **fixed** — the sweep found **eleven** sites across nine files, not three. Also corrected the issue's premise: the logged resurrections are miniflux crash-heals, not stopped containers, so the danger is conditional on the image's SIGTERM handling — which is exactly why a runbook cannot use `stop`. |
| #127 | Truncation floor at 0.04 % of the dump, and a push that sends a constant | **fixed and deployed**, idempotent. Content assertions replace the floor; the push carries restic's own summary. `quick_check` alone would have been a **regression** — a zero-byte file passes it — so the SQLite branch also asserts the database holds tables. Real 03:00 run still unobserved: #137. |
| #128 | Traefik sees all VPN clients as one gateway address; `vpn-only` subnet rule dead, `rate-limit` one bucket | open |
| #129 | Peer-revocation runbook reads a file frozen by the v15 migration | **fixed** (PR #140) — listing now queries `clients_table`; revocation section gated on #138, since revoking is itself impossible. The four commands were re-run from another session before closing: `docker exec` works without `sudo`, which the emergency stopgap depends on. |
| #130 | README understates the public perimeter; swap documented at half its size | **fixed** (PR #142) — figures re-measured on the hosts: 8 GB board (7.7 GiB usable), 4 GiB swap, offsite is the retired 4 GB board. |
| #131 | Empty strings in the example override working defaults; two bind-mounted configs without a restart handler | **fixed and deployed**, `changed=0` with `skipped` 32→33 — the increment is the new assertion skipping, which is what proves it is there. Sweep found these three keys were the only collision. |
| #137 | The backup assertions and summary push are proven on fixtures only — follow-up to #127 | open |
| #138 | wg-easy cannot write its own database: adding or **revoking** a peer fails behind a healthy container — found via #125 | **open, do at the machine.** Closed by mistake on 2026-08-16 and reopened the same evening once the machine was checked: `/mnt/data/services/wireguard` is still uid 1000 and `docker exec wg-easy touch` still returns `Permission denied`, so revoking a VPN peer through the UI remains impossible. The `wg set … remove` stopgap on the live interface still works, but does not survive a container restart. #144 fixed the identical defect for three other services with the same one-line `chown`; wg-easy is excluded because the first successful write regenerates `wg0.conf` and runs `wg syncconf`, and that interface is the only path to the host. |

Still open and still cosmetic: one orphaned anonymous volume (~48 MB) from a
first container start. Remove by hand, never with a broad prune.

## Findings from the SECOND run of 2026-08-16 (evening)

Re-run at the operator's request, three hours after the morning campaign closed.
Baseline was clean — 0 failed units, 28/28 containers healthy, 31 monitors green
— and it found twelve things anyway. All are tracked in #144, #145 and #146, all
three merged, deployed and verified the same night.

| # | Finding | Proven how |
|---|---|---|
| #144 | Vaultwarden, Traefik and immich-server run as root **without `DAC_OVERRIDE`** over data directories owned by uid 1000, so none can create a file. Vaultwarden's vault survived only because its `-wal`/`-shm` predated the capability drop by six days | `docker exec … touch` → `Permission denied` on all three, with a control returning a *different* errno elsewhere. Replayed on the host: root **with** `dac_override` reads the base, root **without** returns `attempt to write a readonly database (8)`. Fixed; `touch` now succeeds |
| #145 | Transmission's healthcheck was `curl` with no `-f` — 401 → rc=0, nonexistent route → rc=0, only a closed port failed | Replaced with `transmission-remote`, which authenticates and enumerates: rc=1 on a bad password, rc=1 on an unreachable daemon |
| #145 | The weekly lynis guard could never fire: the **distribution's own** `lynis.timer` runs daily and kept the report permanently fresh | 14 runs in 14 days, 5 min 45 s of CPU each. Freshness now asserted on the report's mtime; the redundant timer masked |
| #145 | `MIN_INDEX=65` against an index measured at **74 on 5/5 samples, zero variance** | Ratchet on the best index; replayed across seven states — 66 after 76 now reports DOWN where the old code said UP |
| #145 | `Pi health` **detected problems and notified none**: the restart check is true for exactly one run, `maxretries=1` makes that PENDING, and PENDING does not notify in Kuma v2 | 60 days of heartbeats: one real detection (`claude-remote-control.service 7->8`, status=2), zero notifications. The only two DOWN beats are the dead-man's switch. Now held across a second beat; verified to emit on beats 1 and 2 and stop |
| #145 | A **stale dump** could be snapshotted: a failed `sqlite3 .backup` leaves its destination byte-for-byte intact | Needs a run that *aborted* — 103 `started` against 102 `completed`. `rm -rf "$DUMP_DIR"` before the `mkdir` |
| #145 | The posture check never asserted `Config.User`, though nine services declare one | Asserted where compose declares it; all nine match |
| #145 | Two Ansible loops rebuilt the orphan `internal` network **on every deploy** | Removed by hand at 14:12, rebuilt at 14:51. Both loops now name `proxy` only |
| #145 | Eleven Docker secrets had **no restart handler** — a rotated credential is never read while the deploy reports changed | `forgejo_secret_key` ran 17 h 44 on the old key after being written. One handler per consumer, mapped from the running containers' mounts |
| #145 | rkhunter installed and **never run** — no log on either host, `CRON_DAILY_RUN=""`, signatures frozen at 2026-05-10 | Removed rather than scheduled |
| #145 | Journal retention 14.3 days against 19 days of uptime, at a 200M cap sitting at 199.1M; nothing watched the **filesystem**, only the disk | Cap raised to 500M (the cap governs deletion, not writing). ext4 superblock counters now in the daily report: `disk 17%, hdd 53C, ext4 clean` in the message the monitor received |
| #146 | Three `## Restore` blocks contradicted the runbook on the three databases with no second copy, one of them pointing at a path deleted after every backup | `ls /mnt/data/backups/dumps/` → `No such file or directory`. All three now defer to the runbook, which is why `immich.md` had never drifted |

Two things are still **live** after this campaign, and the next run should verify
them on the machine rather than trust their tracking state:

- **wg-easy still cannot write** — see the #138 row above. That issue was closed
  by mistake and reopened once the machine was checked, which is the whole
  argument for verifying against the running system: the tracker said done, the
  filesystem said `Permission denied`. Its exclusion in the posture assertion is
  the only one there, and it disappears with the fix.
- **The orphan `internal` network still exists.** Ansible no longer rebuilds it,
  but nothing deletes a network that has merely stopped being created. One
  `docker network rm internal` is owed.

### Method traps, all paid for the same evening

Worth more than the findings, because each one silently produced a wrong answer.

- **`docker top -o uid` returns nothing.** A sweep built on it reported *every*
  container as mismatched. Derive container uids from `Config.User`, which also
  surfaces the image's own `USER` — that is how Forgejo reads `1000:1000`.
- **busybox `test -w` lies for uid 0.** It answered "writable" for wg-easy.
  Only `access(2)` and host-side permission arithmetic are trustworthy.
- **`systemctl mask --now` leaves the unit `failed`**, so `systemctl --failed`
  stops being empty. Stop first, mask second — measured both orders.
- **A looped Ansible task counts as ONE `changed` in the PLAY RECAP**, not one
  per item. Three chowns plus a template read as `changed=3`, and inferring "the
  template was skipped" from that was wrong.
- **`apt upgrade` is inherently non-idempotent.** A `changed=1` whose only task
  is that one is not a defect. It also restarts whatever links against what it
  upgrades: on this evening it took `docker-ce` and the Kerberos libraries with
  it, which bounced all 28 containers and **killed the running play's SSH
  connection mid-task**. Narrow the tags when the change does not need `base`.
- **A 24-hour window that straddles the tail of a finished event reads as an
  incident in progress.** This one produced a headline finding that was simply
  false, so it is the most important entry here.

  The network agent reported, and the main session repeated twice, that a
  Nextcloud client had been stuck on a WebDAV lock "since at least 2026-08-12" —
  1036 responses of HTTP 423 in 24 hours, one path, ongoing. The count was real.
  The conclusion was not: the whole of it fell on 2026-08-15, and the episode had
  **ended at 20:24 UTC that day**, roughly 26 hours before the audit ran.

  The full retained log, which goes back to 08-12, shows ~700 an hour for three
  days and then nothing at all. It was a client retrying a single Obsidian note —
  49 777 DELETE and 4 977 PUT — and the deletion eventually succeeded: the file
  and its parent folder are gone, Redis holds no lock key, and a targeted
  `files:scan` reports zero discrepancies.

  So: **`--since <duration>` establishes a rate, never a present tense.** Always
  bucket by hour across the whole retained log before writing "ongoing", and
  read the LAST occurrence rather than the total. Note also that
  `docker logs -t` prints UTC while `--since` parses in host local time, and that
  the retention shown by `--since 24h` is the clip, not the actual window — take
  the first line without `--since` to learn how far back the log really goes.

### Two agent claims that did not survive verification, and one of mine

- The backup agent gave the stale-dump window as general. It is **conditional on
  an aborted run**: the cleanup sits *before* the `exit 1`, so a night that fails
  its assertions still empties the directory.
- The network agent attributed 87 rate-limit rejections between middleware and
  backend. **My own instrument for checking that was wrong** (`"-"` appears in
  several columns of the access log), so only the total and the absence of any
  successful `/image_proxy` request survive. Those belong to #128.
- Claiming "the first `docker compose down` leaves the vault read-only" (#144)
  was **too strong**. A full daemon restart happened that evening before the fix
  and Vaultwarden came back intact, same inodes: a Docker-initiated stop does not
  make it close SQLite cleanly. The fix stands — the trigger depends on the
  image's shutdown path, which can change at any version bump — but the urgency
  did not. The correction is recorded on the issue rather than edited away.

### The three patterns behind them

Worth more than the list, and worth checking for new instances next time.

1. **The setting is applied, the state is not.** A declared value never reaches
   the running object because something persisted earlier wins — a service's own
   config file, a database row seeded only at creation, a bind-mounted file with
   no restart handler, an empty string in an example that overrides a working
   default. Four instances this run (#124, #125, #131).
2. **The check cannot fail.** A threshold three orders of magnitude below what
   it guards, a push carrying a constant, a monitor probing the wrong side of a
   NAT (#127, #128, and the Transmission peer-port monitor). The verification
   layer is consistently thinner than it presents.
3. **Yesterday's fix, today's breakage — and partial sweeps.** The `SECRET_KEY`
   correction killed the mirror; the restore runbook was corrected in three
   places out of six; the swap batch left the old size in two files. **Every
   correction should end with a sweep for siblings**, which is how two of this
   run's findings were found at all.

   #138 is the sharpest instance and arrived after the table above was written.
   `cap_drop: ALL` is correct hardening and stays. But it takes `DAC_OVERRIDE`
   away from a container running as root, which then falls back under the
   permission bits it used to bypass — and one service's data directory is owned
   by another uid, so it can no longer create files there. Its database has been
   read-only ever since, which means a VPN peer cannot be **revoked**. Nothing
   showed it: the container is healthy and the tunnel works, because the running
   interface never writes.

   Worth generalising for the next sweep: **after dropping capabilities, check
   what each container still needs to WRITE**, not just that it still starts.
   A service that only writes when the operator asks it to will look healthy
   indefinitely.

### What the evening run added to them

Pattern 2 **dominated**: five of the twelve findings were controls that could
not report the failure they name. After five the same morning, that is ten in a
day, and it is the single most productive thing to hunt here.

The generalisation above **paid immediately** and is the reason #144 exists at
all: it was written down in the morning, and the evening's security agent used
it as a search key to find three more services in the same state, one of them
the password manager. **An audit does not find what it does not yet know to look
for** — which is most of the answer to why successive runs keep producing
findings, and why writing the generalisation down matters more than fixing the
instance.

A fourth pattern is now visible, and it is the uncomfortable one:

4. **The correction creates the next finding.** The `SECRET_KEY` fix killed the
   mirror. `cap_drop: ALL` made three services unable to write. #126's sweep
   from `stop` to `compose down` made #144's failure *more* likely to trigger.
   The orphan network was removed by hand and rebuilt 39 minutes later by the
   automation nobody thought to check. Masking a timer left a unit permanently
   failed. **Every fix deserves the same question as every mechanism: what does
   it now claim that it does not do?** Deploying before merging is what caught
   the last of those.

### A note on scope, for the next run

The dominant pattern is **enumerable rather than samplable**, and three
consecutive runs have sampled it. Measured on 2026-08-16: 18 declared
healthchecks over 42 services, 88 places where a failure can be swallowed
(`|| true`, `2>/dev/null`, `failed_when: false`, `creates:`), 31 monitors, and 5
hard-coded thresholds in the health and posture scripts — roughly 140 objects.
Sampling that space will keep returning findings indefinitely; enumerating it
once ends the pattern. Consider a bounded exhaustive pass instead of a fourth
general audit.

It will not cover defects of **absence** — nothing watches the Nextcloud cron's
freshness, and nothing noticed a WebDAV lock that produced 54 754 rejected
requests over three days in August and then resolved itself unremarked, in
either direction — nor the drift each deploy creates. Those stay the audit's
business. (That episode was also misreported as ongoing while it was already
over; see the 24-hour-window trap above.)

---

## Closed between 2026-08-17 and 2026-08-19 — three days of follow-up runs

The 2026-08-16 table above is now fully resolved except the four issues listed
at the end of this section. Everything here is merged **and deployed**; verify
it gone rather than rediscover it.

| # | Finding | Closed by |
|---|---|---|
| #152 | `rp_filter` declared twice in the sysctl template; the strict value silently won and the kernel dropped VPN client packets | PR #167 — single declaration, loose value; drops stopped |
| #153 | wg-easy's database was world-readable and held the interface key, four client keys and the admin hash | PR #163 — 0644 → 0600 |
| #155 | The offsite host was missed by two sibling sweeps: the distro `lynis.timer`, and a SMART guard that could report "SMART ok" without reading SMART | PR #166 — both sweeps completed on the second host. This is pattern 3 (partial sweep) caught once more; **check both hosts by default** |
| #156 | Five more controls that could not report the failure they name: netdata healthcheck, empty-secret assert, posture count, Lynis retries, DDNS failure branches | PR #170 — including "posture OK on 0 containers" and DDNS branches that could never execute |
| #157 | Three of eighteen certificates had no expiry watch, and a failed ACME renewal left no trace at all | PR #175 — `homelab-health.sh` now parses `acme.json` directly, 21-day threshold, 18/18 covered. Root cause of the blind spot: Traefik's WARN-level filter hides renewal logs, so a log-based watch was structurally impossible |
| #158 | A snapshot that missed its offsite copy was never retried, and the weekly check passed regardless | PR #173 — 7-day time-window filter; 18 snapshots had been at risk |
| #159 | Three database passwords could not be rotated, and the handlers made the no-op look like a rotation | PR #176 — see the rotation notes below |
| #161 | Four documentation statements that would mislead during an incident, out of 238 runbook commands checked | PR #165 |
| #162 | `it-tools:nightly` unrebuilt upstream for 185 days; Renovate cannot tell abandoned from current | PRs #162/#164 — ADR-024 now states an **exposure-based** drop condition; the original one measured the wrong thing |
| #168 | A failed `restic forget` was invisible to the monitor: retention stopped with the push still green | PR #171 |
| #169 | Thirty read-only probes had no `check_mode: false`, so a dry run guarded on output it never read | PR #172 |
| #137 / #174 | The backup assertions and the summary push, proven on fixtures only | Both closed on the real 03:00 runs — assertions fired with real byte counts, push carried restic's own summary, and the first night under the new offsite window was read before anything else |

### What the #159 rotation work established, and must not be re-derived

- **A deploy can rotate some secrets and not others.** Which is which is now
  written down in the repo, together with what the others need. Do not re-audit
  the question; read the doc.
- **The detection bug was a case mismatch** on `admin_token`, which is why the
  posture check could not see an unrotated secret. Fixed, and the posture check
  now makes a rotation that did not land report itself.
- **Password rotation must be verified through container-name probes**, not
  through `localhost` — a localhost probe succeeds against the wrong endpoint.
- **`knowledge/runbooks/rotate-a-secret.md` was wrong in three ways** and each
  was found only by running it: the step order, a missing `occ` step, and a
  required `notify_push` restart. The procedure is now correct; trust the file,
  not memory.
- Two live rotations were performed for real reasons: **Miniflux** (its password
  had been exposed in a `bash -x` trace) and **Nextcloud** (exposed in logs).
  Both completed and were re-verified. Not findings — history.

### New method traps, all paid for between 17 and 19 August

- **`docker logs --since/--until` parse in host local time while `-t` prints
  UTC.** Always suffix `Z`, and cross-check any total against an hourly
  histogram. This compounds the 24-hour-window trap recorded above.
- **`pihole setpassword` has no flags** and will happily take `--help` as the
  new password. Documented; do not "improve" the invocation.
- **The compose pull task always reads `changed` under `--check`.** It is not an
  idempotence defect and is documented as such.
- **A dry run is not free.** Two offsite tasks misbehaved under `--check` alone:
  one announced it would remount the backup disk, another aborted the play on a
  task check mode had skipped. Both fixed, but the lesson stands — `--check` has
  its own failure modes and they are not the play's.

### Still open going into the run of 2026-08-19

Four, and they are the only ones. Do not re-report them; do report anything that
makes one of them materially worse.

| # | Why it is still open |
|---|---|
| #128 | Traefik sees every VPN client as one Docker gateway address — `vpn-only` subnet rule dead, rate-limit one shared bucket. Needs local work |
| #138 | wg-easy cannot write its own database; a peer cannot be revoked. **Requires someone at the machine**: the first successful write regenerates `wg0.conf` and runs `wg syncconf` on the only interface that reaches the host |
| #154 | Neither ext4 volume is ever checked, and a weekly green timer checks nothing. Half doable remotely |
| #160 | `wg_easy_config` claims to enforce the VPN settings, cannot write, and would abort the deploy at step 4 of 12. Sibling of #138 |

---

## The run of 2026-08-19 — what it settled, and what it corrected

Fourth general audit. Baseline clean on both hosts: 0 failed units, 28/28
containers, 12/12 timers exited 0, 31/31 monitors UP. Twenty-three findings,
grouped into four issues — #177 (sweep residues), #178 (statements without
effect), #179 (push monitors), #180 (offsite tunnel, a decision).

### Two previously settled conclusions are now WRONG. Do not quote either.

- **"PENDING notifies nobody" is false.** PENDING escalates — with the wrong
  text. A push monitor at `maxretries=1` raises `"No heartbeat in the time
  window"` whenever the previous beat is not UP, and that raised beat is the one
  that notifies. Counted on notifying heartbeats: `Pi health` 4 alerts, 4 without
  the script's message; the monitors at `maxretries=0`, 6 of 7 kept it (the
  seventh is a genuine no-push case). And there are **two** monitors at
  `maxretries=1`, not three: `Pi health` and `DDNS`. Tracked in #179.
- **Swap is at 38 %, not 44 % and not 53 %.** The audit's own system agent
  headlined "~1800 MiB = 44 %" while citing its own cgroup measurement of
  1571.4 MiB in the same paragraph. Four instruments agree on 1571 MiB of 4095:
  `/proc/swaps`, `free -m`, `/proc/meminfo`, and the live Kuma push (`swap 38%`).
  Keep 85 % — the margin is 47 points, wider than previously believed. Both
  earlier figures were arithmetic errors on top of a conclusion that survived
  each time, which is now a pattern in its own right.

### Measured and rejected — added 2026-08-19

- **The whole secret store being world-readable.** Raised, investigated,
  refuted. The files are 0444 but the **directories** gate the path
  (`drwx--x--x` on `secrets`, `drwx--x---` root:docker on `docker/`); an
  unprivileged read is refused, with `/etc/shadow` refused in the same call as a
  control. The design is sound. What IS exposed is `/mnt/data/services`
  (`drwxr-xr-x`) — a different store, tracked in #177.
- **Transmission's empty-password branch as a present exposure.** The mechanism
  is real (the LSIO init disables RPC auth on an empty value) but impact today is
  zero: `rpc-authentication-required: true`, whitelist enabled, secret 128 bytes.
  It is a rebuild-from-example hazard, ranked accordingly in #177.
- **A read-data check against the offsite repository.** Never run, log complete
  back to 2026-05-14. Not proposed: it sits next to the declined restore drill.
- **The Lynis ratchet seeded at 73** rather than the 74 of #145. That single
  point is `malware_scanner_installed=0` — the arithmetic of rkhunter's
  deliberate removal. No action; recorded so 73 is not later read as drift.

### New instrument traps — three, and one of them was mine

- **`docker inspect .RestartCount` is inert here.** It reads 0 on all 28
  containers while the heal journal records 47 crash-restarts in 19 days. An
  audit concluding "nothing has restarted" from it would be wrong on every count.
  Use the heal journal.
- **mtime against commit date is a false drift instrument in this repo**,
  because deploying before merging makes deployed files legitimately older than
  their source commit. Nine artefacts read as drift until content was compared.
- **A permission error swallowed by `2>/dev/null` produced a wrong answer during
  the main session's own verification**: an unprivileged `grep` on the offsite
  WireGuard config returned nothing, which reads identically to "no Endpoint
  line". Re-run with `sudo`, it returned the hostname that the whole of #180
  rests on. The audit's own instruments are subject to the defect it hunts.

### Verified gone on the machines, not assumed

rp_filter (martians 213/day on 08-12, 49 on 08-17, last line 10 minutes *before*
the sysctl file was written, zero in the 44 h since; `TcpExtIPReversePathFilter`
frozen at 1653 across four samples). #158 and #168 on the real 08-19 run
("8 snapshot(s) offered… 1 new, 7 already there", zero offsite duplicates). The
cert parse, exhaustively: 18/18 `notAfter` values byte-identical to the leaf
served in a live handshake. The perimeter, probed from the offsite uplink with a
known-open port as control: everything else closed, no IPv6 anywhere.

### The pattern shift — the most useful thing this run established

**"The check cannot fail" is thinning.** Hit rate on the class this audit exists
to find: 5/5 on 2026-08-15, 5/12 on 08-16 evening, **4/23** now — and the new
instances are narrow (an `ext4 clean` over zero visited volumes, a cert block
skipped on a missing file) rather than structural.

**The dominant pattern is now the PARTIAL SWEEP**, five instances in one run:
#153 stopped at wg-easy, #155 stopped before the ext4 counter on the offsite
host, #161 swept documentation for existence and never for content, the
empty-secret guard stopped at 4 keys of 35, the cloud-init pin runbook covers one
host of two. The existing rule — every correction ends with a sweep for siblings
— is not enough. Sweep **both hosts and both axes**: existence *and* content.

Also worth carrying: roughly a third of this run's findings could not have been
found earlier. Three were created by fixes younger than 72 hours (pattern 4
again), and four required a search key minted between 17 and 19 August — the
file-mode axis from #153, and "where can a secret reach a log, a trace or an
argument list" from the two rotations of 08-19. The generalisation keeps paying
more than the instance.

### For the next run

The spaces that were genuinely **enumerated** this time came back clean: 28/28
healthchecks, 30/30 sysctls on both hosts, 18/18 certificates, the Ansible key
set in both directions, 19/19 bind-mount inodes against `/proc/<pid>/root`. That
is the third confirmation that enumeration ends a pattern where sampling does
not. Two spaces remain un-enumerated and are where the next yield is:
**file modes across both hosts**, and **the content of documentary claims** as
opposed to their existence.
