# Runbook: SSH Lockout Recovery (no console fallback)

Use this page when sshd refuses you (bad config deployed, fail2ban ban, lost key).
Key-based SSH is the only way into the Pi: the account password is locked and
there is no serial console ([ADR-009](../decisions/ADR-009-physical-attack-surface.md)).

## Before you start

Look for a surviving session first. Existing SSH sessions survive an sshd
restart; any open terminal or tmux on the Pi can fix the problem in seconds.

## Steps

1. **Power off cleanly with the [kill switch](kill-switch.md).** It runs as root,
   independent of SSH:

   ```bash
   curl -d '<keyword>' https://ntfy.sh/<topic>
   ```

   Expected: after ~30 s the green LED stops and ping dies. The LAN loses DNS:
   point your workstation at `1.1.1.1`.
2. **Mount the SD card on the workstation.** Identify it with `lsblk -f` (vfat
   `system-boot` + ext4 `writable`), then mount the ext4 partition if needed:

   ```bash
   udisksctl mount -b /dev/mmcblk0p2
   ```

3. **Fix what locked you out.** Example, a wrong `AllowUsers`:

   ```bash
   sudo sed -i 's/^AllowUsers .*/AllowUsers <your-user>/' <mount>/etc/ssh/sshd_config
   ```

4. **If failed logins preceded the lockout, delete
   `<mount>/var/lib/fail2ban/fail2ban.sqlite3`.** fail2ban re-applies saved bans
   ~30 s after the unlock, locking you out again even with sshd fixed. The file
   is state only; fail2ban recreates it.
5. **Unmount cleanly:**

   ```bash
   udisksctl unmount -b /dev/mmcblk0p2 && udisksctl unmount -b /dev/mmcblk0p1
   ```

6. **Boot and unlock.** SD back in the Pi, power on, SSH in, then follow
   [boot & unlock](boot-and-unlock.md). This poweroff is explained, so the
   evil-maid reflash policy does not apply.
7. **Fix the root cause in the repo.** Make Ansible converge to the same state,
   and check what `--tags security` renders **before** the handler restarts
   sshd. Placeholders that feed `sshd_config` cause lockouts.

## Check it worked

SSH in normally from your workstation.

## Related

- [ADR-009](../decisions/ADR-009-physical-attack-surface.md): why there is no console fallback.
- [Kill-switch runbook](kill-switch.md): trigger details and secrets.
- [Boot & unlock runbook](boot-and-unlock.md): the post-boot path.
