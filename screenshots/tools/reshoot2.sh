#!/bin/bash
set -uo pipefail
P=/private/tmp/claude-501/-Users-matt/77e3b6ea-d82a-47a4-bba1-127726a29dd5/scratchpad
S="$P/shot.sh"; B="$P/before2"; A="$P/after2"
cp ~/.zshrc "$P/zshrc.orig2"
cleanup() { cp "$P/zshrc.orig2" ~/.zshrc; echo "[restored .zshrc]"; }
trap cleanup EXIT

typeshot() {
  local out="$1" rows="$2" seed="$3" typed="$4"
  osascript >/dev/null 2>&1 <<EOF
tell application "Terminal"
    activate
    do script "cd ~/demo"
    delay 0.4
    set number of columns of front window to 96
    set number of rows of front window to $rows
    set position of front window to {80, 80}
    delay 0.4
    do script "$seed" in front window
    delay 1.0
    do script "clear" in front window
    delay 0.8
end tell
delay 0.5
tell application "System Events"
    keystroke "$typed"
end tell
EOF
  sleep 1.5
  local b l t r bo
  b=$(osascript -e 'tell application "Terminal" to get bounds of front window')
  l=$(echo "$b"|cut -d, -f1|tr -d ' '); t=$(echo "$b"|cut -d, -f2|tr -d ' ')
  r=$(echo "$b"|cut -d, -f3|tr -d ' '); bo=$(echo "$b"|cut -d, -f4|tr -d ' ')
  screencapture -x -R "$l,$t,$((r-l)),$((bo-t))" "$out"
  osascript -e 'tell application "Terminal" to close front window saving no' >/dev/null 2>&1
  echo "  $(basename "$out")"
}

# plain ls (no owner column) — BEFORE
cp "$P/zshrc.orig2" ~/.zshrc
sed -i 's|^source "${XDG_CONFIG_HOME|# source "${XDG_CONFIG_HOME|' ~/.zshrc
printf "%s\n" "PROMPT='devuser@Workstation-01 %1~ %# '" >> ~/.zshrc
"$P/demo-scene.sh" >/dev/null
echo "BEFORE:"; "$S" "$B/01b-ls-plain.png" 8 "ls"

# AFTER set
cp "$P/zshrc.orig2" ~/.zshrc
printf "%s\n" "PROMPT=\$'%B%F{green}devuser@Workstation-01%f%b:%B%F{blue}%~%f%b%(!.#.\$) '" >> ~/.zshrc
"$P/demo-scene.sh" >/dev/null
echo "AFTER:"
"$S" "$A/01b-ls-plain.png" 8 "ls"
typeshot "$A/09-autosuggest.png" 6 "grep --color=auto -n hello README.txt" "grep --col"
typeshot "$A/09b-syntax.png"     6 "ls -la" "gerp -n hello README.txt"
