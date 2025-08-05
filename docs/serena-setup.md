# Serena MCP Server Setup Guide

## Overview

[Serena](https://github.com/oraios/serena) is a powerful coding agent toolkit with 7.4k stars that provides semantic retrieval and editing capabilities through an MCP server. It's the first fully-featured coding agent available as an MCP server without requiring API keys or subscriptions.

## What Serena Does

- **Semantic Code Analysis**: Uses language servers for symbolic understanding of code
- **Multi-language Support**: Python, JavaScript, TypeScript, Go, Rust, Java, C++, C#
- **File Operations**: Read, write, edit, and manage files with context awareness
- **Memory System**: Project-specific memory for context retention
- **Web Dashboard**: Real-time monitoring and statistics
- **Log Window**: Debugging and troubleshooting interface
- **Security**: Restricted file operations and shell command controls

## Installation

### Automatic Installation

Serena is automatically installed when you run:

```bash
./install-ai-tools.sh --non-interactive
```

### Manual Installation

For enhanced setup with additional features:

```bash
./setup-serena.sh
```

## Configuration

### Main Configuration

The enhanced setup creates a comprehensive configuration at `~/.serena/serena_config.yml`:

```yaml
# Project configuration
project: ~/workspace
context: ide-assistant

# Language server configuration
language_server:
  enabled: true
  languages:
    - python
    - javascript
    - typescript
    - go
    - rust
    - java
    - cpp
    - csharp

# Web dashboard configuration
web_dashboard:
  enabled: true
  port: 8080
  host: localhost

# Log window configuration
log_window:
  enabled: true
  port: 8081
  host: localhost

# Memory configuration
memory:
  enabled: true
  max_memories: 100

# Security settings
security:
  restrict_to_project: true
  allow_shell_commands: false
  max_file_size: 10485760  # 10MB

# Performance settings
performance:
  max_parallel_files: 10
  enable_caching: true
  cache_timeout: 3600
```

### Project-Specific Configuration

Initialize a project with Serena:

```bash
# Initialize current directory
serena-init

# Initialize specific project
serena-init my-project ~/projects/my-project
```

This creates `.serena/project.yml` in your project directory.

## Usage

### Quick Start

```bash
# Start Serena with default project
serena

# Start with specific project and mode
serena ~/my-project development

# Start in debugging mode
serena ~/my-project debugging
```

### Available Modes

- **default**: Basic code analysis and file operations
- **development**: Full development tools including shell operations
- **debugging**: Enhanced debugging with language server operations

### Web Interface

- **Dashboard**: http://localhost:8080 - Monitor tool usage and statistics
- **Log Window**: http://localhost:8081 - View logs and debug information

## Available Tools

Serena provides 30+ tools for code analysis and manipulation:

### Code Analysis
- `find_symbol`: Search for symbols in codebase
- `get_symbols_overview`: Get overview of top-level symbols
- `find_referencing_code_snippets`: Find code that references a symbol
- `find_referencing_symbols`: Find symbols that reference another symbol

### File Operations
- `read_file`: Read file contents
- `create_text_file`: Create or overwrite files
- `insert_at_line`: Insert content at specific line
- `replace_lines`: Replace line ranges
- `delete_lines`: Delete line ranges
- `list_dir`: List directory contents

### Memory Operations
- `write_memory`: Store project-specific memories
- `read_memory`: Retrieve stored memories
- `list_memories`: List all project memories
- `delete_memory`: Remove specific memories

### Project Management
- `activate_project`: Switch between projects
- `get_active_project`: Get current project info
- `onboarding`: Initialize project structure analysis
- `check_onboarding_performed`: Check if project is onboarded

### Advanced Operations
- `execute_shell_command`: Run shell commands (optional)
- `restart_language_server`: Restart language server
- `switch_modes`: Change operation modes
- `get_current_config`: View current configuration

### Thinking Tools
- `think_about_collected_information`: Analyze information completeness
- `think_about_task_adherence`: Check if on track with task
- `think_about_whether_you_are_done`: Determine if task is complete

## Language Support

Serena supports multiple programming languages through language servers:

- **Python**: Full syntax analysis and refactoring
- **JavaScript/TypeScript**: ES6+ features and type checking
- **Go**: Static analysis and code navigation
- **Rust**: Ownership analysis and error checking
- **Java**: Class hierarchy and dependency analysis
- **C++**: Template analysis and symbol resolution
- **C#**: .NET framework integration

## Security Features

- **Project Restriction**: File operations limited to project directory
- **Shell Command Control**: Optional shell command execution
- **File Size Limits**: 10MB maximum file size for operations
- **Extension Filtering**: Only allowed file types can be modified
- **Memory Limits**: Configurable memory storage limits

## Performance Optimizations

- **Parallel Processing**: Up to 10 files processed simultaneously
- **Response Caching**: Language server responses cached for 1 hour
- **Selective Analysis**: Only analyze relevant file types
- **Memory Management**: Automatic cleanup of old memories

## Troubleshooting

### Common Issues

1. **Language Server Not Working**
   ```bash
   # Restart language server
   claude "restart the language server"
   ```

2. **File Operations Failing**
   - Check file permissions
   - Ensure file is within project directory
   - Verify file extension is allowed

3. **Memory Issues**
   ```bash
   # Clear project memories
   claude "delete all memories for this project"
   ```

4. **Web Dashboard Not Loading**
   - Check if port 8080 is available
   - Verify firewall settings
   - Restart Serena with different port

### Debug Mode

Enable debug mode for detailed logging:

```bash
serena ~/my-project debugging
```

### Log Analysis

Check Serena logs:

```bash
tail -f ~/.serena/serena.log
```

## Comparison with Other Tools

### vs. IDE-based Agents (Cursor, Windsurf)
- ✅ No subscription required
- ✅ Works with any MCP client
- ✅ Symbolic code understanding
- ✅ Open-source and extensible

### vs. API-based Agents (Claude Code, Cline)
- ✅ No API costs
- ✅ No rate limits
- ✅ Works offline
- ✅ Full MCP integration

### vs. Other MCP Servers
- ✅ Semantic code analysis
- ✅ Language server integration
- ✅ Memory system
- ✅ Web dashboard

## Advanced Configuration

### Custom Language Servers

Add custom language server configurations:

```yaml
language_server:
  custom_servers:
    mylang:
      command: mylang-lsp
      args: ["--stdio"]
      file_patterns: ["*.ml"]
```

### Memory Configuration

Configure memory retention:

```yaml
memory:
  enabled: true
  max_memories: 100
  retention_days: 30
  auto_cleanup: true
```

### Performance Tuning

Optimize for your system:

```yaml
performance:
  max_parallel_files: 20  # Increase for powerful systems
  cache_timeout: 7200     # Longer cache for stability
  memory_limit: 512       # MB limit for language servers
```

## Resources

- [Serena GitHub Repository](https://github.com/oraios/serena)
- [MCP Protocol Documentation](https://modelcontextprotocol.io/)
- [Language Server Protocol](https://microsoft.github.io/language-server-protocol/)

## Community

- 📢 Follow [@oraios](https://github.com/oraios) on GitHub
- 💬 Join discussions on [GitHub Issues](https://github.com/oraios/serena/issues)
- 🌟 Star the repository if you find it useful
