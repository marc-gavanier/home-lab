# shellcheck shell=bash
# =============================================================================
# Home Lab — persistence gate for host checks (ADR-030)
# =============================================================================
# One mechanism, sourced by the check scripts, replacing the per-condition
# stamp files each of them grew its own version of.
#
# --- The problem it solves, with the measurement that defines it -------------
# A check that runs every five minutes and reports what it sees at that instant
# alarms on things that are merely in progress. Docker restarted on 2026-08-16
# at 21:36:23 and was up at 21:37:02 — 39 seconds where `systemctl is-active`
# does not say "active". A run landing in that window has a 13% chance
# (39s of 300s) of reporting an outage that resolved itself before anyone read
# the notification. That breaks this stack's own rule: one alert, one action.
#
# The cure every check invented separately is a grace period: remember when the
# condition was FIRST seen, and only report it once it has held. homelab-health.sh
# alone carries seven implementations of that idea, in two shapes — an age since
# a single episode stamp, and a set intersected with the previous run's set.
#
# --- Why this is not the netdata alarm we would rather have ------------------
# A time-series engine expresses this in one word: `lookup: min -10m of failed`
# carries its own memory. netdata's systemdunits collector would therefore
# retire this whole file — except that it reaches systemd ONLY through
# /run/systemd/private (measured 2026-08-23: with the system bus mounted and
# nothing else, it fails identically to having no socket at all). That socket is
# systemd's unauthenticated control channel, and mounting it would give the
# monitoring container the reach to start units on the host, outside its own
# AppArmor profile and capability set. The checks here read unit state through
# `systemctl`, which polkit grants to `nobody` — verified. Trading a correct
# privilege for a query language is a bad trade, so the memory stays here.
#
# --- Semantics ---------------------------------------------------------------
#   gate KEY MIN_AGE [item...]
#
# Prints, one per line, the items present on THIS call that have also been
# present on every previous call for at least MIN_AGE seconds. Items missing
# from a call are forgotten, so a condition that clears resets its clock. With
# no items at all the key is cleared.
#
# Per ITEM and not per episode, which is a deliberate difference from the code
# it replaces: homelab-health.sh stamps the first moment ANY container went
# unhealthy and then reports every later one on that same clock, so a container
# failing at minute nine is reported at minute ten with no grace period of its
# own. Here each item carries its own first sighting.
#
# Time-based rather than run-based, also deliberately. The stamps it replaces
# report on the second consecutive sighting whenever that happens; their own
# comments describe the intent as "sustained for >5 min". A missed or manual run
# should not change the verdict, so the verdict is expressed in seconds.
#
# Items are shell words: no tabs, no newlines. Every caller passes unit names,
# container names or fixed tokens, so this is a documented limit, not a check.
# =============================================================================

HOMELAB_GATE_DIR="${HOMELAB_GATE_DIR:-/var/lib/homelab-gate}"

gate() {
    local key="$1" min_age="$2"
    shift 2
    local file="$HOMELAB_GATE_DIR/$key"

    if [ "$#" -eq 0 ]; then
        rm -f "$file"
        return 0
    fi

    mkdir -p "$HOMELAB_GATE_DIR" || return 0
    local now item first
    now=$(date +%s)

    # Written to a temporary and moved, so a run interrupted midway leaves the
    # previous state intact rather than a half-written one: a truncated state
    # file would silently reset every clock it holds.
    : > "$file.new" || return 0
    for item in "$@"; do
        first=$(awk -F'\t' -v i="$item" '$2 == i { print $1; exit }' "$file" 2>/dev/null)
        [ -n "${first:-}" ] || first="$now"
        printf '%s\t%s\n' "$first" "$item" >> "$file.new"
        [ $((now - first)) -ge "$min_age" ] && printf '%s\n' "$item"
    done
    mv "$file.new" "$file"
}
