#!/usr/bin/env bash
set -e

echo "Simple Claude MCP installer (non-interactive)"
echo "============================================="

# Check Claude
if ! command -v claude &>/dev/null; then
    echo "ERROR: Claude not found"
    exit 1
fi

echo "✓ Claude found: $(claude --version)"

# List current servers
echo
echo "Current MCP servers:"
claude mcp list

# Install MCP servers
servers=(
    "time:npx @modelcontextprotocol/server-time"
    "git:npx @modelcontextprotocol/server-git"
    "github:npx @modelcontextprotocol/server-github"
    "playwright:npx @playwright/mcp@latest"
)

echo
echo "Installing MCP servers..."
for server in "${servers[@]}"; do
    IFS=':' read -r name command <<< "$server"
    echo -n "Installing $name... "
    if claude mcp add "$name" $command 2>&1 >/dev/null; then
        echo "✓"
    else
        echo "✗"
    fi
done

echo
echo "Final MCP servers:"
claude mcp list

echo
echo "Done!"
echo
echo "Note: Some servers require additional configuration:"
echo "- GitHub: Set GITHUB_TOKEN environment variable"
echo "- Playwright: Requires browsers to be installed"