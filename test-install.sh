#!/bin/bash
set -e

echo "Test 1: Basic echo"
echo "Test 2: Command check"
command -v npm && echo "npm found"
command -v claude && echo "claude found"

echo "Test 3: Function call"
log() { echo "[$1] $2"; }
log "INFO" "Test log function"

echo "Test 4: Array"
declare -a TEST_ARRAY=("one" "two" "three")
echo "Array size: ${#TEST_ARRAY[@]}"

echo "Test 5: Install claude function"
install_claude() {
    log "INFO" "Checking Claude..."
    if command -v claude &>/dev/null; then
        log "INFO" "Claude found at $(which claude)"
        if [[ "$(which claude)" == /nix/* ]]; then
            log "INFO" "Claude via Nix, skipping"
            return
        fi
    fi
    log "INFO" "Would install claude here"
}

echo "Calling install_claude..."
install_claude

echo "Test 6: Done"