#!/usr/bin/env bash
set -e

# Force non-interactive mode
export DEBIAN_FRONTEND=noninteractive
export NONINTERACTIVE=1

echo "Testing Claude MCP installation in non-interactive mode..."

# Dynamic path detection
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NPM_GLOBAL_DIR="$HOME/.npm-global"

# Simple logging
log() {
    echo "[$1] $2"
}

# Check npm
if command -v npm &>/dev/null; then
    log "INFO" "npm found: $(npm --version)"
else
    log "ERROR" "npm not found"
    exit 1
fi

# Setup npm global
if [[ ! -d "$NPM_GLOBAL_DIR" ]]; then
    mkdir -p "$NPM_GLOBAL_DIR"
    log "INFO" "Created npm global directory: $NPM_GLOBAL_DIR"
fi
npm config set prefix "$NPM_GLOBAL_DIR"

# Update PATH for current session
export PATH="$HOME/.npm-global/bin:$PATH"

# Check Claude
if command -v claude &>/dev/null; then
    log "INFO" "Claude found at: $(which claude)"
    log "INFO" "Claude version: $(claude --version)"
else
    log "WARN" "Claude not found, would install via npm"
fi

# List current MCP servers
log "INFO" "Checking current MCP servers..."
if command -v claude &>/dev/null; then
    claude mcp list || log "WARN" "No MCP servers installed yet"
fi

log "INFO" "Test complete!"