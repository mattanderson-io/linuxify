# zsh half of linuxify-color: prompt, colored man pages, fetch banner, plugins.
# Installed to ${XDG_CONFIG_HOME:-$HOME/.config}/linuxify/zsh-integration.zsh
# and sourced from ~/.zshrc. This is the only file ~/.zshrc needs to know
# about; the shared, shell-agnostic half is pulled in from here.

source "${XDG_CONFIG_HOME:-$HOME/.config}/linuxify/environment.sh"

# environment.sh exports this; fall back for anyone sourcing this file alone.
BREW_HOME="${HOMEBREW_PREFIX:-$(brew --prefix)}"

# Belt and braces against a PATH that grows in nested shells.
typeset -U path PATH
typeset -U manpath MANPATH

# Ubuntu-style colored prompt: user@host:~/path$
PROMPT=$'%B%F{green}%n@%m%f%b:%B%F{blue}%~%f%b%(!.#.$) '

# colored man pages
export LESS_TERMCAP_mb=$'\e[1;32m'
export LESS_TERMCAP_md=$'\e[1;32m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_so=$'\e[01;33m'
export LESS_TERMCAP_ue=$'\e[0m'
export LESS_TERMCAP_us=$'\e[1;4;31m'

# fetch banner on new interactive shells; set LINUXIFY_NO_FETCH=1 to skip it
if [ -z "$LINUXIFY_NO_FETCH" ] && command -v fastfetch > /dev/null 2>&1; then
    # `install --small` leaves a trimmed config here. Without it, fastfetch is
    # invoked bare so that its own defaults and anything in
    # ~/.config/fastfetch/ keep working as they did.
    _lx_fetch_config="${XDG_CONFIG_HOME:-$HOME/.config}/linuxify/fastfetch.jsonc"
    if [ -r "$_lx_fetch_config" ]; then
        fastfetch --config "$_lx_fetch_config"
    else
        fastfetch
    fi
    unset _lx_fetch_config

    # The tag under the banner: "Powered by" out of the way in grey, the name
    # in the same green as the prompt, and Color doing what it says. Drawn from
    # the terminal's own 16 colors rather than a 256-color ramp, so it follows
    # whatever theme is set instead of fighting it.
    printf '%s\n' $'\e[90mPowered by \e[1;32mLinuxify \e[1;31mC\e[1;33mo\e[1;32ml\e[1;36mo\e[1;34mr\e[0m'
fi

# zsh plugins (syntax-highlighting must be sourced last)
[ -r "${BREW_HOME}/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && source "${BREW_HOME}/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
[ -r "${BREW_HOME}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] && source "${BREW_HOME}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

unset BREW_HOME
