# zsh-only companion to ~/.linuxify
# Prompt, colored man pages, fetch banner, and shell plugins.

BREW_HOME=$(brew --prefix)

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

# fetch banner on new interactive shells
command -v fastfetch > /dev/null 2>&1 && fastfetch

# zsh plugins (syntax-highlighting must be sourced last)
[ -r "${BREW_HOME}/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && source "${BREW_HOME}/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
[ -r "${BREW_HOME}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] && source "${BREW_HOME}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

unset BREW_HOME
