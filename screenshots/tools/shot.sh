#!/bin/bash
set -euo pipefail
OUT="$1"; ROWS="$2"; shift 2
CMD="$*"
ESCAPED=${CMD//\\/\\\\}; ESCAPED=${ESCAPED//\"/\\\"}

osascript <<EOF >/dev/null
tell application "Terminal"
    activate
    do script "cd ~/demo"
    delay 0.4
    set number of columns of front window to 96
    set number of rows of front window to $ROWS
    set position of front window to {80, 80}
    delay 0.4
    do script "clear" in front window
    delay 0.4
    do script "$ESCAPED" in front window
end tell
EOF

sleep 2.2
BOUNDS=$(osascript -e 'tell application "Terminal" to get bounds of front window')
L=$(echo "$BOUNDS" | cut -d, -f1 | tr -d ' '); T=$(echo "$BOUNDS" | cut -d, -f2 | tr -d ' ')
R=$(echo "$BOUNDS" | cut -d, -f3 | tr -d ' '); B=$(echo "$BOUNDS" | cut -d, -f4 | tr -d ' ')
screencapture -x -R "$L,$T,$((R-L)),$((B-T))" "$OUT"
osascript -e 'tell application "Terminal" to close front window saving no' >/dev/null 2>&1 || true
echo "  $(basename "$OUT")"
