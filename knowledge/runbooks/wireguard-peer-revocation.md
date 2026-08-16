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
ssh homelab "sudo sqlite3 -readonly /mnt/data/services/wireguard/wg-easy.db \
  \"SELECT name, ipv4_address, CASE enabled WHEN 1 THEN 'enabled' ELSE 'DISABLED' END \
    FROM clients_table ORDER BY id;\""
```

`-readonly` matters: the file is the live database of a running container, and
opening it read-write would take a lock wg-easy needs.

**Two of them are infrastructure, not people**, and both are documented
elsewhere in this repo because operating the offsite backup requires knowing
them: the offsite Pi's client, and the homelab's own host tunnel
(`knowledge/runbooks/offsite-backup.md`, ADR-010). **Do not remove either** —
one carries the nightly backup copy, the other is the only management path to
the offsite Pi. Everything else in the list should be a personal device you can
name.

**Do not read `wg0.json`.** It was the peer store before the v15 migration
(ADR-020) and is no longer written — the file is still on disk, still parses,
and still returns a peer list, so a command reading it looks like it works. It
answers with the inventory as it stood on the migration day, which means any
peer added since is invisible. `wg0.conf` next to it *is* still regenerated,
which makes the whole directory look alive.

## Revoking

> **Deleting from the UI does not currently work — issue #138.** wg-easy runs as
> root with `cap_drop: ALL`, so it holds no `CAP_DAC_OVERRIDE`, and its data
> directory is owned by uid 1000. It therefore cannot create files there, and the
> database is in `delete` journal mode, which needs a `-journal` file per
> transaction. Every write fails with `SQLITE_READONLY` behind an HTTP 500 — the
> container stays healthy and the UI reports nothing useful. Until #138 is fixed,
> **step 1 below silently does nothing**; use the stopgap first.

**Stopgap while #138 is open.** The kernel side still accepts changes, because
`CAP_NET_ADMIN` is granted. This closes the door immediately:

```bash
# 1. find the public key of the peer to revoke
ssh homelab "sudo sqlite3 -readonly /mnt/data/services/wireguard/wg-easy.db \
  \"SELECT name, public_key FROM clients_table ORDER BY id;\""

# 2. drop it from the running interface
ssh homelab "docker exec wg-easy wg set wg0 peer '<public-key>' remove"
```

This is **not persistent**. The client is still in the database and still in
`wg0.conf`, so the peer returns whenever the interface is rebuilt from that file
— a container restart, or the crash-heal timer picking it up. Treat it as
stopping the bleeding, then finish the deletion through the UI once #138 lands.
A revocation that has to survive is not done until the client is gone from the
listing query.

1. **Delete the client** in the wg-easy UI (`https://vpn.<domain>`, or the
   `127.0.0.1:51821` tunnel) — *delete*, not the toggle next to it. Disabling
   drops the peer from the interface but keeps its key in the database, so a
   disabled client is one click away from working again. Re-run the listing
   query: a deleted client is gone from the output, a disabled one is still
   there marked `DISABLED`.

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
