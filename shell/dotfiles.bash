#!/usr/bin/env bash
# Dotfiles configuration for bash
# This file is managed by the dotfiles repository

# Environment variables
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"

# Source custom aliases
[ -f ~/.config/alias ] && source ~/.config/alias

# Tool initializations
# FZF
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# Atuin
if command -v atuin &>/dev/null; then
    . "$HOME/.atuin/bin/env" 2>/dev/null || true
    [[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh
    eval "$(atuin init bash)" 2>/dev/null || true
fi

# Starship prompt
command -v starship &>/dev/null && eval "$(starship init bash --print-full-init)" 2>/dev/null || true

# Zoxide
command -v zoxide &>/dev/null && eval "$(zoxide init bash --cmd cd --hook pwd)" 2>/dev/null || true