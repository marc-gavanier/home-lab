# ADR-015 — Encrypted DNS egress via cloudflared DoH (Quad9)

**Date**: 2026-07-20
**Status**: accepted (deployment pending on-Pi validation)

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
- DNS egress is encrypted (DoH/HTTP2) — no cleartext domain names to the ISP.
- The upstream is reproducible from Ansible; no more `pihole.toml` drift.
- No new public exposure: cloudflared makes only outbound HTTPS; nothing is
  published.

**Negative / cost**
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
