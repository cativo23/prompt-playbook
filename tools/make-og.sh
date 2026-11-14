#!/usr/bin/env bash
# Renders the share card and the favicon from their HTML sources with headless Chrome.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
shot(){ google-chrome-stable --headless --disable-gpu --hide-scrollbars --no-sandbox \
  --virtual-time-budget=3000 --screenshot="$1" --window-size="$2" "file://$PWD/$3" 2>/dev/null; }
shot assets/og.png 1200,630 tools/og.html
shot assets/icon.png 512,512 tools/icon.html
file assets/og.png assets/icon.png
