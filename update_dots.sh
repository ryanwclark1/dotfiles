#!/usr/bin/env bash

set -e

# Default source and destination directories
SOURCE_DIR="$HOME/.config"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
DESTINATION_DIR="$SCRIPT_DIR"

# Default file and directory lists (relative to $SOURCE_DIR)
DEFAULT_FILE_LIST=("starship.toml")
DEFAULT_DIR_LIST=("atuin" "bat" "eza" "fd" "k9s" "navi" "ripgrep" "ripgrep-all" "tealdeer")

# Ensure destination directory exists
mkdir -p "$DESTINATION_DIR"

# Default text replacement values
OLD_TEXT="new_text"
NEW_TEXT="new_text"

# Function to copy files and modify permissions
copy_files() {
    local src_file="$SOURCE_DIR/$1"
    local dest_file="$DESTINATION_DIR/$1"

    if [[ -f "$src_file" ]]; then
        cp "$src_file" "$dest_file"
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
        cp -r "$src_dir" "$dest_dir"
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
find "$DESTINATION_DIR" -type f -exec sed -i "s/$OLD_TEXT/$NEW_TEXT/g" {} \;

echo "Files and directories copied successfully to $DESTINATION_DIR. Text replacement completed."
