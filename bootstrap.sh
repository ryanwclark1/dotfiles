#!/usr/bin/env bash
set -e

echo "Setting up dotfiles and installing CLI tools..."

# Dynamic path detection
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR"
CONFIG_DIR="$HOME/.config"
SCRIPTS_DIR="$CONFIG_DIR/scripts"
BIN_DIR="$HOME/.local/bin"

# Required tools for validation
REQUIRED_TOOLS=(git curl jq)

# Architecture and platform detection
detect_platform() {
    local os arch platform
    
    # Detect OS
    case "$(uname -s)" in
        Darwin*) os="darwin" ;;
        Linux*)  os="linux" ;;
        *)       error "Unsupported operating system: $(uname -s)" ;;
    esac
    
    # Detect architecture
    case "$(uname -m)" in
        x86_64|amd64) arch="amd64" ;;
        arm64|aarch64) arch="arm64" ;;
        armv7l) arch="armv7" ;;
        *)      error "Unsupported architecture: $(uname -m)" ;;
    esac
    
    platform="${os}-${arch}"
    echo "$platform"
}

# Global platform variables
PLATFORM=$(detect_platform)
OS=$(echo "$PLATFORM" | cut -d'-' -f1)
ARCH=$(echo "$PLATFORM" | cut -d'-' -f2)

# Tools to install with their installation methods
declare -A TOOLS=(
    ["fzf"]="install_from_git"
    ["fd"]="install_from_github"
    ["rg"]="install_from_github"
    ["atuin"]="install_from_script"
    ["starship"]="install_from_script"
    ["zoxide"]="install_from_script"
    ["k9s"]="install_from_github"
)

# Tool-specific configuration with platform support
declare -A TOOL_CONFIG=(
    ["fzf_repo"]="https://github.com/junegunn/fzf.git"
    ["fzf_install_script"]="install --all"
    
    ["fd_repo"]="sharkdp/fd"
    ["fd_debian_pattern"]="fd_{version}_amd64.deb"
    ["fd_linux_amd64_pattern"]="fd-{version}-x86_64-unknown-linux-gnu.tar.gz"
    ["fd_linux_arm64_pattern"]="fd-{version}-aarch64-unknown-linux-gnu.tar.gz"
    ["fd_darwin_amd64_pattern"]="fd-{version}-x86_64-apple-darwin.tar.gz"
    ["fd_darwin_arm64_pattern"]="fd-{version}-aarch64-apple-darwin.tar.gz"
    
    ["rg_repo"]="BurntSushi/ripgrep"
    ["rg_debian_pattern"]="ripgrep_{version}-1_amd64.deb"
    ["rg_linux_amd64_pattern"]="ripgrep-{version}-x86_64-unknown-linux-musl.tar.gz"
    ["rg_linux_arm64_pattern"]="ripgrep-{version}-aarch64-unknown-linux-gnu.tar.gz"
    ["rg_darwin_amd64_pattern"]="ripgrep-{version}-x86_64-apple-darwin.tar.gz"
    ["rg_darwin_arm64_pattern"]="ripgrep-{version}-aarch64-apple-darwin.tar.gz"
    
    ["starship_repo"]="starship/starship"
    ["starship_linux_amd64_pattern"]="starship-x86_64-unknown-linux-musl.tar.gz"
    ["starship_linux_arm64_pattern"]="starship-aarch64-unknown-linux-musl.tar.gz"
    ["starship_linux_armv7_pattern"]="starship-arm-unknown-linux-musleabihf.tar.gz"
    ["starship_darwin_amd64_pattern"]="starship-x86_64-apple-darwin.tar.gz"
    ["starship_darwin_arm64_pattern"]="starship-aarch64-apple-darwin.tar.gz"
    
    ["atuin_script"]="https://setup.atuin.sh"
    ["starship_script"]="https://starship.rs/install.sh"
    ["zoxide_script"]="https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh"
    
    ["k9s_repo"]="derailed/k9s"
    ["k9s_debian_pattern"]="k9s_linux_amd64.deb"
    ["k9s_linux_amd64_pattern"]="k9s_linux_amd64.tar.gz"
    ["k9s_linux_arm64_pattern"]="k9s_linux_arm64.tar.gz"
    ["k9s_darwin_amd64_pattern"]="k9s_darwin_amd64.tar.gz"
    ["k9s_darwin_arm64_pattern"]="k9s_darwin_arm64.tar.gz"
)

# Utility functions
log() {
    echo "[$1] $2"
}

error() {
    log "ERROR" "$1" >&2
    exit 1
}

check_dependencies() {
    log "INFO" "Checking required dependencies..."
    for tool in "${REQUIRED_TOOLS[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            error "Required tool '$tool' is not installed"
        fi
    done
}

get_latest_version() {
    local repo="$1"
    curl -s "https://api.github.com/repos/$repo/releases/latest" | jq -r .tag_name
}

# Generic installer function
install_tool() {
    local tool="$1"
    local method="${TOOLS[$tool]}"
    
    log "INFO" "Installing $tool using method: $method"
    
    case "$method" in
        "install_from_git")
            install_from_git "$tool"
            ;;
        "install_from_github")
            install_from_github "$tool"
            ;;
        "install_from_script")
            install_from_script "$tool"
            ;;
        *)
            error "Unknown installation method: $method for tool: $tool"
            ;;
    esac
}

install_from_git() {
    local tool="$1"
    local repo_key="${tool}_repo"
    local repo="${TOOL_CONFIG[$repo_key]}"
    local install_script_key="${tool}_install_script"
    local install_script="${TOOL_CONFIG[$install_script_key]}"
    
    local temp_dir="$HOME/.${tool}_temp"
    
    if git clone --depth 1 "$repo" "$temp_dir"; then
        cd "$temp_dir"
        if ./$install_script; then
            # Copy binaries to local bin
            if [[ -d "bin" ]]; then
                cp bin/* "$BIN_DIR/" 2>/dev/null || true
            fi
            cd - > /dev/null
            rm -rf "$temp_dir"
            log "INFO" "$tool installed successfully"
        else
            rm -rf "$temp_dir"
            error "Failed to install $tool"
        fi
    else
        error "Failed to clone $tool repository"
    fi
}

install_from_github() {
    local tool="$1"
    local repo_key="${tool}_repo"
    local repo="${TOOL_CONFIG[$repo_key]}"
    
    local version=$(get_latest_version "$repo")
    [[ -z "$version" ]] && error "Failed to get latest version for $tool"
    
    # Prefer Debian packages on Linux with apt, otherwise use tarballs
    if [[ "$OS" == "linux" && -f /etc/debian_version && "$ARCH" == "amd64" ]]; then
        install_debian_package "$tool" "$repo" "$version"
    else
        install_platform_tarball "$tool" "$repo" "$version"
    fi
}

install_debian_package() {
    local tool="$1"
    local repo="$2"
    local version="$3"
    local pattern_key="${tool}_debian_pattern"
    local pattern="${TOOL_CONFIG[$pattern_key]}"
    
    # Replace {version} placeholder
    local filename="${pattern/\{version\}/${version#v}}"
    local url="https://github.com/$repo/releases/download/$version/$filename"
    
    if curl -L -o "$filename" "$url"; then
        if sudo dpkg -i "$filename"; then
            rm "$filename"
            log "INFO" "$tool installed successfully"
        else
            rm "$filename"
            error "Failed to install $tool package"
        fi
    else
        error "Failed to download $tool package"
    fi
}

install_platform_tarball() {
    local tool="$1"
    local repo="$2"
    local version="$3"
    local pattern_key="${tool}_${OS}_${ARCH}_pattern"
    local pattern="${TOOL_CONFIG[$pattern_key]}"
    
    # Check if platform-specific pattern exists
    if [[ -z "$pattern" ]]; then
        error "No installation pattern found for $tool on $OS-$ARCH"
    fi
    
    # Replace version placeholder (if it exists)
    local filename="$pattern"
    if [[ "$pattern" == *"{version}"* ]]; then
        filename="${pattern/\{version\}/${version#v}}"
    fi
    local url="https://github.com/$repo/releases/download/$version/$filename"
    
    # Validate filename before download
    if [[ -z "$filename" ]]; then
        error "Empty filename for $tool on $OS-$ARCH (pattern: $pattern)"
    fi
    
    log "INFO" "Downloading $tool for $OS-$ARCH: $filename"
    log "INFO" "URL: $url"
    
    if curl -L -o "$filename" "$url"; then
        # Try different extraction methods based on the file type
        if [[ "$filename" == *.tar.gz ]]; then
            # Special handling for starship (binary in archive root)
            if [[ "$tool" == "starship" ]]; then
                if tar -xzf "$filename" -O starship > "$BIN_DIR/starship" && chmod +x "$BIN_DIR/starship"; then
                    rm "$filename"
                    log "INFO" "$tool installed successfully"
                else
                    rm "$filename"
                    error "Failed to extract $tool binary"
                fi
            # Try with --strip-components first, then without for other tools
            elif tar -xzf "$filename" -C "$BIN_DIR" --strip-components=1 2>/dev/null ||
                 tar -xzf "$filename" -C "$BIN_DIR" 2>/dev/null; then
                rm "$filename"
                log "INFO" "$tool installed successfully"
            else
                rm "$filename"
                error "Failed to extract $tool archive"
            fi
        elif [[ "$filename" == *.zip ]]; then
            if command -v unzip &>/dev/null; then
                if unzip -o "$filename" -d "$BIN_DIR" >/dev/null; then
                    rm "$filename"
                    log "INFO" "$tool installed successfully"
                else
                    rm "$filename"
                    error "Failed to extract $tool zip file"
                fi
            else
                rm "$filename"
                error "unzip command not found, cannot extract $filename"
            fi
        else
            rm "$filename"
            error "Unsupported archive format for $filename"
        fi
    else
        error "Failed to download $tool from $url"
    fi
}

install_from_script() {
    local tool="$1"
    local script_key="${tool}_script"
    local script_url="${TOOL_CONFIG[$script_key]}"
    
    case "$tool" in
        "atuin")
            if curl --proto '=https' --tlsv1.2 -LsSf "$script_url" | sh; then
                log "INFO" "$tool installed successfully"
            else
                error "Failed to install $tool"
            fi
            ;;
        "starship")
            if env -i PATH="$PATH" HOME="$HOME" USER="$USER" curl -sS "$script_url" | sh -s -- --yes --bin-dir "$BIN_DIR"; then
                log "INFO" "$tool installed successfully"
            else
                error "Failed to install $tool"
            fi
            ;;
        "zoxide")
            if curl -sSfL "$script_url" | sh; then
                log "INFO" "$tool installed successfully"
            else
                error "Failed to install $tool"
            fi
            ;;
        *)
            error "Unknown script installation for tool: $tool"
            ;;
    esac
}

check_and_install_tools() {
    log "INFO" "Checking and installing tools..."
    for tool in "${!TOOLS[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            install_tool "$tool"
        else
            log "INFO" "$tool is already installed"
        fi
    done
}

setup_directories() {
    log "INFO" "Setting up directories..."
    mkdir -p "$BIN_DIR" "$CONFIG_DIR"
}

copy_configurations() {
    log "INFO" "Copying configurations from $DOTFILES_DIR to $CONFIG_DIR"
    
    # Use rsync for efficient copying
    if command -v rsync &>/dev/null; then
        # Exclude the script itself and git files
        local rsync_cmd="rsync -av --exclude=*.sh --exclude=.git* --exclude=CLAUDE.md"
        
        # On macOS, handle extended attributes properly
        if [[ "$OS" == "darwin" ]]; then
            rsync_cmd="$rsync_cmd -E"
        fi
        
        $rsync_cmd "$DOTFILES_DIR/" "$CONFIG_DIR/"
    else
        # Fallback to manual copying
        for item in "$DOTFILES_DIR"/*; do
            local basename_item=$(basename "$item")
            # Skip script files and git files
            [[ "$basename_item" == *.sh ]] && continue
            [[ "$basename_item" == .git* ]] && continue
            [[ "$basename_item" == "CLAUDE.md" ]] && continue
            
            local dest="$CONFIG_DIR/$basename_item"
            if [[ -d "$item" ]]; then
                mkdir -p "$dest"
                if [[ "$OS" == "darwin" ]]; then
                    cp -R "$item/"* "$dest" 2>/dev/null || cp -r "$item/"* "$dest"
                else
                    cp -r "$item/"* "$dest"
                fi
            else
                cp -f "$item" "$dest"
            fi
        done
    fi
}

setup_scripts() {
    log "INFO" "Setting up executable scripts..."
    
    if [[ -d "$SCRIPTS_DIR" ]]; then
        # Make all scripts executable
        chmod +x "$SCRIPTS_DIR"/* 2>/dev/null || true
        
        # Copy scripts to bin directory without .sh extension
        for script in "$SCRIPTS_DIR"/*; do
            if [[ -f "$script" ]]; then
                local script_name=$(basename "$script" .sh)
                cp "$script" "$BIN_DIR/$script_name"
                chmod +x "$BIN_DIR/$script_name"
            fi
        done
    fi
}

configure_atuin() {
    log "INFO" "Configuring atuin for local use..."
    local atuin_config="$CONFIG_DIR/atuin/config.toml"
    
    if [[ -f "$atuin_config" ]]; then
        chmod +rw "$atuin_config"
        # Remove sync-related configurations for local setup
        sed -i '/^key_path *=.*/d' "$atuin_config" 2>/dev/null || true
        sed -i '/^sync_address *=.*/d' "$atuin_config" 2>/dev/null || true
        log "INFO" "Atuin configured for local use"
    fi
}

configure_shell() {
    local shell=$(basename "$SHELL")
    local shell_rc=""
    
    case "$shell" in
        bash) shell_rc="$HOME/.bashrc" ;;
        zsh) shell_rc="$HOME/.zshrc" ;;
        *) 
            log "WARN" "Unsupported shell: $shell. Skipping shell configuration."
            return
            ;;
    esac
    
    log "INFO" "Configuring $shell shell..."
    
    # Clear any conflicting starship environment variables
    unset STARSHIP_SHELL STARSHIP_SESSION_KEY
    
    # Determine editor
    local editor="nano"
    command -v code &>/dev/null && editor="code"
    
    # Function to safely append to shell config
    safe_append() {
        local text="$1"
        # Ensure the shell config file exists and is writable
        touch "$shell_rc" 2>/dev/null || {
            log "WARN" "Cannot create $shell_rc, skipping shell configuration"
            return 1
        }
        chmod +w "$shell_rc" 2>/dev/null || {
            log "WARN" "Cannot make $shell_rc writable, skipping shell configuration"
            return 1
        }
        if ! grep -qF "$text" "$shell_rc" 2>/dev/null; then
            echo "$text" >> "$shell_rc"
        fi
    }
    
    # Add essential configurations
    safe_append 'export PATH="$HOME/.local/bin:$PATH"'
    safe_append "export VISUAL=$editor"
    
    # Add tool initializations based on shell
    case "$shell" in
        bash)
            safe_append '[ -f ~/.fzf.bash ] && source ~/.fzf.bash'
            safe_append '. "$HOME/.atuin/bin/env" 2>/dev/null || true'
            safe_append '[[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh'
            safe_append 'eval "$(atuin init bash)" 2>/dev/null || true'
            safe_append 'eval "$(starship init bash --print-full-init)" 2>/dev/null || true'
            safe_append 'eval "$(zoxide init bash --cmd cd --hook pwd)" 2>/dev/null || true'
            ;;
        zsh)
            safe_append '[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh'
            safe_append '. "$HOME/.atuin/bin/env" 2>/dev/null || true'
            safe_append 'eval "$(atuin init zsh)" 2>/dev/null || true'
            safe_append 'eval "$(starship init zsh --print-full-init)" 2>/dev/null || true'
            safe_append 'eval "$(zoxide init zsh --cmd cd --hook pwd)" 2>/dev/null || true'
            ;;
    esac
    
    # Initialize starship for current session
    if command -v starship &>/dev/null; then
        eval "$(starship init "$shell")" 2>/dev/null || log "WARN" "Starship will be available in new shell sessions"
    fi
}

main() {
    log "INFO" "Starting dotfiles setup..."
    log "INFO" "Detected platform: $PLATFORM (OS: $OS, Architecture: $ARCH)"
    
    check_dependencies
    setup_directories
    check_and_install_tools
    copy_configurations
    setup_scripts
    configure_atuin
    configure_shell
    
    log "INFO" "Dotfiles and CLI tools setup complete!"
    log "INFO" "Please restart your shell or run 'source ~/.${SHELL##*/}rc' to activate changes"
}

# Run main function
main "$@"