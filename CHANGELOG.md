# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-11-08

### Added

#### Testing Infrastructure
- Comprehensive test framework with custom assertion library (`tests/test-framework.sh`)
- Test suites for bootstrap, configurations, and scripts (`tests/test-*.sh`)
- Test orchestrator with colorized output (`run-tests.sh`)
- Docker testing infrastructure with multiple modes (quick, full, multi-distro)
- Docker test environments (`Dockerfile.test`, `Dockerfile.test-quick`, `docker-compose.test.yml`)
- Docker testing orchestrator script (`scripts/test-in-docker.sh`)
- GitHub Actions CI/CD pipeline with parallel testing jobs
- Pre-commit git hooks for automated testing
- Docker integration testing in CI/CD pipeline

#### Scripts and Utilities
- Shared utility library with error handling (`scripts/common.sh`)
- Post-installation validation script (`scripts/validate-install.sh`)
- Environment health check diagnostic tool (`scripts/health-check.sh`)
- Git hooks installation script (`scripts/install-hooks.sh`)

#### Documentation
- Comprehensive testing guide (`docs/testing-guide.md`)
- Docker testing documentation (`docs/docker-testing.md`)
- Script reference manual (`docs/script-reference.md`)
- Troubleshooting guide (`docs/troubleshooting.md`)
- MCP migration summary moved to docs
- Enhanced README with new sections and examples

#### Development Tools
- Comprehensive Makefile with 28+ targets for task automation
- Shell completions support preparation
- Version management with VERSION file
- This CHANGELOG for tracking changes

#### Configuration
- `.dockerignore` for optimized Docker builds
- `.editorconfig` preparation for consistent formatting
- Enhanced `.gitignore` with comprehensive backup patterns

#### Features
- Dry-run mode for bootstrap script (`--dry-run` flag)
- Enhanced logging system with multiple levels (DEBUG, INFO, WARN, ERROR)
- Signal handling and cleanup registration in scripts
- Retry logic with exponential backoff for network operations
- JSON/YAML validation utilities
- Interactive confirmation prompts
- Timestamped backup creation

### Changed
- Reorganized repository structure with dedicated `setup/` and `tests/` directories
- Improved bootstrap script with better error handling and logging
- Updated test-configs.sh to match actual file structure
- Enhanced Makefile with validation and diagnostic targets
- Moved MCP-related scripts to appropriate directories

### Fixed
- Script permissions in `scripts/` directory (11 scripts made executable)
- Test framework arithmetic compatibility issues
- Configuration file test expectations to match actual structure
- Docker test image non-root user security

### Removed
- Legacy migration scripts (migrate-to-mcp-json.sh, test-mcp-json.sh)
- Empty `.specstory/` directory
- Obsolete `.gitignore` entries (meson, ccls, Nix)
- 7 backup files from yazi directory (keymap.toml-*)
- Scattered root-level scripts (moved to organized directories)

### Security
- Non-root user in Docker containers
- Signal trap handlers for cleanup
- Safe directory and file operations
- Backup file exclusion patterns

## [Unreleased]

### Planned
- Interactive setup wizard with tool selection
- Automated release process with GitHub Actions
- Performance benchmarking in CI
- Shell completion files for bash and zsh
- Uninstall script for clean removal
- Configuration profile system (work/personal/server)
- Update checker for tool versions

---

## Version History

- **1.0.0** - Initial stable release with comprehensive testing and documentation
- Earlier versions were informal development iterations

## Links

- [Repository](https://github.com/ryanwclark1/dotfiles)
- [Issue Tracker](https://github.com/ryanwclark1/dotfiles/issues)
- [Releases](https://github.com/ryanwclark1/dotfiles/releases)
