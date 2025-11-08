#!/usr/bin/env bash

# Validation script to check dotfiles installation
# Run this after installation to verify everything is set up correctly

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Source common functions if available
if [[ -f "$SCRIPT_DIR/common.sh" ]]; then
    source "$SCRIPT_DIR/common.sh"
else
    # Fallback color definitions
    COLOR_RESET='\033[0m'
    COLOR_INFO='\033[0;34m'
    COLOR_WARN='\033[1;33m'
    COLOR_ERROR='\033[0;31m'
    COLOR_SUCCESS='\033[0;32m'
fi

# Counters
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNED=0

# Check result tracking
print_result() {
    local status="$1"
    local message="$2"

    case "$status" in
        PASS)
            echo -e "  ${COLOR_SUCCESS}✓${COLOR_RESET} $message"
            CHECKS_PASSED=$((CHECKS_PASSED + 1))
            ;;
        FAIL)
            echo -e "  ${COLOR_ERROR}✗${COLOR_RESET} $message"
            CHECKS_FAILED=$((CHECKS_FAILED + 1))
            ;;
        WARN)
            echo -e "  ${COLOR_WARN}⚠${COLOR_RESET} $message"
            CHECKS_WARNED=$((CHECKS_WARNED + 1))
            ;;
    esac
}

# Print section header
print_section() {
    echo ""
    echo -e "${COLOR_INFO}━━━ $1 ━━━${COLOR_RESET}"
    echo ""
}

# Check if command exists
check_command() {
    local cmd="$1"
    local optional="${2:-false}"

    if command -v "$cmd" &>/dev/null; then
        local version=""
        case "$cmd" in
            eza) version=$($cmd --version 2>&1 | head -1 || echo "") ;;
            fd) version=$($cmd --version 2>&1 | head -1 || echo "") ;;
            rg) version=$($cmd --version 2>&1 | head -1 || echo "") ;;
            bat) version=$($cmd --version 2>&1 | head -1 || echo "") ;;
            starship) version=$($cmd --version 2>&1 | head -1 || echo "") ;;
            fzf) version=$($cmd --version 2>&1 || echo "") ;;
            atuin) version=$($cmd --version 2>&1 | head -1 || echo "") ;;
            zoxide) version=$($cmd --version 2>&1 | head -1 || echo "") ;;
            yazi) version=$($cmd --version 2>&1 | head -1 || echo "") ;;
        esac

        if [[ -n "$version" ]]; then
            print_result "PASS" "$cmd is installed ($version)"
        else
            print_result "PASS" "$cmd is installed"
        fi
        return 0
    else
        if [[ "$optional" == "true" ]]; then
            print_result "WARN" "$cmd not found (optional)"
        else
            print_result "FAIL" "$cmd not found"
        fi
        return 1
    fi
}

# Check if file exists
check_file() {
    local file="$1"
    local optional="${2:-false}"

    if [[ -f "$file" ]]; then
        print_result "PASS" "File exists: $file"
        return 0
    else
        if [[ "$optional" == "true" ]]; then
            print_result "WARN" "File not found (optional): $file"
        else
            print_result "FAIL" "File not found: $file"
        fi
        return 1
    fi
}

# Check if directory exists
check_directory() {
    local dir="$1"
    local optional="${2:-false}"

    if [[ -d "$dir" ]]; then
        local count
        count=$(find "$dir" -type f 2>/dev/null | wc -l)
        print_result "PASS" "Directory exists: $dir ($count files)"
        return 0
    else
        if [[ "$optional" == "true" ]]; then
            print_result "WARN" "Directory not found (optional): $dir"
        else
            print_result "FAIL" "Directory not found: $dir"
        fi
        return 1
    fi
}

# Check PATH for a directory
check_in_path() {
    local dir="$1"

    if [[ ":$PATH:" == *":$dir:"* ]]; then
        print_result "PASS" "$dir is in PATH"
        return 0
    else
        print_result "WARN" "$dir not in PATH"
        return 1
    fi
}

# Check shell configuration
check_shell_config() {
    local shell_name
    shell_name=$(basename "$SHELL")
    local rc_file=""

    case "$shell_name" in
        bash) rc_file="$HOME/.bashrc" ;;
        zsh) rc_file="$HOME/.zshrc" ;;
        *) print_result "WARN" "Unsupported shell: $shell_name"; return 1 ;;
    esac

    if [[ -f "$rc_file" ]]; then
        if grep -q "BEGIN DOTFILES MANAGED BLOCK" "$rc_file" 2>/dev/null; then
            print_result "PASS" "Dotfiles configuration found in $rc_file"
            return 0
        else
            print_result "WARN" "Dotfiles configuration not found in $rc_file"
            return 1
        fi
    else
        print_result "FAIL" "Shell config file not found: $rc_file"
        return 1
    fi
}

# Main validation
main() {
    echo -e "${COLOR_INFO}╔══════════════════════════════════════╗${COLOR_RESET}"
    echo -e "${COLOR_INFO}║   Dotfiles Installation Validation  ║${COLOR_RESET}"
    echo -e "${COLOR_INFO}╚══════════════════════════════════════╝${COLOR_RESET}"

    # Check directories
    print_section "Directory Structure"
    check_directory "$HOME/.config"
    check_directory "$HOME/.local/bin"
    check_directory "$HOME/.config/scripts" "true"
    check_directory "$HOME/.config/starship" "true"
    check_directory "$HOME/.config/atuin" "true"

    # Check essential commands
    print_section "Essential Tools"
    check_command "git"
    check_command "curl"
    check_command "jq"

    # Check installed tools
    print_section "Dotfiles Tools"
    check_command "eza" "true"
    check_command "fd" "true"
    check_command "rg"
    check_command "bat" "true"
    check_command "fzf" "true"
    check_command "starship" "true"
    check_command "atuin" "true"
    check_command "zoxide" "true"
    check_command "yazi" "true"

    # Check configuration files
    print_section "Configuration Files"
    check_file "$REPO_ROOT/starship.toml"
    check_file "$REPO_ROOT/alias"
    check_file "$HOME/.config/starship.toml" "true"

    # Check PATH
    print_section "PATH Configuration"
    check_in_path "$HOME/.local/bin"
    check_in_path "$HOME/.npm-global/bin" "true"

    # Check shell integration
    print_section "Shell Integration"
    check_shell_config

    # Check Git hooks
    print_section "Development Tools"
    check_file "$REPO_ROOT/.git/hooks/pre-commit" "true"
    check_file "$REPO_ROOT/Makefile" "true"
    check_file "$REPO_ROOT/run-tests.sh" "true"

    # Summary
    print_section "Validation Summary"
    local total=$((CHECKS_PASSED + CHECKS_FAILED + CHECKS_WARNED))

    echo -e "Total checks: $total"
    echo -e "${COLOR_SUCCESS}Passed:  $CHECKS_PASSED${COLOR_RESET}"

    if [[ $CHECKS_WARNED -gt 0 ]]; then
        echo -e "${COLOR_WARN}Warnings: $CHECKS_WARNED${COLOR_RESET}"
    fi

    if [[ $CHECKS_FAILED -gt 0 ]]; then
        echo -e "${COLOR_ERROR}Failed:   $CHECKS_FAILED${COLOR_RESET}"
    fi

    echo ""

    # Exit code
    if [[ $CHECKS_FAILED -eq 0 ]]; then
        echo -e "${COLOR_SUCCESS}✅ Validation passed!${COLOR_RESET}"
        if [[ $CHECKS_WARNED -gt 0 ]]; then
            echo -e "${COLOR_WARN}⚠️  Some optional components are missing${COLOR_RESET}"
        fi
        return 0
    else
        echo -e "${COLOR_ERROR}❌ Validation failed!${COLOR_RESET}"
        echo ""
        echo "Some required components are missing or not configured correctly."
        echo "Please run: ./bootstrap.sh"
        return 1
    fi
}

main "$@"
