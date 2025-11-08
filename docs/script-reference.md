# Script Reference

Complete reference for all utility scripts in the dotfiles repository.

## Core Scripts

### bootstrap.sh
Main installation script with dry-run and logging capabilities.

**Usage:**
```bash
./bootstrap.sh [OPTIONS]

OPTIONS:
  -h, --help          Show help
  -d, --dry-run       Preview without executing
  -v, --verbose       Verbose output
  --log-file FILE     Custom log file

ENVIRONMENT:
  DRY_RUN=true        Enable dry-run mode
  VERBOSE=true        Enable verbose logging
  LOG_LEVEL=DEBUG     Set log level
```

**Features:**
- Cross-platform support (Linux, macOS)
- Architecture detection (AMD64, ARM64, ARMv7)
- Tool installation with version pinning
- Configuration file management
- Shell integration (bash, zsh)

### install-ai-tools.sh
Install AI CLIs and MCP servers.

**Usage:**
```bash
./install-ai-tools.sh [OPTIONS]

OPTIONS:
  --non-interactive   No prompts
  --check            Check system only
  --claude-only      Install Claude only
  --gemini-only      Install Gemini only
  --qwen-only        Install Qwen only
```

### update_dots.sh
Sync local configurations back to repository.

**Usage:**
```bash
./update_dots.sh
```

**Features:**
- Excludes backup files automatically
- Preserves write permissions
- Uses rsync when available

## Diagnostic Scripts

### scripts/validate-install.sh
Validate dotfiles installation.

**Usage:**
```bash
./scripts/validate-install.sh
make validate-install
```

**Checks:**
- Directory structure
- Installed tools and versions
- Configuration files
- PATH setup
- Shell integration
- Development tools

**Exit Codes:**
- 0: All checks passed
- 1: Some checks failed

### scripts/health-check.sh
Comprehensive environment health check.

**Usage:**
```bash
./scripts/health-check.sh
make health-check
```

**Checks:**
- Disk space
- Shell configuration
- Environment conflicts
- Misconfigurations
- Tool versions
- Performance
- Git status
- Log files

**Exit Codes:**
- 0: Healthy or warnings only
- 1: Critical issues found

### scripts/common.sh
Shared utility functions library.

**Usage:**
```bash
source scripts/common.sh

# Then use functions:
require_tools git curl jq
retry_with_backoff 5 2 60 curl -fsSL https://example.com
safe_mkdir /path/to/dir 755
```

**Functions:**
- `setup_signal_handlers()` - Handle SIGINT, SIGTERM
- `require_tools()` - Validate dependencies
- `retry_with_backoff()` - Retry with exponential backoff
- `download_file()` - Download with retry
- `validate_json()` - Validate JSON files
- `validate_yaml()` - Validate YAML files
- `safe_mkdir()` - Create directory safely
- `safe_copy()` - Copy with backup
- `check_disk_space()` - Verify space available
- `confirm()` - Interactive confirmation
- `create_backup()` - Timestamped backups

## Utility Scripts

### scripts/cleanup_bashrc.sh
Remove duplicate dotfiles entries from .bashrc.

**Usage:**
```bash
./scripts/cleanup_bashrc.sh
```

### scripts/cleanup-failing-mcps.sh
Remove MCP servers that fail to start.

**Usage:**
```bash
./scripts/cleanup-failing-mcps.sh
```

### scripts/install-hooks.sh
Install git hooks for development.

**Usage:**
```bash
./scripts/install-hooks.sh
make install-hooks
```

**Installs:**
- Pre-commit hook (runs tests)

### scripts/fix-starship
Fix starship prompt initialization issues.

**Usage:**
```bash
./scripts/fix-starship
```

**Fixes:**
- Clears conflicting environment variables
- Resolves bash/zsh conflicts

## Setup Scripts

### setup/setup-serena.sh
Enhanced Serena (coding agent) setup.

**Usage:**
```bash
./setup/setup-serena.sh
```

**Features:**
- Web dashboard setup
- Language server configuration
- Project initialization helpers

### setup/setup-context7.sh
Context7 (code documentation) setup.

**Usage:**
```bash
./setup/setup-context7.sh
```

**Features:**
- UV workspace support
- Advanced indexing
- Project management

### setup/setup-genai-toolbox.sh
GenAI Toolbox (database tools) setup.

**Usage:**
```bash
./setup/setup-genai-toolbox.sh
```

## Test Scripts

### run-tests.sh
Main test runner.

**Usage:**
```bash
./run-tests.sh [OPTIONS] [SUITE...]

OPTIONS:
  -h, --help     Show help
  -v, --verbose  Verbose output
  -q, --quiet    Minimal output
  -l, --list     List test suites

SUITES:
  bootstrap      Bootstrap tests
  configs        Configuration tests
  scripts        Script tests
  mcp            MCP server tests
  all            All tests (default)
```

### tests/test-framework.sh
Testing framework library.

**Functions:**
- `init_tests()` - Initialize test suite
- `test_start()` - Begin a test
- `test_pass()` - Mark test as passed
- `test_fail()` - Mark test as failed
- `assert_equals()` - Equality assertion
- `assert_contains()` - Substring assertion
- `assert_file_exists()` - File existence check
- `skip_test()` - Skip a test

## FZF Integration Scripts

### scripts/fzf-git.sh
Git operations with fuzzy finding.

**Functions:**
- Git branch switching
- Git log browsing
- Git stash management
- Git diff viewing

### scripts/fv.sh
File viewer with fzf integration.

**Usage:**
```bash
fv [directory]
```

### scripts/fzmv.sh
Interactive file moving with fzf.

**Usage:**
```bash
fzmv
```

### scripts/fztop.sh
Process management with fzf.

**Usage:**
```bash
fztop
```

## System Management Scripts

### scripts/sysz.sh
System management with fzf integration.

**Features:**
- Systemd service management
- Resource monitoring
- Log viewing

### scripts/wifiz.sh
WiFi network management.

**Usage:**
```bash
wifiz
```

### scripts/bluetoothz.sh
Bluetooth device management.

**Usage:**
```bash
bluetoothz
```

## Git Scripts

### scripts/gitup.sh
Update multiple git repositories.

**Usage:**
```bash
gitup [directory]
```

## Docker Scripts

### scripts/dkr.sh
Docker container operations.

**Usage:**
```bash
dkr
```

**Features:**
- Container management
- Image operations
- Interactive selection

## Search Scripts

### scripts/igr.sh
Interactive grep with fzf.

**Usage:**
```bash
igr [pattern] [directory]
```

### scripts/rgf.sh
Ripgrep file search.

**Usage:**
```bash
rgf [pattern]
```

## Best Practices

### Error Handling

Always use strict mode:
```bash
set -euo pipefail
```

### Signal Handling

Setup cleanup handlers:
```bash
source scripts/common.sh
setup_signal_handlers
register_cleanup "rm -f /tmp/tempfile"
```

### Dependency Checking

Validate required tools:
```bash
source scripts/common.sh
require_tools git curl jq || exit 1
```

### Network Operations

Use retry logic:
```bash
source scripts/common.sh
retry_with_backoff 5 2 60 curl -fsSL https://example.com/file
```

### File Operations

Use safe operations:
```bash
source scripts/common.sh
safe_mkdir "$HOME/.config/myapp"
safe_copy source.conf "$HOME/.config/myapp/config" true
```

## Exit Codes

Standard exit codes used across all scripts:

- `0` - Success
- `1` - General error
- `2` - Misuse of shell command
- `130` - Script terminated by Ctrl+C
- `143` - Script terminated by SIGTERM

## Environment Variables

Common environment variables:

- `DRY_RUN` - Enable dry-run mode (true/false)
- `VERBOSE` - Enable verbose output (true/false)
- `LOG_LEVEL` - Set log level (DEBUG, INFO, WARN, ERROR)
- `LOG_FILE` - Log file path
- `FORCE` - Skip confirmations (true/false)

## Logging Levels

- `DEBUG` - Detailed debugging information
- `INFO` - General informational messages
- `WARN` - Warning messages (non-critical)
- `ERROR` - Error messages (critical)
- `SUCCESS` - Success messages

## Common Patterns

### Script Template

```bash
#!/usr/bin/env bash
set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common utilities
source "$SCRIPT_DIR/common.sh"

# Setup signal handlers
setup_signal_handlers

# Main logic
main() {
    require_tools git curl jq

    # Your code here
}

main "$@"
```

### With Dry-run Support

```bash
#!/usr/bin/env bash
set -euo pipefail

DRY_RUN="${DRY_RUN:-false}"

dry_run() {
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "DRY RUN: $*"
        return 0
    fi
    return 1
}

# Usage
if ! dry_run "mkdir -p /path/to/dir"; then
    mkdir -p /path/to/dir
fi
```

## Troubleshooting

### Script fails with "command not found"

Ensure scripts are executable:
```bash
chmod +x script.sh
```

### Import errors with common.sh

Use absolute path:
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
```

### Tests fail in CI but pass locally

Check for:
- Hardcoded paths
- Missing dependencies
- Platform-specific commands
- Environment variables

## References

- [Testing Guide](testing-guide.md)
- [Troubleshooting Guide](troubleshooting.md)
- [Bootstrap Documentation](../CLAUDE.md)
