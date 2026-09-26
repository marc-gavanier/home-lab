# shellcheck shell=bash

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

    : > "$file.new" || return 0
    for item in "$@"; do
        first=$(awk -F'\t' -v i="$item" '$2 == i { print $1; exit }' "$file" 2>/dev/null)
        [ -n "${first:-}" ] || first="$now"
        printf '%s\t%s\n' "$first" "$item" >> "$file.new"
        [ $((now - first)) -ge "$min_age" ] && printf '%s\n' "$item"
    done
    mv "$file.new" "$file"
}
