#!/usr/bin/env bash
logger -t usb-tamper "usb ${ACTION:-?} ${ID_VENDOR_ID:-????}:${ID_MODEL_ID:-????} ${ID_MODEL:-unknown}"

[ -e /run/homelab/tamper-armed ] || exit 0

logger -t usb-tamper "TRIGGER while armed — requesting poweroff"

rc=0
systemctl start --no-block usb-tamper.service || rc=$?
[ "$rc" -eq 0 ] && exit 0
logger -t usb-tamper -p daemon.err "TRIGGER while armed — systemd REFUSED the response (rc=$rc); the Pi is STILL UP"
exit "$rc"
