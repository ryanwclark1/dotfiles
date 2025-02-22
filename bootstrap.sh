#!/usr/bin/env bash
set -e

echo "Setting up dotfiles and installing CLI tools..."
shell=$(basename $SHELL)

# Define source and destination directories
DOTFILES_DIR=$HOME/dotfiles
CONFIG_DIR=$HOME/.config
SCRIPTS_DIR=$CONFIG_DIR/scripts
BIN_DIR=$HOME/.local/bin
# list of scripts to be removed from the scripts directory
SCRIPTS_TO_REMOVE=(sysz.sh wifi.sh)
ATUIN_CONFIG="$CONFIG_DIR/atuin/config.toml"

# Ensure $HOME/.local/bin exists
mkdir -p $HOME/.local/bin

# Install fzf
if ! command -v fzf &> /dev/null; then
  echo "Installing fzf..."
  git clone --depth 1 https://github.com/junegunn/fzf.git $HOME/.fzf || { echo "Failed to install fzf"; exit 1; }
  $HOME/.fzf/install --all || { echo "Failed to install fzf"; exit 1; }
  cp $HOME/.fzf/bin/* $HOME/.local/bin
  rm -rf $HOME/.fzf
fi

# Install fd
if ! command -v fd &> /dev/null; then
  echo "Installing fd..."
  latest_version=$(curl -s https://api.github.com/repos/sharkdp/fd/releases/latest | jq -r .tag_name)
  if [ -f /etc/debian_version ]; then
    curl -LO "https://github.com/sharkdp/fd/releases/download/$latest_version/fd_${latest_version#v}_amd64.deb" || { echo "Failed to download fd"; exit 1; }
    sudo dpkg -i "fd_${latest_version#v}_amd64.deb" || { echo "Failed to install fd"; exit 1; }
    rm "fd_${latest_version#v}_amd64.deb"
  else
    curl -LO "https://github.com/sharkdp/fd/releases/download/$latest_version/fd-${latest_version}-x86_64-unknown-linux-gnu.tar.gz" || { echo "Failed to download fd"; exit 1; }
    tar -xzf "fd-${latest_version}-x86_64-unknown-linux-gnu.tar.gz" -C $HOME/.local/bin --strip-components=1 || { echo "Failed to extract fd"; exit 1; }
    rm "fd-${latest_version}-x86_64-unknown-linux-gnu.tar.gz"
  fi
fi

# Install ripgrep
if ! command -v rg &> /dev/null; then
  echo "Installing ripgrep..."
  latest_version=$(curl -s https://api.github.com/repos/BurntSushi/ripgrep/releases/latest | jq -r .tag_name)
  if [ -f /etc/debian_version ]; then
    curl -LO "https://github.com/BurntSushi/ripgrep/releases/download/$latest_version/ripgrep_${latest_version#v}-1_amd64.deb" || { echo "Failed to download ripgrep"; exit 1; }
    sudo dpkg -i "ripgrep_${latest_version#v}-1_amd64.deb" || { echo "Failed to install ripgrep"; exit 1; }
    rm "ripgrep_${latest_version#v}-1_amd64.deb"
  else
    echo "Skipping ripgrep installation..."
    # curl -LO "https://github.com/BurntSushi/ripgrep/releases/download/$latest_version/ripgrep-${latest_version#v}-x86_64-unknown-linux-musl.tar.gz" || { echo "Failed to download ripgrep"; exit 1; }
    # tar -xzf "ripgrep-${latest_version#v}-x86_64-unknown-linux-musl.tar.gz" -C $HOME/.local/bin --strip-components=1 || { echo "Failed to extract ripgrep"; exit 1; }
    # rm "ripgrep-${latest_version#v}-x86_64-unknown-linux-musl.tar.gz"
  fi
fi

# Install atuin
if ! command -v atuin &> /dev/null; then
  echo "Installing atuin..."
  if ! curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh; then
    echo "Failed to install atuin"
    exit 1
  fi
fi

# Install starship
if ! command -v starship &> /dev/null; then
  echo "Installing starship..."
  curl -sS https://starship.rs/install.sh | sh -s -- -y || { echo "Failed to install starship"; exit 1; }
fi

# Install zoxide
if ! command -v zoxide &> /dev/null; then
  echo "Installing zoxide..."
  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh || { echo "Failed to install zoxide"; exit 1; }
fi

# Install k9s
if ! command -v k9s &> /dev/null; then
  echo "Installing k9s..."
  if [ -f /etc/debian_version ]; then
    curl -LO https://github.com/derailed/k9s/releases/latest/download/k9s_linux_amd64.deb || { echo "Failed to download k9s"; exit 1; }
    sudo dpkg -i k9s_linux_amd64.deb || { echo "Failed to install k9s"; exit 1; }
    rm k9s_linux_amd64.deb
  else
    curl -LO https://github.com/derailed/k9s/releases/latest/download/k9s_linux_$(uname -m).tar.gz || { echo "Failed to download k9s"; exit 1; }
    tar -xzf k9s_linux_*.tar.gz -C $HOME/.local/bin || { echo "Failed to extract k9s"; exit 1; }
    rm k9s_Linux_*.tar.gz
  fi
fi


# Step 1: Copy files and directories from $HOME/dotfiles to $HOME/.config recursively, overwriting existing files
echo "Copying files and directories from $DOTFILES_DIR to $CONFIG_DIR"
# rsync -av --delete "$DOTFILES_DIR/" "$CONFIG_DIR/"
mkdir -p $HOME/.config
for item in $HOME/dotfiles/*; do
  dest="$HOME/.config/$(basename "$item")"
  if [ -d "$item" ]; then
    mkdir -p "$dest"
    cp -r "$item/"* "$dest"
  else
    cp -f "$item" "$dest"
  fi
done

# Update ATUIN files for local
chmod +rw $ATUIN_CONFIG
if [[ -f "$ATUIN_CONFIG" ]]; then
    # Use sed to remove lines that start with key_path or sync_address
    sed -i '/^key_path *=.*/d' "$ATUIN_CONFIG"
    sed -i '/^sync_address *=.*/d' "$ATUIN_CONFIG"

    echo "Lines removed from $ATUIN_CONFIG"
else
    echo "Config file not found: $ATUIN_CONFIG"
    exit 1
fi

# Remove a list of script that are not applicable to the current system
for script in "${SCRIPTS_TO_REMOVE[@]}"; do
  rm -f "$SCRIPTS_DIR/$script"
done

# Step 2: Make sure files in $HOME/.config/scripts are executable
echo "Setting execute permissions for files in $SCRIPTS_DIR"
for script in "$SCRIPTS_DIR"/*; do
  if [ -f "$script" ]; then
    chmod +x "$script"
  fi
done

# Step 3: Copy executable scripts to $HOME/bin and remove the .sh extension
echo "Copying scripts from $SCRIPTS_DIR to $BIN_DIR"
for script in "$SCRIPTS_DIR"/*; do
    if [ -f "$script" ]; then
        # Remove .sh extension and copy to bin directory
        script_name=$(basename "$script" .sh)
        cp "$script" "$BIN_DIR/$script_name"
    fi
done


if [ "$shell" = "bash" ]; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> $HOME/.bashrc
  echo 'export VISUAL=code' >> $HOME/.bashrc
  # echo 'export EDITOR="$VISUAL"' >> $HOME/.bashrc
  echo 'eval "$(starship init bash --print-full-init)"' >> $HOME/.bashrc
  echo 'eval "$(zoxide init bash --cmd cd --hook pwd)"' >> $HOME/.bashrc
  echo 'eval "$(fzf --bash)"' >> $HOME/.bashrc
  echo 'eval "$(atuin init bash)"' >> $HOME/.bashrc
  source $HOME/.bashrc
fi

if [ "$shell" = "zsh" ]; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> $HOME/.zshrc
  echo 'export VISUAL=code' >> $HOME/.zshrc
  # echo 'export EDITOR="$VISUAL"' >> $HOME/.zshrc
  echo 'eval "$(starship init zsh --print-full-init)"' >> $HOME/.zshrc
  echo 'eval "$(zoxide init zsh --cmd cd --hook pwd)"' >> $HOME/.zshrc
  echo 'eval "$(fzf --zsh)"' >> $HOME/.zshrc
  echo 'eval "$(atuin init zsh)"' >> $HOME/.zshrc
  source $HOME/.zshrc
fi

echo "Dotfiles and CLI tools setup complete!"
