#!/usr/bin/env bash
set -e

echo "Setting up dotfiles and installing CLI tools..."
shell=$(basename $SHELL)

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
  apt-get update && apt-get install fd-find -y
fi

# Install atuin
if ! command -v atuin &> /dev/null; then
  echo "Installing atuin..."
  curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
fi

# Install starship
if ! command -v starship &> /dev/null; then
  echo "Installing starship..."
  curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

# Install zoxide
if ! command -v zoxide &> /dev/null; then
  echo "Installing zoxide..."
  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
fi

# Install k9s
if ! command -v k9s &> /dev/null; then
  echo "Installing k9s..."
  if [ -f /etc/debian_version ]; then
    curl -LO https://github.com/derailed/k9s/releases/latest/download/k9s_linux_amd64.deb
    sudo dpkg -i k9s_linux_amd64.deb
    rm k9s_linux_amd64.deb
  else
    curl -LO https://github.com/derailed/k9s/releases/latest/download/k9s_linux_$(uname -m).tar.gz
    tar -xzf k9s_linux_*.tar.gz -C ~/.local/bin
    rm k9s_Linux_*.tar.gz
  fi
fi

# Link dotfiles configurations
ln -sf ~/.dotfiles/starship.toml ~/.config/starship.toml
# ln -sf ~/.dotfiles/atuin/config.toml ~/.config/atuin/config.toml

if [ "$shell" = "bash" ]; then
  echo 'eval "$(starship init bash --print-full-init)"' >> ~/.bashrc
  echo 'eval "$(zoxide init bash --cmd cd --hook pwd)"' >> ~/.bashrc
  echo 'eval "$(fzf --bash)"' >> ~/.bashrc
  echo 'eval "$(atuin init bash)"' >> ~/.bashrc
fi

if [ "$shell" = "zsh" ]; then
  echo 'eval "$(starship init zsh --print-full-init)"' >> ~/.zshrc
  echo 'eval "$(zoxide init zsh --cmd cd --hook pwd)"' >> ~/.zshrc
  echo 'eval "$(fzf --zsh)"' >> ~/.zshrc
  echo 'eval "$(atuin init zsh)"' >> ~/.zshrc
fi

echo "Dotfiles and CLI tools setup complete!"
