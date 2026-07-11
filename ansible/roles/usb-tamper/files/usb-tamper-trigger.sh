#!/usr/bin/env bash
# =============================================================================
# Home Lab — USB tamper trigger (called by udev, see 99-usb-tamper.rules)
# =============================================================================
# Runs on EVERY usb_device add/remove event. udev kills long-running RUN
# programs, so this only logs the event and hands off to usb-tamper.service —
# the armed check (ConditionPathExists=/run/homelab/tamper-armed) and the
# poweroff live there. While disarmed the event is still logged (audit trail)
# and the service start is a no-op.
# =============================================================================
logger -t usb-tamper "usb ${ACTION:-?} ${ID_VENDOR_ID:-????}:${ID_MODEL_ID:-????} ${ID_MODEL:-unknown}"
exec systemctl start --no-block usb-tamper.service
