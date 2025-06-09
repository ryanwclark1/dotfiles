# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository that manages configuration files and utility scripts for a development environment. The repository uses a structured approach to organize configurations for various CLI tools and provides automated setup and update scripts.

## Architecture

### Core Components

1. **Configuration Management**: Configuration files are organized by tool in dedicated directories (atuin/, bat/, eza/, fd/, k9s/, etc.)
2. **Script Collection**: Utility scripts in `scripts/` directory provide shortcuts for common development tasks
3. **Bootstrap System**: Modern, dynamic setup via `bootstrap.sh` that automatically detects paths, validates dependencies, and installs tools using configurable methods
4. **Update Mechanism**: `update_dots.sh` synchronizes local configs back to this repository

### Bootstrap Script Features

- **Dynamic Path Detection**: Automatically detects script location instead of hardcoded paths
- **Cross-Platform Support**: Automatically detects OS (Linux/macOS) and architecture (AMD64/ARM64/ARMv7)
- **Architecture-Aware Installation**: Downloads correct binaries for detected platform
- **Dependency Validation**: Checks for required tools (git, curl, jq) before proceeding
- **Configurable Tool Installation**: Uses associative arrays to define tools and installation methods
- **Multiple Install Methods**: Supports Git repos, GitHub releases, and installation scripts
- **Intelligent File Copying**: Uses rsync when available, falls back to manual copying with platform-specific options
- **Consistent Error Handling**: Structured logging and error reporting throughout
- **Shell-Aware Configuration**: Automatically configures bash or zsh with proper tool initialization

### File Structure Pattern

- **Tool configs**: Each CLI tool has its own directory with configuration files
- **Scripts**: Executable utilities in `scripts/` that get copied to `~/.local/bin`
- **Shell integration**: Aliases, starship prompt, and shell-specific configurations
- **Themes**: Consistent theming across tools using Catppuccin color scheme

## Key Commands

### Setup and Updates
```bash
# Initial setup (installs tools and applies configs)
./bootstrap.sh

# Update dotfiles repository from current system configs
./update_dots.sh

# Fix starship prompt if not working in bash
./scripts/fix-starship
```

### Extending the Bootstrap Script

To add new tools to the bootstrap script:

1. **Add to TOOLS array**: Define the tool and its installation method
```bash
["newtool"]="install_from_github"
```

2. **Add to TOOL_CONFIG array**: Define tool-specific configuration
```bash
["newtool_repo"]="owner/repository"
["newtool_debian_pattern"]="newtool_{version}_amd64.deb"
```

3. **Add platform-specific patterns** (for GitHub releases):
```bash
["newtool_linux_amd64_pattern"]="newtool-{version}-x86_64-unknown-linux-gnu.tar.gz"
["newtool_linux_arm64_pattern"]="newtool-{version}-aarch64-unknown-linux-gnu.tar.gz"
["newtool_darwin_amd64_pattern"]="newtool-{version}-x86_64-apple-darwin.tar.gz"
["newtool_darwin_arm64_pattern"]="newtool-{version}-aarch64-apple-darwin.tar.gz"
```

4. **Supported installation methods**:
   - `install_from_git`: Clones repo and runs install script
   - `install_from_github`: Downloads releases from GitHub (supports Debian packages and platform-specific tarballs)
   - `install_from_script`: Downloads and runs installation scripts

### Supported Platforms

The bootstrap script supports the following platforms:

| OS | Architecture | Status |
|---|---|---|
| Linux | AMD64 (x86_64) | ✅ Full support |
| Linux | ARM64 (aarch64) | ✅ Full support |
| Linux | ARMv7 | ✅ Full support |
| macOS | AMD64 (Intel) | ✅ Full support |
| macOS | ARM64 (Apple Silicon) | ✅ Full support |

Platform detection is automatic and tools are downloaded for the correct architecture.

### Common Issues

#### Starship Prompt Not Working
The bootstrap script automatically handles starship initialization issues, but if the prompt still isn't working:
- Run `./scripts/fix-starship` to manually clear conflicting environment variables
- This typically happens when starship was previously initialized for zsh but current session is bash
- The bootstrap script now automatically clears `STARSHIP_SHELL` and `STARSHIP_SESSION_KEY` variables and reinitializes for the current shell

### Development Tools Available
- **fzf**: Fuzzy finder with custom git integration (`fzf-git` script)
- **ripgrep**: Fast text search (with custom `rgf` script for file search)
- **bat**: Syntax-highlighted file viewer (aliased to `cat`)
- **eza**: Modern `ls` replacement with git integration
- **fd**: Fast file finder
- **atuin**: Shell history with sync capabilities
- **starship**: Cross-shell prompt
- **zoxide**: Smart directory jumping
- **yazi**: Terminal file manager
- **tmux**: Terminal multiplexer with custom configuration

### Utility Scripts
All scripts in `scripts/` are available as commands after running `bootstrap.sh`:
- `bluetoothz`: Bluetooth device management
- `dkr`: Docker container operations
- `fv`: File viewer with fzf integration
- `fzf-git`: Git operations with fzf
- `fzmv`: File moving with fzf
- `fztop`: Process management with fzf
- `gitup`: Git repository updates
- `igr`: Interactive grep with fzf
- `rgf`: Ripgrep file search
- `sshget`: SSH key management
- `sysz`: System management with fzf
- `wifiz`: WiFi network management

## Configuration Locations

When `bootstrap.sh` runs:
- Configs are copied to `~/.config/`
- Scripts are made executable and copied to `~/.local/bin/`
- Shell configurations are updated (`.bashrc` or `.zshrc`)
- Tools are installed if not present

When `update_dots.sh` runs:
- Current configs are copied back from `~/.config/` to this repository
- Maintains write permissions for future updates

## Theming

The repository uses Catppuccin theme variants consistently across:
- Starship prompt (Catppuccin Frappé colors)
- Tmux (via forceline theme)
- Yazi file manager
- Bat syntax highlighting
- K9s Kubernetes interface

## Tool Integration

- **Shell aliases** enhance default tools (e.g., `ls` → `eza`, `cat` → `bat`)
- **fzf integration** throughout scripts for interactive selection
- **Git integration** in prompt, file listings, and utility scripts
- **Tmux integration** with custom modules for system monitoring