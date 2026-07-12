#!/usr/bin/env bash
#
# build-branding.sh — produce the Gerbier-branded stylesheet to bind-mount over
# the stock SearXNG "simple" theme.
#
# Strategy (see overrides.css for the "why"):
#   1. Extract the *current image's* compiled CSS   → stays in sync with `latest`
#   2. Append our Gerbier --color-* overrides        → recolor only, no templates
#   3. Optionally embed a logo as a data-URI         → only if SEARXNG_LOGO is set
#   4. Regenerate the .br/.gz siblings               → SearXNG serves precompressed
#
# The base CSS is re-extracted from the image on every build, so a `docker pull`
# + rebuild picks up upstream changes automatically; only our small override
# block is carried across versions (CSS variable names are stable).
#
# The logo is embedded straight into the CSS (data-URI), so there is no image
# file to mount: with no logo set, nothing is added and the stock logo is kept.
#
# Branding is opt-in: with SEARXNG_BRANDING != "true" the script emits the stock
# CSS untouched, so the (always-present) bind-mount is a no-op and SearXNG stays
# vanilla. Set it to "true" to apply the Gerbier theme.
#
# Run where the image is available (the Pi, via the deploy role).
# Requires docker, brotli, gzip. Env:
#   SEARXNG_BRANDING  "true" to apply the Gerbier theme  (default: false = stock)
#   SEARXNG_IMAGE     image to read the base CSS from     (default searxng/searxng:latest)
#   SEARXNG_LOGO      path to a .svg/.png logo, or empty  (default: keep stock logo)
#   OUT_DIR           output directory                    (default ./out)
#
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
BRANDING="${SEARXNG_BRANDING:-false}"
IMAGE="${SEARXNG_IMAGE:-searxng/searxng:latest}"
LOGO="${SEARXNG_LOGO:-}"
OUT="${OUT_DIR:-$SRC/out}"
THEME="/usr/local/searxng/searx/static/themes/simple"

command -v brotli >/dev/null 2>&1 || { echo "✗ brotli is required (apt install brotli)"; exit 1; }

mkdir -p "$OUT"

echo "→ Extracting base CSS from ${IMAGE}"
docker run --rm --entrypoint cat "$IMAGE" "${THEME}/sxng-ltr.min.css" > "$OUT/sxng-ltr.min.css"

if [ "$BRANDING" != "true" ]; then
    echo "→ SEARXNG_BRANDING != true — emitting stock CSS (no overrides, mount is a no-op)"
else
    echo "→ Appending Gerbier colour overrides"
    printf '\n' >> "$OUT/sxng-ltr.min.css"
    cat "$SRC/overrides.css" >> "$OUT/sxng-ltr.min.css"

    if [ -n "$LOGO" ]; then
        [ -f "$LOGO" ] || { echo "✗ SEARXNG_LOGO set but file not found: $LOGO"; exit 1; }
        case "$LOGO" in
            *.svg) mime="image/svg+xml" ;;
            *.png) mime="image/png" ;;
            *) echo "✗ unsupported logo type (use .svg or .png): $LOGO"; exit 1 ;;
        esac
        echo "→ Embedding logo ${LOGO} (${mime}) as a data-URI on .index .title"
        b64="$(base64 -w0 "$LOGO")"
        # Match the stock homepage selector `.index .title` (specificity 0,2,0) so we
        # override it and don't leak the logo onto other `.title` elements. min-height
        # drives the logo size (background-size:contain fits the box height).
        printf '\n.index .title{min-height:8rem;background-image:url("data:%s;base64,%s")}\n' "$mime" "$b64" >> "$OUT/sxng-ltr.min.css"
    else
        echo "→ No logo configured (SEARXNG_LOGO empty) — keeping the stock logo"
    fi
fi

echo "→ Regenerating precompressed variants (.br/.gz)"
brotli -f -q 11 -k "$OUT/sxng-ltr.min.css"
gzip  -f -9 -k "$OUT/sxng-ltr.min.css"

echo "✓ Branded CSS ready in ${OUT}"
ls -la "$OUT"
