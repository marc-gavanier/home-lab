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

As of the TWELFTH run of 2026-09-21, key `durability`. **Rebuilt from
`classes.md`'s OPEN table — do not trust this copy if the two disagree.**

**THREE OPEN CLASSES, and here is the whole membership with its owner:**

| Class | Property | Owner | What is left |
|---|---|---|---|
| C121 | A token whose validity ends with an event, kept on a medium that outlives it, with nothing to expire it | **unassigned — pick by the EVENT, not by the domain** | MINTED 2026-09-21. Mirror of C39. `backup` swept its own plane 7/7 (4 correct, 3 defective, all the same file) and that is a DOMAIN bound. The route: enumerate by the event that ends a token's meaning — boot, container recreation, service restart, deploy — and ask which stores survive it. The mechanism is measured: `/var/lock` is a real directory on BOTH hosts, not the tmpfiles symlink to `/run/lock`, so anything written there is persistent on an image that reads as volatile |
| C34 | A documentary artefact contradicting the sibling it cites | `project-manager` | Axes A (44/44), B (1/1), D (23/23) closed; axis C bounded by the property (467 occurrences, 333 relations, 79 referents, 84 citing documents), 110/110 links and 69/69 glosses swept, 40 more claims opened individually on 2026-09-21. **What blocks it is bookkeeping, not reading: the "~48 never opened" residual was recorded WITHOUT its membership, so the overlap with this run's 40 is unknown and the remainder is between 8 and 48. The next run to measure it must publish the LIST** |
| C01 | A documentary statement whose content contradicts the deployed artefact | `project-manager`, with every domain feeding it | 198 tracked files carrying comments, 13 757 comment lines, 11 666 prose statements. Swept: `ansible/` 176/176, `docker/` 10/10, `ops/` 156/156, `usb-tamper`+`killswitch` 121/121, instruction files 123/123, **the RENDERED stratum 53/53 (2026-09-21)** and **the `durability` slice of `docs/`+`knowledge/` 24/24**. What remains is the rest of the documentary prose |

**C119 and C120 both LEFT the OPEN column on 2026-09-21 — do not re-derive
either.** C119: seven planes of seven, the last being `ansible-deploy`'s 31/31
(spec, artefact) pairs; 30 of 31 rendered detectors can be turned green by
rewriting the detector rather than the guarded thing, exactly 1 cannot. C120:
the "rupture already on record" route swept in six domains — `system` 33/33
systemd limiters + 18/18 other guards, `security` 21/21, `network` 35/35,
`observability` 82/82, `services` 129/129, `backup` 28/28 — with the
provoked-measurement residual declared (70 guards in `services`, 22 monitor
timeouts in `observability`). Neither is GATED: no assertion was made to fail
on purpose.

**THE PREDICATE, and it is reusable — carry it into every future brief.**
`(Burst-1) x RestartSec >= Interval`, or `Interval=0`, means a systemd unit can
NEVER reach `failed`: the burst counter resets between attempts. It decides the
question from two DECLARED numbers, read-only, without provoking anything. This
is what retired C120's "16 units UNDETERMINED" blocker. The repo writes the rule
exactly once, at `ansible/roles/stack-startup/tasks/startup.yml:57-63`.
`StartLimitIntervalSec` belongs in `[Unit]`; systemd silently ignores it in
`[Service]`, and the main session made that mistake on 2026-09-21.

**A BOUND ON THIS AUDIT'S OWN INSTRUMENTS, established 2026-09-21 and more
important than any finding it produced.** netdata's alarm TRANSITION history
retained `5d` by default (raised to `60d` the same day, with in-memory entries
1 000 -> 5 000), while its METRIC store retains 55 days. The swap guard's own
rupture — 94.55 % measured against an 85 % threshold, 2026-08-31 to 09-02 —
left no retained transition, shown with a positive control. **So "this guard has
never tripped", answered from the alarm log, is a false negative beyond a few
days. Answer it from the metric RANGE instead.** C120's closure was written to
rest on metric ranges for exactly this reason.

**Do not re-derive what the eleventh run established.** C119's five newly swept
planes and their cardinals; C34's axis C enumeration; C01's file census and the
four clean strata; C120's six slices. And do not re-propose the two remedies the
main session withdrew after measurement: the `/`-widened masking class (it
redacts paths in `sudo.log`, 270 extra lines against 1) and journald as the
redactor's log destination (it is the one store the masking cannot filter).

**C12 LEFT the OPEN column on 2026-09-20 (tenth run)**, ENUMERATED by two
complementary bounds — `security` 76/76 (value, consumer) pairs derived from the
live host, `ansible-deploy` 52/52 render sites derived from the declarations. Do
not re-derive either. The structural defect it left behind — `--tags secrets`
advertised as a rotation route while reaching 19 of 31 renders — is FIXED.

**Do not re-derive what C44 and C113 left behind** (eighth run): C44's 27/27
subsystems and the coverage figure of 1 of 16 TIER A, and C113's two bounds,
`network` 16/16 and `security` 197/197 with only 2 of 197 verifying a refusal.
Both remedies are DECLINED.

**Read `settled.md`'s DECLINED section of 2026-09-20 before writing any brief.**
Five things were arbitrated away that a fresh agent will otherwise rediscover
and propose: alerting-path coupling (never again, in any form), the two restic
passwords, the `ssh_port_hardened: 22` fallback chain, deny-direction assertions
of every kind, and the mtime comparator for C44. Two of those are the most
"findable" defects in the estate, so expect to have to decline them on the
agent's behalf.

**What C44 leaves behind, so nobody re-derives it.** 27/27 subsystems swept.
**Coverage is 1 of 16 TIER A, not the 4 this file carried for a month** —
`sshd -T`, `postconf -h` and `ufw status` all read the declared FILE, not the
executing process; only `sysctl` reads `/proc/sys`. The sshd and postfix cases
are C111 instances. Do not re-derive TIMER 13/13, DEPLOY-TAG 26/26,
HOST-HARDENING 20/20, or the 27 rows.

**What C113 leaves behind.** Two complementary bounds, neither containing the
other: `network` 16/16 mechanisms (3 deny-covered, 4 admit-only, 9 uncovered),
`security` 197/197 deny-subject assertions of 329 (186 fail-safe, 11 stay
green). **Only 2 of 197 verify that a control actually refuses.**

**Six domains own no OPEN class, and that is the normal state now.** Their job is
the one that demoted C02, C13, C20, C26 and C17: re-read the GATED assertions in
their area and ask whether each is DERIVED from the thing it guards or is merely a
list of the instances once found. `backup` did exactly that on 2026-08-31 and again
on 2026-09-19, finding C15's recorded cadence wrong both times.

**NO GATE IS RED — C07 was widened and deployed GREEN on 2026-09-20.** Read this
before quoting the older text, which says it is red and says a cheap route does
not exist. The rule that closed it keys on the PLUGIN, not the context: *no
plugin whose charts feed no curated alarm may collect more samples/s than the
busiest plugin that does*. Both sides derive live — consumers from the `on:`
lines of `health.d`, rates from `/api/v1/charts`. Made to fail on purpose in five
directions including the one that matters (a consumer list containing a cgroup
context returns OK, so the rule is not structurally stuck red), plus a
retroactive positive control on 2026-09-17 that marks `apps.plugin`. It found
`cgroups.plugin` at 1002 samples/s with zero consumers on its first run; set to
5 s. Live: `ok 316`, goss plan 409 -> 410. **The CONTEXT axis really is not a
function — that measurement stands. The claim that there was no cheap route was
true only of that axis**: `netdata.conf` renders `[plugin:X] update every` for 58
sections, 23.9 KB, 0.23 s.

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
C36 is 41 tmpfs not 37, C50's Docker half is 28 not 25, and C24/C38 move 28 to
32. **C22 does NOT move — its space is healthchecks (28 of 32), and 28 was
already right; corrected 2026-09-20.** C40 is the eighth frozen row and reads
26 of 32, not 29/29. C53's row says 34 handlers / 1 flush point; it is 41 / 3. **C21 is an ARGUMENT,
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

**THIRTY-ONE keys are spent, and the number below is COUNTED, not incremented.** The heading read "twenty-eight" and then "twenty-nine" while the list under it held 31 names and the mint sequence held 31 values; the 2026-09-21 session made it worse by adding one to a number instead of counting the list, which is the same mistake the ENUMERATED heading made with its rows. **Count the names.** `durability` was added 2026-09-21 (twelfth run) — invented, 1 mint, and it is the FIFTH confirmation that a key which turns on the INSTRUMENT is worth more than one that only turns on the estate: its best yield was a bound on this audit's own evidence (netdata's alarm transition log at 5 days against 55 days of metrics) and a PREDICATE that retired a blocker the previous run had declared unreachable read-only. It also confirmed the declared-overlap discipline: three domains placed the key's main form inside C39/C68 and refused to mint for it.

**Twenty-EIGHT keys were spent before it.** `interference` was added 2026-09-20 (ninth
run) — invented, 1 mint, and it is the FOURTH confirmation that a key which turns
on the INSTRUMENT is worth more than one that only turns on the estate. Here the
instrument was this skill: it measured that **~79 % of posture runs are caused by
audits and deploys rather than by the timer**, which is the structural cause of
the "the audit's own baseline lied" entry the register has written four times as
if it were bad luck. Whoever writes key twenty-nine should know that the two
candidates put beside it and not chosen are still unspent: **`admission`** (what
does each mechanism do with a subject born after it was written — high risk of
producing C86/C114 instances rather than mints) and **`credulity`** (what does
this believe without checking, because it comes from a party the estate does not
control — overlaps `oracle`'s borrowed-oracle shape and C108/C112/C86).

The older list follows (`independence` added 2026-09-20, eighth
run — 3 mints, all three DECLINED by the operator the same day; `asymmetry` the
seventh run, 3 mints): `time`, `order`, `identity`, `scale`, `authority`,
`representation`, `vacuity`, `exclusivity`, `interruption`, `succession`,
`residue`, `concurrency`, `plurality`, `dependency`, `granularity`, `locality`,
`repetition`, `reversibility`, `quiescence`, `collision`, `commensurability`,
`aggregation`, `staleness`, `attendance`, `oracle`, `asymmetry`,
`independence`, `substitution`, `interference`, `tolerance`, `durability`. The
mint rate reads 5, 11, 12, 7, 2, 4, 1, 0, 2, 1, 2, 2, 3, 1,
0, 2, 2, 1, 2, 4, 0, 1, 1, 2, 2, 3, 3, 0, 1, 1, **1**. **It is no longer
decaying**: 4.5 per run over the first ten keys, 1.7 over the next eleven, 1.5
over the last ten, and the last ten read 1, 1, 2, 2, 3, 3, 0, 1, 1, 1 — a
plateau, not a descent. A run that reuses a key still proves nothing.

**The mint rate NO LONGER DECIDES ANYTHING — the rule changed on 2026-09-21.**
Zero-mint runs are an observation about this register's vocabulary, not a
clock. What changes the audit's cadence is the SEVERITY FLOOR: two consecutive
runs, different keys, finding nothing that would have cost DATA, AVAILABILITY
or a SECRET. `classes.md` holds the rule, the definitions of the three costs,
and the arithmetic that retired both previous rules — the zero-mint one (4 in
31, never consecutive, 25-70 runs of expected wait) and the detection-ratio one
(0 in 31, strictly harder, withdrawn by the operator within the hour).

**Every brief must now ask each agent for TWO lines per live defect**: its cost
if nobody had found it (DATA / AVAILABILITY / SECRET / below the floor), and
which deployed instrument would have caught it with what differing output. The
second is the detection ratio, kept as an indicator: the twelfth run scored
0 of 6, and that number is what revealed that **thirteen runs gated nothing** —
14 assertions deployed, only 4 ever made to fail on purpose, zero classes
reaching GATED.

**For whoever writes key thirty.** `durability` was easy to evidence for the
same reason `tolerance` was: every retention is a constant on disk and every
demanded depth is a constant in a spec, so the key reduced to putting two
numbers side by side. Both named candidates remain unspent — **`admission`**
(what does each mechanism do with a subject born after it was written) and
**`credulity`** (what does this believe without checking, because it comes from
a party the estate does not control) — as does `cost`, with its standing
warning. Prefer, again, a dimension whose instances already leave a trace.

**`cost` remains the only named unspent candidate**, and the register's warning
about it stands: it shares `scale`'s weakness, little of it leaving a trace you
can measure tonight, and it overlaps C07 heavily. Key twenty-eight is otherwise
an invention.

**What `independence` proved, for whoever writes key twenty-eight.** It was
invented, and it paid in the estate rather than the instruments — but the
operator declined all three mints, which is a result this register had never
recorded before and should not treat as failure. **The rule it adds: when a
sweep's output is a risk the operator accepts, the register's job changes from
tracking a remedy to preventing the rediscovery.** Two of the three declined
findings (the alerting path, the deny-direction gap) are among the most
findable defects in the estate; every future brief must decline them on the
agent's behalf or waste a domain's budget. It also confirmed, for the fourth
consecutive run, that **the audit's own baseline is the least trustworthy
artefact in the process** — and for the first time it lied in the optimistic
direction's opposite, reporting a gap that did not exist.

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
the page agree with its ADR, its runbook, its container?). **That sweep is NOT
C34's space and this paragraph framed it as such until 2026-09-20** — C34 covers
any artefact citing a sibling, including a code comment, which is what reopened
it. Read the OPEN table above for where C34 actually stands: axis A closed 44/44,
axis C at 33 of 460. **C01 is this domain's other open class**, reopened the same
day because its 81-file space was all `.md` while a comment in an Ansible task is
a documentary statement too. Eleven were clean;
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
