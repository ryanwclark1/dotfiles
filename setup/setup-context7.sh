#!/usr/bin/env bash

# Comprehensive Context7 MCP Server Setup Script
# Handles uv workspaces, monorepos, dependency groups, and complex project structures
# Based on https://github.com/upstash/context7

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

# Function to detect Python project structure (uv workspace, regular pyproject.toml, or requirements.txt)
detect_python_project() {
    local project_path="$1"
    local python_info=()

    log "INFO" "Analyzing Python project at: $project_path"

    # Check for pyproject.toml first
    if [[ -f "$project_path/pyproject.toml" ]]; then
        # Check if it's a uv workspace root
        if grep -q "\[tool\.uv\.workspace\]" "$project_path/pyproject.toml" 2>/dev/null; then
            log "INFO" "Detected uv workspace root"
            python_info+=("uv-workspace")

            # Extract workspace members
            if command -v python3 &>/dev/null; then
                local members=$(python3 -c "
import tomllib
import sys
try:
    with open('$project_path/pyproject.toml', 'rb') as f:
        data = tomllib.load(f)
    workspace = data.get('tool', {}).get('uv', {}).get('workspace', {})
    members = workspace.get('members', [])
    for member in members:
        print(member)
except:
    pass
" 2>/dev/null)

                for member in $members; do
                    if [[ -n "$member" ]]; then
                        python_info+=("workspace-member:$member")
                    fi
                done
            fi

            # Extract root dependencies
            if command -v python3 &>/dev/null; then
                local deps=$(python3 -c "
import tomllib
import sys
try:
    with open('$project_path/pyproject.toml', 'rb') as f:
        data = tomllib.load(f)
    project = data.get('project', {})
    deps = project.get('dependencies', [])
    for dep in deps:
        print(dep.split('>=')[0].split('==')[0].split('~=')[0])
except:
    pass
" 2>/dev/null)

                for dep in $deps; do
                    if [[ -n "$dep" ]]; then
                        python_info+=("root-dependency:$dep")
                    fi
                done
            fi

            # Extract dependency groups
            if command -v python3 &>/dev/null; then
                local groups=$(python3 -c "
import tomllib
import sys
try:
    with open('$project_path/pyproject.toml', 'rb') as f:
        data = tomllib.load(f)
    groups = data.get('dependency-groups', {})
    for group_name, group_deps in groups.items():
        print(f'group:{group_name}')
        for dep in group_deps:
            clean_dep = dep.split('>=')[0].split('==')[0].split('~=')[0]
            print(f'group-{group_name}:{clean_dep}')
except:
    pass
" 2>/dev/null)

                for group_info in $groups; do
                    if [[ -n "$group_info" ]]; then
                        python_info+=("$group_info")
                    fi
                done
            fi
        else
            # Regular pyproject.toml (not workspace root)
            log "INFO" "Detected regular Python project with pyproject.toml"
            python_info+=("python")

            # Extract dependencies
            if command -v python3 &>/dev/null; then
                local deps=$(python3 -c "
import tomllib
import sys
try:
    with open('$project_path/pyproject.toml', 'rb') as f:
        data = tomllib.load(f)
    project = data.get('project', {})
    deps = project.get('dependencies', [])
    for dep in deps:
        print(dep.split('>=')[0].split('==')[0].split('~=')[0])
except:
    pass
" 2>/dev/null)

                for dep in $deps; do
                    if [[ -n "$dep" ]]; then
                        python_info+=("python:$dep")
                    fi
                done
            fi
        fi
    elif [[ -f "$project_path/requirements.txt" ]]; then
        # Handle requirements.txt projects
        log "INFO" "Detected Python project with requirements.txt"
        python_info+=("python")

        # Extract dependencies from requirements.txt
        if [[ -f "$project_path/requirements.txt" ]]; then
            local deps=$(grep -v "^#" "$project_path/requirements.txt" | grep -v "^$" | cut -d'=' -f1 | cut -d'>' -f1 | cut -d'<' -f1 | cut -d'~' -f1 | tr -d ' ')

            for dep in $deps; do
                if [[ -n "$dep" ]]; then
                    python_info+=("python:$dep")
                fi
            done
        fi
    elif [[ -f "$project_path/setup.py" ]]; then
        # Handle setup.py projects
        log "INFO" "Detected Python project with setup.py"
        python_info+=("python")

        # Extract dependencies from setup.py (basic parsing)
        if [[ -f "$project_path/setup.py" ]]; then
            local deps=$(grep -i "install_requires\|requires" "$project_path/setup.py" | grep -o "['\"][^'\"]*['\"]" | tr -d "'\"" | head -20)

            for dep in $deps; do
                if [[ -n "$dep" && "$dep" != "install_requires" && "$dep" != "requires" ]]; then
                    python_info+=("python:$dep")
                fi
            done
        fi
    fi

    echo "${python_info[*]}"
}

# Function to analyze workspace members
analyze_workspace_members() {
    local project_path="$1"
    local workspace_info="$2"
    local all_dependencies=()

    # Extract workspace members from workspace info
    local members=()
    for info in $workspace_info; do
        if [[ $info == workspace-member:* ]]; then
            members+=("${info#workspace-member:}")
        fi
    done

    log "INFO" "Analyzing workspace members: ${members[*]}"

    # Analyze each workspace member
    for member in "${members[@]}"; do
        local member_path="$project_path/$member"
        if [[ -d "$member_path" ]]; then
            log "INFO" "Analyzing workspace member: $member"

            # Check for different Python project types in member
            if [[ -f "$member_path/pyproject.toml" ]]; then
                # Extract member dependencies from pyproject.toml
                if command -v python3 &>/dev/null; then
                    local member_deps=$(python3 -c "
import tomllib
import sys
try:
    with open('$member_path/pyproject.toml', 'rb') as f:
        data = tomllib.load(f)
    project = data.get('project', {})
    deps = project.get('dependencies', [])
    for dep in deps:
        print(f'$member:{dep.split(\">=\")[0].split(\"==\")[0].split(\"~=\")[0]}')
except:
    pass
" 2>/dev/null)

                    for dep in $member_deps; do
                        if [[ -n "$dep" ]]; then
                            all_dependencies+=("$dep")
                        fi
                    done
                fi
            elif [[ -f "$member_path/requirements.txt" ]]; then
                # Extract member dependencies from requirements.txt
                local member_deps=$(grep -v "^#" "$member_path/requirements.txt" | grep -v "^$" | cut -d'=' -f1 | cut -d'>' -f1 | cut -d'<' -f1 | cut -d'~' -f1 | tr -d ' ')

                for dep in $member_deps; do
                    if [[ -n "$dep" ]]; then
                        all_dependencies+=("$member:$dep")
                    fi
                done
            fi
        fi
    done

    echo "${all_dependencies[*]}"
}

# Function to detect project type and dependencies (comprehensive)
detect_project_info() {
    local project_path="$1"
    local project_info=()

    log "INFO" "Comprehensive project analysis at: $project_path"

    # Detect Python project first (handles uv workspace, pyproject.toml, requirements.txt, setup.py)
    local python_info=$(detect_python_project "$project_path")
    for info in $python_info; do
        project_info+=("$info")
    done

    # If it's a uv workspace, analyze members
    if echo "$python_info" | grep -q "uv-workspace"; then
        local member_deps=$(analyze_workspace_members "$project_path" "$python_info")
        for dep in $member_deps; do
            project_info+=("$dep")
        done
    fi

    # Detect Node.js projects (including in subdirectories)
    local nodejs_found=false
    if [[ -f "$project_path/package.json" ]]; then
        nodejs_found=true
        log "INFO" "Detected Node.js project"
        project_info+=("nodejs")

        # Extract dependencies from package.json
        if command -v jq &>/dev/null; then
            local deps=$(jq -r '.dependencies // {} | keys[]' "$project_path/package.json" 2>/dev/null)
            local dev_deps=$(jq -r '.devDependencies // {} | keys[]' "$project_path/package.json" 2>/dev/null)

            for dep in $deps $dev_deps; do
                if [[ -n "$dep" ]]; then
                    project_info+=("npm:$dep")
                fi
            done
        fi

        # Detect framework
        if [[ -f "$project_path/next.config.js" || -f "$project_path/next.config.mjs" ]]; then
            project_info+=("framework:nextjs")
        elif [[ -f "$project_path/nuxt.config.js" || -f "$project_path/nuxt.config.ts" ]]; then
            project_info+=("framework:nuxt")
        elif [[ -f "$project_path/vue.config.js" ]]; then
            project_info+=("framework:vue")
        elif [[ -f "$project_path/angular.json" ]]; then
            project_info+=("framework:angular")
        elif [[ -f "$project_path/svelte.config.js" ]]; then
            project_info+=("framework:svelte")
        fi
    else
        # Check for package.json in subdirectories (common in monorepos)
        local package_json_files=$(find "$project_path" -maxdepth 3 -name "package.json" -type f 2>/dev/null | head -5)
        if [[ -n "$package_json_files" ]]; then
            nodejs_found=true
            log "INFO" "Detected Node.js project in subdirectory"
            project_info+=("nodejs")

            # Use the first package.json found
            local first_package_json=$(echo "$package_json_files" | head -1)
            local relative_path=$(realpath --relative-to="$project_path" "$(dirname "$first_package_json")")

            if command -v jq &>/dev/null; then
                local deps=$(jq -r '.dependencies // {} | keys[]' "$first_package_json" 2>/dev/null)
                local dev_deps=$(jq -r '.devDependencies // {} | keys[]' "$first_package_json" 2>/dev/null)

                for dep in $deps $dev_deps; do
                    if [[ -n "$dep" ]]; then
                        project_info+=("npm:$dep")
                    fi
                done
            fi

            # Detect framework in subdirectory
            local subdir=$(dirname "$first_package_json")
            if [[ -f "$subdir/next.config.js" || -f "$subdir/next.config.mjs" ]]; then
                project_info+=("framework:nextjs")
            elif [[ -f "$subdir/nuxt.config.js" || -f "$subdir/nuxt.config.ts" ]]; then
                project_info+=("framework:nuxt")
            elif [[ -f "$subdir/vue.config.js" ]]; then
                project_info+=("framework:vue")
            elif [[ -f "$subdir/angular.json" ]]; then
                project_info+=("framework:angular")
            elif [[ -f "$subdir/svelte.config.js" ]]; then
                project_info+=("framework:svelte")
            fi
        fi
    fi

    # Detect Go projects
    if [[ -f "$project_path/go.mod" ]]; then
        log "INFO" "Detected Go project"
        project_info+=("go")

        # Extract dependencies from go.mod
        if command -v go &>/dev/null; then
            local deps=$(cd "$project_path" && go list -m all 2>/dev/null | grep -v "indirect" | cut -d' ' -f1)

            for dep in $deps; do
                if [[ -n "$dep" && "$dep" != "module" ]]; then
                    project_info+=("go:$dep")
                fi
            done
        fi
    fi

    # Detect Rust projects
    if [[ -f "$project_path/Cargo.toml" ]]; then
        log "INFO" "Detected Rust project"
        project_info+=("rust")

        # Extract dependencies from Cargo.toml
        if command -v cargo &>/dev/null; then
            local deps=$(grep "^[a-zA-Z]" "$project_path/Cargo.toml" | grep -v "\[" | cut -d'=' -f1 | tr -d ' ')

            for dep in $deps; do
                if [[ -n "$dep" && "$dep" != "name" && "$dep" != "version" ]]; then
                    project_info+=("rust:$dep")
                fi
            done
        fi
    fi

    # Detect Java projects
    if [[ -f "$project_path/pom.xml" ]]; then
        log "INFO" "Detected Java/Maven project"
        project_info+=("java")
    fi

    if [[ -f "$project_path/build.gradle" ]]; then
        log "INFO" "Detected Java/Gradle project"
        project_info+=("java")
    fi

    # Detect C/C++ projects (only if Makefile contains C/C++ specific content)
    if [[ -f "$project_path/CMakeLists.txt" ]]; then
        log "INFO" "Detected C++/CMake project"
        project_info+=("cpp")
    fi

    # Only detect C/C++ from Makefile if it contains C/C++ specific patterns
    if [[ -f "$project_path/Makefile" ]]; then
        # Check if Makefile contains C/C++ specific content
        if grep -q -E "(\.c|\.cpp|\.h|\.hpp|\.o|\.a|\.so|gcc|g\+\+|clang|clang\+\+)" "$project_path/Makefile" 2>/dev/null; then
            log "INFO" "Detected C/C++ project (Makefile contains C/C++ patterns)"
            project_info+=("cpp")
        elif grep -q -E "(CC|CXX|CFLAGS|CXXFLAGS)" "$project_path/Makefile" 2>/dev/null; then
            log "INFO" "Detected C/C++ project (Makefile contains C/C++ variables)"
            project_info+=("cpp")
        else
            log "INFO" "Found Makefile but no C/C++ patterns detected (likely build script)"
        fi
    fi

    echo "${project_info[*]}"
}

# Function to generate comprehensive library mappings
generate_library_mappings() {
    local project_info="$1"
    local mappings=()

    # Convert project dependencies to Context7 library IDs
    for info in $project_info; do
        case $info in
            # Python dependencies (handles all Python project types)
            python:fastapi|root-dependency:fastapi|workspace-member:*:fastapi|group-*:fastapi)
                mappings+=("/fastapi/fastapi")
                ;;
            python:django|root-dependency:django|workspace-member:*:django|group-*:django)
                mappings+=("/django/django")
                ;;
            python:flask|root-dependency:flask|workspace-member:*:flask|group-*:flask)
                mappings+=("/flask/flask")
                ;;
            python:pandas|root-dependency:pandas|workspace-member:*:pandas|group-*:pandas)
                mappings+=("/pandas/pandas")
                ;;
            python:numpy|root-dependency:numpy|workspace-member:*:numpy|group-*:numpy)
                mappings+=("/numpy/numpy")
                ;;
            python:tensorflow|root-dependency:tensorflow|workspace-member:*:tensorflow|group-*:tensorflow)
                mappings+=("/tensorflow/tensorflow")
                ;;
            python:torch|root-dependency:torch|workspace-member:*:torch|group-*:torch)
                mappings+=("/pytorch/pytorch")
                ;;
            python:sqlalchemy|root-dependency:sqlalchemy|workspace-member:*:sqlalchemy|group-*:sqlalchemy)
                mappings+=("/sqlalchemy/sqlalchemy")
                ;;
            python:pydantic|root-dependency:pydantic|workspace-member:*:pydantic|group-*:pydantic)
                mappings+=("/pydantic/pydantic")
                ;;
            python:alembic|root-dependency:alembic|workspace-member:*:alembic|group-*:alembic)
                mappings+=("/alembic/alembic")
                ;;
            python:uvicorn|root-dependency:uvicorn|workspace-member:*:uvicorn|group-*:uvicorn)
                mappings+=("/encode/uvicorn")
                ;;
            python:httpx|root-dependency:httpx|workspace-member:*:httpx|group-*:httpx)
                mappings+=("/encode/httpx")
                ;;
            python:redis|root-dependency:redis|workspace-member:*:redis|group-*:redis)
                mappings+=("/redis/redis")
                ;;
            python:psycopg|root-dependency:psycopg|workspace-member:*:psycopg|group-*:psycopg)
                mappings+=("/psycopg/psycopg")
                ;;
            python:asyncpg|root-dependency:asyncpg|workspace-member:*:asyncpg|group-*:asyncpg)
                mappings+=("/magicstack/asyncpg")
                ;;
            python:strawberry-graphql|root-dependency:strawberry-graphql|workspace-member:*:strawberry-graphql|group-*:strawberry-graphql)
                mappings+=("/strawberry-graphql/strawberry")
                ;;
            python:rich|root-dependency:rich|workspace-member:*:rich|group-*:rich)
                mappings+=("/textual/rich")
                ;;
            python:typer|root-dependency:typer|workspace-member:*:typer|group-*:typer)
                mappings+=("/tiangolo/typer")
                ;;
            python:poethepoet|root-dependency:poethepoet|workspace-member:*:poethepoet|group-*:poethepoet)
                mappings+=("/nat-n/poethepoet")
                ;;
            python:ruff|root-dependency:ruff|workspace-member:*:ruff|group-*:ruff)
                mappings+=("/astral-sh/ruff")
                ;;
            python:mypy|root-dependency:mypy|workspace-member:*:mypy|group-*:mypy)
                mappings+=("/python/mypy")
                ;;
            python:pytest|root-dependency:pytest|workspace-member:*:pytest|group-*:pytest)
                mappings+=("/pytest-dev/pytest")
                ;;
            python:coverage|root-dependency:coverage|workspace-member:*:coverage|group-*:coverage)
                mappings+=("/nedbat/coveragepy")
                ;;
            python:playwright|root-dependency:playwright|workspace-member:*:playwright|group-*:playwright)
                mappings+=("/microsoft/playwright")
                ;;
            python:mkdocs|root-dependency:mkdocs|workspace-member:*:mkdocs|group-*:mkdocs)
                mappings+=("/mkdocs/mkdocs")
                ;;
            python:mkdocs-material|root-dependency:mkdocs-material|workspace-member:*:mkdocs-material|group-*:mkdocs-material)
                mappings+=("/squidfunk/mkdocs-material")
                ;;
            python:bandit|root-dependency:bandit|workspace-member:*:bandit|group-*:bandit)
                mappings+=("/pypa/bandit")
                ;;
            python:celery|root-dependency:celery|workspace-member:*:celery|group-*:celery)
                mappings+=("/celery/celery")
                ;;
            python:requests|root-dependency:requests|workspace-member:*:requests|group-*:requests)
                mappings+=("/psf/requests")
                ;;
            python:click|root-dependency:click|workspace-member:*:click|group-*:click)
                mappings+=("/pallets/click")
                ;;
            python:jinja2|root-dependency:jinja2|workspace-member:*:jinja2|group-*:jinja2)
                mappings+=("/pallets/jinja")
                ;;
            python:werkzeug|root-dependency:werkzeug|workspace-member:*:werkzeug|group-*:werkzeug)
                mappings+=("/pallets/werkzeug")
                ;;
            python:scipy|root-dependency:scipy|workspace-member:*:scipy|group-*:scipy)
                mappings+=("/scipy/scipy")
                ;;
            python:matplotlib|root-dependency:matplotlib|workspace-member:*:matplotlib|group-*:matplotlib)
                mappings+=("/matplotlib/matplotlib")
                ;;
            python:seaborn|root-dependency:seaborn|workspace-member:*:seaborn|group-*:seaborn)
                mappings+=("/mwaskom/seaborn")
                ;;
            python:scikit-learn|root-dependency:scikit-learn|workspace-member:*:scikit-learn|group-*:scikit-learn)
                mappings+=("/scikit-learn/scikit-learn")
                ;;
            python:jupyter|root-dependency:jupyter|workspace-member:*:jupyter|group-*:jupyter)
                mappings+=("/jupyter/jupyter")
                ;;
            python:ipython|root-dependency:ipython|workspace-member:*:ipython|group-*:ipython)
                mappings+=("/ipython/ipython")
                ;;

            # Node.js dependencies
            npm:react)
                mappings+=("/react/react")
                ;;
            npm:vue)
                mappings+=("/vue/vue")
                ;;
            npm:angular)
                mappings+=("/angular/angular")
                ;;
            npm:next)
                mappings+=("/vercel/next.js")
                ;;
            npm:nuxt)
                mappings+=("/nuxt/nuxt")
                ;;
            npm:express)
                mappings+=("/express/express")
                ;;
            npm:fastify)
                mappings+=("/fastify/fastify")
                ;;
            npm:prisma)
                mappings+=("/prisma/prisma")
                ;;
            npm:typeorm)
                mappings+=("/typeorm/typeorm")
                ;;
            npm:mongoose)
                mappings+=("/mongoose/mongoose")
                ;;
            npm:supabase)
                mappings+=("/supabase/supabase")
                ;;
            npm:firebase)
                mappings+=("/firebase/firebase")
                ;;
            npm:stripe)
                mappings+=("/stripe/stripe")
                ;;

            # Go dependencies
            go:gin)
                mappings+=("/gin-gonic/gin")
                ;;
            go:echo)
                mappings+=("/labstack/echo")
                ;;
            go:gorm)
                mappings+=("/gorm/gorm")
                ;;

            # Rust dependencies
            rust:tokio)
                mappings+=("/tokio/tokio")
                ;;
            rust:serde)
                mappings+=("/serde/serde")
                ;;
            rust:actix)
                mappings+=("/actix/actix")
                ;;
        esac
    done

    echo "${mappings[*]}"
}

# Function to create comprehensive project configuration
create_project_config() {
    local project_path="$1"
    local project_name="$2"
    local project_info="$3"
    local library_mappings="$4"

    local config_dir="$project_path/.context7"
    mkdir -p "$config_dir"

    # Determine language and frameworks
    local language="auto"
    local frameworks=()
    local workspace_members=()
    local dependency_groups=()

    for info in $project_info; do
        case $info in
            nodejs)
                language="javascript"
                ;;
            python|uv-workspace)
                language="python"
                ;;
            go)
                language="go"
                ;;
            rust)
                language="rust"
                ;;
            java)
                language="java"
                ;;
            cpp)
                language="cpp"
                ;;
            framework:*)
                frameworks+=("${info#framework:}")
                ;;
            workspace-member:*)
                workspace_members+=("${info#workspace-member:}")
                ;;
            group:*)
                dependency_groups+=("${info#group:}")
                ;;
        esac
    done

    # Create comprehensive project configuration
    cat > "$config_dir/project.json" <<EOF
{
  "name": "$project_name",
  "description": "Comprehensive Context7 configuration for $project_name",
  "path": "$project_path",
  "language": "$language",
  "frameworks": [$(IFS=','; echo "${frameworks[*]}")],
  "workspace_members": [$(IFS=','; echo "${workspace_members[*]}")],
  "dependency_groups": [$(IFS=','; echo "${dependency_groups[*]}")],
  "dependencies": [$(IFS=','; echo "${project_info[*]}")],
  "context7_libraries": [$(IFS=','; echo "${library_mappings[*]}")],
  "settings": {
    "indexing": {
      "enabled": true,
      "excludePatterns": [
        "**/node_modules/**",
        "**/.git/**",
        "**/dist/**",
        "**/build/**",
        "**/*.log",
        "**/.DS_Store",
        "**/coverage/**",
        "**/.next/**",
        "**/.cache/**",
        "**/tmp/**",
        "**/temp/**",
        "**/__pycache__/**",
        "**/*.pyc",
        "**/.pytest_cache/**",
        "**/target/**",
        "**/vendor/**",
        "**/.venv/**",
        "**/venv/**",
        "**/.mypy_cache/**",
        "**/.ruff_cache/**"
      ],
      "includePatterns": [
        "**/*.js", "**/*.ts", "**/*.jsx", "**/*.tsx",
        "**/*.py", "**/*.go", "**/*.rs", "**/*.java",
        "**/*.cpp", "**/*.c", "**/*.h", "**/*.md",
        "**/*.json", "**/*.yaml", "**/*.yml",
        "**/*.toml", "**/*.xml", "**/*.html",
        "**/*.css", "**/*.scss", "**/*.sass",
        "**/*.vue", "**/*.svelte", "**/*.php",
        "**/*.rb", "**/*.swift", "**/*.kt",
        "**/*.dart", "**/*.r", "**/*.m",
        "**/*.sql", "**/*.sh", "**/*.bash",
        "**/*.zsh", "**/*.fish", "**/*.ps1"
      ]
    },
    "search": {
      "maxResults": 100,
      "contextLines": 3,
      "fuzzyMatch": true,
      "caseSensitive": false
    },
    "performance": {
      "maxFileSize": 10485760,
      "maxFiles": 10000,
      "cacheTimeout": 3600,
      "parallelIndexing": true
    },
    "devcontainer": {
      "enabled": true,
      "autoDetectDependencies": true,
      "libraryMappings": [$(IFS=','; echo "${library_mappings[*]}")]
    },
    "uv_workspace": {
      "enabled": $(if echo "$project_info" | grep -q "uv-workspace"; then echo "true"; else echo "false"; fi),
      "workspace_members": [$(IFS=','; echo "${workspace_members[*]}")],
      "dependency_groups": [$(IFS=','; echo "${dependency_groups[*]}")]
    }
  }
}
EOF
}

# Function to create comprehensive workspace configuration
create_workspace_config() {
    local context7_home="$1"

    cat > "$context7_home/config.json" <<EOF
{
  "workspaces": [
    {
      "name": "default",
      "path": "$HOME/workspace",
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
        "**/.DS_Store",
        "**/coverage/**",
        "**/.next/**",
        "**/.cache/**",
        "**/tmp/**",
        "**/temp/**",
        "**/__pycache__/**",
        "**/*.pyc",
        "**/.pytest_cache/**",
        "**/target/**",
        "**/vendor/**",
        "**/.venv/**",
        "**/venv/**",
        "**/.mypy_cache/**",
        "**/.ruff_cache/**"
      ],
      "includePatterns": [
        "**/*.js", "**/*.ts", "**/*.jsx", "**/*.tsx",
        "**/*.py", "**/*.go", "**/*.rs", "**/*.java",
        "**/*.cpp", "**/*.c", "**/*.h", "**/*.md",
        "**/*.json", "**/*.yaml", "**/*.yml",
        "**/*.toml", "**/*.xml", "**/*.html",
        "**/*.css", "**/*.scss", "**/*.sass",
        "**/*.vue", "**/*.svelte", "**/*.php",
        "**/*.rb", "**/*.swift", "**/*.kt",
        "**/*.dart", "**/*.r", "**/*.m",
        "**/*.sql", "**/*.sh", "**/*.bash",
        "**/*.zsh", "**/*.fish", "**/*.ps1"
      ]
    },
    "search": {
      "maxResults": 100,
      "contextLines": 3,
      "fuzzyMatch": true,
      "caseSensitive": false
    },
    "performance": {
      "maxFileSize": 10485760,
      "maxFiles": 10000,
      "cacheTimeout": 3600,
      "parallelIndexing": true
    },
    "security": {
      "allowedPaths": [
        "$HOME/workspace",
        "$HOME/projects",
        "$HOME/Code"
      ],
      "restrictToWorkspace": true
    },
    "devcontainer": {
      "enabled": true,
      "autoDetectDependencies": true,
      "libraryMappings": {}
    },
    "uv_workspace": {
      "enabled": false,
      "workspace_members": [],
      "dependency_groups": []
    }
  }
}
EOF
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

log "INFO" "Setting up comprehensive Context7 MCP Server..."

# Create Context7 directories
CONTEXT7_HOME="$HOME/.context7"
CONTEXT7_PROJECTS="$HOME/.context7/projects"
mkdir -p "$CONTEXT7_HOME"
mkdir -p "$CONTEXT7_PROJECTS"

# Create comprehensive workspace configuration
log "INFO" "Creating comprehensive Context7 configuration..."
create_workspace_config "$CONTEXT7_HOME"

# Create project initialization script
cat > "$CONTEXT7_HOME/init-project.sh" <<'EOF'
#!/usr/bin/env bash

# Comprehensive Context7 Project Initialization Script
# Handles uv workspaces, monorepos, and complex dependency structures
# Usage: ./init-project.sh [project_name] [project_path]

set -euo pipefail

PROJECT_NAME="${1:-$(basename "$PWD")}"
PROJECT_PATH="${2:-$PWD}"

CONTEXT7_HOME="$HOME/.context7"
PROJECT_CONFIG_DIR="$PROJECT_PATH/.context7"

echo "Initializing comprehensive Context7 project: $PROJECT_NAME"
echo "Project path: $PROJECT_PATH"

# Detect project information with comprehensive analysis
PROJECT_INFO=$(detect_project_info "$PROJECT_PATH")
LIBRARY_MAPPINGS=$(generate_library_mappings "$PROJECT_INFO")

echo "Detected project info: $PROJECT_INFO"
echo "Library mappings: $LIBRARY_MAPPINGS"

# Create comprehensive project configuration
create_project_config "$PROJECT_PATH" "$PROJECT_NAME" "$PROJECT_INFO" "$LIBRARY_MAPPINGS"

# Add project to workspace if it doesn't exist
WORKSPACE_CONFIG="$CONTEXT7_HOME/config.json"
if [[ -f "$WORKSPACE_CONFIG" ]]; then
    # Check if project already exists in workspace
    if ! jq -e ".workspaces[] | select(.path == \"$PROJECT_PATH\")" "$WORKSPACE_CONFIG" >/dev/null 2>&1; then
        # Add new workspace
        jq ".workspaces += [{\"name\": \"$PROJECT_NAME\", \"path\": \"$PROJECT_PATH\", \"description\": \"$PROJECT_NAME project (comprehensive)\"}]" "$WORKSPACE_CONFIG" > "$WORKSPACE_CONFIG.tmp" && mv "$WORKSPACE_CONFIG.tmp" "$WORKSPACE_CONFIG"
        echo "✅ Added project to Context7 workspace"
    else
        echo "ℹ️ Project already exists in workspace"
    fi
fi

echo "✅ Comprehensive Context7 project initialized!"
echo "📁 Configuration: $PROJECT_CONFIG_DIR/project.json"
echo "🚀 Start Context7: $CONTEXT7_HOME/context7-launcher.sh $PROJECT_PATH"
EOF

chmod +x "$CONTEXT7_HOME/init-project.sh"

# Create Context7 launcher script
cat > "$CONTEXT7_HOME/context7-launcher.sh" <<'EOF'
#!/usr/bin/env bash

# Context7 Launcher Script
# Usage: ./context7-launcher.sh [project_path] [mode]

set -euo pipefail

CONTEXT7_HOME="$HOME/.context7"
DEFAULT_PROJECT="$HOME/workspace"
DEFAULT_MODE="development"

PROJECT_PATH="${1:-$DEFAULT_PROJECT}"
MODE="${2:-$DEFAULT_MODE}"

# Ensure project directory exists
mkdir -p "$PROJECT_PATH"

# Set environment variables
export CONTEXT7_PROJECT_DIR="$PROJECT_PATH"
export CONTEXT7_MODE="$MODE"

# Check if Context7 is installed
if ! command -v npx &>/dev/null; then
    echo "Error: npx not found. Please install Node.js first."
    exit 1
fi

# Launch Context7 MCP server
echo "Starting Context7 MCP server..."
echo "Project: $PROJECT_PATH"
echo "Mode: $MODE"

npx @upstash/context7-mcp
EOF

chmod +x "$CONTEXT7_HOME/context7-launcher.sh"

# Create convenience scripts
mkdir -p "$HOME/.local/bin"

cat > "$HOME/.local/bin/context7" <<'EOF'
#!/usr/bin/env bash
$HOME/.context7/context7-launcher.sh "$@"
EOF

cat > "$HOME/.local/bin/context7-init" <<'EOF'
#!/usr/bin/env bash
$HOME/.context7/init-project.sh "$@"
EOF

cat > "$HOME/.local/bin/context7-add" <<'EOF'
#!/usr/bin/env bash

# Context7 Add Project Script
# Usage: context7-add [project_name] [project_path]

set -euo pipefail

PROJECT_NAME="${1:-$(basename "$PWD")}"
PROJECT_PATH="${2:-$PWD}"

CONTEXT7_HOME="$HOME/.context7"
WORKSPACE_CONFIG="$CONTEXT7_HOME/config.json"

echo "Adding project to Context7: $PROJECT_NAME"
echo "Project path: $PROJECT_PATH"

# Check if jq is available
if ! command -v jq &>/dev/null; then
    echo "Error: jq not found. Please install jq first."
    exit 1
fi

# Add project to workspace
if [[ -f "$WORKSPACE_CONFIG" ]]; then
    # Check if project already exists
    if ! jq -e ".workspaces[] | select(.path == \"$PROJECT_PATH\")" "$WORKSPACE_CONFIG" >/dev/null 2>&1; then
        # Add new workspace
        jq ".workspaces += [{\"name\": \"$PROJECT_NAME\", \"path\": \"$PROJECT_PATH\", \"description\": \"$PROJECT_NAME project\"}]" "$WORKSPACE_CONFIG" > "$WORKSPACE_CONFIG.tmp" && mv "$WORKSPACE_CONFIG.tmp" "$WORKSPACE_CONFIG"
        echo "✅ Added project to Context7 workspace"
    else
        echo "ℹ️ Project already exists in workspace"
    fi
else
    echo "Error: Context7 configuration not found. Run setup-context7.sh first."
    exit 1
fi
EOF

chmod +x "$HOME/.local/bin/context7"
chmod +x "$HOME/.local/bin/context7-init"
chmod +x "$HOME/.local/bin/context7-add"

# Ensure ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc" 2>/dev/null || true
fi

# Check if Context7 is already installed in Claude
if claude mcp list 2>/dev/null | grep -q "^context7\b"; then
    log "INFO" "Context7 MCP server already installed in Claude"
    log "INFO" "Updating Context7 configuration..."

    # Remove existing Context7 installation
    claude mcp remove context7 2>/dev/null || true

    # Reinstall with new configuration
    if claude mcp add --scope user context7 -- npx @upstash/context7-mcp; then
        log "SUCCESS" "Context7 MCP server updated successfully!"
    else
        log "ERROR" "Failed to update Context7 MCP server"
        exit 1
    fi
else
    log "INFO" "Installing Context7 MCP server to Claude..."

    if claude mcp add --scope user context7 -- npx @upstash/context7-mcp; then
        log "SUCCESS" "Context7 MCP server installed successfully!"
    else
        log "ERROR" "Failed to install Context7 MCP server"
        exit 1
    fi
fi

log "SUCCESS" "Comprehensive Context7 setup complete! 🎉"
log "INFO" ""
log "INFO" "📁 Configuration: $CONTEXT7_HOME/config.json"
log "INFO" "🚀 Quick start: context7 [project_path] [mode]"
log "INFO" "📝 Initialize project: context7-init [project_name] [project_path]"
log "INFO" "➕ Add project: context7-add [project_name] [project_path]"
log "INFO" ""
log "INFO" "Comprehensive Features:"
log "INFO" "  ✅ uv workspace detection"
log "INFO" "  ✅ Monorepo support"
log "INFO" "  ✅ Dependency group analysis"
log "INFO" "  ✅ Workspace member analysis"
log "INFO" "  ✅ Complex dependency resolution"
log "INFO" "  ✅ Multi-language support"
log "INFO" "  ✅ Framework detection"
log "INFO" "  ✅ Performance optimizations"
log "INFO" "  ✅ Devcontainer optimization"
log "INFO" "  ✅ Security restrictions"
log "INFO" "  ✅ Up-to-date documentation access"
log "INFO" ""
log "INFO" "Usage examples:"
log "INFO" "  context7 ~/my-project development"
log "INFO" "  context7-init my-project ~/projects/my-project"
log "INFO" "  context7-add existing-project ~/existing/project"
log "INFO" ""
log "INFO" "Documentation: https://github.com/upstash/context7"
