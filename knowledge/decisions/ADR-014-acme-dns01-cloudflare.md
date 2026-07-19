# ADR-014 — ACME certificates via Cloudflare DNS-01 (per-host, no wildcard)

**Date**: 2026-07-20
**Status**: accepted (deployment pending on-Pi validation)

## Context

Traefik issued Let's Encrypt certificates via the **HTTP-01** challenge: LE must
reach `http://<host>.gavanier.com/.well-known/...` from the internet. That
structurally couples "can this host get a certificate" to "is this host publicly
reachable on :80", which fights the vpn-only posture (ADR-002):

- **Every** service subdomain (`drive`, `vault`, `photos`, `videos`, …) needs a
  **public A record** pointing at the home IP, purely so ACME can validate. So
  `dig vault.gavanier.com` publicly reveals the home IP and the service list,
  and **:80** is open to the internet for scanners — even though access itself is
  gated (`vpn-only` → 403). It is not an access hole, but unnecessary public
  footprint and information disclosure.
- The Traefik **dashboard** host (`proxy.gavanier.com`) had no public A record,
  so HTTP-01 could not validate it → it served no valid certificate and (absent
  a Pi-hole split-DNS entry) was unresolvable internally too — routed but dead.
- Adding an internal-only service forces publishing a public A record just to get
  a cert — easy to forget, and it grows the public surface every time.

## Decision

Switch the ACME resolver to the **DNS-01 challenge via Cloudflare** (already the
DNS provider). Traefik proves control by writing `_acme-challenge` **TXT**
records through the Cloudflare API, needing no inbound HTTP and no public A
record. A **scoped API token** (Zone:DNS:Edit + Zone:Read, single zone
`gavanier.com`) is stored in the LUKS secrets set (ADR-011) and passed to the
Traefik container as `CF_DNS_API_TOKEN`.

**Per-host certificates, deliberately NOT a `*.gavanier.com` wildcard.** Each
router keeps its own `certresolver`, so DNS-01 issues one single-host cert per
homelab service. A wildcard was rejected: it would be a single private key valid
for **every** subdomain — including ones served by other providers
(`marc.gavanier.com` is GitHub Pages) and any future one — so a compromise of the
Pi would threaten domains the homelab does not even serve. Per-host certs cover
exactly the homelab hosts and nothing else.

## Consequences

**Positive**
- Service subdomains no longer need a public A record for certificates → the
  public A records can be removed (keep only `vpn.gavanier.com`, needed to
  bootstrap the tunnel) → the homelab **disappears from public DNS**.
- Port **80** is no longer needed for ACME → the ISP router forward can drop to
  `443` + `51820/udp` (or just `51820/udp`, since all legitimate 443 access is
  via the tunnel). The `web` entrypoint stays only for the internal http→https
  redirect over VPN.
- The dashboard (`proxy.gavanier.com`) now gets a valid cert, and a split-DNS
  entry makes it resolvable over VPN.
- Cert issuance is decoupled from public exposure — an internal-only service can
  get a trusted cert without ever being published.

**Negative / cost**
- A Cloudflare API token now lives in the secrets set. Blast radius is bounded:
  it can edit DNS records **only** in the `gavanier.com` zone (no account-wide
  scope). It is treated like the other LUKS-stored secrets (ADR-011).
- Per-host certs mean N ACME orders instead of one (well under LE rate limits),
  and Cloudflare becomes a dependency for renewal.

**Migration (low risk)**
- Existing HTTP-01 certs stay valid — Let's Encrypt does not care which challenge
  issued them. Traefik does **not** reissue immediately; it renews each cert via
  DNS-01 as it nears expiry. No self-signed window for existing services. The one
  cert obtained fresh is the dashboard's — the validation signal that DNS-01
  works.
- Removing the public A records and closing the :80 forward is a follow-on the
  operator does once confident (a security-domain decision; not automated here).

## Alternatives considered

- **Keep HTTP-01, add the missing A records** (`proxy`, …): perpetuates the
  coupling and grows the public footprint. Rejected.
- **`*.gavanier.com` wildcard via DNS-01**: one cert for all, but one private key
  valid for subdomains served elsewhere (GitHub) and for domains the homelab does
  not serve. Rejected on blast-radius grounds.
- **DNS-01 with another provider / self-hosted**: Cloudflare is already the
  authoritative DNS, so no new dependency beyond the scoped token.

## Related

ADR-002 (vpn-only exposure), ADR-011 (secrets off the SD card on LUKS),
issue #12 (network hardening backlog), `docs/04-network/`.
