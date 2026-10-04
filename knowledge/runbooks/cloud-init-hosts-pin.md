# Runbook: LAN host pins disappear after a reboot

Use this page when a host-side service works after a deploy but fails after a
reboot with "Could not resolve host" or a mount error.

Some host services must resolve a homelab domain to an address inside the
allow-list (the Pi's LAN IP on the homelab, its WireGuard address on offsite).
The hosts resolve through public DNS, where only `vpn` has a record, so without
the pin the name does not resolve at all. A **403** is a different fault: the
request arrived from an address outside the `vpn-only` `ipAllowList`
([ADR-002](../decisions/ADR-002-vpn-only-by-default.md)), and re-pinning does not fix it.

| Pin        | Host        | Who needs it                    | Defined in                                          |
|------------|-------------|---------------------------------|-----------------------------------------------------|
| `drive`    | homelab     | rclone vault mount (claude)     | `ansible/roles/claude-code/tasks/vault.yml`         |
| `services` | homelab     | `backup-notify.sh` (Kuma push)  | `ansible/roles/deploy/tasks/backup.yml`             |
| `services` | **offsite** | —                               | `ansible/roles/offsite-backup/tasks/wireguard.yml`  |

## Symptom

The vault mount fails / Claude Code won't start, or the backup Kuma push fails
with curl exit 6.

```bash
getent hosts drive.<domain>      # prints nothing = the pin was wiped
```

## Cause

cloud-init (`manage_etc_hosts: True`) rebuilds `/etc/hosts` from a template on
every boot, wiping any pin written only to `/etc/hosts`.

## Fix

Each role pins in two places: `/etc/cloud/templates/hosts.debian.tmpl`
(survives reboots) and `/etc/hosts` (immediate). Re-apply with **two
playbooks**, because offsite is not in `site.yml`:

```bash
ansible-playbook playbooks/site.yml --ask-vault-pass --tags claude-code,backup
```
```bash
ansible-playbook playbooks/offsite.yml --ask-vault-pass --tags offsite-backup
```

## Check it worked

On the homelab (both must be the Pi LAN IP):

```bash
getent hosts drive.<domain> services.<domain>    # both must be the Pi LAN IP
grep -E 'drive|services' /etc/cloud/templates/hosts.debian.tmpl
```

On offsite, the half that is easy to forget:

```bash
ssh offsite "getent hosts services.<domain>; grep services /etc/cloud/templates/hosts.debian.tmpl"
```

## Related

- `notify-push-troubleshooting.md` — the same pin inside a container, set with
  `extra_hosts` instead.
