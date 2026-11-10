# ADR-043 — The voice bridge's Mumble server on the Pi, and only it

**Date**: 2026-11-08
**Status**: accepted — deployed on the Pi on 2026-11-08; 9 MB RAM idle

## Context

The voice bridge lets the operator talk to a Claude Code session from the phone. Audio goes
Mumla (phone) → WireGuard through the Pi → a Mumble server → the bridge (pymumble) → Whisper →
a Claude Code channel, and the answer comes back through Voxtral.

> **Amended 2026-11-10.** The bridge no longer uses pymumble: its last release (1.6.1, 2021) pinned
> Python 3.11 and a protobuf with known vulnerabilities, and it never verified the server
> certificate. It now uses pymumble-rev, pins this server's certificate and only listens to the
> speaker's client certificate. The server side is unchanged; checked against `v1.6.1001-0` the
> same day (pinned connection accepted, another certificate refused before the password is sent).

The Mumble server was a provisional container on the workstation: no restart policy, so it was
down after every reboot until started by hand, and bound to the address the DHCP lease gave the
workstation, so a new lease meant recreating it and editing the bridge's configuration.

## Decision

Run **only the Mumble server** on the Pi, as the `mumble` service, reachable at
`voice.<domain>:64738` from the LAN and the VPN. The bridge, Whisper and Voxtral stay on the
workstation: they need its GPU, and Claude Code starts the bridge locally.

- **Image:** the official `mumblevoip/mumble-server`, published for arm64. Pinned to
  `v1.6.1001-0`, the latest stable; pymumble, the bridge's client library, was checked against it
  before the choice (authenticated, wrong password refused). No Debian package is needed.
- **Hardening:** uid 10000 from the start, zero capabilities, read-only rootfs. The entrypoint
  only needs `/data` writable, and Ansible creates it with the right owner, so the image's
  `chown` step never runs.
- **Exposure:** the port is published on every interface and filtered in `DOCKER-USER`, the
  pattern Pi-hole's 53 already uses, because published ports bypass UFW's INPUT policy. LAN,
  VPN and container networks pass; nothing is forwarded on the box.
- **Secret:** the server password is a Docker secret named `MUMBLE_CONFIG_SERVERPASSWORD`, the
  file name the entrypoint reads, so no password goes through `environment:` (ADR-016). An empty
  value is refused at deploy time: it would open the server, and the session behind it, to anyone
  on the LAN or the VPN.
- **Backup:** none of its own. `data/` holds a self-signed certificate and a near-empty SQLite
  database; restic takes it with `/mnt/data/services`, and losing it costs one certificate prompt
  in Mumla.

## Consequences

- The server survives workstation reboots and DHCP changes; the bridge's `.env` points at
  `voice.<domain>`.

  > **Amended 2026-11-10.** The bridge reads `~/.config/voice-bridge/config.toml` instead of a
  > `.env`; its `[mumble]` section points at `voice.<domain>` and holds the pinned certificate.
- The voice path now depends on the Pi, which it already did: WireGuard runs there.
- One more container (35), one more Kuma monitor, one more vaulted secret.

## Alternatives considered

- **Keep the server on the workstation with a restart policy and a DHCP reservation.** Fixes
  both defects, but leaves a service outside Ansible, the backup and the monitoring.
- **Move the whole bridge to the Pi.** Whisper and Voxtral need a GPU the Pi does not have.
- **Debian `mumble-server` package on the host.** Not needed since the image exists for arm64,
  and it would be the only service outside Docker Compose besides Claude Code.
