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
- **No git worktrees.** Work in the operator's directory, on their branch, and
  announce any branch switch — a checkout changes what their next deploy ships.
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

**The swap threshold is now calibrated.** Occupancy settled at **53 %** after
the resize, with post-resize daily maxima 1625.7 → 1974.8 → 2169.6 MiB —
concave, projecting to a 59–64 % steady state. **Keep 85 %.** Swap is cold
parking, not thrashing: +6 pages in and 0 out over 60 s, 20-day averages of
2.9 / 5.9 KiB/s. Re-read around 2026-08-30 for a restart-free confirmation, but
this is no longer an open loose end.

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
| #138 | wg-easy cannot write its own database: adding or **revoking** a peer fails behind a healthy container — found via #125 | open, **do at the machine** |

Still open and still cosmetic: one orphaned anonymous volume (~48 MB) from a
first container start. Remove by hand, never with a broad prune.

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
