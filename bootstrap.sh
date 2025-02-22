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
install_fzf() {
  echo "Installing fzf..."
  git clone --depth 1 https://github.com/junegunn/fzf.git $HOME/.fzf || { echo "Failed to install fzf"; exit 1; }
  $HOME/.fzf/install --all || { echo "Failed to install fzf"; exit 1; }
  cp $HOME/.fzf/bin/* $HOME/.local/bin
  rm -rf $HOME/.fzf
}

install_fd(){
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
}

install_rg(){
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
}

install_atuin(){
  echo "Installing atuin..."
  if ! curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh; then
    echo "Failed to install atuin"
  fi
}

install_starship(){
  echo "Installing starship..."
  curl -fsSL https://starship.rs/install.sh | bash -s -- -y || { echo "Failed to install starship"; exit 1; }
}

install_zoxide(){
  echo "Installing zoxide..."
  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh || { echo "Failed to install zoxide"; exit 1; }
}

install_k9s(){
  echo "Installing k9s..."
  if [ -f /etc/debian_version ]; then
    if ! curl -LO https://github.com/derailed/k9s/releases/latest/download/k9s_linux_amd64.deb; then
      echo "Failed to download k9s"
      exit 1
    fi
    if ! sudo dpkg -i k9s_linux_amd64.deb; then
      echo "Failed to install k9s"
      exit 1
    fi
    rm k9s_linux_amd64.deb
  elif [ -n "$(uname -m)" ]; then
    if ! curl -LO https://github.com/derailed/k9s/releases/latest/download/k9s_linux_$(uname -m).tar.gz; then
      echo "Failed to download k9s"
      exit 1
    fi
    if ! tar -xzf k9s_linux_*.tar.gz -C $HOME/.local/bin; then
      echo "Failed to extract k9s"
    fi
    rm k9s_linux_*.tar.gz
  else
    echo "Failed to install k9s"
  fi
}

check_installs(){
  if ! command -v fzf &> /dev/null; then
    install_fzf
  fi

  if ! command -v fd &> /dev/null; then
    install_fd
  fi

  if ! command -v rg &> /dev/null; then
    install_rg
  fi

  if ! command -v atuin &> /dev/null; then
    install_atuin
  fi

  if ! command -v starship &> /dev/null; then
    install_starship
  fi

  if ! command -v zoxide &> /dev/null; then
    install_zoxide
  fi

  if ! command -v k9s &> /dev/null; then
    install_k9s
  fi
}

get_architecture() {
  local _ostype _cputype _bitness _arch _clibtype
  _ostype="$(uname -s)"
  _cputype="$(uname -m)"
  _clibtype="musl"

  if [ "${_ostype}" = Linux ]; then
      if [ "$(uname -o || true)" = Android ]; then
          _ostype=Android
      fi
  fi

  if [ "${_ostype}" = Darwin ] && [ "${_cputype}" = i386 ]; then
      # Darwin `uname -m` lies
      if sysctl hw.optional.x86_64 | grep -q ': 1'; then
          _cputype=x86_64
      fi
  fi

  if [ "${_ostype}" = SunOS ]; then
      # Both Solaris and illumos presently announce as "SunOS" in "uname -s"
      # so use "uname -o" to disambiguate.  We use the full path to the
      # system uname in case the user has coreutils uname first in PATH,
      # which has historically sometimes printed the wrong value here.
      if [ "$(/usr/bin/uname -o || true)" = illumos ]; then
          _ostype=illumos
      fi

      # illumos systems have multi-arch userlands, and "uname -m" reports the
      # machine hardware name; e.g., "i86pc" on both 32- and 64-bit x86
      # systems.  Check for the native (widest) instruction set on the
      # running kernel:
      if [ "${_cputype}" = i86pc ]; then
          _cputype="$(isainfo -n)"
      fi
  fi

  case "${_ostype}" in
  Android)
      _ostype=linux-android
      ;;
  Linux)
      check_proc
      _ostype=unknown-linux-${_clibtype}
      _bitness=$(get_bitness)
      ;;
  FreeBSD)
      _ostype=unknown-freebsd
      ;;
  NetBSD)
      _ostype=unknown-netbsd
      ;;
  DragonFly)
      _ostype=unknown-dragonfly
      ;;
  Darwin)
      _ostype=apple-darwin
      ;;
  illumos)
      _ostype=unknown-illumos
      ;;
  MINGW* | MSYS* | CYGWIN* | Windows_NT)
      _ostype=pc-windows-msvc
      ;;
  *)
      err "unrecognized OS type: ${_ostype}"
      ;;
  esac

  case "${_cputype}" in
  i386 | i486 | i686 | i786 | x86)
      _cputype=i686
      ;;
  xscale | arm)
      _cputype=arm
      if [ "${_ostype}" = "linux-android" ]; then
          _ostype=linux-androideabi
      fi
      ;;
  armv6l)
      _cputype=arm
      if [ "${_ostype}" = "linux-android" ]; then
          _ostype=linux-androideabi
      else
          _ostype="${_ostype}eabihf"
      fi
      ;;
  armv7l | armv8l)
      _cputype=armv7
      if [ "${_ostype}" = "linux-android" ]; then
          _ostype=linux-androideabi
      else
          _ostype="${_ostype}eabihf"
      fi
      ;;
  aarch64 | arm64)
      _cputype=aarch64
      ;;
  x86_64 | x86-64 | x64 | amd64)
      _cputype=x86_64
      ;;
  mips)
      _cputype=$(get_endianness mips '' el)
      ;;
  mips64)
      if [ "${_bitness}" -eq 64 ]; then
          # only n64 ABI is supported for now
          _ostype="${_ostype}abi64"
          _cputype=$(get_endianness mips64 '' el)
      fi
      ;;
  ppc)
      _cputype=powerpc
      ;;
  ppc64)
      _cputype=powerpc64
      ;;
  ppc64le)
      _cputype=powerpc64le
      ;;
  s390x)
      _cputype=s390x
      ;;
  riscv64)
      _cputype=riscv64gc
      ;;
  *)
      err "unknown CPU type: ${_cputype}"
      ;;
  esac

  # Detect 64-bit linux with 32-bit userland
  if [ "${_ostype}" = unknown-linux-musl ] && [ "${_bitness}" -eq 32 ]; then
      case ${_cputype} in
      x86_64)
          # 32-bit executable for amd64 = x32
          if is_host_amd64_elf; then {
              err "x32 userland is unsupported"
          }; else
              _cputype=i686
          fi
          ;;
      mips64)
          _cputype=$(get_endianness mips '' el)
          ;;
      powerpc64)
          _cputype=powerpc
          ;;
      aarch64)
          _cputype=armv7
          if [ "${_ostype}" = "linux-android" ]; then
              _ostype=linux-androideabi
          else
              _ostype="${_ostype}eabihf"
          fi
          ;;
      riscv64gc)
          err "riscv64 with 32-bit userland unsupported"
          ;;
      *) ;;
      esac
  fi

  # Detect armv7 but without the CPU features Rust needs in that build,
  # and fall back to arm.
  # See https://github.com/rust-lang/rustup.rs/issues/587.
  if [ "${_ostype}" = "unknown-linux-musleabihf" ] && [ "${_cputype}" = armv7 ]; then
      if ensure grep '^Features' /proc/cpuinfo | grep -q -v neon; then
          # At least one processor does not have NEON.
          _cputype=arm
      fi
  fi

    _arch="${_cputype}-${_ostype}"
    echo "${_arch}"
}



local _arch
_arch="${ARCH:-$(ensure get_architecture)}"
assert_nz "${_arch}" "arch"
echo "Detected architecture: ${_arch}"

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
