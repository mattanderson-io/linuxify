#!/usr/bin/env bats
#
# Behavioural tests for ./linuxify, driven against tests/fake-brew.
#
# The suite is deliberately weighted towards uninstall: the ways this script
# can go wrong are all ways it can delete something it did not install.

setup() {
    REPO_ROOT="$(cd -- "$(dirname -- "$BATS_TEST_FILENAME")/.." && pwd)"
    export REPO_ROOT

    SANDBOX="$(mktemp -d)"
    export SANDBOX

    # A HOME and XDG dirs of our own, so nothing leaks onto the machine
    export HOME="$SANDBOX/home"
    export XDG_CONFIG_HOME="$SANDBOX/config"
    export XDG_STATE_HOME="$SANDBOX/state"
    mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$XDG_STATE_HOME"

    export FAKE_BREW_DIR="$SANDBOX/brew"
    export FAKE_BREW_PREFIX="$SANDBOX/opt/homebrew"
    mkdir -p "$FAKE_BREW_DIR" "$FAKE_BREW_PREFIX/bin" "$FAKE_BREW_PREFIX/sbin"
    touch "$FAKE_BREW_DIR/installed"

    # environment.sh prefers an inherited HOMEBREW_PREFIX over calling
    # `brew --prefix`, which is the point of it. CI runners export the real one,
    # so pin it to the sandbox rather than letting the host leak in.
    export HOMEBREW_PREFIX="$FAKE_BREW_PREFIX"

    # Put the fake brew ahead of anything real
    mkdir -p "$SANDBOX/bin"
    ln -sf "$REPO_ROOT/tests/fake-brew" "$SANDBOX/bin/brew"
    export PATH="$SANDBOX/bin:$PATH"

    # The script guards on this; the tests are not macOS-specific otherwise
    export OSTYPE="darwin24"

    export CONFIG_DIR="$XDG_CONFIG_HOME/linuxify"
    export MANIFEST="$XDG_STATE_HOME/linuxify/installed-formulas"
    export ZSHRC_LINE='source "${XDG_CONFIG_HOME:-$HOME/.config}/linuxify/zsh-integration.zsh"'
}

teardown() {
    rm -rf "$SANDBOX"
}

# Pretend brew already has these formulas before linuxify ever runs
preinstall() {
    local formula
    for formula in "$@"; do
        echo "$formula" >> "$FAKE_BREW_DIR/installed"
    done
}

@test "install records only the formulas it actually installed" {
    preinstall git vim rsync

    run "$REPO_ROOT/linuxify" install
    [ "$status" -eq 0 ]

    # The three that were already there are not ours
    run grep -qxF git "$MANIFEST"
    [ "$status" -ne 0 ]
    run grep -qxF vim "$MANIFEST"
    [ "$status" -ne 0 ]
    run grep -qxF rsync "$MANIFEST"
    [ "$status" -ne 0 ]

    # Something we did install is
    run grep -qxF coreutils "$MANIFEST"
    [ "$status" -eq 0 ]
}

@test "install does not reinstall formulas that are already present" {
    preinstall git

    run "$REPO_ROOT/linuxify" install
    [ "$status" -eq 0 ]

    run bash -c "grep -qxF git '$FAKE_BREW_DIR/installed.log'"
    [ "$status" -ne 0 ]
}

@test "uninstall leaves pre-existing formulas alone" {
    preinstall git vim rsync openssh python

    run "$REPO_ROOT/linuxify" install
    [ "$status" -eq 0 ]

    run "$REPO_ROOT/linuxify" uninstall
    [ "$status" -eq 0 ]

    local formula
    for formula in git vim rsync openssh python; do
        run bash -c "grep -qxF '$formula' '$FAKE_BREW_DIR/uninstalled.log' 2>/dev/null"
        [ "$status" -ne 0 ]

        # and they are still installed as far as brew is concerned
        run bash -c "grep -qxF '$formula' '$FAKE_BREW_DIR/installed'"
        [ "$status" -eq 0 ]
    done
}

@test "uninstall removes the formulas it did install" {
    run "$REPO_ROOT/linuxify" install
    [ "$status" -eq 0 ]

    run "$REPO_ROOT/linuxify" uninstall
    [ "$status" -eq 0 ]

    run bash -c "grep -qxF coreutils '$FAKE_BREW_DIR/uninstalled.log'"
    [ "$status" -eq 0 ]
    run bash -c "grep -qxF gawk '$FAKE_BREW_DIR/uninstalled.log'"
    [ "$status" -eq 0 ]

    # and the manifest is gone once it is empty
    [ ! -f "$MANIFEST" ]
}

@test "uninstall never removes bash while it is the login shell" {
    export SHELL="$FAKE_BREW_PREFIX/bin/bash"

    run "$REPO_ROOT/linuxify" install
    [ "$status" -eq 0 ]

    run "$REPO_ROOT/linuxify" uninstall
    [ "$status" -eq 0 ]

    run bash -c "grep -qxF bash '$FAKE_BREW_DIR/uninstalled.log' 2>/dev/null"
    [ "$status" -ne 0 ]

    run bash -c "grep -qxF bash '$FAKE_BREW_DIR/installed'"
    [ "$status" -eq 0 ]
}

@test "uninstall keeps a formula that other packages still depend on" {
    run "$REPO_ROOT/linuxify" install
    [ "$status" -eq 0 ]

    echo "some-unrelated-package" > "$FAKE_BREW_DIR/uses.xz"

    run "$REPO_ROOT/linuxify" uninstall
    [ "$status" -eq 0 ]

    run bash -c "grep -qxF xz '$FAKE_BREW_DIR/uninstalled.log' 2>/dev/null"
    [ "$status" -ne 0 ]

    # it stays in the manifest so a later uninstall can try again
    run grep -qxF xz "$MANIFEST"
    [ "$status" -eq 0 ]
}

@test "a formula brew refuses to remove does not abort the uninstall" {
    run "$REPO_ROOT/linuxify" install
    [ "$status" -eq 0 ]

    touch "$FAKE_BREW_DIR/refuse.zstd"

    run "$REPO_ROOT/linuxify" uninstall
    [ "$status" -eq 0 ]

    # formulas processed after the refusal were still removed
    run bash -c "grep -qxF coreutils '$FAKE_BREW_DIR/uninstalled.log'"
    [ "$status" -eq 0 ]
}

@test "install lands in the XDG config directory" {
    run "$REPO_ROOT/linuxify" install
    [ "$status" -eq 0 ]

    [ -f "$CONFIG_DIR/environment.sh" ]
    [ -f "$CONFIG_DIR/zsh-integration.zsh" ]

    # and leaves no dotfiles loose in $HOME
    [ ! -e "$HOME/.linuxify" ]
    [ ! -e "$HOME/.linuxify.zsh" ]
}

@test "install honours a relocated XDG_CONFIG_HOME" {
    export XDG_CONFIG_HOME="$SANDBOX/elsewhere"

    run "$REPO_ROOT/linuxify" install
    [ "$status" -eq 0 ]

    [ -f "$SANDBOX/elsewhere/linuxify/environment.sh" ]
    [ ! -e "$CONFIG_DIR/environment.sh" ]
}

@test "install falls back to ~/.config when XDG_CONFIG_HOME is unset" {
    unset XDG_CONFIG_HOME

    run "$REPO_ROOT/linuxify" install
    [ "$status" -eq 0 ]

    [ -f "$HOME/.config/linuxify/environment.sh" ]
    [ -f "$HOME/.config/linuxify/zsh-integration.zsh" ]
}

@test "the installed files are readable but not writable by group or other" {
    run "$REPO_ROOT/linuxify" install
    [ "$status" -eq 0 ]

    run bash -c "ls -l '$CONFIG_DIR/environment.sh' | cut -c1-10"
    [ "$output" = "-rw-r--r--" ]
}

@test "install works from any directory" {
    cd "$SANDBOX"

    run "$REPO_ROOT/linuxify" install
    [ "$status" -eq 0 ]

    run diff -q "$REPO_ROOT/environment.sh" "$CONFIG_DIR/environment.sh"
    [ "$status" -eq 0 ]
    run diff -q "$REPO_ROOT/zsh-integration.zsh" "$CONFIG_DIR/zsh-integration.zsh"
    [ "$status" -eq 0 ]
}

@test "install does not pick up unrelated files of the same name" {
    cd "$SANDBOX"
    echo "this is not ours" > "$SANDBOX/environment.sh"

    run "$REPO_ROOT/linuxify" install
    [ "$status" -eq 0 ]

    run grep -q "this is not ours" "$CONFIG_DIR/environment.sh"
    [ "$status" -ne 0 ]
}

@test "repeated installation is idempotent" {
    run "$REPO_ROOT/linuxify" install
    [ "$status" -eq 0 ]
    run "$REPO_ROOT/linuxify" install
    [ "$status" -eq 0 ]

    run bash -c "grep -cxF '$ZSHRC_LINE' '$HOME/.zshrc'"
    [ "$output" = "1" ]

    # the manifest does not accumulate duplicates either
    run bash -c "sort '$MANIFEST' | uniq -d | wc -l | tr -d ' '"
    [ "$output" = "0" ]
}

@test "the zshrc gets exactly one line" {
    run "$REPO_ROOT/linuxify" install
    [ "$status" -eq 0 ]

    run bash -c "wc -l < '$HOME/.zshrc' | tr -d ' '"
    [ "$output" = "1" ]
}

@test "the ~/.zshrc line stays unexpanded so XDG_CONFIG_HOME is resolved at runtime" {
    run "$REPO_ROOT/linuxify" install
    [ "$status" -eq 0 ]

    run grep -qF 'XDG_CONFIG_HOME:-$HOME/.config' "$HOME/.zshrc"
    [ "$status" -eq 0 ]

    # the sandbox path must not have been baked in
    run grep -qF "$SANDBOX" "$HOME/.zshrc"
    [ "$status" -ne 0 ]
}

@test "uninstall strips its own line and leaves the rest of .zshrc intact" {
    cat > "$HOME/.zshrc" <<'EOF'
export EDITOR=vim
alias ll='ls -l'
EOF

    run "$REPO_ROOT/linuxify" install
    [ "$status" -eq 0 ]
    run "$REPO_ROOT/linuxify" uninstall
    [ "$status" -eq 0 ]

    run grep -qxF "export EDITOR=vim" "$HOME/.zshrc"
    [ "$status" -eq 0 ]
    run grep -qxF "alias ll='ls -l'" "$HOME/.zshrc"
    [ "$status" -eq 0 ]
    run grep -qF "linuxify" "$HOME/.zshrc"
    [ "$status" -ne 0 ]
}

@test "uninstall does not delete lines that merely resemble its own" {
    # Every one of these is matched by the real line read as a regex, because
    # of the dots in '.config' and 'zsh-integration.zsh'
    cat > "$HOME/.zshrc" <<'EOF'
source "${XDG_CONFIG_HOME:-$HOME/Xconfig}/linuxify/zsh-integration.zsh"
source "${XDG_CONFIG_HOME:-$HOME/.config}/linuxify/zsh-integrationXzsh"
source "${XDG_CONFIG_HOME:-$HOME/.config}/linuxify/zsh-integration.zsh" # mine
EOF

    run "$REPO_ROOT/linuxify" install
    [ "$status" -eq 0 ]
    run "$REPO_ROOT/linuxify" uninstall
    [ "$status" -eq 0 ]

    run bash -c "wc -l < '$HOME/.zshrc' | tr -d ' '"
    [ "$output" = "3" ]
}

@test "uninstall removes the config directory it created" {
    run "$REPO_ROOT/linuxify" install
    [ "$status" -eq 0 ]
    run "$REPO_ROOT/linuxify" uninstall
    [ "$status" -eq 0 ]

    [ ! -e "$CONFIG_DIR" ]
}

@test "uninstall leaves the config directory alone if it holds anything else" {
    run "$REPO_ROOT/linuxify" install
    [ "$status" -eq 0 ]
    echo "mine" > "$CONFIG_DIR/notes.txt"

    run "$REPO_ROOT/linuxify" uninstall
    [ "$status" -eq 0 ]

    [ -f "$CONFIG_DIR/notes.txt" ]
    [ ! -e "$CONFIG_DIR/environment.sh" ]
}

@test "install preserves a pre-existing .zshrc as a backup" {
    echo "export EDITOR=vim" > "$HOME/.zshrc"

    run "$REPO_ROOT/linuxify" install
    [ "$status" -eq 0 ]

    run grep -qxF "export EDITOR=vim" "$HOME/.zshrc.linuxify.bak"
    [ "$status" -eq 0 ]
    run bash -c "grep -qF linuxify '$HOME/.zshrc.linuxify.bak'"
    [ "$status" -ne 0 ]
}

@test "a pre-existing environment.sh is backed up and restored" {
    mkdir -p "$CONFIG_DIR"
    echo "user's own file" > "$CONFIG_DIR/environment.sh"

    run "$REPO_ROOT/linuxify" install
    [ "$status" -eq 0 ]
    run grep -qxF "user's own file" "$CONFIG_DIR/environment.sh.linuxify.bak"
    [ "$status" -eq 0 ]

    run "$REPO_ROOT/linuxify" uninstall
    [ "$status" -eq 0 ]
    run grep -qxF "user's own file" "$CONFIG_DIR/environment.sh"
    [ "$status" -eq 0 ]
}

@test "uninstall without a prior install removes nothing" {
    preinstall git vim coreutils gawk

    run "$REPO_ROOT/linuxify" uninstall
    [ "$status" -eq 0 ]

    [ ! -f "$FAKE_BREW_DIR/uninstalled.log" ]
}

@test "an unknown command exits nonzero" {
    run "$REPO_ROOT/linuxify" frobnicate
    [ "$status" -eq 2 ]
}

@test "no command at all exits nonzero" {
    run "$REPO_ROOT/linuxify"
    [ "$status" -eq 2 ]
}

@test "--help exits zero" {
    run "$REPO_ROOT/linuxify" --help
    [ "$status" -eq 0 ]
    run "$REPO_ROOT/linuxify" -h
    [ "$status" -eq 0 ]
}

@test "a non-macOS host exits nonzero" {
    export OSTYPE="linux-gnu"

    run "$REPO_ROOT/linuxify" install
    [ "$status" -ne 0 ]
    [[ "$output" == *"macOS only"* ]]
}

@test "a missing Homebrew exits nonzero" {
    rm "$SANDBOX/bin/brew"
    export PATH="/usr/bin:/bin"

    run "$REPO_ROOT/linuxify" install
    [ "$status" -ne 0 ]
    [[ "$output" == *"Homebrew not installed"* ]]
}

@test "an unwriteable brew prefix exits nonzero" {
    rm -rf "$FAKE_BREW_PREFIX/sbin"

    run "$REPO_ROOT/linuxify" install
    [ "$status" -ne 0 ]
    [[ "$output" == *"must exist and be writeable"* ]]
}

@test "environment.sh puts the gnubin directories on PATH" {
    local formula
    for formula in coreutils gawk gpatch gnu-sed grep make; do
        mkdir -p "$FAKE_BREW_PREFIX/opt/$formula/libexec/gnubin"
    done

    run bash -c "unset MANPATH INFOPATH; HOMEBREW_PREFIX='$FAKE_BREW_PREFIX' . '$REPO_ROOT/environment.sh' >/dev/null 2>&1; echo \"\$PATH\""
    [ "$status" -eq 0 ]

    for formula in coreutils gawk gpatch gnu-sed grep make; do
        [[ "$output" == *"$FAKE_BREW_PREFIX/opt/$formula/libexec/gnubin"* ]]
    done
}

@test "environment.sh does not add directories that do not exist" {
    # Scoped to the sandbox prefix: the machine running the tests may well have
    # its own gnubin directories on PATH already.
    run bash -c "unset MANPATH INFOPATH; HOMEBREW_PREFIX='$FAKE_BREW_PREFIX' . '$REPO_ROOT/environment.sh' >/dev/null 2>&1; echo \"\$PATH\""
    [ "$status" -eq 0 ]
    [[ "$output" != *"$FAKE_BREW_PREFIX/opt/"* ]]
}

@test "environment.sh does not grow PATH when sourced repeatedly" {
    mkdir -p "$FAKE_BREW_PREFIX/opt/coreutils/libexec/gnubin"

    run bash -c "
        unset MANPATH INFOPATH
        export HOMEBREW_PREFIX='$FAKE_BREW_PREFIX'
        . '$REPO_ROOT/environment.sh' >/dev/null 2>&1
        once=\$(echo \"\$PATH\" | tr ':' '\n' | wc -l)
        . '$REPO_ROOT/environment.sh' >/dev/null 2>&1
        . '$REPO_ROOT/environment.sh' >/dev/null 2>&1
        thrice=\$(echo \"\$PATH\" | tr ':' '\n' | wc -l)
        [ \"\$once\" -eq \"\$thrice\" ]
    "
    [ "$status" -eq 0 ]
}

@test "environment.sh sets no global build flags" {
    run bash -c "
        unset MANPATH INFOPATH LDFLAGS CPPFLAGS PKG_CONFIG_PATH
        HOMEBREW_PREFIX='$FAKE_BREW_PREFIX' . '$REPO_ROOT/environment.sh' >/dev/null 2>&1
        echo \"LDFLAGS=[\${LDFLAGS:-}] CPPFLAGS=[\${CPPFLAGS:-}] PKG_CONFIG_PATH=[\${PKG_CONFIG_PATH:-}]\"
    "
    [ "$status" -eq 0 ]
    [ "$output" = "LDFLAGS=[] CPPFLAGS=[] PKG_CONFIG_PATH=[]" ]
}

@test "environment.sh is safe under set -u" {
    run bash -c "
        set -u
        unset MANPATH INFOPATH
        HOMEBREW_PREFIX='$FAKE_BREW_PREFIX' . '$REPO_ROOT/environment.sh' >/dev/null 2>&1
    "
    [ "$status" -eq 0 ]
}

@test "environment.sh keeps the trailing entry that MANPATH needs" {
    mkdir -p "$FAKE_BREW_PREFIX/share/man"

    run bash -c "unset MANPATH INFOPATH; HOMEBREW_PREFIX='$FAKE_BREW_PREFIX' . '$REPO_ROOT/environment.sh' >/dev/null 2>&1; echo \"\$MANPATH\""
    [ "$status" -eq 0 ]
    [ "$output" = "$FAKE_BREW_PREFIX/share/man:" ]
}

@test "environment.sh leaves no helper variables or functions behind" {
    run bash -c "
        unset MANPATH INFOPATH
        HOMEBREW_PREFIX='$FAKE_BREW_PREFIX' . '$REPO_ROOT/environment.sh' >/dev/null 2>&1
        echo \"[\${BREW_HOME:-}][\${_lx_var:-}][\${_lx_dir:-}][\${_lx_formula:-}][\${_lx_lesspipe:-}]\"
        if type linuxify_prepend >/dev/null 2>&1; then echo LEAKED; fi
    "
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "[][][][][]" ]
    [[ "$output" != *LEAKED* ]]
}

@test "zsh-integration.zsh pulls in environment.sh from the installed location" {
    mkdir -p "$FAKE_BREW_PREFIX/opt/coreutils/libexec/gnubin"

    run "$REPO_ROOT/linuxify" install
    [ "$status" -eq 0 ]

    run zsh -c "
        unset MANPATH INFOPATH
        export XDG_CONFIG_HOME='$XDG_CONFIG_HOME'
        export HOMEBREW_PREFIX='$FAKE_BREW_PREFIX'
        source '$CONFIG_DIR/zsh-integration.zsh' >/dev/null 2>&1
        echo \$PATH
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"$FAKE_BREW_PREFIX/opt/coreutils/libexec/gnubin"* ]]
}

@test "zsh-integration.zsh follows a relocated XDG_CONFIG_HOME" {
    export XDG_CONFIG_HOME="$SANDBOX/elsewhere"
    mkdir -p "$FAKE_BREW_PREFIX/opt/coreutils/libexec/gnubin"

    run "$REPO_ROOT/linuxify" install
    [ "$status" -eq 0 ]

    run zsh -c "
        unset MANPATH INFOPATH
        export XDG_CONFIG_HOME='$SANDBOX/elsewhere'
        export HOMEBREW_PREFIX='$FAKE_BREW_PREFIX'
        source '$SANDBOX/elsewhere/linuxify/zsh-integration.zsh' >/dev/null 2>&1
        echo \$PATH
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"$FAKE_BREW_PREFIX/opt/coreutils/libexec/gnubin"* ]]
}

@test "zsh-integration.zsh sets the prompt" {
    run "$REPO_ROOT/linuxify" install
    [ "$status" -eq 0 ]

    run zsh -c "
        export XDG_CONFIG_HOME='$XDG_CONFIG_HOME'
        source '$CONFIG_DIR/zsh-integration.zsh' >/dev/null 2>&1
        echo \$PROMPT
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"%n@%m"* ]]
}
