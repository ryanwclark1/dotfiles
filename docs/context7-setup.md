# Context7 MCP Server Setup Guide

## Overview

[Context7](https://github.com/upstash/context7) is a powerful MCP server that provides **up-to-date code documentation** for LLMs and AI code editors. It's one of the most popular MCP servers with over 24k stars on GitHub.

## What Context7 Does

- **Real-time Documentation**: Provides current, up-to-date documentation for libraries and frameworks
- **Library Resolution**: Automatically finds the right documentation for any library
- **Code Examples**: Delivers working, current code examples
- **API Documentation**: Access to the latest API documentation
- **Setup Guides**: Step-by-step installation and configuration guides
- **Multi-workspace Support**: Manage multiple projects with advanced indexing
- **Fuzzy Search**: Intelligent search with context-aware results
- **Deep Code Search**: Search across multiple workspaces with advanced filters
- **Semantic Understanding**: Understands code structure and relationships
- **Context Awareness**: Maintains project-wide context for better suggestions
- **Intelligent Navigation**: Navigate codebases efficiently
- **Pattern Recognition**: Identify code patterns and similar implementations
- **Multi-language Support**: Works with most programming languages

## Installation

### Automatic Installation

Context7 is automatically installed when you run:

```bash
./install-ai-tools.sh --non-interactive
```

### Manual Installation

For comprehensive setup with advanced features:

```bash
./setup-context7.sh
```

## Configuration

### Main Configuration

The comprehensive setup creates a configuration at `~/.context7/config.json`:

```json
{
  "workspaces": [
    {
      "name": "default",
      "path": "~/workspace",
      "description": "Default workspace for projects"
    }
  ],
  "settings": {
    "indexing": {
      "enabled": true,
      "excludePatterns": [
        "**/node_modules/**",
        "**/.git/**",
        "**/dist/**",
        "**/build/**",
        "**/*.log",
        "**/.DS_Store",
        "**/.venv/**",
        "**/venv/**",
        "**/__pycache__/**",
        "**/.mypy_cache/**",
        "**/.ruff_cache/**",
        "**/target/**",
        "**/vendor/**",
        "**/.gradle/**",
        "**/cmake-build-*/**"
      ],
      "includePatterns": [
        "**/*.js", "**/*.ts", "**/*.jsx", "**/*.tsx",
        "**/*.py", "**/*.go", "**/*.rs", "**/*.java",
        "**/*.cpp", "**/*.c", "**/*.h", "**/*.md",
        "**/*.json", "**/*.yaml", "**/*.yml", "**/*.toml"
      ]
    },
    "search": {
      "maxResults": 100,
      "contextLines": 3,
      "fuzzyMatch": true,
      "caseSensitive": false
    },
    "performance": {
      "maxFileSize": 10485760,
      "maxFiles": 10000,
      "cacheTimeout": 3600,
      "parallelIndexing": true
    },
    "security": {
      "allowedPaths": [
        "~/workspace",
        "~/projects",
        "~/Code"
      ],
      "restrictToWorkspace": true
    }
  }
}
```

### Project-Specific Configuration

Initialize a project with Context7:

```bash
# Initialize current directory
context7-init

# Initialize specific project
context7-init my-project ~/projects/my-project
```

## Advanced Features

### 🎯 **Intelligent Dependency Detection**

The comprehensive setup automatically analyzes your project files to detect dependencies:

#### **Supported Package Managers**

| Language | Package Manager | Files Detected                                   |
| -------- | --------------- | ------------------------------------------------ |
| Node.js  | npm/yarn/pnpm   | `package.json`                                   |
| Python   | pip/poetry/uv   | `pyproject.toml`, `requirements.txt`, `setup.py` |
| Go       | go modules      | `go.mod`                                         |
| Rust     | cargo           | `Cargo.toml`                                     |
| Java     | maven/gradle    | `pom.xml`, `build.gradle`                        |
| C++      | cmake/make      | `CMakeLists.txt`, `Makefile`                     |

#### **Framework Detection**

Automatically detects popular frameworks:

- **Node.js**: Next.js, Nuxt, Vue, Angular, Svelte, Express
- **Python**: FastAPI, Django, Flask, Streamlit, Jupyter
- **Go**: Gin, Echo, Fiber, Chi
- **Rust**: Tokio, Actix, Rocket, Axum
- **Java**: Spring Boot, Quarkus, Micronaut

### 🏗️ **uv Workspace Support**

For complex Python projects using uv workspaces:

```toml
# Root workspace pyproject.toml
[project]
dependencies = [
  "accent-core",
  "accent-gateway",
  "accent-engine",
]

[tool.uv.workspace]
members = [
    "service/accent-core",
    "service/accent-gateway",
    "service/accent-engine",
]

[dependency-groups]
dev = ["bandit", "celery", "mypy", "pytest"]
test = ["pytest", "coverage", "httpx"]
docs = ["mkdocs", "mkdocs-material"]
```

### 📦 **Monorepo Intelligence**

Handles complex project structures:

- **Multi-package Analysis**: Analyzes each package in the monorepo
- **Shared Dependencies**: Identifies dependencies shared across packages
- **Package-specific Configurations**: Creates optimized settings per package
- **Dependency Resolution**: Handles complex dependency relationships

### 🐳 **Devcontainer Optimization**

- **Local Execution**: Context7 runs locally in your devcontainer
- **Project-specific Configuration**: Each project gets optimized settings
- **Dependency-aware Indexing**: Focuses on relevant file types and patterns
- **Performance Tuning**: Optimized for containerized environments

## Library Mapping

Converts detected dependencies to Context7 library IDs:

| Detected Dependency | Context7 Library ID      |
| ------------------- | ------------------------ |
| `npm:react`         | `/react/react`           |
| `npm:next`          | `/vercel/next.js`        |
| `python:fastapi`    | `/fastapi/fastapi`       |
| `python:django`     | `/django/django`         |
| `go:gin`            | `/gin-gonic/gin`         |
| `rust:tokio`        | `/tokio/tokio`           |
| `python:pandas`     | `/pandas/pandas`         |
| `python:numpy`      | `/numpy/numpy`           |
| `python:sqlalchemy` | `/sqlalchemy/sqlalchemy` |
| `python:pydantic`   | `/pydantic/pydantic`     |

## Usage Examples

### Basic Project Initialization

```bash
# Initialize current directory
context7-init

# Initialize specific project
context7-init my-project ~/projects/my-project
```

### Advanced Project Analysis

```bash
# Example: Node.js project with Next.js
# Detects: nodejs, framework:nextjs, npm:react, npm:next, npm:typescript
context7-init my-nextjs-app

# Example: Python project with FastAPI
# Detects: python, python:fastapi, python:pydantic, python:uvicorn
context7-init my-fastapi-app

# Example: uv workspace with multiple services
# Detects: uv-workspace, workspace-member:service/accent-core, workspace-member:service/accent-gateway
context7-init accent-ai-monorepo
```

### Project Configuration

Creates optimized `.context7/project.json`:

```json
{
  "name": "my-nextjs-app",
  "description": "Enhanced Context7 configuration for my-nextjs-app",
  "path": "/workspace/my-nextjs-app",
  "language": "javascript",
  "frameworks": ["nextjs"],
  "dependencies": ["nodejs", "npm:react", "npm:next", "npm:typescript"],
  "context7_libraries": ["/react/react", "/vercel/next.js"],
  "settings": {
    "devcontainer": {
      "enabled": true,
      "autoDetectDependencies": true,
      "libraryMappings": ["/react/react", "/vercel/next.js"]
    },
    "indexing": {
      "excludePatterns": [
        "**/node_modules/**",
        "**/.next/**",
        "**/dist/**",
        "**/build/**"
      ],
      "includePatterns": [
        "**/*.js", "**/*.ts", "**/*.jsx", "**/*.tsx"
      ]
    }
  }
}
```

## Convenience Scripts

### `context7`
Quick launcher for Context7:

```bash
# Launch Context7 for current directory
context7

# Launch for specific project
context7 ~/projects/my-project
```

### `context7-init`
Project initialization script:

```bash
# Initialize current directory
context7-init

# Initialize with custom name
context7-init my-project

# Initialize specific path
context7-init my-project ~/projects/my-project
```

### `context7-add`
Add libraries to project:

```bash
# Add specific library
context7-add /react/react

# Add multiple libraries
context7-add /react/react /vercel/next.js /typescript/typescript
```

## Troubleshooting

### Common Issues

#### **Context7 not found**
```bash
# Check if Context7 is installed
claude mcp list | grep context7

# Reinstall if needed
./setup-context7.sh
```

#### **Project not detected**
```bash
# Check project structure
ls -la

# Ensure you have package files (package.json, pyproject.toml, etc.)
# Reinitialize project
context7-init
```

#### **Dependencies not mapped**
```bash
# Check detected dependencies
cat .context7/project.json

# Manually add libraries
context7-add /library/name
```

### Debug Mode

Enable debug logging:

```bash
# Set debug environment variable
export CONTEXT7_DEBUG=true

# Run Context7 with debug output
context7
```

## Integration with Claude

### MCP Server Status

Check if Context7 is properly installed:

```bash
claude mcp list
```

Expected output:
```
context7: npx @upstash/context7-mcp ✓ Connected
```

### Using Context7 with Claude

Once installed, you can ask Claude to:

- **Search code**: "Find all React components in my project"
- **Get documentation**: "Show me FastAPI documentation for routing"
- **Analyze patterns**: "Find similar authentication implementations"
- **Navigate code**: "Show me the main entry point of this application"

## Performance Optimization

### Indexing Settings

Optimize for your project size:

```json
{
  "settings": {
    "indexing": {
      "maxFiles": 50000,        // Large projects
      "maxFileSize": 20971520,  // 20MB files
      "parallelIndexing": true  // Faster indexing
    }
  }
}
```

### Caching

Enable caching for better performance:

```json
{
  "settings": {
    "performance": {
      "enableCaching": true,
      "cacheTimeout": 7200,     // 2 hours
      "cacheSize": 1000         // Cache size in MB
    }
  }
}
```

## Security Considerations

### File Access Restrictions

```json
{
  "settings": {
    "security": {
      "allowedPaths": [
        "~/workspace",
        "~/projects"
      ],
      "restrictToWorkspace": true,
      "maxFileSize": 10485760   // 10MB limit
    }
  }
}
```

### Environment Variables

Context7 respects environment variables:

```bash
# Set custom workspace
export CONTEXT7_WORKSPACE=~/my-projects

# Set debug mode
export CONTEXT7_DEBUG=true

# Set custom config path
export CONTEXT7_CONFIG=~/.context7/custom-config.json
```

## Documentation

- **Official Documentation**: https://github.com/upstash/context7
- **MCP Protocol**: https://modelcontextprotocol.io/
- **Claude Integration**: https://docs.anthropic.com/claude/docs

## Support

For issues and questions:

1. Check the troubleshooting section above
2. Review the project configuration at `~/.context7/config.json`
3. Check the Context7 logs at `~/.context7/logs/`
4. Visit the [Context7 GitHub repository](https://github.com/upstash/context7)
