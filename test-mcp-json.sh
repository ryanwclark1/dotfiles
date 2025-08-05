#!/bin/bash

# Test script for .mcp.json approach
# This script validates the new MCP configuration approach

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

# Function to test MCP JSON validation
test_mcp_json_validation() {
    log "INFO" "Testing MCP JSON validation..."

    if command -v jq &>/dev/null; then
        if jq empty .mcp.json 2>/dev/null; then
            log "SUCCESS" ".mcp.json is valid JSON"
        else
            log "ERROR" ".mcp.json contains invalid JSON"
            return 1
        fi

        # Check for required fields
        local required_fields=("mcpServers")
        for field in "${required_fields[@]}"; do
            if jq -e ".$field" .mcp.json &>/dev/null; then
                log "SUCCESS" "Required field '$field' found in .mcp.json"
            else
                log "ERROR" "Required field '$field' missing from .mcp.json"
                return 1
            fi
        done
    else
        log "WARN" "jq not found, skipping JSON validation"
    fi
}

# Function to test CLI MCP support
test_cli_mcp_support() {
    local cli="$1"
    log "INFO" "Testing $cli MCP support..."

    if command -v "$cli" &>/dev/null; then
        if $cli mcp --help &>/dev/null; then
            log "SUCCESS" "$cli supports MCP protocol"
            return 0
        else
            log "WARN" "$cli does not support MCP protocol"
            return 1
        fi
    else
        log "WARN" "$cli CLI not found"
        return 1
    fi
}

# Function to test MCP server installation
test_mcp_server_installation() {
    local cli="$1"
    local server="$2"

    log "INFO" "Testing MCP server installation: $server"

    # Test if server can be added
    if $cli mcp add --scope user "$server" -- npx "@modelcontextprotocol/server-$server" &>/dev/null; then
        log "SUCCESS" "MCP server $server installed successfully"

        # Test if server is listed
        if $cli mcp list 2>/dev/null | grep -q "^$server\b"; then
            log "SUCCESS" "MCP server $server is listed"
        else
            log "WARN" "MCP server $server not found in list"
        fi

        # Clean up - remove the test server
        $cli mcp remove "$server" &>/dev/null || true
    else
        log "WARN" "Failed to install MCP server $server"
    fi
}

# Function to compare old vs new approach
compare_approaches() {
    log "INFO" "Comparing old vs new MCP approach..."

    echo "=== OLD APPROACH (install-ai-tools.sh) ==="
    echo "✅ Pros:"
    echo "  - Centralized installation"
    echo "  - Automatic dependency management"
    echo "  - Cross-platform compatibility"
    echo "❌ Cons:"
    echo "  - Complex bash arrays and loops"
    echo "  - Hard to maintain and modify"
    echo "  - No environment variable support"
    echo "  - Difficult to test individual servers"
    echo "  - No scope management"

    echo ""
    echo "=== NEW APPROACH (.mcp.json) ==="
    echo "✅ Pros:"
    echo "  - Clean JSON configuration"
    echo "  - Environment variable expansion"
    echo "  - Scope-based configuration (project, user, global)"
    echo "  - Easy to test and debug"
    echo "  - CLI-specific configurations"
    echo "  - Better maintainability"
    echo "  - Support for different environments"
    echo "❌ Cons:"
    echo "  - Requires manual server installation"
    echo "  - Less automated than bash script"
    echo "  - Need to manage dependencies separately"
}

# Function to test environment variable expansion
test_env_expansion() {
    log "INFO" "Testing environment variable expansion..."

    # Set test environment variable
    export TEST_SERENA_DIR="/test/workspace"

    # Create test config with environment variable
    cat > ".mcp.test.json" << 'EOF'
{
  "mcpServers": {
    "serena": {
      "command": "uvx",
      "args": ["--from", "git+https://github.com/oraios/serena", "serena-mcp-server"],
      "env": {
        "SERENA_PROJECT_DIR": "${TEST_SERENA_DIR:-/workspace}"
      }
    }
  }
}
EOF

    # Test if environment variable is expanded
    if grep -q "\${TEST_SERENA_DIR}" .mcp.test.json; then
        log "SUCCESS" "Environment variable expansion syntax is correct"
    else
        log "WARN" "Environment variable expansion syntax may be incorrect"
    fi

    # Clean up
    rm -f .mcp.test.json
}

# Function to create usage examples
create_usage_examples() {
    log "INFO" "Creating usage examples..."

    cat > "docs/mcp-usage-examples.md" << 'EOF'
# MCP Usage Examples

This document provides examples of how to use the new `.mcp.json` approach.

## Basic Usage

### Using Project-level Config
```bash
# Start Claude with project-level MCP config
claude

# Start Qwen with project-level MCP config
qwen
```

### Using Specific Config Files
```bash
# Use development config
claude --config .mcp.dev.json

# Use production config
claude --config .mcp.prod.json

# Use CLI-specific config
claude --config .mcp.claude.json
```

## Environment-specific Configurations

### Development Environment (.mcp.dev.json)
```json
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
```

### Production Environment (.mcp.prod.json)
```json
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
```

## CLI-specific Configurations

### Claude-specific (.mcp.claude.json)
```json
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
```

### Qwen-specific (.mcp.qwen.json)
```json
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
```

## Environment Variable Examples

### Using Environment Variables
```bash
# Set environment variable
export SERENA_PROJECT_DIR="/my/project"

# Start Claude with environment variable
claude
```

### Default Values
```json
{
  "mcpServers": {
    "serena": {
      "command": "uvx",
      "args": ["--from", "git+https://github.com/oraios/serena", "serena-mcp-server"],
      "env": {
        "SERENA_PROJECT_DIR": "${SERENA_PROJECT_DIR:-/workspace}",
        "API_KEY": "${API_KEY:-default_key}"
      }
    }
  }
}
```

## Testing and Debugging

### Test MCP Servers
```bash
# Test all servers in a config
./migrate-to-mcp-json.sh --test-claude .mcp.json

# Test specific server
claude mcp get sequential-thinking

# List all servers
claude mcp list
```

### Debug with MCP Inspector
```bash
# Install MCP Inspector
npm install -g @modelcontextprotocol/inspector

# Start inspector
npx @modelcontextprotocol/inspector
```

## Migration from Old Approach

### Step 1: Backup Existing Configs
```bash
./migrate-to-mcp-json.sh --backup
```

### Step 2: Create New Configs
```bash
# Create all config types
./migrate-to-mcp-json.sh --create-env-configs
./migrate-to-mcp-json.sh --create-cli-configs
```

### Step 3: Test Configurations
```bash
# Test Claude configs
./migrate-to-mcp-json.sh --test-claude .mcp.json

# Test Qwen configs
./migrate-to-mcp-json.sh --test-qwen .mcp.json
```

### Step 4: Update Scripts
```bash
# Modify install-ai-tools.sh to use .mcp.json
# Remove old MCP installation logic
```

## Best Practices

1. **Use project-level configs for team-shared servers**
2. **Use user-level configs for personal tools**
3. **Use environment-specific configs for different deployment stages**
4. **Test configurations before deploying**
5. **Use environment variables for sensitive data**
6. **Keep configurations version-controlled**
7. **Document custom server configurations**
EOF

    log "SUCCESS" "Created usage examples (docs/mcp-usage-examples.md)"
}

# Main test function
main() {
    log "INFO" "Starting MCP JSON testing..."

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --validate)
                test_mcp_json_validation
                exit 0
                ;;
            --test-cli)
                test_cli_mcp_support "$2"
                exit 0
                ;;
            --test-server)
                test_mcp_server_installation "$2" "$3"
                exit 0
                ;;
            --compare)
                compare_approaches
                exit 0
                ;;
            --test-env)
                test_env_expansion
                exit 0
                ;;
            --create-examples)
                create_usage_examples
                exit 0
                ;;
            --help)
                echo "Usage: $0 [OPTIONS]"
                echo "Options:"
                echo "  --validate              Validate .mcp.json syntax"
                echo "  --test-cli CLI          Test CLI MCP support"
                echo "  --test-server CLI SERVER Test MCP server installation"
                echo "  --compare               Compare old vs new approach"
                echo "  --test-env              Test environment variable expansion"
                echo "  --create-examples       Create usage examples"
                echo "  --help                  Show this help message"
                exit 0
                ;;
            *)
                log "ERROR" "Unknown option: $1"
                exit 1
                ;;
        esac
        shift
    done

    # Default: run all tests
    log "INFO" "Running comprehensive MCP JSON tests..."

    # Test JSON validation
    test_mcp_json_validation

    # Test CLI support
    test_cli_mcp_support "claude"
    test_cli_mcp_support "qwen"

    # Test environment variable expansion
    test_env_expansion

    # Create usage examples
    create_usage_examples

    # Compare approaches
    compare_approaches

    log "SUCCESS" "All MCP JSON tests completed!"
    log "INFO" "Next steps:"
    log "INFO" "1. Review the test results"
    log "INFO" "2. Test with your preferred CLI"
    log "INFO" "3. Customize configurations as needed"
    log "INFO" "4. Update your workflow to use .mcp.json"
}

# Run main function
main "$@"
