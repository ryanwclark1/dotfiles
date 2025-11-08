# Troubleshooting Guide

Common issues and solutions for the dotfiles repository.

## Table of Contents

- [Installation Issues](#installation-issues)
- [Shell Configuration](#shell-configuration)
- [Tool-Specific Problems](#tool-specific-problems)
- [Testing Issues](#testing-issues)
- [Git and Version Control](#git-and-version-control)

---

## Installation Issues

### Bootstrap script fails with "Permission denied"

**Problem:** Cannot execute bootstrap.sh

**Solution:**
```bash
chmod +x bootstrap.sh
./bootstrap.sh
```

### Script fails with "Required tool not installed"

**Problem:** Missing dependencies (git, curl, jq)

**Solution:**
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install git curl jq

# macOS
brew install git curl jq
```

### Installation fails partway through

**Problem:** Script stopped unexpectedly

**Solution:**
1. Check the log file for details:
   ```bash
   cat ~/.dotfiles-install.log
   ```

2. Try running in dry-run mode first:
   ```bash
   ./bootstrap.sh --dry-run
   ```

3. Run with verbose logging:
   ```bash
   ./bootstrap.sh --verbose
   ```

### "No space left on device" error

**Problem:** Insufficient disk space

**Solution:**
```bash
# Check available space
df -h

# Clean up if needed
make clean

# Or manually remove old installations
rm -rf ~/.config/scripts ~/.local/bin/old-tools
```

---

## Shell Configuration

### Starship prompt not showing

**Problem:** Prompt doesn't display after installation

**Solution 1:** Run the fix script
```bash
./scripts/fix-starship
```

**Solution 2:** Manual fix
```bash
# Clear conflicting environment variables
unset STARSHIP_SHELL STARSHIP_SESSION_KEY

# Restart your shell
exec bash  # or exec zsh
```

**Solution 3:** Check if starship is in PATH
```bash
which starship
# If not found, add to PATH
export PATH="$HOME/.local/bin:$PATH"
```

### Changes not taking effect after bootstrap

**Problem:** Configuration updates don't appear

**Solution:**
```bash
# Reload shell configuration
source ~/.bashrc   # for bash
source ~/.zshrc    # for zsh

# Or restart your shell
exec bash
```

### Duplicate PATH entries

**Problem:** PATH contains repeated entries

**Solution:**
```bash
# Check your PATH
echo $PATH | tr ':' '\n'

# Clean up duplicate entries in shell config
./scripts/cleanup_bashrc.sh
```

### NVM conflicts with npm-global

**Problem:** npm packages not found when using nvm

**Solution:**
The dotfiles are nvm-aware and automatically exclude `~/.npm-global/bin` from PATH when nvm is detected. This is expected behavior to prevent conflicts.

To use globally installed npm packages with nvm:
```bash
# Install packages through nvm's npm instead
npm install -g package-name
```

---

## Tool-Specific Problems

### eza command not found

**Problem:** eza not installed or not in PATH

**Solution:**
```bash
# Check if eza is installed
command -v eza

# If not found, install via bootstrap
./bootstrap.sh

# Or install manually
make install
```

### Atuin sync not working

**Problem:** Cannot sync shell history

**Solution:**
```bash
# Register with Atuin
atuin register -u <username> -e <email>

# Login
atuin login -u <username>

# Sync
atuin sync
```

### K9s fails to start

**Problem:** K9s cannot connect to Kubernetes cluster

**Solution:**
```bash
# Verify kubectl works
kubectl cluster-info

# Check k9s config
cat ~/.config/k9s/config.yaml

# Reset k9s config if needed
rm -rf ~/.config/k9s
./bootstrap.sh
```

### Yazi doesn't show icons

**Problem:** File manager shows squares instead of icons

**Solution:**
Install a Nerd Font:
```bash
# macOS
brew tap homebrew/cask-fonts
brew install --cask font-hack-nerd-font

# Linux - download and install manually
# https://www.nerdfonts.com/font-downloads
```

Then configure your terminal to use the Nerd Font.

### FZF git integration not working

**Problem:** fzf-git commands don't work

**Solution:**
```bash
# Ensure fzf-git script is executable
chmod +x ~/.config/scripts/fzf-git.sh

# Source it in your shell
source ~/.config/scripts/fzf-git.sh

# Or restart shell
exec bash
```

---

## Testing Issues

### Tests fail with "command not found"

**Problem:** Test framework or test scripts not executable

**Solution:**
```bash
# Make test runner executable
chmod +x run-tests.sh

# Make all test scripts executable
chmod +x tests/*.sh

# Or use make
make test
```

### ShellCheck warnings in tests

**Problem:** Linting shows many warnings

**Solution:**
ShellCheck warnings in the lint step are informational and don't fail the build. To fix them:

```bash
# Run shellcheck manually
make lint

# Fix specific issues
shellcheck path/to/script.sh
```

### Tests pass locally but fail in CI

**Problem:** Different behavior in GitHub Actions

**Solution:**
1. Check for hardcoded paths:
   ```bash
   # Bad
   cp /home/myuser/file.txt dest/

   # Good
   cp "$HOME/file.txt" dest/
   ```

2. Ensure all dependencies are installed in CI (check `.github/workflows/test.yml`)

3. Test in a clean container:
   ```bash
   make ci
   ```

---

## Git and Version Control

### Pre-commit hook blocks commits

**Problem:** Cannot commit due to test failures

**Solution 1:** Fix the failing tests
```bash
# Run tests to see what's failing
./run-tests.sh

# Fix the issues, then commit
git add .
git commit -m "Fix tests"
```

**Solution 2:** Bypass hook temporarily (not recommended)
```bash
git commit --no-verify -m "Message"
```

**Solution 3:** Disable hooks
```bash
rm .git/hooks/pre-commit
```

### Backup files accidentally committed

**Problem:** .bak, .swp files in git history

**Solution:**
```bash
# Remove from git but keep locally
git rm --cached file.bak

# Update .gitignore
echo "*.bak" >> .gitignore
git add .gitignore
git commit -m "Update gitignore"

# Remove from history (advanced)
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch "*.bak"' \
  --prune-empty --tag-name-filter cat -- --all
```

### Cannot pull/push dotfiles

**Problem:** Git conflicts or authentication issues

**Solution:**
```bash
# Update from remote
git fetch origin
git pull origin main

# If conflicts
git status  # check conflicted files
# Resolve conflicts, then:
git add .
git commit -m "Resolve conflicts"

# For authentication
git config --global credential.helper store
```

---

## Performance Issues

### Bootstrap takes too long

**Problem:** Installation is very slow

**Solution:**
```bash
# Use dry-run to see what takes time
./bootstrap.sh --dry-run

# Skip tool installation if already installed
# (The script checks for existing installations)

# Or install specific tools manually
make install
```

### Shell startup is slow

**Problem:** New shell sessions take seconds to start

**Solution:**
```bash
# Profile your shell startup
bash -x ~/.bashrc 2>&1 | less
# or
zsh -x ~/.zshrc 2>&1 | less

# Common culprits:
# - Multiple tool initializations
# - Slow network calls
# - Complex prompt configurations

# Disable tools you don't use by commenting out in shell config
```

---

## Configuration Issues

### JSON configuration is invalid

**Problem:** .mcp.json or other JSON files have syntax errors

**Solution:**
```bash
# Validate JSON
jq empty .mcp.json

# Get specific error
jq . .mcp.json

# Use validation make target
make validate
```

### TOML configuration is invalid

**Problem:** starship.toml or other TOML files have errors

**Solution:**
```bash
# Install toml validator
pip install toml

# Validate
toml check starship.toml

# Or use online validator
# https://www.toml-lint.com/
```

---

## Advanced Troubleshooting

### Enable debug logging

Get detailed information about what's happening:

```bash
# Set debug log level
LOG_LEVEL=DEBUG ./bootstrap.sh

# Or with verbose output
./bootstrap.sh --verbose

# Check full log
tail -f ~/.dotfiles-install.log
```

### Reset everything

Complete clean slate:

```bash
# Backup first!
make backup

# Remove all installed files
make clean

# Reinstall
make install
```

### Get help

If you can't resolve an issue:

1. Check the log file: `~/.dotfiles-install.log`
2. Run tests: `./run-tests.sh`
3. Try dry-run mode: `./bootstrap.sh --dry-run`
4. Check documentation: `docs/`
5. Create an issue on GitHub with:
   - Error messages
   - Log file contents
   - Output of `uname -a`
   - Shell version: `bash --version` or `zsh --version`

---

## Quick Reference

Common commands for troubleshooting:

```bash
# Check installation log
cat ~/.dotfiles-install.log | tail -50

# Verify tools are installed
command -v eza fd rg bat fzf starship

# Test configuration validity
make validate

# Run all checks
make check

# Preview changes
./bootstrap.sh --dry-run

# Verbose output
./bootstrap.sh --verbose

# Run tests
make test

# Clean and reinstall
make clean && make install

# Show repository statistics
make stats
```
