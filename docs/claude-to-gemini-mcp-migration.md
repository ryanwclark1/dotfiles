# Claude to Gemini MCP Migration Guide

This guide explains how to configure MCP (Model Context Protocol) servers for Gemini CLI, based on the Claude MCP setup in this dotfiles repository.

## Key Differences

### Claude MCP Configuration
- Uses `claude mcp add` commands to dynamically add MCP servers
- Configuration is stored internally by the Claude CLI
- Servers are added via the `install-ai-tools.sh` script

### Gemini MCP Configuration
- Uses a JSON configuration file (`settings.json`)
- Supports multiple configuration locations (user, project, system)
- MCP servers are defined in the `mcpServers` section

## Configuration File Locations

Gemini looks for `settings.json` in these locations (in order of precedence):
1. **User level**: `~/.gemini/settings.json`
2. **Project level**: `.gemini/settings.json` (in current directory)
3. **System level**: `/etc/gemini-cli/settings.json`

## Migration Steps

### 1. Create Gemini Configuration Directory
```bash
mkdir -p ~/.gemini
```

### 2. Copy the Template Configuration
```bash
cp gemini/settings.json ~/.gemini/settings.json
```

### 3. Configure API Keys

Edit `~/.gemini/settings.json` and replace the placeholder API keys:

- **Brave Search**: Replace `YOUR_BRAVE_API_KEY_HERE` with your actual Brave API key
- **GitHub**: Replace `YOUR_GITHUB_TOKEN_HERE` with your GitHub personal access token

### 4. Adjust File System Paths

The filesystem server in the template allows access to `/home` and `/workspace`. Modify these paths based on your needs:

```json
"filesystem": {
  "command": "npx",
  "args": ["@modelcontextprotocol/server-filesystem", "/path/to/allow", "/another/path"],
  "trust": true
}
```

## MCP Server Configuration Format

Each MCP server in Gemini is configured with these properties:

- **command** (required): The command to start the server
- **args** (optional): Array of arguments to pass to the command
- **env** (optional): Environment variables for the server
- **cwd** (optional): Working directory for the server
- **timeout** (optional): Request timeout in milliseconds
- **trust** (optional): Whether to bypass tool call confirmations

## Example: Adding a Custom MCP Server

To add a custom Python-based MCP server:

```json
"myCustomServer": {
  "command": "python",
  "args": ["/path/to/mcp_server.py", "--port", "8080"],
  "cwd": "/path/to/server/directory",
  "env": {
    "MY_API_KEY": "secret_key"
  },
  "timeout": 5000,
  "trust": false
}
```

## Verifying Configuration

After setting up the configuration, you can verify it's working:

```bash
# Check if Gemini is reading your configuration
gemini --version

# List available extensions/tools
gemini --list-extensions
```

## Notes

1. **MCP Protocol Compatibility**: While both Claude and Gemini support MCP, verify that specific MCP servers are compatible with Gemini's implementation.

2. **Tool Name Conflicts**: If multiple MCP servers expose tools with the same name, Gemini prefixes them with the server alias (e.g., `filesystem.read_file` vs `git.read_file`).

3. **Security**: The `trust` property bypasses tool call confirmations. Only set this to `true` for servers you fully trust.

4. **Environment Variables**: Sensitive data like API keys should be stored as environment variables rather than directly in the config file:
   ```json
   "env": {
     "BRAVE_API_KEY": "${BRAVE_API_KEY}"
   }
   ```

## Troubleshooting

1. **MCP Server Not Found**: Ensure the npm packages are installed globally or in your project
2. **Permission Denied**: Check that the filesystem server has appropriate path permissions
3. **Configuration Not Loading**: Verify the JSON syntax and file location
4. **API Key Issues**: Ensure environment variables are properly set if using variable substitution