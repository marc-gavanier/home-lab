# ADR-006: Remote Kill Switch via Secret ntfy Message

**Date**: 2026-06-23
**Status**: Accepted
**Deciders**: Marc Gavanier

## Context

The Pi hosts sensitive self-hosted data (Vaultwarden, Nextcloud, Immich, backups).
If the hardware is stolen, or in any situation calling for an immediate remote
shutdown ("panic" off), there must be a way to power it off from anywhere —
**without** opening an inbound port, which would contradict the perimeter rules
(only 80/443 and 51820/udp exposed, see [ADR-002](ADR-002-vpn-only-by-default.md)).

Constraints:
- No new inbound port, no public listener on the Pi.
- Must work from any device (a friend's laptop, a phone) with nothing but a
  memorised/written-down secret — the operator may have lost their own hardware.
- Powering off must leave the machine in a *safe* state: it should not come back
  up trivially in an attacker's hands.

## Decision

A root systemd service (`killswitch.service`) **subscribes outbound** to a
secret topic on the public `ntfy.sh` server and runs `systemctl poweroff` when it
receives a message whose body **exactly matches** a secret keyword.

- **Transport**: `curl -sN https://ntfy.sh/<topic>/raw` — a long-lived outbound
  HTTPS stream. No inbound connection, no port opened, nothing for UFW to allow.
- **Two independent secrets**, both stored only in the vault-encrypted
  `host_vars/homelab/local.yml` (never in the repo):
  - `killswitch_ntfy_topic` — a high-entropy topic (`openssl rand -hex 16`). On a
    public ntfy server the topic name **is** the access control, so it must be
    unguessable.
  - `killswitch_keyword` — a second secret; poweroff fires only on an exact match.
- **Trigger** from anywhere: `curl -d '<keyword>' https://ntfy.sh/<topic>`.
- **Recovery is deliberately manual** (see the runbook): there is no remote
  power-on. Restore power physically, then bring the encrypted data volume back
  as on any boot.

## Consequences

### Pros
- **No attack surface added**: outbound-only, consistent with the perimeter model.
  Nothing to scan, nothing for fail2ban/UFW to defend.
- **Reachable from anywhere** with just the two secrets — survives losing your own
  devices (the design goal). Secrets are kept on paper, off-network.
- **Defence in depth**: even if the topic leaks, the keyword is still required.
- **Simple & legible**: ~35 lines of bash + a systemd unit, no extra service to host.

### Cons
- **Secrets cross a third party**: the keyword transits `ntfy.sh` in the message
  body. Anyone subscribed to the topic sees it the first time it fires — hence the
  topic must stay secret (it gatekeeps who can subscribe), not just the keyword.
- **Topic visible locally**: `curl`'s URL (with the topic) appears in the process
  command line (`ps`, `systemctl status`). Acceptable on a single-admin Pi; a
  hardened variant would pass the topic via an auth header instead of the URL.
- **No confirmation / not reversible remotely**: once fired, the machine is off
  until someone is physically present. This is intended, not a limitation.
- **Depends on ntfy.sh availability**: a public-service outage disables the switch.

### Recovery model
Power-off is the safe state. Recovery requires physical presence: restore power,
then unlock the encrypted data volume with the LUKS passphrase as on any boot.
See the runbook for the exact steps.

## Alternatives Considered

- **Inbound webhook / open port**: simplest to trigger, but opens a public
  listener on the Pi — rejected, contradicts [ADR-002](ADR-002-vpn-only-by-default.md).
- **Smart plug (remote power cut)**: cuts power abruptly (risk of FS corruption),
  adds a cloud-dependent IoT device, and gives no clean OS shutdown. Rejected.
- **Self-hosted ntfy with auth tokens**: would let the topic be memorable while a
  credential carries the secret — but it's one more service to host, and if it
  runs on the Pi it's circular (down with the Pi). Deferred; reconsider if a
  self-hosted ntfy is deployed for other reasons.
- **MQTT / Telegram bot / e-mail poller**: all require either an inbound path, a
  hosted broker, or bot credentials with more moving parts than the ntfy stream.
  Rejected for complexity.