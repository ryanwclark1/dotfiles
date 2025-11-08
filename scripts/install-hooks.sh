#!/usr/bin/env bash

# Install git hooks for dotfiles repository

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
HOOKS_DIR="$REPO_ROOT/hooks"
GIT_HOOKS_DIR="$REPO_ROOT/.git/hooks"

echo "Installing git hooks..."

if [[ ! -d "$GIT_HOOKS_DIR" ]]; then
    echo "Error: Not a git repository"
    exit 1
fi

# Install pre-commit hook
if [[ -f "$HOOKS_DIR/pre-commit" ]]; then
    ln -sf "$HOOKS_DIR/pre-commit" "$GIT_HOOKS_DIR/pre-commit"
    chmod +x "$GIT_HOOKS_DIR/pre-commit"
    echo "✅ Installed pre-commit hook"
else
    echo "⚠️  Warning: pre-commit hook not found in $HOOKS_DIR"
fi

echo ""
echo "Git hooks installed successfully!"
echo ""
echo "To disable hooks temporarily, use: git commit --no-verify"
