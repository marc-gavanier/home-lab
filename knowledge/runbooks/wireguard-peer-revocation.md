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

> **#138 is closed since 2026-08-26 (`ca6d72e`): the UI is the primary path
> again.** For eight days this runbook said the opposite, because wg-easy ran as
> root over a data directory owned by uid 1000 with `cap_drop: ALL`, so its SQLite
> rollback journal could not be created and every write returned `SQLITE_READONLY`
> behind an HTTP 500. The directory is now `root:root 0700`, and the container
> writes: a `userconfig` POST returned HTTP 200 with `updated_at` moving, and
> wg-easy regenerated `wg0.conf` on its own at 02:52:20 on 2026-08-29.
>
> **What is proven and what is not.** The write path is proven. A *client
> deletion* specifically has not been exercised — it takes the same path, but
> nobody has removed a real peer to watch it happen, and this runbook has just
> spent eight days being confidently wrong about this exact mechanism. So: delete
> through the UI, then **verify against `clients_table` and against the running
> interface** as steps 1 and 2 below require. Treat the listing query as the
> verdict, not the UI.

**Immediate measure, when the device is already out of your hands.** The kernel
side accepts changes directly, because `CAP_NET_ADMIN` is granted, and this shuts
the peer out in one command without waiting for anything else. It is no longer a
workaround for a broken UI — it is what you do first when minutes matter, before
doing the durable deletion below:

```bash
# 1. find the public key of the peer to revoke
ssh homelab "sudo sqlite3 -readonly /mnt/data/services/wireguard/wg-easy.db \
  \"SELECT name, public_key FROM clients_table ORDER BY id;\""

# 2. drop it from the running interface
ssh homelab "docker exec wg-easy wg set wg0 peer '<public-key>' remove"
```

**How long it holds: until wg-easy restarts or the Pi reboots.** Not until the
next timer tick — that distinction is the whole question when you are deciding
whether you can go to bed. wg-easy runs a job every 60 s that *can* undo a
manual removal: it regenerates `wg0.conf` and runs `wg syncconf`, rebuilding
the interface from the database, where the client still is. But it only does
that after toggling a client that passed its expiry date, and nothing here has
an expiry set — so the rebuild is never reached, and the peer stays out.

**It is not the revocation.** A restart brings the client back from the database.
Always follow it with the deletion below: a revocation that has to survive is not
done until the client is gone from `clients_table`.

**Peers with an expiry date.** The job that disables an expired client does it
with a database write, which failed for as long as #138 was open. Writes work
again, but **nothing has an expiry set today and the expiry path has never been
observed running here** — so a time-limited peer is reasonable to hand out now,
and worth verifying the first time you do rather than assuming.

1. **Delete the client** in the wg-easy UI (`https://vpn.<domain>`, or the
   loopback tunnel) — *delete*, not the toggle next to it. Disabling drops the
   peer from the interface but keeps its key in the database, so a disabled
   client is one click away from working again. Re-run the listing query: a
   deleted client is gone from the output, a disabled one is still there marked
   `DISABLED`.

   **The listing query is the verdict, not the UI.** If the client is still in
   `clients_table` after a delete, the write did not land — capture the wg-easy
   logs before doing anything else, because that is #138 returning and the
   posture check's exemption for it was removed in `ca6d72e` precisely so it
   would be caught.

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
