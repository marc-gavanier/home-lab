# ADR-008: USB Tamper Response — Poweroff on Any USB Event

**Date**: 2026-07-08
**Status**: Accepted
**Deciders**: Marc Gavanier

## Context

The Pi's setup is discussed publicly (social media), which makes it a plausible
target for a "for sport" physical intrusion. The perimeter (ADR-002) covers the
network; the LUKS encryption covers the powered-off state. The remaining gap is
the **powered-on, unlocked** state: the LUKS volume key sits in RAM, and the
machine has physical ports.

Realistic physical attacks on a running Pi 4:
- **BadUSB / HID injection**: a device that enumerates as a keyboard and types
  into the local console. USB on the Pi 4 carries no DMA (no Thunderbolt/PCIe),
  so a USB device cannot read RAM directly — keystroke injection is the threat.
- **Hardware substitution**: unplug the data disk (or another device) and plug
  something else in its place.
- Console access via UART on the GPIO header — out of scope here; closed by
  [ADR-009](ADR-009-physical-attack-surface.md): serial emits no udev event,
  so this response would never see it.

The remote kill switch (ADR-006) already established poweroff as the safe state
and the manual-recovery model. What is missing is an **automatic local trigger**
on physical tampering.

## Decision

A udev rule fires on **every** USB device `add` **or** `remove` event and runs
`systemctl poweroff` — but only while the system is **armed**.

- **Trigger**: `SUBSYSTEM=="usb", DEVTYPE=="usb_device", ACTION=="add|remove"`
  → a short udev script logs the event and starts `usb-tamper.service`
  (non-blocking; udev kills long-running RUN programs).
- **No device whitelist**: USB vendor/product IDs are trivially spoofable, so a
  whitelist only stops the laziest attacker while adding a bypass for prepared
  ones. Any device, any direction, triggers.
- **Armed flag on tmpfs** (`/run/homelab/tamper-armed`), checked by the service
  via `ConditionPathExists`. `/run` starts empty on every boot, so the udev
  coldplug replay at boot (which re-emits `add` for every present device) can
  never fire the response. Events are still logged while disarmed (audit trail).
- **Arming is automatic**: `homelab-unlock` arms right after mounting the
  volume — protection starts the moment the key enters RAM. `homelab-lock`
  disarms first. `homelab-tamper-arm` / `homelab-tamper-disarm` cover physical
  maintenance (touching cables, moving the disk).
- **Response is poweroff**, reusing the ADR-006 model: RAM (and the LUKS key)
  is gone, recovery is physical presence + passphrase. Ethernet and HDMI are
  deliberately **not** monitored (see alternatives).

## Consequences

### Pros
- **Closes the unlocked-state gap**: plugging a BadUSB device or pulling the
  disk yields a dead machine with an encrypted disk, not a live console.
- **Whitelist-free means bypass-free** (on the USB vector): there is no "right"
  device an attacker could present.
- **Boot-safe by construction**: the tmpfs flag makes the coldplug replay inert
  without any timing heuristics.
- **Small and legible**: one udev rule, one oneshot service, two flag commands.

### Cons
- **False positives power the lab off.** A spontaneous USB reset of the HDD
  (it happens) is a `remove`+`add` and takes the Pi down until someone runs
  `homelab-unlock`. Accepted: a disconnected data disk means a broken lab
  anyway, and a clean poweroff is close to the right response.
- **Physical maintenance needs discipline**: touching any USB cable while armed
  = instant poweroff. The disarm command must become a reflex (runbook).
- **Not a full physical-security story**: no protection against power cut plus
  SD-card tampering (evil-maid on the unencrypted OS), UART console access, or
  an attacker content with just stealing the hardware. It specifically defends
  the key-in-RAM window against the USB vector.

### Recovery model
Identical to ADR-006: no remote power-on; restore power, unlock with the LUKS
passphrase, staged startup brings services back.

## Alternatives Considered

- **Whitelist known devices (by vendor/product ID)**: rejected — IDs are
  spoofable in firmware, and the legitimate disk's own resets would look like
  foreign events anyway. A whitelist adds complexity and an attacker path.
- **Also trigger on Ethernet link changes**: rejected — a router or switch
  reboot is a link down/up, which would power the lab off overnight for a
  common, benign event. The Ethernet threat (network access) is already the
  perimeter's job (ADR-002), not a physical-tamper signal.
- **Also trigger on HDMI hotplug**: rejected — DRM hotplug events are flaky on
  a headless Pi, and a display is output-only; the input path of a console
  attack is USB, which is covered.
- **usbguard (block unauthorized devices instead of poweroff)**: rejected — it
  answers a different question. Blocking a rogue device leaves the key in RAM
  and does nothing when the disk is *removed*; it also reintroduces a whitelist.
- **Soft response (`homelab-lock` instead of poweroff)**: rejected — stopping
  the stack, unmounting, and closing LUKS takes tens of seconds during which
  the machine is live, and it fights the heal timer. Poweroff is faster,
  simpler, and already the established safe state.
