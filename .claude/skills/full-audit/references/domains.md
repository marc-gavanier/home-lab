# Domain mandates

One entry per agent. Each gives the scope, the angle that actually pays, and the
state already established so the agent does not spend its budget rediscovering
it. Update the "already established" lines after each run — they are what keeps
successive audits from repeating themselves.

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
guarded by `creates:` is not resized by changing its size variable.

---

## security

**Scope** — hardening, firewall, fail2ban, SSH, secret handling, exposure
surface, physical security.

**Angle** — what has been deployed *since the last audit* and has therefore
never been reviewed. Each new service is a chance for the established posture to
erode quietly. Also read the posture-check script for what it does **not**
assert: the gaps in an automated check are where drift accumulates.

**Calibration** — this is a home lab, not a bank. Rank by realistic attack
scenario. A latent weakness that costs one line now and a full re-enrolment
later is worth raising; a theoretical one that costs a weekend is not.

**Already established** — see `references/settled.md` for the container-layer
work that is closed and the hardening proposals that have been declined.

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
`mode=ro`, and never write a test heartbeat during an audit. Its timestamps are
UTC while the hosts are local time.

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

**A worked example to calibrate against** — an ADR once promised that a job's
carried-over count would appear in its monitoring message. It never had, because
the push mechanism was broken from the start. Nobody had noticed, because nobody
confronts what an ADR claims with what the system does. That is the class of
finding worth hunting.

**Note** — the real domain is deliberately masked as `example.com` throughout
the public repo. That is not an inconsistency; do not report it.
