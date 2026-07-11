# Runbook: USB Tamper Response (arming, maintenance, recovery)

While armed, **any** USB plug or unplug on the Pi powers it off immediately.
Design rationale in [ADR-008](../decisions/ADR-008-usb-tamper-poweroff.md).

## Lifecycle

| State    | When                                                            |
|----------|-----------------------------------------------------------------|
| Disarmed | After every boot (flag on tmpfs), after `homelab-lock`/`-disarm` |
| Armed    | `homelab-unlock` arms it right after mounting `/mnt/data`        |

The flag is `/run/homelab/tamper-armed`; `usb-tamper.service` powers off only
if it exists. USB events are logged (`journalctl -t usb-tamper`) in both states.

## Physical maintenance (touching ANY cable or the disk)

**Disarm first — this must be a reflex:**

```bash
sudo homelab-tamper-disarm
# ... unplug/replug whatever you need ...
sudo homelab-tamper-arm
```

Forgetting the disarm = instant poweroff on the first unplug, then the full
[boot & unlock](boot-and-unlock.md) cycle. No data harm (clean shutdown), but
the lab is down until you unlock it.

## Verify

```bash
ls /run/homelab/tamper-armed          # exists = armed
journalctl -t usb-tamper -b           # every usb add/remove is logged, armed or not
```

Safe check that events flow (while **disarmed**): plug any USB device and
confirm a `usb add ...` line appears in the journal — the poweroff path is
condition-gated, so nothing else happens.

Full end-to-end test (fires a real poweroff — do it once, deliberately): arm,
plug a USB stick, watch the Pi shut down, then recover via
[boot & unlock](boot-and-unlock.md).

## Known false positive

A spontaneous USB reset of the HDD registers as `remove`+`add` and powers the
Pi off while armed. If the Pi is found off with `TRIGGER while armed` in the
journal and nobody touched it, check the disk's cabling/PSU before suspecting
an intruder — then unlock as usual.

## Related

- [ADR-008](../decisions/ADR-008-usb-tamper-poweroff.md) — design & alternatives.
- [Boot & unlock runbook](boot-and-unlock.md) — recovery path after a trigger.
- [Kill-switch runbook](kill-switch.md) — the remote sibling of this response.
