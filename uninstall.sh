#!/usr/bin/env bash
#
# uninstall.sh - Cleanly remove all dotfiles installations
#
# Usage:
#   ./uninstall.sh [OPTIONS]
#
# Options:
#   -h, --help       Show this help message
#   -y, --yes        Skip confirmation prompts
#   -b, --backup     Create backup before uninstalling
#   --keep-tools     Keep installed tools, only remove configs
#   --dry-run        Show what would be removed without removing
#   -v, --verbose    Enable verbose output

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Configuration
DRY_RUN=false
SKIP_CONFIRM=false
CREATE_BACKUP=false
KEEP_TOOLS=false
VERBOSE=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    case "$level" in
        INFO)
            echo -e "${BLUE}[INFO]${NC} $message"
            ;;
        WARN)
            echo -e "${YELLOW}[WARN]${NC} $message" >&2
            ;;
        ERROR)
            echo -e "${RED}[ERROR]${NC} $message" >&2
            ;;
        SUCCESS)
            echo -e "${GREEN}[SUCCESS]${NC} $message"
            ;;
        DEBUG)
            if [[ "$VERBOSE" == "true" ]]; then
                echo -e "[DEBUG] $message"
            fi
            ;;
    esac
}

# Show usage
usage() {
    cat <<EOF
Dotfiles Uninstaller

Usage: $(basename "$0") [OPTIONS]

Cleanly removes all dotfiles installations from your system.

Options:
    -h, --help       Show this help message
    -y, --yes        Skip confirmation prompts
    -b, --backup     Create backup before uninstalling
    --keep-tools     Keep installed tools, only remove configs
    --dry-run        Show what would be removed without removing
    -v, --verbose    Enable verbose output

Examples:
    # Preview what will be removed
    ./uninstall.sh --dry-run

    # Uninstall with backup
    ./uninstall.sh --backup

    # Remove only configs, keep tools
    ./uninstall.sh --keep-tools

    # Quick uninstall without prompts
    ./uninstall.sh --yes
EOF
}

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            -y|--yes)
                SKIP_CONFIRM=true
                shift
                ;;
            -b|--backup)
                CREATE_BACKUP=true
                shift
                ;;
            --keep-tools)
                KEEP_TOOLS=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            *)
                log "ERROR" "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
}

# Confirm action
confirm() {
    if [[ "$SKIP_CONFIRM" == "true" ]]; then
        return 0
    fi

    local prompt="$1"
    read -rp "$prompt [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Remove file or directory
remove_item() {
    local item="$1"
    local description="${2:-$item}"

    if [[ ! -e "$item" ]]; then
        log "DEBUG" "Not found: $item (skipping)"
        return 0
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "Would remove: $description"
        return 0
    fi

    log "INFO" "Removing: $description"
    rm -rf "$item" && log "SUCCESS" "Removed: $description" || log "ERROR" "Failed to remove: $description"
}

# Create backup
create_backup() {
    if [[ "$CREATE_BACKUP" != "true" ]]; then
        return 0
    fi

    local backup_dir="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
    log "INFO" "Creating backup at: $backup_dir"

    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "Would create backup at: $backup_dir"
        return 0
    fi

    mkdir -p "$backup_dir"

    # Backup configurations
    [[ -d "$HOME/.config/atuin" ]] && cp -r "$HOME/.config/atuin" "$backup_dir/" 2>/dev/null || true
    [[ -d "$HOME/.config/bat" ]] && cp -r "$HOME/.config/bat" "$backup_dir/" 2>/dev/null || true
    [[ -d "$HOME/.config/eza" ]] && cp -r "$HOME/.config/eza" "$backup_dir/" 2>/dev/null || true
    [[ -d "$HOME/.config/fd" ]] && cp -r "$HOME/.config/fd" "$backup_dir/" 2>/dev/null || true
    [[ -d "$HOME/.config/k9s" ]] && cp -r "$HOME/.config/k9s" "$backup_dir/" 2>/dev/null || true
    [[ -d "$HOME/.config/starship.toml" ]] && cp "$HOME/.config/starship.toml" "$backup_dir/" 2>/dev/null || true
    [[ -d "$HOME/.config/tmux" ]] && cp -r "$HOME/.config/tmux" "$backup_dir/" 2>/dev/null || true
    [[ -d "$HOME/.config/yazi" ]] && cp -r "$HOME/.config/yazi" "$backup_dir/" 2>/dev/null || true
    [[ -d "$HOME/.config/zoxide" ]] && cp -r "$HOME/.config/zoxide" "$backup_dir/" 2>/dev/null || true

    # Backup shell configs
    [[ -f "$HOME/.bashrc" ]] && cp "$HOME/.bashrc" "$backup_dir/" 2>/dev/null || true
    [[ -f "$HOME/.zshrc" ]] && cp "$HOME/.zshrc" "$backup_dir/" 2>/dev/null || true

    log "SUCCESS" "Backup created at: $backup_dir"
}

# Remove configuration files
remove_configs() {
    log "INFO" "Removing configuration files..."

    # Config directories
    remove_item "$HOME/.config/atuin" "Atuin configuration"
    remove_item "$HOME/.config/bat" "Bat configuration"
    remove_item "$HOME/.config/eza" "Eza configuration"
    remove_item "$HOME/.config/fd" "Fd configuration"
    remove_item "$HOME/.config/k9s" "K9s configuration"
    remove_item "$HOME/.config/starship.toml" "Starship configuration"
    remove_item "$HOME/.config/tmux" "Tmux configuration"
    remove_item "$HOME/.config/yazi" "Yazi configuration"
    remove_item "$HOME/.config/zoxide" "Zoxide configuration"
    remove_item "$HOME/.config/scripts" "Custom scripts directory"
}

# Remove installed scripts
remove_scripts() {
    log "INFO" "Removing installed scripts..."

    local scripts=(
        "bluetoothz"
        "dkr"
        "fv"
        "fzf-git"
        "fzmv"
        "fztop"
        "gitup"
        "igr"
        "rgf"
        "sshget"
        "sysz"
        "wifiz"
        "fix-starship"
        "fzf-preview"
        "cleanup_bashrc"
        "cleanup-failing-mcps"
    )

    for script in "${scripts[@]}"; do
        remove_item "$HOME/.local/bin/$script" "Script: $script"
    done
}

# Remove shell integration
remove_shell_integration() {
    log "INFO" "Removing shell integration..."

    if [[ -f "$HOME/.bashrc" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            log "INFO" "Would remove dotfiles entries from ~/.bashrc"
        else
            # Remove dotfiles entries from bashrc
            if grep -q "# >>> dotfiles >>>" "$HOME/.bashrc" 2>/dev/null; then
                log "INFO" "Removing dotfiles entries from ~/.bashrc"
                sed -i '/# >>> dotfiles >>>/,/# <<< dotfiles <<</d' "$HOME/.bashrc"
                log "SUCCESS" "Removed dotfiles entries from ~/.bashrc"
            fi
        fi
    fi

    if [[ -f "$HOME/.zshrc" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            log "INFO" "Would remove dotfiles entries from ~/.zshrc"
        else
            # Remove dotfiles entries from zshrc
            if grep -q "# >>> dotfiles >>>" "$HOME/.zshrc" 2>/dev/null; then
                log "INFO" "Removing dotfiles entries from ~/.zshrc"
                sed -i '/# >>> dotfiles >>>/,/# <<< dotfiles <<</d' "$HOME/.zshrc"
                log "SUCCESS" "Removed dotfiles entries from ~/.zshrc"
            fi
        fi
    fi
}

# Remove installed tools
remove_tools() {
    if [[ "$KEEP_TOOLS" == "true" ]]; then
        log "INFO" "Skipping tool removal (--keep-tools specified)"
        return 0
    fi

    log "INFO" "Removing installed tools..."

    local tools=(
        "atuin"
        "bat"
        "eza"
        "fd"
        "fzf"
        "rg"
        "ripgrep"
        "starship"
        "zoxide"
        "yazi"
        "k9s"
    )

    for tool in "${tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            local tool_path
            tool_path=$(command -v "$tool")

            # Only remove if it's in ~/.local/bin
            if [[ "$tool_path" == "$HOME/.local/bin/"* ]]; then
                remove_item "$tool_path" "Tool: $tool"
            else
                log "DEBUG" "Skipping $tool (installed at $tool_path, not in ~/.local/bin)"
            fi
        fi
    done
}

# Clean up tmux plugins
remove_tmux_plugins() {
    log "INFO" "Removing tmux plugins..."
    remove_item "$HOME/.tmux/plugins" "Tmux plugins directory"
}

# Main uninstall function
main() {
    parse_args "$@"

    echo ""
    log "INFO" "Dotfiles Uninstaller"
    echo ""

    if [[ "$DRY_RUN" == "true" ]]; then
        log "WARN" "DRY RUN MODE - No files will be removed"
        echo ""
    fi

    # Summary of what will be removed
    echo "This will remove:"
    echo "  • Configuration files in ~/.config/"
    echo "  • Custom scripts in ~/.local/bin/"
    echo "  • Shell integration from ~/.bashrc and ~/.zshrc"
    if [[ "$KEEP_TOOLS" != "true" ]]; then
        echo "  • Installed tools in ~/.local/bin/"
    fi
    echo ""

    if [[ "$CREATE_BACKUP" == "true" ]]; then
        echo "A backup will be created before removal."
        echo ""
    fi

    # Confirm
    if [[ "$DRY_RUN" != "true" ]] && ! confirm "Do you want to proceed?"; then
        log "WARN" "Uninstall cancelled"
        exit 0
    fi

    echo ""

    # Create backup if requested
    create_backup

    # Remove components
    remove_configs
    remove_scripts
    remove_shell_integration
    remove_tmux_plugins
    remove_tools

    echo ""
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "Dry run complete. No files were removed."
    else
        log "SUCCESS" "Uninstall complete!"
        echo ""
        log "INFO" "You may want to:"
        echo "  • Restart your shell or run: source ~/.bashrc"
        echo "  • Remove the dotfiles repository directory"
        if [[ "$CREATE_BACKUP" == "true" ]]; then
            echo "  • Check your backup if you need to restore anything"
        fi
    fi
}

# Run main
main "$@"
