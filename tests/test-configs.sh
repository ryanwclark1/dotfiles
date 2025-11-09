#!/usr/bin/env bash

# Tests for configuration files

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Source test framework
source "$SCRIPT_DIR/test-framework.sh"

# Initialize test suite
init_tests "Configuration Files Tests"

# Test: starship.toml is valid TOML
test_start "starship.toml is valid TOML"
if command -v toml &>/dev/null; then
    if toml check "$REPO_ROOT/starship.toml" &>/dev/null; then
        test_pass
    else
        test_fail "starship.toml contains invalid TOML"
    fi
else
    skip_test "toml tool not available"
fi

# Test: .mcp.json is valid JSON
test_start ".mcp.json is valid JSON"
if [[ -f "$REPO_ROOT/.mcp.json" ]]; then
    if jq empty "$REPO_ROOT/.mcp.json" &>/dev/null; then
        test_pass
    else
        test_fail ".mcp.json contains invalid JSON"
    fi
else
    skip_test ".mcp.json not present"
fi

# Test: Atuin config exists
test_start "atuin config.toml exists"
if assert_file_exists "$REPO_ROOT/atuin/config.toml"; then
    test_pass
else
    test_fail
fi

# Test: Bat config exists
test_start "bat config exists"
if assert_file_exists "$REPO_ROOT/bat/config"; then
    test_pass
else
    test_fail
fi

# Test: Eza theme exists
test_start "eza theme.yml exists"
if assert_file_exists "$REPO_ROOT/eza/theme.yml"; then
    test_pass
else
    test_fail
fi

# Test: Shell configurations exist
test_start "shell configuration files exist"
shell_configs_exist=true
missing_configs=()

declare -a shell_files=("bashrc.snippet" "dotfiles.bash" "dotfiles.zsh")
for file in "${shell_files[@]}"; do
    if [[ ! -f "$REPO_ROOT/shell/$file" ]]; then
        shell_configs_exist=false
        missing_configs+=("$file")
    fi
done

if $shell_configs_exist; then
    test_pass
else
    test_fail "Missing shell configs: ${missing_configs[*]}"
fi

# Test: Tmux config exists
test_start "tmux.conf exists"
if assert_file_exists "$REPO_ROOT/tmux/tmux.conf"; then
    test_pass
else
    test_fail
fi

# Test: Yazi configs exist
test_start "yazi configuration files exist"
yazi_configs_exist=true
missing_yazi=()

declare -a yazi_files=("keymap.toml" "theme.toml" "init.lua")
for file in "${yazi_files[@]}"; do
    if [[ ! -f "$REPO_ROOT/yazi/$file" ]]; then
        yazi_configs_exist=false
        missing_yazi+=("$file")
    fi
done

if $yazi_configs_exist; then
    test_pass
else
    test_fail "Missing yazi configs: ${missing_yazi[*]}"
fi

# Test: K9s config exists
test_start "k9s config.yaml exists"
if assert_file_exists "$REPO_ROOT/k9s/config.yaml"; then
    test_pass
else
    test_fail
fi

# Test: Alias file is not empty
test_start "alias file contains aliases"
if [[ -s "$REPO_ROOT/alias" ]]; then
    content=$(cat "$REPO_ROOT/alias")
    if assert_contains "$content" "alias"; then
        test_pass
    else
        test_fail "alias file doesn't contain any aliases"
    fi
else
    test_fail "alias file is empty"
fi

# Test: No backup files in repo (should be gitignored)
test_start "no backup files tracked in git"
if [[ -d "$REPO_ROOT/.git" ]]; then
    backup_files=$(git -C "$REPO_ROOT" ls-files | grep -E '\.(bak|backup|old|swp|tmp)$' || true)
    if [[ -z "$backup_files" ]]; then
        test_pass
    else
        test_fail "Found backup files in git: $backup_files"
    fi
else
    # Skip test if not a git repository (e.g., in Docker)
    skip_test "Not a git repository"
fi

# Test: .gitignore exists and has content
test_start ".gitignore exists and is not empty"
if assert_file_exists "$REPO_ROOT/.gitignore" && [[ -s "$REPO_ROOT/.gitignore" ]]; then
    test_pass
else
    test_fail
fi

# Test: .gitignore contains backup patterns
test_start ".gitignore contains backup file patterns"
gitignore_content=$(cat "$REPO_ROOT/.gitignore")
if assert_contains "$gitignore_content" "*.bak" && \
   assert_contains "$gitignore_content" "*.backup"; then
    test_pass
else
    test_fail ".gitignore missing backup patterns"
fi

# Print summary
test_summary
exit $?
