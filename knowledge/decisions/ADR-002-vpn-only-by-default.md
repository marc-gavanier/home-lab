# ADR-002: VPN-only Access by Default for All Services

**Date**: 2026-05-15
**Status**: Accepted
**Deciders**: Marc Gavanier

## Context

Initial design exposed some services (Nextcloud, Vaultwarden, Jellyfin, Navidrome, Immich, HedgeDoc) publicly via Traefik, with only admin panels (Pi-hole, Netdata, Uptime Kuma, WireGuard UI) gated behind VPN.

Exposing services publicly meant:
- Each service is a potential entry point if a CVE is found in its codebase
- Internet bots could enumerate the services (via subdomain scanning, banner grabbing)
- Bots could attempt credential stuffing, vulnerability scans, DoS
- Defense relies entirely on each service's own auth + the user keeping every service patched

## Decision

Apply the `vpn-only` middleware globally on Traefik's `websecure` entrypoint. All HTTPS services now require a request from:
- LAN (`192.168.1.0/24`)
- WireGuard VPN (`10.8.0.0/24`)
- Docker bridge networks (`172.16.0.0/12`)

Anything else gets `403 Forbidden`.

## Consequences

### Pros
- **Minimized attack surface**: only WireGuard (51820/UDP) and Traefik HTTP/HTTPS (80, 443) are exposed to the internet; HTTPS rejects every non-VPN/LAN request
- **CVE protection**: a future vulnerability in Nextcloud/Vaultwarden/etc. can only be exploited by an authenticated VPN client (defense in depth)
- **No enumeration**: bots scanning the public IP get `403`, can't discover what services are hosted
- **Secure by default**: every new service added to compose inherits the protection — no risk of forgetting the middleware on a new router

### Cons
- **VPN must be active on mobile** for Bitwarden/Nextcloud/Immich sync to work from cellular networks. WireGuard's always-on connection is lightweight but adds slight battery drain
- **No third-party integrations**: services that need to call back to the homelab from the public internet (webhooks, OAuth callbacks) won't work
- **Exposing a service later**: requires removing the global middleware and adding it per-router on the others, then explicitly leaving it off on the public one

### ACME / Let's Encrypt
HTTP-01 challenges go to `/.well-known/acme-challenge/*` on port 80, handled by Traefik's ACME resolver **before** middlewares. Certificate renewal continues to work despite the global middleware.

## Alternatives Considered

- **Per-router middleware**: explicit on each service. More verbose, easier to forget, but allows per-service exceptions. Rejected because the homelab has no service that should be public.
- **Cloudflare Tunnel + Cloudflare Access**: cloud-based auth proxy. Rejected because it cedes control to Cloudflare and contradicts the sovereignty goal.
- **mTLS client certificates**: very strong but heavy to deploy on mobile and impractical for browser access. Rejected.