# Installation Guide

Use this page to build the homelab Pi from a blank SD card to a running stack.

## Before you start

On the workstation:

- SSH key pair (`~/.ssh/id_ed25519`)
- Raspberry Pi Imager (`sudo apt install rpi-imager`)
- Ansible (`pipx install ansible --include-deps`)
- The pinned collections and roles, from the repository root:
  `ansible-galaxy collection install -r ansible/requirements.yml` and
  `ansible-galaxy role install -r ansible/requirements.yml`
- nmap (`sudo apt install nmap`)
- An SD card reader

## Step 1 — Flash the SD Card

In Raspberry Pi Imager choose Raspberry Pi 4, Ubuntu Server 24.04 LTS (64-bit),
the 64 GB card. Click "Edit Settings" before flashing:

| Setting         | Value                                             |
|-----------------|---------------------------------------------------|
| Hostname        | `homelab`                                         |
| Username        | `pi`                                              |
| Password        | Set a temporary password (will be disabled later) |
| Locale/Timezone | `Europe/Paris`, keyboard `fr`                     |
| SSH             | Enabled, public-key authentication only           |
| SSH public key  | Content of `~/.ssh/id_ed25519.pub`                |
| Telemetry       | Disabled                                          |
| Wi-Fi           | Not configured (Ethernet only)                    |

"Set username and password" must be enabled, or no user exists for the SSH key.

Wait for write and verification, then eject:

```bash
sudo umount /dev/mmcblk0p1 /dev/mmcblk0p2 2>/dev/null
sync
# Then physically remove the card
```

## Step 2 — First Boot

1. Insert the SD card.
2. Connect Ethernet, the 5 TB HDD (blue USB 3.0 port), then power last.
3. Wait ~2 minutes, then find the host named `homelab`:

```bash
nmap -sn 192.168.1.0/24
```

## Step 3 — Verify SSH Access

```bash
ssh pi@<pi-lan-ip>
```

Expected: no password prompt, then the Ubuntu welcome message.

## Step 4 — Configure Static IP

1. Open the router admin panel (192.168.1.1), **LAN > Baux statiques**.
2. Add a static lease: MAC from `ip link show eth0 | grep ether`, IP outside the
   dynamic range (e.g. `192.168.1.10`). If the router says "IP already in use",
   pick one outside the dynamic pool (.10–.50 or .100).
3. Reboot the Pi: `sudo reboot`
4. Verify: `ssh pi@<pi-lan-ip>`
5. Remove the old host key: `ssh-keygen -R <OLD_IP>`

## Step 5 — Verify Ansible Connectivity

Ansible checks host keys against your `known_hosts`. Its first connection to a new
address or port, including the hardened SSH port after the first full run, asks you
to confirm the key. After a reflash, remove the old entries first:
`ssh-keygen -R <pi-lan-ip>` and `ssh-keygen -R "[<pi-lan-ip>]:<ssh-port>"`.

```bash
cd ~/Storage/Workspace/learn/home-lab/ansible
ansible homelab -m ping
```

Expected:

```
homelab | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

Check the HDD is detected (expected: `/dev/sda` with a `sda1` partition, ~4.5T):

```bash
ansible homelab -m command -a "lsblk"
```

## Step 6 — Configure Secrets

All secrets live in `local.yml`, encrypted with Ansible Vault. The Pi's address and
other private, non-secret values live in `private.yml`, gitignored and not encrypted.

```bash
cd ~/Storage/Workspace/learn/home-lab/ansible/inventory/host_vars/homelab
cp local.example.yml local.yml
cp private.example.yml private.yml
# Edit local.yml — fill in real values (domain, username, passwords)
# Edit private.yml — set homelab_ip
```

Generate the passwords in your password manager, then encrypt:

```bash
cd ~/Storage/Workspace/learn/home-lab/ansible
ansible-vault encrypt inventory/host_vars/homelab/local.yml
```

Edit or read it later:

```bash
ansible-vault edit inventory/host_vars/homelab/local.yml
ansible-vault view inventory/host_vars/homelab/local.yml  # read-only
```

**Save the vault password in your password manager.** Without it the secrets
are unrecoverable.

## Step 7 — Provision

Run phase by phase; every command needs `--ask-vault-pass`. The first `storage` run
carries `-e data_disk_force_format=true`, which lets it erase and encrypt the blank data
disk; never run it again with that flag. A fresh card listens on port 22 while the
inventory targets the hardened port: the runs up to and including `security`, which
moves sshd, carry `-e homelab_ssh_port=22`.

```bash
cd ~/Storage/Workspace/learn/home-lab/ansible

# Phase 1 — Foundations
ansible-playbook playbooks/site.yml --tags base --ask-vault-pass -e homelab_ssh_port=22
# Reboot required after base (cgroup memory for Docker)
ssh -p 22 homelab "sudo reboot"
# Wait ~30 seconds
ansible-playbook playbooks/site.yml --tags storage --ask-vault-pass -e homelab_ssh_port=22 -e data_disk_force_format=true
ansible-playbook playbooks/site.yml --tags security --ask-vault-pass -e homelab_ssh_port=22
ansible-playbook playbooks/site.yml --tags docker --ask-vault-pass
ansible-playbook playbooks/site.yml --tags observability --ask-vault-pass

# Phase 2 — Network infrastructure
ansible-playbook playbooks/site.yml --tags deploy --ask-vault-pass --extra-vars "deploy_services='traefik pihole wg-easy'"

# Phase 3 — Essential services
ansible-playbook playbooks/site.yml --tags deploy --ask-vault-pass --extra-vars "deploy_services='nextcloud nextcloud-db vaultwarden'"

# Phase 4 — Secondary services
ansible-playbook playbooks/site.yml --tags deploy --ask-vault-pass --extra-vars "deploy_services='jellyfin navidrome immich-server immich-machine-learning immich-redis immich-db'"

# Phase 5 — Observability
ansible-playbook playbooks/site.yml --tags deploy --ask-vault-pass --extra-vars "deploy_services='uptime-kuma netdata'"

# Boot orchestration and physical protections — without stack-startup the unlock brings up Tier 0 only
ansible-playbook playbooks/site.yml --tags claude-code,killswitch,usb-tamper,stack-startup --ask-vault-pass
```

Data directories come from `roles/storage/tasks/directories.yml` (top-level
tree, `media/` and `library/` subtrees, a few per-service dirs),
`roles/deploy/tasks/data_dirs.yml` (e.g. `vaultwarden`, `traefik/acme`,
`wireguard` at 0700), and Docker for the rest (root, 0755).

## Step 8 — SSH Client Configuration

Once the security role has changed the SSH port:

```bash
cat > ~/.ssh/config << 'EOF'
Host homelab
    HostName <pi-lan-ip>
    User pi
    Port <ssh_port_hardened>   # the port set in your vaulted local.yml
    IdentityFile ~/.ssh/id_ed25519

Host offsite
    HostName 10.8.0.4          # WireGuard IP — the offsite Pi has no LAN route
    User pi
    Port <ssh_port_hardened>
    IdentityFile ~/.ssh/id_ed25519
    ProxyJump homelab          # only the homelab holds the tunnel peer identity
EOF
chmod 600 ~/.ssh/config
```

```bash
ssh homelab
ssh offsite    # jumps through homelab; needs homelab-unlock done first
```

The `offsite` alias applies once the backup Pi is at its remote location; see
the [offsite backup runbook](../../knowledge/runbooks/offsite-backup.md).

## Step 9 — Post-Reboot Unlock

After every reboot the volume is locked and services are stopped. The first
unlock must come from the LAN (the VPN config is on the locked volume). Full
procedure: [boot & unlock runbook](../../knowledge/runbooks/boot-and-unlock.md).

```bash
ssh -t homelab "sudo homelab-unlock"
# Enter LUKS passphrase when prompted → /mnt/data mounted → Docker starts
```

Lock the volume and stop services. This also stops WireGuard and wg-easy, which depend on
`/mnt/data`: run it from the LAN, or you lose remote access until someone unlocks on site.

```bash
ssh homelab "sudo homelab-lock"
```

## Step 10 — Network Configuration (Phase 2)

### ISP — IPv4 Full Stack

SFR/Red boxes are often behind CGNAT (WAN IP in `10.x.x.x`), which blocks port
forwarding. Ask Red by SFR support (chat) for an **"IPv4 full stack rollback"**:
free, a few hours. Then check:

```
WAN > IPv4 > Adresse IP → should be a public IP (not 10.x.x.x)
```

### DNS (Cloudflare)

Certificates use ACME **DNS-01** ([ADR-014](../../knowledge/decisions/ADR-014-acme-dns01-cloudflare.md)),
so service subdomains need no public record; Pi-hole resolves them internally.

1. Create **one public A record**: `vpn` (WireGuard), DNS only, not proxied.
2. Create a scoped API token: My Profile → API Tokens → Create Custom Token,
   permissions `Zone:DNS:Edit` + `Zone:Read`, zone `example.com`. Store it in
   `local.yml` as `cloudflare_dns_api_token`.

- No wildcard: per-host certs leave other subdomains (personal site, Proton
  mail, GitHub Pages) untouched.
- **Do not enable the Cloudflare proxy (orange cloud)**: it breaks direct TLS
  and WireGuard.

### Port Forwarding (ISP Router)

Forward only:

| Port  | Protocol | Destination   | Purpose                                             |
|-------|----------|---------------|-----------------------------------------------------|
| 51820 | UDP      | <pi-lan-ip> | WireGuard tunnel                                    |
| 51413 | TCP/UDP  | <pi-lan-ip> | Transmission BitTorrent peer (optional — P2P connectivity) |

**Do not forward 80 or 443**: DNS-01 needs no inbound port and vpn-only would
answer 403. Public services belong on a separate, isolated system.

### Split DNS (Pi-hole)

- The `base` role disables `systemd-resolved`'s stub listener, which would
  otherwise hold port 53.
- Pi-hole resolves homelab subdomains to the Pi's LAN IP (<pi-lan-ip>), so VPN
  clients reach services directly.
- Config: `ansible/roles/deploy/templates/pihole-05-homelab.conf.j2`. It needs
  `FTLCONF_misc_etc_dnsmasq_d: "true"`, because Pi-hole v6 ignores
  `/etc/dnsmasq.d/` by default.
- The canonical list of served names is `docs/04-network/README.md`.

### WireGuard VPN — Initial Setup

The wg-easy UI (port 51821) is served by Traefik at `https://vpn.example.com`
(LAN or VPN). When Traefik is down, use an SSH tunnel:

```bash
ssh -L 51821:127.0.0.1:51821 homelab
# Then open http://localhost:51821 in your browser
```

Install the [WireGuard app](https://www.wireguard.com/install/) on your phone,
create a client in the UI and scan its QR code.

Check: on mobile data (not Wi-Fi), connect the VPN and open
`https://dns.example.com/admin/login`. Expected: the Pi-hole login page.

### Backup (Restic)

`homelab-backup.timer` runs an encrypted backup daily at 3 AM. Retention: 7
daily, 4 weekly, 6 monthly.

| Included | Source |
|----------|--------|
| Database dumps | MariaDB (Nextcloud), PostgreSQL (Miniflux), SQLite copies of small databases; Immich's own PostgreSQL dumps ride in its data |
| Service data | `/mnt/data/services` |
| Media | `/mnt/data/media` (not `/mnt/data/library`, re-downloadable, ADR-035) |
| Secrets | `/mnt/data/secrets` (ADR-011) |
| Deployment configs | `/opt/homelab` |

```bash
ssh homelab "sudo systemctl start homelab-backup.service"
```

```bash
ssh -t homelab "sudo restic -r /mnt/data/backups/restic-repo snapshots"
# Enter restic password when prompted
```

This repository shares the HDD with the data; the append-only offsite copy
(ADR-010) covers disk loss.

### Services Access Summary

All HTTPS services are VPN/LAN-only (`vpn-only` middleware on Traefik's
`websecure` entrypoint). Install-time subset; the full list is
`docs/04-network/README.md`.

| Service      | URL                     |
|--------------|-------------------------|
| Nextcloud    | `drive.example.com`     |
| Vaultwarden  | `vault.example.com`     |
| Jellyfin     | `videos.example.com`    |
| Navidrome    | `music.example.com`     |
| Immich       | `photos.example.com`    |
| Pi-hole      | `dns.example.com/admin` |
| Uptime Kuma  | `services.example.com`  |
| Netdata      | `system.example.com`    |
| WireGuard UI | `vpn.example.com` (SSH tunnel too) |

## Decisions Made

- **OS**: Ubuntu 24.04 LTS rather than 26.04 LTS (more mature on ARM64).
- **Username**: set in `local.yml`, masked as `pi` in the repo.
- **Encryption**: LUKS on the HDD only, no keyfile anywhere; the passphrase is
  typed after each reboot. No crypttab/fstab entries:
  `systemd-cryptsetup-generator` ignores `noauto` on Ubuntu, so
  `homelab-unlock` does everything explicitly.
- **Fan**: on 5V/GND (pins 4/6), full speed; no software control without a GPIO
  transistor.
- **SSH**: key-only (ed25519), vaulted non-standard port
  (`ssh_port_hardened`), LAN/VPN only. The port only cuts bot noise.
- **WireGuard UI password**: hashed by wg-easy itself with argon2.
- **VPN-only allow-list**: LAN (192.168.1.0/24), `proxy` Docker network
  (172.18.0.0/16, where full-tunnel VPN clients arrive, hairpin-NATed),
  WireGuard (10.8.0.0/24, the offsite Pi's push path). Mobile sync needs the VPN
  on.
