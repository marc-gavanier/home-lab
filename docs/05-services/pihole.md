# Pi-hole

DNS server for the LAN and the VPN: ad and tracker blocking, and split DNS that resolves home lab
subdomains to the Pi's LAN address. Upstream goes through dnsproxy to Quad9 over DoH
([Network](../04-network/README.md#resolver), ADR-015).

## At a glance

| Item           | Value                                                                                   |
|----------------|-----------------------------------------------------------------------------------------|
| Admin panel    | `https://dns.example.com/admin` (LAN and VPN)                                           |
| Password       | set by Ansible via `pihole setpassword`, from `local.yml`                               |
| Split DNS      | `ansible/roles/deploy/templates/pihole-05-homelab.conf.j2`                              |
| Upstream       | `dnsproxy` sidecar, `network_mode: service:pihole`                                      |
| Config and DB  | `/mnt/data/services/pihole/etc/` (`pihole.toml`, `pihole-FTL.db`, `gravity.db`)         |
| Custom dnsmasq | `/mnt/data/services/pihole/dnsmasq/`                                                    |
| Logs           | `/var/log/pihole`, container writable layer, not persisted                              |
| Backup         | restic, `/mnt/data/services` minus `pihole-FTL.db` (query history, excluded on purpose) |

## Router setup

Make Pi-hole the DNS server handed out by DHCP:

1. Router admin (192.168.1.1) > LAN > Characteristics.
2. DNS primaire: `<pi-lan-ip>`.
3. DNS secondaire: leave empty, so devices cannot bypass Pi-hole.

## Exempting a client from filtering

Some devices (typically an ISP TV decoder) break when filtered.

1. Pi-hole admin > **Groups** > create group `bypass` (description: "Unfiltered devices — e.g. TV decoder").
2. Pi-hole admin > **Clients** > add the device **by MAC**, not by IP.
3. Assign it to `bypass` only (remove it from **Default**).
4. Make sure no adlist is assigned to `bypass`.

Use the MAC: a rule on an IP keeps matching the old lease after the router moves it, and the
device is silently filtered again. Pi-hole v6 resolves a MAC per query.

This is a UI change, not a deploy: the client table lives in `gravity.db`, which Ansible does not
manage. Check what the rule holds:

```bash
sudo sqlite3 "file:/mnt/data/services/pihole/etc/gravity.db?mode=ro" \
  "select c.ip, g.name from client_by_group cg
     join client c on c.id = cg.client_id
     join 'group' g on g.id = cg.group_id;"
```

**Still open:** the `Bypass` group is still keyed on an IP. Replace it with the MAC in the UI,
then re-run the query.

Exempted devices are recorded in `pihole_bypass_clients` (list of `{ mac, label }`) in
`ansible/inventory/host_vars/<host>/private.yml`, gitignored because the repo is public;
`private.example.yml` has a placeholder. Nothing reads that key.

## Pi-hole v6 gotchas

- `WEBPASSWORD` and `DNSMASQ_LISTENING` no longer work. Use `FTLCONF_webserver_api_password` and
  `FTLCONF_dns_listeningMode`.
- `FTLCONF_*` values are re-applied at every start and lock the key in the UI. `pihole.toml` keeps
  every other setting; no need to delete it.
- Listening mode must be `all` (not `LOCAL`) to accept LAN queries through Docker's NAT.
- Custom dnsmasq files in `/etc/dnsmasq.d/` need `FTLCONF_misc_etc_dnsmasq_d: "true"`.
- **`pihole setpassword` takes no flags.** `pihole setpassword --help` sets the password to
  `--help`. To recover, re-run the Ansible deploy, which restores the vaulted value.
- The password hash is at `webserver.api.pwhash`, visible only under **Settings → All settings**
  with *Expert* on.

## How the data is protected

`pihole/etc` holds the only login factor (`webserver.api.pwhash`) and every DNS query
(`pihole-FTL.db`).

- On every start the image resets modes: directories `0755`, files `0640`. Gravity's weekly
  rebuild puts `gravity.db` and `listsCache/` back to `0664`. So modes inside the directory
  cannot be enforced.
- The gate is one level up, on a directory nothing inside the container can touch:

| Assertion | What it holds |
|---|---|
| `pihole-store-not-traversable-by-others` | `/mnt/data/services/pihole` is `0750` |
| `pihole-credential-files-not-world-readable` | `pihole.toml`, `pihole-FTL.db`, `*.key` and `cli_pw` are not world-readable, and at least two of them are found |

## Logs

- `/var/log/pihole` is not persisted, on purpose: `pihole-FTL.db` already holds every query. It is
  excluded from the backup too, so the query history does not survive a restore. The writable layer is on the HDD (`/mnt/data/docker`).
- `pihole.log` rotates with `copytruncate`, from a file this repo owns. The image's own rotation
  signals FTL to reopen and can fail silently, leaving FTL writing to the rotated file.
- `FTL.log` and `webserver.log` keep the image's `create` rotation.
- The only rotator is `pihole flush once quiet` (cron, midnight), which runs
  `logrotate --force`. So every stanza rotates daily; `rotate 21` keeps three weeks of
  `FTL.log` and `webserver.log`, `pihole.log` keeps 5 days.
  Empty logs are not rotated (`notifempty`).

`pihole-ftl-writes-the-current-log` checks which file FTL actually has open. Run it on the host
(the container lacks `CAP_SYS_PTRACE` and must not get it):

```bash
for p in $(pgrep -x pihole-FTL); do sudo readlink /proc/$p/fd/*; done | grep /var/log/pihole/
```

## Restore

Stopping both containers costs the house its DNS for the restore. Do it anyway: restoring under a
running FTL gets overwritten when FTL flushes.

1. Stop dnsproxy first (it lives in Pi-hole's namespace), then Pi-hole:

   ```bash
   cd /opt/homelab
   docker compose down dnsproxy pihole
   ```

2. Restore:

   ```bash
   restic restore latest --target / --include /mnt/data/services/pihole
   ```

3. Recreate both. `down` removed the containers, so dnsproxy must be recreated to attach to the new
   Pi-hole:

   ```bash
   docker compose up -d pihole
   docker compose up -d --force-recreate dnsproxy
   ```

4. Re-run the Ansible deploy to set the password. If it recreates Pi-hole, it re-attaches dnsproxy
   itself (`roles/deploy/tasks/compose.yml`).

## Troubleshooting

**LAN-wide DNS outage, both containers green.** dnsproxy runs with `network_mode: service:pihole`.
When Pi-hole comes back, dnsproxy stays attached to the old namespace and is unreachable. The fix
depends on how Pi-hole came back:

| Pi-hole was…                                   | Fix |
|------------------------------------------------|-----|
| restarted in place (`docker restart pihole`)   | `docker restart pihole && docker restart dnsproxy` |
| recreated (`compose up`, Ansible deploy, …)    | `docker compose up -d --force-recreate dnsproxy` |

Never restart dnsproxy after a recreate: it points at the dead container ID, exits 1 and stays
stopped. Details: [container-config-changes.md](../../knowledge/runbooks/container-config-changes.md).
