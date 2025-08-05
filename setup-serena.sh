#!/usr/bin/env bash

# Improved Serena MCP Server Setup Script
# Based on https://github.com/oraios/serena

set -euo pipefail

# Colors
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
NC="\033[0m"

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
}

# Check if uvx is available
if ! command -v uvx &>/dev/null; then
    log "ERROR" "uvx not found. Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.cargo/bin:$PATH"
fi

# Check if Claude CLI is available
if ! command -v claude &>/dev/null; then
    log "ERROR" "Claude CLI not found. Please install it first."
    exit 1
fi

log "INFO" "Setting up improved Serena MCP Server..."

# Create Serena directories
SERENA_HOME="$HOME/.serena"
SERENA_PROJECTS="$HOME/.serena/projects"
mkdir -p "$SERENA_HOME"
mkdir -p "$SERENA_PROJECTS"

# Function to detect project directory and environment variables
detect_project_environment() {
    local detected_project=""
    local env_files=()

    # Look for .env files in common locations
    local possible_env_files=(
        ".env"
        ".devcontainer/.env"
        ".env.local"
        ".env.development"
        ".env.production"
        ".env.staging"
    )

    for env_file in "${possible_env_files[@]}"; do
        if [[ -f "$env_file" ]]; then
            env_files+=("$env_file")
            log "INFO" "Found environment file: $env_file"
        fi
    done

    # Load environment variables from found files
    for env_file in "${env_files[@]}"; do
        if [[ -f "$env_file" ]]; then
            log "INFO" "Loading environment variables from $env_file"
            # Export variables from .env file
            set -a
            source "$env_file"
            set +a
        fi
    done

    # Detect project directory from various sources
    local possible_project_dirs=(
        "${SERENA_PROJECT_DIR:-}"
        "${PROJECT_DIR:-}"
        "${WORKSPACE_DIR:-}"
        "/workspace"
        "/workspaces"
        "$HOME/workspace"
        "$HOME/workspaces"
        "$PWD"
    )

    for dir in "${possible_project_dirs[@]}"; do
        if [[ -n "$dir" && -d "$dir" ]]; then
            # Check if it looks like a project directory
            if [[ -f "$dir/package.json" || -f "$dir/pyproject.toml" || -f "$dir/go.mod" || -f "$dir/Cargo.toml" || -f "$dir/pom.xml" || -f "$dir/requirements.txt" ]]; then
                detected_project="$dir"
                log "SUCCESS" "Detected project directory: $detected_project"
                break
            elif [[ -d "$dir/src" || -d "$dir/app" || -d "$dir/lib" || -d "$dir/service" ]]; then
                detected_project="$dir"
                log "SUCCESS" "Detected project directory: $detected_project"
                break
            fi
        fi
    done

    # If no project detected, use default
    if [[ -z "$detected_project" ]]; then
        detected_project="$HOME/workspace"
        log "INFO" "No project directory detected, using default: $detected_project"
    fi

    echo "$detected_project"
}

# Function to generate Serena configuration based on project type
generate_serena_config() {
    local project_dir="$1"
    local config_file="$2"

    # Detect project type and languages
    local languages=()
    local file_patterns=()
    local exclude_patterns=()

    # Check for Python projects
    if [[ -f "$project_dir/pyproject.toml" || -f "$project_dir/requirements.txt" || -f "$project_dir/setup.py" ]]; then
        languages+=("python")
        file_patterns+=("**/*.py")
        exclude_patterns+=("**/__pycache__/**" "**/*.pyc" "**/.venv/**" "**/venv/**" "**/.mypy_cache/**" "**/.ruff_cache/**")
        log "INFO" "Detected Python project"
    fi

    # Check for Node.js projects
    if [[ -f "$project_dir/package.json" ]]; then
        languages+=("javascript" "typescript")
        file_patterns+=("**/*.js" "**/*.ts" "**/*.jsx" "**/*.tsx")
        exclude_patterns+=("**/node_modules/**" "**/dist/**" "**/build/**" "**/.next/**" "**/.nuxt/**")
        log "INFO" "Detected Node.js project"
    fi

    # Check for Go projects
    if [[ -f "$project_dir/go.mod" ]]; then
        languages+=("go")
        file_patterns+=("**/*.go")
        exclude_patterns+=("**/vendor/**")
        log "INFO" "Detected Go project"
    fi

    # Check for Rust projects
    if [[ -f "$project_dir/Cargo.toml" ]]; then
        languages+=("rust")
        file_patterns+=("**/*.rs")
        exclude_patterns+=("**/target/**")
        log "INFO" "Detected Rust project"
    fi

    # Check for Java projects
    if [[ -f "$project_dir/pom.xml" || -f "$project_dir/build.gradle" ]]; then
        languages+=("java")
        file_patterns+=("**/*.java")
        exclude_patterns+=("**/target/**" "**/build/**" "**/.gradle/**")
        log "INFO" "Detected Java project"
    fi

    # Check for C/C++ projects
    if [[ -f "$project_dir/CMakeLists.txt" || -f "$project_dir/Makefile" ]]; then
        languages+=("cpp")
        file_patterns+=("**/*.c" "**/*.cpp" "**/*.h" "**/*.hpp")
        exclude_patterns+=("**/build/**" "**/cmake-build-*/**")
        log "INFO" "Detected C/C++ project"
    fi

    # Default languages if none detected
    if [[ ${#languages[@]} -eq 0 ]]; then
        languages=("python" "javascript" "typescript" "go" "rust" "java" "cpp")
        file_patterns=("**/*.py" "**/*.js" "**/*.ts" "**/*.go" "**/*.rs" "**/*.java" "**/*.c" "**/*.cpp")
        log "INFO" "No specific project type detected, using default languages"
    fi

    # Convert arrays to YAML format
    local languages_yaml=$(printf "    - %s\n" "${languages[@]}")
    local patterns_yaml=$(printf "    - %s\n" "${file_patterns[@]}")
    local excludes_yaml=$(printf "    - %s\n" "${exclude_patterns[@]}")

    # Generate configuration
    cat > "$config_file" <<EOF
# Serena Configuration
# Auto-generated based on project analysis

# Project configuration
project: $project_dir
context: ide-assistant

# Language server configuration
language_server:
  enabled: true
  languages:
$languages_yaml

# Web dashboard configuration
web_dashboard:
  enabled: true
  port: 8080
  host: localhost

# Log window configuration
log_window:
  enabled: true
  port: 8081
  host: localhost

# Tool usage statistics
record_tool_usage_stats: true

# Memory configuration
memory:
  enabled: true
  max_memories: 100

# Optional tools (disabled by default for security)
included_optional_tools:
  - execute_shell_command
  # - initial_instructions  # Uncomment to enable initial instructions

# Modes configuration
modes:
  default:
    - code_analysis
    - file_operations
    - memory_operations
  development:
    - code_analysis
    - file_operations
    - memory_operations
    - shell_operations
  debugging:
    - code_analysis
    - file_operations
    - memory_operations
    - shell_operations
    - language_server_operations

# File operations configuration
file_operations:
  allowed_extensions:
    - .py
    - .js
    - .ts
    - .jsx
    - .tsx
    - .go
    - .rs
    - .java
    - .cpp
    - .c
    - .h
    - .hpp
    - .cs
    - .md
    - .json
    - .yaml
    - .yml
    - .toml
    - .xml
    - .html
    - .css
    - .scss
    - .sass

# Project-specific file patterns
file_patterns:
  include:
$patterns_yaml
  exclude:
$excludes_yaml
    - .git/**/*
    - *.log
    - *.tmp
    - *.cache

# Security settings
security:
  # Restrict file operations to project directory
  restrict_to_project: true
  # Allow shell commands (use with caution)
  allow_shell_commands: false
  # Maximum file size for operations (in bytes)
  max_file_size: 10485760  # 10MB

# Performance settings
performance:
  # Maximum number of files to process in parallel
  max_parallel_files: 10
  # Cache language server responses
  enable_caching: true
  # Cache timeout (in seconds)
  cache_timeout: 3600

# Logging configuration
logging:
  level: info
  file: $SERENA_HOME/serena.log
  max_file_size: 10485760  # 10MB
  max_files: 5
EOF
}

# Detect project directory and environment
log "INFO" "Detecting project environment..."
PROJECT_DIR=$(detect_project_environment)

# Create project directory if it doesn't exist
mkdir -p "$PROJECT_DIR"

log "SUCCESS" "Using project directory: $PROJECT_DIR"

# Generate Serena configuration based on project analysis
log "INFO" "Generating Serena configuration based on project analysis..."
generate_serena_config "$PROJECT_DIR" "$SERENA_HOME/serena_config.yml"

# Create project-specific configuration template
cat > "$SERENA_HOME/project_template.yml" <<EOF
# Project-specific Serena configuration template
# Copy this to your project directory as .serena/project.yml

project_name: "your-project-name"
description: "Your project description"

# Project-specific tools
tools:
  - code_analysis
  - file_operations
  - memory_operations

# Project-specific modes
modes:
  development:
    - code_analysis
    - file_operations
    - memory_operations
    - shell_operations

# Project-specific file patterns
file_patterns:
  include:
    - "src/**/*"
    - "lib/**/*"
    - "app/**/*"
  exclude:
    - "node_modules/**/*"
    - "dist/**/*"
    - "build/**/*"
    - ".git/**/*"
    - "*.log"
    - "*.tmp"

# Project-specific memory
memory:
  project_specific: true
  max_memories: 50
EOF

# Create a convenient Serena launcher script
cat > "$SERENA_HOME/serena-launcher.sh" <<'EOF'
#!/usr/bin/env bash

# Serena Launcher Script
# Usage: ./serena-launcher.sh [project_path] [mode]

set -euo pipefail

SERENA_HOME="$HOME/.serena"
DEFAULT_PROJECT="$HOME/workspace"
DEFAULT_MODE="development"

PROJECT_PATH="${1:-$DEFAULT_PROJECT}"
MODE="${2:-$DEFAULT_MODE}"

# Ensure project directory exists
mkdir -p "$PROJECT_PATH"

# Set environment variables
export SERENA_PROJECT_DIR="$PROJECT_PATH"
export SERENA_MODE="$MODE"

# Check if Serena is installed
if ! command -v uvx &>/dev/null; then
    echo "Error: uvx not found. Please install uv first."
    exit 1
fi

# Launch Serena MCP server
echo "Starting Serena MCP server..."
echo "Project: $PROJECT_PATH"
echo "Mode: $MODE"
echo "Web Dashboard: http://localhost:8080"
echo "Log Window: http://localhost:8081"

uvx --from git+https://github.com/oraios/serena serena-mcp-server \
    --context ide-assistant \
    --project "$PROJECT_PATH" \
    --mode "$MODE"
EOF

chmod +x "$SERENA_HOME/serena-launcher.sh"

# Create a project initialization script
cat > "$SERENA_HOME/init-project.sh" <<'EOF'
#!/usr/bin/env bash

# Serena Project Initialization Script
# Usage: ./init-project.sh [project_name] [project_path]

set -euo pipefail

PROJECT_NAME="${1:-$(basename "$PWD")}"
PROJECT_PATH="${2:-$PWD}"

SERENA_HOME="$HOME/.serena"
PROJECT_CONFIG_DIR="$PROJECT_PATH/.serena"

echo "Initializing Serena project: $PROJECT_NAME"
echo "Project path: $PROJECT_PATH"

# Create project-specific Serena directory
mkdir -p "$PROJECT_CONFIG_DIR"

# Copy project template
cp "$SERENA_HOME/project_template.yml" "$PROJECT_CONFIG_DIR/project.yml"

# Update project configuration
sed -i.bak "s/your-project-name/$PROJECT_NAME/g" "$PROJECT_CONFIG_DIR/project.yml"
rm -f "$PROJECT_CONFIG_DIR/project.yml.bak"

echo "✅ Serena project initialized!"
echo "📁 Configuration: $PROJECT_CONFIG_DIR/project.yml"
echo "🚀 Start Serena: $SERENA_HOME/serena-launcher.sh $PROJECT_PATH"
EOF

chmod +x "$SERENA_HOME/init-project.sh"

# Check if Serena is already installed in Claude
if claude mcp list 2>/dev/null | grep -q "^serena\b"; then
    log "INFO" "Serena MCP server already installed in Claude"
    log "INFO" "Updating Serena configuration..."

    # Remove existing Serena installation
    claude mcp remove serena 2>/dev/null || true

    # Reinstall with new configuration
    if claude mcp add --scope user serena -- uvx --from git+https://github.com/oraios/serena serena-mcp-server --context ide-assistant --project "$PROJECT_DIR"; then
        log "SUCCESS" "Serena MCP server updated successfully!"
    else
        log "ERROR" "Failed to update Serena MCP server"
        exit 1
    fi
else
    log "INFO" "Installing Serena MCP server to Claude..."

    if claude mcp add --scope user serena -- uvx --from git+https://github.com/oraios/serena serena-mcp-server --context ide-assistant --project "$PROJECT_DIR"; then
        log "SUCCESS" "Serena MCP server installed successfully!"
    else
        log "ERROR" "Failed to install Serena MCP server"
        exit 1
    fi
fi

# Create convenience scripts
cat > "$HOME/.local/bin/serena" <<'EOF'
#!/usr/bin/env bash
$HOME/.serena/serena-launcher.sh "$@"
EOF

cat > "$HOME/.local/bin/serena-init" <<'EOF'
#!/usr/bin/env bash
$HOME/.serena/init-project.sh "$@"
EOF

chmod +x "$HOME/.local/bin/serena"
chmod +x "$HOME/.local/bin/serena-init"

# Ensure ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc" 2>/dev/null || true
fi

log "SUCCESS" "Enhanced Serena setup complete! 🎉"
log "INFO" ""
log "INFO" "📁 Configuration: $SERENA_HOME/serena_config.yml"
log "INFO" "🚀 Quick start: serena [project_path] [mode]"
log "INFO" "📝 Initialize project: serena-init [project_name] [project_path]"
log "INFO" "🌐 Web Dashboard: http://localhost:8080"
log "INFO" "📋 Log Window: http://localhost:8081"
log "INFO" ""
log "INFO" "Available modes: development, debugging, default"
log "INFO" "Example: serena ~/my-project development"
log "INFO" ""
log "INFO" "Enhanced Features:"
log "INFO" "  ✅ Automatic project detection and environment loading"
log "INFO" "  ✅ .env file support (including .devcontainer/.env)"
log "INFO" "  ✅ Smart project type detection (Python, Node.js, Go, Rust, Java, C++)"
log "INFO" "  ✅ Auto-generated configuration based on project analysis"
log "INFO" "  ✅ Language server support (Python, JS, TS, Go, Rust, Java, C++)"
log "INFO" "  ✅ Web dashboard for monitoring"
log "INFO" "  ✅ Log window for debugging"
log "INFO" "  ✅ Project-specific configurations"
log "INFO" "  ✅ Memory system for context retention"
log "INFO" "  ✅ Security restrictions and file size limits"
log "INFO" "  ✅ Performance optimizations and caching"
log "INFO" "  ✅ Devcontainer integration"
log "INFO" ""
log "INFO" "Environment variables supported:"
log "INFO" "  - SERENA_PROJECT_DIR, PROJECT_DIR, WORKSPACE_DIR"
log "INFO" "  - Common devcontainer paths: /workspace, /workspaces"
log "INFO" "  - Auto-detection from .env files"
log "INFO" ""
log "INFO" "Documentation: https://github.com/oraios/serena"
