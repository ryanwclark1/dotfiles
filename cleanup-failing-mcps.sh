#!/usr/bin/env bash

# Cleanup script to remove failing MCP servers from Claude
# This script removes the MCP servers that are not published to npm registry

set -euo pipefail

# Colors
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
NC="\033[0m"

log() {
    local level="$1"
    local message="$2"
    local color="$NC"
    local emoji=""

    case "$level" in
        INFO) color="$BLUE"; emoji="ℹ️" ;;
        WARN) color="$YELLOW"; emoji="⚠️" ;;
        ERROR) color="$RED"; emoji="❌" ;;
        SUCCESS) color="$GREEN"; emoji="✅" ;;
    esac

    echo -e "${color}${emoji} [$level]${NC} $message"
}

# Check if Claude CLI is available
if ! command -v claude &>/dev/null; then
    log "ERROR" "Claude CLI not found. Please install it first."
    exit 1
fi

# List of failing MCP servers to remove
FAILING_SERVERS=(
    "git"
    "fetch"
    "time"
    "language-server"
    "run-python"
    "memory-bank"
)

log "INFO" "Starting cleanup of failing MCP servers..."

# Get current MCP servers
current_servers=$(claude mcp list 2>/dev/null | grep -E "^[a-zA-Z-]+" | awk '{print $1}' || echo "")

if [[ -z "$current_servers" ]]; then
    log "INFO" "No MCP servers currently installed"
    exit 0
fi

# Remove each failing server
removed_count=0
for server in "${FAILING_SERVERS[@]}"; do
    if echo "$current_servers" | grep -q "^$server$"; then
        log "INFO" "Removing failing MCP server: $server"
        if claude mcp remove "$server" 2>/dev/null; then
            log "SUCCESS" "Removed $server"
            ((removed_count++))
        else
            log "WARN" "Failed to remove $server (may not exist)"
        fi
    else
        log "INFO" "Server $server not found in current installation"
    fi
done

log "SUCCESS" "Cleanup complete! Removed $removed_count failing MCP servers"

# Show remaining servers
log "INFO" "Remaining MCP servers:"
claude mcp list 2>/dev/null || log "WARN" "Could not list remaining servers"

log "INFO" "You can now re-run the installer to get only working MCP servers:"
log "INFO" "./install-ai-tools.sh --non-interactive"
