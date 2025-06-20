#!/usr/bin/env bash
set -e

echo "Setting up Claude Code and MCP servers..."

# Dynamic path detection
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Configuration
NPM_GLOBAL_DIR="$HOME/.npm-global"
CLAUDE_PACKAGE="@anthropic-ai/claude-code"

# MCP servers to install
declare -a MCP_SERVERS=(
    "playwright:npx @playwright/mcp@latest"
    "github:npx @modelcontextprotocol/server-github"
    "context7:npx @context7/mcp-server"
    "memorybank:npx memory-bank-mcp"
    "memory:npx @modelcontextprotocol/server-memory"
    "serena:SPECIAL"  # Special handling for Serena with custom command
    "time:npx @modelcontextprotocol/server-time"
    "git:npx @modelcontextprotocol/server-git"
    # Add more MCP servers here in format "name:command"
    # Example: "filesystem:npx @modelcontextprotocol/server-filesystem /path/to/allow"
)

# Playwright configuration
PLAYWRIGHT_BROWSERS_PATH="${PLAYWRIGHT_BROWSERS_PATH:-$HOME/.cache/ms-playwright}"
INSTALL_PLAYWRIGHT_DEPS=true
SETUP_DEVCONTAINER=true

# Utility functions
log() {
    echo "[$1] $2"
}

error() {
    log "ERROR" "$1" >&2
    exit 1
}

check_npm() {
    if ! command -v npm &>/dev/null; then
        error "npm is not installed. Please install Node.js from https://nodejs.org/"
    fi
    log "INFO" "npm found: $(npm --version)"
}

setup_npm_global() {
    log "INFO" "Setting up npm global directory..."
    
    # Create npm global directory if it doesn't exist
    if [[ ! -d "$NPM_GLOBAL_DIR" ]]; then
        mkdir -p "$NPM_GLOBAL_DIR"
        log "INFO" "Created npm global directory: $NPM_GLOBAL_DIR"
    fi
    
    # Configure npm to use the new prefix
    npm config set prefix "$NPM_GLOBAL_DIR"
    log "INFO" "npm global prefix set to: $NPM_GLOBAL_DIR"
}

update_path() {
    local shell=$(basename "$SHELL")
    local shell_rc=""
    
    case "$shell" in
        bash) shell_rc="$HOME/.bashrc" ;;
        zsh) shell_rc="$HOME/.zshrc" ;;
        *)
            log "WARN" "Unsupported shell: $shell. Please manually add $NPM_GLOBAL_DIR/bin to your PATH"
            return
            ;;
    esac
    
    # Check if shell rc file is writable (not a symlink or read-only)
    if [[ -L "$shell_rc" ]] || [[ ! -w "$shell_rc" ]]; then
        log "WARN" "Cannot modify $shell_rc (managed by system/Home Manager)"
        log "INFO" "Please manually add these lines to your shell configuration:"
        log "INFO" '  export PATH="$HOME/.npm-global/bin:$PATH"'
        log "INFO" '  [ -d "$HOME/.cargo/bin" ] && export PATH="$HOME/.cargo/bin:$PATH"'
        
        # Export for current session
        export PATH="$HOME/.npm-global/bin:$PATH"
        [[ -d "$HOME/.cargo/bin" ]] && export PATH="$HOME/.cargo/bin:$PATH"
        return
    fi
    
    # Function to safely append to shell config
    safe_append() {
        local text="$1"
        if ! grep -qF "$text" "$shell_rc" 2>/dev/null; then
            echo "$text" >> "$shell_rc"
            log "INFO" "Added to $shell_rc: $text"
        fi
    }
    
    # Add npm global bin to PATH
    safe_append 'export PATH="$HOME/.npm-global/bin:$PATH"'
    
    # Add cargo/uv bin to PATH if it exists
    safe_append '[ -d "$HOME/.cargo/bin" ] && export PATH="$HOME/.cargo/bin:$PATH"'
}

setup_devcontainer_config() {
    if [[ "$SETUP_DEVCONTAINER" != "true" ]]; then
        return
    fi
    
    log "INFO" "Setting up devcontainer configuration for Playwright..."
    
    # Create .devcontainer directory
    local devcontainer_dir="$SCRIPT_DIR/.devcontainer"
    mkdir -p "$devcontainer_dir"
    
    # Create devcontainer.json
    cat > "$devcontainer_dir/devcontainer.json" << 'EOF'
{
    "name": "Development Container with Playwright",
    "image": "mcr.microsoft.com/playwright:v1.40.0-jammy",
    
    // Or use a Dockerfile
    // "build": {
    //     "dockerfile": "Dockerfile"
    // },
    
    "features": {
        "ghcr.io/devcontainers/features/node:1": {
            "version": "lts"
        },
        "ghcr.io/devcontainers/features/common-utils:2": {
            "installZsh": true,
            "configureZshAsDefaultShell": true,
            "installOhMyZsh": true,
            "username": "vscode",
            "userUid": "1000",
            "userGid": "1000"
        }
    },
    
    "customizations": {
        "vscode": {
            "extensions": [
                "ms-playwright.playwright",
                "dbaeumer.vscode-eslint",
                "esbenp.prettier-vscode"
            ],
            "settings": {
                "terminal.integrated.defaultProfile.linux": "zsh"
            }
        }
    },
    
    "postCreateCommand": "npm install && npx playwright install-deps && npx playwright install",
    
    "mounts": [
        "source=${localEnv:HOME}/.npm-global,target=/home/vscode/.npm-global,type=bind,consistency=cached",
        "source=${localEnv:HOME}/.cache/ms-playwright,target=/home/vscode/.cache/ms-playwright,type=bind,consistency=cached",
        "source=${localEnv:HOME}/.context7,target=/home/vscode/.context7,type=bind,consistency=cached",
        "source=${localEnv:HOME}/.memorybank,target=/home/vscode/.memorybank,type=bind,consistency=cached",
        "source=${localEnv:HOME}/.mcp-memory,target=/home/vscode/.mcp-memory,type=bind,consistency=cached",
        "source=${localEnv:HOME}/.serena,target=/home/vscode/.serena,type=bind,consistency=cached",
        "source=${localEnv:HOME}/.git-mcp,target=/home/vscode/.git-mcp,type=bind,consistency=cached"
    ],
    
    "remoteEnv": {
        "PLAYWRIGHT_BROWSERS_PATH": "/home/vscode/.cache/ms-playwright",
        "PATH": "/home/vscode/.npm-global/bin:${containerEnv:PATH}",
        "GITHUB_TOKEN": "${localEnv:GITHUB_TOKEN}"
    },
    
    "forwardPorts": [3000, 8080, 9323],
    
    "remoteUser": "vscode"
}
EOF
    
    log "INFO" "Created devcontainer.json at: $devcontainer_dir/devcontainer.json"
    
    # Create Dockerfile for custom devcontainer
    cat > "$devcontainer_dir/Dockerfile" << 'EOF'
FROM mcr.microsoft.com/playwright:v1.40.0-jammy

# Install additional tools
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    vim \
    build-essential \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install global npm packages
RUN npm install -g \
    typescript \
    @playwright/test \
    eslint \
    prettier

# Set up non-root user
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Set the default user
USER $USERNAME

# Ensure Playwright browsers are installed
RUN npx playwright install-deps
EOF
    
    log "INFO" "Created Dockerfile at: $devcontainer_dir/Dockerfile"
    
    # Create a sample Playwright config for devcontainer
    cat > "$SCRIPT_DIR/playwright.config.js" << 'EOF'
// @ts-check
const { defineConfig, devices } = require('@playwright/test');

module.exports = defineConfig({
  testDir: './tests',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',
  
  use: {
    trace: 'on-first-retry',
    // Use headless mode in devcontainer
    headless: true,
  },

  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },
  ],

  // Run local dev server before starting tests
  // webServer: {
  //   command: 'npm run start',
  //   port: 3000,
  // },
});
EOF
    
    log "INFO" "Created sample playwright.config.js"
}

install_playwright_browsers() {
    log "INFO" "Installing Playwright browsers..."
    
    # Set Playwright browsers path
    export PLAYWRIGHT_BROWSERS_PATH="$PLAYWRIGHT_BROWSERS_PATH"
    log "INFO" "Playwright browsers will be installed to: $PLAYWRIGHT_BROWSERS_PATH"
    
    # Install Playwright
    if npm install -g playwright; then
        log "INFO" "Playwright package installed successfully"
        
        # Install browsers
        if npx playwright install chromium webkit firefox; then
            log "INFO" "Playwright browsers installed successfully"
        else
            log "WARN" "Failed to install some Playwright browsers"
        fi
        
        # Install system dependencies if on Linux
        if [[ "$OSTYPE" == "linux-gnu"* ]] && [[ "$INSTALL_PLAYWRIGHT_DEPS" == "true" ]]; then
            log "INFO" "Installing Playwright system dependencies..."
            if command -v apt-get &>/dev/null; then
                # Debian/Ubuntu
                if sudo npx playwright install-deps; then
                    log "INFO" "Playwright dependencies installed successfully"
                else
                    log "WARN" "Failed to install Playwright dependencies. You may need to install them manually."
                fi
            else
                log "WARN" "Non-Debian system detected. Please install Playwright dependencies manually."
                log "INFO" "See: https://playwright.dev/docs/cli#install-system-dependencies"
            fi
        fi
    else
        log "WARN" "Failed to install Playwright package"
    fi
}


install_claude() {
    log "INFO" "Checking Claude Code installation..."
    
    # Check if Claude Code is already installed
    if command -v claude &>/dev/null; then
        log "INFO" "Claude Code is already installed"
        log "INFO" "Current version: $(claude --version 2>/dev/null || echo 'unknown')"
        log "INFO" "Location: $(which claude)"
        
        # Skip npm installation if Claude is installed via system package manager
        if [[ "$(which claude)" == /nix/* ]] || [[ "$(which claude)" == /usr/* ]]; then
            log "INFO" "Claude Code is installed via system package manager, skipping npm installation"
            return
        fi
        
        read -p "Do you want to reinstall/update via npm? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return
        fi
    fi
    
    # Install Claude Code
    log "INFO" "Installing Claude Code via npm..."
    if npm install -g "$CLAUDE_PACKAGE"; then
        log "INFO" "Claude Code installed successfully"
        log "INFO" "Version: $(claude --version 2>/dev/null || echo 'installed')"
    else
        error "Failed to install Claude Code"
    fi
}

check_github_token() {
    log "INFO" "Checking GitHub token configuration..."
    
    # Check if GITHUB_TOKEN is set
    if [[ -z "${GITHUB_TOKEN}" ]]; then
        log "WARN" "GITHUB_TOKEN environment variable is not set"
        log "INFO" "The GitHub MCP server requires a GitHub personal access token"
        log "INFO" "To create one:"
        log "INFO" "  1. Go to https://github.com/settings/tokens"
        log "INFO" "  2. Click 'Generate new token (classic)'"
        log "INFO" "  3. Select scopes: repo, read:org, read:user"
        log "INFO" "  4. Generate and copy the token"
        log "INFO" "  5. Add to your shell config: export GITHUB_TOKEN='your_token_here'"
        echo
        read -p "Do you have a GitHub token to set now? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            read -sp "Enter your GitHub token: " github_token
            echo
            if [[ -n "$github_token" ]]; then
                export GITHUB_TOKEN="$github_token"
                
                # Add to shell config
                local shell=$(basename "$SHELL")
                local shell_rc=""
                case "$shell" in
                    bash) shell_rc="$HOME/.bashrc" ;;
                    zsh) shell_rc="$HOME/.zshrc" ;;
                esac
                
                if [[ -n "$shell_rc" ]]; then
                    # Check if shell rc is writable
                    if [[ -L "$shell_rc" ]] || [[ ! -w "$shell_rc" ]]; then
                        log "WARN" "Cannot save GITHUB_TOKEN to $shell_rc (managed by system)"
                        log "INFO" "Please manually add to your shell configuration:"
                        log "INFO" "  export GITHUB_TOKEN='$github_token'"
                    else
                        echo "export GITHUB_TOKEN='$github_token'" >> "$shell_rc"
                        log "INFO" "Added GITHUB_TOKEN to $shell_rc"
                    fi
                fi
            fi
        else
            log "WARN" "GitHub MCP server will be installed but won't work without a token"
        fi
    else
        log "INFO" "GitHub token found in environment"
    fi
}

check_context7_config() {
    log "INFO" "Setting up Context7 MCP server..."
    
    # Create Context7 config directory
    local context7_config_dir="$HOME/.context7"
    mkdir -p "$context7_config_dir"
    
    # Check if Context7 config exists
    local context7_config="$context7_config_dir/config.json"
    if [[ ! -f "$context7_config" ]]; then
        log "INFO" "Creating Context7 configuration..."
        
        # Create default config
        cat > "$context7_config" << 'EOF'
{
  "workspaces": [
    {
      "name": "default",
      "path": "~/projects",
      "description": "Default workspace for projects"
    }
  ],
  "settings": {
    "indexing": {
      "enabled": true,
      "excludePatterns": [
        "**/node_modules/**",
        "**/.git/**",
        "**/dist/**",
        "**/build/**",
        "**/*.log",
        "**/.DS_Store"
      ],
      "includePatterns": [
        "**/*.js",
        "**/*.ts",
        "**/*.jsx",
        "**/*.tsx",
        "**/*.py",
        "**/*.go",
        "**/*.rs",
        "**/*.java",
        "**/*.cpp",
        "**/*.c",
        "**/*.h",
        "**/*.md",
        "**/*.json",
        "**/*.yaml",
        "**/*.yml",
        "**/*.toml",
        "**/*.xml",
        "**/*.html",
        "**/*.css",
        "**/*.scss",
        "**/*.sass"
      ]
    },
    "search": {
      "maxResults": 100,
      "contextLines": 3
    }
  }
}
EOF
        log "INFO" "Created default Context7 config at: $context7_config"
        
        # Ask if user wants to configure workspaces
        echo
        read -p "Would you like to add a custom workspace path? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            read -p "Enter workspace path (e.g., ~/Code): " workspace_path
            if [[ -n "$workspace_path" ]]; then
                # Expand tilde to home directory
                workspace_path="${workspace_path/#\~/$HOME}"
                
                # Update config with custom path
                jq --arg path "$workspace_path" '.workspaces[0].path = $path' "$context7_config" > "$context7_config.tmp" && mv "$context7_config.tmp" "$context7_config"
                log "INFO" "Updated workspace path to: $workspace_path"
            fi
        fi
    else
        log "INFO" "Context7 config already exists at: $context7_config"
    fi
}

setup_memorybank() {
    log "INFO" "Setting up MemoryBank MCP server..."
    
    # Create MemoryBank data directory
    local memorybank_dir="$HOME/.memorybank"
    mkdir -p "$memorybank_dir"
    mkdir -p "$memorybank_dir/memories"
    mkdir -p "$memorybank_dir/templates"
    
    # Create default configuration
    local memorybank_config="$memorybank_dir/config.json"
    if [[ ! -f "$memorybank_config" ]]; then
        log "INFO" "Creating MemoryBank configuration..."
        
        cat > "$memorybank_config" << 'EOF'
{
  "dataPath": "~/.memorybank/memories",
  "templatesPath": "~/.memorybank/templates",
  "settings": {
    "maxMemorySize": 10485760,
    "autoSave": true,
    "saveInterval": 300000,
    "encryption": false,
    "compression": true,
    "versioning": {
      "enabled": true,
      "maxVersions": 10
    },
    "categories": [
      "personal",
      "work",
      "projects",
      "learning",
      "code-snippets",
      "documentation",
      "conversations",
      "ideas"
    ]
  }
}
EOF
        log "INFO" "Created MemoryBank config at: $memorybank_config"
    else
        log "INFO" "MemoryBank config already exists at: $memorybank_config"
    fi
    
    # Create sample memory templates
    local templates_dir="$memorybank_dir/templates"
    
    # Project template
    cat > "$templates_dir/project.json" << 'EOF'
{
  "name": "Project Template",
  "fields": {
    "title": "",
    "description": "",
    "status": "active",
    "startDate": "",
    "technologies": [],
    "goals": [],
    "notes": ""
  }
}
EOF
    
    # Code snippet template
    cat > "$templates_dir/code-snippet.json" << 'EOF'
{
  "name": "Code Snippet Template",
  "fields": {
    "title": "",
    "language": "",
    "description": "",
    "code": "",
    "tags": [],
    "usage": "",
    "source": ""
  }
}
EOF
    
    # Learning note template
    cat > "$templates_dir/learning-note.json" << 'EOF'
{
  "name": "Learning Note Template",
  "fields": {
    "topic": "",
    "summary": "",
    "keyPoints": [],
    "resources": [],
    "questions": [],
    "date": ""
  }
}
EOF
    
    log "INFO" "Created memory templates in: $templates_dir"
}

setup_sequential_memory() {
    log "INFO" "Setting up Sequential Thinking Memory MCP server..."
    
    # Create memory directory for sequential thinking
    local memory_dir="$HOME/.mcp-memory"
    mkdir -p "$memory_dir"
    mkdir -p "$memory_dir/thoughts"
    mkdir -p "$memory_dir/knowledge"
    
    # Create configuration
    local memory_config="$memory_dir/config.json"
    if [[ ! -f "$memory_config" ]]; then
        log "INFO" "Creating Sequential Memory configuration..."
        
        cat > "$memory_config" << 'EOF'
{
  "memoryPath": "~/.mcp-memory",
  "settings": {
    "maxThoughts": 1000,
    "maxKnowledgeEntries": 5000,
    "persistThoughts": true,
    "autoCleanup": true,
    "cleanupAge": 2592000000,
    "thoughtRetention": {
      "important": "permanent",
      "normal": "30d",
      "temporary": "24h"
    }
  }
}
EOF
        log "INFO" "Created Sequential Memory config at: $memory_config"
    else
        log "INFO" "Sequential Memory config already exists at: $memory_config"
    fi
    
    # Create initial structure files
    local thoughts_index="$memory_dir/thoughts/index.json"
    if [[ ! -f "$thoughts_index" ]]; then
        echo '{"thoughts": [], "lastUpdated": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"}' > "$thoughts_index"
    fi
    
    local knowledge_index="$memory_dir/knowledge/index.json"
    if [[ ! -f "$knowledge_index" ]]; then
        echo '{"entries": {}, "lastUpdated": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"}' > "$knowledge_index"
    fi
    
    log "INFO" "Sequential Memory setup complete"
}

check_uvx() {
    log "INFO" "Checking for uvx (Python package runner)..."
    
    if ! command -v uvx &>/dev/null; then
        log "WARN" "uvx is not installed. Installing uv..."
        
        # Install uv (which includes uvx)
        if curl -LsSf https://astral.sh/uv/install.sh | sh; then
            log "INFO" "uv installed successfully"
            # Add to PATH for current session
            export PATH="$HOME/.cargo/bin:$PATH"
        else
            error "Failed to install uv. Please install it manually from https://github.com/astral-sh/uv"
        fi
    else
        log "INFO" "uvx found: $(uvx --version 2>/dev/null || echo 'installed')"
    fi
}

setup_serena() {
    log "INFO" "Setting up Serena MCP server..."
    
    # Check for uvx
    check_uvx
    
    # Get the default project directory
    local default_project_dir="$HOME/projects"
    local project_dir=""
    
    echo
    log "INFO" "Serena requires a project directory to work with"
    read -p "Enter your default project directory (default: $default_project_dir): " project_dir
    project_dir="${project_dir:-$default_project_dir}"
    
    # Expand tilde to home directory
    project_dir="${project_dir/#\~/$HOME}"
    
    # Create project directory if it doesn't exist
    if [[ ! -d "$project_dir" ]]; then
        mkdir -p "$project_dir"
        log "INFO" "Created project directory: $project_dir"
    fi
    
    # Store configuration for Serena
    local serena_config_dir="$HOME/.serena"
    mkdir -p "$serena_config_dir"
    
    cat > "$serena_config_dir/config.json" << EOF
{
  "defaultProject": "$project_dir",
  "context": "ide-assistant",
  "settings": {
    "autoSync": true,
    "enableCodeAnalysis": true,
    "enableRefactoring": true,
    "enableTesting": true
  }
}
EOF
    
    log "INFO" "Created Serena config at: $serena_config_dir/config.json"
    log "INFO" "Default project directory: $project_dir"
    
    # Export for use in install
    export SERENA_PROJECT_DIR="$project_dir"
}

setup_git_mcp() {
    log "INFO" "Setting up Git MCP server..."
    
    # Create git MCP config directory
    local git_mcp_dir="$HOME/.git-mcp"
    mkdir -p "$git_mcp_dir"
    
    # Get repository directories
    local repos_config="$git_mcp_dir/repositories.json"
    local repos=()
    
    echo
    log "INFO" "Git MCP needs to know which repositories to work with"
    log "INFO" "Enter repository paths (press Enter without input to finish):"
    
    while true; do
        read -p "Repository path (or Enter to finish): " repo_path
        [[ -z "$repo_path" ]] && break
        
        # Expand tilde to home directory
        repo_path="${repo_path/#\~/$HOME}"
        
        # Validate it's a git repository
        if [[ -d "$repo_path/.git" ]]; then
            repos+=("$repo_path")
            log "INFO" "Added repository: $repo_path"
        else
            log "WARN" "$repo_path is not a git repository"
        fi
    done
    
    # Add default repositories if none specified
    if [[ ${#repos[@]} -eq 0 ]]; then
        log "INFO" "No repositories specified, adding defaults..."
        # Add common repository locations
        for default_repo in "$HOME/projects" "$HOME/Code" "$HOME/work" "$HOME/dev"; do
            if [[ -d "$default_repo" ]]; then
                # Find git repositories in the directory
                while IFS= read -r -d '' git_dir; do
                    repo_dir=$(dirname "$git_dir")
                    repos+=("$repo_dir")
                    log "INFO" "Found repository: $repo_dir"
                done < <(find "$default_repo" -maxdepth 3 -type d -name ".git" -print0 2>/dev/null)
            fi
        done
    fi
    
    # Create repositories config
    cat > "$repos_config" << EOF
{
  "repositories": [
$(printf '    "%s"' "${repos[@]}" | sed '$!s/$/,/')
  ],
  "settings": {
    "autoFetch": false,
    "showHidden": false,
    "maxCommits": 100
  }
}
EOF
    
    log "INFO" "Created Git MCP config with ${#repos[@]} repositories"
}

install_mcp_servers() {
    if [[ ${#MCP_SERVERS[@]} -eq 0 ]]; then
        log "INFO" "No MCP servers configured for installation"
        return
    fi
    
    log "INFO" "Installing MCP servers..."
    log "DEBUG" "Number of servers to install: ${#MCP_SERVERS[@]}"
    
    # Check if claude command exists
    if ! command -v claude &>/dev/null; then
        error "Claude Code must be installed before adding MCP servers"
    fi
    
    log "DEBUG" "Claude found, checking server-specific configurations..."
    
    # Check for server-specific configurations
    for server_config in "${MCP_SERVERS[@]}"; do
        if [[ "$server_config" == github:* ]]; then
            check_github_token
        elif [[ "$server_config" == context7:* ]]; then
            check_context7_config
        elif [[ "$server_config" == memorybank:* ]]; then
            setup_memorybank
        elif [[ "$server_config" == memory:* ]]; then
            setup_sequential_memory
        elif [[ "$server_config" == serena:* ]]; then
            setup_serena
        elif [[ "$server_config" == git:* ]]; then
            setup_git_mcp
        fi
    done
    
    # Install each MCP server
    for server_config in "${MCP_SERVERS[@]}"; do
        # Split the config into name and command
        IFS=':' read -r server_name server_command <<< "$server_config"
        
        log "INFO" "Adding MCP server: $server_name"
        
        # Handle special cases
        if [[ "$server_name" == "serena" ]]; then
            # Special handling for Serena with custom command
            local project_dir="${SERENA_PROJECT_DIR:-$(pwd)}"
            if claude mcp add serena -- uvx --from git+https://github.com/oraios/serena serena-mcp-server --context ide-assistant --project "$project_dir"; then
                log "INFO" "Successfully added Serena MCP server with project: $project_dir"
            else
                log "WARN" "Failed to add Serena MCP server"
            fi
        else
            # Standard installation
            if claude mcp add "$server_name" $server_command; then
                log "INFO" "Successfully added MCP server: $server_name"
            else
                log "WARN" "Failed to add MCP server: $server_name"
            fi
        fi
    done
}

show_mcp_servers() {
    log "INFO" "Current MCP servers:"
    claude mcp list 2>/dev/null || log "WARN" "Could not list MCP servers"
}

print_next_steps() {
    echo
    echo "========================================"
    echo "Setup complete!"
    echo "========================================"
    echo
    echo "Next steps:"
    echo "1. Restart your terminal or run: source ~/.${SHELL##*/}rc"
    echo "2. Verify Claude Code is installed: claude --version"
    echo "3. List MCP servers: claude mcp list"
    echo "4. Add more MCP servers: claude mcp add <name> <command>"
    echo
    
    # Show Playwright-specific instructions if installed
    for server_config in "${MCP_SERVERS[@]}"; do
        if [[ "$server_config" == playwright:* ]]; then
            echo "Playwright MCP Setup:"
            echo "- Browsers installed at: $PLAYWRIGHT_BROWSERS_PATH"
            echo "- Test Playwright locally: npx playwright --version"
            
            if [[ "$SETUP_DEVCONTAINER" == "true" ]]; then
                echo
                echo "DevContainer Support for Playwright:"
                echo "- DevContainer config: $SCRIPT_DIR/.devcontainer/"
                echo "- Playwright config: $SCRIPT_DIR/playwright.config.js"
                echo
                echo "To use in VS Code:"
                echo "1. Open your project in VS Code"
                echo "2. Install 'Dev Containers' extension"
                echo "3. Run command: 'Dev Containers: Reopen in Container'"
                echo "4. Inside container: npx playwright test"
                echo
                echo "The devcontainer includes:"
                echo "- All Playwright browsers pre-installed"
                echo "- Node.js LTS and npm"
                echo "- Playwright VS Code extension"
                echo "- Persistent browser cache via volume mounts"
            fi
            echo
            break
        fi
    done
    
    # Show server-specific instructions
    for server_config in "${MCP_SERVERS[@]}"; do
        if [[ "$server_config" == github:* ]]; then
            echo "GitHub MCP Server:"
            if [[ -n "${GITHUB_TOKEN}" ]]; then
                echo "- GitHub token is configured ✓"
            else
                echo "- GitHub token is NOT configured ✗"
                echo "- Set it with: export GITHUB_TOKEN='your_token_here'"
            fi
            echo "- Usage: The GitHub MCP allows Claude to:"
            echo "  * Read repository contents"
            echo "  * List repositories and organizations"
            echo "  * Access issues and pull requests"
            echo "  * Search code across repositories"
            echo
        elif [[ "$server_config" == context7:* ]]; then
            echo "Context7 MCP Server:"
            echo "- Config location: ~/.context7/config.json"
            echo "- Usage: Context7 provides advanced code search and context:"
            echo "  * Deep code search across workspaces"
            echo "  * Semantic code understanding"
            echo "  * Project-wide context awareness"
            echo "  * Intelligent file navigation"
            echo "  * Code pattern recognition"
            echo "- Manage workspaces: Edit ~/.context7/config.json"
            echo
        elif [[ "$server_config" == memorybank:* ]]; then
            echo "MemoryBank MCP Server:"
            echo "- Data location: ~/.memorybank/"
            echo "- Config: ~/.memorybank/config.json"
            echo "- Usage: MemoryBank helps Claude remember across sessions:"
            echo "  * Store and retrieve memories"
            echo "  * Organize information by categories"
            echo "  * Create structured memory templates"
            echo "  * Version control for memories"
            echo "  * Search and filter stored knowledge"
            echo "- Categories: personal, work, projects, learning, code-snippets"
            echo
        elif [[ "$server_config" == memory:* ]]; then
            echo "Sequential Thinking Memory MCP Server:"
            echo "- Data location: ~/.mcp-memory/"
            echo "- Config: ~/.mcp-memory/config.json"
            echo "- Usage: Enables Claude's sequential thinking capabilities:"
            echo "  * Track thoughts during problem-solving"
            echo "  * Build knowledge incrementally"
            echo "  * Maintain context across reasoning steps"
            echo "  * Store important insights permanently"
            echo "  * Auto-cleanup temporary thoughts"
            echo "- Retention: permanent (important), 30d (normal), 24h (temporary)"
            echo
        elif [[ "$server_config" == serena:* ]]; then
            echo "Serena IDE Assistant MCP Server:"
            echo "- Config location: ~/.serena/config.json"
            if [[ -f "$HOME/.serena/config.json" ]]; then
                local project_dir=$(jq -r '.defaultProject' "$HOME/.serena/config.json" 2>/dev/null || echo "unknown")
                echo "- Default project: $project_dir"
            fi
            echo "- Context: ide-assistant"
            echo "- Usage: Serena provides advanced IDE capabilities:"
            echo "  * Code analysis and understanding"
            echo "  * Refactoring suggestions"
            echo "  * Test generation and execution"
            echo "  * Project-aware code completion"
            echo "  * Intelligent code navigation"
            echo "  * Architecture insights"
            echo "- Requires: uvx (Python package runner)"
            echo
        elif [[ "$server_config" == time:* ]]; then
            echo "Time MCP Server:"
            echo "- Usage: Provides time and date utilities:"
            echo "  * Get current time in any timezone"
            echo "  * Convert between timezones"
            echo "  * Calculate time differences"
            echo "  * Format dates and times"
            echo "  * Set timers and reminders"
            echo "  * Work with Unix timestamps"
            echo
        elif [[ "$server_config" == git:* ]]; then
            echo "Git MCP Server:"
            echo "- Config location: ~/.git-mcp/repositories.json"
            if [[ -f "$HOME/.git-mcp/repositories.json" ]]; then
                local repo_count=$(jq '.repositories | length' "$HOME/.git-mcp/repositories.json" 2>/dev/null || echo "0")
                echo "- Configured repositories: $repo_count"
            fi
            echo "- Usage: Git repository operations:"
            echo "  * View commit history"
            echo "  * Check file changes and diffs"
            echo "  * Branch management"
            echo "  * Repository status"
            echo "  * Blame and log analysis"
            echo "  * Search commits and content"
            echo "- Note: Works with local repositories only"
            echo
        fi
    done
    
    echo "Example MCP servers you can add:"
    echo "  claude mcp add filesystem npx @modelcontextprotocol/server-filesystem /path/to/allow"
    echo "  claude mcp add postgres npx @modelcontextprotocol/server-postgres postgresql://localhost/mydb"
    echo "  claude mcp add sqlite npx @modelcontextprotocol/server-sqlite /path/to/database.db"
    echo
}

main() {
    log "INFO" "Starting Claude Code and MCP servers setup..."
    
    log "DEBUG" "Step 1: Checking npm..."
    check_npm
    
    log "DEBUG" "Step 2: Setting up npm global..."
    setup_npm_global
    
    log "DEBUG" "Step 3: Updating PATH..."
    update_path
    
    log "DEBUG" "Step 4: Installing Claude..."
    install_claude
    
    log "DEBUG" "Step 5: Installing MCP servers..."
    install_mcp_servers
    
    log "DEBUG" "Step 6: Setting up devcontainer..."
    
    # Setup devcontainer and install Playwright browsers if playwright MCP is being installed
    for server_config in "${MCP_SERVERS[@]}"; do
        if [[ "$server_config" == playwright:* ]]; then
            install_playwright_browsers
            setup_devcontainer_config
            break
        fi
    done
    
    show_mcp_servers
    print_next_steps
}

# Run main function
main "$@"