# ADR-009: Physical Attack-Surface Reduction (UART, GPIO Buses, Radios, Password)

**Date**: 2026-07-11
**Status**: Accepted — deployed and verified on the Pi the same day
**Deciders**: Marc Gavanier

## Context

The physical-intrusion review that produced [ADR-008](ADR-008-usb-tamper-poweroff.md)
also audited every other physical access path of the Pi 4. Findings:

- **UART (GPIO pins 8/10)**: a login getty was running on `ttyS0`, and the
  account password was usable — so a 2€ USB-TTL adapter gave a login prompt
  where **password auth worked**, silently bypassing the SSH key-only rule.
  Kernel boot logs and SysRq were also exposed on the serial line.
- **I2C/SPI**: enabled by the Ubuntu image defaults, used by nothing.
- **Wi-Fi / Bluetooth**: services inactive but hardware powered — re-enablable
  at runtime by any root-level software compromise.
- **Account password**: set, but with SSH key-only and `NOPASSWD` sudo it had
  no legitimate use left — while its hash sat on the unencrypted SD card,
  crackable offline.
- JTAG (full RAM/CPU access, could extract the LUKS key): already off — it
  requires `enable_jtag_gpio` in `config.txt` plus a reboot, and the reboot
  wipes the key from RAM anyway.

## Decision

Kill everything unused at the **firmware level** (`config.txt`), not in
software — a dtoverlay cannot be re-enabled at runtime even by root; undoing
it takes an SD edit plus a reboot, which destroys the key the attacker is
after. All in the `base` role:

- `enable_uart=0`, `console=serial0` removed from `cmdline.txt`,
  `serial-getty@ttyS0` masked (masked, not disabled: nothing can pull a login
  prompt back onto the serial line)
- `dtparam=i2c_arm=off`, `dtparam=spi=off`
- `dtoverlay=disable-wifi`, `dtoverlay=disable-bt` (in an explicit `[all]`
  block — a bare append would land inside the last conditional section)
- Admin account password locked (`security` role) — key-based SSH is now the
  **only** authentication path to this machine

## Consequences

### Pros
- The serial console — the one physical path where password auth still worked —
  no longer exists; neither do the radio paths a software compromise could
  have re-opened.
- With the USB tamper response (ADR-008) covering USB (including the USB-C
  OTG port), every input-capable physical port is now either dead or booby-
  trapped; remaining vectors (SD evil-maid) are handled by policy (see the
  [boot & unlock runbook](../runbooks/boot-and-unlock.md)).

### Cons
- **No emergency console.** If SSH access is lost (config error, ban, key
  loss), there is no fallback login: recovery means pulling the SD card and
  editing it on another machine. Accepted — and exercised for real on
  2026-07-11, an hour after deploying: a placeholder `ssh_allowed_users: [pi]`
  shipped `AllowUsers pi` to sshd and locked the admin out. The recovery
  procedure is now the [SSH lockout runbook](../runbooks/ssh-lockout-recovery.md).
- No Wi-Fi fallback if Ethernet dies (this box has always been Ethernet-only).

## Alternatives Considered

- **Keep the serial console as emergency access**: rejected — it was the very
  attack vector under review, and a password-authenticated one at that.
- **Software-level disabling (rfkill, service masks) for the radios**:
  rejected — reversible at runtime by exactly the attacker it should stop.
- **SysRq restriction instead of UART removal**: pointless once the serial
  line is gone; local SysRq via a USB keyboard is covered by ADR-008.
