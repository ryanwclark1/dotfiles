#!/usr/bin/env bash
# set -euo pipefail
# set -x
set -o pipefail

# =========================
# AI Tools Installer 🚀
# =========================
# Installs Claude CLI, Gemini CLI, and MCP servers
# Note: MCP (Model Context Protocol) is Anthropic-specific and only works with Claude
# Gemini uses different extension mechanisms

# ---- Default Config ----
FORCE_NON_INTERACTIVE=false
CHECK_ONLY=false
DEBUG_MODE=false
LOG_FILE=""
EXCLUDE_MCP=""
ONLY_MCP=""
CLAUDE_ONLY=false
GEMINI_ONLY=false
USE_STANDARD_FILESYSTEM=false

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
        --claude-only)
            CLAUDE_ONLY=true ;;
        --gemini-only)
            GEMINI_ONLY=true ;;
        --use-standard-filesystem)
            USE_STANDARD_FILESYSTEM=true ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo "Installs AI CLIs (Claude, Gemini) and MCP servers for enhanced functionality"
            echo ""
            echo "Options:"
            echo "  --non-interactive, -n   Run in non-interactive mode"
            echo "  --check, --dry-run, -c  Check system readiness only"
            echo "  --log-file=FILE         Log output to file"
            echo "  --debug                 Enable debug mode"
            echo "  --exclude=name1,name2   Skip certain MCPs"
            echo "  --only=name1,name2      Only install listed MCPs"
            echo "  --claude-only           Only install Claude CLI (skip Gemini)"
            echo "  --gemini-only           Only install Gemini CLI (skip Claude and MCPs)"
            echo "  --use-standard-filesystem  Use standard filesystem MCP instead of Serena"
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
    command -v gemini &>/dev/null && log "INFO" "gemini found: $(gemini --version 2>/dev/null || echo 'version unknown')" || log "WARN" "gemini not installed"
    command -v npx &>/dev/null && log "INFO" "npx found" || error "npx is missing"
    command -v uvx &>/dev/null && log "INFO" "uvx (Python runner) found" || log "WARN" "uvx not found (needed for Serena)"

    log "INFO" "Current Claude MCP servers:"
    claude mcp list 2>/dev/null || log "WARN" "No Claude MCP servers registered"

    if command -v gemini &>/dev/null; then
        log "INFO" "Gemini CLI is installed (Note: MCP protocol is Claude-specific)"
    fi

    log "SUCCESS" "Environment check complete ✅"
    exit 0
}

install_claude_if_missing() {
    if ! command -v claude &>/dev/null; then
        log "INFO" "Installing Claude CLI via npm..."
        if npm install -g "@anthropic-ai/claude-code"; then
            log "SUCCESS" "Claude CLI installed!"
        else
            error "Failed to install Claude CLI"
        fi
    fi
}

install_gemini_if_missing() {
    if ! command -v gemini &>/dev/null; then
        log "INFO" "Installing Gemini CLI via npm..."
        # Try multiple known Gemini CLI packages
        local installed=false
        for package in "@google/gemini-cli" "gemini-cli" "@gemini/cli"; do
            if npm install -g "$package" 2>/dev/null; then
                log "SUCCESS" "Gemini CLI installed from $package!"
                installed=true
                break
            fi
        done
        if [[ "$installed" == "false" ]]; then
            log "WARN" "Failed to install Gemini CLI - this is optional, continuing..."
            log "INFO" "You may need to install Gemini CLI manually or it might not be available via npm yet"
        fi
    else
        log "INFO" "Gemini CLI is already installed"
    fi
}

setup_gemini_mcp_config() {
    if ! command -v gemini &>/dev/null; then
        log "WARN" "Gemini CLI not installed, skipping MCP configuration setup"
        return 1
    fi

    log "INFO" "Setting up Gemini MCP configuration..."

    # Create Gemini config directory
    mkdir -p "$HOME/.gemini"

    # Check if template exists
    local template_file="$SCRIPT_DIR/gemini/settings.json"
    if [[ ! -f "$template_file" ]]; then
        log "WARN" "Gemini settings template not found at $template_file"
        return 1
    fi

    # Check if user already has a config
    local user_config="$HOME/.gemini/settings.json"
    if [[ -f "$user_config" ]]; then
        if [[ "$INTERACTIVE" == "true" ]]; then
            read -p "Gemini config already exists. Overwrite? [y/N]: " response
            if [[ ! "$response" =~ ^[Yy]$ ]]; then
                log "INFO" "Keeping existing Gemini configuration"
                return 0
            fi
        else
            log "INFO" "Gemini config exists, skipping setup (use --force to override)"
            return 0
        fi
    fi

    # Copy template to user config
    cp "$template_file" "$user_config"

    # Update API keys if available
    if [[ -n "$BRAVE_SEARCH_API_KEY" ]]; then
        sed -i.bak 's/"BRAVE_API_KEY": "YOUR_BRAVE_API_KEY_HERE"/"BRAVE_API_KEY": "'"$BRAVE_SEARCH_API_KEY"'"/' "$user_config"
        rm -f "$user_config.bak"
    fi

    # Check for GitHub token in environment
    if [[ -n "$GITHUB_TOKEN" || -n "$GITHUB_PERSONAL_ACCESS_TOKEN" ]]; then
        local token="${GITHUB_TOKEN:-$GITHUB_PERSONAL_ACCESS_TOKEN}"
        sed -i.bak 's/"GITHUB_PERSONAL_ACCESS_TOKEN": "YOUR_GITHUB_TOKEN_HERE"/"GITHUB_PERSONAL_ACCESS_TOKEN": "'"$token"'"/' "$user_config"
        rm -f "$user_config.bak"
    fi

    log "SUCCESS" "Gemini MCP configuration created at $user_config"
    log "INFO" "Note: MCP servers in Gemini work differently than Claude"
    log "INFO" "Please review the configuration and update any API keys as needed"

    return 0
}


install_uvx_if_missing() {
    if ! command -v uvx &>/dev/null; then
        log "INFO" "Installing uv..."
        curl -LsSf https://astral.sh/uv/install.sh | sh
        export PATH="$HOME/.cargo/bin:$PATH"
    fi
}

install_playwright_browsers() {
    log "INFO" "Installing Playwright..."
    if npm install -g playwright; then
        log "SUCCESS" "Playwright installed"
    else
        log "ERROR" "Failed to install Playwright"
        FAILED_MCP_INSTALLS+=("playwright")
        return
    fi

    log "INFO" "Installing system dependencies for Playwright (may require sudo)..."
    if npx playwright install-deps; then
        log "SUCCESS" "Playwright dependencies installed"
    else
        log "WARN" "Failed to install Playwright system dependencies. Skipping browser installation."
        FAILED_MCP_INSTALLS+=("playwright-deps")
        return
    fi

    log "INFO" "Installing Playwright browsers..."
    if npx playwright install chromium firefox webkit; then
        log "SUCCESS" "Playwright browsers installed"
    else
        log "WARN" "Playwright installed, but browser download failed"
        FAILED_MCP_INSTALLS+=("playwright-browsers")
    fi
}

setup_serena() {
    install_uvx_if_missing

    local default_project="/workspace"
    local project_dir="$default_project"

    if [[ "$INTERACTIVE" == "true" ]]; then
        read -p "Enter Serena project directory [$default_project]: " input
        project_dir="${input:-$default_project}"
    fi

    mkdir -p "$project_dir"
    mkdir -p "$HOME/.serena"

    # Create proper YAML config file as per documentation
    cat > "$HOME/.serena/serena_config.yml" <<EOF
# Serena configuration
project: $project_dir
context: ide-assistant
EOF

    export SERENA_PROJECT_DIR="$project_dir"
    log "INFO" "Created Serena config at ~/.serena/serena_config.yml"

    return 0  # Return success for config setup
}

setup_brave_search() {
    log "INFO" "Setting up Brave Search MCP..."
    log "WARN" "Brave Search requires an API key from https://brave.com/search/api/"

    local api_key=""
    if [[ "$INTERACTIVE" == "true" ]]; then
        read -p "Enter Brave Search API key (or press Enter to skip): " api_key
    fi

    if [[ -z "$api_key" ]]; then
        log "WARN" "Skipping Brave Search setup - no API key provided"
        return 1
    fi

    # Store API key for use in install_mcp_server_to_cli
    export BRAVE_SEARCH_API_KEY="$api_key"
    return 0
}

# Function to add MCP server to a specific CLI (claude or gemini)
install_mcp_server_to_cli() {
    local cli="$1"  # claude or gemini
    local name="$2"
    local cmd="$3"

    # Check if CLI is available
    if ! command -v "$cli" &>/dev/null; then
        log "WARN" "$cli CLI not available, skipping MCP installation for $name"
        return 1
    fi

    # Gemini doesn't support MCP protocol
    if [[ "$cli" == "gemini" ]]; then
        log "INFO" "Gemini CLI does not support MCP protocol (Model Context Protocol is Anthropic-specific)"
        return 0
    fi

    # Check if already installed
    if $cli mcp list 2>/dev/null | grep -q "^$name\b"; then
        log "INFO" "MCP '$name' already installed in $cli"
        return 0
    fi

    # Handle special command modifications
    local modified_cmd="$cmd"
    case "$name" in
        "brave-search")
            if [[ -n "$BRAVE_SEARCH_API_KEY" ]]; then
                modified_cmd="$cmd --api-key $BRAVE_SEARCH_API_KEY"
            fi
            ;;
        "serena")
            if [[ -n "$SERENA_PROJECT_DIR" ]]; then
                modified_cmd="uvx --from git+https://github.com/oraios/serena serena-mcp-server --context ide-assistant --project $SERENA_PROJECT_DIR"
            fi
            ;;
    esac

    # Add MCP server at user scope (available in all directories)
    log "INFO" "Installing MCP '$name' to $cli at user scope..."
    
    if $cli mcp add --scope user "$name" -- $modified_cmd; then
        log "SUCCESS" "MCP '$name' installed to $cli at user scope (available everywhere)"
        return 0
    else
        log "ERROR" "Failed to install MCP '$name' to $cli"
        return 1
    fi
}

install_mcp_server() {
    local name="$1"
    local cmd="$2"

    if is_excluded "$name" || ! is_included "$name"; then
        log "INFO" "Skipping MCP: $name"
        return
    fi

    log "INFO" "Processing MCP: $name"

    # Handle special setups first
    if [[ "$cmd" == "SPECIAL" ]]; then
        case "$name" in
            "serena")
                setup_serena || { FAILED_MCP_INSTALLS+=("$name"); return; }
                ;;
            # "brave-search")
            #     setup_brave_search || { FAILED_MCP_INSTALLS+=("$name"); return; }
            #     ;;
            *)
                log "ERROR" "Unknown special setup for $name"
                FAILED_MCP_INSTALLS+=("$name")
                return
                ;;
        esac
    fi

    # Determine which command to use based on special cases
    local actual_cmd="$cmd"
    if [[ "$cmd" == "SPECIAL" ]]; then
        case "$name" in
            "serena")
                actual_cmd="uvx --from git+https://github.com/oraios/serena serena-mcp-server"
                ;;
            # "brave-search")
            #     actual_cmd="npx @modelcontextprotocol/server-brave-search"
            #     ;;
        esac
    fi

    # Install to Claude if not gemini-only
    if [[ "$GEMINI_ONLY" != "true" ]]; then
        install_mcp_server_to_cli "claude" "$name" "$actual_cmd" || FAILED_MCP_INSTALLS+=("claude:$name")
    fi

    # Note: MCP is Anthropic-specific, Gemini uses different extension mechanisms
}

main() {
    log "INFO" "Starting AI Tools Installer 🚀"
    [[ "$CHECK_ONLY" == "true" ]] && run_checks_only

    # Initialize failed installs array
    declare -a FAILED_MCP_INSTALLS=()

    log "INFO" "Preparing environment..."
    mkdir -p "$NPM_GLOBAL_DIR"
    npm config set prefix "$NPM_GLOBAL_DIR"
    export PATH="$NPM_GLOBAL_DIR/bin:$PATH"
    ensure_path_in_shell_rc

    # Install CLIs based on flags
    if [[ "$GEMINI_ONLY" != "true" ]]; then
        install_claude_if_missing
    fi

    if [[ "$CLAUDE_ONLY" != "true" ]]; then
        install_gemini_if_missing
        # Setup Gemini MCP config if Gemini was installed
        if command -v gemini &>/dev/null; then
            setup_gemini_mcp_config
        fi
    fi

    # Determine which filesystem server to use
    local filesystem_choice="serena"  # Default to serena since it's more feature-rich
    
    # Check if flag was set
    if [[ "$USE_STANDARD_FILESYSTEM" == "true" ]]; then
        filesystem_choice="standard"
    elif [[ "$INTERACTIVE" == "true" ]]; then
        echo "Choose filesystem MCP server:"
        echo "1) Serena (recommended - includes filesystem + code intelligence)"
        echo "2) Standard filesystem server (basic filesystem operations only)"
        read -p "Enter choice [1-2] (default: 1): " choice
        case "$choice" in
            2) filesystem_choice="standard" ;;
            *) filesystem_choice="serena" ;;
        esac
    fi

    MCP_SERVERS=(
        # Core MCP servers from modelcontextprotocol (only published ones)
        "sequential-thinking:npx @modelcontextprotocol/server-sequential-thinking"
        "memory:npx @modelcontextprotocol/server-memory"
        "everything:npx @modelcontextprotocol/server-everything"

        # Browser automation
        "playwright:npx @playwright/mcp@latest"
        "puppeteer:npx @modelcontextprotocol/server-puppeteer"

        # GitHub integration
        "github:npx @modelcontextprotocol/server-github"

        # Note: The following servers are not yet published on npm:
        # - @modelcontextprotocol/server-git
        # - @modelcontextprotocol/server-fetch
        # - @modelcontextprotocol/server-time
        # - @isaacphi/language-server-mcp
        # - @pydantic/mcp-run-python
        # - @alioshr/memory-bank-mcp
        # - @context7/mcp-server
        
        # Note: Gemini doesn't support MCP protocol - it's Anthropic-specific
    )

    # Add filesystem server based on choice
    if [[ "$filesystem_choice" == "serena" ]]; then
        MCP_SERVERS+=("serena:SPECIAL")
        log "INFO" "Using Serena for filesystem operations and code intelligence"
    else
        MCP_SERVERS+=("filesystem:npx @modelcontextprotocol/server-filesystem /home /workspace")
        log "INFO" "Using standard filesystem MCP server"
    fi

    for entry in "${MCP_SERVERS[@]}"; do
        IFS=':' read -r name cmd <<< "$entry"
        install_mcp_server "$name" "$cmd"
    done

    install_playwright_browsers

    # Install additional tools
    log "INFO" "Installing ccusage (Claude usage tracking tool)..."
    if npm install -g ccusage@latest; then
        log "SUCCESS" "ccusage installed successfully!"
    else
        log "WARN" "Failed to install ccusage"
        FAILED_MCP_INSTALLS+=("ccusage")
    fi

    # Note: We don't pre-cache MCP packages as they don't support standard CLI flags
    # They will be downloaded on first use by Claude

    log "SUCCESS" "All installations processed ✅"

    # Show installed MCP servers for each CLI
    if [[ "$GEMINI_ONLY" != "true" ]] && command -v claude &>/dev/null; then
        log "INFO" "Claude MCP servers:"
        claude mcp list || log "WARN" "Could not list Claude MCP servers"
    fi

    if [[ "$CLAUDE_ONLY" != "true" ]] && command -v gemini &>/dev/null; then
        log "INFO" "Gemini CLI installed (Note: MCP protocol is Claude-specific)"
    fi

    if [[ "${#FAILED_MCP_INSTALLS[@]}" -gt 0 ]]; then
        log "WARN" "Some components failed to install:"
        for failed in "${FAILED_MCP_INSTALLS[@]}"; do
            log "ERROR" "❌ $failed"
        done
        log "INFO" "You can re-run the script to retry failed installations"
        exit 1
    else
        log "SUCCESS" "AI CLIs and all MCP servers installed successfully 🎉"
        log "INFO" "Restart your shell or source your shell config to ensure PATH is updated"
        log "INFO" "Note: Some MCP servers may fail to connect on first run - this is normal"
        log "INFO" "They will download dependencies on first actual use"
        log "INFO" "MCP servers were installed at user scope"
        log "INFO" "They will be available when you start Claude from any directory"
    fi
}

main "$@"
