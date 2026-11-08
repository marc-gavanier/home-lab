# Mumble

The voice server of the workstation's voice bridge: the phone (Mumla) and the bridge (pymumble,
on the workstation) meet here. Only the server runs on the Pi; the bridge, Whisper and Voxtral
need the workstation's GPU ([ADR-043](../../knowledge/decisions/ADR-043-mumble-voice-bridge-server.md)).

## At a glance

| Item       | Value                                                                      |
|------------|----------------------------------------------------------------------------|
| Address    | `voice.example.com`, port `64738` TCP+UDP (LAN and VPN only, Pi-hole DNS)  |
| Container  | `mumble` (uid 10000, zero capabilities, read-only rootfs)                  |
| Login      | any user name + the server password `mumble_server_password` (vault)       |
| Image      | `mumblevoip/mumble-server:v1.6.1001-0`                                     |
| Data       | `/mnt/data/services/mumble/data`: server certificate, settings, SQLite     |
| Backup     | restic (`/mnt/data/services`); nothing in it needs a dump                  |
| Monitoring | healthcheck (TCP) + Kuma TCP monitor on `voice.example.com:64738`          |
| Startup    | wave 2, right after Pi-hole                                                |

## How it works

- Not behind Traefik: Mumble speaks its own TLS protocol on 64738. The port is published on every
  interface and filtered in UFW's `DOCKER-USER` chain like Pi-hole's 53: the LAN, the VPN and the
  container networks pass, everything else is dropped. The box forwards nothing to it.
- The server password is a Docker secret mounted as `/run/secrets/MUMBLE_CONFIG_SERVERPASSWORD`,
  which the image's entrypoint reads at every start. It writes it into
  `data/mumble_server_config.ini`, regenerated at each start, on the encrypted volume.
- The certificate is self-signed and generated on first start. Mumla asks once to trust it; a new
  `data/` means a new certificate and one more question.
- No user is registered and no channel is created: the bridge and the phone join the root channel.

## Common tasks

### Change the server password

Set `mumble_server_password` in the vaulted `local.yml` and deploy: the secret changes, the
handler restarts `mumble`. Then update `MUMBLE_PASSWORD` in the bridge's `.env` and the password
in Mumla.

### Restore

Nothing to restore by hand: restic brings `data/` back with `/mnt/data/services`. Deleting
`data/` is also a valid restore; the server starts empty and Mumla asks to trust the new
certificate.

## Troubleshooting

| Symptom                                | Cause                                               | Action                                                         |
|----------------------------------------|-----------------------------------------------------|----------------------------------------------------------------|
| Mumla: "certificate changed"           | `data/` was recreated                               | Accept the new certificate                                     |
| Mumla times out on `voice.example.com` | Phone not on Pi-hole DNS, or outside LAN and VPN    | Check Wi-Fi DNS, or turn WireGuard on                          |
| "Wrong server password"                | Vault, `.env` and Mumla disagree                    | Compare the three; the vault is the reference                  |

Upstream docs: <https://www.mumble.info/documentation/>
