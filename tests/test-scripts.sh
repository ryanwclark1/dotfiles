#!/usr/bin/env bash

# Tests for utility scripts

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Source test framework
source "$SCRIPT_DIR/test-framework.sh"

# Initialize test suite
init_tests "Utility Scripts Tests"

# Test: All scripts in scripts/ have shebangs
test_start "all scripts have proper shebangs"
scripts_without_shebang=()
all_have_shebang=true

for script in "$REPO_ROOT/scripts"/*; do
    if [[ -f "$script" && -x "$script" ]]; then
        first_line=$(head -n 1 "$script")
        if [[ ! "$first_line" =~ ^#! ]]; then
            all_have_shebang=false
            scripts_without_shebang+=("$(basename "$script")")
        fi
    fi
done

if $all_have_shebang; then
    test_pass
else
    test_fail "Scripts without shebang: ${scripts_without_shebang[*]}"
fi

# Test: Scripts are executable
test_start "all .sh scripts are executable"
non_executable=()
all_executable=true

for script in "$REPO_ROOT/scripts"/*.sh; do
    if [[ -f "$script" && ! -x "$script" ]]; then
        all_executable=false
        non_executable+=("$(basename "$script")")
    fi
done

if $all_executable; then
    test_pass
else
    test_fail "Non-executable scripts: ${non_executable[*]}"
fi

# Test: FZF scripts exist
test_start "fzf integration scripts exist"
declare -a fzf_scripts=("fzf-git.sh" "fv.sh" "fzmv.sh" "fztop.sh")
all_exist=true
missing=()

for script in "${fzf_scripts[@]}"; do
    if [[ ! -f "$REPO_ROOT/scripts/$script" ]]; then
        all_exist=false
        missing+=("$script")
    fi
done

if $all_exist; then
    test_pass
else
    test_fail "Missing fzf scripts: ${missing[*]}"
fi

# Test: System management scripts exist
test_start "system management scripts exist"
declare -a sys_scripts=("sysz.sh" "wifiz.sh" "bluetoothz.sh")
all_exist=true
missing=()

for script in "${sys_scripts[@]}"; do
    if [[ ! -f "$REPO_ROOT/scripts/$script" ]]; then
        all_exist=false
        missing+=("$script")
    fi
done

if $all_exist; then
    test_pass
else
    test_fail "Missing system scripts: ${missing[*]}"
fi

# Test: Cleanup scripts are in scripts/ directory
test_start "cleanup scripts are in scripts/ directory"
if assert_file_exists "$REPO_ROOT/scripts/cleanup-failing-mcps.sh" && \
   assert_file_exists "$REPO_ROOT/scripts/cleanup_bashrc.sh"; then
    test_pass
else
    test_fail
fi

# Test: Scripts don't have Windows line endings
test_start "scripts don't have Windows line endings (CRLF)"
scripts_with_crlf=()
all_unix=true

for script in "$REPO_ROOT/scripts"/*.sh; do
    if [[ -f "$script" ]] && file "$script" | grep -q "CRLF"; then
        all_unix=false
        scripts_with_crlf+=("$(basename "$script")")
    fi
done

if $all_unix; then
    test_pass
else
    test_fail "Scripts with CRLF: ${scripts_with_crlf[*]}"
fi

# Test: Core installation scripts exist
test_start "core installation scripts exist"
declare -a install_scripts=("bootstrap.sh" "install-ai-tools.sh" "update_dots.sh")
all_exist=true
missing=()

for script in "${install_scripts[@]}"; do
    if [[ ! -f "$REPO_ROOT/$script" ]]; then
        all_exist=false
        missing+=("$script")
    fi
done

if $all_exist; then
    test_pass
else
    test_fail "Missing install scripts: ${missing[*]}"
fi

# Test: Setup scripts are in setup/ directory
test_start "setup scripts are organized in setup/ directory"
if assert_dir_exists "$REPO_ROOT/setup" && \
   assert_file_exists "$REPO_ROOT/setup/setup-serena.sh" && \
   assert_file_exists "$REPO_ROOT/setup/setup-context7.sh" && \
   assert_file_exists "$REPO_ROOT/setup/setup-genai-toolbox.sh"; then
    test_pass
else
    test_fail
fi

# Test: No scripts in root that should be in subdirectories
test_start "no orphaned test/setup scripts in root"
orphaned_scripts=()
has_orphans=false

# Check for old script locations
for pattern in "test-*.sh" "setup-*.sh"; do
    while IFS= read -r -d '' script; do
        has_orphans=true
        orphaned_scripts+=("$(basename "$script")")
    done < <(find "$REPO_ROOT" -maxdepth 1 -name "$pattern" -print0 2>/dev/null)
done

if ! $has_orphans; then
    test_pass
else
    test_fail "Found orphaned scripts in root: ${orphaned_scripts[*]}"
fi

# Test: fix-starship script exists
test_start "fix-starship utility script exists"
if assert_file_exists "$REPO_ROOT/scripts/fix-starship"; then
    test_pass
else
    test_fail
fi

# Print summary
test_summary
exit $?
