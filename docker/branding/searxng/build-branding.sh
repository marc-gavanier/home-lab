#!/usr/bin/env bash
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
BRANDING="${SEARXNG_BRANDING:-false}"
IMAGE="${SEARXNG_IMAGE:-searxng/searxng:latest}"
LOGO="${SEARXNG_LOGO:-}"
OUT="${OUT_DIR:-$SRC/out}"
THEME="/usr/local/searxng/searx/static/themes/simple"

command -v brotli >/dev/null 2>&1 || { echo "✗ brotli is required (apt install brotli)"; exit 1; }

mkdir -p "$OUT"
TMP="$OUT/.sxng-ltr.min.css.new"
trap 'rm -f "$TMP"' EXIT

echo "→ Extracting base CSS from ${IMAGE}"
docker run --rm --entrypoint cat "$IMAGE" "${THEME}/sxng-ltr.min.css" > "$TMP"

if [ "$BRANDING" != "true" ]; then
    echo "→ SEARXNG_BRANDING != true — emitting stock CSS (no overrides, mount is a no-op)"
else
    echo "→ Appending Gerbier colour overrides"
    printf '\n' >> "$TMP"
    cat "$SRC/overrides.css" >> "$TMP"

    if [ -n "$LOGO" ]; then
        [ -f "$LOGO" ] || { echo "✗ SEARXNG_LOGO set but file not found: $LOGO"; exit 1; }
        case "$LOGO" in
            *.svg) mime="image/svg+xml" ;;
            *.png) mime="image/png" ;;
            *) echo "✗ unsupported logo type (use .svg or .png): $LOGO"; exit 1 ;;
        esac
        echo "→ Embedding logo ${LOGO} (${mime}) as a data-URI on .index .title"
        b64="$(base64 -w0 "$LOGO")"
        printf '\n.index .title{min-height:8rem;background-image:url("data:%s;base64,%s")}\n' "$mime" "$b64" >> "$TMP"
    else
        echo "→ No logo configured (SEARXNG_LOGO empty) — keeping the stock logo"
    fi
fi

if [ -f "$OUT/sxng-ltr.min.css" ] && cmp -s "$TMP" "$OUT/sxng-ltr.min.css"; then
    echo "✓ CSS identical to the deployed build — nothing to rewrite"
    echo "BRANDING_RESULT=unchanged"
    exit 0
fi

echo "→ Refreshing CSS + precompressed variants (.br/.gz)"
cat "$TMP" > "$OUT/sxng-ltr.min.css"
brotli -q 11 -c "$OUT/sxng-ltr.min.css" > "$TMP" && cat "$TMP" > "$OUT/sxng-ltr.min.css.br"
gzip -9 -n -c "$OUT/sxng-ltr.min.css" > "$TMP" && cat "$TMP" > "$OUT/sxng-ltr.min.css.gz"

echo "✓ Branded CSS ready in ${OUT}"
echo "BRANDING_RESULT=updated"
ls -la "$OUT"
