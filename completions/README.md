# Shell Completions

This directory contains shell completion scripts for dotfiles commands.

## Installation

### Bash

Add to your `~/.bashrc`:

```bash
# Source dotfiles completions
if [ -f ~/.config/dotfiles/completions/bash/dotfiles ]; then
    source ~/.config/dotfiles/completions/bash/dotfiles
fi
```

Or manually:

```bash
# Copy to system completion directory
sudo cp completions/bash/dotfiles /etc/bash_completion.d/

# Or to user completion directory
mkdir -p ~/.local/share/bash-completion/completions
cp completions/bash/dotfiles ~/.local/share/bash-completion/completions/
```

### Zsh

Add to your `~/.zshrc` (before `compinit`):

```zsh
# Add dotfiles completions to fpath
fpath=(~/.config/dotfiles/completions/zsh $fpath)

# Initialize completions
autoload -Uz compinit
compinit
```

Or manually:

```bash
# Copy to zsh completions directory
mkdir -p ~/.local/share/zsh/site-functions
cp completions/zsh/_dotfiles ~/.local/share/zsh/site-functions/
```

## Available Completions

### Scripts

- `bootstrap.sh` - Installation script options
- `uninstall.sh` - Uninstallation script options
- `run-tests.sh` - Test runner with suite selection
- `update_dots.sh` - Update script options
- `test-in-docker.sh` - Docker testing commands
- `validate-install.sh` - Validation script options
- `health-check.sh` - Health check options

### Makefile Targets

When in the dotfiles directory, `make` command will autocomplete with all available targets:

```bash
make <TAB>
# Shows: help, test, install, docker-test, etc.
```

## Usage Examples

### Bash

```bash
# Type and press TAB to see options
./bootstrap.sh <TAB>
# Shows: -h --help -d --dry-run -v --verbose --log-file

./run-tests.sh <TAB>
# Shows: -h --help -v --verbose bootstrap configs scripts mcp all

make docker<TAB>
# Shows: docker-test docker-test-full docker-test-multi docker-shell docker-build docker-clean
```

### Zsh

```zsh
# Type and press TAB to see options with descriptions
./uninstall.sh <TAB>
# Shows options with descriptions:
# -h --help               -- Show help message
# -y --yes                -- Skip confirmation prompts
# -b --backup             -- Create backup before uninstalling
# --keep-tools            -- Keep installed tools, only remove configs

./test-in-docker.sh <TAB>
# Shows commands with descriptions:
# quick        -- Run quick Docker test
# full         -- Run full installation test
# multi        -- Test on multiple distributions
```

## Troubleshooting

### Completions not working (Bash)

1. Check if bash-completion is installed:
   ```bash
   dpkg -l | grep bash-completion  # Debian/Ubuntu
   rpm -qa | grep bash-completion  # RHEL/Fedora
   ```

2. Ensure bash-completion is sourced in `~/.bashrc`:
   ```bash
   if [ -f /etc/bash_completion ]; then
       . /etc/bash_completion
   fi
   ```

3. Reload your shell:
   ```bash
   source ~/.bashrc
   ```

### Completions not working (Zsh)

1. Ensure `fpath` is set before `compinit`:
   ```zsh
   # This should be BEFORE compinit
   fpath=(~/.config/dotfiles/completions/zsh $fpath)

   autoload -Uz compinit
   compinit
   ```

2. Clear completion cache:
   ```zsh
   rm -f ~/.zcompdump*
   exec zsh
   ```

3. Check if completions are loaded:
   ```zsh
   which _dotfiles
   # Should show function definition
   ```

## Development

To add completions for a new script:

1. **Bash**: Add a new completion function in `bash/dotfiles`
2. **Zsh**: Add a new completion function in `zsh/_dotfiles`
3. Register the completion with `complete` (Bash) or `compdef` (Zsh)
4. Test with `source` and verify with TAB completion

See existing completions for examples.
