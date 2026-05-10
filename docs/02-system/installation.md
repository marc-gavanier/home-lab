# Installation Guide

Step-by-step installation of the home lab from scratch.

## Prerequisites (workstation)

- Linux workstation with SSH key pair (`~/.ssh/id_ed25519`)
- Raspberry Pi Imager (`sudo apt install rpi-imager`)
- Ansible (`pipx install ansible --include-deps`)
- nmap for network discovery (`sudo apt install nmap`)
- SD card reader

## Step 1 — Flash the SD Card

Using Raspberry Pi Imager:

1. **Device**: Raspberry Pi 4
2. **OS**: Ubuntu Server 24.04 LTS (64-bit)
3. **Storage**: 64 GB SD card

Customization settings (click "Edit Settings" before flashing):

| Setting         | Value                                             |
|-----------------|---------------------------------------------------|
| Hostname        | `homelab`                                         |
| Username        | `marc-gavanier`                                   |
| Password        | Set a temporary password (will be disabled later) |
| Locale/Timezone | `Europe/Paris`, keyboard `fr`                     |
| SSH             | Enabled, public-key authentication only           |
| SSH public key  | Content of `~/.ssh/id_ed25519.pub`                |
| Telemetry       | Disabled                                          |
| Wi-Fi           | Not configured (Ethernet only)                    |

> **Important**: "Set username and password" must be enabled for the user account to be created. Without it, the SSH key has no user to attach to.

Flash and wait for write + verification to complete.

Eject the SD card:
```bash
sudo umount /dev/mmcblk0p1 /dev/mmcblk0p2 2>/dev/null
sync
# Then physically remove the card
```

## Step 2 — First Boot

1. Insert the SD card into the Pi
2. Connect: Ethernet cable, 5TB HDD (USB 3.0 blue port), power supply (last)
3. Wait ~2 minutes for first boot to complete
4. Find the Pi's IP address:

```bash
nmap -sn 192.168.1.0/24
```

Look for the host named `homelab`.

## Step 3 — Verify SSH Access

```bash
ssh marc-gavanier@<PI_IP>
```

Should connect without password prompt (key-based auth). If it works, you'll see the Ubuntu welcome message with system info.

## Step 4 — Configure Static IP

Set a DHCP static lease on the ISP router to ensure the Pi always gets the same IP address.

1. Open the router admin panel (192.168.1.1)
2. Navigate to **LAN > Baux statiques** (static leases)
3. Add a new static lease:
   - **MAC address**: get it from the Pi with `ip link show eth0 | grep ether`
   - **IP address**: choose an IP outside the dynamic DHCP range (e.g. `192.168.1.100`)
4. Reboot the Pi to apply: `sudo reboot`
5. Verify the new IP: `ssh marc-gavanier@192.168.1.100`
6. Clean up old SSH host key: `ssh-keygen -R <OLD_IP>`

> **Note**: if the router says "IP already in use", pick an IP outside the dynamic pool (lower range like .10-.50 or use .100).

## Step 5 — Verify Ansible Connectivity

```bash
cd ~/Storage/Workspace/learn/home-lab/ansible
ansible homelab -m ping
```

Expected output:
```
homelab | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

Verify HDD is detected:
```bash
ansible homelab -m command -a "lsblk"
```

Expected: `/dev/sda` with a `sda1` partition (~4.5T).

## Step 6 — Provision

Run phase by phase:
```bash
cd ~/Storage/Workspace/learn/home-lab/ansible

# Phase 1 — Foundations
ansible-playbook playbooks/site.yml --tags base
# Reboot required after base (cgroup memory for Docker)
ssh marc-gavanier@192.168.1.100 "sudo reboot"
# Wait ~30 seconds
ansible-playbook playbooks/site.yml --tags storage --extra-vars "luks_passphrase='YOUR_STRONG_PASSPHRASE'"
ansible-playbook playbooks/site.yml --tags security
ansible-playbook playbooks/site.yml --tags docker

# Phase 2-5 — Services
ansible-playbook playbooks/site.yml --tags deploy
```

> **Important**: The `storage` role requires a LUKS passphrase passed via `--extra-vars` (single quotes around it to avoid shell interpolation of special characters). This passphrase is never stored in the repo. Store it in a password manager — you'll need it after every reboot.

> **Note**: The `storage` role only creates top-level directories (`services/`, `media/`, `backups/`). Per-service subdirectories are created automatically by Docker via volume mounts at first start.

## Step 7 — SSH Client Configuration

After the security role changes the SSH port, configure your workstation for easy access:

```bash
cat > ~/.ssh/config << 'EOF'
Host homelab
    HostName 192.168.1.100
    User marc-gavanier
    Port 21202
    IdentityFile ~/.ssh/id_ed25519
EOF
chmod 600 ~/.ssh/config
```

Then connect with just:
```bash
ssh homelab
```

## Step 8 — Post-Reboot Unlock

After every reboot, the Pi boots normally but services are stopped and the data volume is locked. To unlock:

```bash
ssh homelab "sudo homelab-unlock"
# Enter LUKS passphrase when prompted → /mnt/data mounted → Docker starts
```

To lock the volume and stop services:
```bash
ssh homelab "sudo homelab-lock"
```

### Boot Flow

```
Power on → Ubuntu boots (SD, unencrypted) → SSH available
                                                 │
                                        User runs: ssh homelab "sudo homelab-unlock"
                                                 │
                                        Enter passphrase → /mnt/data mounted → Docker starts
```

## Decisions Made

- **OS**: Ubuntu Server 24.04 LTS over 26.04 LTS (more mature, 2 years of bug fixes, better ARM64 community support)
- **Username**: `marc-gavanier` (same as workstation for consistency)
- **Encryption**: LUKS on HDD (data) only, not on SD card (OS). No keyfile stored anywhere — passphrase required via SSH after each reboot. Trade-off: requires manual intervention after power loss, but no key material on disk. No crypttab/fstab entries — `systemd-cryptsetup-generator` ignores `noauto` on Ubuntu, so `homelab-unlock` handles everything explicitly.
- **Fan**: Connected to 5V/GND (pins 4/6), runs at full speed. No software control possible without rewiring to a GPIO pin with transistor.
- **Telemetry**: Disabled (Canonical telemetry opt-out)
- **SSH**: Public-key only (ed25519), non-standard port 21202. Not exposed to internet — remote access via WireGuard VPN only.
- **SSH port**: 21202 (avoids bot noise on 22; classic alternatives like 2222 are also scanned). Real security comes from key-only auth + fail2ban, not the port.
- **IP assignment**: Static DHCP lease on router (192.168.1.100)
- **Docker**: Does not auto-start at boot. Started by `homelab-unlock` after LUKS volume is opened.
- **Remote access**: All remote access goes through WireGuard VPN (port 51820/udp). SSH is LAN/VPN only, never directly exposed to internet.
