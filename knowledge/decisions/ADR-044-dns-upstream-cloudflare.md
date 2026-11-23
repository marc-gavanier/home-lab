# ADR-044 — DNS upstream moves from Quad9 to Cloudflare 1.1.1.2

**Date**: 2026-11-23
**Status**: accepted — supersedes the provider choice of ADR-015; the DoH sidecar design is unchanged

## Context

Quad9 stops serving users located in France on 2026-11-24 ("Farewell, France", quad9.net,
2026-10-22), after refusing a Paris court order to block streaming domains. Its post does not
say how French users are identified nor what they will receive, so the Pi's French residential
IP must be assumed cut off. Both dnsproxy upstreams were Quad9 with no fallback (ADR-015): the
cut-off would leave Pi-hole with no working upstream for every LAN and VPN client.

## Decision

dnsproxy forwards to Cloudflare's malware-blocking resolver over DoH, addressed by IP:
`https://1.1.1.2/dns-query` and `https://1.0.0.2/dns-query`, in load-balance as before.

- `1.1.1.2` keeps what Quad9 provided: malware blocking and DNSSEC validation.
- The certificate served on both addresses carries `1.1.1.2` and `1.0.0.2` as IP SANs
  (checked 2026-11-23), so the IP form keeps a verified TLS connection and needs no bootstrap
  lookup.
- One provider, no fallback, for the reason given in ADR-015.

## Consequences

- Cloudflare sees the queries instead of Quad9. The domain is already on Cloudflare (DNS-01,
  DDNS), so no new third party is added.
- Cloudflare faces the same kind of blocking orders (Belgium, early 2027; a French attempt by
  Canal+ was refused in 2026). If it complies or withdraws, the upstream has to change again;
  the change is the two `-u` lines in `docker/compose.yaml`.

## Alternatives considered

- **Cloudflare `1.1.1.1`** (no filtering) — drops the malware blocking Quad9 gave. Rejected.
- **Google, DNS4EU** — apply the French blocking orders. Rejected.
