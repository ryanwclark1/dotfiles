#!/usr/bin/env bash

# Tests for bootstrap.sh

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Source test framework
source "$SCRIPT_DIR/test-framework.sh"

# Initialize test suite
init_tests "Bootstrap Script Tests"

# Test: bootstrap.sh exists
test_start "bootstrap.sh exists and is executable"
if assert_file_exists "$REPO_ROOT/bootstrap.sh" && [[ -x "$REPO_ROOT/bootstrap.sh" ]]; then
    test_pass
else
    test_fail "bootstrap.sh is not executable"
fi

# Test: bootstrap.sh has proper shebang
test_start "bootstrap.sh has proper shebang"
first_line=$(head -n 1 "$REPO_ROOT/bootstrap.sh")
if assert_contains "$first_line" "#!/" "Missing shebang"; then
    test_pass
else
    test_fail
fi

# Test: bootstrap.sh contains required functions
test_start "bootstrap.sh contains core functions"
content=$(cat "$REPO_ROOT/bootstrap.sh")
if assert_contains "$content" "install_from_github" && \
   assert_contains "$content" "TOOLS=" && \
   assert_contains "$content" "TOOL_CONFIG="; then
    test_pass
else
    test_fail "Missing core functions or arrays"
fi

# Test: bootstrap-container.sh exists
test_start "bootstrap-container.sh exists and is executable"
if assert_file_exists "$REPO_ROOT/bootstrap-container.sh" && [[ -x "$REPO_ROOT/bootstrap-container.sh" ]]; then
    test_pass
else
    test_fail "bootstrap-container.sh is not executable"
fi

# Test: Key configuration directories are defined
test_start "Configuration directories exist in repository"
declare -a config_dirs=("atuin" "bat" "eza" "fd" "k9s" "ripgrep" "scripts" "shell" "tmux" "yazi")
all_exist=true
missing_dirs=()

for dir in "${config_dirs[@]}"; do
    if [[ ! -d "$REPO_ROOT/$dir" ]]; then
        all_exist=false
        missing_dirs+=("$dir")
    fi
done

if $all_exist; then
    test_pass
else
    test_fail "Missing directories: ${missing_dirs[*]}"
fi

# Test: Scripts directory contains executable files
test_start "Scripts directory contains executable files"
script_count=$(find "$REPO_ROOT/scripts" -type f -executable 2>/dev/null | wc -l)
if [[ $script_count -gt 0 ]]; then
    test_pass
else
    test_fail "No executable scripts found in scripts/ directory"
fi

# Test: Essential scripts exist
test_start "Essential utility scripts exist"
declare -a essential_scripts=("fzf-git.sh" "igr.sh" "fv.sh")
all_exist=true
missing_scripts=()

for script in "${essential_scripts[@]}"; do
    if [[ ! -f "$REPO_ROOT/scripts/$script" ]]; then
        all_exist=false
        missing_scripts+=("$script")
    fi
done

if $all_exist; then
    test_pass
else
    test_fail "Missing scripts: ${missing_scripts[*]}"
fi

# Test: Starship config exists
test_start "starship.toml exists"
if assert_file_exists "$REPO_ROOT/starship.toml"; then
    test_pass
else
    test_fail
fi

# Test: Alias file exists
test_start "alias file exists"
if assert_file_exists "$REPO_ROOT/alias"; then
    test_pass
else
    test_fail
fi

# Test: update_dots.sh exists
test_start "update_dots.sh exists and is executable"
if assert_file_exists "$REPO_ROOT/update_dots.sh" && [[ -x "$REPO_ROOT/update_dots.sh" ]]; then
    test_pass
else
    test_fail
fi

# Print summary
test_summary
exit $?
