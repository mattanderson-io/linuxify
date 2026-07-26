#!/bin/bash
# Capture a Terminal window with the login banner still on screen.
#
# shot.sh clears the screen before running its command, which is what you want
# for a shot of one command's output and exactly what you do not want for a shot
# of the banner. So this opens the window, sizes it, and only then starts a
# fresh shell: the banner is drawn at the final width rather than reflowed from
# whatever Terminal's default happened to be.
#
# usage: shot-banner.sh <out.png> <rows> <cols> [command ...]
set -euo pipefail
OUT="$1"; ROWS="$2"; COLS="$3"; shift 3
CMD="$*"
ESCAPED=${CMD//\\/\\\\}; ESCAPED=${ESCAPED//\"/\\\"}

osascript <<EOF >/dev/null
tell application "Terminal"
    activate
    do script "cd ~/demo"
    delay 0.4
    set number of columns of front window to $COLS
    set number of rows of front window to $ROWS
    set position of front window to {80, 80}
    delay 0.6
    -- exec, so the banner is printed by a shell that already knows the width
    do script "clear; exec zsh" in front window
    delay 1.6
end tell
EOF

if [ -n "$CMD" ]; then
    osascript >/dev/null <<EOF
tell application "Terminal" to do script "$ESCAPED" in front window
EOF
fi

sleep 2.2
BOUNDS=$(osascript -e 'tell application "Terminal" to get bounds of front window')
L=$(echo "$BOUNDS" | cut -d, -f1 | tr -d ' '); T=$(echo "$BOUNDS" | cut -d, -f2 | tr -d ' ')
R=$(echo "$BOUNDS" | cut -d, -f3 | tr -d ' '); B=$(echo "$BOUNDS" | cut -d, -f4 | tr -d ' ')
screencapture -x -R "$L,$T,$((R-L)),$((B-T))" "$OUT"
osascript -e 'tell application "Terminal" to close front window saving no' >/dev/null 2>&1 || true
echo "  $(basename "$OUT")"
