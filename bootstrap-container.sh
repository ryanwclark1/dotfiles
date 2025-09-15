#!/usr/bin/env bash
set -euo pipefail

# Container-safe bootstrap script for VS Code Dev Containers
# This script only copies configurations without installing tools

# Dynamic path detection
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR"
CONFIG_DIR="$HOME/.config"
BIN_DIR="$HOME/.local/bin"

echo "Setting up dotfiles configurations for container environment..."

# Utility functions
log() {
    echo "[$1] $2"
}

error() {
    log "ERROR" "$1" >&2
    exit 1
}

# Create necessary directories
create_directories() {
    log "INFO" "Creating directories..."
    if mkdir -p "$CONFIG_DIR" 2>/dev/null; then
        log "INFO" "Created config directory: $CONFIG_DIR"
    else
        log "WARN" "Could not create config directory (read-only filesystem?)"
    fi
    
    if mkdir -p "$BIN_DIR" 2>/dev/null; then
        log "INFO" "Created bin directory: $BIN_DIR"
    else
        log "WARN" "Could not create bin directory (read-only filesystem?)"
    fi
}

# Copy configuration files
copy_configs() {
    log "INFO" "Copying configuration files..."
    
    # Copy starship config if it exists
    if [[ -f "$DOTFILES_DIR/starship.toml" ]]; then
        if cp "$DOTFILES_DIR/starship.toml" "$CONFIG_DIR/" 2>/dev/null; then
            log "INFO" "Copied starship configuration"
        else
            log "WARN" "Could not copy starship config (read-only filesystem?)"
        fi
    fi
    
    # Copy configuration directories
    local config_dirs=("atuin" "bat" "eza" "fd" "k9s" "navi" "ripgrep" "ripgrep-all" "tealdeer")
    
    for dir in "${config_dirs[@]}"; do
        if [[ -d "$DOTFILES_DIR/$dir" ]]; then
            if command -v rsync >/dev/null 2>&1; then
                if rsync -a "$DOTFILES_DIR/$dir/" "$CONFIG_DIR/$dir/" 2>/dev/null; then
                    log "INFO" "Copied $dir configuration"
                else
                    log "WARN" "Could not copy $dir configuration (read-only filesystem?)"
                fi
            else
                if cp -r "$DOTFILES_DIR/$dir" "$CONFIG_DIR/" 2>/dev/null; then
                    log "INFO" "Copied $dir configuration"
                else
                    log "WARN" "Could not copy $dir configuration (read-only filesystem?)"
                fi
            fi
        fi
    done
}

# Setup scripts (container-safe)
setup_scripts() {
    log "INFO" "Setting up executable scripts..."
    
    if [[ -d "$DOTFILES_DIR/scripts" ]]; then
        # Copy scripts to bin directory
        for script in "$DOTFILES_DIR/scripts"/*; do
            if [[ -f "$script" && ! "$script" =~ \.(backup|bak)$ ]]; then
                local script_name=$(basename "$script" .sh)
                # Skip backup files
                if [[ ! "$script_name" =~ \.(backup|bak)$ ]]; then
                    cp "$script" "$BIN_DIR/$script_name"
                    chmod +x "$BIN_DIR/$script_name"
                    log "INFO" "Installed script: $script_name"
                fi
            fi
        done
    fi
}

# Configure shell (minimal, container-safe)
configure_shell() {
    log "INFO" "Configuring shell for container..."
    
    # Detect shell
    local shell_rc=""
    case "$(basename "$SHELL")" in
        bash) shell_rc="$HOME/.bashrc" ;;
        zsh) shell_rc="$HOME/.zshrc" ;;
        *) log "WARN" "Unknown shell, skipping shell configuration" ;;
    esac
    
    if [[ -n "$shell_rc" ]]; then
        # Create shell config if it doesn't exist
        touch "$shell_rc"
        
        # Add PATH for local bin if not already present
        if ! grep -q "$HOME/.local/bin" "$shell_rc" 2>/dev/null; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$shell_rc"
            log "INFO" "Added local bin to PATH"
        fi
        
        # Copy aliases if they exist
        if [[ -f "$DOTFILES_DIR/alias" ]]; then
            echo "" >> "$shell_rc"
            echo "# Dotfiles aliases" >> "$shell_rc"
            cat "$DOTFILES_DIR/alias" >> "$shell_rc"
            log "INFO" "Added aliases to shell configuration"
        fi
        
        # Initialize starship if available (don't install it)
        if command -v starship >/dev/null 2>&1; then
            if ! grep -q "starship init" "$shell_rc" 2>/dev/null; then
                echo 'eval "$(starship init bash)"' >> "$shell_rc"
                log "INFO" "Added starship initialization"
            fi
        fi
    fi
}

# Configure atuin for container use
configure_atuin() {
    log "INFO" "Configuring atuin for container use..."
    local atuin_config="$CONFIG_DIR/atuin/config.toml"
    
    if [[ -f "$atuin_config" ]]; then
        # Remove sync-related configurations for container setup
        sed -i '/^key_path *=.*/d' "$atuin_config" 2>/dev/null || true
        sed -i '/^sync_address *=.*/d' "$atuin_config" 2>/dev/null || true
        log "INFO" "Atuin configured for local use"
    fi
}

# Main execution
main() {
    log "INFO" "Starting container-safe dotfiles setup..."
    
    create_directories
    copy_configs
    setup_scripts
    configure_shell
    configure_atuin
    
    log "INFO" "Container-safe dotfiles setup completed!"
    log "INFO" "Note: Tools are not installed in container mode. Use container's package manager if needed."
}

# Run main function
main "$@"