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

As of the SECOND run of 2026-09-19, key `commensurability`. **Rebuilt from
`classes.md`'s OPEN table — do not trust this copy if the two disagree.**

**ONE OPEN CLASS. The counter went 5 -> 1 and the class total did not move.**

| Class | Owner | What is left to do |
|---|---|---|
| C44 | `services` + `ansible-deploy` | the deploy-tag sub-space is CLOSED 26/26 by two independent derivations — do not re-derive it. What is left is the third cadence slice, named and unswept: assertions whose artefact is rewritten by an EXTERNAL writer, `unattended-upgrades` on `/usr/lib/sysctl.d` being the named case. Neither a timer nor a tag, so it belongs to `system` or `security` as much as to either current owner |

**Seven domains own no OPEN class, and that is the normal state now.** Their job is
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

**C03-T IS NO LONGER RED ON ITS NAMED DEFECT — read this before quoting the
register's older text.** Both clauses of the deployed `/etc/goss/posture.yaml`
carry `h.status = 1` (`:3240`, `:3255`), verified independently. Two residuals are
genuinely open: it has never completed a green SCHEDULED run, and a live reporter
pushing a genuine failure is still indistinguishable from a mute one — the
fail-safe direction.

**Three classes sit ENUMERATED with live instances** — verify the instances are
gone, do not re-derive the classes. **C98**: still the same 2 of 4 (`$BEFORE_ASSETS`
and the unguarded `compose.yaml.bak`, read back as authoritative at runbook:369).
**C99**: unchanged, 31 sites, transmission's value-keyed `lineinfile`, 0 live
duplicates. **C100**: the fix is deployed and the provenance half is PROVEN — the
beat says `manual run` verbatim — but it has still never been exercised by a
SCHEDULED posture run.

**Do not re-derive**: C20 (43/43 by value), C103 (37/37), C105 (28/28), C01's
instruction-file stratum (123/123), C88's three slices, C37, C90, C94, C95, and
C44's deploy-tag sub-space (26/26).

**Rows corrected in the second 2026-09-19 run; do not re-derive them.** C15's
cadence is DAILY, not weekly. C44's deploy-assertion cardinal is 26, not 12. C105's
inverse cardinal is 12, not 11. C20's cardinal is 43 by value — 16, 15 and 59 were
three different bounds and 59 is not reproducible.

**The baseline is part of the brief, and two of its entries are traps every time.**
A never-run unit reports `Result=success`, and so does a unit that DOES NOT EXIST
(`LoadState=not-found`, exit 0, measured) — so `Result` alone can never say whether
something ran; read `ExecMainStartTimestamp` beside it. And before quoting a
monitor's colour, ask when its last SCHEDULED execution was and what THAT one
reported: the posture monitor has now been green by a hand-run on two consecutive
audit nights.

**Twenty-one keys are now spent**: `time`, `order`, `identity`, `scale`,
`authority`, `representation`, `vacuity`, `exclusivity`, `interruption`,
`succession`, `residue`, `concurrency`, `plurality`, `dependency`, `granularity`,
`locality`, `repetition`, `reversibility`, `quiescence`, `collision`,
`commensurability`. The mint rate reads 5, 11, 12, 7, 2, 4, 1, 0, 2, 1, 2, 2, 3, 1,
0, 2, 2, 1, 2, 4, **0**. A run that reuses one proves nothing.
**`commensurability` had been proposed and passed over FOUR times as probably
already covered, and it turned out to be exactly that** — which is evidence the
register is approaching completeness, not evidence against inventing keys.
**This is the first of the two consecutive zero-mint runs the termination criterion
needs; the next key decides.** Still proposed and unspent: `staleness` (what is the
maximum age of the value this decision rests on, and what bounds it? — overlaps
C39, C44 and C76, stated when it was proposed), `asymmetry` and `cost`. The register
records that `cost` shares `scale`'s weakness: little of it leaves a trace you can
measure tonight.

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
