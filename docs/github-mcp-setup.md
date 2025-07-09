# GitHub MCP Server Setup Guide

## Overview

The GitHub MCP (Model Context Protocol) server enables Claude to interact with GitHub repositories, issues, pull requests, and more. This guide covers setup and usage.

## Prerequisites

1. Claude Code installed (`@anthropic-ai/claude-code`)
2. GitHub personal access token with appropriate permissions
3. npm/Node.js installed

## Installation

The GitHub MCP server is automatically installed when you run:

```bash
./install-claude-tools.sh
```

## GitHub Token Setup

### Creating a Personal Access Token

1. Go to [GitHub Settings > Tokens](https://github.com/settings/tokens)
2. Click "Generate new token (classic)"
3. Give your token a descriptive name (e.g., "Claude MCP Access")
4. Select the following scopes:
   - `repo` - Full control of private repositories
   - `read:org` - Read org and team membership
   - `read:user` - Read user profile data
5. Click "Generate token"
6. Copy the token immediately (you won't see it again!)

### Setting the Token

#### Option 1: During Installation
The install script will prompt you to enter your GitHub token if not already set.

#### Option 2: Manual Setup
Add to your shell configuration file:

```bash
# For bash (~/.bashrc)
export GITHUB_TOKEN='ghp_your_token_here'

# For zsh (~/.zshrc)
export GITHUB_TOKEN='ghp_your_token_here'
```

Then reload your shell:
```bash
source ~/.bashrc  # or ~/.zshrc
```

#### Option 3: Secure Storage (Recommended)
Use a password manager or secure environment variable storage:

```bash
# Using 1Password CLI (if available)
export GITHUB_TOKEN=$(op read "op://Private/GitHub MCP Token/token")

# Using macOS Keychain
security add-generic-password -a "$USER" -s "github-mcp-token" -w "your_token_here"
export GITHUB_TOKEN=$(security find-generic-password -a "$USER" -s "github-mcp-token" -w)
```

## Usage with Claude

Once configured, Claude can:

### Repository Operations
- Read repository contents and structure
- Access file contents
- Navigate branches and tags
- View commit history

### Issues and Pull Requests
- List and read issues
- View pull request details
- Access comments and reviews
- Search through issues/PRs

### Organization Access
- List organization repositories
- View team structures
- Access organization-level data

### Code Search
- Search code across repositories
- Find specific implementations
- Locate configuration files

## Example Commands

When chatting with Claude, you can ask:

- "Show me the README from owner/repo"
- "List all open issues in my repository"
- "Search for implementations of functionName"
- "What are the recent pull requests?"
- "Show me the package.json from the main branch"

## Troubleshooting

### Token Not Working
1. Verify token has correct scopes
2. Check token hasn't expired
3. Ensure GITHUB_TOKEN is exported in current shell
4. Try regenerating the token

### Permission Errors
- For private repos, ensure token has `repo` scope
- For organization repos, verify you have access
- Check if SSO is required for your organization

### Rate Limiting
GitHub API has rate limits:
- Authenticated: 5,000 requests/hour
- Unauthenticated: 60 requests/hour

Monitor your usage to avoid hitting limits.

## Security Best Practices

1. **Never commit tokens**: Add to `.gitignore`:
   ```
   .env
   .env.local
   *.token
   ```

2. **Use minimal scopes**: Only grant permissions you need

3. **Rotate tokens regularly**: Set calendar reminders

4. **Use environment-specific tokens**: Different tokens for dev/prod

5. **Monitor token usage**: Check GitHub settings for last used dates

## DevContainer Usage

When using with devcontainers, the GitHub token is automatically passed from your host environment:

```json
"remoteEnv": {
    "GITHUB_TOKEN": "${localEnv:GITHUB_TOKEN}"
}
```

This ensures the token is available inside the container without hardcoding.

## Revoking Access

If you need to revoke access:

1. Go to [GitHub Settings > Tokens](https://github.com/settings/tokens)
2. Find your token
3. Click "Delete" or "Revoke"
4. Remove from shell configuration
5. Restart your terminal

## Additional Resources

- [GitHub MCP Server Documentation](https://github.com/modelcontextprotocol/servers/tree/main/src/github)
- [GitHub API Documentation](https://docs.github.com/en/rest)
- [Personal Access Token Guide](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)