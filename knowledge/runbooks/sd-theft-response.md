# Runbook — Homelab SD card stolen, lost or possibly imaged

Use this page when the SD card (or an image of it) may be in someone else's hands.
The card holds the system and configs (as public as the GitHub repo) plus the
short list of live material below; service and backup credentials are on LUKS
([ADR-011](../decisions/ADR-011-secrets-off-sd.md)).

## Steps

Do these in order.

1. **Kill switch.** The card holds `/etc/killswitch.env` (topic + keyword), so
   the holder can power the Pi off. Rotate `killswitch_ntfy_topic` and
   `killswitch_keyword` in the homelab vault and redeploy (`--tags killswitch`).
2. **Claude OAuth tokens.** The `claude` user's state (login, sessions, memory)
   and the vault's write cache are on LUKS, bind-mounted at `/home/claude/.claude`,
   and the operator account holds no Claude login; older tokens can survive in the
   card's freed blocks. At claude.ai → Settings → Account, revoke the Pi's line
   under *Active sessions*, or *Log out of all devices* if it cannot be told
   apart, then re-auth on the Pi.
3. **SSH host keys.** An image lets an attacker impersonate the server (MITM).
   Regenerate with `sudo rm /etc/ssh/ssh_host_*` then
   `sudo ssh-keygen -A && sudo systemctl restart ssh.socket`, and update
   `known_hosts` on your clients.
4. **Password hash.** The account has no hash, but the flash-time one can
   survive in the card's freed blocks and be cracked offline: if that password
   is used anywhere else, change it there.
5. **Kuma push tokens.** They live on LUKS, but tokens older than their move
   there can survive in the card's freed blocks: reset any push monitor's token
   in Kuma that has not been reset since 2026-09-27.

## What the card does not give

Service passwords, Kuma push tokens, restic repo passwords (local and offsite),
the WireGuard key, rclone credentials, the SearXNG secret, the `claude` user's
sessions and the notes it writes through the vault: all on LUKS.

## Whole-Pi theft

- **Powered off**: same steps; the LUKS disk is locked, data stays confidential,
  offsite backups are untouched.
- **Running** (volume unlocked): the evil-maid case, see ADR-008 and ADR-009.
  Assume full compromise and rotate everything.
