# MCP Server Status & Troubleshooting Guide

## Current Status (Updated Regularly)

### ✅ **WORKING MCP Servers** (Published to npm registry)

These servers are stable and should connect successfully:

| Server              | Package                                            | Status    | Notes                          |
| ------------------- | -------------------------------------------------- | --------- | ------------------------------ |
| sequential-thinking | `@modelcontextprotocol/server-sequential-thinking` | ✅ Working | Core MCP server                |
| memory              | `@modelcontextprotocol/server-memory`              | ✅ Working | Core MCP server                |
| everything          | `@modelcontextprotocol/server-everything`          | ✅ Working | Core MCP server                |
| github              | `@modelcontextprotocol/server-github`              | ✅ Working | Requires GitHub token          |
| puppeteer           | `@modelcontextprotocol/server-puppeteer`           | ✅ Working | Browser automation             |
| playwright          | `@playwright/mcp@latest`                           | ✅ Working | Browser automation             |
| asana               | `mcp-remote https://mcp.asana.com/sse`             | ✅ Working | Remote server                  |
| serena              | `uvx --from git+https://github.com/oraios/serena`  | ✅ Working | Filesystem + code intelligence |
| genai-toolbox       | `@googleapis/genai-toolbox`                        | ✅ Working | Database and AI tools          |
| context7            | `@upstash/context7-mcp`                            | ✅ Working | Up-to-date code documentation  |

### 🛠️ **DEVELOPMENT TOOLS**

These are tools for testing and debugging MCP servers:

| Tool          | Package                           | Status    | Notes                               |
| ------------- | --------------------------------- | --------- | ----------------------------------- |
| MCP Inspector | `@modelcontextprotocol/inspector` | ✅ Working | Visual testing tool for MCP servers |
| ccusage       | `ccusage@latest`                  | ✅ Working | Claude usage tracking tool          |

### ❌ **FAILING MCP Servers** (Not published to npm)

These servers exist in GitHub repositories but are not published to npm registry:

| Server          | Package                              | Status    | Issue                |
| --------------- | ------------------------------------ | --------- | -------------------- |
| git             | `@modelcontextprotocol/server-git`   | ❌ Failing | Not published to npm |
| fetch           | `@modelcontextprotocol/server-fetch` | ❌ Failing | Not published to npm |
| time            | `@modelcontextprotocol/server-time`  | ❌ Failing | Not published to npm |
| language-server | `@isaacphi/language-server-mcp`      | ❌ Failing | Not published to npm |
| run-python      | `@pydantic/mcp-run-python`           | ❌ Failing | Not published to npm |
| memory-bank     | `@alioshr/memory-bank-mcp`           | ❌ Failing | Not published to npm |

## Development Tools

### MCP Inspector

The [MCP Inspector](https://github.com/modelcontextprotocol/inspector) is a visual testing tool for MCP servers. It provides:

- **Interactive UI**: Visual interface for testing MCP servers
- **CLI Mode**: Scriptable commands for automation
- **Tool Testing**: Form-based parameter input and response visualization
- **Resource Exploration**: Hierarchical navigation of server resources
- **Debugging**: Request history and error visualization

#### Usage

```bash
# Start interactive inspector
./scripts/mcp-inspector

# Test a specific MCP server
./scripts/mcp-inspector npx @modelcontextprotocol/server-everything

# CLI mode for scripting
./scripts/mcp-inspector --cli npx @modelcontextprotocol/server-everything --method tools/list

# Use configuration file
./scripts/mcp-inspector --config my-config.json --server myserver
```

#### Features

- **UI Mode**: Best for development, debugging, and learning MCP
- **CLI Mode**: Ideal for automation, CI/CD, and scripting
- **Configuration**: Save server configurations for reuse
- **Authentication**: Secure token-based authentication
- **Real-time**: Live updates and streaming responses

## Why Some Servers Fail

### 1. **Not Published to npm Registry**
Most failing servers exist in GitHub repositories but haven't been published to npm yet. When you run:
```bash
npx @modelcontextprotocol/server-git
```
npm tries to find the package in the registry, fails, and the connection fails.

### 2. **Development Status**
Many MCP servers are still in development and not ready for production use.

### 3. **Package Name Mismatches**
Some servers might have different package names than expected.

## Solutions

### Option 1: Use Only Working Servers (Recommended)
The installer now only installs servers that are published to npm and known to work:

```bash
./install-ai-tools.sh --non-interactive
```

### Option 2: Manual Installation from GitHub
For experimental servers, you can try installing directly from GitHub:

```bash
# Example for git server
npm install -g git+https://github.com/modelcontextprotocol/server-git.git

# Then add to Claude manually
claude mcp add --scope user git -- npx @modelcontextprotocol/server-git
```

### Option 3: Wait for Official Releases
Monitor the MCP ecosystem for when these servers are officially published to npm.

## Checking Server Status

### Test Individual Servers
```bash
# Test if a server package exists
npx @modelcontextprotocol/server-git --help 2>&1 || echo "Package not found"

# Test connection (simulate Claude's connection)
echo '{"jsonrpc": "2.0", "method": "initialize", "params": {"protocolVersion": "0.1.0", "capabilities": {}}, "id": 1}' | timeout 5 npx @modelcontextprotocol/server-git
```

### List Current MCP Servers
```bash
# List installed servers
claude mcp list

# Check connection status
claude mcp list --verbose
```

## Troubleshooting

### Common Issues

1. **"Failed to connect" errors**
   - Server not published to npm
   - Network connectivity issues
   - Server crashed during startup

2. **"Package not found" errors**
   - Package not published to npm registry
   - Incorrect package name
   - Network issues preventing download

3. **Permission errors**
   - Check npm global installation permissions
   - Ensure PATH includes npm global bin directory

### Debug Steps

1. **Check npm registry**
   ```bash
   npm view @modelcontextprotocol/server-git
   ```

2. **Test with npx directly**
   ```bash
   npx @modelcontextprotocol/server-git --help
   ```

3. **Check Claude MCP list**
   ```bash
   claude mcp list
   ```

4. **Remove and reinstall**
   ```bash
   claude mcp remove git
   claude mcp add --scope user git -- npx @modelcontextprotocol/server-git
   ```

## Future Updates

When new MCP servers are published to npm, they can be easily added to the installer by:

1. Uncommenting the server in the `MCP_SERVERS` array
2. Testing the connection
3. Updating this documentation

## Resources

- [MCP Protocol Documentation](https://modelcontextprotocol.io/)
- [MCP Server Registry](https://github.com/modelcontextprotocol/registry)
- [Claude MCP Documentation](https://docs.anthropic.com/claude/docs/model-context-protocol-mcp)

## Contributing

If you find a working MCP server that's not listed here, please:
1. Test it thoroughly
2. Update the installer script
3. Update this documentation
4. Submit a pull request
