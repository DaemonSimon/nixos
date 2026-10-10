#!/usr/bin/env bash
#
# Rebuild Vesktop's custom Vencord directory and append the control bridge.
#
# Vesktop loads Vencord from a directory of its choosing. We keep a custom
# copy (sessionData/vencordFiles + our bridge) and point Vesktop at it.
# Run this again whenever Vesktop/Vencord updates, so the bridge is applied to
# the new bundle.
#
set -euo pipefail

VESKTOP_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/vesktop"
VENCORD_FILES="$VESKTOP_CONFIG/sessionData/vencordFiles"
CUSTOM_DIR="$VESKTOP_CONFIG/vencord-custom"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BRIDGE="$SCRIPT_DIR/vencord-bridge.js"

if [ ! -f "$VENCORD_FILES/vencordDesktopMain.js" ]; then
    echo "error: no Vencord files found in $VENCORD_FILES" >&2
    echo "Open Vesktop once so it can download Vencord, then retry." >&2
    exit 1
fi

echo "Rebuilding $CUSTOM_DIR from $VENCORD_FILES"
mkdir -p "$CUSTOM_DIR"
cp "$VENCORD_FILES/vencordDesktopMain.js" \
   "$VENCORD_FILES/vencordDesktopPreload.js" \
   "$VENCORD_FILES/vencordDesktopRenderer.js" \
   "$VENCORD_FILES/vencordDesktopRenderer.css" \
   "$VENCORD_FILES/package.json" \
   "$CUSTOM_DIR/"

# Keep a pristine copy of the upstream bundle for reference/diffing.
cp "$CUSTOM_DIR/vencordDesktopMain.js" "$CUSTOM_DIR/vencordDesktopMain.js.orig"

# Append the bridge.
cat "$BRIDGE" >> "$CUSTOM_DIR/vencordDesktopMain.js"

if command -v node >/dev/null 2>&1; then
    node --check "$CUSTOM_DIR/vencordDesktopMain.js" >/dev/null \
        && echo "bridge appended, syntax OK"
else
    echo "bridge appended (install 'node' to enable the syntax check)"
fi

echo
echo "Done. Next steps:"
echo "  1. In Vesktop: Settings -> Vencord Location -> choose $CUSTOM_DIR"
echo "     (only needed the first time; it is remembered afterwards)"
echo "  2. Restart Vesktop"
echo "  3. Verify from a terminal:  curl http://127.0.0.1:6459/ping   -> pong"
