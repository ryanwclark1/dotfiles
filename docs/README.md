# Documentation Index

Welcome to the dotfiles documentation! This directory contains comprehensive guides for installation, configuration, testing, and troubleshooting.

## 📚 Table of Contents

### Quick Start Guides

- **[Testing Guide](guides/testing-guide.md)** - How to write and run tests
- **[Troubleshooting Guide](guides/troubleshooting.md)** - Common issues and solutions
- **[Docker Testing Guide](guides/docker-testing.md)** - Testing in isolated containers

### Reference Documentation

- **[Script Reference](guides/script-reference.md)** - Complete reference for all scripts and utilities

### Tool Setup Guides

#### AI Coding Assistants

- **[Serena Setup](setup/serena-setup.md)** - Coding agent with web dashboard and language servers
- **[Context7 Setup](setup/context7-setup.md)** - Code documentation and context generation
- **[Qwen Setup](setup/qwen-setup.md)** - Qwen CLI with Ollama integration

#### MCP (Model Context Protocol) Servers

- **[MCP Server Status](mcp/mcp-server-status.md)** - Current status of all MCP servers
- **[Claude to Gemini MCP Migration](mcp/claude-to-gemini-mcp-migration.md)** - Using MCP with Gemini CLI
- **[GitHub MCP Setup](mcp/github-mcp-setup.md)** - GitHub integration via MCP
- **[MemoryBank MCP Setup](mcp/memorybank-mcp-setup.md)** - Memory and context persistence

## 🚀 Getting Started

New to this repository? Start here:

1. Read the main [README.md](../README.md) for an overview
2. Review the [Testing Guide](guides/testing-guide.md) to understand the test framework
3. Check the [Troubleshooting Guide](guides/troubleshooting.md) if you encounter issues
4. Explore [Tool Setup Guides](#tool-setup-guides) for specific tools

## 📖 Documentation Organization

### Core Guides (`guides/`)

**testing-guide.md**
- Test framework overview
- Writing tests
- Running tests locally and in CI
- Test suite organization

**troubleshooting.md**
- Installation issues
- Shell configuration problems
- Tool-specific fixes
- Performance optimization
- Testing and CI problems

**docker-testing.md**
- Docker test modes (quick, full, multi-distro)
- Container setup and configuration
- CI integration
- Advanced usage and debugging

**script-reference.md**
- Complete script documentation
- Usage examples
- Options and flags
- Common workflows

### Setup Guides (`setup/`)

**serena-setup.md**
- Installation and configuration
- Web dashboard setup
- Language server integration
- Usage examples

**context7-setup.md**
- Project initialization
- Workspace configuration
- Advanced indexing
- Troubleshooting

**qwen-setup.md**
- Ollama integration
- Model configuration
- CLI usage
- Performance tuning

### MCP Documentation (`mcp/`)

**mcp-server-status.md**
- List of all configured MCP servers
- Server status and health
- Known issues
- Update information

**claude-to-gemini-mcp-migration.md**
- Configuration differences
- Migration steps
- Server compatibility
- Testing and validation

**github-mcp-setup.md**
- GitHub MCP server setup
- Authentication and tokens
- Available operations
- Usage examples

**memorybank-mcp-setup.md**
- Memory persistence setup
- Context management
- Configuration options
- Best practices

## 🔍 Finding Information

### By Topic

- **Installation**: See main [README.md](../README.md) and [guides/troubleshooting.md](guides/troubleshooting.md)
- **Testing**: See [guides/testing-guide.md](guides/testing-guide.md) and [guides/docker-testing.md](guides/docker-testing.md)
- **Scripts**: See [guides/script-reference.md](guides/script-reference.md)
- **AI Tools**: See individual setup guides under [Tool Setup Guides](#tool-setup-guides)
- **MCP Servers**: See docs under [MCP Documentation](#mcp-documentation)

### By Task

| Task | Documentation |
|------|---------------|
| Running tests | [guides/testing-guide.md](guides/testing-guide.md) |
| Testing in Docker | [guides/docker-testing.md](guides/docker-testing.md) |
| Fixing installation issues | [guides/troubleshooting.md](guides/troubleshooting.md) |
| Setting up Serena | [setup/serena-setup.md](setup/serena-setup.md) |
| Setting up Context7 | [setup/context7-setup.md](setup/context7-setup.md) |
| Configuring MCP servers | [mcp/mcp-server-status.md](mcp/mcp-server-status.md) |
| Using scripts | [guides/script-reference.md](guides/script-reference.md) |
| Contributing | [../CONTRIBUTING.md](../CONTRIBUTING.md) |

## 📝 Documentation Standards

All documentation in this directory follows these standards:

### Structure
- Clear title and overview
- Table of contents for docs >100 lines
- Organized sections with headers
- Examples and code blocks
- Troubleshooting section (where applicable)

### Formatting
- Markdown format
- Code blocks with language tags
- Links to related documentation
- Consistent header hierarchy

### Maintenance
- Keep documentation in sync with code
- Update version-specific information
- Remove outdated content
- Add dates to time-sensitive information

## 🤝 Contributing to Documentation

To improve this documentation:

1. Follow the documentation standards above
2. Test all commands and examples
3. Add screenshots where helpful (not required)
4. Update this index when adding new docs
5. Link to related documentation
6. Run spell check before committing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for general contribution guidelines.

## 📅 Recent Updates

- **2025-11-08**: Added comprehensive documentation cleanup
- **2025-11-08**: Added Docker testing guide
- **2025-11-08**: Created documentation index

## 🔗 External Resources

- [Anthropic Claude Documentation](https://docs.anthropic.com/)
- [Model Context Protocol (MCP)](https://modelcontextprotocol.io/)
- [Starship Prompt](https://starship.rs/)
- [Tmux Documentation](https://github.com/tmux/tmux/wiki)
- [Yazi File Manager](https://yazi-rs.github.io/)

---

**Navigation**: [Main README](../README.md) | [Contributing](../CONTRIBUTING.md) | [Changelog](../CHANGELOG.md)
