#!/bin/bash

# Test script for Sourcebot MCP installation
# This script tests the sourcebot MCP server installation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    local level="$1"
    shift
    local message="$*"

    case "$level" in
        "INFO")
            echo -e "${GREEN}[INFO]${NC} $message"
            ;;
        "WARN")
            echo -e "${YELLOW}[WARN]${NC} $message"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} $message"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[SUCCESS]${NC} $message"
            ;;
    esac
}

log "INFO" "Testing Sourcebot MCP installation..."

# Check if Claude CLI is available
if ! command -v claude &>/dev/null; then
    log "ERROR" "Claude CLI not found. Please install it first."
    exit 1
fi

# Check if sourcebot is already installed
if claude mcp list 2>/dev/null | grep -q "^sourcebot\b"; then
    log "INFO" "Sourcebot MCP server already installed"
    log "INFO" "Current sourcebot configuration:"
    claude mcp list | grep sourcebot || log "WARN" "Could not get sourcebot details"
else
    log "INFO" "Sourcebot MCP server not found, installing..."

    # Install sourcebot MCP server
    if claude mcp add sourcebot -e SOURCEBOT_HOST=http://localhost:3002 -e SOURCEBOT_API_KEY=sourcebot-aee0d48126b846c89a4ad153f444f6b01ea6c3ac4555192952aa9a10b2e0688c -- npx -y @sourcebot/mcp@latest; then
        log "SUCCESS" "Sourcebot MCP server installed successfully!"
    else
        log "ERROR" "Failed to install Sourcebot MCP server"
        exit 1
    fi
fi

# Test the installation
log "INFO" "Testing sourcebot MCP server..."
log "INFO" "Current MCP servers:"
claude mcp list 2>/dev/null || log "WARN" "Could not list MCP servers"

log "SUCCESS" "Sourcebot MCP test completed!"
log "INFO" "You can now use sourcebot in Claude for source code search and analysis."
