# Runbook: SSH Lockout Recovery (no console fallback)

Since [ADR-009](../decisions/ADR-009-physical-attack-surface.md), key-based SSH
is the **only** way into the Pi: the account password is locked and the serial
console no longer exists. If sshd refuses you (bad config deployed, fail2ban
ban, lost key), this is the recovery path. Born from the real incident of
2026-07-11: a placeholder `ssh_allowed_users: [pi]` in `group_vars/all.yml`
shipped `AllowUsers pi` to sshd — locking out the actual admin user.

## 0. Check for a surviving session first

Existing SSH sessions survive an sshd restart. Any open terminal or tmux on
the Pi can fix the problem in seconds — look before touching hardware.

## 1. Clean poweroff via the kill switch

The ntfy [kill switch](kill-switch.md) runs as root on the Pi, independent of
SSH — it doubles as the remote clean-shutdown tool for offline maintenance:

```bash
curl -d '<keyword>' https://ntfy.sh/<topic>
```

Wait ~30 s (green LED stops, ping dies). The LAN loses DNS from here — point
your workstation at `1.1.1.1` meanwhile.

## 2. Edit the SD card on the workstation

Insert the SD; identify it with `lsblk -f` (vfat `system-boot` + ext4
`writable`). Mount the ext4 partition if not auto-mounted:

```bash
udisksctl mount -b /dev/mmcblk0p2
```

Fix whatever locked you out — for the 2026-07-11 incident that was:

```bash
sudo sed -i 's/^AllowUsers .*/AllowUsers <your-user>/' <mount>/etc/ssh/sshd_config
```

**Also delete `<mount>/var/lib/fail2ban/fail2ban.sqlite3`** whenever failed
logins preceded the lockout: fail2ban persists bans there and re-applies them
at boot — you can be locked out by a stale ban *even after fixing sshd*, with
no way left to unban yourself. The file is state only; fail2ban recreates it.

## 3. Unmount cleanly, boot, unlock

```bash
udisksctl unmount -b /dev/mmcblk0p2 && udisksctl unmount -b /dev/mmcblk0p1
```

SD back in the Pi, power on, SSH in, then the normal
[boot & unlock](boot-and-unlock.md) procedure. This poweroff is *explained*,
so the evil-maid reflash policy does not apply.

## 4. Fix the root cause in the repo

The SD edit is a hotfix; make Ansible converge to the same state (and check
`--tags security` renders what you expect **before** the handler restarts
sshd). Placeholders that feed `sshd_config` are lockout bugs waiting to fire.

## Related

- [ADR-009](../decisions/ADR-009-physical-attack-surface.md) — why there is no console fallback.
- [Kill-switch runbook](kill-switch.md) — trigger details and secrets.
- [Boot & unlock runbook](boot-and-unlock.md) — the post-boot path.
