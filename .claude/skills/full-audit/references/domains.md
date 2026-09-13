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

As of the run of 2026-09-13 (late evening), key `repetition`. **Rebuilt from
`classes.md`'s OPEN table — do not trust this copy if the two disagree.**

**FOUR OPEN classes, after a run whose job was to come back empty.** Ownership:

| Class | Owner(s) | What closing it needs |
|---|---|---|
| **C37** (REOPENED) — a WAL-mode SQLite copied without its `-wal` | `backup`, with `project-manager` on the runbook slice | A space bounded by the PROPERTY — every place a `.db` is copied or read — not by the dump mechanism. The 08-29 sweep's bound is what let a runbook instance sit outside it |
| **C88** (REOPENED off its file axis) — a store that adds with no counterpart removing what its register no longer names | `services` (image store), `security` (ufw rule set), `ansible-deploy` (the original file axis) | A bound over STORES, not over rendered files. Two domains reached the property independently in non-file stores |
| **C98** (minted ENUMERATED) — a repeated procedure reuses a fixed, run-invariant NAME for the artefact it later reads back as authoritative | `project-manager` (8 reference points) + `backup` (12 workspaces) | Already swept on both slices. It is ENUMERATED, not GATED — nothing continuously derives the (procedure, artefact-name) relation, so a new runbook reopens it |
| **C99** (minted ENUMERATED) — a declarative in-place write keyed on the VALUE it writes rather than the record's IDENTITY | `ansible-deploy` | Swept 31/31, 4 defective, 0 live. ENUMERATED, not GATED: nothing asserts that an in-place write carries an identity key |

**ONE GATE IS RED, and it is the one promoted the same day.** **C03-T** cannot
detect a mute reporter: Kuma fabricates a DOWN beat every interval for any push
monitor that is not UP, and C03-T's clauses count `heartbeat` rows with no
`status` filter. Verified live — 39 fabricated rows on 09-13, all `status=0`.
`observability` owns the repair and the predicate is `h.status = 1`, **not** a
match on the upstream English string. Do not re-derive this; read the run section.

**The standing structural gap that is not a class, re-confirmed exactly**:
`offsite.yml` plays `base`, `security` and `offsite-backup` only, so `/etc/goss`
on the offsite holds ONE spec against three on homelab. Every fix that must cross
hosts is unverified there by construction. It has never been arbitrated — do not
propose it as a finding.

**Rows corrected this run; do not re-derive them.** C12's "no live assertion at
all" is FALSE since #333 and the class is a candidate for re-promotion to GATED.
C14 is 21/21, not 18/18, and its "silent ACME failure" half is a proxy that
cannot see a name which never obtains a certificate. C19's derived floor is at
`homelab-health.sh:665`. C21's description is stale for the third time — there is
no retention monitor. C11's 2026-09-05 "BROKEN" verdict has now been refuted
three times; retire the comparison.

**Template-vs-deployed was verified clean in both directions over 317 assertion
names and 4 specs.** Every "derived" verdict in `classes.md` that rests on a goss
template is safe. Do not re-check without a new symptom.

**Seventeen keys are now spent**: `time`, `order`, `identity`, `scale`,
`authority`, `representation`, `vacuity`, `exclusivity`, `interruption`,
`succession`, `residue`, `concurrency`, `plurality`, `dependency`,
`granularity`, `locality`, `repetition`. The mint rate reads 5, 11, 12, 7, 2, 4,
1, 0, 2, 1, 2, 2, 3, 1, 0, 2, **2**. A run that reuses one proves nothing.
**Two were proposed to the operator and not spent — `commensurability` (are both
sides of this comparison in the same unit, base and reference frame?) and
`reversibility` (does this mechanism have an inverse, and does the inverse
restore the prior state?). Both are still available and both arrived with three
unclassed precedents each.** The keys that paid best
were found the same way: look for an instrument trap in `settled.md` that no
class has adopted, or a pair of narrow classes in `classes.md` that are
obviously two faces of a dimension nobody named.

**What `repetition` proved, for whoever writes key eighteen.** It was the first
key whose risk was stated to the operator BEFORE it was chosen, and the warning
held exactly: Ansible idempotence is swept ground, and not one of the run's four
register moves came from it. The key paid where a repeat is NOT the
well-understood question — runbooks a human follows twice, a staging directory
read back as authoritative, a store with no reaper. **Its sharpest finding was
not an instance of itself**: the gate deployed that same afternoon was blind
because its fail-on-purpose proof ran against a synthetic database. The general
lesson is in `settled.md` and it outranks the key — *a gate proven against a
fixture is proven against the fixture's model of the world.*

**What `locality` proved, for whoever writes key seventeen.** It paid twice at
the meta level, and both payments are instructive. The main session's own
instrument hit the key's property twice while hunting it — a root `mountpoint`
on a uid-private FUSE mount, and a probe run from a container that lacked the
binary. And the key's sharpest finding inverted its own first fix: the SSH rule
looked like it needed widening and needed nothing, because the correct path
already existed one address over. **A key that catches the people using it is a
key with territory left.** `locality` is spent as a key, but C96 and C97 are
both ENUMERATED rather than GATED, so its findings can come back.

**What `dependency` proved, for whoever writes key fifteen.** Its premise check
paid twice over — once by confirming the key had territory, and once by being
WRONG in a way that cost eight briefs. The lead it produced
(`homelab-ddns.service` lacking a mount guard) came from
`systemctl show -p ConditionPathExists`, which returns empty on this systemd
version even when the unit declares it. Four domains refuted it. **Verify the
premise with a positive control, and verify the LEAD the same way** — a null
result from an unproven instrument is not a lead, and this one propagated to
every agent.

**Invent the key first, write it into the brief, and send the agents after it.**

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
