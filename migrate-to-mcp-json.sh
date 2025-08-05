#!/bin/bash

# Migration script to transition from install-ai-tools.sh MCP approach to .mcp.json
# This script helps migrate existing MCP configurations to the new .mcp.json format

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    local level="$1"
    shift
    local message="$*"
    case "$level" in
        "INFO") echo -e "${BLUE}ℹ️ [INFO]${NC} $message" ;;
        "SUCCESS") echo -e "${GREEN}✅ [SUCCESS]${NC} $message" ;;
        "WARN") echo -e "${YELLOW}⚠️ [WARN]${NC} $message" ;;
        "ERROR") echo -e "${RED}❌ [ERROR]${NC} $message" ;;
    esac
}

# Function to check if CLI supports MCP
check_cli_mcp_support() {
    local cli="$1"
    if command -v "$cli" &>/dev/null; then
        if $cli mcp --help &>/dev/null; then
            return 0
        else
            log "WARN" "$cli CLI does not support MCP protocol"
            return 1
        fi
    else
        log "WARN" "$cli CLI not found"
        return 1
    fi
}

# Function to backup existing MCP configurations
backup_existing_configs() {
    log "INFO" "Backing up existing MCP configurations..."

    # Backup Claude MCP configs
    if [[ -f "$HOME/.claude/mcp.json" ]]; then
        cp "$HOME/.claude/mcp.json" "$HOME/.claude/mcp.json.backup.$(date +%Y%m%d_%H%M%S)"
        log "SUCCESS" "Backed up Claude MCP config"
    fi

    # Backup project MCP configs
    if [[ -f ".mcp.json" ]]; then
        cp ".mcp.json" ".mcp.json.backup.$(date +%Y%m%d_%H%M%S)"
        log "SUCCESS" "Backed up project MCP config"
    fi

    if [[ -f "~/.mcp.json" ]]; then
        cp "~/.mcp.json" "~/.mcp.json.backup.$(date +%Y%m%d_%H%M%S)"
        log "SUCCESS" "Backed up user MCP config"
    fi
}

# Function to test MCP server configurations
test_mcp_servers() {
    local cli="$1"
    local config_file="$2"

    if [[ ! -f "$config_file" ]]; then
        log "WARN" "Config file $config_file not found"
        return 1
    fi

    log "INFO" "Testing MCP servers in $config_file for $cli..."

    # Extract server names from JSON and test them
    local servers=$(jq -r '.mcpServers | keys[]' "$config_file" 2>/dev/null || echo "")

    for server in $servers; do
        log "INFO" "Testing MCP server: $server"
        if $cli mcp get "$server" &>/dev/null; then
            log "SUCCESS" "MCP server $server is working"
        else
            log "WARN" "MCP server $server failed to load"
        fi
    done
}

# Function to create environment-specific configs
create_env_configs() {
    log "INFO" "Creating environment-specific MCP configurations..."

    # Create development environment config
    cat > ".mcp.dev.json" << 'EOF'
{
  "mcpServers": {
    "sequential-thinking": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-sequential-thinking"],
      "env": {}
    },
    "memory": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-memory"],
      "env": {}
    },
    "github": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-github"],
      "env": {}
    },
    "serena": {
      "command": "uvx",
      "args": ["--from", "git+https://github.com/oraios/serena", "serena-mcp-server"],
      "env": {
        "SERENA_PROJECT_DIR": "${SERENA_PROJECT_DIR:-/workspace}"
      }
    }
  }
}
EOF
    log "SUCCESS" "Created development MCP config (.mcp.dev.json)"

    # Create production environment config
    cat > ".mcp.prod.json" << 'EOF'
{
  "mcpServers": {
    "sequential-thinking": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-sequential-thinking"],
      "env": {}
    },
    "memory": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-memory"],
      "env": {}
    },
    "everything": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-everything"],
      "env": {}
    },
    "filesystem": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-filesystem", "/home", "/workspace"],
      "env": {}
    }
  }
}
EOF
    log "SUCCESS" "Created production MCP config (.mcp.prod.json)"
}

# Function to create CLI-specific configs
create_cli_configs() {
    log "INFO" "Creating CLI-specific MCP configurations..."

    # Create Claude-specific config
    cat > ".mcp.claude.json" << 'EOF'
{
  "mcpServers": {
    "sequential-thinking": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-sequential-thinking"],
      "env": {}
    },
    "memory": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-memory"],
      "env": {}
    },
    "everything": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-everything"],
      "env": {}
    },
    "github": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-github"],
      "env": {}
    },
    "puppeteer": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-puppeteer"],
      "env": {}
    },
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp@latest"],
      "env": {}
    },
    "serena": {
      "command": "uvx",
      "args": ["--from", "git+https://github.com/oraios/serena", "serena-mcp-server"],
      "env": {
        "SERENA_PROJECT_DIR": "${SERENA_PROJECT_DIR:-/workspace}"
      }
    }
  }
}
EOF
    log "SUCCESS" "Created Claude-specific MCP config (.mcp.claude.json)"

    # Create Qwen-specific config (if Qwen supports MCP)
    cat > ".mcp.qwen.json" << 'EOF'
{
  "mcpServers": {
    "sequential-thinking": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-sequential-thinking"],
      "env": {}
    },
    "memory": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-memory"],
      "env": {}
    },
    "everything": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-everything"],
      "env": {}
    },
    "filesystem": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-filesystem", "/home", "/workspace"],
      "env": {}
    }
  }
}
EOF
    log "SUCCESS" "Created Qwen-specific MCP config (.mcp.qwen.json)"
}

# Function to create documentation
create_documentation() {
    log "INFO" "Creating MCP configuration documentation..."

    cat > "docs/mcp-migration.md" << 'EOF'
# MCP Configuration Migration Guide

This document describes the migration from the old `install-ai-tools.sh` approach to using `.mcp.json` files.

## Overview

The new `.mcp.json` approach provides:
- Better organization and maintainability
- Environment variable expansion
- Scope-based configuration (project, user, global)
- Easier testing and debugging
- Support for different CLI types (Claude, Qwen, Gemini)

## Configuration Files

### Project-level (`.mcp.json`)
Contains MCP servers specific to this project. Available to all team members.

### User-level (`~/.mcp.json`)
Contains personal MCP servers available across all projects.

### Environment-specific
- `.mcp.dev.json` - Development environment
- `.mcp.prod.json` - Production environment

### CLI-specific
- `.mcp.claude.json` - Claude-specific servers
- `.mcp.qwen.json` - Qwen-specific servers

## Usage

### Basic Usage
```bash
# Use project-level config
claude

# Use specific config file
claude --config .mcp.dev.json

# Use user-level config
claude --config ~/.mcp.json
```

### Environment Variables
The `.mcp.json` files support environment variable expansion:

```json
{
  "mcpServers": {
    "serena": {
      "command": "uvx",
      "args": ["--from", "git+https://github.com/oraios/serena", "serena-mcp-server"],
      "env": {
        "SERENA_PROJECT_DIR": "${SERENA_PROJECT_DIR:-/workspace}"
      }
    }
  }
}
```

### Testing MCP Servers
```bash
# Test all servers in a config
./migrate-to-mcp-json.sh --test-claude .mcp.json

# Test specific server
claude mcp get sequential-thinking
```

## Migration Steps

1. **Backup existing configs**: The migration script automatically backs up existing configurations
2. **Create new configs**: Use the provided `.mcp.json` templates
3. **Test configurations**: Use the test functions to verify everything works
4. **Update scripts**: Modify `install-ai-tools.sh` to use `.mcp.json` instead of manual installation

## Benefits

- **Cleaner code**: No more complex bash arrays and loops
- **Better maintainability**: JSON is easier to read and modify
- **Environment support**: Different configs for different environments
- **CLI flexibility**: Support for multiple CLI types
- **Variable expansion**: Dynamic configuration based on environment
- **Scope management**: Clear separation between project and user configs

## Troubleshooting

### Common Issues

1. **Server not found**: Check if the npm package is published and accessible
2. **Permission errors**: Ensure proper file permissions on `.mcp.json` files
3. **Environment variables**: Verify that required environment variables are set
4. **CLI compatibility**: Some MCP servers may not work with all CLI types

### Debugging

```bash
# Check MCP server status
claude mcp list

# Test specific server
claude mcp get <server-name>

# Use MCP Inspector for debugging
npx @modelcontextprotocol/inspector
```

## Future Enhancements

- [ ] Add support for more MCP servers
- [ ] Create CLI-specific installation scripts
- [ ] Add validation for `.mcp.json` schemas
- [ ] Implement automatic server discovery
- [ ] Add support for remote MCP servers
EOF

    log "SUCCESS" "Created MCP migration documentation (docs/mcp-migration.md)"
}

# Main migration function
main() {
    log "INFO" "Starting MCP configuration migration..."

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --backup)
                backup_existing_configs
                exit 0
                ;;
            --test-claude)
                if check_cli_mcp_support "claude"; then
                    test_mcp_servers "claude" "$2"
                fi
                exit 0
                ;;
            --test-qwen)
                if check_cli_mcp_support "qwen"; then
                    test_mcp_servers "qwen" "$2"
                fi
                exit 0
                ;;
            --create-env-configs)
                create_env_configs
                exit 0
                ;;
            --create-cli-configs)
                create_cli_configs
                exit 0
                ;;
            --create-docs)
                create_documentation
                exit 0
                ;;
            --help)
                echo "Usage: $0 [OPTIONS]"
                echo "Options:"
                echo "  --backup              Backup existing MCP configurations"
                echo "  --test-claude FILE    Test Claude MCP servers in config file"
                echo "  --test-qwen FILE      Test Qwen MCP servers in config file"
                echo "  --create-env-configs  Create environment-specific configs"
                echo "  --create-cli-configs  Create CLI-specific configs"
                echo "  --create-docs         Create migration documentation"
                echo "  --help                Show this help message"
                exit 0
                ;;
            *)
                log "ERROR" "Unknown option: $1"
                exit 1
                ;;
        esac
        shift
    done

    # Default: run full migration
    log "INFO" "Running full MCP migration..."

    # Backup existing configs
    backup_existing_configs

    # Create documentation
    create_documentation

    # Test current configs
    if check_cli_mcp_support "claude"; then
        test_mcp_servers "claude" ".mcp.json"
    fi

    if check_cli_mcp_support "qwen"; then
        test_mcp_servers "qwen" ".mcp.json"
    fi

    log "SUCCESS" "MCP migration completed!"
    log "INFO" "Next steps:"
    log "INFO" "1. Review the created .mcp.json files"
    log "INFO" "2. Test the configurations with your preferred CLI"
    log "INFO" "3. Update install-ai-tools.sh to use .mcp.json approach"
    log "INFO" "4. Remove old MCP installation logic from install-ai-tools.sh"
}

# Run main function
main "$@"
