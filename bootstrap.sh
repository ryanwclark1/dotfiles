#!/usr/bin/env bash
set -e

echo "Setting up dotfiles and installing CLI tools..."

# Ensure ~/.local/bin exists
mkdir -p ~/.local/bin

# Install fzf
if ! command -v fzf &> /dev/null; then
  echo "Installing fzf..."
  git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
  ~/.fzf/install --all
fi

# Install fd
if ! command -v fd &> /dev/null; then
  echo "Installing fd..."
  curl -LO https://github.com/sharkdp/fd/releases/latest/download/fd_$(uname -m)-unknown-linux-gnu.tar.gz
  tar -xzf fd_*_linux-gnu.tar.gz --strip-components=1 -C ~/.local/bin
  rm fd_*_linux-gnu.tar.gz
fi

# Install atuin
if ! command -v atuin &> /dev/null; then
  echo "Installing atuin..."
  curl -sSL https://github.com/ellie/atuin/releases/latest/download/atuin-linux-$(uname -m) -o ~/.local/bin/atuin
  chmod +x ~/.local/bin/atuin
fi

# Install starship
if ! command -v starship &> /dev/null; then
  echo "Installing starship..."
  curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

# Install k9s
if ! command -v k9s &> /dev/null; then
  echo "Installing k9s..."
  curl -LO https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_$(uname -m).tar.gz
  tar -xzf k9s_Linux_*.tar.gz -C ~/.local/bin
  rm k9s_Linux_*.tar.gz
fi

# Link dotfiles configurations
ln -sf ~/.dotfiles/starship.toml ~/.config/starship.toml
ln -sf ~/.dotfiles/.bashrc ~/.bashrc
ln -sf ~/.dotfiles/.zshrc ~/.zshrc
ln -sf ~/.dotfiles/.atuin.toml ~/.config/atuin/config.toml

echo "Dotfiles and CLI tools setup complete!"
