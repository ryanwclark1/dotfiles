#!/usr/bin/env bash

set -e

# Default source and destination directories
SOURCE_DIR="$HOME/.config"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
DESTINATION_DIR="$SCRIPT_DIR"

# Default file and directory lists (relative to $SOURCE_DIR)
DEFAULT_FILE_LIST=("starship.toml")
DEFAULT_DIR_LIST=("atuin" "bat" "eza" "fd" "k9s" "navi" "ripgrep" "ripgrep-all" "scripts" "tealdeer")

# Function to remove existing files
remove_files() {
    local dest_file="$DESTINATION_DIR/$1"

    if [[ -f "$dest_file" ]]; then
        rm -f "$dest_file"
        echo "Removed existing file: $dest_file"
    fi
}

# Function to remove existing directories
remove_directories() {
    local dest_dir="$DESTINATION_DIR/$1"

    if [[ -d "$dest_dir" ]]; then
        rm -rf "$dest_dir"
        echo "Removed existing directory: $dest_dir"
    fi
}

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
        cp -rfL "$src_dir" "$dest_dir"  # Use -rL to dereference symbolic links
        chown -R "$USER" "$dest_dir"
        find "$dest_dir" -type f -exec chmod u+w {} \;
        echo "Copied directory: $src_dir -> $dest_dir"
    else
        echo "Warning: Directory $src_dir does not exist."
    fi
}

# Remove existing files
for file in "${DEFAULT_FILE_LIST[@]}"; do
    remove_files "$file"
done

# Remove existing directories
for dir in "${DEFAULT_DIR_LIST[@]}"; do
    remove_directories "$dir"
done

# Ensure destination directory exists
mkdir -p "$DESTINATION_DIR"

# Copy default files
for file in "${DEFAULT_FILE_LIST[@]}"; do
    copy_files "$file"
done

# Copy default directories
for dir in "${DEFAULT_DIR_LIST[@]}"; do
    copy_directories "$dir"
done

echo "Files and directories copied successfully to $DESTINATION_DIR. Text replacement completed."

# if [[ -n $(git status --porcelain) ]]; then
#     git add .
#     git commit -m "Auto-update: $(date)"
#     git push origin main  # Change 'main' to your branch name if different
# else
#     echo "No changes to commit."
# fi
