#!/usr/bin/env bash

# Health check script for dotfiles environment
# Checks for common issues and provides recommendations

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions if available
if [[ -f "$SCRIPT_DIR/common.sh" ]]; then
    source "$SCRIPT_DIR/common.sh"
else
    COLOR_RESET='\033[0m'
    COLOR_INFO='\033[0;34m'
    COLOR_WARN='\033[1;33m'
    COLOR_ERROR='\033[0;31m'
    COLOR_SUCCESS='\033[0;32m'
fi

# Tracking
ISSUES_FOUND=0
WARNINGS_FOUND=0

issue() {
    echo -e "${COLOR_ERROR}✗ Issue:${COLOR_RESET} $*"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
}

warning() {
    echo -e "${COLOR_WARN}⚠ Warning:${COLOR_RESET} $*"
    WARNINGS_FOUND=$((WARNINGS_FOUND + 1))
}

info() {
    echo -e "${COLOR_INFO}ℹ${COLOR_RESET} $*"
}

ok() {
    echo -e "${COLOR_SUCCESS}✓${COLOR_RESET} $*"
}

section() {
    echo ""
    echo -e "${COLOR_INFO}━━━ $* ━━━${COLOR_RESET}"
}

# Check disk space
check_disk_space() {
    section "Disk Space"

    local home_available
    if command -v df &>/dev/null; then
        home_available=$(df -h "$HOME" | awk 'NR==2 {print $4}')
        ok "Available space in HOME: $home_available"

        # Check if less than 1GB
        local available_kb
        available_kb=$(df "$HOME" | awk 'NR==2 {print $4}')
        if [[ $available_kb -lt 1048576 ]]; then
            warning "Low disk space (less than 1GB available)"
        fi
    else
        warning "Cannot check disk space (df not available)"
    fi
}

# Check shell configuration
check_shell() {
    section "Shell Configuration"

    echo "Current shell: $SHELL"

    case "$(basename "$SHELL")" in
        bash)
            if [[ -f "$HOME/.bashrc" ]]; then
                ok ".bashrc exists"

                # Check for duplicate PATH entries
                if command -v awk &>/dev/null; then
                    local path_count
                    path_count=$(echo "$PATH" | tr ':' '\n' | sort | uniq -d | wc -l)
                    if [[ $path_count -gt 0 ]]; then
                        warning "Duplicate entries in PATH ($path_count found)"
                        info "Run: ./scripts/cleanup_bashrc.sh"
                    else
                        ok "No duplicate PATH entries"
                    fi
                fi
            else
                warning ".bashrc not found"
            fi
            ;;
        zsh)
            if [[ -f "$HOME/.zshrc" ]]; then
                ok ".zshrc exists"
            else
                warning ".zshrc not found"
            fi
            ;;
        *)
            warning "Unsupported shell: $(basename "$SHELL")"
            ;;
    esac
}

# Check environment conflicts
check_env_conflicts() {
    section "Environment Conflicts"

    # Check for nvm/npm-global conflicts
    if [[ -d "$HOME/.nvm" ]]; then
        info "NVM detected"
        if [[ ":$PATH:" == *":$HOME/.npm-global/bin:"* ]]; then
            warning "Both NVM and npm-global in PATH (potential conflict)"
            info "The dotfiles handle this automatically, but verify npm works correctly"
        fi
    fi

    # Check for starship conflicts
    if [[ -n "${STARSHIP_SHELL:-}" ]]; then
        info "STARSHIP_SHELL is set to: $STARSHIP_SHELL"
        local current_shell
        current_shell=$(basename "$SHELL")
        if [[ "$STARSHIP_SHELL" != "$current_shell" ]]; then
            warning "STARSHIP_SHELL ($STARSHIP_SHELL) doesn't match current shell ($current_shell)"
            info "Run: ./scripts/fix-starship"
        fi
    fi

    # Check for Python virtual environments
    if [[ -n "${VIRTUAL_ENV:-}" ]]; then
        info "Python virtual environment active: $VIRTUAL_ENV"
    fi
}

# Check for common misconfigurations
check_misconfigurations() {
    section "Common Misconfigurations"

    # Check if scripts are executable
    if [[ -d "$HOME/.local/bin" ]]; then
        local non_executable
        non_executable=$(find "$HOME/.local/bin" -type f ! -executable 2>/dev/null | wc -l)
        if [[ $non_executable -gt 0 ]]; then
            warning "Found $non_executable non-executable files in ~/.local/bin"
            info "Run: chmod +x ~/.local/bin/*"
        else
            ok "All scripts in ~/.local/bin are executable"
        fi
    fi

    # Check for backup files
    local backup_files
    backup_files=$(find "$HOME/.config" -type f \( -name "*.bak" -o -name "*.backup" -o -name "*.old" \) 2>/dev/null | wc -l)
    if [[ $backup_files -gt 0 ]]; then
        warning "Found $backup_files backup files in ~/.config"
        info "Consider cleaning up old backups"
    else
        ok "No backup files found"
    fi
}

# Check tool versions
check_tool_versions() {
    section "Tool Versions"

    local tools=(eza fd rg bat fzf starship atuin zoxide yazi)

    for tool in "${tools[@]}"; do
        if command -v "$tool" &>/dev/null; then
            local version
            case "$tool" in
                fzf) version=$($tool --version 2>&1 || echo "unknown") ;;
                *) version=$($tool --version 2>&1 | head -1 || echo "unknown") ;;
            esac
            ok "$tool: $version"
        fi
    done
}

# Check for performance issues
check_performance() {
    section "Performance"

    # Check shell startup time
    if command -v time &>/dev/null; then
        local shell_cmd
        case "$(basename "$SHELL")" in
            bash) shell_cmd="bash -i -c exit" ;;
            zsh) shell_cmd="zsh -i -c exit" ;;
            *) shell_cmd="" ;;
        esac

        if [[ -n "$shell_cmd" ]]; then
            info "Measuring shell startup time..."
            local startup_time
            startup_time=$( { time $shell_cmd; } 2>&1 | grep real | awk '{print $2}')
            info "Shell startup time: $startup_time"

            # Warn if startup takes more than 1 second
            if [[ "$startup_time" =~ ^0m([0-9]+)\. ]]; then
                local seconds="${BASH_REMATCH[1]}"
                if [[ $seconds -gt 1 ]]; then
                    warning "Slow shell startup time (>${seconds}s)"
                    info "Consider profiling your shell configuration"
                fi
            fi
        fi
    fi
}

# Check git configuration
check_git() {
    section "Git Configuration"

    if [[ -d ".git" ]]; then
        # Check for hooks
        if [[ -f ".git/hooks/pre-commit" ]]; then
            ok "Pre-commit hook installed"
        else
            info "Pre-commit hook not installed"
            info "Run: make install-hooks"
        fi

        # Check for uncommitted changes
        if ! git diff-index --quiet HEAD -- 2>/dev/null; then
            warning "Uncommitted changes detected"
            info "Run: git status"
        else
            ok "No uncommitted changes"
        fi

        # Check if we're ahead of remote
        if git rev-parse --abbrev-ref --symbolic-full-name @{u} &>/dev/null; then
            local commits_ahead
            commits_ahead=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo "0")
            if [[ $commits_ahead -gt 0 ]]; then
                info "$commits_ahead commits ahead of remote"
                info "Run: git push"
            fi
        fi
    fi
}

# Check log files
check_logs() {
    section "Log Files"

    local log_file="$HOME/.dotfiles-install.log"
    if [[ -f "$log_file" ]]; then
        local log_size
        log_size=$(du -h "$log_file" | cut -f1)
        ok "Install log: $log_file ($log_size)"

        # Check for errors in log
        if grep -qi "error" "$log_file" 2>/dev/null; then
            warning "Errors found in install log"
            info "Check: cat $log_file | grep -i error"
        fi

        # Warn if log is large
        local size_kb
        size_kb=$(du -k "$log_file" | cut -f1)
        if [[ $size_kb -gt 1024 ]]; then
            info "Large log file (>1MB)"
            info "Consider rotating or cleaning: rm $log_file"
        fi
    fi
}

# Main function
main() {
    echo -e "${COLOR_INFO}╔══════════════════════════════════════╗${COLOR_RESET}"
    echo -e "${COLOR_INFO}║    Dotfiles Health Check            ║${COLOR_RESET}"
    echo -e "${COLOR_INFO}╚══════════════════════════════════════╝${COLOR_RESET}"

    check_disk_space
    check_shell
    check_env_conflicts
    check_misconfigurations
    check_tool_versions
    check_performance
    check_git
    check_logs

    # Summary
    echo ""
    section "Summary"

    if [[ $ISSUES_FOUND -eq 0 && $WARNINGS_FOUND -eq 0 ]]; then
        echo -e "${COLOR_SUCCESS}✅ All checks passed! Your dotfiles environment is healthy.${COLOR_RESET}"
        return 0
    elif [[ $ISSUES_FOUND -eq 0 ]]; then
        echo -e "${COLOR_WARN}⚠️  $WARNINGS_FOUND warnings found, but no critical issues.${COLOR_RESET}"
        return 0
    else
        echo -e "${COLOR_ERROR}❌ $ISSUES_FOUND issues and $WARNINGS_FOUND warnings found.${COLOR_RESET}"
        echo ""
        echo "Please address the issues above."
        return 1
    fi
}

main "$@"
