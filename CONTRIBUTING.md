# Contributing to Dotfiles

Thank you for your interest in contributing to this dotfiles repository! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Testing Requirements](#testing-requirements)
- [Commit Guidelines](#commit-guidelines)
- [Pull Request Process](#pull-request-process)
- [Adding New Tools](#adding-new-tools)
- [Documentation](#documentation)

## Code of Conduct

This project follows a simple code of conduct: be respectful, constructive, and helpful. We welcome contributions from everyone.

## Getting Started

### Prerequisites

- Git
- Bash 4.0+ or Zsh
- Docker (for running Docker tests)
- Basic understanding of shell scripting

### Fork and Clone

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/dotfiles.git
   cd dotfiles
   ```
3. Add upstream remote:
   ```bash
   git remote add upstream https://github.com/ryanwclark1/dotfiles.git
   ```

### Set Up Development Environment

```bash
# Install git hooks
make install-hooks

# Or manually
./scripts/install-hooks.sh

# Run tests to ensure everything works
make test
```

## Development Workflow

### 1. Create a Feature Branch

```bash
git checkout -b feature/your-feature-name
```

### 2. Make Your Changes

- Follow the coding standards (see below)
- Add tests for new functionality
- Update documentation as needed

### 3. Test Your Changes

```bash
# Run all tests
make test

# Run specific test suite
./run-tests.sh bootstrap

# Test in Docker (recommended)
make docker-test

# Run full CI checks locally
make ci
```

### 4. Commit Your Changes

Follow the commit guidelines (see below).

### 5. Push and Create Pull Request

```bash
git push origin feature/your-feature-name
```

Then create a pull request on GitHub.

## Coding Standards

### Shell Scripts

1. **Strict Mode**: All scripts should use:
   ```bash
   #!/usr/bin/env bash
   set -euo pipefail
   ```

2. **Naming Conventions**:
   - Use lowercase with underscores for functions: `my_function()`
   - Use UPPERCASE for constants: `INSTALL_DIR="/usr/local"`
   - Use lowercase for local variables: `local my_var="value"`

3. **Error Handling**:
   - Use signal handlers for cleanup
   - Provide meaningful error messages
   - Use `log()` function from `scripts/common.sh`
   ```bash
   source "$(dirname "$0")/common.sh"
   setup_signal_handlers
   log "INFO" "Starting operation..."
   ```

4. **Documentation**:
   - Add header comments explaining purpose
   - Document function parameters and return values
   - Include usage examples

5. **ShellCheck**: All scripts must pass ShellCheck:
   ```bash
   make lint
   ```

### Example Script Structure

```bash
#!/usr/bin/env bash
#
# script-name.sh - Brief description of what this script does
#
# Usage:
#   ./script-name.sh [OPTIONS]
#
# Options:
#   -h, --help     Show this help message
#   -v, --verbose  Enable verbose output

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Constants
readonly SCRIPT_NAME="$(basename "$0")"
readonly VERSION="1.0.0"

# Functions
usage() {
    cat <<EOF
Usage: $SCRIPT_NAME [OPTIONS]

Brief description.

Options:
    -h, --help     Show this help message
    -v, --verbose  Enable verbose output
EOF
}

main() {
    setup_signal_handlers

    # Your code here
    log "INFO" "Starting $SCRIPT_NAME"

    # Do work...

    log "INFO" "Completed successfully"
}

# Run main function
main "$@"
```

## Testing Requirements

### Writing Tests

1. **Location**: Place tests in `tests/test-*.sh`
2. **Naming**: Use descriptive test names
3. **Framework**: Use the custom test framework

Example test:

```bash
#!/usr/bin/env bash

source "$(dirname "$0")/test-framework.sh"

init_tests "My Feature Tests"

test_start "feature does something correctly"
if [[ $(my_function) == "expected" ]]; then
    test_pass
else
    test_fail "Expected 'expected', got '$(my_function)'"
fi

test_start "feature handles errors gracefully"
if my_function --invalid 2>/dev/null; then
    test_fail "Should have failed with invalid option"
else
    test_pass
fi

test_summary
```

### Running Tests

```bash
# All tests
make test

# Specific suite
./run-tests.sh bootstrap

# Docker tests (recommended before PR)
make docker-test
make docker-test-full
make docker-test-multi

# Complete CI check
make ci
```

### Test Requirements

- All new features must include tests
- Tests must pass on Ubuntu, Debian, and Alpine (use `make docker-test-multi`)
- Maintain or improve test coverage
- Tests should be fast (<1 second per test when possible)

## Commit Guidelines

### Commit Message Format

```
<type>: <subject>

<body>

<footer>
```

### Types

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Code style changes (formatting, etc.)
- **refactor**: Code refactoring
- **test**: Adding or updating tests
- **chore**: Maintenance tasks

### Examples

```
feat: Add Docker testing infrastructure

- Add Dockerfile.test for full installation testing
- Add Dockerfile.test-quick for fast testing
- Add docker-compose.test.yml for multi-distro testing
- Add scripts/test-in-docker.sh orchestrator
- Update Makefile with Docker targets

Closes #123
```

```
fix: Correct shell completion path in bashrc

The shell completion directory was incorrectly set to ~/.local/completions
instead of ~/.local/share/bash-completion/completions.

Fixes #456
```

### Commit Best Practices

- Use present tense ("Add feature" not "Added feature")
- Use imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit subject line to 72 characters
- Separate subject from body with blank line
- Wrap body at 72 characters
- Reference issues and pull requests

## Pull Request Process

### Before Submitting

1. ✅ Tests pass locally (`make test`)
2. ✅ Docker tests pass (`make docker-test`)
3. ✅ ShellCheck passes (`make lint`)
4. ✅ Documentation updated
5. ✅ CHANGELOG.md updated
6. ✅ Commits are clean and well-formatted

### PR Description Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests pass
- [ ] Docker tests pass
- [ ] Tested on multiple platforms

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] No new warnings
- [ ] Tests added/updated
- [ ] CHANGELOG.md updated
```

### Review Process

1. Automated CI checks must pass
2. At least one maintainer review required
3. All review comments must be addressed
4. Changes should be squashed if requested

## Adding New Tools

When adding a new tool to the bootstrap script:

### 1. Update Bootstrap Configuration

Add to `bootstrap.sh`:

```bash
# In TOOLS array
["newtool"]="install_from_github"

# In TOOL_CONFIG array
["newtool_repo"]="owner/repository"
["newtool_linux_amd64_pattern"]="newtool-{version}-x86_64-linux.tar.gz"
["newtool_linux_arm64_pattern"]="newtool-{version}-aarch64-linux.tar.gz"
["newtool_darwin_amd64_pattern"]="newtool-{version}-x86_64-darwin.tar.gz"
["newtool_darwin_arm64_pattern"]="newtool-{version}-aarch64-darwin.tar.gz"
```

### 2. Add Configuration Files

```bash
# Create config directory
mkdir -p newtool/

# Add configuration
cat > newtool/config.toml <<EOF
# Tool configuration
EOF
```

### 3. Add Tests

```bash
# In tests/test-configs.sh
test_start "newtool configuration exists"
if assert_file_exists "$REPO_ROOT/newtool/config.toml"; then
    test_pass
else
    test_fail
fi
```

### 4. Update Documentation

- Add tool to README.md list
- Add configuration notes to CLAUDE.md
- Update CHANGELOG.md

## Documentation

### Required Documentation

- **README.md**: User-facing documentation
- **CLAUDE.md**: AI assistant guidance and architecture
- **docs/**: Detailed guides and references
- **Code comments**: Inline documentation for complex logic

### Documentation Style

- Use clear, concise language
- Include examples
- Keep formatting consistent
- Use code blocks with syntax highlighting
- Add table of contents for long documents

### Building Documentation

```bash
# Check for broken links
make check-docs  # (coming soon)

# Preview documentation
make docs-preview  # (coming soon)
```

## Questions or Problems?

- **Documentation**: Check `docs/` directory
- **Troubleshooting**: See `docs/guides/troubleshooting.md`
- **Issues**: Open an issue on GitHub
- **Discussions**: Use GitHub Discussions

## Attribution

When contributing, you agree that your contributions will be licensed under the same license as the project (see LICENSE file).

---

Thank you for contributing! 🎉
