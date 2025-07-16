#!/usr/bin/env bash
# Remove directory-specific MCP servers so we can reinstall them globally

echo "Removing directory-specific MCP servers..."

# List of MCP servers to remove
MCP_SERVERS=(
    "filesystem"
    "git"
    "fetch"
    "time"
    "sequential-thinking"
    "memory"
    "everything"
    "language-server"
    "run-python"
    "memory-bank"
    "serena"
    "playwright"
    "puppeteer"
    "context7"
    "github"
)

for server in "${MCP_SERVERS[@]}"; do
    echo "Removing $server..."
    claude mcp remove "$server" 2>/dev/null || true
done

echo "Done! Now run ./install-ai-tools.sh to reinstall MCP servers globally"