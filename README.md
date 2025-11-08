# AI Tools Installer & Dotfiles

A comprehensive dotfiles repository with integrated AI CLI tools, automated testing, and professional development workflow.

## ⚡ Quick Start

```bash
# Preview installation without making changes
./bootstrap.sh --dry-run

# Install dotfiles and tools
./bootstrap.sh

# Or use make
make install

# Install git hooks
make install-hooks

# Run tests
make test
```

## 🎯 Key Features

- ✅ **Automated Testing** - Comprehensive test framework with CI/CD
- ✅ **Dry-run Mode** - Preview changes before applying
- ✅ **Enhanced Logging** - Detailed logs with multiple levels
- ✅ **Git Hooks** - Pre-commit testing to prevent broken commits
- ✅ **Make Integration** - Common tasks via simple commands
- ✅ **Cross-platform** - Linux and macOS support (AMD64, ARM64, ARMv7)
- ✅ **Well-documented** - Comprehensive guides and troubleshooting

## 📦 Installation

### Basic Installation

```bash
# Standard installation
./bootstrap.sh

# With verbose output
./bootstrap.sh --verbose

# Preview only (no changes)
./bootstrap.sh --dry-run
```

### AI Tools Installation

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

### Using Make (Recommended)

```bash
make help          # Show all available commands
make install       # Install dotfiles
make test          # Run tests
make lint          # Run ShellCheck
make dry-run       # Preview changes
make check         # Run all checks
make backup        # Backup current configs
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

## 📚 Documentation

- **[Testing Guide](docs/testing-guide.md)** - How to write and run tests
- **[Troubleshooting Guide](docs/troubleshooting.md)** - Common issues and solutions
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

## 🔧 Development

### Setting Up Development Environment

```bash
# Install git hooks
make setup-dev

# This installs:
# - Pre-commit hooks for automatic testing
# - Development dependencies
```

### Running Checks Locally

```bash
# Run all CI checks locally
make ci

# Individual checks
make test          # Run test suite
make lint          # ShellCheck linting  
make validate      # Validate configs
```

### Making Changes

1. Make your changes
2. Run tests: `make test`
3. Check with: `make check`
4. Commit (pre-commit hook runs automatically)
5. Push

### Bootstrap Options

```bash
./bootstrap.sh [OPTIONS]

OPTIONS:
  -h, --help          Show help message
  -d, --dry-run       Preview changes without executing
  -v, --verbose       Enable verbose logging
  --log-file FILE     Set log file path

ENVIRONMENT VARIABLES:
  DRY_RUN=true        Same as --dry-run
  VERBOSE=true        Same as --verbose
  LOG_LEVEL=DEBUG     Set log level (DEBUG, INFO, WARN, ERROR)
  LOG_FILE=path       Custom log file path
```

## 🐛 Troubleshooting

See the comprehensive [Troubleshooting Guide](docs/troubleshooting.md) for common issues and solutions.

Quick tips:
- **Installation fails**: Check `~/.dotfiles-install.log`
- **Tests failing**: Run `./run-tests.sh --verbose`
- **Starship not working**: Run `./scripts/fix-starship`
- **Preview changes**: Use `./bootstrap.sh --dry-run`

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Add tests for new features
4. Ensure all tests pass: `make test`
5. Run linting: `make lint`
6. Submit a pull request

## 📊 Repository Statistics

```bash
make stats    # Show repository statistics
```

Current features:
- 30+ test cases across 3 test suites
- 100+ utility scripts and configurations
- Cross-platform support (Linux, macOS)
- Automated CI/CD with GitHub Actions
- Comprehensive documentation

