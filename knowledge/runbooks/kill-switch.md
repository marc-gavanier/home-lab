# Runbook: Remote Kill Switch (trigger & recovery)

Power the Pi off from anywhere via a secret `ntfy.sh` message, then bring it back.
Design rationale in [ADR-006](../decisions/ADR-006-remote-kill-switch.md).

The two secrets live **only** in the vault (`host_vars/homelab/local.yml`) and on
your off-network paper backup — never in this repo:

| Secret                  | Role                                                 |
|-------------------------|------------------------------------------------------|
| `killswitch_ntfy_topic` | the ntfy topic — gatekeeps who can publish/subscribe |
| `killswitch_keyword`    | exact message body that triggers `poweroff`          |

## Trigger (power off)

From **any** device with internet — a phone, a borrowed laptop — no VPN, no SSH:

```bash
curl -d '<keyword>' https://ntfy.sh/<topic>
```

Within ~1–2 s the service logs `TRIGGER received — powering off now` and runs
`systemctl poweroff`. Any message body that is **not** an exact match is logged as
`keyword mismatch — ignored` and does nothing.

> Keep the trigger line (with the real topic) on your paper backup — the topic
> alone is useless without the keyword, but you cannot publish without it.

## Recovery (power back on)

There is **no remote power-on** by design. Recovery requires physical presence:

1. Restore power to the Pi (plug it back / flip the smart plug).
2. Let it boot. Unlock the encrypted data volume (`/mnt/data`) as on any boot —
   LUKS passphrase.
3. The Docker stack restarts on its own (`restart: unless-stopped`).

## Verify the service is armed

After a deploy or reboot, confirm it's listening (no poweroff involved):

```bash
systemctl is-active killswitch.service        # active
journalctl -u killswitch.service -n 5 -o cat  # "armed — listening on ntfy topic (outbound)"
```

Safe end-to-end test (does **not** power off) — publish a deliberately wrong body:

```bash
curl -d 'wrong-keyword-test' https://ntfy.sh/<topic>
# journal should show: message received but keyword mismatch — ignored
```

## Change the secrets

Rotate the topic/keyword (e.g. if the topic may have leaked):

```bash
openssl rand -hex 16            # new topic
cd ansible && ansible-vault edit inventory/host_vars/homelab/local.yml   # update both values
ansible-playbook playbooks/site.yml --tags killswitch --ask-vault-pass
```

The `Restart killswitch` handler picks up the new env on a running service
(systemd reads `EnvironmentFile` only at start). **Update your paper backup.**

## Related

- [ADR-006](../decisions/ADR-006-remote-kill-switch.md) — design & alternatives.
- Reboot caveat: cutting the Pi takes LAN DNS down ~15 min while the full stack
  restarts; don't `docker restart`/reboot to "fix" a slow boot (it self-heals).
  Workaround during the outage: point the client DNS at `1.1.1.1`.