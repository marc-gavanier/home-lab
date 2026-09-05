# The class register

The audit's unit of progress, and the only object in this skill that can reach
zero.

## Why the unit had to change

Nine runs between 2026-08-15 and 2026-08-29 produced 5, 9, 12, 23, 13, 29, 26,
4 and 23 findings. Counting that way, the work looks endless, and the operator
reasonably asked whether a hundredth run would still return something.

It would. But the number is an artefact of the unit, not a property of the
system. Mapping the 23 findings of the 2026-08-29 afternoon run onto the classes
below gives a different picture:

| Class                                   | Named un-enumerated on | Findings on 2026-08-29 |
|-----------------------------------------|------------------------|------------------------|
| Content of documentary claims           | 2026-08-19             | 11                     |
| The offsite host as a whole             | 2026-08-22             | 3                      |
| Instrument answers a different question | —                      | 3                      |
| Delivery path of a working detector     | —                      | 2                      |
| Posture-check coverage gaps             | —                      | 1                      |
| `start_period` (reopened)               | —                      | 1                      |
| Cost of what feeds the alarms           | —                      | 1                      |
| Sampling instant of a threshold probe   | 2026-08-21             | 1                      |

**Fourteen of the twenty-three fell into two classes this file's predecessor had
already named as un-enumerated, ten and seven days earlier.** They were not
unforeseeable. Nothing obliged anyone to close the class, so each run sampled it,
fixed three instances of eleven, and left it open for the next.

That is the loop. Not a rotting system — a wrong unit of measure. `settled.md`
has carried the correct rule since 2026-08-16 and it has held through four
subsequent runs:

> **Enumeration ends a pattern where sampling makes it recur. Every space
> enumerated once has come back clean and stayed clean.**

A finding is not a countable object: how many exist depends on the search key,
which is written fresh for every run. A **class** is countable, and closing one
is permanent.

## What a class is

Three things, all mandatory. Two of them is not a class, it is a hunch.

1. **A defining property** — the predicate that decides whether an object
   belongs. Written so that someone else applies it and gets the same answer.
2. **An exhaustive space with a cardinal** — the finite set the property can
   live in, and its size `N`. If you cannot state `N`, you cannot close the
   class; you can only sample it forever.
3. **A gate** — the assertion that keeps it closed once swept. Without one, the
   class reopens on the next deploy and the sweep has to be redone by hand.

The scope trap, paid for on 2026-08-22: **define the class by its property, not
by the directory you happen to be reading.** A security agent concluded "exactly
one live instance" from an enumeration of deployed *scripts*, while the worst
instance was a healthcheck in `compose.yaml`.

## The four states

```
OPEN  ──swept N/N, counted──▶  ENUMERATED  ──assertion deployed──▶  GATED
  └──────────────arbitrated by the operator────────────────────▶  DECLINED
```

- **OPEN** — the property is named, the space is not fully swept. Findings here
  are audit results.
- **ENUMERATED** — swept once, completely, with the count recorded. Findings
  here should not recur, but nothing prevents a deploy from reopening it.
- **GATED** — a live assertion fails when the property reappears. **A finding in
  a GATED class is not an audit result; it is a broken gate**, handled like a red
  test.
- **DECLINED** — the operator considered it and said no. Re-raising requires a
  new fact, not a new argument.

## The three rules

1. **A finding is never recorded alone.** It is recorded as an instance of a
   class. If it fits none, **mint a new class** — that is the only move that
   counts as progress against what nobody has thought to look for yet.
2. **A finding in a GATED class is a gate defect.** It leaves the audit's
   perimeter and becomes ordinary maintenance. This is what stops corrections
   from generating audit work forever.
3. **A run does not hunt findings.** It closes OPEN classes by enumeration, and
   mints the classes that are missing. The report to the operator opens with the
   OPEN counter, not with a list.

## The termination criterion

> **The audit is finished when the register holds no OPEN class, and two
> consecutive runs, each using a different search key, mint zero new classes.**

The second half is the real guarantee. "No OPEN class" only says the known
register is worked down; the zero-mint runs test whether the register itself is
complete. Without it you measure only what you already thought to look at.

The honest weakness is the mint rate — it is the one unbounded term. Its defence
is that minting has been driven by new search keys rather than by new territory,
and that the two-run rule makes an incomplete register visible instead of
invisible.

**The evening run of 2026-08-29 put a number on that weakness, and it is not
reassuring.** Its key was *time* — anything with a period, a window, a deadline
or a clock. It minted **five** classes and reopened two, from a register that had
just been worked down to two OPEN classes. The reason is visible in hindsight:
all 38 classes then on file asked whether something was *configured* correctly.
Not one asked whether it was *timed* correctly. A single new dimension therefore
paid five classes.

The lesson for whoever writes the next key: pick a dimension, not a topic. The
keys that have paid were dimensions the register had no vocabulary for.

**The evening run of 2026-08-30 used `order` and minted eleven** — more than
`time` did — which confirms the mechanism rather than the pessimism: eleven
classes existed all along and nothing had a word for them. The clock on the
termination criterion therefore resets. **Both dimensions this sentence once
named as unused — `identity` and `scale` — have since been spent, on 2026-08-30
and 2026-08-31. There is no named unused dimension left; the next key must be
invented.**

One caution for whoever writes the `scale` key. `order` and `time` both had a
property this file should not take for granted: every instance was observable
on the machine tonight. `scale` mostly is not, and the mandate's rule 1 —
"an evidenced clean beats a speculative list" — will bite harder there. Prefer
the parts of scale that leave a trace already (retention windows, growth rates
in netdata, a store whose oldest record is younger than its own period) over the
parts that need a thought experiment.

---

# The register

Runs of 2026-08-15 through 2026-09-05.
**83 classes: 1 OPEN, 13 GATED, 64 ENUMERATED, 5 closed by decision, plus the
DECLINED list.** (GATED = C07, C10, C11, C14-C19, C21, C41 and C81; closed by
decision = C04, C08, C57, C66 and C77's non-secret half; everything else
ENUMERATED.)

**The run of 2026-09-05 closed C82 (308/308) and minted C83. The counter is
therefore 1 -> 0 -> 1, and the termination clock RESETS.** That is the honest
outcome and it was not the convenient one: declining the mint would have shown
`0 OPEN` and satisfied the first half of the criterion. Five agents converged on
C83's property from five unrelated directions, which this register's own rule
names as the strongest evidence available. Minting it costs the run its clean
sheet; not minting it would have been measuring to the target.

**The OPEN column reached zero on 2026-09-03, for the first time in the
register's life.** The three classes minted that evening were all closed the
same night: C79 by finishing its sweep (13/13), C80 by sweeping its space
(26/26), and C77's secret slice by enumeration with its non-secret slice closed
by the operator's arbitration. That satisfies the FIRST half of the termination
criterion and only the first. The second half — two consecutive runs, each with
a different search key, minting zero new classes — has never been tested, and
`representation` minted four. **The next run's job is therefore not to find
anything. It is to invent a key and come back empty.** If it does, and the one
after it does too, this is finished.

**Both classes that were OPEN going into 2026-09-03 closed by enumeration, and
the counter still went 2 -> 3.** That is the register working, not failing:
C03 — the class this skill's founding defect belongs to, open for nineteen days
across seven runs — closed 107/107, and C75 closed 18/18 with zero live
instances. The three now open are all new, all minted the same evening, and each
arrived with the part of its space that was swept already counted.

**Two corrections to the header this one replaces.** Its GATED list omitted C18
while the GATED table carried it — the count of 13 was right and the enumeration
was short by one, so the true figure was 14. And C12 and C20 were both listed
GATED without being derived; they are downgraded below, which is what takes 14
to 12.

**The counter moved 5 -> 2, and for the first time the reason is arbitration
rather than sweeping.** C46 and C73 closed by enumeration. C57 and C66 were put
to the operator on 2026-09-02 and closed by decision: both had reached the point
where the only remaining move was one the operator declines to make, and
recording that is more honest than leaving them open to be re-sampled forever.

**The counter moved the right way for the first time in four runs: 9 OPEN to 5.**
It started at 9, not the 8 the previous header claimed — see the C03 correction
below. Five closed by enumeration (C05, C56, C58, C60, C62), seven minted after
arbitration, six of which arrived already ENUMERATED because the agent that
minted them also swept them.

**But the termination clock does not merely reset — it has run out of road.**
`scale` was the last dimension this file had named and never applied. It minted
seven, against five for `time`, eleven for `order` and twelve for `identity`.
The mint rate is decaying, which is the encouraging half. The discouraging half
is that **there is no named unused dimension left**, so the next run's key has to
be invented rather than taken off this list. Until one is, a run cannot honestly
claim the second half of the termination criterion.

## What the run of 2026-08-31 cost and paid

Its key was **scale** — what breaks at ten times the data. The register warned
that this key would be harder than its predecessors because `time`, `order` and
`identity` were all observable on the machine that night and most of scale is
not. The warning was right and the mitigation worked: agents were confined to
the forms of scale that already leave a trace, and the result is that **most of
what came back is a closed question with a number on it** rather than a lead.
`/mnt/data` reaches 85 % in 8.8 years; the offsite in 6.3 with 525 days of
warning; SD wear is 11.5 card-writes a year; the forced fsck costs 3 min 27 s
and does not grow with the data because a fixed inode table dominates it. None
of those needed action, and saying so with numbers is the point.

**The run's headline is that the gate written the previous night to close C45 —
the founding defect of this skill — is already failing, and its own comment
predicted it in writing.** Three agents and the main session converged on it from
four directions.

## OPEN — 1

C82 closed on 2026-09-05, 308/308. The column did not reach zero, because the
same run minted C83 — see below for why that merge was the honest call.

| ID | Property | Space, and its cardinal | Why it is still open |
|-----|--------------------------------------------|--------------------------------------------|----------------------------------------|
| C83 | A mechanism that reports success, health or completion after producing or examining a set, WITHOUT bounding that set's cardinality from below — so "produced/examined nothing" and "produced/examined everything" are the same observable | Two faces, one property. **Producer face**: every artefact a periodic job produces and something certifies (dumps, snapshots, generated specs, rendered configs) — `backup` enumerated its slice at 9, of which 6 are unbound and 4 material. **Consumer face**: every mechanism that iterates a derived set and reports on the run rather than on the count (posture derivations, heal loops, report scripts, `when:`-gated task groups). Partially swept by five domains under this run's key with five different questions; **no unified sweep, so the cardinal is not stated** | Minted 2026-09-05 after arbitration of 3 proposals. Distinct from C22 (a healthcheck that cannot report the failure it NAMES — here the check reports exactly what it names, and what it names is insufficient), from C03 (an instrument answering a different question from its comment — here the comment is accurate), and from C29 (the CONSTRUCT exists — here the construct is correct and the runtime cardinal is unbounded). **The register's own evidence that this is real: the remedy is already written into the repo in at least six places**, each on the day a single instance was fixed, and never generalised — C10's `credential-stores-derivation-nonempty` floor at >=12, the SQLite dumps' `-content` floor with its reasoning stated verbatim, `homelab-posture.sh`'s absent-vs-unresolvable distinction for Vaultwarden, ADR-030's "no silent caps" else-branch in `observability/tasks/main.yml`, C41's starvation guard at `[ "$n" -ge 10 ]`, and the WireGuard peers assertion's `[ -n "$live" ]`. Six statements of one rule, six times not applied next door |

## The run of 2026-09-05 — the key was `vacuity`, and it was invented

**For every mechanism that consumes or produces a set, a list, a string, a file
or a command's output: what does it do when that thing has ZERO elements, and is
that outcome DISTINGUISHABLE from the healthy one?** `time` asked *when*, `order`
*in what sequence*, `identity` *who*, `scale` *how much*, `authority` *on whose
authority*, `representation` *in what encoding*. `scale` asked what breaks at ten
times the data; **nothing in 82 classes had ever asked what happens at zero.**

Six already-paid facts were the tell, and none had a class: the offsite
`stdout: []` that emitted no assertion, `'REMOTE_MATCH' not in ''` opening its
own guard, the `pass = ` an empty rclone stdout would have written, the
`restic restore` that restores an empty directory and exits 0, the unprivileged
`grep` whose empty result was read as an absence, and the empty image list that
reads as a destroyed store.

**Sweep totals, eight domains: 1 216 sites.** system 126/126, security 272/272,
network 24/24, services 116/116, backup 75/75, observability 251/251 (goss
`exec:` blocks, 264 resources parsed off both live hosts), ansible-deploy 125/125
plus C82's 308, project-manager 80/80.

### C82 — CLOSED, 308/308, and the shape that produced it is still there

308 write-sites (`site.yml` 230 + `offsite.yml` 78, `import_tasks` expanded),
plus 77/77 binary-use sites and 34/34 handlers across 3 flush points.
**12 (writer, earlier-consumer) pairs, 2 instances, 10 refuted with reasons.**

The two instances are the known one, and the finding is that **the ordering is
unchanged**: `firewall.yml` still `blockinfile`s into `/etc/ufw/after.rules` at
lines 186 and 199, while `Set UFW default deny incoming` reads that file at line
49. What shipped heals the BYTE (the task-1 `replace`, `0cb8ef7`) and gates the
CAUSE (C81 in pre-commit). Neither touches the shape. The structural fix is one
edit: move the two `blockinfile` tasks above the default-policy task. Verified on
the hosts: 0 non-ASCII bytes across all six ufw files, markers rewritten 23:20 /
23:22 on 09-04.

**C81's gate is bounded, not broken**: its marker half is derived, its
`ASCII_STRICT_PREFIXES` half is a hand-kept list of one. Recorded so the next run
does not mistake the second half for a derivation.

**A THIRD instance appeared the same morning, and the change that closed C82
introduced it.** The corrections of this run added an assertion to
`homelab-health.sh` that reads the output of `homelab-stack-heal.sh`.
`observability` is a phase-1 role and `stack-startup` is phase-5, so the deploy
installed the check at 10:31:39 and its producer at 10:41:08; the health run at
10:41:08 pushed a DOWN for a mechanism that was working, the first `checked`
line arrived at 10:42:14, and the monitor cleared itself at 10:45:58.

Two things follow, and the second is the more important.

- The instance is fixed by starting the window at the later of "15 minutes ago"
  and "when the producer was installed" — an assertion must not demand a window
  longer than the producer has existed. Reordering the roles would fight the
  phase structure for one check.
- **C82 is ENUMERATED and that is not enough.** The sweep was correct when it
  ran; nothing stopped the very next commit from adding a pair. A class whose
  space can be re-populated by any deploy needs a gate, and C82 has none — no
  assertion derives the (writer, earlier-consumer) set. This is the C45 problem
  wearing a different coat, and it is why the class must not be read as settled
  merely because 308/308 came back clean.

### Minted — 1, after arbitration of 3 proposals

`backup` proposed "a verification that certifies an artefact's form and never
bounds its content from below" (9 artefacts, 6 unbound, 4 material). `services`
proposed "a repair loop whose success report is identical whether the set was
empty because nothing broke or because the query was blind" (0 live occurrences,
offered not asserted). `project-manager` proposed "a documented verification
whose empty output is the same observable as its success" (80/80) and said
plainly it might be the documentary face of the key rather than a class.

They are one property, and three more domains hit it without proposing anything:
`security`'s C16 derivation that increments `checked` 23 times over 0 surviving
pairs, `network`'s gravity gate that asserts a timestamp and never a domain
count, `observability`'s `self-test ok (0 checks)`, `system`'s timer loop with no
cardinal, `ansible-deploy`'s `_up` gates skipping 58 tasks with no else-branch.
Merged as **C83**; the merge is the run's real output and the convergence is
stronger evidence than any single route.

**Why it was minted rather than folded into the key.** `vacuity` is a dimension,
not a class — the same way `time` was a dimension that produced C67, C68 and C69.
C83 is one bounded defect shape inside it, with an enumerable space and an
obvious gate (a floor assertion), and it is distinct from C22, C03 and C29 for
the reasons in the OPEN table. The cost of minting it is that this run fails the
zero-mint half of the termination criterion. That cost was accepted rather than
shaved.

### Instances, grouped under C83, ranked by what is true right now

1. **Three of six dumps are certified complete and never certified non-empty.**
   `goss-backup-dumps.yaml.j2` asserts the completion marker for
   `backup_sql_dumps` and the zcat-carried marker for Immich. Both tools write
   that marker on a database with no rows. Measured against tonight's dumps:
   `miniflux.sql` 38 922 556 B against **670 B** header-only, `nextcloud.sql`
   26 916 653 B against **1 353 B**; Immich's figure is INFERRED, not measured,
   because measuring it would mean creating a database and rule 5 forbids it.
   Since 2026-08-31 those three datadirs are excluded from the source set, so the
   dump is the only copy, and Immich's `keepLastAmount=7` rotates out the last
   good dump after seven empty-but-valid nights. **The same file's SQLite half
   already carries the floor** — `select count(*) from sqlite_master >= 1` — with
   its reasoning stated verbatim: "a ZERO-BYTE file passes quick_check […]
   Restoring an empty Vaultwarden is not a lesser disaster than restoring a
   corrupt one." It was not carried across. The SQL half's comment explains why
   it dropped a BYTE FLOOR (10240 B was 0.037 % of miniflux.sql, #127) and that
   reasoning is correct — but a row-count floor is not a byte floor.
2. **The crash-heal timer cannot distinguish a clean stack from a blind query.**
   Every `logger` call in `homelab-stack-heal.sh` sits inside the `while read`
   loop over `docker ps --filter status=exited`. Verified on the host tonight:
   `Result=success`, `ExecMainStatus=0`, `journalctl -t homelab-heal -b` ->
   `-- No entries --`. **The script's own comment records that this exact string
   was the observable throughout the 2026-08-26 outage**, when 15 containers sat
   stopped and the timer fired every two minutes into an empty `exit 0`. #241
   fixed one cause; two remain (`status=exited` cannot see `created` or `dead`,
   and a never-created service is invisible). 23 of 29 containers are
   `restart: "no"` and have no other recovery path. One line: log the count
   outside the loop.
3. **The LUKS header restore is licensed by a word a typo produces.**
   `luks-header-backup.md:100-106` tells the operator to read `cryptsetup status
   data_crypt` and treat "inactive" as the good case, one line above what its own
   comment calls "how you lose the disk". Measured with a positive control:
   `cryptsetup status data_cryptX` prints `/dev/mapper/data_cryptX is inactive.`
   — the literal go-ahead. Exit is 4, but the page directs a human to read the
   text, not `$?`. Disaster-recovery path, one-sentence fix.
4. **The Tier 0 rebuild list yields zero from anywhere but `/opt/homelab`.**
   `boot-and-unlock.md:86-89` deliberately replaced a hardcoded list of six with
   a derived command — good instinct, and the page says why. But `docker compose
   config --format json | jq …` returns **6 lines from `/opt/homelab` and 0 lines
   with exit 0 from `$HOME`**, because the pipeline's status is `jq`'s. Measured
   both ways tonight. The section "If the orchestrator aborts" sends the operator
   to that list to rebuild missing Tier 0 containers by hand, during a boot
   failure.
5. **Four `_up` liveness facts gate 58 tasks with no else-branch.**
   `nextcloud_up` / `collabora_up` / `transmission_up` / `pihole_up` in
   `roles/deploy/tasks/`. A container that is not Running silently skips the
   files_lock timeout, the external-storage read-only flags, all of LibreSign and
   **two password enforcements** — the last being a C20 instance by a route its
   four probes cannot see. All four containers are up tonight. The antidote is in
   this same repo at `observability/tasks/main.yml:43`, with the comment "The run
   was correct; its silence was not."
6. **Pi-hole gravity is gated on its timestamp and never on its content.**
   `pihole-gravity-not-stale` reads `info.updated`; a `grep -rn` for any
   domain-count assertion returns nothing. `gravity.sh` calls
   `update_gravity_timestamp` unconditionally after the download step, which
   returns 0 even when every list ends at `status=4` — so a rebuild yielding zero
   blocked domains refreshes the very timestamp the gate reads. Healthy tonight
   (79 747 domains). Latent; privacy and comfort, not availability.
7. **`homelab-notify-push.sh:82` counts checkmarks with no floor**, so a
   self-test producing neither glyph pushes UP as `self-test ok (0 checks)`, and
   the same event silences the failure detector. Latent (6 checks parse today).
   Recorded under C22 as well as C83.
8. **`homelab-health.sh:558`** iterates `homelab-*` timers with no cardinal in
   the message; 13 tonight, and at zero it reports what 13 clean timers report.
   12 of 13 carry an independent derived dead-man, so impact is small.

### Broken gates — red tests, not audit results

- **C16 is broken and sharper than recorded.** Its predicate
  `owner == OPERATOR_UID` is a proxy, and `security` simulated the derivation
  live: 23 containers reach the mount loop and **0 (container, mount) pairs
  survive**, while `checked` increments 23 times and the report says "posture OK
  — N checks". Confirmed at the code by the main session:
  `checked=$((checked + 1))` sits outside the inner loop. C16's own recorded
  instance is GONE — `nextcloud-notify-push` now mounts `/var/www/html`
  `rw=false` — and the sweep under the real property is 26/26 with 0 instances.
  **The class is clean; the gate is not.**
- **C17 still broken**, both hosts, unchanged: every `Last checked` /
  `Next check after` in the repo is a comment, zero assertions. Root reads
  `Last checked Sun Aug 30 17:28:54 2026`, which is to the second the start of
  boot -2. Not re-proposed.
- **C11 is derived in form but has no floor**: 9 of 29 services declare `user:`
  and the assertion is emitted per declaration, so dropping a declaration removes
  its own check. `socket-proxy` (root) and `collabora` (1001) already sit
  unasserted. This is C83 applied to a gate.
- **C19 holds, but the register's row overstates it.** Positive control on the
  homelab: `[ -z "$(systemctl --failed … 2>/dev/null)" ]` exits 0 in the healthy
  case, in the `--machine=doesnotexist` case, AND with the binary absent. It is
  rescued by six neighbouring assertions that also go through systemd —
  composition, not assertion.

### Verified fixed, and not re-reported

- **C02's remedy is deployed and confirmed by three independent agents.**
  `offsite-health.yaml:77` now carries `[ -z "$(systemctl --failed …)" ]`, and
  `stdout: []` appears **zero times in the 227-251 deployed assertions across
  both hosts**. The vacuous form is gone from the estate.
- **13 of 14 corrections from 2026-09-03/04 verified GONE against the running
  system**, not against git: C78's restore table re-derived on today's snapshot
  (six `--include` paths, six matches), `DOCKER-USER` carrying exactly the eight
  rules the README claims, `logtimezone = UTC` under `[vaultwarden]` and nowhere
  else, the C81 gate clean over 112/112 `ansible/*.yml` with pre-commit
  installed. The exception is harmless and self-converging:
  `/boot/firmware/config.txt` on the homelab still carries em-dash markers
  because the `base` role has not run since; the repo fix exists.
- **C35 re-verified on CONTENT**: 15/15 push monitors carry a live measured
  message, 0 empty, 0 constant. The empty case is provably reachable in that
  database — 55 empty UP heartbeats across 5 monitors between 2026-06-06 and
  2026-07-19, none since.
- **C45's coverage hole is fixed** (both stragglers emit the marker) and it is
  **still not derived**. Unchanged verdict.
- **C15 holds and already fails closed on an empty `pgrep`** — the one gate in
  the estate written against this run's key before it had a name.
- **C10 holds and is the only gate carrying an explicit anti-vacuity floor.**

### Rejected from the agents, and why

- **`services`' "empty datadir, healthy service"** died on measurement: all 61
  bind sources sit under the single `/mnt/data` mount, so an independently empty
  datadir is not reachable. 2 empty by design, 0 unexpected.
- **`observability`'s three leads** did not survive: the absent dumps directory,
  monitor 22's lost `deep check` phrase, and Forgejo's healthz body.
- **`security`'s near-headline was killed by its own control.** `fail2ban-regex`
  in FILE mode reported zero date-template hits over 4 892 Nextcloud lines, which
  looked like a dead jail; a real line from that same file, re-tested singly,
  returns one hit. **New instrument trap: file-mode date-hit counting in
  `fail2ban-regex` is unusable.**
- **Immich's header-only dump size is inferred, not measured**, and the agent
  said so unprompted rather than quoting a number it had not taken.
- **`services`' and `project-manager`'s mint proposals** were merged into C83
  rather than counted separately.

### Register corrections

- **C53's row says "1 flush point"; there are two explicit plus the implicit
  end-of-play in each play.** Found while sweeping C82.
- **C21's row is stale a THIRD time, on a different word.** The `copy:` has no
  bound (correct, re-verified), but the row names a *"retention monitor"* that
  does not exist; the gate is the unbounded `copy` plus the `Offsite backup`
  push monitor.
- **C18's derivation claim is TRUE** — 19 checks generated by two Jinja loops
  over the group_vars lists, TAP plan line = 19 — but its property says "absent,
  stale, or **empty**" and the gate does not assert empty. The row overstates
  itself by one word, and that word is this run's key.
- **The `sshd` jail's `journalmatch` is half-dead on both hosts**:
  `_SYSTEMD_UNIT=sshd.service` is `not-found` under Ubuntu 24.04, so the jail
  survives only on `_COMM=sshd`, which OpenSSH 9.8 renames to `sshd-session`.
  Latent; it would report 0 bans forever while looking healthy. Recorded here
  rather than as a C83 instance because the mechanism is upstream naming, not a
  missing floor.

## The run of 2026-09-03 — the key was `representation`, and it was invented

The register had recorded that no named dimension was left. This key was
invented to fill that gap: **for every value that crosses a boundary between two
components, in what encoding does the producer write it, in what encoding does
the consumer read it, and what detects the mismatch?** `time` asked *when*,
`order` *in what sequence*, `identity` *who*, `scale` *how much*, `authority`
*on whose authority*; none had ever asked *in what*.

Three already-paid facts were the tell that the register had no word for it: the
Nextcloud/Redis outage of 2026-09-01 (a password with special characters
concatenated into a session URL), the `docker logs --since` timezone trap, and
C03's own live instance — `?immutable=1` against `?mode=ro`, which is a
representation defect wearing a validation class's clothes.

**It minted 4** — against 3 for `authority`, 7 for `scale`, 5 for `time`, 11 for
`order` and 12 for `identity`. Six mint proposals came back and four agents each
numbered theirs C77; the arbitration is below, because an unmerged mint list
inflates the counter and hides the convergence, which is the run's best evidence.

### Closed by enumeration — 2, and both were the ones that mattered

| ID | Property | Outcome |
|-----|----------------------------------------------|--------------------------------------------|
| C03 | A validation whose instrument answers a different question from the one its comment claims | **ENUMERATED 107/107, 99 true / 8 false — and the cardinal in this file was wrong for the fourth time.** 107, not 104: 21 shell artefacts + 86 `exec:` blocks. The 21st, `ansible/roles/storage/files/homelab-luks-header-backup`, carries a shebang and no extension, so every `*.sh` sweep in this register's history has missed it. The shell half was swept at **198 guard sites** rather than 21 files, 193 of them true. This class was open for nineteen days across seven runs; it is the one the founding defect of this skill belongs to |
| C75 | An authority held by a principal that the mechanism meant to govern it does not know exists | **ENUMERATED N=18, 18/18, 37 principals read, 0 live instances.** 18 of 29 containers hold their own account table. The "Ansible believes it governs, with no effect" axis is empty: Miniflux's repair is proven by its own log (`Skipping admin user creation`, last login 09-03) and the only other candidate matches its deployed value. Five populations with no claimed governance are recorded so they are not re-sampled: 6 Nextcloud app passwords (2 dormant, not revoked by a password change), 4 image-created MariaDB accounts, calibre-web's inert `Guest`, the 4 wg-easy peers, and `immich-redis` on `nopass` (already C56) |

### Minted — 4, after arbitration of 6 proposals

**Three agents proposed the same class and did not know it.** `security` wrote
"a secret written into its consumer's grammar with no escaping, alphabet
unconstrained"; `ansible-deploy` wrote "a value rendered into a consumer whose
grammar gives meaning to some of its characters, with no escaping and no shape
assertion"; `services` wrote "a value composed in a syntax where a character of
its own alphabet is a delimiter". Three routes, one property. They are merged as
C77, and the convergence is stronger evidence than any of the three alone.

**Two more merged for the same reason.** `network` found the same set of 18
service names enumerated by hand in four machine-readable grammars with nothing
comparing the copies; `backup` found a set defined by *subtraction* at the
producer and by *enumeration* at the consumer, with nothing comparing the two.
Both are one property: a set with two or more independent definitions and no
reconciliation. They are merged as C78, and that merge is what explains the
run's most expensive finding and C14's blind spot with a single sentence.

| ID | Property | Space swept | State |
|-----|--------------------------------------------------|-----------------|------------|
| C77 | A value rendered into a consumer whose grammar gives meaning to characters of the value's own alphabet, with no escaping and no constraint on the alphabet | secret slice 37/37, 3 defects | ENUMERATED on the secret slice; non-secret slice **closed by decision** |
| C78 | A set of which two or more components each hold their own definition, in different grammars, with nothing comparing the definitions | 4/4 name grammars (18/18/18, Kuma 15/18) + 21/21 restore expressions against 13 exclude patterns | ENUMERATED |
| C79 | A statement recording a deliberate non-action, which survives the reversal of that decision | **13/13** | ENUMERATED |
| C80 | A timestamp crossing a boundary without its timezone | **26/26** | ENUMERATED |

### C81, minted and GATED the next evening by the deploy itself

| ID | Property | Gate |
|-----|------------------------------------------------------|--------------------------------------------------------|
| C81 | A byte written into a file whose consumer reads it back through a NARROWER encoding than the producer's | `ops/check-ascii-system-files.py`, in pre-commit. **Made to fail on purpose on the three live markers before they were changed**, and made to fail again on a deliberately re-introduced em dash after they were fixed — both directions, which is what the C58 lesson asks for |

Distinct from C77, and the difference is the useful part. C77 is about a
character the consumer's GRAMMAR gives meaning to — a `$` in a shell source, a
delimiter in a DSN. C81 is about a byte the consumer's CODEC cannot represent at
all, whatever it means. `ufw` rewrites `/etc/ufw/after.rules` line by line
through `os.write(fd, bytes(out, 'ascii'))`, so one em dash in a blockinfile
marker made the whole security role unrunnable — at the fourth task, before it
could reach a single rule.

The gate's two learned boundaries are what make it derived rather than a
denylist, and both were measured rather than assumed:

- **`state: absent` names a marker to FIND, not one to write.** A check that
  forbade that would forbid its own remedy.
- **A ufw RULE COMMENT is hex-encoded** into `user.rules`
  (`comment=426974...c2b5...`), so any byte survives there by construction. The
  live `µTP/DHT` comment is safe and must not be "fixed". Verified on the host:
  no rule file contains a raw non-ASCII byte.

### How the three closed, the same night they were minted

The operator's instruction was to do whatever avoided another pass. Two closed
by sweeping, because their spaces turned out to be cheap once stated; one closed
by arbitration, because its remaining half is the kind of unbounded hunt this
register has twice recorded as not worth a run.

- **C79 — 13/13, one false, and it is the one that was fixed.** The space is
  every statement in `docs/` and `knowledge/` recording a deliberate
  non-action; a single grep on the phrasings bounds it. Twelve still hold, each
  checked against the machine rather than against the repository: 80/443 still
  not forwarded (probed from outside with a known-open control), `NET_RAW` still
  absent from netdata's caps, still exactly one socket-proxy, still no wildcard
  in `acme.json`, and Pi-hole's log genuinely unpersisted — 14.7 MB inside the
  container's writable layer, no bind mount, no tmpfs, exactly as its page says.
  The thirteenth was the security README's claim that `DOCKER-USER` is empty.
- **C80 — 26/26, one instance, fixed.** The space is every site where one
  component writes a timestamp another parses: 26 across both hosts' scripts and
  specs. **Fourteen are `date +%s`** — epoch, so the question cannot arise — and
  of the twelve real parse sites, eleven carry an explicit offset or an epoch:
  `docker logs --since "$started"` is fed the `Z`-suffixed `StartedAt`, and both
  `journalctl --since` calls use the `@epoch` form. The twelfth was fail2ban
  reading Vaultwarden's naked UTC log as local time. **The sweep is the useful
  half of this class**, not the instance: it shows the codebase had already
  converged on the two safe forms everywhere it wrote them deliberately.
- **C77 — the secret slice is enumerated, the rest is closed by decision.**
  37/37 interpolation sites, 3 defects, 1 live and fixed. The non-secret slice is
  a finite set of template sites but sweeping it means reading every Jinja
  interpolation in the tree against its consumer's grammar, for a class whose
  only demonstrated cost has been in secrets. That is C66's tail wearing new
  clothes, and it is closed the way that one was. **The fact that makes this
  defensible is also the one that makes it uncomfortable**: `| quote` and
  `| urlencode` appear zero times in the entire tree, so nothing prevents the
  next instance — only the password generator's undocumented alphabet does.

### C78 is the run's headline, and it lands on the disaster-recovery path

`knowledge/runbooks/restore-from-backup.md:70-73` gives the generic recipe
`restic restore latest --target / --include /mnt/data/services/<service>`. Since
2026-08-31 the live datadirs are excluded from the source set. Verified on
tonight's snapshot `9e99f3fa` with `restic ls` on the local repository:

    /mnt/data/services/miniflux                 <- the directory, and nothing else
    /mnt/data/services/nextcloud
    /mnt/data/services/nextcloud/data           <- no db
    /mnt/data/backups/dumps/{forgejo,miniflux,nextcloud,uptime-kuma,vaultwarden}

**Nothing is lost — the dumps are in the snapshot and the backup is complete.**
What is wrong is the procedure: for Miniflux, whose service directory holds only
`db`, that command restores an empty directory **and exits 0**. For Nextcloud and
Immich it restores the files without the database, silently producing an
inconsistent pair.

The sharp part is that `resticprofile.yaml` states the safety rule that should
have caught it, in its own comment: *"exclude nothing that a documented restore
procedure reads […] `restore-from-backup.md` already restores all of them from
the dump — each of its procedures resets the datadir."* The rule was checked
against the per-service procedures and not against the generic one in the same
file. `78372e1` touched exactly one file.

### Broken gates found on 2026-09-03 — red tests, not audit results

- **C02** (a failed unit on the offsite host). `/etc/goss/offsite-health.yaml:68-71`
  is `exec: systemctl --failed --no-legend --plain` with `exit-status: 0` and
  `stdout: []`. `systemctl` returns 0 whether the list is empty or not — control
  taken on the host, `list-units --state=active` prints **433 lines with exit=0**
  — and `stdout: []` emits no assertion at all. The check is vacuous. The homelab
  has the correct form at `units.yaml:88`, `[ -z "$(systemctl --failed …)" ]`,
  which turns the output into an exit code. **The right pattern exists, on one of
  the two hosts.** The offsite Pi, with no physical access and probed weekly, has
  no net under failed units.
- **C16** (a read-write bind mount its container cannot create files in).
  `nextcloud-notify-push` mounts `/var/www/html` rw, runs as uid 0 with
  `cap_drop: ALL` and only `CAP_DAC_READ_SEARCH`. Measured with a positive
  control at the same uid: `HTML_NOT_WRITABLE` against `TMP_WRITABLE`. The
  deployed assertion cannot see it — its predicate is `owner == OPERATOR_UID`, a
  proxy for the property rather than the property. Full sweep under the property:
  27/27 rw mounts, this one case.
- **C17** (a filesystem never checked). Still broken, and **the model written
  into the gate is wrong**: the initramfs clock is not frozen at one date, it is
  late by a variable amount, and `e2fsck` in preen mode branches at 24 h. Both
  branches observed the same evening, one per host: homelab, skew 21 h 28 min,
  "in the future … by less than a day", no rewrite; offsite, skew ~37 days,
  **`FIXED.`**, superblock rewritten. The loop is intermittent with a measurable
  margin — the homelab escaped it by **2 h 32 min**. Its "good" `Last checked
  Aug 30 17:28:54` is, to the second, the start of boot -2 (`journalctl
  --list-boots`): a boot instant, not a check instant. `Last checked` /
  `Next check after`: **zero assertions in the entire repository.**
- **C26** (a credential reaching a command line). `ansible/roles/claude-code/tasks/vault.yml:69`
  puts `pass={{ rclone_webdav_pass }}` in the argv of an `ansible.builtin.command`,
  on a `/proc` with no `hidepid`, while the sibling task **eleven lines above**
  passes the same value through `environment:`. `no_log: true` hides it from
  Ansible's output, not from `/proc` — false reassurance. Its guard opens instead
  of closing: `failed_when: false` plus `default('')` means a failed probe makes
  `'REMOTE_MATCH' not in ''` true, so the task runs. **Two agents disagreed here
  and the disagreement was the finding**: `security` swept the property with `ps`
  on both hosts plus every `compose.yaml` healthcheck and correctly found zero
  live instances, because a process that only exists during a deploy cannot be
  seen at audit time.

### Downgraded from GATED — 2, for the reason that already cost C02, C13 and C26

| ID | Property | Why it is not a gate |
|-----|----------------------------------------------|--------------------------------------------|
| C12 | A rotated secret no consumer restarts to read | **No live assertion at all.** Nothing in the three deployed goss specs mentions handler coverage. The 51 notify sites and 0 orphans of #145 were a sweep, not a gate |
| C20 | A secret that a deploy reports as rotated without rotating it | 4 hand-written probes over a space of 16 secret files. A list of four is not a gate |

### Also verified, and worth not re-deriving

- **C21's row in the GATED table is stale, again.** The time-window filter it
  describes no longer exists: `copy:` carries no bound and every snapshot is
  re-offered nightly (31 local / 81 offsite, no gaps). The class holds; the
  description does not.
- **C15 holds, and its space was widened rather than re-swept.** Three surfaces
  (process, unit, alternative write path), 3/3: `--append-only` on both the live
  cmdline and `ExecStart`, and the surface that would have voided the argument —
  a private key on the main host, or an `authorized_keys` under the offsite root
  — **does not exist**.
- **C18 holds and is genuinely derived**, 19 checks re-derived from the two
  group_vars lists. It belongs in the GATED header count, which omitted it.
- **The two dated predictions left by the 2026-08-31 run are closed, pre-empted.**
  `4685e74` bounded both windows on 08-31 19:23 and is deployed on both hosts
  (26 h and 8 d caps, `timeout: 60000`). The 09-01 posture run passed without
  overrun.
- **C47's count is confirmed at 2/29 and its instrument corrected**: `SigCgt`
  alone gives 6; `s6-svscan` (x2) and `tini` (x2) handle SIGTERM through
  `SigBlk`/signalfd. **C40's "24 at the 10 s default, not 25" is a
  configuration count only** — it comes from `Config.StopTimeout` and not from
  observed kills. The agent disclosed this itself: its cross-check against the
  daemon log (`failed to exit within … — using the force`), which this register
  names as the correct instrument for C40, overran 120 s under the fleet's load
  and was killed without producing anything. It was deliberately not retried,
  rule 6 outranking a cross-check the conclusion did not depend on. **The
  "how many were actually force-killed" axis is still the 2026-08-30 sweep,
  8 instances, and has not been refreshed.**
- **C11 intact, 9/9. C41 holds and is genuinely derived** (the `type='push'` set,
  each monitor's own `interval` as the window, starvation guard at 10/15).
  **C35 swept 15/15 with zero constants. C45 must stay ENUMERATED**: the 10 sites
  emit the marker, but nothing derives the set of emitters.

### One disclosure, made unprompted by the agent that caused it

`services` reports that the cleartext value of Nextcloud's Redis `save_path`
transited its context — its own redaction filtered `auth[]=` and not `auth=`. The
value was not written anywhere and was not transmitted to anything. It is
recorded here for the same reason last run's rule-5 violation was: an audit that
handles secrets has to say when it mishandles one.

## The run of 2026-09-02 — the key was `authority`, and it was invented

The register had recorded that no named dimension was left and that the next key
would have to be invented. This one was: **for every fact the machine acts on,
how many places state it, which one binds when they diverge, and what detects the
divergence?** `time` asked *when*, `order` *in what sequence*, `identity` *who*,
`scale` *how much*; none had ever asked *on whose authority*. C13 ("an
environment value shadowed by a persisted config file") and C27 ("a deployed
artefact differing from the repo") were the tell: the register had words for two
narrow cases of the dimension and none for the general one.

**It minted 3 against `scale`'s 7, `time`'s 5, `order`'s 11 and `identity`'s 12.**
The decay is real and this is the first key to produce a single-digit yield.

### Closed by enumeration — 2

| ID | Property | Outcome |
|-----|----------------------------------------------|--------------------------------------------|
| C46 | A supervisor's log that declares an act it did not perform | **ENUMERATED 34/34, 0 confirmed instances — and the blocker was a stale cardinal in this file, not a real gap.** The "6 mute supervisors" did not exist: re-derivation found **4** candidates, of which **3 were merely mis-searched** — their claims are durably corroborated under the systemd units' own transition logs rather than under their own tag. Verified live: `journalctl -t homelab-unlock` is indeed empty (the register's observation, reproduced as a negative control), while `mnt-data.mount` carries the same events with real timestamps. The 4th closes by source argument (`set -euo pipefail` + immediate `$rc` capture makes divergence unreachable). **The four `logger -t` lines this file called for were never needed** |
| C73 | A documented duration extrapolated from an unrepresentative sample | **ENUMERATED N=20, 20/20** — 11 correctly derived, 2 extrapolated across 3 live sites, **6 of untraceable origin**, and that third bucket's size is itself the result. Two further instances of its own defect: `ADR-021-collabora-online.md:220` and `homelab-stack-startup.sh:157-158` still cite warm-boot figures (~80 s/~90 s) that `compose.yaml`'s own comments already say are 6-12x low (real: 7 min 49 s - 16 min 33 s). **Note the arbitration**: `project-manager` also reported C73 closed, on the grounds that its single instance had been fixed by `241d504`. That closes the instance, not the class. Same verdict, one valid reason |

### Closed by the operator's decision — 2

| ID | Property | Decision |
|-----|----------------------------------------------|--------------------------------------------|
| C57 | An authentication failure recorded without an identity | `security` moved it — space independently re-derived at **N≈21** (the prior 24 was an aggregate whose item list was never preserved), 4 more decided by upstream source reading, 3 known instances re-confirmed. The remainder needs a **deliberate-failure drill**, and the operator declined it on 2026-09-02. The class is therefore closed by decision rather than left open to be re-sampled |
| C66 | A correction applied to the instance that revealed it, whose siblings were never enumerated | Cut in two, on `project-manager`'s proposal and the operator's approval. The **historical half is ENUMERATED and closed for good** (128/128 + 188/188): `git log` structurally cannot see hand-fixes, so re-sweeping it forever asks an instrument to do what it cannot. The **unbounded tail is DECLINED**. What survives is not a class but a method — compare live populations against what is written, which bounds without history, and which is exactly this run's key. It produced three instances that evening by that route alone |

### Minted — 3

| ID | Property | Space swept | State |
|-----|--------------------------------------------------|-----------------|------------|
| C74 | A rule whose decision is pre-empted by another component acting earlier on the same object, with nothing detecting the pre-emption | 7 UFW inbound rules, 7/7 | ENUMERATED, **fix shipped** |
| C75 | An authority held by a principal the mechanism meant to govern it does not know exists | not swept — see the OPEN table | **OPEN** |
| C76 | A verification whose expiry is reported through the same channel, and in the same terms, as the condition it watches | 197 homelab + 43 offsite assertions | ENUMERATED, no action requested |

### C74 is the run's headline, and three agents reached it independently

`network` and `security` proposed it from different routes — chain order, and
Pi-hole's `FTLCONF_dns_listeningMode: all` — and the main session verified it on
the chains. **`FORWARD` places `DOCKER-USER` at 1 and `DOCKER-FORWARD` at 2; the
six `ufw-*-forward` chains only start at 3. `DOCKER-USER` is empty.** The `DOCKER`
chain then holds `ACCEPT udp 0.0.0.0/0 -> 172.19.0.2 dpt:53` with no source
filter, and that ACCEPT terminates the traversal.

Meanwhile ufw displayed `53 ALLOW IN 192.168.1.0/24 # DNS (Pi-hole, LAN only)` —
a rule on the INPUT path, which a packet bound for a container never takes.
**Six of the seven inbound rules were in that position; only one had its written
intent violated**, the other five saying "Anywhere" and being honest. No live
exposure: probed from the offsite uplink with a known-open control (51413 open,
80/443/53 closed). **The protection came entirely from the router, and nothing on
the host knew it.**

Note the shape: C74 is the **inverse** of C70 ("a rule inert today that would be
a fault if enforced"). Here, a rule believed to be enforced that is inert. That
is what made it a mint rather than an instance.

### The load confound, caught by the main session

`observability` reported two assertions timing out during the audit
(`container-health-sample-floor-reachable`,
`only-socket-proxy-mounts-the-docker-socket`, both on the 10 s default).
**Re-measured at near-idle, two passes: 27.68 s and 24.55 s for the whole spec,
zero `not ok`, zero timeouts.** They do not time out normally — they timed out
under eight concurrent agents, which is instrument trap #1 of `settled.md`
reproduced exactly. What survives is sharper than either version: these
assertions are **load-sensitive**, and the machine demonstrably has real
contention episodes. That is C76, and it is why the three "went red for being
slow" commits of that week were treating one class one instance at a time.

### One agent broke the read-only rule

`security` provoked a real authentication failure against the offsite
`rest-server` while investigating C57, and disclosed it unprompted. Impact nil —
nothing persisted, the append-only repository untouched. Recorded because it is
precisely the act the register classes as out of scope, and because the operator
declined that same drill hours later.

## Closed by the run of 2026-08-31 — 5

| ID | Property | Outcome |
|-----|----------------------------------------------|--------------------------------------------|
| C05 | Something a reader would reasonably assume the posture check asserts, and which it does not | **ENUMERATED, and the cardinal was wrong: N=104, not 53.** Swept 104/104 on both hosts under a stated criterion — one proposition per verifiable predicate rather than one per bullet, so the disagreement with the previous count is explicit rather than silent. **7 FALSE, and of the 97 true, 37 asserted / 60 unasserted.** Six of the seven false are drifted counts and **in three the deployed posture is STRONGER than the prose** — 16 zero-capability containers where the document claims 15, and so on. No exposure among them. The load-bearing unasserted statements are unchanged in nature: SSH key-only (the only access path, ~6 lines per host against `sudo sshd -T`) and 80/443 not forwarded (~12 lines, endpoint derived from the offsite's own `wg0.conf`, both positive controls inside the assertion). **Correction to this file: `unattended-upgrades` IS asserted on both hosts**, at the outcome level — both health scripts alarm if security updates stay pending past 48 h |
| C56 | An authorization or an attribution decided after the caller's identity has already been lost | **CLOSED on both halves, and both cardinals are derived from the running machine rather than from compose.** Network half **19/19, 6 instances** (4 UFW source rules, 1 scoped DNAT, 2 deciding middlewares, 0 of 21 routers with their own auth, 2 attribution fields, 1 Pi-hole client rule, 2 shared-secret logins, 4 WG peers, 3 jails). Container half **32/32, 5 instances** — the space being every non-loopback listening socket another container can reach, enumerated with `ss` inside each network namespace. 4 endpoints authorize with no caller identity at all; 1 shares a principal across three callers. The socket proxy's grant set was measured rather than argued: **103 069 requests over 22 h**, netdata 92.9 %, dozzle 3.9 %, traefik 0.6 %, and no caller uses more than 3 of the 5 grants |
| C58 | A control all of whose assertions test the direction that permits | **CLOSED 14/14, and it closed by REFUTING its own blocking premise**, which is worth more than the count. 3 permitting-only (the three already on file — there is no fourth), 5 refusing-only, 5 bidirectional, 1 presence-only. The register recorded the refusing direction as "unobservable from any address on this machine". **It is observable**: `curl --interface 172.20.0.1 --resolve ...` returns **403** against a **200** positive control, reproduced on three routers. Every other host address fails as a control because POSTROUTING launders 172.17/172.19 into the allowlisted 172.18.0.1, and `homelab_socketproxy` escapes only because it is `internal: true` — so an assertion must pin `%{local_ip}` and treat 000 as control failure rather than as a pass |
| C60 | A copy whose scope is a list of fields facing a third party's schema | **ENUMERATED 12/12, 1 instance, and the register's own numbers were wrong.** Live: **21 of 114 columns**, not 22 of 118. `dns_resolve_server` on the Pi-hole DNS monitor and the Transmission basic-auth triple are the omissions that carry intent. **The register also overstated the impact and that is corrected**: nothing restores from the JSON — the documented path is the whole-file `.sqlite3` — so the cost is not a silently wrong restore but **review blindness in the very instrument used to review monitoring**, which is live today |
| C62 | An announced exclusion that the mechanism does not enforce | **CLOSED 21/21** (25 candidates, 4 rejected as capability statements rather than exclusions), **2 instances, the same sentence at two sites**. **The register's description of the mechanism was wrong**: the guard is NOT read only by `homelab-unlock` and itself — `AssertPathExists=!/run/homelab/unlock-fsck-in-progress` is deployed on `mnt-data.mount`, so every systemd path is blocked. The real gap is `mount(8)`, which nothing consults. The worse of the two sites prints "nothing else can mount it either" immediately after `e2fsck` has declined to repair a damaged filesystem. **The fix on file — "one sentence" — was wrong twice over**: it is a reworded sentence *or* a real interlock, and the choice is the operator's |

## Minted by the run of 2026-08-31 — 7, after arbitration of 11 proposals

**Four agents proposed a class numbered C67 and they were not the same class;
three of those four were.** The arbitration below is part of the run's output,
because an unmerged mint list inflates the counter and hides the convergence.

| ID | Property | Space swept | State |
|-----|--------------------------------------------------|-----------------|------------|
| C67 | A verification whose deadline was sized against an input that was empty or small when it was measured, and which grows without bound | 13 constructs across both hosts' verification layer, 13/13 | ENUMERATED, **not gated** |
| C68 | A store whose declared retention is overridden by a limit that is not the one written down | 7 stores + 31 container log rings | ENUMERATED |
| C69 | A periodic control whose own runtime is a fraction of its period that nothing measures | 16 periodic controls, 16/16 | ENUMERATED |
| C70 | A rule that is inert today and would be a fault if it were enforced | 19 UFW rules, 19/19 | ENUMERATED |
| C71 | A recurring cost driven by rewrite rate rather than by information carried | 22 backup subtrees, 22/22 | ENUMERATED |
| C72 | A remedy that enlarges a window, and therefore takes effect only after a delay equal to the enlargement | 2 windows enlarged since 08-29 | ENUMERATED |
| C73 | A documented duration extrapolated from an unrepresentative sample | 1 instance, space unbounded | **OPEN** |

**C67 absorbed three independent proposals** — `ansible-deploy`'s "cost grows
against a fixed budget", `observability`'s "timeout sized while its store was
near-empty" and `backup`'s "deadline sized against an input that had just been
emptied". Three agents, three routes, one class. **C69 was kept separate on
purpose**: it is not about a deadline being crossed but about a runtime nothing
measures at all, and its instance (`homelab-health` going 6 s to 24 s at the
08-30 reboot and holding, load controlled for) would be invisible to C67.

**C68 absorbed two** — `services`' "two limits where the binding one is not the
one written down" and `observability`'s "declared retention silently overridden
by a size cap" — and `system`'s "retention window whose binding limit is an
unrelated routine event" is its third face: no container on the host is older
than 4.96 days, so **29 of 29 log rings have never reached their configured
size**, including the 200 MB ring sized at ~32 days five days earlier whose log
is 19 hours old.

### C67's instance is the run's headline, and the gate predicted its own failure

`no-kuma-report-was-lost-in-silence` — written on 2026-08-30 to close C45, the
defect that created this skill — scans the journal from Kuma's start, and Kuma's
uptime is what bounds the window. Measured by the main session at idle:

    6 h  -> 5.63 s      12 h -> 6.54 s
    25 h -> 20.04 s     48 h -> 52.90 s      against a 45 s budget

`backup` measured it under the load the spec itself creates: **34.5 / 35.9 /
40.6 s of 45 s at one day of Kuma uptime.** The spec's comment claims an 11x
margin; **it is 1.2x**. Its twin `offsite-no-report-was-lost-in-silence`
declares no `timeout:` at all and runs against goss's 10 s default, proven
empirically (`sleep 11` -> `timed out (10s)`).

**The comment on the assertion states the failure and the remedy in advance:**
*"The scan grows with the window, which is bounded by Kuma's uptime rather than
by anything here. If this ever times out again, that is the reason, and the fix
is to bound the window — not to raise the number."* Written 2026-08-30, true
2026-08-31.

When it trips, goss reports a timeout as `not ok`, indistinguishable from a
failed assertion — so **the gate built to catch "a report was lost" will
announce that reports were lost, for having got slow.** `backup` left two dated,
falsifiable predictions: the posture run of 2026-09-01 11:09 and the offsite run
of 2026-09-06 08:00.

**A compounding term nobody had connected, found in halves by two agents.**
C39's remedy raised the journal cap 500M -> 1500M on 2026-08-30 to lengthen
RETENTION. This gate's cost is linear in journal bytes scanned. The fix for one
class is the load term of another. That interaction is C72.

### The `-p err` remedy was REJECTED by the main session, and the rejection matters more than the finding

`backup` offered a 22x speedup: the same query with `-p err` falls from 34.5 s
to 1.56 s, reproduced by the main session at 20.59 s -> 1.57 s.

**It would make the gate blind.** The marker is emitted as `echo
"kuma-push-failed: ..." >&2` at 10 of its 11 sites; the units run
`StandardError=inherit` with `SyslogLevel=6`; and the positive control is
decisive — a line that is unmistakably script stderr, `curl: (28) Operation
timed out after 10001 milliseconds`, sits in the journal at **priority 6**. So
an empty `-p err` sweep over 45 days is not evidence that no push has failed; it
is evidence that the filter cannot see the marker.

Applying it would have made the assertion 22x faster and **permanently,
silently green** — a C03 instance installed inside the gate for the class that
created this skill, and one that would pass review because the check keeps
saying `ok`. **If a priority filter is ever wanted, the marker must be EMITTED
at that priority first, in the same change.**

### Two agents disagreed, and the disagreement was the finding

- `project-manager`: the restore-time claim is fine — the repository is 352 GiB
  against 343 documented, +2.6 %, so "around 7 hours" still holds.
- `backup`: "around 7 hours" was extrapolated from a 243 MiB / 18 s sample; the
  true range is 7.4-33 h.

Not a contradiction. They tested different axes: one asked whether the number had
DRIFTED, the other whether it had ever been DERIVED. The second is the deeper
question and its answer stands as C73. **The first is correct on the question it
asked and must not be reported as clearing the claim** — which is precisely how
a negative result becomes a false all-clear.

### Rejected by the main session — one agent claim, re-measured

`network` asked to overturn `settled.md`'s retraction *"VPN clients appear in the
clear as 10.8.0.x"*, concluding that fail2ban's jails cannot ban a VPN client.
Its evidence was a correlation: one device seen as `10.8.0.2` to Pi-hole and
`172.18.0.1` to Navidrome one second apart.

Measured directly on the live access log instead: the 22 993 laundered requests
are **Uptime Kuma's own probes** — `/healthcheck`, `/ping`, `/alive`,
`/healthz`, `/status.php` — exactly as `settled.md` recorded, and **14 requests
arrive with `10.8.0.x` preserved**, an address in no ignored range. The
correlation had no base-rate control: Kuma probes 34 monitors on ~60 s cycles,
so a one-second coincidence is the expected case. **Rejected.** What survives is
narrower: both paths exist and nothing establishes which one a given request
takes.

## Reopened and broken gates found on 2026-08-31 — red tests, not audit results

- **C38** (a container log growing without rotation). **REOPENED, and it is the
  most immediately actionable thing the run found.**
  `/opt/homelab/configs/pihole/logrotate` is owned `marc-gavanier:docker`, so
  logrotate refuses the entire file — *"file owner is wrong"*, nightly. The
  `copytruncate` fix of 2026-08-25 has therefore **never been in effect**, and it
  silently killed the two rules in that file that WERE working. `pihole.log` is
  23.8 MiB with no rotated copy, growing **14.4 MB/day**. One word — `owner: root`
  on a single Ansible task. This is also a C49 instance: a hardening applied to
  an artefact whose producer regenerates it.
- **C63** (a recovery destination that cannot hold what it restores). Two live
  instances, and they are the same shape found independently by two agents.
  `restore-from-backup.md` restores Immich's dump directory — **595 MiB
  measured, 7 files of 89 MiB** — into `/tmp`, which is `tmpfs size=1048576k`.
  It fits today with 429 MiB of headroom and fails at roughly 16 000 assets
  against today's 9 489. **State that horizon in assets, never in dates**: the
  dumps grew 13.5 KB in six days, so a calendar projection gives decades and is
  meaningless. Separately, `offsite-backup.md:189` restores ~343 GiB into the
  offsite root's 221 GiB free, on the path taken when the homelab is lost.
- **C06** (`start_period` never measured) and **C29** (a construct that disables
  a feature silently) were not re-swept tonight. C29's calibration was corrected
  in `settled.md` on 2026-08-31: the redactor's PID 1 is `sh`, not the pipeline,
  so if `tail` dies the container stays `Up` with a vacuous `pgrep` healthcheck.
  It is an exposure, not a tidy-up.

## The run of 2026-08-30 (night) — the key was `identity`

Four of the six OPEN classes closed, twelve minted. The key asked **who is
acting**, as opposed to what is running, and it paid the way `time` and `order`
did before it — which is now three consecutive confirmations that the mint rate
tracks unused dimensions rather than a rotting system.

### Closed by enumeration — 4

| ID | Property | Outcome |
|-----|----------------------------------------------|--------------------------------------------|
| C50 | A liveness probe whose subject answers without the component the probe claims to prove | **ENUMERATED 62/62, ~19 instances.** The cardinal was wrong: recorded as 64, it is **62** — 25 Docker healthchecks (taken from the machine, not the repo: three services inherit their `test:` from their image), **34** Kuma monitors (not 36) and 3 `wait_healthy`. Three agents swept disjoint thirds. The instances that matter are not the resolver ones this row was opened on: `pg_isready -d <db> -U <user>` returns the same output and exit 0 for a database and a role that **do not exist** (verified with a control against the real call), so the arguments are decorative on two databases; Kuma's own healthcheck greps `entryPage`, which is the FIELD NAME in `{"type":"entryPage","entryPage":null}` — and Kuma is the only container no external monitor watches; `miniflux -healthcheck auto` performs **zero** transactions over 30 probes. The suspicion worth more than its instances: if `/mnt/data` disappears while the containers run, calibre-web serves `/login`, jellyfin `Healthy`, navidrome `.`, immich `pong` — four dead services, four green probes, four routers kept |
| C51 | A procedure whose written order differs from the order the machine imposes | **ENUMERATED 80/80, 6 instances** (the 4 fixed on 08-30 plus 2). The 80th sequence was found by dropping the title index and taking the two candidates invisible to it: `sd-theft-response.md` is clean on 6 machine-verified claims, and `ops/bootstrap.sh` carries one instance — its connectivity check and its final command omit `-e homelab_ssh_port=22`, which `hosts.yml` states in writing, and `--ask-vault-pass`; proven, `ansible-inventory --host homelab` answers `Attempting to decrypt but no vault secrets found`. **The suspected instance is CONFIRMED without dropping anything**, and it is worse than an inversion: step 1 prints an unfilled `--cap-add`, whose only source is step 4, and step 4's instrument is **blind on 25 containers of 29** (24 without `getcap`, 2 without a shell). The blind set contains Collabora, and the rule "empty sweep ⇒ the flag is safe" therefore authorises the drop |
| C52 | A safety argument whose premise is a defect that has just been corrected | **ENUMERATED, bucket swept 9/9 of 151 candidate arguments, 1 confirmed instance.** `observability/handlers/main.yml` refuses `netdatacli reload-health` on the grounds — stamped **"Measured, not assumed"** — that `/run/netdata/` is empty. Measured tonight inside the container (the right namespace): `netdata.pipe` is present and `netdatacli ping` answers `pong`. The direct cost is one netdata restart per deploy instead of a reload; the value is that **a measurement stamped "measured" expired and nothing noticed**, which is the property itself. A second material: `homelab.env` is argued about as "group-readable and mounted into the containers" when it is 0600 and mounted nowhere — right decision, false reasons |
| C54 | A startup list that is neither derived from the machine nor asserted against it | **ENUMERATED 4/4.** Tier 0, wave 1, wave 2, wave 3; only the Tier 0 list is both derived (from `compose.yaml`) and asserted. Coverage 6+9+6+8 = 29 = the 29 services, no discrepancy. **The suspected instance is DISCARDED with proof**: a service no wave starts fails the goss assertions generated for it (`docker inspect <absent> | jq` -> `null`, positive control `traefik` -> `false`) — real detection, but at 24 h and under a misleading name. **1 confirmed latent instance**: the Tier 0 assertion covers one of the three `restart:` values, so an `always`/`on-failure` would pass it in both directions and short-circuit the staged startup. Measured 0 today (6 `unless-stopped`, 23 `no`, 29/29 compliant). ~10 lines turn the equality into a partition assertion and **C54 would reach GATED** |

### Minted — 12

| ID | Property | Swept | State |
|-----|--------------------------------------------------|-----------------|------------|
| C55 | A container uid that is a real login account on the host | 5/29, 4 inert, 1 assumed | ENUMERATED |
| C56 | An authorization or attribution decided after the caller's identity is lost | 3 surfaces | **OPEN** |
| C57 | An authentication failure recorded without an identity | 1 instance | **OPEN** |
| C58 | A control all of whose assertions test the permitting direction | 3 assertions | **OPEN** |
| C59 | A verification whose subject supplies its own instrument | 12/12, 1 instance | ENUMERATED |
| C60 | A copy whose scope is a field list facing a third party's schema | 1 instance | **OPEN** |
| C61 | A numeric identifier used where a name was meant | 17/17, **4 wrong** | ENUMERATED |
| C62 | An announced exclusion the mechanism does not enforce | 1 SUSPECTED | **OPEN** |
| C63 | A recovery destination that cannot hold what it restores | 13 destinations, 9 instances | ENUMERATED |
| C64 | Data whose owner is no process's identity | 27/29 clean, 2 instances | ENUMERATED |
| C65 | A mounted file whose identity no task declares | 3, cost measured zero | ENUMERATED, DECLINED candidate |
| C66 | A correction applied to the instance that revealed it, whose siblings were never enumerated | 3 instances on file | **OPEN** |

**C55's cardinal deserves its footnote, because the loose predicate is useless.**
Fourteen of the 29 containers run PID 1 as host uid 0 and one as 65534; counting
those as "a real host account" would give 15 and mean nothing. The property is a
collision with a *non-system* account, and on that reading it is 5. The sharp
instance is **Collabora**: `Config.User` 1001 with no userns remapping, so its
PID 1 runs as host uid 1001 = `claude`, the login account that carries
`claude-remote-control.service` and an rclone mount of the Nextcloud vault — and
host gid 1001 = `spi`, an unrelated group. Nothing allocated that uid; it is the
image's default. Mitigation measured: Collabora declares **no bind mount**, so
no shared write path exists today. The day someone adds one, they add it with
`claude`'s rights.

**C61 is the cheapest class on this table and the one most likely to bite.**
`gid 1000` is `gpio`, not the operator's group, which is 1003; `gid 999` is
`systemd-journal` on the homelab while `uid 999` is `rest-server` on the offsite.
`docker/.env.example` ships `PGID=1000` where the deployed value is 1003 — it
only bites on a rebuild from the example, and then it hands the containers the
`gpio` group. The offsite-restore step of `offsite-backup.md:189` ("on any
machine") would hand the Postgres datadirs to the network daemon's account.

### Broken gates — red tests, not audit results

- **C06** (`start_period` never measured). Confirmed broken on **four** points, one
  of them new: 14 declared against a header reading `THIRTEEN`; the redactor's
  30 s measured at **99 s**; it survives only by accident (30 + 3x60 = 210 s of
  tolerance); and the upstream cause — **`traefik` declares no `start_period` at
  all** and takes 98 s to load its configuration.
- **C29** (a construct that disables a feature silently). Still broken, uncorrected
  in repo and on the machine. Calibrated: the test is
  `pgrep -f ... && [ -f .../access.log ]`, so the FILE half works; only the
  liveness half can never fail. Do not present the probe as wholly vacuous.
- **C26** (a credential reaching argv, a child, a job or a trace). **Downgraded
  GATED -> ENUMERATED.** The instance is genuinely gone (`-K -` deployed, 0
  credentials in argv across the 4 re-swept axes), but `grep -ciE
  "argv|cmdline|hidepid"` over the deployed spec returns **0**: one assertion of
  193 covers this class and it is the *trace* axis. `/proc` carries no `hidepid`.
  Same disguise that cost C02 and C13.
- **C18** (a database dump absent, stale or empty). **Downgraded GATED ->
  ENUMERATED.** Derived on one axis — a database on the list cannot escape its
  check, 19/19 verified — and **listed on the other**: nothing derives the list
  from the machine. 11 SQLite stores exist; `wireguard/wg-easy.db` is classified
  nowhere.
- **C17** (a filesystem never checked). **Red test NEGATIVE — the gate is not
  broken.** `/run/initramfs/fsck.log` is a tmpfs file written at tonight's 17:29
  boot and dated `Tue Jul 28 15:05:07 2026`: the initramfs clock is frozen,
  e2fsck runs a full check every boot and antedates the superblock. Not
  asserting `Last checked` is therefore correct. **What is real**: the offsite
  has no assertion on its root at all — three lines to copy into
  `goss-offsite-health.yaml.j2`, and C02, being derived from timers, cannot see
  it.
- **C41** re-read at the code: **genuinely derived.** Nothing to do.
- **C21**: the register's own description is **stale** — ADR-031 removed the time
  window filter and the replacement is better. 77 snapshots, one per day from
  01-08 to 30-08, no gap, `locks/` empty.

### C45 must NOT be promoted to GATED — and this is the run's headline

`no-kuma-report-was-lost-in-silence` is a careful assertion: its floor is
**derived** (the first beat Kuma itself recorded since its own start, rather than
the 434 s observed), its controls were run in both directions, and it refuses to
judge rather than pass vacuously. Its defect is **coverage**. It reads a marker
that **8 of the 10 push sites emit**. The two that do not are the two that do not
live in `/usr/local/bin/`:

    /opt/homelab/scripts/backup-notify.sh:179       || log "push failed"
    /home/claude/.local/share/feed-digest/digest.sh:133  || log "WARNING: Kuma push failed"

Both **detect** the failure — the C45 fix reached them — and neither emits the
marker. So a lost push from the **entire backup chain** is invisible to the gate
written to catch exactly that. Three independent sources reached it
(`observability`, `backup`, and the main session's own re-measurement), and the
main session's first enumeration fell into the same hole and saw only 7 sites.

**The mechanism is the scope trap**, the one this register has recorded since
2026-08-22: an enumeration scoped to a DIRECTORY (`/usr/local/bin/`,
`roles/*/templates/`) instead of to the PROPERTY. It bit the gate itself, the day
after the gate was written. One line fixes the two scripts; the class stays
ENUMERATED until the marker's emitters are derived rather than listed.

### C03 — designed, not deployed

The gate is designed and **derived**: 104 units — the 20 shell artefacts **plus 84
goss `exec:` blocks**, two of the seven instances living outside the 20 — with its
five deliberate-failure controls. Measured before being proposed: pipefail 0
defects of 20, curl 0 defects of 22 (4 derived exemptions), and the "proxy guard"
family **established not gateable** (44 flags over 63 correct sites, 70 % noise).
C03 stays OPEN until the assertion is deployed and made to fail on purpose.

---

## Settled by the run of 2026-08-30 (evening) — three of the four OPEN, and C27

| ID | Property | Outcome |
|-----|----------------------------------------------|--------------------------------------------|
| C41 | A dead-man's fuse that the restart of its own watchdog re-arms from zero | **GATED, 15/15.** The assertion is genuinely DERIVED — it selects `where m.active = 1 and m.type = 'push'`, compares each silence against that monitor's own `m.interval`, fires only on the INCONSISTENCY (silent past its window while the last beat still says UP, so a late backup cannot mute it for days), and starves loudly (`only $n active push monitor(s) with a beat — the query stopped matching`). Verified live at 358/358, and on history: 54 silences past their window with a last beat UP, against 16 with a last beat DOWN where it correctly says nothing |
| C40 | A container that begins an ordered shutdown and is killed before finishing it | **ENUMERATED 29/29, 8 instances**, and the sweep is worth more than the count. **This row previously asserted that the evidence "is never in its own log, only in the next startup's" — that was WRONG**, and it is why the 02:45 sweep found 4. The daemon logs it directly, and the previous instrument (crash-recovery markers in container logs) can only see databases. #288 is verified good: the four DBs drained in 7.6-9.1 s of a 30 s grace and are absent from the 17:29 list. The remaining cause is configurational — 25 containers still sit at Docker's default 10 s |
| C42 | A time-ordering mechanism that ranks by a timestamp the machine wrote before its clock was correct | **ENUMERATED 6/6, 1 confirmed instance**, the journal one, fixed and verified (skew 32 days → 35 s). One residual and one belonging to `backup`. Broke a neighbour on the way out — see C17 below |
| C27 | A deployed artefact differing from the repo | **ENUMERATED 129/129, 0 instances** (108 homelab, 21 offsite), by sha256 and by static-line containment in both directions, and on BOTH layers the reopening of 08-29 distinguished: 0 units awaiting `daemon-reload`, 15/15 container configs re-read at the 17:29 restart, 8/8 host services, 5/5 offsite. Twenty commits in a day and no drift |

## Minted by the run of 2026-08-30 (evening) — 11

Six arrived already enumerated, because the agent that minted them also swept
them. Five are in the OPEN table above.

| ID | Property | Swept | State |
|-----|--------------------------------------------------|-----------------|------------|
| C44 | A verification whose cadence cannot observe the event it guards | 13/13 timers swept; **1 instance**, not 12 — see below | ENUMERATED, remedy shipped, **not gated** |
| C45 | A reporting path that cannot report its own failure | 10/10 push sites, **8 instances** | ENUMERATED |
| C47 | A PID 1 that cannot act on the signal it is sent | 29/29, **2 instances** | ENUMERATED |
| C48 | A real dependency that nothing declares | 29 services + 18 configs, **1 instance** | ENUMERATED |
| C49 | A hardening applied to an artefact its producer regenerates | 28/28, **1 new instance** (3 prior: #189, #299, the UFW sysctl) | ENUMERATED |
| C53 | A handler whose effect is expected earlier in the play than it occurs | 34 handlers, 1 flush point, **2 instances, 1 fixed** | ENUMERATED, **not gated** |

### C44's cardinal was wrong, and the error is the one this file warns about

It was recorded as **12 instances of 13**. That was a count of `homelab-*`
timers lacking `OnBootSec`, which is a *proxy* for the property, not the
property — the scope trap this register already documents from 2026-08-22:
**define the class by its property, not by the enumeration that was convenient
to run.**

Re-read against the property — *a verification whose cadence cannot observe the
event it guards* — the answer is **1**. `homelab-health` runs every five
minutes, so it observes any post-boot state on its own. `homelab-disk`,
`homelab-lynis` and the weeklies guard facts a reboot does not change. Only the
posture check both guards state that a reboot and a deploy alter, and ran on a
cadence that could see neither. **Do not carry the 12 forward as if it were
instances.**

**C44 is the one to act on, and it is not the one with the most instances.**
`homelab-posture.timer` has no boot hook: the spec was written at 17:23:28, the
last scheduled run was 11:09:01, and the next is the following day at 11:06.
Swept, **none of the 13 `homelab-*` timers carries `OnBootSec`**; the 12
calendar timers are `Persistent=yes`, which catches up a MISSED run but does not
fire on a reboot whose day was already served. `homelab-stack-heal` is
monotonic, so its absence is correct — 12 of 13.

C53 sharpens it rather than duplicating it: the deploy role's LAST task is
"Re-assert the container posture", and Ansible runs its 14 handlers at the end
of the PLAY, so the posture check grades the stack **before** the restarts the
deploy just queued. The repo held exactly one `meta: flush_handlers`, in
`security`. Together the two mean: **the only two occasions on which the posture
could have covered a day's changes both fell at the wrong moment — one before
the handlers, one before the reboot.** The state was in fact good; nothing in
the system established that.

**Both were fixed the same evening, in two lines** (PR #307): a
`meta: flush_handlers` before the re-assertion, and `OnBootSec=30min` on the
timer — 30 rather than 0 because `/mnt/data` is unlocked by hand and the staged
startup then takes ~9 minutes, and the script already exits 0 with
`/mnt/data locked — posture not checked` if the volume is not up. Verified on
the machine: `OnBootUSec=30min` live, and the post-flush re-assertion ran at
21:45:28 with `Result=success`, its monitor carrying a real reading rather than
a constant.

**Corrected is not gated, and the distinction is the whole point of this file.**
Nothing stops a future timer from shipping without a boot hook, or a future role
from putting a verification ahead of its own handlers. C53's SECOND instance is
untouched: `Restart Docker` still lands after the deploy role has configured the
entire stack against the old daemon, and the flush moves when it fires without
changing that ordering. The founding defect of this skill survived fifteen days
on nine scripts *after* being fixed on the tenth — which is exactly what
"corrected, not gated" costs when nobody writes it down.

## Reopened by the run of 2026-08-30 (evening) — C03 (fourth time) and C29

| ID | What reopened it |
|-----|--------------------------------------------------------------|
| C03 | **Its fourth reopening, and the fourth is ours.** `homelab-netdata-kuma.sh` pushed with no `--fail`, so Kuma's 404 "Monitor not found or not active" exited 0 and its own `log "ERROR: push failed"` was unreachable — an instrument answering "did the transfer complete" where the comment claimed "did the beat land". Fixed. Then the ASSERTION written to close C45 committed the same error: `journalctl \| grep -c 'kuma-push-failed:'` answers "does the journal contain this string", not "did a push fail", and it counted 7 losses on a host that had lost none — all seven were sudo's log of the audit's own verification commands. **A class that reopens four times does not need a fifth sweep, it needs a gate**, and it has none |
| C29 | `traefik-log-redactor`'s healthcheck is `pgrep -f "tail -F …"`, which matches the command line of the shell running `pgrep` — proven in the container, a pattern naming a nonexistent path returns a vacuous pass. The liveness half can never fail. **Calibrated down against the agent that found it:** PID 1 is the `tail \| awk` pipeline, so either death exits the container and the restart policy plus the container-down alarm already cover it. A real class instance with a one-line fix, not an exposure |

## Settled on 2026-08-30 — C39 and C43

| ID | Property | Cardinal, and outcome |
|-----|--------------------------------------------|--------------------------------------------|
| C39 | An event whose only durable evidence has a retention shorter than the event's own period | **ENUMERATED, cardinal 16** — every periodic job on the two hosts, against the most durable store that records a *distinguishable* result for it. 14 of 16 already correct and not by accident: their Kuma messages carry readings, so a run that did nothing cannot produce the message of a run that did something. **1 instance**, and it was the one that mattered: the weekly `prune + check` has two modes — re-read a twelfth of the repository's bytes, or list metadata — and after ADR-031 both pushed `prune and check completed`. The distinction had EXISTED and was lost in the migration; Kuma still holds the shell job's `local prune + deep check (8/12) passed` from 2026-08-02 beside `local prune + metadata check passed` from 08-09. Restored, richer, and gated from outside by `restic-deep-check-not-stale` (45 days, against a 24-37 day healthy gap) because resticprofile cannot know what ran last month. **A second instance on the cardinal's other axis**: the redacted access log at 6.17 MB/day spanned 4.86 days on the daemon default, against a host whose only trace there is one request a week — given its own 10 x 20 MB block, ~32 days. The 2 jobs whose only evidence is the journal took the retention branch instead: 500M held 16 days against monthly events, raised to 1500M (~48 days), which adds no writes because a cap governs deletion |

| C43 | An address that a deployed configuration hard-codes and a third party assigns | Enumerated: **6**, of which **1** was monitored | **ENUMERATED and closed on 2026-08-30 (#292).** Six addresses, each now pinned, derived, or watched, and the deliverable was stating which per address. 2 derived (the public IPv4 by the DDNS, the offsite endpoint by the re-resolve timer), 4 newly watched: the LAN address against `homelab_ip` — a one-day lease under 19 hardcoded occurrences, including the resolver handed to every VPN client — and the three Docker subnets, which carry no `ipam_config`. One of the four is load-bearing rather than tidy and is asserted against the two AUTHORITIES instead of a remembered value: Traefik's `vpn-only` admits `172.18.0.0/16` because that is where `proxy` happens to live, so the day Docker moves it every VPN client is refused — the assertion compares the live network to the allowlist file. Pinning was rejected on cost, not on principle: `proxy` is `external` and recreating it stops every container on it. Two stale ranges corrected (a C01 instance): one placed `homelab_socketproxy` at 172.21 against a measured 172.20, the other described 172.20 as a phantom's range when it is now a live one |

## Reopened by the run of 2026-08-29 (evening) — 2, plus one downgrade

An ENUMERATED class has no gate; these are what "will reopen" looks like in
practice, and both were reopened by changes made *after* their sweep.

| ID | What reopened it |
|-----|--------------------------------------------------------------|
| C26 | A credential reaching **a trace**. #259 removed the Traefik access log's 400-599 filter on 2026-08-28 so the log could answer who is present, and that filter is exactly what had made this class invisible to the 4-axis sweep of 2026-08-22 — the sweep was correct on the day and a later fix reopened the class underneath it. Two services, both of which can only present the credential where it lands. **The mechanism is not recorded here: this file is public and, until #287 shipped, the condition was live.** It is in the audit report of 2026-08-29, held off-repo. Closed by ADR-034 — masked before the line reaches any durable store, and gated by `traefik-access-log-carries-no-credential`. Tracked as **#287** |
| C27 | The repo is ahead of the host by the four `compose.yaml` changes of PR #286: `uptime-kuma` 960 s→180 s, `forgejo` 420 s→120 s, and both Redis healthchecks still unguarded. **C03 and C06 are therefore closed in the repo and not on the machine.** 12/12 running containers do match the deployed file, so there is no second "deployed but not applied" layer. **Not an issue — deploy #286.** |
| C03 | **Its space, not a change to the code.** Closed on 2026-08-29 as enumerated across the four goss specs; the instance found on 2026-08-30 is in none of them, because the sweep had been scoped to the files it was reading instead of to the property. Nothing regressed — the class had never been swept over the space it names. Restated and re-swept in **#289**; see its row below |
| C13 | **Downgraded GATED → ENUMERATED on 2026-08-30 (#291),** by the re-check C02's downgrade called for. Its gate is `homelab-posture.sh`'s config.json comparison, hardcoded to **vaultwarden** — a list of one presented as a gate on "a declared environment value shadowed by a persisted config file". The check itself is careful (it resolves `*_FILE` indirections, it reports an unreadable secret rather than passing), and none of that makes it derived. Its real space is every container that persists a config file capable of shadowing an injected value, and that has never been enumerated. **No second instance is claimed here** — what is claimed is that nothing would find one |
| C02 | **Downgraded GATED → ENUMERATED.** Its gate is a *list* of seven assertions, not a derivation, so it cannot catch an eighth instance — and there is one: lynis is installed on the offsite with its timer masked and no replacement, last report 2026-08-17. C10 is the shape C02 needs ("derived from the dump variables rather than listed"). Tracked as **#291**, which also re-checks the twelve remaining GATED rows for the same disguise. **Re-GATED on 2026-08-30.** The gate derives the control set from the machine — every deployed `homelab-*.timer` — and requires each to be classified in `homelab_control_timers`, failing in both directions so a stale exemption is as loud as an unclassified timer. The offsite assertions are generated from that register, so they cannot be shorter than it and it cannot be shorter than reality. Proven by removing an entry (`no offsite decision: homelab-lynis`), by adding one for a timer that does not exist (`register names timer(s) that are not deployed`), and by starving the enumeration (`only 0 ... the sweep stopped matching`). The eighth instance was settled by REMOVING lynis from the offsite rather than carrying its schedule across |

## Closed by the runs of 2026-08-29 — eight classes

Seven in the morning, C09 in the evening. C02's row records its downgrade.

| ID | Property | Outcome |
|-----|----------------------------------------------|--------------------------------------------|
| C01 | A documentary statement whose content contradicts the deployed artefact | **ENUMERATED**, not GATED, and the distinction is the honest part. Bounded at last: **472 machine-checkable claim occurrences across 81 files, 218 distinct referents** (121 absolute paths, 29 containers, 26 quoted thresholds, 23 units, 19 goss/alarm names). Twelve instances corrected in #284. Free prose cannot be gated; what replaces a gate is **duplication removal** — where a document lists something the machine owns, print the command that regenerates it instead. Applied three times in #284. Its **temporal slice** was swept to completion on 2026-08-29 evening — N=88 from 389 candidate lines across 63 files, 88/88, 68 exact and **20 contradicted** — and is tracked as **#293** |
| C02 | A control on the homelab with no counterpart on the offsite host | **ENUMERATED, not GATED** — recorded GATED by #285 on 2026-08-29 morning and downgraded the same evening. #285 gave the offsite `rest-server`, `wg-quick@wg0`, `ssh`, `fail2ban`, a `--failed` catch-all, ufw by its rules, and `offsite-wg-reresolve.timer`, and corrected its two SMART assertions. But a list of seven assertions is not a gate on the property, and the eighth instance was found the same day |
| C09 | Work a container schedules for itself, on a period no sweep window catches | **ENUMERATED 28/28**, closed 2026-08-29 evening after being named un-enumerated on 08-22 and sampled by three runs. Four axes: processes by cgroup from the host, cron files including `/etc/crontabs`, application schedulers queried in their own state, clocks. 4 containers carry an internal crond (1 inert), 11 an application scheduler, 4 databases an internal maintenance, 11 schedule nothing. **1 instance**: two Miniflux feeds of 119 reached `parsing_error_count = 3`, which excludes them from the scheduling query while leaving `disabled` false — feed 89 unpolled since 2026-08-20 and unable to recover on its own (tracked as **#294**). Also established: 25 of 28 containers run at UTC, with no job landing in the backup window |
| C03 | A validation whose instrument answers a different question from the one its comment claims | **ENUMERATED, and its space restated on 2026-08-30 (#289).** It had been scoped to *the four goss specs on both hosts* — the directory the first sweep happened to be reading — rather than to the property, which is the scope trap this register already records from 2026-08-22. Restated: **every guard in the repo that decides whether a downstream step may trust a value**, swept as 20 shell artefacts × their guard sites. First sweep (goss specs): `zcat \| tail` swallowing the CRC verdict, and `redis-cli ping` exiting 0 on an error reply. Re-sweep under the restated space, **3 more**: the netdata adapter's retry, guarded on "the body is not empty" while the caller needed "the alarms parsed" — the only one **observed**, one run logging `answered on attempt 3` and `unreachable or unparseable` together; and two latent siblings, `feed-digest.sh` reading a 200 that is not an entries page as "nothing unread" and pushing UP, and `cloudflare-ddns.sh` guarding a raw body for emptiness while consuming a derivation of it, which answers a malformed 200 by creating a duplicate record. All five fixed, all five proven to fail on purpose first |
| C04 | A working detector whose delivery path cannot reach a human | **Closed by decision.** smartd's mail channel was dead — and redundant: every alert it carried was already covered, more carefully, by the daily disk report. Silenced deliberately, with the measurement written into `smartd.conf`. Pi-hole's `gravity.info.updated` gained an assertion |
| C06 | A `start_period` whose real startup cost has never been measured | **ENUMERATED**, 13/13, after the first attempt closed at its instrument's edge. netdata cannot observe the wave that starts before netdata; re-measured from `State.StartedAt` to the first listen line, two more had overshot |
| C07 | A collector whose polling cost is disproportionate to the granularity of what it feeds | **GATED** by #285, and the gate is two assertions because one was a proxy. The floor is now derived from the resolution rather than written twice |
| C08 | A threshold probe that samples at an instant which cannot contain the peak it guards | **Closed by decision.** The homelab reads `Power Cycle Min/Max`, which resets each boot. The offsite keeps the instantaneous reading and reports its peak instead — its only maximum is lifetime, and a threshold on a figure that cannot come back down latches red forever |

## GATED — 11 here, plus C07 recorded above

A finding in any of these is a broken gate, not an audit result.

**C02 left the GATED state on 2026-08-29 evening, and the reason generalises to
every row below: a list of assertions is not a gate on a property.** Before
recording a class as GATED, check that its assertion is *derived* from the thing
it guards — the way C10's is generated from the dump variables and C18's from the
same source — rather than enumerating the instances that happened to be found.
A listed gate closes the instances; only a derived one closes the class.

**Re-checked on 2026-08-30 (#291).** Two rows were read at the code rather than
taken from their description. **C11 is genuinely derived** — the posture spec is
generated from `compose.yaml` and emits the user assertion for every service that
declares one, so "9 services" is a count and not a hand-list. **C13 is not**, and
it was downgraded. The remaining ten were checked against what this register
records of their derivation rather than re-read line by line; that is a weaker
check, and it is stated as one.

| ID | Property | Gate |
|-----|------------------------------------------------------|--------------------------------------------------------|
| C10 | A credential store readable beyond its service | goss posture, **derived** from the dump variables rather than listed, plus a named assertion for the Immich dumps (#217, #272) |
| C11 | A container whose running `Config.User` differs from what compose declares | posture assertion, 9 services (#145) |
| C12 | A rotated secret no consumer restarts to read | **Left this table on 2026-09-03 — downgraded to ENUMERATED.** There is no live assertion at all: nothing in the three deployed goss specs mentions handler coverage. The 51 notify sites and 0 orphans of #145 were a sweep, not a gate |
| C13 | A declared environment value shadowed by a persisted config file | **Left this table on 2026-08-30 — see the downgrade above.** The assertion is hardcoded to vaultwarden (#124, #159); a list of one is not a gate |
| C14 | A certificate with no expiry watch, or a silent ACME failure | `homelab-health.sh` parses `acme.json` directly, 21-day threshold, 18/18 (#157) |
| C15 | The offsite repository losing the one property that makes it a backup | goss assertion on the live rest-server process, proven to fail in both modes (#278) |
| C16 | A read-write bind mount its container cannot create files in | posture assertion, continuous since 2026-08-16 |
| C17 | A filesystem never checked, and boot triggers reset every boot | `passno` plus the daily disk report's `ext4 clean` field (#254, #260) |
| C18 | A database dump absent, stale, or empty | goss `backup-dumps`, 19 checks, generated from the dump variables so a database cannot get a dump without a check (#177, ADR-032) |
| C19 | A failed systemd unit, or a timer whose service did not succeed | goss `units.yaml` plus the health script's last-run check — **homelab only; the offsite half is C02** |
| C20 | A secret that a deploy reports as rotated without rotating it | **Left this table on 2026-09-03 — downgraded to ENUMERATED.** 4 hand-written probes over a space of 16 secret files; a list of four is not a gate (#159 fixed the case-mismatch bug, which is a different question) |
| C21 | A snapshot that missed its offsite copy and is never retried | retention monitor (#158, #168). **The "time-window filter" this row used to name no longer exists** — re-verified 2026-09-03: `copy:` carries no bound, every snapshot is re-offered nightly, 31 local / 81 offsite with no gaps. The class holds; the description was stale for the second time |
| C81 | A byte written into a file whose consumer reads it back through a narrower encoding than the producer's | `ops/check-ascii-system-files.py` in pre-commit, proven to fail in both directions (2026-09-04) |
| C41 | A dead-man's fuse re-armed from zero by the restart of its own watchdog | `kuma-no-push-monitor-silent-past-its-own-window`, derived from Kuma's own monitor table and each monitor's `interval`, with a starvation guard; discriminates on 54 historical silences against 16 (2026-08-30) |

### Broken gates found on 2026-08-30 — these are red tests, not audit results

- **C17** (a filesystem never checked). `fake-hwclock` made the premise of
  `filesystem-checks.yml:176-183` false the same evening: the kernel logged
  `checktime reached` for the first time since 1 August, and the offsite retains
  proof that `e2fsck` rewrote (`FIXED.`) the backup disk's superblock from a
  wrong clock. The gate asserts `passno` and `ext4 clean`; it has never asserted
  `Last checked`.
- **C26** (a credential reaching a command line, a child process, a scheduled
  job or a trace). Recorded GATED on the strength of one assertion covering the
  *trace* axis. The *argv* axis has **no live assertion at all** — `grep -niE
  "argv|cmdline|hidepid"` over the deployed spec returns nothing — and carried a
  live instance: `homelab-netdata-kuma.sh` passed the push URL, token included,
  as a curl argv on a `/proc` without `hidepid`. #177 converted eleven scripts to
  the stdin form and #188 the twelfth; this role was the thirteenth and nothing
  would have found it. Fixed 2026-08-30. **The class is GATED on one of its four
  axes and the table said GATED — the same disguise that cost C02 and C13.**
- **C06** (a `start_period` whose real startup cost has never been measured). 14
  declared against a header that reads `THIRTEEN`; the redactor's 30 s was never
  measured, and `/run/traefik/access.log` appears 99 s after its container starts
  while its healthcheck requires the file.

## ENUMERATED — 27 here; the rest (C01, C03, C06, C09, C13, C27, C39, C43, C75) are recorded in their own sections above

Swept completely at least once. Re-check only after a change that could reopen
them; do not re-derive without a new symptom.

| ID | Property | Swept | When |
|-----|--------------------------------------------------|-----------------|------------|
| C22 | A healthcheck that cannot report the failure it names | 28/28, with negative **and** positive controls | 08-19, re-swept 08-29 |
| C23 | A kernel parameter differing between hot and boot path, or between hosts | 30/30 both hosts | 08-19 |
| C24 | An image that is not genuinely arm64 | 28/28 | 08-21 |
| C25 | A bind mount whose inode differs from what the container sees | 19/19 against `/proc/<pid>/root`; 62 mounts re-checked 08-29 | 08-19 |
| C26 | **REOPENED 2026-08-29 evening** — a credential reaching a command line, a child process, a scheduled job or a trace | 4 axes, incl. 3 457 `/proc` sweeps over 140 s with a positive control | 08-22 |
| C27 | **REOPENED 2026-08-29 evening** — a deployed artefact differing from the repo | 12/12 by sha256, 25/25 templates, both hosts | 08-29 |
| C28 | An operator key no role reads, or a role key the example omits | 123 keys, both directions, 0 and 0 | 08-29 |
| C29 | A construct that disables a feature silently | 81 read one by one; 08-29: 80 `default()`, 22 `failed_when: false`, 5 `creates:`, 3 absent-var gates | 08-19, 08-29 |
| C30 | A proxy router or middleware declared but not applied | 19/19 routers in the live API, headers on 18/18, `vpn-only` proven both ways | 08-29 |
| C31 | A name resolving differently inside and outside | split DNS 18/18, single DoH upstream, 2590/2590 queries | 08-29 |
| C32 | A port reachable from outside that should not be | probed from the offsite uplink with a known-open control | 08-19, 08-29 |
| C33 | A broken relative link or a path that does not exist | 104 links, 123 absolute paths | 08-29 |
| C34 | A service page contradicting its ADR, its runbook or its container | 20 pages × 3 axes | 08-22 |
| C35 | A push monitor carrying a constant instead of its script's message | 12, now 15; all at `maxretries=0` | 08-19, 08-29 |
| C36 | An unsized tmpfs | 37, parsed rather than grepped | 08-21 |
| C37 | A WAL-mode SQLite copied without its `-wal` | 3 dumped / 4 declined / 3 ephemeral | 08-29 |
| C38 | A container log growing without rotation | 28/28, rotation proven applied rather than declared | 08-21, 08-29 |
| C40 | A container killed before finishing an ordered shutdown | 29/29, 8 instances, on the daemon's own log rather than on crash markers | 08-30 |
| C42 | A mechanism ranking by a timestamp written before the clock was right | 6/6, 1 instance | 08-30 |
| C44 | A verification whose cadence cannot observe the event it guards | 13/13 timers, 1 instance (12 was the proxy count) | 08-30 |
| C45 | A reporting path that cannot report its own failure | 10/10 push sites, 8 instances | 08-30 |
| C47 | A PID 1 that cannot act on the signal it is sent | 29/29, 2 instances (`SigCgt` masks, not documentation) | 08-30 |
| C48 | A real dependency that nothing declares | 29 services + 18 configs, 1 instance | 08-30 |
| C49 | A hardening applied to an artefact its producer regenerates | 28/28, 1 new instance | 08-30 |
| C53 | A handler whose effect is expected earlier in the play than it occurs | 34 handlers, 1 flush point, 2 instances, 1 fixed | 08-30 |
| C67 | A verification whose deadline was sized against an input that has since grown | 13/13 both hosts, 2-4 instances | 08-31 |
| C68 | A store whose declared retention is overridden by a limit that is not the one written down | 7 stores + 31 log rings | 08-31 |
| C69 | A periodic control whose own runtime nothing measures | 16/16, 1 material instance | 08-31 |
| C70 | A rule inert today that would be a fault if enforced | 19/19 UFW rules, 2 instances | 08-31 |
| C71 | A recurring cost driven by rewrite rate rather than information carried | 22/22 backup subtrees, 6 instances | 08-31 |
| C72 | A remedy that enlarges a window, effective only after a delay equal to the enlargement | 2 windows | 08-31 |
| C74 | A rule whose decision is pre-empted by another component acting earlier on the same object | 7/7 UFW inbound rules, 1 instance | 09-02 |
| C76 | A verification whose expiry is reported through the same channel, and in the same terms, as the condition it watches | 197 + 43 assertions; 15 within 2x of budget | 09-02 |
| C12 | A rotated secret no consumer restarts to read | 51 notify sites, 0 orphans — **downgraded from GATED 09-03**, no live assertion | 08-16, 09-03 |
| C20 | A secret that a deploy reports as rotated without rotating it | 4 probes over 16 secret files — **downgraded from GATED 09-03** | 08-19, 09-03 |
| C78 | A set of which two or more components each hold their own definition, in different grammars, with nothing comparing the definitions | 4/4 name grammars (18/18/18, Kuma 15/18) + 21/21 restore expressions against 13 exclude patterns | 09-03 |
| C82 | A fault whose only detector runs earlier in the same sequence than the step that introduces it | 308/308 write-sites + 77/77 binary-use + 34/34 handlers; 12 pairs, 2 instances, 10 refuted | 09-05 |

## DECLINED

The operator considered these and said no. They are in the register so that a
run does not spend budget re-proposing them. Detail and reasoning stay in
`settled.md`.

Live kernel patching · an IPS/reputation layer · a forward-auth SSO portal ·
user-namespace remapping · the kernel audit daemon · additional fail2ban jails ·
reinstalling rkhunter · unmasking the distribution's lynis timer ·
`errors=remount-ro` (a decision, not a finding) · external supervision of the
main host · a timed restore drill · drift detection between the two hosts ·
dumping the media services' metadata databases · expiring the frozen snapshots
of obsolete path sets · memory limits on containers · reopening the DNS-over-HTTPS
investigation · the structural elevated capabilities and writable root filesystems.

**Added by the operator's arbitration of 2026-09-02**, all with the instruction
that they never be proposed again:

- **The Docker daemon stall of 2026-09-01** — 146 daemon-level healthcheck
  timeouts in one episode, 18 more on 08-25, an ~11.5 h Kuma push blackout, cause
  never established. Not to be investigated.
- **`killswitch.service` cannot reach `failed`** — `Restart=always` +
  `RestartUSec=10s` against `StartLimitIntervalUSec=10s`/`Burst=5`, and the unit
  is in no goss spec. Sole remote-poweroff mechanism.
- **The offsite restore that cannot fit** — `offsite-backup.md:189`, ~353 GiB into
  221 GiB free, unconditional ENOSPC on the disaster path. Half of C63, the other
  half having been fixed by `241d504`.
- **C29's vacuous liveness half** — the redactor's PID 1 is `sh`, `pgrep` matches
  its own static argv even if `tail` dies. The file half works.
- **The offsite root having no fsck assertion** — `offsite.yml` never plays the
  `observability` role, so C17's assertions cannot deploy there.
- **The files hidden under `/mnt/data`** — written while the volume was unmounted,
  masked by the mount.
- **Both intrusive measurements**: bind-mounting `/mnt/data` to measure what the
  mount hides, and provoking a deliberate authentication failure. The second is
  what makes C57 permanently undecidable, and that is accepted.

**Added by the operator's arbitration of 2026-09-04:**

- **C77's non-secret slice** — every Jinja interpolation of a NON-secret value
  into a consumer whose grammar gives meaning to its characters. The secret half
  is enumerated 37/37 and its live defect is fixed; the rest is an unbounded read
  of the whole template tree for a class whose only demonstrated cost has been in
  secrets. Closed the way C66's tail was. Do not re-open it without an instance.

**C76** is on this list in effect rather than in form: it was minted and
enumerated on 2026-09-02 and no action was requested on it.

---

## Working a run

1. Read this file. The OPEN table **is** the mandate; the number of OPEN classes
   is the headline of the report.
2. Assign each OPEN class to the domain agent that owns its space. An agent's
   job is to close its class by enumeration — state `N`, sweep `N/N`, record the
   count — or to say precisely why the space cannot be bounded.
3. Anything found that fits no class is a **mint**. Write the property and the
   space before writing the instance; an instance without a property is how C01
   stayed open for ten days.
4. Update this file before writing to the operator: state transitions, new
   cardinals, new classes.
5. A class only reaches GATED when the assertion has been **made to fail on
   purpose**. #278 is the reference: it was disbelieved until it failed in both
   modes.

## What this file is not

It is not a findings log — that is the issue tracker. It is not the history of
decisions or the catalogue of instrument traps — that is `settled.md`. It holds
exactly one thing: **which classes are closed, which are open, and what keeps
the closed ones closed.**
