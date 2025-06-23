#!/usr/bin/env bash
set -euo pipefail

# =========================
# Claude MCP Installer 🚀
# =========================

# ---- Default Config ----
FORCE_NON_INTERACTIVE=false
CHECK_ONLY=false
DEBUG_MODE=false
LOG_FILE=""
EXCLUDE_MCP=""
ONLY_MCP=""

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NPM_GLOBAL_DIR="$HOME/.npm-global"
PATH_UPDATE_LINE='export PATH="$HOME/.npm-global/bin:$PATH"'

# Colors and Emojis
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
NC="\033[0m"

# ---- CLI Arguments ----
while [[ $# -gt 0 ]]; do
    case $1 in
        --non-interactive|-n)
            FORCE_NON_INTERACTIVE=true ;;
        --check|--dry-run|-c)
            CHECK_ONLY=true ;;
        --log-file=*)
            LOG_FILE="${1#*=}" ;;
        --debug)
            DEBUG_MODE=true ;;
        --exclude=*)
            EXCLUDE_MCP="${1#*=}" ;;
        --only=*)
            ONLY_MCP="${1#*=}" ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo "  --non-interactive, -n   Run in non-interactive mode"
            echo "  --check, --dry-run, -c  Check system readiness only"
            echo "  --log-file=FILE         Log output to file"
            echo "  --debug                 Enable debug mode"
            echo "  --exclude=name1,name2   Skip certain MCPs"
            echo "  --only=name1,name2      Only install listed MCPs"
            exit 0 ;;
        *)
            echo -e "${RED}❌ Unknown option: $1${NC}" >&2
            exit 1 ;;
    esac
    shift
done

INTERACTIVE=true
if [[ "$FORCE_NON_INTERACTIVE" == "true" || ! -t 0 ]]; then
    INTERACTIVE=false
fi

log() {
    local level="$1"
    local message="$2"
    local color="$NC"
    local emoji=""

    case "$level" in
        INFO) color="$BLUE"; emoji="ℹ️" ;;
        WARN) color="$YELLOW"; emoji="⚠️" ;;
        ERROR) color="$RED"; emoji="❌" ;;
        SUCCESS) color="$GREEN"; emoji="✅" ;;
    esac

    echo -e "${color}${emoji} [$level]${NC} $message"
    [[ -n "$LOG_FILE" ]] && echo "[$level] $message" >> "$LOG_FILE"
}

error() {
    log "ERROR" "$1"
    exit 1
}

debug() {
    [[ "$DEBUG_MODE" == "true" ]] && echo "[DEBUG] $1"
}

is_excluded() {
    [[ ",$EXCLUDE_MCP," == *",$1,"* ]]
}

is_included() {
    [[ -z "$ONLY_MCP" || ",$ONLY_MCP," == *",$1,"* ]]
}

detect_shell_rc() {
    case "$(basename "$SHELL")" in
        zsh) echo "$HOME/.zshrc" ;;
        bash) echo "$HOME/.bashrc" ;;
        fish) echo "$HOME/.config/fish/config.fish" ;; # warning only
        *) echo "" ;;
    esac
}

safe_append() {
    local file="$1"
    local line="$2"
    grep -qF -- "$line" "$file" || echo "$line" >> "$file"
}

ensure_path_in_shell_rc() {
    local rc_file
    rc_file=$(detect_shell_rc)

    if [[ -z "$rc_file" ]]; then
        log "WARN" "Unknown shell. Please add $PATH_UPDATE_LINE to your shell config manually."
        return
    fi

    if [[ ! -f "$rc_file" ]]; then
        touch "$rc_file"
        log "INFO" "Created $rc_file"
    fi

    if [[ -L "$rc_file" || ! -w "$rc_file" ]]; then
        log "WARN" "$rc_file is read-only or a symlink. Please update it manually."
        return
    fi

    safe_append "$rc_file" "$PATH_UPDATE_LINE"
}

run_checks_only() {
    log "INFO" "Running system check..."
    command -v npm &>/dev/null && log "INFO" "npm found: $(npm --version)" || error "npm not found"
    command -v claude &>/dev/null && log "INFO" "claude found: $(claude --version)" || log "WARN" "claude not installed"
    command -v npx &>/dev/null && log "INFO" "npx found" || error "npx is missing"
    command -v uvx &>/dev/null && log "INFO" "uvx (Python runner) found" || log "WARN" "uvx not found (needed for Serena)"
    log "INFO" "Current MCP servers:"
    claude mcp list || log "WARN" "No MCP servers registered"
    log "SUCCESS" "Environment check complete ✅"
    exit 0
}

install_claude_if_missing() {
    if ! command -v claude &>/dev/null; then
        log "INFO" "Installing Claude via npm..."
        npm install -g "@anthropic-ai/claude-code" && log "SUCCESS" "Claude installed!" || error "Failed to install Claude"
    fi
}

install_uvx_if_missing() {
    if ! command -v uvx &>/dev/null; then
        log "INFO" "Installing uv..."
        curl -LsSf https://astral.sh/uv/install.sh | sh
        export PATH="$HOME/.cargo/bin:$PATH"
    fi
}

install_playwright_browsers() {
    log "INFO" "Installing Playwright + Browsers..."
    npm install -g playwright
    npx playwright install chromium firefox webkit
    log "SUCCESS" "Playwright browsers installed"
}

setup_serena() {
    install_uvx_if_missing
    local default_project="$HOME/projects"
    local project_dir="$default_project"

    if [[ "$INTERACTIVE" == "true" ]]; then
        read -p "Enter Serena project directory [$default_project]: " input
        project_dir="${input:-$default_project}"
    fi

    mkdir -p "$project_dir"
    mkdir -p "$HOME/.serena"
    echo "{"defaultProject": "$project_dir", "context": "ide-assistant"}" > "$HOME/.serena/config.json"
    export SERENA_PROJECT_DIR="$project_dir"
    log "INFO" "Installing Serena MCP..."
    claude mcp add serena -- uvx --from git+https://github.com/oraios/serena serena-mcp-server --context ide-assistant --project "$SERENA_PROJECT_DIR"         && log "SUCCESS" "Serena MCP installed"         || log "ERROR" "Serena MCP installation failed"
}

install_mcp_server() {
    local name="$1"
    local cmd="$2"

    if is_excluded "$name" || ! is_included "$name"; then
        log "INFO" "Skipping MCP: $name"
        return
    fi

    log "INFO" "Installing MCP: $name"
    if claude mcp list | grep -q "^$name\b"; then
        log "INFO" "MCP '$name' already installed"
        return
    fi

    if [[ "$name" == "serena" ]]; then
        setup_serena
    else
        if claude mcp add "$name" $cmd; then
            log "SUCCESS" "MCP $name installed"
        else
            log "ERROR" "Failed to install MCP $name"
        fi
    fi
}

main() {
    log "INFO" "Starting Claude MCP Installer 🚀"
    [[ "$CHECK_ONLY" == "true" ]] && run_checks_only

    log "INFO" "Preparing environment..."
    mkdir -p "$NPM_GLOBAL_DIR"
    npm config set prefix "$NPM_GLOBAL_DIR"
    export PATH="$NPM_GLOBAL_DIR/bin:$PATH"
    ensure_path_in_shell_rc

    install_claude_if_missing

    MCP_SERVERS=(
        "playwright:npx @playwright/mcp@latest"
        "github:npx @modelcontextprotocol/server-github"
        "context7:npx @context7/mcp-server"
        "memorybank:npx memory-bank-mcp"
        "memory:npx @modelcontextprotocol/server-memory"
        "serena:SPECIAL"
        "time:npx @modelcontextprotocol/server-time"
        "git:npx @modelcontextprotocol/server-git"
    )

    for entry in "${MCP_SERVERS[@]}"; do
        IFS=':' read -r name cmd <<< "$entry"
        install_mcp_server "$name" "$cmd"
    done

    install_playwright_browsers

    log "SUCCESS" "All MCPs processed ✅"
    claude mcp list
}

main "$@"
