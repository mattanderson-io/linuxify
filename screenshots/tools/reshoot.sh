#!/bin/bash
set -uo pipefail
P=/private/tmp/claude-501/-Users-matt/77e3b6ea-d82a-47a4-bba1-127726a29dd5/scratchpad
S="$P/shot.sh"; B="$P/before2"; A="$P/after2"; N="$P/needs-sanitizing2"
rm -rf "$B" "$A" "$N"; mkdir -p "$B" "$A" "$N"

cp ~/.zshrc "$P/zshrc.orig"
FFDIR=~/.config/fastfetch
FFHAD=no; [ -e "$FFDIR/config.jsonc" ] && FFHAD=yes && cp "$FFDIR/config.jsonc" "$P/ff.orig"

cleanup() {
    cp "$P/zshrc.orig" ~/.zshrc
    if [ "$FFHAD" = yes ]; then cp "$P/ff.orig" "$FFDIR/config.jsonc"; else rm -f "$FFDIR/config.jsonc"; rmdir "$FFDIR" 2>/dev/null; fi
    echo "[restored .zshrc and fastfetch config]"
}
trap cleanup EXIT

mkdir -p "$FFDIR"; cp "$P/fastfetch.jsonc" "$FFDIR/config.jsonc"

# ---------- BEFORE: stock macOS, anonymised prompt ----------
cp "$P/zshrc.orig" ~/.zshrc
sed -i 's|^source "${XDG_CONFIG_HOME|# source "${XDG_CONFIG_HOME|' ~/.zshrc
printf "%s\n" "PROMPT='devuser@Workstation-01 %1~ %# '" >> ~/.zshrc

"$P/demo-scene.sh" >/dev/null
echo "BEFORE:"
"$S" "$B/01-ls.png"        21 "ls -la"
"$S" "$B/02-grep.png"       7 "grep -n hello README.txt; grep -n ERROR app.log"
"$S" "$B/03-diff.png"      12 "diff before.txt after.txt"
"$S" "$B/04-man.png"       24 "man ls"
"$S" "$B/05-lesspipe.png"   5 "less archive.tar.gz"
"$S" "$B/06-gnu-flags.png" 15 "sed -i 's/alpha/ALPHA/' before.txt; head -1 before.txt; find . -maxdepth 1 -name '*.txt' -printf '%f\n'; date -d '2 days ago' +%F"
"$S" "$B/07-tools.png"      7 "tree -L 2; ip -brief addr show lo0; htop --version"
"$S" "$N/07-tools-FULL-before.png" 7 "tree -L 2; ip -brief addr; htop --version"

# ---------- AFTER: linuxify active, anonymised prompt ----------
cp "$P/zshrc.orig" ~/.zshrc
printf "%s\n" "PROMPT=\$'%B%F{green}devuser@Workstation-01%f%b:%B%F{blue}%~%f%b%(!.#.\$) '" >> ~/.zshrc

"$P/demo-scene.sh" >/dev/null
echo "AFTER:"
"$S" "$A/01-ls.png"        21 "ls -la"
"$S" "$A/02-grep.png"       7 "grep -n hello README.txt; grep -n ERROR app.log"
"$S" "$A/03-diff.png"      12 "diff before.txt after.txt"
"$S" "$A/04-man.png"       24 "man ls"
"$S" "$A/05-lesspipe.png"   6 "less archive.tar.gz"
"$P/demo-scene.sh" >/dev/null
"$S" "$A/06-gnu-flags.png" 10 "sed -i 's/alpha/ALPHA/' before.txt; head -1 before.txt; find . -maxdepth 1 -name '*.txt' -printf '%f\n'; date -d '2 days ago' +%F"
"$P/demo-scene.sh" >/dev/null
"$S" "$A/07-tools.png"     20 "tree -L 2; ip -brief addr show lo0; htop --version"
"$S" "$N/07-tools-FULL-after.png" 26 "tree -L 2; ip -brief addr; htop --version"
"$S" "$A/08-fastfetch.png" 31 "fastfetch"
echo done
