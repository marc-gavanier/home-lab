# Runbook — revoking a WireGuard peer

A peer key is the whole perimeter. Everything behind `vpn-only` — Nextcloud,
Vaultwarden, Immich, the Pi-hole admin, the Traefik dashboard — trusts anyone
holding one, and `wg-easy` makes adding peers easy enough that they accumulate
silently (issue #38).

**Revoke on**: a lost or stolen phone, a laptop being replaced or sold, a guest
whose access has served its purpose, or any device you can no longer name.

## Listing the peers

The inventory is deliberately **not** written down here — this repository is
public, and a list of peer names and addresses maps the personal devices that
can reach everything behind `vpn-only`. Read it from the host instead:

```bash
ssh homelab 'sudo jq -r ".clients | to_entries[] | \"\(.value.name) \(.value.address)\"" \
  /mnt/data/services/wireguard/wg0.json'
```

**Two of them are infrastructure, not people**, and both are documented
elsewhere in this repo because operating the offsite backup requires knowing
them: the offsite Pi's client, and the homelab's own host tunnel
(`knowledge/runbooks/offsite-backup.md`, ADR-010). **Do not remove either** —
one carries the nightly backup copy, the other is the only management path to
the offsite Pi. Everything else in the list should be a personal device you can
name.

## Revoking

1. **Delete the client** in the wg-easy UI (`https://vpn.<domain>`, or the
   `127.0.0.1:51821` tunnel). The peer disappears from `wg0.json`.

2. **Verify the kernel actually dropped it** — the UI showing it gone is not
   proof, the running interface is:

   ```bash
   ssh homelab 'docker exec wg-easy wg show wg0 | grep -A2 "peer:"'
   ```

   The revoked public key must be absent. If it is still listed, the interface
   has not been reloaded: `docker restart wg-easy`, then check again.

3. **Confirm the remaining peers still work** before walking away — recreation
   drops handshakes and they return at each client's own pace, so poll for a
   minute rather than concluding immediately:

   ```bash
   ssh homelab 'docker exec wg-easy wg show wg0 latest-handshakes'
   ```

   `offsite-backup` (10.8.0.4) is the one to watch: it dials out on its own
   schedule, so give it a few minutes, or force it with
   `ssh offsite sudo systemctl restart wg-quick@wg0`.

## What the lost device still holds

Revoking the tunnel closes the door; it does not empty the pockets of whoever
took the device. Work through this before deciding the incident is over:

- **Vaultwarden**: the mobile client keeps an **encrypted offline cache**. It is
  useless without the master password, but a device unlocked at the moment of
  loss is a different situation — change the master password, then use
  `/admin` → *Users* to invalidate sessions.
- **Nextcloud**: `occ user:delete-app-password` or the *Devices & sessions* list
  in the web UI. App passwords survive a password change; sessions do not.
- **Immich, Jellyfin**: sign out of all sessions from their respective settings.
- **SSH**: if the device carried a key, remove it from `authorized_keys` on both
  Pis — the tunnel is not the only path in, and the key outlives the VPN peer.

## Cadence

Review the peer list at each restore drill (annually, see
`restore-from-backup.md`). The question to answer is not "are these peers
valid?" but "**can I name the device behind each one?**" — a peer that cannot be
named is a peer to remove.
