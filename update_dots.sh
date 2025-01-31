#!/usr/bin/env bash

set -e

# Default source and destination directories
SOURCE_DIR="$HOME/.config"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
DESTINATION_DIR="$SCRIPT_DIR"

# Default file and directory lists (relative to $SOURCE_DIR)
DEFAULT_FILE_LIST=("starship.toml")
DEFAULT_DIR_LIST=("atuin" "bat" "eza" "fd" "k9s" "navi" "ripgrep" "ripgrep-all" "scripts" "tealdeer")

# Ensure destination directory exists
mkdir -p "$DESTINATION_DIR"

# Default text replacement values
OLD_TEXT="~"
NEW_TEXT="~"

# Function to copy files and modify permissions
copy_files() {
    local src_file="$SOURCE_DIR/$1"
    local dest_file="$DESTINATION_DIR/$1"

    if [[ -f "$src_file" ]]; then
        cp -L "$src_file" "$dest_file"  # Use -L to dereference symbolic links
        chown "$USER" "$dest_file"
        chmod u+w "$dest_file"
        echo "Copied file: $src_file -> $dest_file"
    else
        echo "Warning: File $src_file does not exist."
    fi
}

# Function to copy directories recursively and modify permissions
copy_directories() {
    local src_dir="$SOURCE_DIR/$1"
    local dest_dir="$DESTINATION_DIR/$1"

    if [[ -d "$src_dir" ]]; then
        echo "Copying directory: $src_dir -> $dest_dir"
        cp -rL "$src_dir" "$dest_dir"  # Use -rL to dereference symbolic links
        chown -R "$USER" "$dest_dir"
        find "$dest_dir" -type f -exec chmod u+w {} \;
        echo "Copied directory: $src_dir -> $dest_dir"
    else
        echo "Warning: Directory $src_dir does not exist."
    fi
}

# Copy default files
for file in "${DEFAULT_FILE_LIST[@]}"; do
    copy_files "$file"
done

# Copy default directories
for dir in "${DEFAULT_DIR_LIST[@]}"; do
    copy_directories "$dir"
done

# Update text within copied files
escaped_old_text=$(printf '%s\n' "$OLD_TEXT" | sed 's/[]\/$*.^|[]/\\&/g')
escaped_new_text=$(printf '%s\n' "$NEW_TEXT" | sed 's/[]\/$*.^|[]/\\&/g')
find "$DESTINATION_DIR" -type f -exec sed -i "s/$escaped_old_text/$escaped_new_text/g" {} \;

echo "Files and directories copied successfully to $DESTINATION_DIR. Text replacement completed."
