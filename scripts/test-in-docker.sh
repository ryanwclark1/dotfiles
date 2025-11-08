#!/usr/bin/env bash

# Test dotfiles installation in Docker containers
# Provides various testing modes for different scenarios

set -euo pipefail

# Colors
readonly COLOR_RESET='\033[0m'
readonly COLOR_INFO='\033[0;34m'
readonly COLOR_SUCCESS='\033[0;32m'
readonly COLOR_ERROR='\033[0;31m'
readonly COLOR_WARN='\033[1;33m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

info() {
    echo -e "${COLOR_INFO}[INFO]${COLOR_RESET} $*"
}

success() {
    echo -e "${COLOR_SUCCESS}[SUCCESS]${COLOR_RESET} $*"
}

error() {
    echo -e "${COLOR_ERROR}[ERROR]${COLOR_RESET} $*" >&2
}

warn() {
    echo -e "${COLOR_WARN}[WARN]${COLOR_RESET} $*"
}

# Check if docker is available
check_docker() {
    if ! command -v docker &>/dev/null; then
        error "Docker is not installed or not in PATH"
        echo "Please install Docker: https://docs.docker.com/get-docker/"
        exit 1
    fi

    if ! docker info &>/dev/null; then
        error "Docker daemon is not running"
        echo "Please start Docker and try again"
        exit 1
    fi
}

# Check if docker-compose is available
check_docker_compose() {
    if command -v docker-compose &>/dev/null; then
        return 0
    elif docker compose version &>/dev/null; then
        # Docker Compose V2 (docker compose)
        return 0
    else
        warn "Docker Compose not found, using docker build directly"
        return 1
    fi
}

# Run docker-compose command
run_compose() {
    if command -v docker-compose &>/dev/null; then
        docker-compose "$@"
    else
        docker compose "$@"
    fi
}

# Build test image
build_image() {
    local dockerfile="${1:-Dockerfile.test}"
    local tag="${2:-dotfiles-test:latest}"

    info "Building test image: $tag"
    info "Using Dockerfile: $dockerfile"

    cd "$REPO_ROOT"

    if docker build -f "$dockerfile" -t "$tag" .; then
        success "Image built successfully: $tag"
        return 0
    else
        error "Failed to build image"
        return 1
    fi
}

# Run tests in container
run_test_container() {
    local image="${1:-dotfiles-test:latest}"
    local test_cmd="${2:-./scripts/validate-install.sh && ./scripts/health-check.sh}"

    info "Running tests in container..."
    info "Image: $image"
    info "Test command: $test_cmd"

    if docker run --rm "$image" bash -c "cd /home/testuser/dotfiles && $test_cmd"; then
        success "Tests passed in container"
        return 0
    else
        error "Tests failed in container"
        return 1
    fi
}

# Interactive container shell
run_interactive() {
    local image="${1:-dotfiles-test:latest}"

    info "Starting interactive container..."
    info "Image: $image"
    echo ""
    echo "You can now test the dotfiles installation interactively."
    echo "Working directory: /home/testuser/dotfiles"
    echo "User: testuser"
    echo ""

    docker run --rm -it "$image" bash
}

# Quick test mode
quick_test() {
    info "Running quick test (dry-run + unit tests)..."

    cd "$REPO_ROOT"

    if build_image "Dockerfile.test-quick" "dotfiles-test:quick"; then
        run_test_container "dotfiles-test:quick" "./bootstrap.sh --dry-run && ./run-tests.sh"
    else
        return 1
    fi
}

# Full test mode
full_test() {
    info "Running full test (complete installation)..."

    cd "$REPO_ROOT"

    if build_image "Dockerfile.test" "dotfiles-test:full"; then
        run_test_container "dotfiles-test:full" \
            "./scripts/validate-install.sh && ./scripts/health-check.sh"
    else
        return 1
    fi
}

# Test on multiple distributions
multi_distro_test() {
    info "Testing on multiple distributions..."

    cd "$REPO_ROOT"

    if check_docker_compose; then
        run_compose -f docker-compose.test.yml build
        run_compose -f docker-compose.test.yml run --rm dotfiles-test-ubuntu
        run_compose -f docker-compose.test.yml run --rm dotfiles-test-debian
        run_compose -f docker-compose.test.yml run --rm dotfiles-test-alpine || warn "Alpine test may fail (limited tools)"

        success "Multi-distro tests completed"
    else
        warn "Docker Compose not available, skipping multi-distro tests"
        return 1
    fi
}

# Clean up Docker images
cleanup() {
    info "Cleaning up Docker images..."

    docker images | grep dotfiles-test | awk '{print $3}' | xargs -r docker rmi -f 2>/dev/null || true

    success "Cleanup completed"
}

# Usage information
usage() {
    cat << EOF
Usage: $0 [COMMAND] [OPTIONS]

Test dotfiles installation in Docker containers.

COMMANDS:
    quick           Run quick test (dry-run + unit tests)
    full            Run full installation test
    multi           Test on multiple distributions
    interactive     Start interactive container for manual testing
    build           Build test image
    clean           Remove test Docker images
    help            Show this help

OPTIONS:
    --image IMAGE   Use specific image (default: dotfiles-test:latest)
    --distro NAME   Test specific distribution (ubuntu, debian, alpine)

EXAMPLES:
    $0 quick                    # Quick test
    $0 full                     # Full installation test
    $0 multi                    # Test on all distributions
    $0 interactive              # Interactive testing
    $0 build                    # Just build the image
    $0 clean                    # Clean up images

ENVIRONMENT VARIABLES:
    DOCKER_BUILDKIT=1           Enable BuildKit for faster builds

REQUIREMENTS:
    - Docker installed and running
    - Docker Compose (optional, for multi-distro testing)

EOF
}

# Main function
main() {
    local command="${1:-help}"
    shift || true

    # Check Docker availability
    check_docker

    case "$command" in
        quick|q)
            quick_test
            ;;
        full|f)
            full_test
            ;;
        multi|m)
            multi_distro_test
            ;;
        interactive|i|shell)
            build_image "Dockerfile.test" "dotfiles-test:dev"
            run_interactive "dotfiles-test:dev"
            ;;
        build|b)
            build_image "Dockerfile.test" "dotfiles-test:latest"
            ;;
        clean|cleanup)
            cleanup
            ;;
        help|h|--help|-h)
            usage
            exit 0
            ;;
        *)
            error "Unknown command: $command"
            echo ""
            usage
            exit 1
            ;;
    esac
}

main "$@"
