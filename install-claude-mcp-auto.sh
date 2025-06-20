#!/usr/bin/env bash
set -e

echo "Claude MCP Auto-Installer (Non-interactive mode)"
echo "================================================"

# Configuration
NPM_GLOBAL_DIR="$HOME/.npm-global"

# MCP servers to install
MCP_SERVERS=(
    "playwright:npx @playwright/mcp@latest"
    "github:npx @modelcontextprotocol/server-github"
    "context7:npx @context7/mcp-server"
    "memorybank:npx memory-bank-mcp"
    "memory:npx @modelcontextprotocol/server-memory"
    "time:npx @modelcontextprotocol/server-time"
    "git:npx @modelcontextprotocol/server-git"
)

# Logging
log() { echo "[$1] $2"; }

# Check prerequisites
log "INFO" "Checking prerequisites..."

if ! command -v npm &>/dev/null; then
    log "ERROR" "npm not found. Please install Node.js first."
    exit 1
fi

if ! command -v claude &>/dev/null; then
    log "ERROR" "Claude not found. Please install Claude Code first."
    exit 1
fi

log "INFO" "npm version: $(npm --version)"
log "INFO" "Claude version: $(claude --version)"

# Setup npm global directory
if [[ ! -d "$NPM_GLOBAL_DIR" ]]; then
    mkdir -p "$NPM_GLOBAL_DIR"
    log "INFO" "Created npm global directory: $NPM_GLOBAL_DIR"
fi
npm config set prefix "$NPM_GLOBAL_DIR"

# Export PATH for current session
export PATH="$HOME/.npm-global/bin:$PATH"

# Check current MCP servers
log "INFO" "Current MCP servers:"
claude mcp list || echo "None installed yet"

# Install MCP servers
log "INFO" "Installing MCP servers..."
installed=0
failed=0

for server_config in "${MCP_SERVERS[@]}"; do
    IFS=':' read -r server_name server_command <<< "$server_config"
    
    log "INFO" "Installing $server_name..."
    
    # Skip Serena as it needs special handling
    if [[ "$server_name" == "serena" ]]; then
        log "WARN" "Skipping Serena (requires interactive setup)"
        continue
    fi
    
    if claude mcp add "$server_name" $server_command 2>&1; then
        log "INFO" "✓ Successfully installed $server_name"
        ((installed++))
    else
        log "WARN" "✗ Failed to install $server_name"
        ((failed++))
    fi
done

# Summary
echo
echo "========================================"
echo "Installation Summary"
echo "========================================"
echo "Installed: $installed servers"
echo "Failed: $failed servers"
echo
echo "Current MCP servers:"
claude mcp list

# Configuration notes
echo
echo "========================================"
echo "Configuration Notes"
echo "========================================"
echo
echo "1. GitHub MCP Server:"
echo "   - Set environment variable: export GITHUB_TOKEN='your-token'"
echo "   - Get token from: https://github.com/settings/tokens"
echo
echo "2. PATH Configuration:"
echo "   - Add to your shell config: export PATH=\"\$HOME/.npm-global/bin:\$PATH\""
echo
echo "3. Serena IDE Assistant:"
echo "   - Run interactive installer: ./install-claude-mcp.sh"
echo "   - Requires project directory configuration"
echo
echo "4. For devcontainer support:"
echo "   - Copy .devcontainer/ folder to your project"
echo "   - Includes all necessary mounts and configurations"
echo
echo "Done!"