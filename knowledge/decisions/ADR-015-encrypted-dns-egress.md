# ADR-015 — Encrypted DNS egress via cloudflared DoH (Quad9)

**Date**: 2026-07-20
**Status**: accepted — deployed and validated on the Pi. The **client changed on
2026-07-27** (cloudflared → dnsproxy); the decision itself is unchanged, see the
appended section.

## Context

Two gaps in the DNS path (network audit, issue #12 LATER-1):

- **Cleartext egress.** Pi-hole (FTL, a dnsmasq fork) forwarded upstream queries
  over plain UDP/53 to public resolvers. Every domain the homelab resolves was
  visible to the ISP and any on-path observer. FTL has **no native DoT/DoH**
  (verified — the official Pi-hole v6 does not ship it; only a third-party FTL
  fork does).
- **Config drift.** The upstream resolvers lived in `pihole.toml` on the data
  volume — manual UI state, not reproducible from Ansible, invisible to review.

## Decision

Add a **cloudflared** sidecar (`proxy-dns`) that shares Pi-hole's network
namespace (`network_mode: service:pihole`). Pi-hole forwards to `127.0.0.1#5053`
(which, via the shared netns, is cloudflared), and cloudflared proxies to
**Quad9 over DoH** (`https://dns.quad9.net/dns-query`, RFC 8484, HTTP/2).

The upstream is pinned in `compose.yaml` via `FTLCONF_dns_upstreams:
127.0.0.1#5053` — **version-controlled and FTLCONF-locked** (the web UI can no
longer silently change it, killing the drift).

Pi-hole's role is unchanged: it stays the LAN resolver (ad-blocking, split DNS,
lists, stats). Only the last hop — Pi-hole → internet — is now encrypted.

**Provider: Quad9, no fallback.** Quad9 gives malware blocking + DNSSEC and a
privacy-focused policy. A second DoH upstream was rejected: cloudflared delegates
to CoreDNS's `forward`, whose default policy is `random` — two upstreams means
~50/50, so a fallback provider would see ~half the queries in normal operation,
diluting the privacy choice. cloudflared does not expose CoreDNS's `sequential`
policy, so true primary/failover isn't available without replacing it. Quad9
anycast plus `restart: unless-stopped` is deemed reliable enough.

## Consequences

**Positive**
- **LAN client** DNS egress is encrypted (DoH/HTTP2): anything that resolves
  through Pi-hole leaves this network over HTTPS to Quad9, and the ISP sees no
  domain name for it. That is the traffic this decision was taken for, and it is
  the majority of the lab's queries.
- The upstream is reproducible from Ansible; no more `pihole.toml` drift.
- No new public exposure: cloudflared makes only outbound HTTPS; nothing is
  published.

**Negative / cost**
- **The perimeter is Pi-hole's clients, not the whole machine.** This section
  used to read "no cleartext domain names to the ISP", full stop, which is not
  what the host does. Measured on 2026-08-22 and re-measured on 2026-08-24:

  ```
  /etc/resolv.conf          -> nameserver 1.1.1.1 / 8.8.8.8
  /etc/docker/daemon.json   -> no dns key
  container resolv.conf     -> 127.0.0.11  (28 of 29 — Docker's embedded resolver)
                               the 29th is traefik-log-redactor, on
                               network_mode: none — Docker gives it no embedded
                               resolver and writes the upstreams into the file.
                               It has no socket to resolve THROUGH, so nothing
                               leaves it, in cleartext or otherwise; the
                               conclusion below is untouched. Do not "correct"
                               this to 29 of 29 and assert an embedded resolver
                               for a container that has none.
  ```

  Docker's embedded resolver forwards whatever it cannot answer to the **host's**
  nameservers, so a container looking up an update server, and the host itself
  doing the same for apt or NTP, both leave over plaintext UDP/53. Only a service
  carrying an explicit `dns:` in `compose.yaml` escapes that, and the container's
  own `resolv.conf` does not show the difference — it says `127.0.0.11` either
  way, which is why this went unnoticed for so long.

  Volume is low (one query in 60 s with an empty house), and the amendment is
  deliberate rather than a plan to fix: pointing every container at Pi-hole makes
  Pi-hole a start-order dependency for the whole stack, on a host whose only
  remote path is a tunnel that starts inside that stack. The claim is corrected
  to the perimeter that was actually built; widening the perimeter stays open in
  #219 as a separate decision.
- cloudflared is now on the **critical path** for all external resolution: if it
  is down, Pi-hole has no working upstream. Mitigated by `restart: unless-stopped`
  (Tier 0, same as Pi-hole) — but there is deliberately **no cleartext fallback**
  (it would defeat the encryption).
- Quad9 sees the queries (trusted provider, encrypted transport) — the normal
  DoH trust model.

**No bootstrap loop**
- cloudflared must resolve `dns.quad9.net` once to open the DoH connection. The
  Pi host's `/etc/resolv.conf` uses `1.1.1.1` + `8.8.8.8` (not Pi-hole), and
  Docker's embedded DNS (127.0.0.11) forwards external names to those — so the
  bootstrap never goes through Pi-hole. No loop.

## Alternatives considered

- **Native Pi-hole v6 DoT** — does not exist in the official release. Rejected.
- **unbound (recursive)** — removes the third-party resolver but does its
  recursion to authoritative servers largely in cleartext, so it does **not**
  meet the "encrypt egress" goal. Rejected for this purpose.
- **pihole-dot (third-party FTL fork with native DoT)** — a non-official image;
  supply-chain/maintenance risk against the repo's pin-official-images
  discipline. Rejected.
- **DoH fallback provider** — see above (privacy dilution / no strict failover in
  cloudflared). Rejected.

## Related

ADR-014 (ACME DNS-01), issue #12 (network hardening), `docs/04-network/`.

---

## 2026-07-27 — the client changed, the decision did not (issue #50)

Cloudflare **removed** `proxy-dns` in cloudflared 2026.2.0. The container this
ADR specified did not break — it stopped existing. `2026.7.3` exits immediately
with `dns-proxy feature is no longer supported`, and since this container is
Pi-hole's only upstream, deploying that bump would have taken DNS down for the
whole LAN and every VPN client. Caught by testing the image before deploying it,
not after.

The decision recorded above — encrypted egress to Quad9 over DoH, in a sidecar
sharing Pi-hole's network namespace — is untouched. Only the implementation
moved.

### Candidates, benched under the hardening this stack applies

| Candidate | Starts under `read_only` + `cap_drop: ALL` + `no-new-privileges` | RSS |
|---|---|---|
| **`adguard/dnsproxy`** | yes, with one capability | **6.9 MiB** |
| `cloudflare/cloudflared` (previous) | yes | 14.7 MiB |
| `unbound` (full recursion) | **no** — `unable to set group id`, needs SETUID/SETGID | — |
| `dnscrypt-proxy` | not benched: TOML config plus a downloaded resolver list, a poor fit for a read-only rootfs | — |

Pi-hole's own FTL (v6.7) has no encrypted-upstream option — `dns.upstreams`
accepts `IP#port` only — so removing the sidecar entirely was not available.

### Two details that are not obvious

**One capability, and not for the port.** `cap_drop: ALL` alone makes the
container fail with `exec /opt/dnsproxy/dnsproxy: operation not permitted`. The
binary carries `cap_net_bind_service` as a *file capability*, and such a binary
cannot even be exec'd when the capability is outside the bounding set — the same
mechanism that broke `ping` in uptime-kuma and `pihole-FTL` (ADR-017). It is not
needed to bind `:5053`, which is unprivileged.

**Upstreams by IP, deliberately.** The hostname form works — measured inside
Pi-hole's own namespace, where the only resolver on `127.0.0.1#5053` is the
sidecar itself. But a service that *is* the DNS path should not depend on DNS to
start, and the IP form has nothing to resolve. Quad9's certificate carries IP
SANs, so this is not a downgrade to an unverified connection.

Both forms log occasional `exchange failed ... unexpected EOF` against Quad9 —
an HTTP/2 connection-lifecycle artifact, not a property of either form. Over 30
uncached queries each, the IP form produced **0** client-visible failures and
the hostname form **1**. Two upstreams in load-balance mode exist to absorb
exactly that.

### What the switch cost

A first attempt took DNS down for uncached names: the image was pinned as
`0.83.0` where the registry publishes `v0.83.0`, so `up -d` failed after
cloudflared had already been removed — and the rollback harness's probe passed
anyway, because it queried three names it had just cached itself. Both defects
are fixed in the procedure (`knowledge/runbooks/container-config-changes.md`):
pull the replacement **before** dismantling what works, and probe with a name
that cannot be cached.
