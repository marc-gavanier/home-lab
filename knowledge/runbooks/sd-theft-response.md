# Runbook — Homelab SD card stolen, lost or possibly imaged

Since [ADR-011](../decisions/ADR-011-secrets-off-sd.md) the SD card carries
**no service or backup credentials** — those live on the LUKS volume. An
attacker holding the card (or an image of it) gets the system and configs
(equivalent to the public GitHub repo) plus a short list of live material.
Response, in order:

1. **Kill switch** — the card holds `/etc/killswitch.env` (ntfy topic +
   keyword): whoever has it can power the Pi off remotely. Rotate
   `killswitch_ntfy_topic` and `killswitch_keyword` in the homelab vault,
   redeploy (`--tags killswitch`).
2. **Claude OAuth tokens** — `~/.claude/.credentials.json` (both users).
   Revoke the sessions at claude.ai → Settings → Devices, re-auth on the Pi.
3. **SSH host keys** — an imaged card lets an attacker impersonate the
   *server* to you (MITM). Regenerate: `sudo rm /etc/ssh/ssh_host_*` then
   `sudo ssh-keygen -A && sudo systemctl restart ssh.socket`, and update
   `known_hosts` on your clients.
4. **Password hash** — nothing to do: the flash-time hash in the cloud-init
   artifacts is redacted by the security role, and the account is
   password-locked anyway.

What the card does **not** give: service passwords, restic repo passwords
(local & offsite), the WireGuard key, rclone credentials, the SearXNG
secret — all on LUKS. DNS/ad-block config, compose files, hardening config
are public by design.

> Whole-Pi theft **while powered off** is the same scenario plus a locked
> LUKS disk: data stays confidential, offsite backups untouched. Theft
> **while running** (volume unlocked) is the evil-maid case — see ADR-008
> (USB tamper) and ADR-009; assume full compromise and rotate everything.
