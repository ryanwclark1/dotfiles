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
REQUIRED_TOOLS=(git curl jq)
# Ensure $HOME/.local/bin exists
mkdir -p $HOME/.local/bin

# Install fzf
install_fzf() {
  echo "Installing fzf..."
  git clone --depth 1 https://github.com/junegunn/fzf.git $HOME/.fzf || {
    echo "Failed to install fzf"
  }
  $HOME/.fzf/install --all || {
    echo "Failed to install fzf"
  }
  cp $HOME/.fzf/bin/* $HOME/.local/bin
  rm -rf $HOME/.fzf
}

# Install fd
install_fd() {
  echo "Installing fd..."
  latest_version=$(curl -s https://api.github.com/repos/sharkdp/fd/releases/latest | jq -r .tag_name)
  if [ -f /etc/debian_version ]; then
    curl -LO "https://github.com/sharkdp/fd/releases/download/$latest_version/fd_${latest_version#v}_amd64.deb" || {
      echo "Failed to download fd"
    }
    sudo dpkg -i "fd_${latest_version#v}_amd64.deb" || {
      echo "Failed to install fd"
    }
    rm "fd_${latest_version#v}_amd64.deb"
  else
    curl -LO "https://github.com/sharkdp/fd/releases/download/$latest_version/fd-${latest_version}-x86_64-unknown-linux-gnu.tar.gz" || {
      echo "Failed to download fd"
    }
    tar -xzf "fd-${latest_version}-x86_64-unknown-linux-gnu.tar.gz" -C $HOME/.local/bin --strip-components=1 || {
      echo "Failed to extract fd"
    }
    rm "fd-${latest_version}-x86_64-unknown-linux-gnu.tar.gz"
  fi
}

# Install ripgrep
install_rg() {
  echo "Installing ripgrep..."
  latest_version=$(curl -s https://api.github.com/repos/BurntSushi/ripgrep/releases/latest | jq -r .tag_name)
  if [ -f /etc/debian_version ]; then
    curl -LO "https://github.com/BurntSushi/ripgrep/releases/download/$latest_version/ripgrep_${latest_version#v}-1_amd64.deb" || {
      echo "Failed to download ripgrep"
    }
    sudo dpkg -i "ripgrep_${latest_version#v}-1_amd64.deb" || {
      echo "Failed to install ripgrep"
    }
    rm "ripgrep_${latest_version#v}-1_amd64.deb"
  else
    echo "Skipping ripgrep installation..."
    # curl -LO "https://github.com/BurntSushi/ripgrep/releases/download/$latest_version/ripgrep-${latest_version#v}-x86_64-unknown-linux-musl.tar.gz" || { echo "Failed to download ripgrep"; exit 1; }
    # tar -xzf "ripgrep-${latest_version#v}-x86_64-unknown-linux-musl.tar.gz" -C $HOME/.local/bin --strip-components=1 || { echo "Failed to extract ripgrep"; exit 1; }
    # rm "ripgrep-${latest_version#v}-x86_64-unknown-linux-musl.tar.gz"
  fi
}

# Install atuin
install_atuin() {
  echo "Installing atuin..."
  if ! curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh; then
    echo "Failed to install atuin"
  fi
}

# Install starship
install_starship() {
  echo "Installing starship..."
  curl -fsSL https://starship.rs/install.sh | sh -s -- -y || {
    echo "Failed to install starship"
    exit 1
  }
}

# Install zoxide
install_zoxide() {
  echo "Installing zoxide..."
  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh || {
    echo "Failed to install zoxide"
    exit 1
  }
}

# Install k9s
install_k9s() {
  echo "Installing k9s..."
  if [ -f /etc/debian_version ]; then
    if ! curl -LO https://github.com/derailed/k9s/releases/latest/download/k9s_linux_amd64.deb; then
      echo "Failed to download k9s"
    fi
    if ! sudo dpkg -i k9s_linux_amd64.deb; then
      echo "Failed to install k9s"
    fi
    rm k9s_linux_amd64.deb
  elif [ -n "$(uname -m)" ]; then
    if ! curl -LO https://github.com/derailed/k9s/releases/latest/download/k9s_linux_$(uname -m).tar.gz; then
      echo "Failed to download k9s"
    fi
    if ! tar -xzf k9s_linux_*.tar.gz -C $HOME/.local/bin; then
      echo "Failed to extract k9s"
    fi
    rm k9s_linux_*.tar.gz
  else
    echo "Failed to install k9s"
  fi
}

check_installs() {
  if ! command -v fzf &>/dev/null; then
    install_fzf
  fi

  if ! command -v fd &>/dev/null; then
    install_fd
  fi

  if ! command -v rg &>/dev/null; then
    install_rg
  fi

  if ! command -v atuin &>/dev/null; then
    install_atuin
  fi

  if ! command -v starship &>/dev/null; then
    install_starship
  fi

  if ! command -v zoxide &>/dev/null; then
    install_zoxide
  fi

  if ! command -v k9s &>/dev/null; then
    install_k9s
  fi
}

check_proc() {
    # Check for /proc by looking for the /proc/self/exe link.
    # This is only run on Linux.
    if ! test -L /proc/self/exe ; then
        err "fatal: Unable to find /proc/self/exe.  Is /proc mounted?  Installation cannot proceed without /proc."
    fi
}

need_cmd() {
    if ! check_cmd "$1"; then
        err "need '$1' (command not found)"
    fi
}

check_cmd() {
    command -v "$1" > /dev/null 2>&1
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

get_bitness() {
    need_cmd head
    # Architecture detection without dependencies beyond coreutils.
    # ELF files start out "\x7fELF", and the following byte is
    #   0x01 for 32-bit and
    #   0x02 for 64-bit.
    # The printf builtin on some shells like dash only supports octal
    # escape sequences, so we use those.
    local _current_exe_head
    _current_exe_head=$(head -c 5 /proc/self/exe)
    if [ "${_current_exe_head}" = "$(printf '\177ELF\001')" ]; then
        echo 32
    elif [ "${_current_exe_head}" = "$(printf '\177ELF\002')" ]; then
        echo 64
    else
        err "unknown platform bitness"
    fi
}

get_endianness() {
    local cputype="$1"
    local suffix_eb="$2"
    local suffix_el="$3"

    # detect endianness without od/hexdump, like get_bitness() does.
    need_cmd head
    need_cmd tail

    local _current_exe_endianness
    _current_exe_endianness="$(head -c 6 /proc/self/exe | tail -c 1)"
    if [ "${_current_exe_endianness}" = "$(printf '\001')" ]; then
        echo "${cputype}${suffix_el}"
    elif [ "${_current_exe_endianness}" = "$(printf '\002')" ]; then
        echo "${cputype}${suffix_eb}"
    else
        err "unknown platform endianness"
    fi
}

is_host_amd64_elf() {
    need_cmd head
    need_cmd tail
    # ELF e_machine detection without dependencies beyond coreutils.
    # Two-byte field at offset 0x12 indicates the CPU,
    # but we're interested in it being 0x3E to indicate amd64, or not that.
    local _current_exe_machine
    _current_exe_machine=$(head -c 19 /proc/self/exe | tail -c 1)
    [ "${_current_exe_machine}" = "$(printf '\076')" ]
}

ensure() {
    if ! "$@"; then err "command failed: $*"; fi
}

assert_nz() {
    if [ -z "$1" ]; then err "found empty string: $2"; fi
}

# Configure shell
configure_shell() {
  local shell_rc="$1"
  local shell_type="$2"
  local editor="nano"
  
  # Check if VS Code is installed
  if command -v code &>/dev/null; then
    editor="code"
  fi

  # Function to safely append text if it doesn't exist
  safe_append() {
    local text="$1"
    if ! grep -qF "$text" "$shell_rc"; then
      echo "$text" >> "$shell_rc"
    fi
  }

  # Create a temporary file for the new configuration
  local temp_rc="$(mktemp)"

  # Add PATH if not already present
  safe_append 'export PATH="$HOME/.local/bin:$PATH"'
  
  # Set editor
  safe_append "export VISUAL=$editor"
  
  # Initialize tools in the correct order
  case "$shell_type" in
    bash)
      safe_append '[ -f ~/.fzf.bash ] && source ~/.fzf.bash'
      safe_append '. "$HOME/.atuin/bin/env"'
      safe_append '[[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh'
      safe_append 'eval "$(atuin init bash)"'
      safe_append 'eval "$(starship init bash --print-full-init)"'
      safe_append 'eval "$(zoxide init bash --cmd cd --hook pwd)"'
      ;;
    zsh)
      safe_append '[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh'
      safe_append '. "$HOME/.atuin/bin/env"'
      safe_append 'eval "$(atuin init zsh)"'
      safe_append 'eval "$(starship init zsh --print-full-init)"'
      safe_append 'eval "$(zoxide init zsh --cmd cd --hook pwd)"'
      ;;
  esac
  
  # Source the rc file
  source "$shell_rc"
}

main() {
  local _arch
  _arch="${ARCH:-$(ensure get_architecture)}"
  assert_nz "${_arch}" "arch"
  echo "Detected architecture: ${_arch}"
  check_installs

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
  fi

  # Remove a list of script that are not applicable to the current system
  for script in "${SCRIPTS_TO_REMOVE[@]}"; do
    rm -f "$SCRIPTS_DIR/$script"
    echo "Removed $SCRIPTS_DIR/$script"
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
    configure_shell "$HOME/.bashrc" "bash"
  elif [ "$shell" = "zsh" ]; then
    configure_shell "$HOME/.zshrc" "zsh"
  fi

  echo "Dotfiles and CLI tools setup complete!"
}

{
  main "$@" || exit 1
}
