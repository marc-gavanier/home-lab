# Runbook — revoking a WireGuard peer

Use this when a device should lose VPN access: lost or stolen phone, laptop replaced or sold, guest
access that has served its purpose, or any peer you cannot name. A peer key opens everything behind
`vpn-only`.

## Before you start

- **Never remove the two infrastructure peers**: the offsite Pi's client (carries the nightly
  backup copy) and the homelab host tunnel (only management path to the offsite Pi). See
  [offsite-backup.md](offsite-backup.md) and ADR-010.
- **Do not read `wg0.json`.** It is the pre-v15 store (ADR-020): it still parses but is frozen, so
  peers added since are missing.
- Open the database with `-readonly`: it belongs to a running container, and a read-write open
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

## Clean up what the lost device still holds

- **Vaultwarden**: the mobile client keeps an encrypted offline cache. If the device may have been
  unlocked, change the master password, then invalidate sessions in `/admin` → *Users*.
- **Nextcloud**: `occ user:delete-app-password`, or *Devices & sessions* in the web UI. App
  passwords survive a password change; sessions do not.
- **Immich, Jellyfin**: sign out of all sessions in their settings.
- **SSH**: if the device carried a key, remove it from `authorized_keys` on both Pis.

## When to review

Review the peer list whenever a device is replaced, and at any restore drill. The question: can you
name the device behind each peer? If not, remove it.
