# ADR-040 — Split the security posture from the service checks

**Date**: 2026-10-25
**Status**: accepted
**Related**: ADR-032 (goss posture spec)

## Context

`/etc/goss/posture.yaml` started as the container security posture: capabilities,
read-only root filesystems, AppArmor, the Docker socket. Over the following audits
every new daily assertion went into the same spec, whatever it guarded: netdata
collectors, restic deep-check age, Nextcloud background jobs, Pi-hole gravity,
Miniflux feeds, silent Kuma monitors. By October 2026 fewer than half of its checks
were about security, and all of them reported on one monitor, `Pi security posture`.

On 2026-10-23 Miniflux stopped polling one RSS feed after its site answered 503
fifteen times. `Pi security posture` went red and stayed red: a security regression
in that window would have landed on a monitor already known to be red for a
harmless reason.

## Decision

The spec is split in two, run by the same script and timer, each pushing its own
monitor:

| Spec                     | Template                 | Monitor               |
|--------------------------|--------------------------|-----------------------|
| `/etc/goss/posture.yaml` | `goss-posture.yaml.j2`   | `Pi security posture` |
| `/etc/goss/service.yaml` | `goss-service.yaml.j2`   | `Pi service checks`   |

- **The test for the security side**: does a failure let someone in, or leave a
  secret or a credential open? File modes, hardening, ufw, sshd, sysctl, fail2ban,
  WireGuard peers, Redis authentication, Traefik log redaction, Vaultwarden's
  `config.json`.
- **Two borderline checks stay on the security side**: a container running an
  image its tag no longer designates (a pulled patch not applied), and a rotated
  secret its consumer never received (the old credential still live).
- **The Traefik allowlist checks go to the service side**: they assert that the
  VPN is not locked out, not that strangers are.
- **One timer, one script.** The split changes where a failure is reported, not
  when anything runs, so no unit is added to the offsite parity register.

## Consequences

### Pros

- `Pi security posture` goes red only for a security reason.
- A broken feed, collector or backup check is still reported every day, on a
  monitor that says what it is.

### Cons

- One more push monitor, created by hand in Kuma, and one more vaulted push URL.
- A new daily check has to be filed on one side; the test above decides.
