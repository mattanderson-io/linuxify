# Shell-agnostic half of linuxify-color: PATH/MANPATH/INFOPATH and colors.
# Installed to ${XDG_CONFIG_HOME:-$HOME/.config}/linuxify/environment.sh.
#
# zsh users get this via zsh-integration.zsh, which sources it. bash users
# should source it directly from ~/.bashrc.

# `brew --prefix` costs a fork on every shell start, so only pay it once and
# only if `brew shellenv` has not already told us the answer.
export HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-$(brew --prefix)}"
BREW_HOME="$HOMEBREW_PREFIX"

# Put a directory at the front of a path-style variable, skipping directories
# that do not exist and ones that are already there. The de-duplication matters
# because ~/.zshrc is re-read by every nested shell, and without it PATH grows
# by a dozen entries each time.
linuxify_prepend() {
    _lx_var="$1"
    _lx_dir="$2"

    [ -d "$_lx_dir" ] || return 0

    eval "_lx_old=\${$_lx_var:-}"
    case ":${_lx_old}:" in
        *":${_lx_dir}:"*) return 0 ;;
    esac

    # An empty tail is meaningful in MANPATH and INFOPATH: it tells man and
    # info to go on searching their built-in defaults. PATH has no such
    # convention, and a trailing colon there would quietly mean "and also the
    # current directory".
    if [ -z "$_lx_old" ] && [ "$_lx_var" = PATH ]; then
        eval "export $_lx_var=\"\$_lx_dir\""
    else
        eval "export $_lx_var=\"\$_lx_dir:\$_lx_old\""
    fi
}

# most programs
linuxify_prepend PATH "${BREW_HOME}/bin"
linuxify_prepend MANPATH "${BREW_HOME}/share/man"
linuxify_prepend INFOPATH "${BREW_HOME}/share/info"

# Formulas that ship their GNU-named commands in a gnubin directory, so that
# awk, sed, tar, patch and friends work without a g prefix.
for _lx_formula in coreutils ed findutils gawk gnu-indent gnu-sed gnu-tar \
                   gnu-which gpatch grep make; do
    linuxify_prepend PATH "${BREW_HOME}/opt/${_lx_formula}/libexec/gnubin"
    linuxify_prepend MANPATH "${BREW_HOME}/opt/${_lx_formula}/libexec/gnuman"
done

# Keg-only formulas, and ones whose binaries live somewhere non-standard
linuxify_prepend PATH "${BREW_HOME}/opt/m4/bin"
linuxify_prepend PATH "${BREW_HOME}/opt/file-formula/bin"
linuxify_prepend PATH "${BREW_HOME}/opt/unzip/bin"
linuxify_prepend PATH "${BREW_HOME}/opt/python/libexec/bin"
linuxify_prepend PATH "${BREW_HOME}/opt/flex/bin"
linuxify_prepend PATH "${BREW_HOME}/opt/bison/bin"
linuxify_prepend PATH "${BREW_HOME}/opt/libressl/bin"

# Deliberately no global LDFLAGS/CPPFLAGS/PKG_CONFIG_PATH. Exporting those
# would make every unrelated build on this machine link against Homebrew's
# keg-only LibreSSL and friends, which is rarely what you want and is very hard
# to debug when it is not. Set them per-project instead.

unset -f linuxify_prepend
unset _lx_var _lx_dir _lx_old _lx_formula BREW_HOME

# colors
if command -v dircolors >/dev/null 2>&1; then
    if [ -r ~/.dircolors ]; then
        eval "$(dircolors -b ~/.dircolors)"
    else
        eval "$(dircolors -b)"
    fi
fi

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias diff='diff --color=auto'
alias zgrep='zgrep --color=auto'
alias bzgrep='bzgrep --color=auto'
alias xzgrep='xzgrep --color=auto'
alias zstdgrep='zstdgrep --color=auto'

# less: auto-decompress gz/bz2/xz/zip/tar/etc. via lesspipe
_lx_lesspipe="$(command -v lesspipe.sh || true)"
if [ -n "$_lx_lesspipe" ]; then
    LESSOPEN="|${_lx_lesspipe} %s"
    export LESSOPEN
fi
unset _lx_lesspipe
