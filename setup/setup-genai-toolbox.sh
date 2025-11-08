#!/usr/bin/env bash

# Google GenAI Toolbox MCP Server Setup Script
# This script helps set up the GenAI Toolbox for use with Claude

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

# Check if Claude CLI is available
if ! command -v claude &>/dev/null; then
    log "ERROR" "Claude CLI not found. Please install it first."
    exit 1
fi

# Check if npm is available
if ! command -v npm &>/dev/null; then
    log "ERROR" "npm not found. Please install Node.js first."
    exit 1
fi

log "INFO" "Setting up Google GenAI Toolbox MCP Server..."

# Create configuration directory
TOOLBOX_CONFIG_DIR="$HOME/.genai-toolbox"
mkdir -p "$TOOLBOX_CONFIG_DIR"

# Function to detect and load environment variables
detect_environment_variables() {
    local env_vars=()
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

    # Check for common database environment variables
    local db_vars=()
    if [[ -n "${DB_HOST:-}" ]]; then db_vars+=("DB_HOST"); fi
    if [[ -n "${DB_PORT:-}" ]]; then db_vars+=("DB_PORT"); fi
    if [[ -n "${DB_NAME:-}" ]]; then db_vars+=("DB_NAME"); fi
    if [[ -n "${DB_USER:-}" ]]; then db_vars+=("DB_USER"); fi
    if [[ -n "${DB_PASSWORD:-}" ]]; then db_vars+=("DB_PASSWORD"); fi
    if [[ -n "${DB_DRIVER:-}" ]]; then db_vars+=("DB_DRIVER"); fi
    if [[ -n "${DB_SCHEMA:-}" ]]; then db_vars+=("DB_SCHEMA"); fi

    # Check for other common database variable patterns
    if [[ -n "${DATABASE_URL:-}" ]]; then db_vars+=("DATABASE_URL"); fi
    if [[ -n "${POSTGRES_HOST:-}" ]]; then db_vars+=("POSTGRES_HOST"); fi
    if [[ -n "${POSTGRES_PORT:-}" ]]; then db_vars+=("POSTGRES_PORT"); fi
    if [[ -n "${POSTGRES_DB:-}" ]]; then db_vars+=("POSTGRES_DB"); fi
    if [[ -n "${POSTGRES_USER:-}" ]]; then db_vars+=("POSTGRES_USER"); fi
    if [[ -n "${POSTGRES_PASSWORD:-}" ]]; then db_vars+=("POSTGRES_PASSWORD"); fi
    if [[ -n "${MYSQL_HOST:-}" ]]; then db_vars+=("MYSQL_HOST"); fi
    if [[ -n "${MYSQL_PORT:-}" ]]; then db_vars+=("MYSQL_PORT"); fi
    if [[ -n "${MYSQL_DATABASE:-}" ]]; then db_vars+=("MYSQL_DATABASE"); fi
    if [[ -n "${MYSQL_USER:-}" ]]; then db_vars+=("MYSQL_USER"); fi
    if [[ -n "${MYSQL_PASSWORD:-}" ]]; then db_vars+=("MYSQL_PASSWORD"); fi

    if [[ ${#db_vars[@]} -gt 0 ]]; then
        log "SUCCESS" "Detected database environment variables: ${db_vars[*]}"
        return 0
    else
        log "INFO" "No database environment variables detected"
        return 1
    fi
}

# Function to generate database configuration from environment variables
generate_database_config() {
    local config_file="$1"

    # Determine database type and connection details
    local db_type="postgres"
    local db_host="${DB_HOST:-${POSTGRES_HOST:-localhost}}"
    local db_port="${DB_PORT:-${POSTGRES_PORT:-5432}}"
    local db_name="${DB_NAME:-${POSTGRES_DB:-postgres}}"
    local db_user="${DB_USER:-${POSTGRES_USER:-postgres}}"
    local db_password="${DB_PASSWORD:-${POSTGRES_PASSWORD:-}}"
    local db_schema="${DB_SCHEMA:-public}"

    # Check if we have a DATABASE_URL
    if [[ -n "${DATABASE_URL:-}" ]]; then
        log "INFO" "Using DATABASE_URL for configuration"
        cat > "$config_file" << EOF
# Google GenAI Toolbox Configuration
# Auto-generated from environment variables

sources:
  primary-db:
    kind: postgres
    url: ${DATABASE_URL}
    schema: ${db_schema}

tools:
  search-data:
    kind: postgres-sql
    source: primary-db
    description: Search data in database
    parameters:
      - name: query
        type: string
        description: Search query
    statement: |
      SELECT * FROM information_schema.tables
      WHERE table_schema = '${db_schema}'
      AND table_name ILIKE '%' || \$1 || '%';

  list-tables:
    kind: postgres-sql
    source: primary-db
    description: List all tables in the database
    statement: |
      SELECT table_name, table_type
      FROM information_schema.tables
      WHERE table_schema = '${db_schema}'
      ORDER BY table_name;

  describe-table:
    kind: postgres-sql
    source: primary-db
    description: Describe table structure
    parameters:
      - name: table_name
        type: string
        description: Name of the table to describe
    statement: |
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns
      WHERE table_schema = '${db_schema}'
      AND table_name = \$1
      ORDER BY ordinal_position;

toolsets:
  default:
    - search-data
    - list-tables
    - describe-table
EOF
    else
        # Use individual connection parameters
        log "INFO" "Using individual database parameters for configuration"
        cat > "$config_file" << EOF
# Google GenAI Toolbox Configuration
# Auto-generated from environment variables

sources:
  primary-db:
    kind: postgres
    host: ${db_host}
    port: ${db_port}
    database: ${db_name}
    user: ${db_user}
    password: ${db_password}
    schema: ${db_schema}

tools:
  search-data:
    kind: postgres-sql
    source: primary-db
    description: Search data in database
    parameters:
      - name: query
        type: string
        description: Search query
    statement: |
      SELECT * FROM information_schema.tables
      WHERE table_schema = '${db_schema}'
      AND table_name ILIKE '%' || \$1 || '%';

  list-tables:
    kind: postgres-sql
    source: primary-db
    description: List all tables in the database
    statement: |
      SELECT table_name, table_type
      FROM information_schema.tables
      WHERE table_schema = '${db_schema}'
      ORDER BY table_name;

  describe-table:
    kind: postgres-sql
    source: primary-db
    description: Describe table structure
    parameters:
      - name: table_name
        type: string
        description: Name of the table to describe
    statement: |
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns
      WHERE table_schema = '${db_schema}'
      AND table_name = \$1
      ORDER BY ordinal_position;

  query-data:
    kind: postgres-sql
    source: primary-db
    description: Execute custom SQL query
    parameters:
      - name: sql_query
        type: string
        description: SQL query to execute
    statement: \$1

toolsets:
  default:
    - search-data
    - list-tables
    - describe-table
    - query-data
EOF
    fi
}

# Check if configuration already exists
if [[ -f "$TOOLBOX_CONFIG_DIR/tools.yaml" ]]; then
    log "WARN" "Configuration already exists at $TOOLBOX_CONFIG_DIR/tools.yaml"
    read -p "Overwrite existing configuration? [y/N]: " response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        log "INFO" "Keeping existing configuration"
    else
        log "INFO" "Backing up existing configuration..."
        cp "$TOOLBOX_CONFIG_DIR/tools.yaml" "$TOOLBOX_CONFIG_DIR/tools.yaml.backup"
    fi
fi

# Detect environment variables and generate configuration
log "INFO" "Detecting environment variables for database configuration..."

if detect_environment_variables; then
    log "SUCCESS" "Environment variables detected! Generating configuration..."
    generate_database_config "$TOOLBOX_CONFIG_DIR/tools.yaml"
    log "SUCCESS" "Configuration generated from environment variables"
else
    # Fallback to example configuration
    log "INFO" "No environment variables detected. Using example configuration..."
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    EXAMPLE_CONFIG="$SCRIPT_DIR/genai-toolbox/tools.yaml.example"

    if [[ -f "$EXAMPLE_CONFIG" ]]; then
        cp "$EXAMPLE_CONFIG" "$TOOLBOX_CONFIG_DIR/tools.yaml"
        log "SUCCESS" "Configuration template copied to $TOOLBOX_CONFIG_DIR/tools.yaml"
        log "INFO" "Please edit the configuration file to match your database setup"
    else
        log "WARN" "Example configuration not found. Creating basic template..."
        cat > "$TOOLBOX_CONFIG_DIR/tools.yaml" << 'EOF'
# Google GenAI Toolbox Configuration
# Edit this file to configure your database connections

sources:
  # Add your database sources here
  # Example:
  # my-db:
  #   kind: postgres
  #   host: localhost
  #   port: 5432
  #   database: your_database
  #   user: your_user
  #   password: your_password

tools:
  # Add your tools here
  # Example:
  # search-data:
  #   kind: postgres-sql
  #   source: my-db
  #   description: Search data in database
  #   parameters:
  #     - name: query
  #       type: string
  #       description: Search query
  #   statement: SELECT * FROM your_table WHERE column ILIKE '%' || $1 || '%';

toolsets:
  default: []
EOF
        log "SUCCESS" "Basic configuration created at $TOOLBOX_CONFIG_DIR/tools.yaml"
    fi
fi

# Check if GenAI Toolbox is already installed in Claude
if claude mcp list 2>/dev/null | grep -q "^genai-toolbox\b"; then
    log "INFO" "GenAI Toolbox MCP server already installed in Claude"
else
    log "INFO" "Installing GenAI Toolbox MCP server to Claude..."

    # Add the MCP server to Claude
    if claude mcp add --scope user genai-toolbox -- npx @googleapis/genai-toolbox; then
        log "SUCCESS" "GenAI Toolbox MCP server installed successfully!"
    else
        log "ERROR" "Failed to install GenAI Toolbox MCP server"
        log "INFO" "You may need to install it manually:"
        log "INFO" "claude mcp add --scope user genai-toolbox -- npx @googleapis/genai-toolbox"
        exit 1
    fi
fi

log "SUCCESS" "Google GenAI Toolbox setup complete! 🎉"
log "INFO" ""
log "INFO" "Features:"
log "INFO" "  ✅ Automatic environment variable detection"
log "INFO" "  ✅ .env file support (including .devcontainer/.env)"
log "INFO" "  ✅ Database configuration auto-generation"
log "INFO" "  ✅ PostgreSQL, MySQL, SQL Server support"
log "INFO" "  ✅ BigQuery, Firestore, Spanner support"
log "INFO" "  ✅ MongoDB, Redis, Neo4j support"
log "INFO" ""
log "INFO" "Next steps:"
log "INFO" "1. Configuration: $TOOLBOX_CONFIG_DIR/tools.yaml"
log "INFO" "2. Test connection: claude mcp list"
log "INFO" "3. Use Claude to interact with your databases"
log "INFO" ""
log "INFO" "Environment variables supported:"
log "INFO" "  - DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD"
log "INFO" "  - POSTGRES_HOST, POSTGRES_PORT, POSTGRES_DB, etc."
log "INFO" "  - MYSQL_HOST, MYSQL_PORT, MYSQL_DATABASE, etc."
log "INFO" "  - DATABASE_URL (full connection string)"
log "INFO" ""
log "INFO" "Documentation: https://googleapis.github.io/genai-toolbox/"
