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
- **The orphan `internal` network is gone**, removed 2026-08-22. It had survived
  since 14:51 on 2026-08-16 — the timestamp of the Ansible loop that rebuilt it
  39 minutes after the first hand removal, before that loop was fixed. Nothing
  recreates it: no Ansible task declares a bare `internal` network, and Compose
  declares `internal` without `external`, so it creates the project-prefixed
  `homelab_internal` instead. Identified unambiguously before deletion — the
  orphan carried **no Compose labels and 0 containers**, against 12 containers
  and a full label set on the live one — and `homelab_internal` was confirmed
  still carrying its 12 afterwards.

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

---

## Follow-up of 2026-08-20/21 — the 08-19 run is fully shipped

All four issues the 08-19 audit produced are merged and deployed, each verified
on the machines and idempotent: **#177** (sweep residues, PR #181), **#178**
(statements without effect, PR #184), **#179** (push monitors, PR #183),
**#180** (offsite tunnel, PR #185). Plus **PR #186**, a CI fix unrelated to the
audit. **#182 stays open by design**: three `notify()` sites and the dump gate
are still proven on fixtures only, and their real runs are Sun 2026-08-23 05:00
and 06:00 and Mon 2026-08-24 00:42.

### One of MY OWN entries in this file was contradicted without being read

On 2026-08-21 I told the operator #128 was the best remaining remote-doable
issue, reasoning that SSH does not traverse Traefik so a bad rule is
recoverable. The reasoning is true and answers the wrong question. **This file
already classified #128 as "Needs local work", and that classification is
right.**

Checked afterwards, on the compose file rather than from memory: wg-easy and
Traefik are **already on the same `proxy` network**. The source address is not
erased by a boundary between them but by the *path* — VPN traffic leaves to the
host and re-enters through the published port, arriving as the bridge gateway.
Correcting that means touching wg-easy's forwarding rules, or changing what VPN
clients resolve and therefore the `AllowedIPs` in **every client configuration**.
Both touch the only route to the host; the second also needs every device
re-provisioned.

The lesson is not about #128. **Read the reason column before contradicting the
table.** An entry that says why something is open is load-bearing, and
re-litigating it from a plausible-sounding argument is exactly the failure this
file exists to prevent.

### A live break test was repaired by a mechanism nobody had enumerated

The #180 mechanism was exercised for real: the offsite peer's endpoint was
forced to an unroutable TEST-NET-1 address with an unattended rollback armed
first. The tunnel recovered in **under ten seconds — and not by the mechanism
under test**, whose 150 s gate was never reached and whose journal stayed silent.

```
+0s   endpoint forced to TEST-NET-1        (handshake 117s)
+10s  endpoint ALREADY correct, handshake still ageing at 127s
+20s  new handshake completed
```

The middle line is the proof: corrected **without a new handshake**, so nothing
on that host initiated it. WireGuard's **roaming** did — a peer adopts the source
address of any authenticated packet it receives, and the homelab initiated a
rekey to the endpoint it still knew.

**Before breaking something to test a repair, enumerate every mechanism that
could repair it.** Otherwise the test measures the fastest one, which may not be
the one being tested, and a green result reads as proof.

The test also chose the wrong scenario: breaking the endpoint while the home
address is unchanged is precisely the sub-case roaming covers. The target
failure — a home address *change* — remains unexercised.

### Settled by research, do not re-derive

- **Roaming does NOT recover a server address change for a client behind NAT.**
  Upstream states it directly (a moved server cannot reach the client, "it needs
  client to initial the connection"; `PersistentKeepalive` does not help), and
  RFC 4787 explains why: the NAT holds a mapping created toward the OLD address,
  and address-dependent or address-and-port-dependent filtering — the common
  consumer behaviours — drop packets from a source the internal host never wrote
  to. Only one direction of repair exists: **the offsite host must send first**,
  which reaches the peer and opens the return path in the same packet. So the
  re-resolve timer is **load-bearing, not redundant**, and it holds under any
  filtering behaviour because it never asks that NAT to accept an unsolicited
  source.
- **The offsite tunnel is split**, and that is what makes any re-resolution
  possible: the host's resolver is its own LAN router over `eth0`, AllowedIPs
  carry the homelab VPN subnet only. A full-tunnel client could not look the name
  up while the tunnel was down, and only detection would have remained.
- **Handshake age is a sawtooth with a structural ceiling**: 60 samples at 5 s
  gave p50 55 s, p90 112 s, max 122 s, never above 135 s — WireGuard's ~120 s
  renegotiation plus establishment, not a variable that drifts. The 150 s gate
  sits 28 s above it. A spurious fire rewrites the same address on an existing
  peer and changes nothing.
- **`ansible-galaxy role install` does not accept `--no-cache`**; only
  `collection install` does (checked against ansible-core 2.21.2). The response
  cache cannot help on a runner that starts empty — it is reusable only between
  the two invocations of one job.
- **Navidrome reads `ND_SCANNER_SCHEDULE`**, and an unknown `ND_*` warns about
  nothing. Check the boot log for `Scheduling periodic scan`, never the variable.
- **`deploy_services` with more than one service needs the JSON form**
  (`-e '{"deploy_services": "a b"}'`); the shell eats the quotes otherwise.
- **Credential stores are gated by DIRECTORY mode 0700**, not per-file modes,
  because SQLite recreates `-wal`/`-shm` with the process umask. Safe only
  because each of the five is bind-mounted by exactly one container and reached
  as the directory's own owner — no `DAC_OVERRIDE` dependency, so no repeat of
  #138.

### New instrument traps — four, three of them mine

- **`head -10` truncated a sweep and hid its only real result.** The sweep for
  the false "PENDING does not notify" claim reported clean on docs and templates;
  the one genuine instance was a comment block in `homelab-health.sh.j2`,
  asserting it about the very monitor #179 was changing. **Never pipe a
  completeness sweep through `head`** — cap the output, or count it, but do not
  truncate the evidence you are about to call complete.
- **A regex found 2 of 4 unsized tmpfs; the YAML parser found 4.** Structured
  files get parsed, not grepped, when the question is "how many".
- **The journal bounds the journal, not reality.** "1239 DDNS runs unchanged"
  reads as long-term stability; it reaches back 13 days. Cloudflare's own record
  answers properly — `created_on == modified_on == 2026-07-19` means the address
  has *never* changed. Ask the authoritative system, not the local log.
- **zsh command-substituted a backticked segment inside `git commit -m`**,
  silently emptying it. Write long messages to a file and `-F` them, and verify
  from the commit object rather than the exit code.
- Related, from the same evening: an unprivileged `grep` with `2>/dev/null` on a
  root-only config returned nothing, which is indistinguishable from "the line is
  absent". A permission error swallowed is a false negative.

### Still open going into the next run

Five, and four of them share a cause.

| # | Why it is still open |
|---|---|
| #128 | Traefik sees every VPN client as one gateway address. **Local work** — the fix touches wg-easy's forwarding or every client's `AllowedIPs`; already re-confirmed once, do not re-litigate |
| #138 | wg-easy cannot write its own database; a peer cannot be revoked. **Requires someone at the machine** |
| #154 | Neither ext4 volume is ever checked. **Half doable remotely**: the configuration change is remote, the verification needs a boot-time check or an unmount of `/mnt/data` — and `/mnt/data` carries wg-easy, so unmounting it removes remote access |
| #160 | `wg_easy_config` cannot write and would abort the deploy at step 4 of 12. Sibling of #138 |
| #182 | Scheduled, not blocked: the three unrun `notify()` sites and the dump gate fire on their own over 23–24 August |

The four blocked ones all touch **the tunnel or the disk** — the two things that
cannot be broken without someone on site. That is not a planning accident; it is
what remained after everything else was done.

Also open: **Renovate PR #88**, eleven image bumps, one of which is wg-easy.
It cannot be merged whole from a distance. Split the wg-easy bump out, ship the
other ten, and hold the VPN upgrade for a day with physical access.

## The run of 2026-08-21 — one pattern, four instances, and one finding that dissolved

The baseline was clean before the fan-out: zero failed units, 28 containers up,
eight `homelab-*` timers at exit 0, 31/31 monitors UP. The run still returned
findings, which is the whole argument for running it against a green surface.

One piece of baseline work paid for itself immediately: five containers had been
recreated at the same second the evening before, and checking `RestartCount=0`
and `OOMKilled=false` **before** briefing the agents kept two of them from
reporting "unexplained restarts". It was PR #186 shipping, nothing more.

### The run's headline finding was the household leaving on holiday

Written down in full because it was the most confident wrong conclusion of the
run, and the correction cost one sentence from the operator.

Since **2026-08-08**, not one LAN address had sent a query:

| Day        | Queries | Distinct clients |
|------------|---------|------------------|
| 2026-08-07 | 42 364  | 7                |
| 2026-08-08 | 27 460  | 7 ← the break    |
| 2026-08-09 | 24 251  | 3                |
| 2026-08-20 | 46 635  | 4                |

The four LAN clients stopped between 08:56 and 14:34 on the same day, and the
remaining traffic was the VPN peers, the Docker gateway, the loopback and the Pi
itself. Every fact was correct and independently re-measured. The reading built
on them — a resolver nobody uses any more, ad-blocking silently off for the whole
LAN — was wrong.

**2026-08-08 is the day the operator left for holiday.** The devices went with
them. The VPN peers that kept querying throughout are the same people, remotely.
Nothing broke; the house emptied.

The rules this buys, and they are cheap to apply:

- **Ask what changed in the household, not only in the configuration.** Nothing
  on either machine could have distinguished the two readings, and no amount of
  further measurement on the machines would have either. One question to the
  operator settled it in a sentence.
- **A disappearance is not an event until something identifies the disappearing
  side.** Traffic that stops in a band of a few hours on a single day describes
  people at least as well as it describes machinery.
- **Do not build an alarm on this.** "No LAN client is querying" is true every
  time the house is empty for a week, so any monitor asserting it would fire on
  holidays and teach everyone to ignore it. The gap it appears to expose — Kuma
  asserts the resolver answers, never that anyone asks — is real but not worth
  closing, for exactly that reason.

The one follow-up worth keeping is dated and manual: **after the return, confirm
that LAN clients reappear in the query log.** If they come back and do *not*
resume querying, that is the finding this run thought it had.

Two smaller things, still true: pinging those addresses at 01:00 and finding them
silent with `INCOMPLETE` ARP entries proves nothing — a sleeping phone answers
identically, and an absent one does too. And the remaining traffic kept the daily
count high enough that no volume-based alarm could have fired either way.

### The pattern: four sweeps, each stopped one instance short

Every correction of the previous week was applied to the set its author had open,
not to the set that shares the defect.

| Sweep                    | What it closed                         | What it left behind                                                  | Issue |
|--------------------------|----------------------------------------|----------------------------------------------------------------------|-------|
| argv (#177)              | 11 scripts moved to `curl -K -`        | the `claude-code` role — `feed-digest` leaks **two** credentials     | #188  |
| credential stores (#177) | 5 directories set to 0700              | `pihole.toml`, 644 under 755 parents, carrying the API password hash | #189  |
| dump guards              | 3 gates became `check_sqlite_dump`     | the 4th, Immich: no `else`, and content never asserted               | #190  |
| accepted 401 (#145)      | the Transmission container healthcheck | the Kuma monitor, still accepting 401                                | #191  |

Two of the four were found independently by two agents each, from different
angles — that convergence is what moved them from lead to finding.

**The lesson for the next sweep**: enumerate the class from the property that
defines it (every process that hands a credential to `curl`, every store holding
a hash, every dump the script does not produce itself), not from the files
already open in the editor. All four instances were outside the directory the
original work was in.

### Reported on 2026-08-21, not yet decided

Kept here so the next run does not re-derive them from scratch. Evidence is in
that run's reports, outside the repo.

- **The 5 TB drive's temperature threshold is its own lifetime maximum.** The
  daily check alarms at 60 °C and comments "rated to 65"; the drive reports
  `Specified Max Operating 50`, `Power Cycle Max 56`, `Lifetime Max 60`. It is
  sampled once a day, so the peak is never seen. `-l scttempsts` reads the max
  since power-up. Same sweep applies to the offsite host.
- **The documented mirror-staleness threshold cannot fire.** The observability
  page promises an alert after 4 h without a completed sync; the mirror interval
  is 8 h and the grace is one more, so the earliest possible alarm is 9 h.
- **46 container resurrections in 30 days that nothing counts** (44 miniflux, 2
  miniflux-db). Unit flapping is watched closely; the heal timer's own journal is
  read by no instrument. Two agents, two routes, same gap.
- **One floating image tag out of 28**: miniflux's database. Renovate cannot
  raise a PR against it, so the binary can change under the data directory
  without a commit.
- **The stored `offsite-backup` VPN profile is full-tunnel** while the deployed
  one is split. Regenerating it from the UI would remove the recovery path #180
  added. Two documentation lines — attach them to #138, do not open a row.
- **The Discord notification is not the default.** 31/31 monitors are bound
  today, but the next one entered by hand is born with no alerting path.
- **A pre-branding copy of the compose file** sits next to the live one, dated
  5 July, referenced nowhere, carrying 13 floating tags — one of which would
  refuse to start against the current data directory. A `rm`.
- **The box-reset warning covers the web ports and omits the published DNS one**,
  the only one with no application-layer guard. Proved closed today from the
  offsite uplink, with a known-open port as control.
- The offsite VPN role claims a name "resolves publicly" when it has no public
  record; the `/etc/hosts` pin is what makes it resolve at all.

### Measured and rejected — added 2026-08-21

- **The swap question is answered, and the 08-30 recheck can be closed.** It is a
  ceiling, not a ramp: 3 % after the 08-16 restart, peak 1826 MiB (44.6 %) on
  08-18, then **down to 1620 MiB with no restart at all**, and 1460 MiB (35.7 %)
  on 08-21. Forty points below the 85 % gate. Re-open only on a peak above
  44.6 %.
- The same measurement shows **the 08-15 resize was not cosmetic**: `free+used`
  was 2048 MiB until 08-15 10:51 UTC, with mean free swap between 1.6 and
  9.7 MiB for about ten days. The cold-page set measured now would not have fit.
- **Memory stalls are bounded, not worsening**: 0.067 % of time above 5 % before,
  0.069 % after — same frequency, amplitude halved (34.93 → 14.96 %). Every daily
  maximum falls inside the 03:00 backup window.
- **ext4 reserved blocks on the data volume** (250 GB): pointless against a
  ten-year runway at +0.97 GiB/day.
- **dm-crypt write latency** (123 ms against 1.7 ms on the raw device): real, but
  the only lever touches the unlock path for 1.3 % blocked time, and per-bio
  accounting biases the mean.
- **SD wear**: 1.94–1.97 GB/day on two concordant instruments, about eleven card
  rewrites a year. No action.
- **Collabora's 33 `coolmount`/`CAP_SYS_ADMIN` errors and its 95.8 s jail copy**
  are documented and decided in ADR-021. Refuted on the machine before being
  written down; do not re-report.
- **fail2ban has never banned anything** — and the absence of `f2b` chains is
  **not** proof it is broken: 1.0.2 enables `actionstart_on_demand` by itself.
  Only a reversible drill settles it, and an audit is read-only, so it stays
  suspected.

### New instrument traps — eight, two of them mine

- **Mine: counting the heal journal with a grep that matched systemd's own lines
  returned 26 922.** The real number is 46. Count only what the script itself
  emits, never the unit's start/stop chatter around it.
- **Mine: ping and ARP at 01:00 say nothing about a device's presence.** A
  sleeping client is indistinguishable from an absent one. It nearly turned a
  solid finding into a wrong causal claim.
- **`no_log` does not mask `environment:`** — both tasks leak identically under
  `-vvv`. Do not propose adding it to `restic init`.
- **`default:` in an `argument_specs` file defines nothing** (measured on
  ansible-core 2.21.2; 0 of 113 in this repo rely on it).
- **`is-enabled` counts the `mnt-data.mount.wants` links**, which inflates any
  enabled-unit tally that goes through it.
- **A `*unattended*` glob returns the inverse of the truth on the offsite host.**
- **The `config-hash` drift check gives a systematic false positive on dnsproxy**:
  Compose resolves `network_mode: service:pihole` to a container ID before
  hashing. Proved by substitution — the correct reading is 28/28 conforming.
- **An unprivileged shell glob evaluated in front of `sudo`, under a 0770
  directory, reads as "path does not exist"** — the same false-negative family as
  the swallowed permission error already recorded above. And
  `grep "^#\+ *Restore"` misses `## Data and Restore`, which nearly produced a
  false finding about Calibre-Web's restore procedure.

### One entry in this file was wrong: `.RestartCount`

It is not inert. It counts **policy** restarts only — useless for the 23
containers at `restart=no`, which is presumably how it got written off, but it is
the right instrument for the five Tier-0 ones, and those write no line in the
heal journal at all.

### Verified clean by enumeration — do not re-derive without a new symptom

- **Repo→host drift is zero on both hosts**: 21/21 verbatim copies identical by
  sha256, 23/23 homelab templates and 9/9 offsite artefacts identical line by
  line.
- 93 operator keys with no dead knob (`offsite_ip` is read by the inventory);
  45 `notify:` with no orphan handler; no `command`/`shell` without
  `changed_when` or `creates:`; 81 silent-disablement constructs read one by one,
  the three gates on absent variables documented and applied.
- 28/28 arm64, 28/28 log rotation, 37 tmpfs all sized, healthchecks with zero
  retained probe failures, mount coherence, `depends_on`.
- Perimeter: no IPv6, 19/19 routers carrying all three middlewares, headers
  served on 18/18, `sniStrict` proven, 18/18 certificates at 49–83 days, split
  DNS 18/18, a single DoH upstream, gravity fresh.
- **No no-op push**: all 12 push monitors carry their own script's message. The
  constant DDNS message means the address has never changed; lynis reporting
  `best 0` is the bootstrap run, and the file holds 73.
- Documentation: 100 relative links with none broken, 153 absolute paths, 28/28
  image tags, 17/17 thresholds in the health script, every timer schedule, and
  the restore runbook point by point.
- Backup verified on **content**, not presence: all five dumps and all seven
  Immich dumps byte-identical between the two hosts, 44 snapshots continuous
  since 2026-07-11 with only the documented 07-20 hole.

### Still open going into the next run

| #    | Why it is still open                                                                                                   |
|------|------------------------------------------------------------------------------------------------------------------------|
| #188 | `feed-digest` hands two credentials to argv. Remote, two lines, the only live exposure of the run                      |
| #189 | `pihole.toml` readable by every local account. Remote, one line in two places                                          |
| #190 | The Immich dump guard skips silently and never asserts content. Remote, one commit                                     |
| #191 | The Transmission monitor accepts 401. **UI plus a doc line** — Kuma monitors are entered by hand                       |
| #128 | Traefik sees every VPN client as one gateway address. **Local work**; already re-confirmed twice, do not re-litigate   |
| #138 | wg-easy cannot write its own database; a peer cannot be revoked. **Requires someone at the machine**                   |
| #154 | Neither ext4 volume is ever checked. **Half doable remotely** — the verification needs a boot-time check or an unmount |
| #160 | `wg_easy_config` cannot write and would abort the deploy at step 4 of 12. Sibling of #138                              |
| #182 | Scheduled, not blocked: the unrun `notify()` sites and the dump gate fire on their own over 23–24 August               |

The four new ones are all remote work. The four blocked ones still touch the
tunnel or the disk, unchanged from the previous run.

Also still open: **Renovate PR #88**, eleven image bumps, one of which is
wg-easy. Split that one out, ship the other ten, hold the VPN upgrade for a day
with physical access.

---

## The run of 2026-08-22 — the yield does not decay, and the reason matters

Fifth general audit. Baseline clean before the fan-out on both hosts: 0 failed
units, 28/28 containers, 12/12 timer services at exit 0, 31/31 monitors UP. Eight
agents, ~29 confirmed findings, grouped into seven issues — **#198** (argv),
**#199** (credential stores), **#200** (Kuma), **#201** (offsite health),
**#202** (Pi-hole log), **#203** (documentation), **#204** (rate limit).

One piece of baseline work paid for itself again: eight containers had started
recently, and checking `RestartCount=0` / `OOMKilled=false` / `restart=no`
**before** briefing the agents stopped them being reported as unexplained
restarts. They were the 08-19 and 08-20 deploys.

### Two entries in this file are now wrong. Do not quote either.

- **"The 4 `DAC_OVERRIDE` and the 4 writable rootfs are structural"** — it is
  **5 and 6** since Calibre-Web (2026-08-05). They remain structural and are not
  to be re-proposed; only the count drifted, and it drifted because a service
  arrived after the verdict was written and was never read under it.
- **"87 rate-limit rejections"** — the real figure is **851 over nine days**,
  a tenfold undercount. That entry already flagged its own instrument as
  unreliable; the correct count anchors on the status field of the CLF access
  log. All 851 are on the SearXNG image proxy, the most recent the day before.

### The headline: a fix from six days earlier created a continuous exposure

#145 replaced a Transmission healthcheck that could not fail (it accepted a 401)
with `transmission-remote`, which authenticates — **through the command line**.
Captured from an unprivileged account, digest compared against the secret file:
the full RPC password, every 30 s, **2 880 times a day**. Pattern 4 in its purest
form, and the largest finding of the run.

The credential must be treated as disclosed and rotated, not merely hidden: the
account that could read it is the one running a model over arbitrary third-party
feed content every morning.

### Two spaces are now ENUMERATED, and that is the useful outcome

`settled.md` has said since 2026-08-16 that enumeration ends a pattern where
sampling makes it recur. Both spaces it named as un-enumerated were closed this
run, by hand, after the agents finished.

**The 20 service pages, three axes each** (does the page agree with its ADR, its
runbook, and its container?). All 20 read in full. **11 are clean on all three
axes**; nine carry ten findings, two of which the sampled pass had missed — the
Nextcloud monitor documented as `HTTP(s)` when it is a Keyword check on
`"maintenance":false,"needsDbUpgrade":false`, and `claude-code.md` claiming a
`/sandbox` confinement that does not exist. Seven of the ten have the same
signature: **the correction reached the ADR and/or the runbook and stopped before
the service page.** `docs/05-services/*.md` is the set every sweep forgets, and
it is the first thing anyone opens during an incident.

**The "any argv" class on `compose.yaml`.** Four axes, because the text alone
proves nothing:

- static YAML parse of all 28 services — 24 command lines built across
  `healthcheck` / `command` / `entrypoint`, exactly **one** carrying a
  credential; the 4 interpolated `${VAR}` are database names and users; **0**
  labels match;
- **child processes**, because a clean command line can spawn a dirty one:
  MariaDB's `healthcheck.sh` uses `--defaults-extra-file=` (a path), and Immich's
  own scheduled dump passes `PGPASSWORD` in the child's **environment**
  (`/proc/<pid>/environ` is 0400), not in argv;
- **scheduled in-container jobs**, outside any sampling window by construction:
  `nextcloud-cron` is `busybox crond`, no credential;
- **empirical** — 35 real secret values extracted structurally from the secret
  files and four `.env` files, 3 457 sweeps of `/proc` over 140 s covering more
  than two cycles of all 24 healthchecks, 3 808 distinct command lines,
  **positive control passed**, **exactly 1 match**.

The empirical axis proves *continuous* exposures only. The nightly and
deploy-time sites were established by reading the deployed artefacts. Say so
rather than claiming the class is empty everywhere.

### The most important correction of the run was to one of our own agents

The security agent concluded, after "an exhaustive enumeration of argv across all
deployed executables on both hosts", that there was **exactly one** live
instance. It was wrong, and the reason is the pattern this audit exists to find:
its scope was *deployed scripts*, and the worst instance lives in
`compose.yaml`. It also reported "no control that cannot report its own failure"
while three other domains found three.

**An audit agent defines a class as narrowly as the sweep it is auditing.** Where
two agents disagree, resolve it before writing a word to the operator — and treat
a confident negative from a single domain as a claim about that domain's scope,
not about the class.

### Does the yield decay? No — and the reason is not that the system is rotten

Counted honestly: 5 findings (08-15), 9 (08-16 am), 12 (08-16 pm), 23 (08-19),
4 + 9 undecided (08-21), **~29 (08-22)**. Neither quantity nor severity is
falling — this run's headline is a continuous credential exposure and a
supervision healthcheck that cannot fail, the same calibre as the founding run.

The law that fits the data: **the yield tracks the quality of the search key and
what shipped since the last run, not the residual defect stock.** This run's
biggest finding came from a key minted 24 hours earlier (#188's "any argv").

There are **two stocks**, and only one of them drains:

1. **Design defects** — structural, severe, genuinely being exhausted. No
   equivalent of the dead mirror or the three unwritable services this time.
2. **Sweep residue** — created by the corrections themselves, and therefore
   **recharged by every fix**. Five of this run's biggest findings are children
   of previous corrections.

What empties the second stock is not another general audit. It is enumerating the
class by its defining property. Every space enumerated once has come back clean
and stayed clean across four runs — and two more closed this time.

### New instrument traps — five, four of them ours

- **`find -size -1M` matches only EMPTY files.** `find` rounds block counts up,
  so any non-empty file under a megabyte occupies 1 block and is not `< 1`. A
  sweep silently fell from 89 371 files to 724 and returned "0 matches" twice.
  Use `-size -1000000c`. **Only the positive control revealed it.**
- **`sudo -u <other> find` ABORTS if the cwd is not traversable by that account**
  — 10 files returned out of 1 069. With `2>/dev/null` that is indistinguishable
  from a clean system. `cd /` first, and never discard `find`'s stderr.
- **`/etc/os-release` is a symlink**, so `-type f` excludes it. A positive
  control must be a regular file; `/etc/passwd` works.
- **A `/proc` sweep that reads the pid and then re-opens the file loses the
  race.** Short-lived processes evaporate between the two reads
  (`No such file or directory`). Let one `grep` read `/proc/*/cmdline` in a
  single pass. And exclude the sweeper's own command line, or it matches itself.
- **The harness truncates too, not only the command.** A 150 s measurement was
  killed by a 2-minute tool timeout and still wrote partial output that looked
  like a complete result; only exit code 143 gave it away. This is the "never
  pipe a completeness sweep through `head`" rule in a form this file did not
  cover.

And one method note worth more than the traps: **a null result is worthless
without a positive control.** "1 match" and "the sweep is broken" are the same
observation until something known-present is shown to be found.

### Verified gone on the machines, not assumed

The four findings of 2026-08-21 (#188–#191) were confirmed **on the hosts** before
the fan-out, not from the commit log: `digest.sh` uses `--data-urlencode`, the
Pi-hole store directory is 0700, and the Immich guard now reads the dump. That
guard then fired for real on the 03:00 run of 2026-08-22 —
`fresh <48h, completion marker present`, with a real byte count — which closes
the dump-gate half of #182 on a real run rather than on fixtures. The offsite
host's armed 04:00 reboot happened and it came back unaided: disk mounted,
0 failed units, 6 security updates installed, and the night's copy landed
(46 snapshots, newest 03:05:49).

### Still open going into the next run

| #    | Why it is still open                                                                                                   |
|------|------------------------------------------------------------------------------------------------------------------------|
| #198 | The argv class: one continuous exposure plus four narrower sites and five documented commands. Remote, one commit + a rotation |
| #199 | The nightly dump copies are world-readable, and `forgejo.db` is the seventh store. Remote, two lines                   |
| #200 | Kuma notifies once per incident, and its own healthcheck cannot fail. UI plus one healthcheck                          |
| #201 | The offsite health report never thresholds the CPU temperature the runbook says it watches. Remote                     |
| #202 | Pi-hole's query log is orphaned and its rotation is permanently skipped. Remote                                        |
| #203 | Fourteen documentary statements that contradict their ADR, runbook or container. Remote, one commit                    |
| #204 | The Traefik rate limit rejected 851 real requests in nine days. Remote, one value                                      |
| #128 | Traefik sees every VPN client as one gateway address. **Local work**; re-confirmed twice, do not re-litigate           |
| #138 | wg-easy cannot write its own database; a peer cannot be revoked. **Requires someone at the machine**                   |
| #154 | Neither ext4 volume is ever checked. **Half doable remotely**                                                          |
| #160 | `wg_easy_config` cannot write and would abort the deploy at step 4 of 12. Sibling of #138                              |
| #182 | The dump gate is now proven on a real run; the unrun `notify()` sites remain                                           |

Seven new ones, all remote work. The four blocked ones still touch the tunnel or
the disk, unchanged for a third run.

Also still open: **Renovate PR #88**, eleven image bumps, one of which is
wg-easy. Split that one out, ship the other ten, hold the VPN upgrade for a day
with physical access.

### For the next run

Both spaces named last time are now enumerated. The two that remain sampled, and
are therefore where the next yield is:

- **What each container's own scheduled work does** — the in-container jobs that
  run rarely enough that no sweep window catches them. Two were checked by hand
  this run (Immich's dump, the Nextcloud cron); nobody has enumerated the set.
- **The offsite host as a whole.** Three of this run's findings were its missing
  half of a homelab control. It has been the trailing edge of four sweeps now
  (#155, #156, #201), which makes "check both hosts by default" a rule that keeps
  being written down and not applied.

---

## Shipped the same day — 2026-08-22 evening

Five of the seven issues the morning run produced were fixed, deployed and
**verified on function rather than on status**, all remotely, in one afternoon:
**#198** (argv), **#199** (credential-store copies), **#201** (offsite health),
**#203** (fourteen documentary statements), **#204** (rate-limit burst). What
remains is #200 and #202 — both recreate a container — and #207, which waits for
someone at the machine.

### What each fix actually proved

- **#198.** The Transmission healthcheck moved to `-ne`/`TR_AUTH`. Proven by PID:
  the process's argv reads `sleep 25`, its `environ` carries the value at 0400,
  and an unprivileged read of `environ` is refused. Then proven again in
  operation — a 140 s `/proc` sweep with a positive control **saw
  `transmission-remote` run twice** and found the secret in **zero** command
  lines. `backup.sh` reads the secret inside the container through `MYSQL_PWD`,
  which also made `NEXTCLOUD_DB_PASSWORD` dead weight in `backup.env`; it is
  gone. Pi-hole gained a Docker secret because `pihole setpassword` takes its
  argument from the command line and nowhere else. **The RPC password was
  rotated**, and the rotation was proven rather than assumed: the digest of the
  secret file changed, the new value was accepted and a wrong one refused.
- **#199.** `install -d -m 0700` for the nightly dumps, `0700` on Forgejo's data
  directory, both now asserted by the posture check. The load-bearing check was
  **not** the mode but whether Forgejo could still WRITE — it can, `touch` and
  `database:ping` both pass. That is the #138 question, asked before it could
  bite instead of six weeks later.
- **#201.** CPU temperature thresholded at 70 (not the homelab's 80 — that board
  idles at ~50 °C and its fan engages at 60), the `apt-check` guard ported, and a
  "visited nothing" guard added to the undervoltage loop. Verified by the real
  push: `SMART ok, disk 20%, ext4 clean (2), ssd 43C, cpu 51C, tunnel 75s` —
  green, carrying the temperature, not alarming on it.
- **#204.** `burst` 50 → 250, sized on **episodes** rather than seconds. Verified
  from Traefik's own API rather than from the file:
  `{"rateLimit":{"average":100,"burst":250},"status":"enabled"}`.

### Corrections to entries written earlier the same day

Recorded rather than edited away, because each was a confident wrong reading.

- **`notifempty` does NOT make Pi-hole's rotation skip forever.** #202 says it
  does; the nightly job runs `logrotate --force`, and `--force` overrides
  `notifempty`. The mechanism is also not system logrotate at all — there is no
  `cron.d` entry and no state file — but `pihole flush once quiet` at 00:00,
  which runs logrotate with its **own** state file and **no FTL restart**, so
  reopening depends entirely on the `postrotate` `kill -USR2`. That signal has a
  valid target: the pidfile exists and matches `pidof`.
- **The #198 deploy accidentally cured #202's symptom.** Recreating pihole for
  the secret mount wiped `/var/log/pihole`, which lives in the writable layer.
  The orphaned 71 MB inode is gone and the log is healthy again — and five days
  of query history were destroyed by a deploy that had nothing to do with
  Pi-hole. The design defect is now *observed* rather than inferred.
- **The marginal sector was not new.** It was reported as appearing that
  morning. The drive's self-test log shows the **same LBA** failing at 2529 h,
  2363 h and 2363 h of power-on time — three reproducible failures over about
  seven days.
- **The offsite SMART test is already `-t long`.** #207 suggested folding a
  short-to-long change into #201; wrong — the short-test gap is homelab-only.

### New facts, established on the machines

- **A remote reboot of the homelab is impossible, and this is now a rule.**
  `/etc/wireguard/wg0.conf` is a symlink onto the encrypted volume, so after a
  reboot it dangles and `wg-quick@wg0` cannot start; `wg-easy` cannot either,
  being a container on the same volume. `homelab-unlock` asks for the passphrase
  interactively. **No unlock without the tunnel, no tunnel without the unlock.**
  `claude-remote-control` is no escape hatch — its vault mount needs Nextcloud,
  hence docker, hence the unlock. Stated by the operator as a standing
  constraint: they go home to reboot.
- **Recreating pihole orphans dnsproxy, and nothing paired them.** `dnsproxy`
  runs in pihole's network namespace; `compose up` recreates pihole whenever its
  definition changes, which destroys that namespace while dnsproxy stays up and
  healthy — a LAN-wide outage with both containers green. The `Restart pihole`
  handler pairs them; nothing did after a compose recreate. Now guarded by a
  namespace comparison rather than by inspecting `compose_result.actions`, so it
  also covers a recreate nobody predicted.
- **Rotating a credential can require a change in Kuma.** Exactly **1 of the 31**
  monitors authenticates (Transmission, since #191), and its password lives in
  `kuma.db`. A rotation that stops at the deploy leaves the monitor red with
  nothing on the host to explain it. The general form: **a change that makes a
  service authenticate creates a credential copy wherever it is monitored from.**
- **The household has still not returned.** One LAN client, ~20 queries on 08-16,
  08-17 and 08-21, none today. The dated follow-up from the 08-21 run therefore
  stays open, and it is what makes the reboot constraint above bite.

### New instrument traps — six, all paid the same day

Worth more than the fixes, on the usual reasoning.

- **A SQL `LIMIT` truncates a completeness sweep exactly like `head`.** Querying
  the last 10 heartbeats across five monitors returned only the two daily ones,
  and three monitors looked absent. Query per monitor, or count, but never bound
  a completeness question by a global limit.
- **A canary injected on the command line matches itself.** The first attempt to
  prove the argv fix passed the marker to `docker exec`, so the sweep found four
  hits — all of them mine. Let the value come from the file at runtime, exactly
  as the mechanism under test does.
- **A two-step `/proc` read loses the race.** Finding the pid and then reopening
  `cmdline` returns `No such file or directory` for anything short-lived. Let one
  `grep` read `/proc/*/cmdline` in a single pass.
- **Stripping Jinja with `sed` to shell-check a template produces broken shell,
  twice.** `{{ }}` and `{% %}` both have to go, and removing `{% if %}` lines
  leaves orphan `fi`. It reports a syntax error in *your filter*, not in the
  file. Extract the block you added and check that alone.
- **The harness truncates too.** A 150 s measurement was killed by a 2-minute
  tool timeout and still printed partial output that looked like a complete
  result; only exit code 143 gave it away. Same family as the `head` rule, one
  layer up.
- **A green monitor carrying its own script's message can still be unproven.**
  Three push monitors showed exactly the text #182 asks for — from runs three
  days *older* than the deploy that rewrote them. Compare the beat's timestamp
  with the artefact's mtime before ticking anything off.

### Still open

| #    | Why                                                                                                     |
|------|---------------------------------------------------------------------------------------------------------|
| #200 | Kuma notifies once per incident, and its own healthcheck cannot fail. Remote, but recreates a container   |
| #202 | Pi-hole's rotation. Symptom cleared by accident; cause undecided until the 00:00 run is observed          |
| #207 | One marginal sector, seven days old. **On site**, during the reboot, before the volume is mounted         |
| #182 | Four scheduled observations, all within 48 h                                                              |
| #128 | Traefik sees every VPN client as one gateway address. **Local work**, re-confirmed twice                  |
| #138 | wg-easy cannot write its own database. **Requires someone at the machine**                                |
| #154 | Neither ext4 volume is ever checked. Configuration change is remote; verification needs the on-site reboot |
| #160 | `wg_easy_config` cannot write and would abort the deploy. Sibling of #138                                 |

Also open: **Renovate PR #88**, eleven image bumps, one of which is wg-easy.

Four of these now share one moment: #207, #154, #138 and #160 all resolve during
the same on-site visit, and the reboot that #207 needs is the one #154's
verification wants. Plan them as one trip, not four.
