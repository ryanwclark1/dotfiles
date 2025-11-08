#!/usr/bin/env bash

# Common utility functions for dotfiles scripts
# Source this file for shared functionality

# Strict error handling
set -euo pipefail

# Colors
readonly COLOR_RESET='\033[0m'
readonly COLOR_DEBUG='\033[0;36m'    # Cyan
readonly COLOR_INFO='\033[0;34m'     # Blue
readonly COLOR_WARN='\033[1;33m'     # Yellow
readonly COLOR_ERROR='\033[0;31m'    # Red
readonly COLOR_SUCCESS='\033[0;32m'  # Green

# Cleanup tracking
declare -a CLEANUP_COMMANDS=()

# Register cleanup command
register_cleanup() {
    local cmd="$*"
    CLEANUP_COMMANDS+=("$cmd")
}

# Execute cleanup commands
run_cleanup() {
    local exit_code=$?

    if [[ ${#CLEANUP_COMMANDS[@]} -gt 0 ]]; then
        echo "Running cleanup..." >&2
        for cmd in "${CLEANUP_COMMANDS[@]}"; do
            eval "$cmd" 2>/dev/null || true
        done
    fi

    exit "$exit_code"
}

# Set up signal handlers
setup_signal_handlers() {
    trap run_cleanup EXIT
    trap 'echo "Interrupted by user"; exit 130' INT
    trap 'echo "Terminated"; exit 143' TERM
}

# Validate required tools
require_tools() {
    local missing=()

    for tool in "$@"; do
        if ! command -v "$tool" &>/dev/null; then
            missing+=("$tool")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${COLOR_ERROR}Error: Missing required tools: ${missing[*]}${COLOR_RESET}" >&2
        echo "Please install them and try again." >&2
        return 1
    fi

    return 0
}

# Retry a command with exponential backoff
retry_with_backoff() {
    local max_attempts="${1:-5}"
    local delay="${2:-2}"
    local max_delay="${3:-60}"
    shift 3
    local attempt=1
    local current_delay="$delay"

    while [[ $attempt -le $max_attempts ]]; do
        if "$@"; then
            return 0
        fi

        if [[ $attempt -lt $max_attempts ]]; then
            echo -e "${COLOR_WARN}Command failed (attempt $attempt/$max_attempts). Retrying in ${current_delay}s...${COLOR_RESET}" >&2
            sleep "$current_delay"
            current_delay=$((current_delay * 2))
            if [[ $current_delay -gt $max_delay ]]; then
                current_delay="$max_delay"
            fi
        fi

        attempt=$((attempt + 1))
    done

    echo -e "${COLOR_ERROR}Command failed after $max_attempts attempts${COLOR_RESET}" >&2
    return 1
}

# Download file with retry
download_file() {
    local url="$1"
    local output="$2"
    local max_attempts="${3:-3}"

    retry_with_backoff "$max_attempts" 2 10 curl -fsSL -o "$output" "$url"
}

# Validate JSON file
validate_json() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        echo -e "${COLOR_ERROR}File not found: $file${COLOR_RESET}" >&2
        return 1
    fi

    if ! jq empty "$file" 2>/dev/null; then
        echo -e "${COLOR_ERROR}Invalid JSON: $file${COLOR_RESET}" >&2
        return 1
    fi

    return 0
}

# Validate YAML file
validate_yaml() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        echo -e "${COLOR_ERROR}File not found: $file${COLOR_RESET}" >&2
        return 1
    fi

    if command -v yamllint &>/dev/null; then
        yamllint -d relaxed "$file" 2>/dev/null
        return $?
    fi

    # Basic validation if yamllint not available
    if ! python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
        echo -e "${COLOR_ERROR}Invalid YAML: $file${COLOR_RESET}" >&2
        return 1
    fi

    return 0
}

# Safe directory creation
safe_mkdir() {
    local dir="$1"
    local mode="${2:-755}"

    if [[ -e "$dir" && ! -d "$dir" ]]; then
        echo -e "${COLOR_ERROR}Path exists but is not a directory: $dir${COLOR_RESET}" >&2
        return 1
    fi

    if [[ ! -d "$dir" ]]; then
        mkdir -p -m "$mode" "$dir"
    fi
}

# Safe file copy with backup
safe_copy() {
    local src="$1"
    local dst="$2"
    local backup="${3:-true}"

    if [[ ! -f "$src" ]]; then
        echo -e "${COLOR_ERROR}Source file not found: $src${COLOR_RESET}" >&2
        return 1
    fi

    # Create parent directory if needed
    safe_mkdir "$(dirname "$dst")"

    # Backup existing file
    if [[ "$backup" == "true" && -f "$dst" ]]; then
        local backup_file="${dst}.backup-$(date +%Y%m%d-%H%M%S)"
        cp "$dst" "$backup_file"
        echo -e "${COLOR_INFO}Backed up existing file to: $backup_file${COLOR_RESET}" >&2
    fi

    cp "$src" "$dst"
}

# Check if running as root
check_not_root() {
    if [[ $EUID -eq 0 ]]; then
        echo -e "${COLOR_ERROR}Error: This script should not be run as root${COLOR_RESET}" >&2
        echo "Please run as a normal user." >&2
        return 1
    fi
    return 0
}

# Check disk space
check_disk_space() {
    local required_mb="${1:-100}"
    local path="${2:-.}"

    if ! command -v df &>/dev/null; then
        echo -e "${COLOR_WARN}Warning: Cannot check disk space (df not available)${COLOR_RESET}" >&2
        return 0
    fi

    local available_kb
    available_kb=$(df "$path" | awk 'NR==2 {print $4}')
    local available_mb=$((available_kb / 1024))

    if [[ $available_mb -lt $required_mb ]]; then
        echo -e "${COLOR_ERROR}Error: Insufficient disk space${COLOR_RESET}" >&2
        echo "Required: ${required_mb}MB, Available: ${available_mb}MB" >&2
        return 1
    fi

    return 0
}

# Confirm action with user
confirm() {
    local prompt="${1:-Are you sure?}"
    local default="${2:-n}"

    if [[ "${FORCE:-false}" == "true" ]]; then
        return 0
    fi

    local yn
    if [[ "$default" == "y" ]]; then
        read -p "$prompt [Y/n] " -n 1 -r yn
    else
        read -p "$prompt [y/N] " -n 1 -r yn
    fi
    echo

    case "$yn" in
        [Yy]*) return 0 ;;
        [Nn]*) return 1 ;;
        "") [[ "$default" == "y" ]] && return 0 || return 1 ;;
        *) return 1 ;;
    esac
}

# Create timestamped backup
create_backup() {
    local source="$1"
    local backup_dir="${2:-$HOME/.dotfiles-backups}"

    if [[ ! -e "$source" ]]; then
        echo -e "${COLOR_WARN}Warning: Source not found: $source${COLOR_RESET}" >&2
        return 1
    fi

    safe_mkdir "$backup_dir"

    local timestamp
    timestamp=$(date +%Y%m%d-%H%M%S)
    local basename_source
    basename_source=$(basename "$source")
    local backup_path="$backup_dir/${basename_source}-${timestamp}"

    if [[ -d "$source" ]]; then
        cp -r "$source" "$backup_path"
    else
        cp "$source" "$backup_path"
    fi

    echo -e "${COLOR_SUCCESS}Backup created: $backup_path${COLOR_RESET}" >&2
    echo "$backup_path"
}

# Check if file is writable
is_writable() {
    local file="$1"

    if [[ -e "$file" ]]; then
        [[ -w "$file" ]]
    else
        # Check if parent directory is writable
        local parent
        parent=$(dirname "$file")
        [[ -w "$parent" ]]
    fi
}

# Sanitize filename
sanitize_filename() {
    local filename="$1"
    # Remove/replace dangerous characters
    echo "$filename" | tr -dc '[:alnum:]._-' | tr '[:upper:]' '[:lower:]'
}

# Get absolute path
get_absolute_path() {
    local path="$1"

    if [[ -d "$path" ]]; then
        (cd "$path" && pwd)
    elif [[ -f "$path" ]]; then
        local dir
        dir=$(dirname "$path")
        local file
        file=$(basename "$path")
        echo "$(cd "$dir" && pwd)/$file"
    else
        echo -e "${COLOR_ERROR}Path not found: $path${COLOR_RESET}" >&2
        return 1
    fi
}

# Check if process is running
is_process_running() {
    local process_name="$1"
    pgrep -x "$process_name" >/dev/null 2>&1
}

# Wait for process to finish
wait_for_process() {
    local process_name="$1"
    local timeout="${2:-30}"
    local elapsed=0

    while is_process_running "$process_name" && [[ $elapsed -lt $timeout ]]; do
        sleep 1
        elapsed=$((elapsed + 1))
    done

    if is_process_running "$process_name"; then
        echo -e "${COLOR_WARN}Warning: Process still running after ${timeout}s: $process_name${COLOR_RESET}" >&2
        return 1
    fi

    return 0
}

# Log message with level
log_message() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    local color=""
    case "$level" in
        DEBUG) color="$COLOR_DEBUG" ;;
        INFO)  color="$COLOR_INFO" ;;
        WARN)  color="$COLOR_WARN" ;;
        ERROR) color="$COLOR_ERROR" ;;
        SUCCESS) color="$COLOR_SUCCESS" ;;
    esac

    echo -e "${color}[$timestamp] [$level]${COLOR_RESET} $message"
}

# Export functions for use in subshells
export -f register_cleanup run_cleanup setup_signal_handlers
export -f require_tools retry_with_backoff download_file
export -f validate_json validate_yaml
export -f safe_mkdir safe_copy
export -f check_not_root check_disk_space confirm
export -f create_backup is_writable sanitize_filename
export -f get_absolute_path is_process_running wait_for_process
export -f log_message
