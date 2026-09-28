# Runbook: USB Tamper Response (arming, maintenance, recovery)

Use this page before touching any cable on the homelab Pi, and after a poweroff
you suspect was a USB trigger. While armed, **any** USB plug or unplug powers the
Pi off immediately.

## Before you start

| State    | When                                                            |
|----------|-----------------------------------------------------------------|
| Disarmed | After every boot (flag on tmpfs), after `homelab-lock`/`-disarm` |
| Armed    | `homelab-unlock` arms it right after mounting `/mnt/data`        |

The flag is `/run/homelab/tamper-armed`; `usb-tamper.service` powers off only
if it exists. USB events are logged in both states.

## Physical maintenance (touching ANY cable or the disk)

**Disarm first, every time.** Forgetting means an instant clean poweroff and a
full [boot & unlock](boot-and-unlock.md) cycle.

```bash
sudo homelab-tamper-disarm
# ... unplug/replug whatever you need ...
sudo homelab-tamper-arm
```

## Verify

```bash
ls /run/homelab/tamper-armed          # exists = armed
journalctl -t usb-tamper -b           # every usb add/remove is logged, armed or not
```

- Safe check (while **disarmed**): plug any USB device; a `usb add ...` line
  appears in the journal and nothing else happens.
- End-to-end test (a real poweroff, do it once, deliberately): arm, plug a USB
  stick, watch the Pi shut down, recover via [boot & unlock](boot-and-unlock.md).

## After a poweroff: tamper or false positive?

A spontaneous USB reset of the HDD registers as `remove`+`add` and powers the Pi
off while armed. The persistent journal lives on the encrypted volume, but rsyslog also writes the
`usb-tamper` lines to `/var/log/syslog` on the card, readable before the unlock:

```bash
ssh homelab 'sudo grep usb-tamper /var/log/syslog'
```

A `usb remove` then `usb add` of the disk's vendor:model just before `TRIGGER while armed` is a
USB reset. No line proves nothing: that file is written asynchronously and the poweroff can beat it.

| What you know | Action |
|---------------|--------|
| Someone touched a cable, or the disk's cabling/PSU is visibly at fault | Unlock as usual |
| Nothing explains the poweroff | Treat it as tampering: reflash the SD and re-provision **before** unlocking (step 2 of [boot & unlock](boot-and-unlock.md)) |

Once unlocked, confirm a false positive with `journalctl -t usb-tamper -b -1`.

Why: [ADR-008](../decisions/ADR-008-usb-tamper-poweroff.md). Remote sibling:
[kill-switch runbook](kill-switch.md).
