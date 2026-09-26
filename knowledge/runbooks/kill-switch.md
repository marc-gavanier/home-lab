# Runbook: Remote Kill Switch (trigger & recovery)

Use this page to power the Pi off from anywhere with a secret `ntfy.sh` message,
check the switch is armed, bring the Pi back, or change its secrets.

## Before you start

You need both secrets. They live only in the vault
(`host_vars/homelab/local.yml`) and your offline backup, never in this repo:

| Secret                  | Role                                                 |
|-------------------------|------------------------------------------------------|
| `killswitch_ntfy_topic` | the ntfy topic — gatekeeps who can publish/subscribe |
| `killswitch_keyword`    | exact message body that triggers `poweroff`          |

Keep the trigger line, with the real topic, in your offline backup.

## Trigger (power off)

1. From any device with internet (no VPN, no SSH needed):

   ```bash
   curl -d '<keyword>' https://ntfy.sh/<topic>
   ```

   Expected: within ~1–2 s the service logs `TRIGGER received — powering off now`
   and runs `systemctl poweroff`. Any other body logs `keyword mismatch — ignored`
   and does nothing.

## Recovery (power back on)

There is no remote power-on. You must be on site.

1. Restore power (plug back in, or flip the smart plug).
2. Let it boot, then unlock `/mnt/data` with the LUKS passphrase as on any boot.
3. Wait for the staged startup: DNS back ~2–3 min after the unlock, all waves
   dispatched in ~8–10 min, heavy tier (Immich, Calibre-Web, Collabora) ~20 min
   on a cold boot. Until the unlock the LAN has no DNS: point your client at
   `1.1.1.1`. Details: [boot & unlock runbook](boot-and-unlock.md).

## Verify the service is armed

Run after a deploy or reboot. Nothing powers off.

```bash
systemctl is-active killswitch.service   # active
sudo journalctl -t killswitch -n 5 -o cat
sudo ss -tnp state established '( dport = :443 )' | grep curl
```

- Only the `ss` line proves it: an established `curl` socket to ntfy means the
  stream is up. `active` and the `armed` log line are written before any
  connection, and stay unchanged while the stream is down or reconnecting.
- Use `journalctl -t killswitch`, not `-u`: the script logs through `logger`,
  and `-u` drops the `armed` line.

End-to-end test of the receive path (does **not** power off):

```bash
curl -d 'wrong-keyword-test' https://ntfy.sh/<topic>
# journal should show: message received but keyword mismatch — ignored
```

## Change the secrets

Use when the topic may have leaked.

1. Generate a new topic:

   ```bash
   openssl rand -hex 16            # new topic
   ```

2. Update both values in the vault and deploy:

   ```bash
   cd ansible && ansible-vault edit inventory/host_vars/homelab/local.yml   # update both values
   ansible-playbook playbooks/site.yml --tags killswitch --ask-vault-pass
   ```

   The `Restart killswitch` handler reloads the service (systemd reads
   `EnvironmentFile` only at start).
3. Update your offline backup.
4. Run [Verify the service is armed](#verify-the-service-is-armed).

## Related

- [ADR-006](../decisions/ADR-006-remote-kill-switch.md): design and alternatives.
- [usb-tamper runbook](usb-tamper.md): poweroff on any USB plug/unplug while
  the volume is unlocked ([ADR-008](../decisions/ADR-008-usb-tamper-poweroff.md)).
- [SSH lockout recovery](ssh-lockout-recovery.md): uses the kill switch as a
  remote clean shutdown before SD card surgery.
