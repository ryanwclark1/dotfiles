#!/usr/bin/env bash
# Script to clean up duplicate dotfiles entries in .bashrc

set -euo pipefail

BASHRC="$HOME/.bashrc"
BACKUP="$BASHRC.backup.$(date +%Y%m%d_%H%M%S)"

# Create backup
echo "Creating backup at $BACKUP"
cp "$BASHRC" "$BACKUP"

# Markers for managed sections
START_MARKER="# BEGIN DOTFILES MANAGED BLOCK"
END_MARKER="# END DOTFILES MANAGED BLOCK"

# Create temporary file with content before first managed block
TEMP_FILE=$(mktemp)

# Extract content before any managed blocks and remove all managed blocks
awk -v start="$START_MARKER" -v end="$END_MARKER" '
    BEGIN { in_block = 0; found_first = 0 }
    $0 ~ start { in_block = 1; found_first = 1; next }
    $0 ~ end { in_block = 0; next }
    !in_block && !found_first { print }
' "$BASHRC" > "$TEMP_FILE"

# Now append the rest of the file after all managed blocks
awk -v start="$START_MARKER" -v end="$END_MARKER" '
    BEGIN { in_block = 0; after_blocks = 0 }
    $0 ~ start { in_block = 1; next }
    $0 ~ end { in_block = 0; after_blocks = 1; next }
    !in_block && after_blocks { print }
' "$BASHRC" >> "$TEMP_FILE"

# Replace original file
mv "$TEMP_FILE" "$BASHRC"

echo "Cleaned up duplicate dotfiles entries from $BASHRC"
echo "Backup saved at: $BACKUP"
echo ""
echo "Now run ./bootstrap.sh to add the configuration properly"