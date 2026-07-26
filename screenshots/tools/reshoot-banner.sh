#!/bin/bash
# Re-shoot the two banner images: the hero at the top of the README, and the
# small banner beside the --small flag.
#
# Both need this repo's zsh integration in place and a hostname that isn't the
# machine's, so the whole thing is staged and then undone: ~/.zshrc,
# ~/.config/linuxify and ~/.config/fastfetch are put back exactly as they were,
# on any exit.
set -uo pipefail
TOOLS="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd -- "$TOOLS/../.." && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/linuxify"
FFDIR="${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch"
STASH="$(mktemp -d)"

cp ~/.zshrc "$STASH/zshrc"
[ -d "$CONFIG_DIR" ] && cp -R "$CONFIG_DIR" "$STASH/linuxify"
[ -d "$FFDIR" ] && cp -R "$FFDIR" "$STASH/fastfetch"

cleanup() {
    cp "$STASH/zshrc" ~/.zshrc
    rm -rf "$CONFIG_DIR" "$FFDIR"
    [ -d "$STASH/linuxify" ] && cp -R "$STASH/linuxify" "$CONFIG_DIR"
    [ -d "$STASH/fastfetch" ] && cp -R "$STASH/fastfetch" "$FFDIR"
    rm -rf "$STASH"
    echo "[restored ~/.zshrc, ~/.config/linuxify and ~/.config/fastfetch]"
}
trap cleanup EXIT

# The integration as this repo has it, installed by hand: a screenshot run has
# no business invoking brew.
mkdir -p "$CONFIG_DIR"
install -m 0644 "$REPO/environment.sh" "$REPO/zsh-integration.zsh" "$CONFIG_DIR/"

# Anonymised prompt. Appended, so it lands after the line that sources the
# integration and therefore wins.
printf "%s\n" "PROMPT=\$'%B%F{green}devuser@Workstation-01%f%b:%B%F{blue}%~%f%b%(!.#.\$) '" >> ~/.zshrc

# A banner with no hostname, no IP and no battery in it
mkdir -p "$FFDIR"
cp "$TOOLS/fastfetch.jsonc" "$FFDIR/config.jsonc"

"$TOOLS/demo-scene.sh" >/dev/null

# The hero: the full banner, the tag, and the three commands the color story is
# built on. No fastfetch.jsonc of ours, so fastfetch is invoked bare exactly as
# a plain install leaves it.
#
# Plain `ls` rather than `ls -la`, because the long form prints the owner and
# this image is public.
echo "HERO:"
rm -f "$CONFIG_DIR/fastfetch.jsonc"
"$TOOLS/shot-banner.sh" "$REPO/screenshots/colors.png" 41 132 \
    "ls; grep -n ERROR app.log; diff before.txt after.txt"

# The small banner, as ./linuxify install --small leaves it
echo "SMALL:"
install -m 0644 "$TOOLS/fastfetch-small.jsonc" "$CONFIG_DIR/fastfetch.jsonc"
"$TOOLS/shot-banner.sh" "$REPO/screenshots/after/11-small-banner.png" 10 96

echo "done"
