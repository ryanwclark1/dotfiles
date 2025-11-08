# AI Tools Installer

A comprehensive installer for AI CLIs (Claude, Gemini) and MCP servers with enhanced setup scripts.

## Quick Start

```bash
# Install all tools in non-interactive mode
./install-ai-tools.sh --non-interactive

# Check system readiness only
./install-ai-tools.sh --check

# Install only Claude CLI
./install-ai-tools.sh --claude-only

# Install only Gemini CLI
./install-ai-tools.sh --gemini-only

# Install only Qwen CLI (with Ollama integration)
./install-ai-tools.sh --qwen-only
```

## Enhanced Setup Scripts

### Serena (Coding Agent)
```bash
# Enhanced Serena setup with web dashboard and language servers
./setup/setup-serena.sh

# Quick start Serena
serena [project_path] [mode]

# Initialize a project
serena-init [project_name] [project_path]
```

### GenAI Toolbox (Database Tools)
```bash
# Setup GenAI Toolbox for database operations
./setup/setup-genai-toolbox.sh

# Configure databases in ~/.genai-toolbox/tools.yaml
```

### Context7 (Code Documentation)
```bash
# Comprehensive Context7 setup with uv workspace support
./setup/setup-context7.sh

# Initialize project: context7-init [project_name] [project_path]
# Add project: context7-add [project_name] [project_path]
```

### Sourcebot (Source Code Search)
```bash
# Test sourcebot MCP installation
./tests/test-sourcebot-mcp.sh

# Sourcebot provides source code search and analysis capabilities
# Configured with: SOURCEBOT_HOST=http://localhost:3002
```

## Features

- **Non-interactive mode** for automated installations
- **Enhanced Serena setup** with web dashboard and language servers
- **GenAI Toolbox integration** for database operations
- **Comprehensive Context7 setup** with uv workspace support and advanced indexing
- **Sourcebot MCP server** for source code search and analysis
- **Qwen CLI integration** with Ollama for local model inference
- **MCP Inspector** for testing and debugging
- **Comprehensive error handling** and logging

## Documentation

- [MCP Server Status](docs/mcp-server-status.md) - Current status of all MCP servers
- [Serena Setup Guide](docs/serena-setup.md) - Complete Serena documentation
- [Context7 Setup Guide](docs/context7-setup.md) - Context7 documentation
- [Qwen Setup Guide](docs/qwen-setup.md) - Qwen CLI with Ollama integration

## Testing

The repository includes a comprehensive testing framework to ensure reliability.

```bash
# Run all tests
./run-tests.sh

# Run specific test suite
./run-tests.sh bootstrap
./run-tests.sh configs
./run-tests.sh scripts

# List available test suites
./run-tests.sh --list

# Test non-interactive installation mode
./tests/test-non-interactive.sh

# Test MCP Inspector
./scripts/mcp-inspector

# Clean up failing MCP servers
./scripts/cleanup-failing-mcps.sh
```

See [Testing Guide](docs/testing-guide.md) for details on writing and running tests.
