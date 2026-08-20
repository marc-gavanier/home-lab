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

## Consequences

- A home IP change now costs under four minutes of tunnel downtime instead of a trip.
- One more timer on the offsite host, firing every minute and doing nothing almost
  always.
- The failure mode moves rather than disappearing: if the name itself cannot be
  resolved — DNS broken at the parents' site, or the record deleted — the mechanism
  correctly refuses to act, the tunnel stays down, and the trip is back on the table.
  That residual case is what the health report's handshake age is for.
- **Not yet trusted.** The mechanism is deployed but unproven against the real event.
  It must be exercised by pointing the endpoint at a deliberately wrong address and
  confirming recovery, with an unattended rollback armed first — the test breaks the
  only link to that machine.
