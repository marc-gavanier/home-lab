# Runbook: LAN host pins disappear after a reboot

Some host-side services must resolve a homelab domain to the **Pi's LAN IP**, not
the public IP, to avoid the DNS hairpin (out through NAT, back to Traefik with an
external source IP → rejected **403** by the vpn-only `ipAllowList`, see
[ADR-002](../decisions/ADR-002-vpn-only-by-default.md)). Two such pins exist:

| Domain              | Who needs it    | Why                                    |
|---------------------|-----------------|----------------------------------------|
| `drive.<domain>`    | rclone (claude) | vault WebDAV mount → Claude Code       |
| `services.<domain>` | `backup.sh`     | Uptime Kuma push for backup monitoring |

## Symptom

Works right after a deploy, then **breaks after a reboot** (e.g. a power cut): the
vault mount fails / Claude Code won't start, or the backup Kuma push 403s.

```bash
getent hosts drive.example.com      # shows the PUBLIC ip = the pin was wiped
```

## Cause

This host is **cloud-init managed** (`manage_etc_hosts: True`). cloud-init
**regenerates `/etc/hosts` from a template on every boot**, wiping any plain
`lineinfile` pin written directly into `/etc/hosts`.

## Fix

Pin in **two** places (both roles already do this):

1. `/etc/cloud/templates/hosts.debian.tmpl` — the template cloud-init rebuilds from,
   so the pin **survives reboots**.
2. `/etc/hosts` directly — **immediate**, no reboot needed.

Defined in `ansible/roles/claude-code/tasks/main.yml` (`drive`) and
`ansible/roles/deploy/tasks/main.yml` (`services`). Re-apply with:

```bash
ansible-playbook playbooks/site.yml --tags claude-code,deploy
```

## Verify

```bash
getent hosts drive.example.com services.example.com    # both must be the Pi LAN IP
grep -E 'drive|services' /etc/cloud/templates/hosts.debian.tmpl
```

## Related

- [ADR-002](../decisions/ADR-002-vpn-only-by-default.md) — why the hairpin 403s.
- `notify-push-troubleshooting.md` — the same hairpin hitting Nextcloud's notify_push,
  fixed differently (container `extra_hosts`, since it's resolved *inside* a container).
