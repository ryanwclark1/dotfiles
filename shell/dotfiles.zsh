#!/usr/bin/env zsh
# Dotfiles configuration for zsh
# This file is managed by the dotfiles repository

# Environment variables
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"

# Source custom aliases
[ -f ~/.config/alias ] && source ~/.config/alias

# Tool initializations
# FZF
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Atuin
if command -v atuin &>/dev/null; then
    . "$HOME/.atuin/bin/env" 2>/dev/null || true
    eval "$(atuin init zsh)" 2>/dev/null || true
fi

# Starship prompt
command -v starship &>/dev/null && eval "$(starship init zsh --print-full-init)" 2>/dev/null || true

# Zoxide
command -v zoxide &>/dev/null && eval "$(zoxide init zsh --cmd cd --hook pwd)" 2>/dev/null || true