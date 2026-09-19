# Domain mandates

One entry per agent. Each gives the scope, the angle that actually pays, and the
state already established so the agent does not spend its budget rediscovering
it. Update the "already established" lines after each run — they are what keeps
successive audits from repeating themselves.

**This file gives the scope; `classes.md` gives the mandate.** An agent is sent
to close the OPEN classes that live in its space, not to hunt freely in it. The
current ownership:

**This table goes stale faster than anything else in these files.** It listed
eight OPEN classes on 2026-08-30 that had all been closed, in some cases days
earlier — which would have sent eight agents to re-derive settled work. Rebuild
it from `classes.md`'s OPEN table at the start of every run; if the two
disagree, `classes.md` wins.

As of the SIXTH run of 2026-09-19, key `oracle`. **Rebuilt from `classes.md`'s
OPEN table — do not trust this copy if the two disagree.**

**ONE OPEN CLASS. The counter went 1 -> 1; C109 and C110 were ACCEPTED by the
operator and C111 and C112 were minted, so the class total went 110 -> 112.**
C44 stays open, its cardinal moved to **TIER A 16, coverage 4/16 = 25 %**
(`docker` demoted on the #15 predicate), and **the sixth run found why it has
never closed: this register records the cardinal WITHOUT the membership.** It
refers to admissions `#13`/`#15`/`#16` of a 27-row list that exists nowhere in
the file; only 11 of the 16 are nameable. **Writing those 27 rows is the next
run's first task and it is bookkeeping, not research.** Until it exists, no run
can state N/N and no new cardinal should be trusted. **The termination clock
RESETS.**

**What `oracle` proved, for whoever writes key twenty-six.** It was invented
rather than taken off the list, and it paid in the ASSERTIONS — a third
territory, distinct from the estate (`attendance`, `aggregation`) and from the
instruments (`staleness`, `commensurability`). Its two mints both concern where
an expectation comes from rather than whether a mechanism runs. **The rule it
confirms for a fourth time: a key that turns on the thing doing the checking is
worth more than one that turns on the thing being checked.**

**And it produced the run's most useful negative result, which is a discipline
result rather than a finding: three of the eight agents' headline claims were
written decisions reported as gaps, and one proposed a fix that the repository
had already tried and reverted with the reasoning left in place at the point of
the code.** Read the code before proposing to change it; this estate writes down
why it did things.

| Class | Owner | What is left to do |
|---|---|---|
| C44 | `system` | **SIXTH RUN — the blocker is BOOKKEEPING, not research. TIER A is 16 (`docker` demoted on the #15 predicate: daemon.json declares 6 values, `docker info` resolves 3, and `shutdown-timeout` + `log-opts.{max-size,max-file}` are exposed by no daemon readout, measured 0/0/0 with `LoggingDriver`=1 as the positive control). Coverage 4/16 = 25 %.** `fail2ban` was tested for demotion and SURVIVED (`get <jail> action <act> port` and `get actions` resolve the 5 keys with no `get <key>` verb). A clock admission was tested and REJECTED — `timedatectl show-timesync` resolves everything but `/etc/systemd/timesyncd.conf.d/` is empty, so no declared intent. **THE REASON IT CANNOT CLOSE: this register records the cardinal WITHOUT the membership.** It refers to `#13`/`#15`/`#16` of a 27-row list that exists nowhere; only **11 of 16** are nameable (the 4 covered + the 6 read on 09-19 + #13 firmware). That is why the cardinal has moved 19 -> 17 -> 16 across three runs — each re-derives it against a list it cannot read. **FIRST TASK: transcribe the 27 rows into `classes.md`. Do not close C44, and do not trust a new cardinal, until they are there.** **FOUR sub-spaces remain closed — TIMER 13/13, DEPLOY-TAG 26/26, HOST-HARDENING 20/20, and the comparator route's own cardinal. Do not re-derive any of them.** Four subsystems have no resolver at all — pam, needrestart, smartd, cloud-init; systemd is excluded on normalisation. Two reserves hold: the route compares `/etc` to effective state, so a writer that rewrites the `/etc` file the estate owns moves both sides together (the `pam-auth-update` shape); and the route's cadence is daily, which is C44 applied to its own output |

**Six domains own no OPEN class, and that is the normal state now.** Their job is
the one that demoted C02, C13, C20, C26 and C17: re-read the GATED assertions in
their area and ask whether each is DERIVED from the thing it guards or is merely a
list of the instances once found. `backup` did exactly that on 2026-08-31 and again
on 2026-09-19, finding C15's recorded cadence wrong both times.

**ONE GATE IS RED — C07, and it is `observability`'s.** Unchanged in kind and
sharper in measurement: a floor rendered by one Jinja expression from ONE
collector's interval, compared against a fleet. `apps.plugin` fell 22.4 % -> 4.50 %
of a core against a cadence factor of 5, so the 2026-09-18 fix landed — but the
gate certifies the go.d **docker** collector at 0.70 % while `cgroups.plugin` runs
at netdata's stock 1 s for **6.91 % across 995 charts**, with no alarm, no goss
check and no push monitor reading a cgroups context. A derived floor must key on
`(chart context) -> update_every` from `/api/v1/charts`. **The gate was not
widened, so the row stays red.**

**CORRECTED 2026-09-19 (fifth run): keying that floor on the CONTEXT does not
work.** `(context -> update_every)` is NOT a function — `disk.space` and
`disk.inodes` each carry both 1 and 5, because the `/tmp` charts run at 5 s.
Measured twice, with a reachability control (host `000`, container `200`), and
after the measuring agent's own scratch file was removed, so it is structural.
**Use a per-plugin floor**: 4 plugins carry >100 charts and it comes up red on
exactly one member, against 1712 of 3838 charts for a naive `>= 5`. And there is
no cheap route — the light endpoints (`/api/v1|v2|v3/contexts`) do not carry
`update_every` at all, 383/383 missing, so it is `/api/v1/charts`, 5.3 MB,
0.74 s. `proc.plugin`, 531 charts at 1 s, is named nowhere either.

**C03-T IS NO LONGER RED ON ITS NAMED DEFECT — read this before quoting the
register's older text.** Both clauses of the deployed `/etc/goss/posture.yaml`
carry `h.status = 1` (`:3240`, `:3255`), verified independently. **Its
"never completed a green SCHEDULED run" residual RETIRED on 2026-09-19 at
11:07:08** — observed firing, exit 0 in 66 s, plan 403 / 403 results / 0 failures.
ONE residual is genuinely open: a live reporter pushing a genuine failure is still
indistinguishable from a mute one, which is the fail-safe direction.

**Three classes sit ENUMERATED with live instances** — verify the instances are
gone, do not re-derive the classes. **C98**: still the same 2 of 4 (`$BEFORE_ASSETS`
and the unguarded `compose.yaml.bak`, read back as authoritative at runbook:369).
**C99**: unchanged, 31 sites, transmission's value-keyed `lineinfile`, 0 live
duplicates. **C100 is CLOSED** — the scheduled run of 2026-09-19 11:07:08 pushed
`posture OK — 423 checks (...) — scheduled run` at 09:08:14 UTC, against the
01:11:17 beat's `— manual run`. The provenance field discriminates, and the
register has its first green SCHEDULED posture run. Do not carry the residual
forward.

**Do not re-derive**: C20 (43/43 by value), C103 (37/37), C105 (28/28), C01's
instruction-file stratum (123/123), C88's three slices, C37, C90, C94, C95, C104
(219/219), C44's deploy-tag (26/26) AND host-hardening (20/20) sub-spaces,
**C107 (32/32 executables + 12/12 supervision-plane instruments — the two bounds
are complementary, neither contains the other)** and **C108 (32/32 containers,
31 resolving a mutable tag + 1 digest-pinned)**.

**A THIRD baseline trap, paid on 2026-09-19 (fourth run), and it is new in kind.**
The two previous runs opened on a hand-run mistaken for a scheduled one. This one
opened on a genuinely scheduled green — and the green **predated the deploy it
was being used to certify by 33 minutes**: `/etc/goss/posture.yaml` mtime
11:40:58, last posture run 11:07:08-11:08:14, no run since. The live beat carried
`goss 400`; goss counted 406. **Before quoting a verdict, compare its timestamp
to the mtime of what it is supposed to have graded.**

**Rows corrected in the second 2026-09-19 run; do not re-derive them.** C15's
cadence is DAILY, not weekly. C44's deploy-assertion cardinal is 26, not 12. C105's
inverse cardinal is 12, not 11. C20's cardinal is 43 by value — 16, 15 and 59 were
three different bounds and 59 is not reproducible.

**Rows corrected in the THIRD 2026-09-19 run.** **Seven classes carry cardinals
frozen at a 28-container estate against 32 today** — C25 is 80 bind mounts not 62,
C36 is 41 tmpfs not 37, C50's Docker half is 28 not 25, and C22/C24/C38 move 28 to
32. C53's row says 34 handlers / 1 flush point; it is 41 / 3. **C21 is an ARGUMENT,
not a gate** — nothing would notice a bound being added to the deployed `copy:`.
C74's offsite residual is FIXED. **A15 is NOT resolved and its withdrawal matters:**
the two `ufw reload`s its test relied on never happened, so the control never ran.

**The baseline is part of the brief, and two of its entries are traps every time.**
A never-run unit reports `Result=success`, and so does a unit that DOES NOT EXIST
(`LoadState=not-found`, exit 0, measured) — so `Result` alone can never say whether
something ran; read `ExecMainStartTimestamp` beside it. **`Result` cannot
distinguish scheduled from manual either — read
`systemctl show <unit>.timer -p LastTriggerUSec` beside it.** TWO consecutive runs
opened on a false clean built from a hand-run: 2026-09-18's was 17 minutes before
the briefs, 2026-09-19's was 7 hours before and asserted in all eight briefs that
C100 had retired. Three agents demolished it independently. Before quoting a
monitor's colour, ask when its last SCHEDULED execution was and what THAT one
reported.

**And never count occurrences of a command string in `auth.log`.** A `grep` run
under `sudo` writes the string it hunts into the log it reads; on 2026-09-19 that
cost two conclusions, one of which reached the operator as a suspected intrusion.

**Twenty-FIVE keys are now spent** (`oracle` added 2026-09-19, sixth run — it
minted 2 and it bit on the ASSERTIONS, a third territory after the estate and
the instruments): `time`, `order`, `identity`, `scale`, `authority`,
`representation`, `vacuity`, `exclusivity`, `interruption`, `succession`,
`residue`, `concurrency`, `plurality`, `dependency`, `granularity`, `locality`,
`repetition`, `reversibility`, `quiescence`, `collision`, `commensurability`,
`aggregation`, `staleness`, `attendance`, `oracle`. The mint rate across them
reads 5, 11, 12, 7, 2, 4, 1, 0, 2, 1, 2, 2, 3, 1, 0, 2, 2, 1, 2, 4, 0, 1, 1, 2,
**2**. A run that reuses one proves nothing. **The pair of consecutive zero-mint
runs the criterion needs has still never been achieved.** Still proposed and
unspent: `asymmetry` and `cost` — the register records that `cost` shares
`scale`'s weakness, little of it leaving a trace you can measure tonight. **Key
twenty-six must be invented or must be `asymmetry`.**

**What `staleness` proved, for whoever writes key twenty-four.** It was taken off
the proposed list rather than invented, and the register had predicted a low mint
yield on the grounds that it overlaps C39, C44 and C76. **The prediction was
right about the count and wrong about where the value would be**: the estate came
back measured clean almost everywhere, and the key bit on the INSTRUMENTS and on
this register — a firewall check that never read the default policy, a premise
about Kuma retention written in three live artefacts and true only by accident,
an agent file that mis-sized its own detection window by 2.5x and had been
re-blessed by a commit that morning, and four self-contradictions in
`classes.md`/`settled.md`. **Third confirmation of the rule: a key that turns on
the instrument is worth more than one that only turns on the estate.**

**What `aggregation` proved, for whoever writes key twenty-three.** It was invented
rather than taken off the list, and it paid in the estate rather than the
instruments — the reverse of `commensurability`. Four of its five shipped findings
were reductions that mapped a failing reading to a passing verdict, and the fifth
was a floor that bounded presence instead of cardinality. **The declared-overlap
table is what kept the mint count honest**: five classes were named in every brief
as instance-only, and seven of eight domains came back with an explicit "no mint"
rather than dressing an instance as a discovery.

**The rule the run cost twice over: an instrument that writes to the medium it
reads is not an instrument.** A `sudo grep` for a command string logs that string.
Two agent conclusions died to it, one of them reaching the operator as a suspected
intrusion.

**What `commensurability` proved, for whoever writes key twenty-two.** It minted
nothing and still paid, because its yield was in the INSTRUMENTS rather than the
estate: the two sharpest findings of the run were a systemd field rendered in two
incommensurable representations, and a container clock two hours off a jail's
window. It also cost the main session two bad instruments of its own, both caught
by a control and both recorded. Rule confirmed twice now: **a key that turns on the
instrument is worth more than one that only turns on the estate.**

**Six domains own no OPEN class and are not idle.** Their job is the one that
demoted C02, C13, C20, C26 and, on 2026-09-05 evening, C17: re-read the GATED
assertions in their area and ask whether each is DERIVED from the thing it
guards or merely a list of the instances once found. `backup` did exactly that on 2026-08-31 and found C10 to
be *stronger* than recorded, C21's description stale, and C18's list underived.

A class with two owners is deliberate: C66's two halves are code and prose, and
the 2026-08-31 run showed that neither is visible from the other — the technical
sweep found a handler ordering its own half could not see, and the documentary
sweep found a runbook the code sweep had no reason to open.

The angles below share one idea: **Uptime Kuma already covers whether a service
answers.** Sending an agent to confirm that wastes it. Send it after what no
instrument watches.

---

## system

**Scope** — OS, kernel, sysctl, filesystems, systemd, RAM/swap/IO, Pi hardware:
temperature, throttling, USB, SD-card wear.

**Angle** — headroom rather than incidents. A machine with no OOM kill can still
have spent its margin; ask how close it came and how often, not whether it
broke. Distinguish a past peak from a continuous drift, since they call for
different answers.

**Traps** — swap accounting: use cgroup counters, never a sum of per-process
`VmSwap` (it double-counts pages shared between forked children). A swap file
guarded by `creates:` is not resized by changing its size variable. And swap
occupancy is **not** a steady state to project from: it accumulates cold pages
until something restarts the containers, at which point it collapses (52 % → 3 %
on 2026-08-16). Always say when the last restart was before quoting a figure.

**Already established** — the journal cap and the ext4 error counters were both
handled on 2026-08-16 evening; the cap was raised to **1500M on 2026-08-30**
(#290, class C39) and the daily disk report now
carries an `ext4 clean` field. Sysctl, mount options, unit health and the
hot-versus-boot path were all verified matching with zero drift; do not
re-derive them without a new symptom.

---

## security

**Scope** — hardening, firewall, fail2ban, SSH, secret handling, exposure
surface, physical security.

**Angle** — what has been deployed *since the last audit* and has therefore
never been reviewed. Each new service is a chance for the established posture to
erode quietly. Also read the posture-check script for what it does **not**
assert: the gaps in an automated check are where drift accumulates.

**The secret class is swept by VALUE, not by mechanism — C89, 2026-09-12.**
Every earlier sweep of it was bounded by a mechanism (container mounts, then
`environment:` blocks, then write sites) and every one had a blind spot, because
the class is defined by a value and not by a mechanism. The method that closes
it: derive the live secret VALUES, control that derivation against known
secrets, then search each enumerated surface with a positive control. Do not
re-derive the swept surfaces without a new symptom — and read
`settled.md`'s "Handling secrets DURING an audit" FIRST, because that sweep
caused five exposures of its own and each one is a repeatable mistake.

The unswept slice, if this is ever picked up again: restic snapshots (376 GB,
123 snapshots), and the depth-limited subtrees of Immich, Jellyfin, Navidrome,
Transmission and Nextcloud.

**Calibration** — this is a home lab, not a bank. Rank by realistic attack
scenario. A latent weakness that costs one line now and a full re-enrolment
later is worth raising; a theoretical one that costs a weekend is not.

**Already established** — see `references/settled.md` for the container-layer
work that is closed and the hardening proposals that have been declined.

**The argv class (C26) was ENUMERATED on 2026-08-22 and REOPENED on 2026-09-12
on its TRACE axis — see `classes.md`'s OPEN table before reading the rest of this
paragraph as settled.** Its four axes were: a
YAML parse of all 28 services in `compose.yaml`, the child processes those
command lines spawn, the in-container scheduled jobs no sweep window catches, and
an empirical 140 s `/proc` sweep against 35 real secret values with a positive
control. Do not re-derive it — but note the scope trap that produced it: the
security agent that run concluded "exactly one live instance" from an enumeration
of *deployed scripts*, while the worst instance was a healthcheck in
`compose.yaml`. **Define the class by its property, not by the directory you are
reading.** If you re-check anything here, re-check that the sweep still finds
`transmission-remote` running before believing a null result.

The **writability sweep is done** as of 2026-08-16 evening: every running
container was checked for a read-write bind mount it cannot create files in, and
the four that failed are fixed except wg-easy. The posture check now asserts it
continuously, so do not redo the sweep by hand — read what the assertion reports.
Two instruments lied while it was being built and will lie again: `docker top -o
uid` returns nothing, and busybox `test -w` answers "writable" for uid 0
regardless of capabilities. Use `Config.User` and `access(2)`.

**Two traps the 2026-09-12 run paid for, both worth carrying.** First, an
un-`sudo`'d shell **glob** over a root-only directory does not fail — it expands
to nothing, or to the literal pattern, and every downstream count reads zero. It
cost the main session a false "0 domains" on the Traefik ACME backups; the fix
is `sudo sh -c '...'` so the glob expands as root. This is the same family as the
un-`sudo`'d recursive `grep` recorded on 2026-09-11. Second, **comparing two
secrets by hash requires both sides stripped identically**: `jq -r` appends a
newline, `cat` of a file may not, and hashing one of each compares different
strings. The main session reported a Vaultwarden token as "different" on that
basis before re-measuring it as byte-identical. Always include a control that
hashes one known string twice.

---

## network

**Scope** — DNS and ad-blocking, split-DNS, DoH, reverse proxy, TLS/ACME,
VPN, dynamic DNS, container networks, NAT.

**Angle** — configuration quality, which nothing tests. Query the proxy's own
API rather than reading labels: a middleware declared is not a middleware
applied. Fetch real responses to see which headers are actually served. Check
what the router forwards by probing **from outside**, using the offsite host's
uplink — and include a port known to be open as a control, or a timeout proves
nothing.

**Hard constraint** — remote access to the main host runs through the VPN
tunnel and there is no out-of-band path. Never propose anything that could drop
it without someone physically on site.

The mechanism, measured on 2026-08-22, because it is sharper than the rule:
`/etc/wireguard/wg0.conf` is a **symlink onto the encrypted volume**. After a
reboot it dangles, `wg-quick@wg0` cannot start, `wg-easy` cannot either, and
`homelab-unlock` asks for a passphrase interactively. **No unlock without the
tunnel, no tunnel without the unlock.** So a *reboot* belongs in the same class
as a wg-easy upgrade: propose, never perform. `claude-remote-control` is not an
escape hatch — its vault mount needs Nextcloud, hence docker, hence the unlock.

Also worth knowing before touching Pi-hole: `dnsproxy` shares its network
namespace, so **recreating** pihole — which `compose up` does on any definition
change — destroys that namespace while dnsproxy stays up and healthy. A guard now
re-attaches it, but a proposal that recreates pihole should still say so: it
costs the house its resolution, though never SSH, which goes to a bare IP.

---

## services

**Scope** — container configuration, image pinning, arm64 fitness, resource
sizing, health checks, proxy label wiring, mount coherence.

**Angle** — again, configuration quality rather than liveness. Missing or lying
health checks, unpinned images, dead environment variables, orphaned or
redundant mounts, logs growing without rotation, containers restarting without
anyone noticing.

**Traps** — `docker stats` reports resident memory only and badly understates
any container whose pages have been swapped out; add the cgroup swap counter
before ranking footprints. A symlinked secret breaks when a container reads it
through a *directory* bind mount, because the link resolves inside the
container's namespace. A heal timer resurrects stopped containers, so
maintenance needs a compose-level `down`, not a `stop`.

---

## backup

**Scope** — coverage, database dumps, restore procedures, offsite replication,
retention, integrity verification.

**Angle** — this domain gets worked on often, so the value is in what the last
round did *not* cover. Do the restore procedures still match reality after the
paths and container names moved? Does a service's own scheduled backup actually
produce fresh files, and would anyone notice if it stopped? Is there data
produced recently that falls outside every backed-up path? Would a failed dump
be visible, or does it degrade to a warning nobody reads?

**Hard constraint** — read-only in the strictest sense. The offsite repository
is append-only, and a concurrent operation there creates permanent duplicates
that only a manual prune reclaims.

---

## observability

**Scope** — monitoring, alerting, health scripts, log management, metric and
alert thresholds.

**Angle** — what is *not* watched, and whether what is watched can actually
reach a human. Follow the notification path all the way to its destination: an
alerting stack with rules running and no recipient configured is the exact shape
of defect this audit exists to find. Then look for monitors that probe a façade
rather than a function, and for thresholds that are decorative because they can
never trigger.

**Method** — read the *content* of what a monitor reports, not its colour. A
green monitor carrying a constant message is the signature of a broken push.

**Constraint** — the monitoring database is read-only here: open it with
`mode=ro` on the LIVE file — a `cp` misses the write-ahead log and hands you
stale messages. Never write a test heartbeat during an audit. Its timestamps are
UTC while the hosts are local time.

**Already established** — the notification path was followed end to end on
2026-08-16 evening and is sound: every monitor bound to a valid webhook, egress
verified from inside the Kuma container. Do not re-derive it.

**Two corrections, both measured on 2026-08-29, both to text that used to live
here.** "PENDING notifies nobody" is **false** — PENDING escalates, with the
wrong text (established 2026-08-19). And **no push monitor sits at
`maxretries=1`** any more; two agents measured all of them at 0 independently.
Do not carry either claim forward. The counts they came with belong in
`classes.md`, not in this file.

---

## ansible-deploy

**Scope** — role structure, argument specs, idempotence, vault usage, handler
correctness, and the gap between what the repo describes and what is deployed.

**Angle** — silent disablement. A variable with an empty default turns a feature
off instead of failing the run; a `when:` on an absent variable skips tasks
without a word; `failed_when: false` swallows a real error; a `creates:` guard
makes a settings change inert. Hunt the pattern, not the instance.

**A specific check that pays** — compare the *set of keys* the operator actually
sets against the set the roles consume, in both directions. A key that no role
reads is a dead knob; a key a role needs that the example file omits means a
rebuild from that example would silently skip whatever it guards. Argument
specs do not catch either: validation ignores surplus variables.

**Constraint** — the operator's overrides are vault-encrypted and there is no
password file. Never ask for the passphrase and never run a playbook, not even
in check mode. Work from the example file and the deployed result.

---

## project-manager

**Scope** — documentary coherence: does what the repo *asserts* match what is
deployed?

**Angle** — this is the one domain where drift is directly measurable, and it
widens with every deploy. Compare running containers against the tables in the
docs, deployed versions against cited ones, runbook paths and commands against
what exists on the hosts, and relative markdown links against the tree.

**Calibration** — rank by the cost of the error on the day someone relies on it.
A wrong runbook during a restore is expensive; a stale version table is not.
Ignore style and wording entirely: report only what could *mislead* someone
during an incident.

**The 20 service pages are ENUMERATED** as of 2026-08-22, three axes each (does
the page agree with its ADR, its runbook, its container?). Eleven were clean;
the other nine produced fourteen corrections, shipped in #203. Re-check after a
change rather than re-exploring — but two shapes are worth carrying forward.
First, `docs/05-services/*.md` was the set every previous sweep forgot: seven of
the ten findings were corrections that reached the ADR and/or the runbook and
stopped before the service page. Second, an **enumeration that puts a watched
thing next to an unwatched one reads as coverage** — that is how a CPU
temperature nobody thresholded survived in a sentence listing three things the
check "watches" (#201), and the same sentence existed in a second runbook that
only a sibling sweep found.

**A worked example to calibrate against** — an ADR once promised that a job's
carried-over count would appear in its monitoring message. It never had, because
the push mechanism was broken from the start. Nobody had noticed, because nobody
confronts what an ADR claims with what the system does. That is the class of
finding worth hunting.

**Note** — the real domain is deliberately masked as `example.com` throughout
the public repo. That is not an inconsistency; do not report it.
