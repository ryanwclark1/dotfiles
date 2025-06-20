# Context7 MCP Server Setup Guide

## Overview

Context7 is an advanced code intelligence MCP server that provides deep code search, semantic understanding, and project-wide context awareness for Claude. It indexes your codebase and enables intelligent navigation and search capabilities.

## Features

- **Deep Code Search**: Search across multiple workspaces with advanced filters
- **Semantic Understanding**: Understands code structure and relationships
- **Context Awareness**: Maintains project-wide context for better suggestions
- **Intelligent Navigation**: Navigate codebases efficiently
- **Pattern Recognition**: Identify code patterns and similar implementations
- **Multi-language Support**: Works with most programming languages

## Installation

Context7 is automatically installed when you run:

```bash
./install-claude-mcp.sh
```

## Configuration

### Default Configuration

The installer creates a default configuration at `~/.context7/config.json`:

```json
{
  "workspaces": [
    {
      "name": "default",
      "path": "~/projects",
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
        "**/.DS_Store"
      ],
      "includePatterns": [
        "**/*.js", "**/*.ts", "**/*.jsx", "**/*.tsx",
        "**/*.py", "**/*.go", "**/*.rs", "**/*.java",
        "**/*.cpp", "**/*.c", "**/*.h", "**/*.md",
        "**/*.json", "**/*.yaml", "**/*.yml",
        "**/*.toml", "**/*.xml", "**/*.html",
        "**/*.css", "**/*.scss", "**/*.sass"
      ]
    },
    "search": {
      "maxResults": 100,
      "contextLines": 3
    }
  }
}
```

### Adding Workspaces

To add additional workspaces, edit `~/.context7/config.json`:

```json
{
  "workspaces": [
    {
      "name": "dotfiles",
      "path": "~/Code/dotfiles",
      "description": "Personal dotfiles configuration"
    },
    {
      "name": "work",
      "path": "~/Work",
      "description": "Work projects"
    },
    {
      "name": "personal",
      "path": "~/Projects",
      "description": "Personal projects"
    }
  ]
}
```

### Customizing File Patterns

#### Exclude Patterns

Add patterns to exclude specific files or directories:

```json
"excludePatterns": [
  "**/node_modules/**",
  "**/.git/**",
  "**/vendor/**",
  "**/coverage/**",
  "**/*.min.js",
  "**/package-lock.json"
]
```

#### Include Patterns

Specify which file types to index:

```json
"includePatterns": [
  "**/*.js",
  "**/*.ts",
  "**/*.py",
  "**/*.go",
  "**/*.rs",
  "**/*.rb",
  "**/*.php",
  "**/*.swift",
  "**/*.kt"
]
```

### Search Settings

Configure search behavior:

```json
"search": {
  "maxResults": 100,      // Maximum results per search
  "contextLines": 3,      // Lines of context around matches
  "caseSensitive": false, // Case sensitivity
  "useRegex": true        // Enable regex search
}
```

## Usage with Claude

Once configured, you can ask Claude to:

### Code Search
- "Search for all implementations of UserService"
- "Find all places where API_KEY is used"
- "Show me all error handlers in the project"
- "Find similar code to this function"

### Navigation
- "Show me the file structure of the auth module"
- "Navigate to the database configuration"
- "List all test files in the project"
- "Show dependencies of this module"

### Analysis
- "What does this codebase do?"
- "Explain the architecture of this project"
- "Find potential security issues"
- "Identify code duplication"

### Context Understanding
- "How is authentication implemented?"
- "What's the data flow for user registration?"
- "Show me the API endpoints"
- "Explain the testing strategy"

## Advanced Configuration

### Performance Tuning

For large codebases, optimize indexing:

```json
"indexing": {
  "enabled": true,
  "batchSize": 100,          // Files per batch
  "maxFileSize": 1048576,    // 1MB max file size
  "updateInterval": 300000,   // Re-index every 5 minutes
  "threads": 4               // Parallel indexing threads
}
```

### Custom Language Support

Add support for custom file extensions:

```json
"languages": {
  "customExtensions": {
    ".vue": "javascript",
    ".svelte": "javascript",
    ".prisma": "typescript",
    ".tf": "hcl"
  }
}
```

### Workspace-Specific Settings

Override settings per workspace:

```json
"workspaces": [
  {
    "name": "legacy-project",
    "path": "~/legacy",
    "settings": {
      "indexing": {
        "includePatterns": ["**/*.java", "**/*.xml"],
        "maxFileSize": 5242880  // 5MB for this workspace
      }
    }
  }
]
```

## Troubleshooting

### Index Not Updating

1. Check if indexing is enabled in config
2. Verify file patterns match your files
3. Check for errors in Claude's logs
4. Manually trigger re-index by restarting Claude

### Search Not Finding Results

1. Verify workspace paths are correct
2. Check include/exclude patterns
3. Ensure files are within size limits
4. Try simpler search queries first

### Performance Issues

1. Reduce number of indexed files
2. Add more exclude patterns
3. Decrease batch size
4. Limit maximum file size

### Configuration Errors

1. Validate JSON syntax: `jq . ~/.context7/config.json`
2. Check all paths exist and are accessible
3. Ensure no duplicate workspace names
4. Verify pattern syntax

## Best Practices

1. **Organize Workspaces**: Group related projects together
2. **Exclude Generated Files**: Add build outputs to excludePatterns
3. **Regular Updates**: Periodically review and update patterns
4. **Use Descriptive Names**: Make workspace names meaningful
5. **Test Patterns**: Verify patterns work as expected
6. **Monitor Performance**: Adjust settings for optimal speed

## Integration with DevContainers

When using with devcontainers, mount the Context7 config:

```json
"mounts": [
  "source=${localEnv:HOME}/.context7,target=/home/vscode/.context7,type=bind,consistency=cached"
]
```

This ensures your workspace configuration persists across container rebuilds.

## Security Considerations

1. **Sensitive Files**: Exclude files containing secrets
2. **Access Control**: Context7 has access to all indexed files
3. **API Keys**: Never include files with hardcoded credentials
4. **Private Repos**: Be cautious with proprietary code

## Commands Reference

Common Context7 queries for Claude:

```
# Search
"search for function:<name>"
"find all TODO comments"
"show usage of <variable>"

# Navigate
"go to file <filename>"
"show directory structure"
"list all files matching <pattern>"

# Analyze
"explain this codebase"
"find security issues"
"suggest improvements"

# Context
"what does <module> do?"
"how do I use <feature>?"
"show related code"
```

## Additional Resources

- [Context7 Documentation](https://github.com/context7/mcp-server)
- [MCP Protocol Specification](https://modelcontextprotocol.org)
- [Claude Code Integration Guide](https://docs.anthropic.com/claude-code)