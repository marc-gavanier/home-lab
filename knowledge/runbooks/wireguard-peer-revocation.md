# Runbook — revoking a WireGuard peer

Use this when a device should lose VPN access: lost or stolen phone, laptop replaced or sold, guest
access that has served its purpose, or any peer you cannot name. A peer key opens everything behind
`vpn-only`.

## Before you start

- **Never remove the two infrastructure peers**: the offsite Pi's client (carries the nightly
  backup copy) and the homelab host tunnel (only management path to the offsite Pi). See
  [offsite-backup.md](offsite-backup.md) and ADR-010. The one exception is a stolen offsite Pi.
- **Do not read `wg0.json`.** It is the pre-v15 store (ADR-020): it still parses but is frozen, so
  peers added since are missing.
- Read the database with `-readonly`: it belongs to a running container, and a read-write open
  takes a lock wg-easy needs.

## List the peers

The list is not written in this public repo. Read it from the host:

```bash
ssh homelab "sudo sqlite3 -readonly /mnt/data/services/wireguard/wg-easy.db \
  \"SELECT name, ipv4_address, CASE enabled WHEN 1 THEN 'enabled' ELSE 'DISABLED' END \
    FROM clients_table ORDER BY id;\""
```

This query is the verdict for every step below, not the UI.

## Cut the peer off now

Use this first when the device is already out of your hands. It holds until wg-easy restarts or the
Pi reboots, so always follow it with the deletion below.

1. Find the peer's public key:

   ```bash
   ssh homelab "sudo sqlite3 -readonly /mnt/data/services/wireguard/wg-easy.db \
     \"SELECT name, public_key FROM clients_table ORDER BY id;\""
   ```

2. Drop it from the running interface:

   ```bash
   ssh homelab "docker exec wg-easy wg set wg0 peer '<public-key>' remove"
   ```

## Delete the peer

1. In the wg-easy UI (`https://vpn.<domain>`, or the SSH tunnel), **delete** the client. Do not use
   the toggle: a disabled client keeps its key and is one click from working again.
2. Re-run the listing query. Expected: the client is gone. A disabled one would still show
   `DISABLED`.
3. Check the kernel dropped it:

   ```bash
   ssh homelab 'docker exec wg-easy wg show wg0 | grep -A2 "peer:"'
   ```

   Expected: the revoked public key is absent.

4. Check the remaining peers reconnect. Poll for a few minutes; handshakes return at each client's
   pace:

   ```bash
   ssh homelab 'docker exec wg-easy wg show wg0 latest-handshakes'
   ```

   Watch `offsite-backup` (10.8.0.4): it keeps alive every 25 s and re-resolves every minute.
   Do not restart its `wg-quick@wg0`: that goes through the tunnel it tears down (ADR-029).

## If it fails

| Symptom | Action |
|---|---|
| Client still in `clients_table` after a UI delete | The write did not land. Capture the wg-easy logs before anything else. |
| Key still listed by `wg show` | Interface not reloaded: `docker restart wg-easy`, then check again. **Only with someone able to reach the Pi physically** — see [rotate-a-secret.md](rotate-a-secret.md). |

The UI delete path has not yet been exercised on a real peer: always verify with the query.

## Peers with an expiry date

No peer has an expiry today, and the expiry job has never been seen running here. You can hand out
a time-limited peer, but check the first time that it is actually disabled at expiry.

## End every wg-easy admin session

A wg-easy login never expires on the server, and neither a password change nor a logout ends
another browser's session. A device that was logged in to the UI can still add peers and download
every client's configuration, private keys included. Replace the key that seals the sessions;
wg-easy reads it on every request, so no restart is needed:

```bash
ssh homelab "sudo sqlite3 /mnt/data/services/wireguard/wg-easy.db \
  \"UPDATE general_table SET session_password = lower(hex(randomblob(32)));\""
```

Expected: the UI asks you to log in again.

## Clean up what the lost device still holds

- **wg-easy UI**: if the device was ever logged in, end every session (above).
- **Claude app**: it reaches Remote Control on the Pi through claude.ai, not through the VPN.
  Revoke its line at claude.ai → Settings → Account → *Active sessions*.
- **Navidrome**: music apps keep the account password. Change it in Navidrome.
- **Vaultwarden**: the mobile client keeps an encrypted offline cache. If the device may have been
  unlocked, change the master password, then invalidate sessions in `/admin` → *Users*.
- **Nextcloud**: `occ user:auth-tokens:list <user>` then
  `occ user:auth-tokens:delete <user> <id>`, or *Devices & sessions* in the web UI. App
  passwords survive a password change; sessions do not.
- **Immich, Jellyfin**: sign out of all sessions in their settings.
- **SSH**: if the device carried a key, remove it from `authorized_keys` on both Pis.

## When to review

Review the peer list whenever a device is replaced, and at any restore drill. The question: can you
name the device behind each peer? If not, remove it.
