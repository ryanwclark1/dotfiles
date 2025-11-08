#!/usr/bin/env bash

# Main test runner for dotfiles repository
# Runs all test suites or specific tests based on arguments

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTS_DIR="$SCRIPT_DIR/tests"

# Test categories
declare -A TEST_SUITES=(
    ["bootstrap"]="$TESTS_DIR/test-bootstrap.sh"
    ["configs"]="$TESTS_DIR/test-configs.sh"
    ["scripts"]="$TESTS_DIR/test-scripts.sh"
    ["mcp"]="$TESTS_DIR/test-mcp.sh"
)

# Track results
SUITES_RUN=0
SUITES_PASSED=0
SUITES_FAILED=0
declare -a FAILED_SUITES

# Print usage
usage() {
    echo "Usage: $0 [OPTIONS] [TEST_SUITE...]"
    echo ""
    echo "Run dotfiles test suites"
    echo ""
    echo "Test Suites:"
    echo "  bootstrap    Test bootstrap and installation scripts"
    echo "  configs      Test configuration file validity"
    echo "  scripts      Test utility scripts"
    echo "  mcp          Test MCP server installations"
    echo "  all          Run all test suites (default)"
    echo ""
    echo "Options:"
    echo "  -h, --help   Show this help message"
    echo "  -v, --verbose Enable verbose output"
    echo "  -q, --quiet   Minimal output (only failures)"
    echo "  -l, --list    List available test suites"
    echo ""
    echo "Examples:"
    echo "  $0                  # Run all tests"
    echo "  $0 bootstrap        # Run only bootstrap tests"
    echo "  $0 configs scripts  # Run configs and scripts tests"
    echo "  $0 -v all          # Run all tests with verbose output"
}

# List available test suites
list_suites() {
    echo "Available test suites:"
    echo ""
    for suite in "${!TEST_SUITES[@]}"; do
        test_file="${TEST_SUITES[$suite]}"
        if [[ -f "$test_file" ]]; then
            echo -e "  ${GREEN}✓${NC} $suite"
        else
            echo -e "  ${RED}✗${NC} $suite (file missing)"
        fi
    done
}

# Run a single test suite
run_suite() {
    local suite_name="$1"
    local test_file="${TEST_SUITES[$suite_name]}"

    SUITES_RUN=$((SUITES_RUN + 1))

    echo ""
    echo -e "${BOLD}╔════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║  Running: $(printf "%-28s" "$suite_name") ║${NC}"
    echo -e "${BOLD}╚════════════════════════════════════════╝${NC}"
    echo ""

    if [[ ! -f "$test_file" ]]; then
        echo -e "${RED}Error: Test file not found: $test_file${NC}"
        ((SUITES_FAILED++))
        FAILED_SUITES+=("$suite_name")
        return 1
    fi

    if [[ ! -x "$test_file" ]]; then
        echo -e "${YELLOW}Warning: Test file not executable, making it executable${NC}"
        chmod +x "$test_file"
    fi

    if "$test_file"; then
        SUITES_PASSED=$((SUITES_PASSED + 1))
        return 0
    else
        SUITES_FAILED=$((SUITES_FAILED + 1))
        FAILED_SUITES+=("$suite_name")
        return 1
    fi
}

# Print final summary
print_summary() {
    echo ""
    echo ""
    echo -e "${BOLD}╔════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║         OVERALL TEST SUMMARY           ║${NC}"
    echo -e "${BOLD}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "Total test suites:  $SUITES_RUN"
    echo -e "${GREEN}Passed suites:      $SUITES_PASSED${NC}"

    if [[ $SUITES_FAILED -gt 0 ]]; then
        echo -e "${RED}Failed suites:      $SUITES_FAILED${NC}"
        echo ""
        echo -e "${RED}Failed suites:${NC}"
        for suite in "${FAILED_SUITES[@]}"; do
            echo -e "  ${RED}✗${NC} $suite"
        done
    else
        echo -e "Failed suites:      $SUITES_FAILED"
    fi

    echo ""

    if [[ $SUITES_FAILED -eq 0 ]]; then
        echo -e "${GREEN}${BOLD}🎉 All test suites passed!${NC}"
        return 0
    else
        echo -e "${RED}${BOLD}❌ Some test suites failed!${NC}"
        return 1
    fi
}

# Main execution
main() {
    local verbose=false
    local quiet=false
    local run_all=true
    declare -a suites_to_run

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -q|--quiet)
                quiet=true
                shift
                ;;
            -l|--list)
                list_suites
                exit 0
                ;;
            all)
                run_all=true
                shift
                ;;
            bootstrap|configs|scripts|mcp)
                run_all=false
                suites_to_run+=("$1")
                shift
                ;;
            *)
                echo -e "${RED}Error: Unknown argument: $1${NC}"
                echo ""
                usage
                exit 1
                ;;
        esac
    done

    # Print header
    echo -e "${BLUE}${BOLD}"
    echo "╔═══════════════════════════════════════════╗"
    echo "║     Dotfiles Repository Test Runner      ║"
    echo "╚═══════════════════════════════════════════╝"
    echo -e "${NC}"

    # Determine which suites to run
    if $run_all || [[ ${#suites_to_run[@]} -eq 0 ]]; then
        suites_to_run=("${!TEST_SUITES[@]}")
    fi

    # Sort suites for consistent ordering
    IFS=$'\n' sorted_suites=($(sort <<<"${suites_to_run[*]}"))
    unset IFS

    # Run test suites
    for suite in "${sorted_suites[@]}"; do
        run_suite "$suite" || true
    done

    # Print summary
    print_summary
    exit $?
}

# Run main
main "$@"
