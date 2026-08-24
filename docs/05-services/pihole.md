# Pi-hole

DNS server with ad/tracker blocking and split DNS for the home lab.

## Access

- Admin panel: `https://dns.example.com/admin`
- Accessible from LAN (via split DNS) and VPN
- Password: set by Ansible via `pihole setpassword` (from `local.yml`)

## What It Does

- Blocks ads and trackers at the DNS level for all devices using it as DNS
- Split DNS: resolves homelab subdomains to LAN IP so traffic stays local
- Custom dnsmasq config: `ansible/roles/deploy/templates/pihole-05-homelab.conf.j2`

## Network-wide Setup

### ISP Router Configuration

Set Pi-hole as the DNS server distributed by DHCP:

1. Router admin (192.168.1.1) > LAN > Characteristics
2. DNS primaire: `192.168.1.100`
3. DNS secondaire: leave empty (prevents devices from bypassing Pi-hole)

### TV Decoder Bypass

The SFR TV decoder breaks when filtered by Pi-hole. Exclude it:

1. Pi-hole admin > **Groups** > create group `bypass` (description: "Unfiltered devices — e.g. TV decoder")
2. Pi-hole admin > **Clients** > add decoder IP (`192.168.1.46`, MAC `B4:E2:65:E3:BF:DF`)
3. Assign the decoder to group **bypass** only (remove from **Default**)
4. Ensure adlists are NOT assigned to the bypass group

## Pi-hole v6 Gotchas

- **Environment variables**: `WEBPASSWORD` and `DNSMASQ_LISTENING` no longer work. Use `FTLCONF_webserver_api_password` and `FTLCONF_dns_listeningMode` instead.
- **Config persistence**: env vars are only read on first start. Once `pihole.toml` exists in the volume, env vars are ignored. Delete `pihole.toml` to force re-read.
- **Listening mode**: must be set to `all` (not `LOCAL`) for Pi-hole to accept DNS queries from the LAN through Docker's NAT.
- **Password**: set via `pihole setpassword` command (Ansible handles this automatically).
- **`pihole setpassword` takes no flags**: it treats its argument as the new password, whatever
  it looks like. Running `pihole setpassword --help` to see the options **sets the password to
  the literal string `--help`** and answers `[✓] New password set`. Done accidentally on
  2026-08-18; recovered by re-running the Ansible task, which restores the vaulted value.
  The password is also not editable from the normal settings pages — it lives at
  `webserver.api.pwhash`, visible only under **Settings → All settings** with *Expert* on.
- **Custom dnsmasq**: requires `FTLCONF_misc_etc_dnsmasq_d: "true"` to read files in `/etc/dnsmasq.d/`.

## Data

| Path                                 | Content                               |
|--------------------------------------|---------------------------------------|
| `/mnt/data/services/pihole/etc/`     | Pi-hole configuration (`pihole.toml`) |
| `/mnt/data/services/pihole/dnsmasq/` | Custom dnsmasq configs                |

### The directory mode is the image's, the file modes are what protect the data

`pihole/etc` is a credential store — `pihole.toml` carries `webserver.api.pwhash`
with TOTP and app-password empty, so that hash is the only factor, and
`pihole-FTL.db` is every DNS query the household has made.

It is **not** held at `0700`, and that is measured rather than conceded. The
image's prestart script runs, on every container start:

```
find /etc/pihole/ /var/log/pihole/ -type d -exec chmod 0755 {} +
find /etc/pihole/ /var/log/pihole/ -type f ! \( -name '*.pem' -o -name '*.crt' \) -exec chmod 0640 {} +
```

So a directory mode set from Ansible survives until the next restart, and #189's
gate had been reverted every time Pi-hole started since it was applied — visible
only when a restart happened to fall between two posture runs, which it finally
did on 2026-08-25.

The second line is what matters: the files are `0640` and re-asserted on every
start. From a genuinely different unprivileged account, with controls:

```
READABLE   /etc/passwd                    <- control
refused    /etc/shadow                    <- control
refused    .../pihole/etc/pihole.toml
refused    .../pihole/etc/pihole-FTL.db
refused    .../pihole/etc/cli_pw
```

Only the listing of file *names* is permitted. The posture spec therefore asserts
`pihole-etc-no-world-readable-file` — which would also have caught #189's original
finding (`pihole.toml` at `0644`) and does not depend on a mode the image owns.
`versions` is excluded by name: the same script sets it `0644` deliberately and it
holds version strings.

### Logs are deliberately NOT persisted

`/var/log/pihole` lives in the container's writable layer and is discarded on a
recreate. That is a decision, not an oversight: `pihole-FTL.db` (332 MB, under
`pihole/etc/`) already holds every query, is already persisted and is already in
the restic set. Persisting the text log would put the household's DNS history
into the offsite backup a second time, in cleartext, for no capability that
Pi-hole's own database does not provide. The writable layer is on
`/mnt/data/docker` — the HDD — so the growth never touches the SD card either.

**Rotation uses `copytruncate`, and this repository owns that file.** The image's
own rotation asks FTL to reopen with a `SIGUSR2` and hides the failure behind
upstream's `|| true`. On 2026-08-17 the signal did not land: the file had already
been renamed, FTL kept writing to the renamed inode, `pihole.log` stayed at 0
bytes, and `notifempty` then skipped it every night after — self-sustaining, and
by 2026-08-25 the rotated file was 38 MB into a second stretch (#202).

The symptom is invisible to every check that looks at outcomes — the container is
healthy, DNS answers, the files are present with sane modes and `pihole.log`
exists. What is wrong is *which file the writer has open*, so that is what
`pihole-ftl-writes-the-current-log` asserts, at the descriptor, from the host:

```bash
for p in $(pgrep -x pihole-FTL); do sudo readlink /proc/$p/fd/*; done | grep /var/log/pihole/
```

It has to run on the host — reading another uid's `/proc/PID/fd` needs
`CAP_SYS_PTRACE`, which this container does not have and must not be given.

`FTL.log` and `webserver.log` keep the image's `create` rotation: they are opened
and closed per line, which is why they rotated correctly throughout. The offsite
Pi runs no Pi-hole and has no `/var/log/pihole` — both checked when this was
fixed.

## Restore

From Restic backup:
```bash
restic restore latest --target / --include /mnt/data/services/pihole
# Both, in this order, and never `docker restart pihole` alone: dnsproxy runs
# with `network_mode: service:pihole`, so restarting Pi-hole destroys the
# namespace dnsproxy is attached to. dnsproxy keeps running and stays healthy
# while being permanently unreachable, which leaves Pi-hole with no upstream at
# all — a LAN-wide DNS outage with both containers green. The Ansible handler
# does exactly this pair for the same reason.
docker restart pihole && docker restart dnsproxy
# Then re-run Ansible deploy to set the password
```
