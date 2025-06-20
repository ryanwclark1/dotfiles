# Claude MCP Installation Guide

This guide covers the installation and configuration of Claude Code and MCP (Model Context Protocol) servers.

## Quick Start

### Interactive Installation (recommended)
```bash
./install-claude-mcp.sh
```

### Non-Interactive Installation
```bash
# For automated/scripted installations
./install-claude-mcp.sh --non-interactive

# Or use the auto-installer
./install-claude-mcp-auto.sh
```

### Simple Installation (minimal servers)
```bash
# Installs only time and git MCP servers
./install-claude-mcp-simple.sh
```

## What Gets Installed

### MCP Servers

1. **Time Server** - Date/time utilities
   - Get current time in any timezone
   - Convert between timezones
   - Calculate time differences

2. **Git Server** - Local repository operations
   - View commit history
   - Check file changes and diffs
   - Branch management

3. **GitHub Server** - GitHub API integration
   - Requires GITHUB_TOKEN environment variable
   - Read repository contents
   - Access issues and pull requests

4. **Playwright Server** - Browser automation
   - Includes devcontainer configuration
   - Automated browser testing support

5. **Context7 Server** - Advanced code intelligence
   - Deep code search across workspaces
   - Semantic code understanding
   - Project-wide context awareness

6. **MemoryBank Server** - Persistent memory storage
   - Store and retrieve memories across sessions
   - Organize information by categories
   - Version control for memories

7. **Sequential Memory Server** - Sequential thinking support
   - Track thoughts during problem-solving
   - Build knowledge incrementally
   - Maintain context across reasoning steps

8. **Serena IDE Assistant** - Advanced IDE capabilities
   - Code analysis and understanding
   - Refactoring suggestions
   - Test generation

## Configuration

### GitHub Token
```bash
export GITHUB_TOKEN='your-github-token'
```

To create a token:
1. Go to https://github.com/settings/tokens
2. Click 'Generate new token (classic)'
3. Select scopes: repo, read:org, read:user

### PATH Configuration

Add to your shell configuration (~/.bashrc or ~/.zshrc):
```bash
export PATH="$HOME/.npm-global/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"  # For uvx/Serena
```

## Managing MCP Servers

### List installed servers
```bash
claude mcp list
```

### Add a new server
```bash
claude mcp add <name> <command>
```

### Remove a server
```bash
claude mcp remove <name>
```

### Example additional servers
```bash
# File system access
claude mcp add filesystem npx @modelcontextprotocol/server-filesystem /path/to/allow

# PostgreSQL database
claude mcp add postgres npx @modelcontextprotocol/server-postgres postgresql://localhost/mydb

# SQLite database
claude mcp add sqlite npx @modelcontextprotocol/server-sqlite /path/to/database.db
```

## Troubleshooting

### Script hangs during installation
Use the non-interactive mode:
```bash
./install-claude-mcp.sh --non-interactive
```

### Claude not found
- If using Nix/Home Manager, Claude may be installed via system packages
- Check: `which claude`
- The script will detect system-installed Claude and skip npm installation

### MCP server fails to install
- Check npm is installed: `npm --version`
- Ensure Claude is installed: `claude --version`
- Try installing individually: `claude mcp add <name> <command>`

### GitHub server not working
- Ensure GITHUB_TOKEN is set: `echo $GITHUB_TOKEN`
- Token needs repo, read:org, and read:user scopes

### Playwright browsers not installed
```bash
# Install browsers manually
npx playwright install chromium webkit firefox

# Install system dependencies (Linux)
sudo npx playwright install-deps
```

## Devcontainer Support

For VS Code devcontainer support with Playwright:

1. Copy the generated `.devcontainer/` folder to your project
2. Install the "Dev Containers" extension in VS Code
3. Run command: "Dev Containers: Reopen in Container"

The devcontainer includes:
- All Playwright browsers pre-installed
- Node.js LTS and npm
- Playwright VS Code extension
- Persistent browser cache via volume mounts

## Data Locations

- NPM global packages: `~/.npm-global/`
- Context7 config: `~/.context7/config.json`
- MemoryBank data: `~/.memorybank/`
- Sequential memory: `~/.mcp-memory/`
- Serena config: `~/.serena/config.json`
- Git MCP repos: `~/.git-mcp/repositories.json`
- Playwright browsers: `~/.cache/ms-playwright/`