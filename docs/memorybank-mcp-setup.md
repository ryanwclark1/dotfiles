# MemoryBank MCP Server Setup Guide

## Overview

MemoryBank is a powerful MCP server that provides persistent memory capabilities for Claude, allowing it to store, retrieve, and manage information across sessions. It acts as Claude's long-term memory system with structured data storage, versioning, and categorization.

## Features

- **Persistent Memory**: Store information that persists across Claude sessions
- **Categorized Storage**: Organize memories into predefined categories
- **Template System**: Use structured templates for consistent data storage
- **Version Control**: Track changes to memories with version history
- **Search & Filter**: Quickly find stored information
- **Data Compression**: Efficient storage with optional compression
- **Export/Import**: Backup and restore memory data

## Installation

MemoryBank is automatically installed when you run:

```bash
./install-claude-mcp.sh
```

This creates:
- Data directory: `~/.memorybank/memories/`
- Templates directory: `~/.memorybank/templates/`
- Configuration file: `~/.memorybank/config.json`

## Configuration

### Default Configuration

```json
{
  "dataPath": "~/.memorybank/memories",
  "templatesPath": "~/.memorybank/templates",
  "settings": {
    "maxMemorySize": 10485760,    // 10MB per memory
    "autoSave": true,
    "saveInterval": 300000,        // 5 minutes
    "encryption": false,
    "compression": true,
    "versioning": {
      "enabled": true,
      "maxVersions": 10
    },
    "categories": [
      "personal",
      "work", 
      "projects",
      "learning",
      "code-snippets",
      "documentation",
      "conversations",
      "ideas"
    ]
  }
}
```

### Customizing Categories

Add or modify categories in the config:

```json
"categories": [
  "personal",
  "work",
  "projects",
  "learning",
  "code-snippets",
  "documentation",
  "conversations",
  "ideas",
  "meetings",          // Add custom categories
  "research",
  "bookmarks"
]
```

## Usage with Claude

### Storing Memories

Ask Claude to remember information:

- "Remember that the API key for project X is stored in .env.local"
- "Store this code snippet for database connection"
- "Save these meeting notes from today"
- "Remember my preferences for code formatting"

### Retrieving Memories

Ask Claude to recall information:

- "What do you remember about project X?"
- "Show me all code snippets related to authentication"
- "What were the key points from last week's meeting?"
- "List all my saved bookmarks"

### Managing Memories

- "Update the memory about deployment process"
- "Delete old memories about the legacy system"
- "Show me all memories from last month"
- "Export my learning notes"

## Memory Templates

MemoryBank includes predefined templates for structured data:

### Project Template
```json
{
  "title": "New E-commerce Platform",
  "description": "Building a modern e-commerce solution",
  "status": "active",
  "startDate": "2024-01-15",
  "technologies": ["React", "Node.js", "PostgreSQL"],
  "goals": ["Launch MVP by Q2", "Support 10k users"],
  "notes": "Using microservices architecture"
}
```

### Code Snippet Template
```json
{
  "title": "Database Connection Helper",
  "language": "javascript",
  "description": "Reusable database connection with pooling",
  "code": "const pool = new Pool({...});",
  "tags": ["database", "postgresql", "connection"],
  "usage": "Import and use getConnection() method",
  "source": "project-x/lib/db.js"
}
```

### Learning Note Template
```json
{
  "topic": "Docker Networking",
  "summary": "Understanding Docker network modes",
  "keyPoints": [
    "Bridge network is default",
    "Host network shares host networking",
    "Custom networks enable container communication"
  ],
  "resources": ["docs.docker.com/network/"],
  "questions": ["How does overlay network work?"],
  "date": "2024-01-20"
}
```

## Creating Custom Templates

Add templates to `~/.memorybank/templates/`:

```json
// meeting-notes.json
{
  "name": "Meeting Notes Template",
  "fields": {
    "title": "",
    "date": "",
    "attendees": [],
    "agenda": [],
    "decisions": [],
    "actionItems": [],
    "followUp": ""
  }
}
```

## Advanced Usage

### Search and Filter

- "Find all memories tagged with 'api'"
- "Show memories from category 'projects'"
- "Search for memories containing 'deployment'"
- "List memories created this week"

### Bulk Operations

- "Export all code snippets to a file"
- "Delete all memories older than 6 months"
- "Backup entire memory bank"
- "Import memories from backup"

### Memory Relationships

- "Link this memory to project X"
- "Show all memories related to authentication"
- "Create a memory collection for onboarding"

## Best Practices

1. **Use Categories**: Always categorize memories for better organization
2. **Add Tags**: Tag memories with relevant keywords
3. **Regular Cleanup**: Periodically review and clean old memories
4. **Use Templates**: Leverage templates for consistent structure
5. **Descriptive Titles**: Use clear, searchable titles
6. **Version Important Data**: Enable versioning for critical information

## Data Management

### Backup

Backup your memory bank:

```bash
tar -czf memorybank-backup-$(date +%Y%m%d).tar.gz ~/.memorybank
```

### Restore

Restore from backup:

```bash
tar -xzf memorybank-backup-20240120.tar.gz -C ~/
```

### Export Specific Categories

```bash
# Export all code snippets
find ~/.memorybank/memories -name "*code-snippets*" -type f > code-snippets-export.txt
```

## Security Considerations

1. **Sensitive Data**: Avoid storing passwords or secrets
2. **Encryption**: Enable encryption for sensitive memories
3. **Access Control**: MemoryBank uses file system permissions
4. **Regular Backups**: Backup important memories regularly

## Troubleshooting

### Memory Not Saving

1. Check disk space
2. Verify write permissions on `~/.memorybank`
3. Check config for autoSave setting
4. Look for errors in Claude's output

### Search Not Working

1. Verify memory exists in correct category
2. Check search syntax
3. Try broader search terms
4. Rebuild search index (restart Claude)

### Template Issues

1. Validate JSON syntax in templates
2. Ensure template file permissions
3. Check template path in config
4. Use default templates as reference

## Integration with DevContainers

MemoryBank data persists across devcontainer sessions:

```json
"mounts": [
  "source=${localEnv:HOME}/.memorybank,target=/home/vscode/.memorybank,type=bind"
]
```

## Performance Tips

1. **Compression**: Enable for large text memories
2. **Cleanup**: Remove old versions periodically
3. **Categories**: Use specific categories to limit search scope
4. **Indexing**: Restart Claude if search becomes slow

## Common Use Cases

### Development Workflow
- Store project setup instructions
- Remember debugging solutions
- Save useful code patterns
- Track architecture decisions

### Learning & Research
- Save learning resources
- Track progress on topics
- Store question/answer pairs
- Build knowledge base

### Project Management
- Meeting notes and decisions
- Team member preferences
- Project timelines
- Important communications

### Personal Productivity
- Daily task lists
- Important reminders
- Goal tracking
- Idea collection

## Commands Reference

Common MemoryBank commands for Claude:

```
# Store
"remember this as <category>: <content>"
"save this code snippet"
"store these notes"

# Retrieve  
"what do you remember about <topic>?"
"show all <category> memories"
"find memories with <keyword>"

# Manage
"update memory about <topic>"
"delete memory <id>"
"list recent memories"

# Export/Import
"export all memories"
"backup memory bank"
"import memories from <file>"
```

## Additional Resources

- [MemoryBank GitHub Repository](https://github.com/alioshr/memory-bank-mcp)
- [MCP Protocol Documentation](https://modelcontextprotocol.org)
- [Claude Code Memory Features](https://docs.anthropic.com/claude-code/memory)