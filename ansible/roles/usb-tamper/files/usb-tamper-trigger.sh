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

# The armed check is DUPLICATED here, and the duplication is the point. It also
# lives in the unit as ConditionPathExists, but a unit start can be refused by
# systemd BEFORE its condition is ever evaluated — so on the one recorded
# occasion the response was actually due (2026-09-01, three events while
# armed), nothing said so. `TRIGGER while armed` had never been written once in
# the whole retained journal, while `usb-tamper.md` makes that exact line the
# discriminant between "disk failure" and "someone touched the machine".
# Writing it here means it appears whenever the response is DUE, independently
# of whether it then RUNS.
[ -e /run/homelab/tamper-armed ] || exit 0

logger -t usb-tamper "TRIGGER while armed — requesting poweroff"

# Still delegated rather than executed here: udev kills long-running RUN
# programs, which is why the poweroff lives in the unit. What changed is that
# the refusal is now caught and named instead of leaving a bare exit code.
# `rc=$?` after an if/fi would read 0, because a taken-no-branch `if` returns
# success — which would have made this very message lie about the refusal it
# exists to report.
rc=0
systemctl start --no-block usb-tamper.service || rc=$?
[ "$rc" -eq 0 ] && exit 0
logger -t usb-tamper -p daemon.err "TRIGGER while armed — systemd REFUSED the response (rc=$rc); the Pi is STILL UP"
exit "$rc"
