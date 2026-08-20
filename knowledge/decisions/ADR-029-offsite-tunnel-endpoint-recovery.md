# ADR-029 — The offsite tunnel recovers from a home IP change, and why not by restarting it

**Date**: 2026-08-20
**Status**: accepted — implemented, pending the deliberate-break test

## Context

The offsite Pi (ADR-010) dials home over WireGuard. Its peer configuration names a
hostname, and `wg-quick` resolves that name **once**, at `up`. The kernel then holds
the resulting address indefinitely. `PersistentKeepalive` does not help — it re-sends
to the same stale address.

The home connection has a dynamic public IPv4. DDNS keeps `vpn.<domain>` pointing at
the current one, and that side works. Nothing told the offsite kernel to look again.

The 2026-08-19 audit found this as a **partition**, not a degradation:

- the offsite backup copy stops, which is that host's only purpose;
- SSH to it runs **through that tunnel**, so remote repair is impossible;
- recovery requires someone physically at the machine.

Detection already worked — the push monitors go quiet and the dead-man's switch fires.
Recovery did not exist.

### What was measured before choosing

**The trigger has never fired.** The audit reported "1239 DDNS runs unchanged", but
that was a bound on the *journal*, which only reaches back 13 days. Cloudflare's own
record answers properly: `created_on == modified_on == 2026-07-19T23:12:06Z`. The A
record has never been modified since creation — 32 days, and a lower bound obtained
from the right instrument.

That is an argument about probability, not about cost. The cost is a trip, and it is
the same trip whether it happens next month or next year.

**The tunnel is split, which is what makes any fix possible.** The offsite host's
resolver is its own LAN router on `eth0`, and its default route is `eth0`; the tunnel
carries the homelab VPN subnet and nothing else. So name resolution does **not** depend
on the tunnel being repaired. Had this been a full-tunnel client, no re-resolution
scheme could work at all and only option C below would have remained.

**The handshake age is a sawtooth with a structural ceiling.** 60 samples at 5-second
intervals on 2026-08-20: p50 55s, p90 112s, max 122s, never above 135s. That ceiling is
WireGuard's ~120s renegotiation plus establishment time, not a random variable that
could drift upward.

## Decision

**Re-resolve the name when the handshake goes stale.** `offsite-wg-reresolve.timer`
runs every minute; the script does nothing while the last handshake is under **150s**,
and otherwise hands the *name* to `wg set`.

Threshold: 150s sits 28s above the measured ceiling of 122s. A spurious fire costs
nothing — it rewrites the same address on an existing peer, with no interface change —
so the margin is chosen for a quiet journal, not for safety. Recovery is bounded at
one timer period plus the gate: under four minutes.

Two properties make this acceptable on a host nobody can reach:

- **It fires on the handshake, not on a clock.** A working tunnel is never touched.
  The mechanism only acts when the tunnel is *already* dead, so it cannot be the cause
  of an outage it then has to fix.
- **It fails closed by construction.** The name goes to `wg set`, which resolves it
  itself. A resolution failure makes `wg set` fail and `set -e` aborts. There is no
  path in the script that clears an endpoint.

### Why not restart the tunnel

The alternative was a watchdog restarting `wg-quick@wg0` past a handshake threshold —
the shape already used elsewhere in this repo, and it catches more than a stale address.

It was rejected because **the trigger is identical**. Both designs read the same signal:
handshake age. They differ only in the action. `wg set` writes one field on a live
interface; a restart tears the interface down and builds it back up, on the one host
where a failed `up` cannot be undone remotely. The heavier action buys nothing the
lighter one does not already catch, and a threshold set too low would turn an upstream
hiccup into a self-inflicted flap.

### Why not detection only

Adding the handshake age to the health report and accepting the trip was a legitimate
option, and part of it was kept regardless: the offsite health message now carries the
age. But that message travels *through* the tunnel, so it can only describe a tunnel
that is alive — one that needed repairing, or one whose handshake is ageing. A tunnel
that is truly down is still read from silence, by the dead-man's switch. Detection
alone would have left the failure mode ending in a trip.

### Why our own script rather than the upstream one

`wireguard-tools` ships `reresolve-dns.sh` (GPL-2.0, by WireGuard's author) as a
documentation example, and it is present on the host. The design above is taken
directly from it, including the handshake gate and the delegate-resolution-to-`wg`
property — that design is the contribution, and it is public.

The code is not reused, for two practical reasons rather than legal ones. Most of that
script is a configuration-file parser handling any number of peers; this host has one,
at a known path, so the parser disappears and what remains is three lines. And a file
under `/usr/share/doc/` is an example, not an interface — a package update may move or
drop it. Vendoring it would also have made it the repository's first third-party file
under an explicit licence, in a repository that declares none.

## The break test invalidated itself, and that is the finding

Run on the live tunnel at 2026-08-20 23:54, with an unattended rollback armed first.
The endpoint was forced to 192.0.2.1 (TEST-NET-1, unroutable) and the tunnel recovered
in **under ten seconds** — but not by this mechanism.

```
23:54:14  endpoint forced to 192.0.2.1        (handshake 117s)
23:54:24  endpoint ALREADY back to the real address, handshake still 117s -> 127s
23:54:34  new handshake completed (age 10s)
```

The middle line is decisive: the address was corrected **without a new handshake**, and
the re-resolve journal is silent — its 150s gate was never reached, so it could not and
did not act.

What repaired it is WireGuard's **roaming**: a peer adopts the source address of any
authenticated packet it receives. `wg-easy` sets no `PersistentKeepalive` toward its
clients, but the homelab had traffic for the offsite peer and initiated a rekey to the
endpoint it still knew — the parents' public address and NAT-mapped port, unchanged and
still valid. The offsite host authenticated that packet and adopted its source.

**The test exercised the wrong scenario.** Breaking the endpoint while the home address
stays put is exactly the case roaming covers. In the real failure the home address has
*changed*, so the homelab's packets reach the parents' NAT from a source it has never
seen. Consumer NATs commonly filter inbound by source address or address+port, in which
case those packets are dropped, no roaming occurs, and this mechanism is the only
recovery left. If that NAT is endpoint-independent instead, roaming already covers the
failure and this timer is a belt over braces.

**The protocol's own documentation answers it, and the answer is no.** Three independent
sources agree that roaming does not recover a server address change when the client is
behind NAT:

- The WireGuard mailing list, on exactly this question: a changed server cannot reach the
  client, "it needs client to initial the connection", and `PersistentKeepalive` does not
  help. The thread points at the reresolve script as the mechanism to build.
- Pro Custodibus, stating the condition explicitly: recovery would require "the endpoint
  proactively initiates a connection to the client from its new IP address (which NAT or
  other firewall rules make impossible in a typical client-server scenario)".
- The unofficial WireGuard docs: roaming learns from authenticated packets, but "DNS
  hostnames are not continuously polled in the background", so proactive refresh needs
  external tooling.

The mechanics behind that agreement: the parents' NAT holds a mapping created by the
offsite host's outbound traffic to the OLD home address. When packets arrive from the NEW
one, address-dependent or address-and-port-dependent filtering drops them — the internal
host has never sent anything there. Per RFC 4787 those filtering behaviours are the common
consumer case; endpoint-independent filtering combined with endpoint-independent mapping,
the one arrangement that would let roaming through, is rare in practice.

So the direction of repair matters, and only one direction is available. The offsite host
must send *first*, to the new address, which both reaches the peer and opens the NAT
mapping for the return path. Re-resolving the name is what makes it send there. That is
why this fix does not depend on the parents' NAT at all: it works under any filtering
behaviour, because it never asks the NAT to accept an unsolicited source.

**This mechanism is therefore load-bearing, not redundant**, and the audit's premise was
right. What the break test proved is narrower than intended but not nothing: the fail-safe
paths hold on a live interface, and roaming covers the sub-case where the home address is
unchanged. The target failure mode remains unexercised — reproducing it needs a home
address change or a test rig that suppresses roaming.

## Consequences

- A home IP change now costs under four minutes of tunnel downtime instead of a trip.
- One more timer on the offsite host, firing every minute and doing nothing almost
  always.
- The failure mode moves rather than disappearing: if the name itself cannot be
  resolved — DNS broken at the parents' site, or the record deleted — the mechanism
  correctly refuses to act, the tunnel stays down, and the trip is back on the table.
  That residual case is what the health report's handshake age is for.
- **Not yet trusted.** Deployed, idempotent, and proven on a scratch interface across
  four cases including the fail-closed one. The live break test recovered in under ten
  seconds but by roaming, not by this timer, so the target failure mode is still
  unexercised. See the section above for the test that would settle it.
- **The question this opened is closed.** Roaming does not recover a home-address change
  for a client behind NAT — upstream says so, and RFC 4787 explains why the common
  consumer filtering behaviours drop the packets that would carry it. The exposure the
  audit described was real, and this timer carries it.
