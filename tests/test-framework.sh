#!/usr/bin/env bash

# Simple test framework for dotfiles
# Provides basic testing utilities without external dependencies

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
CURRENT_TEST_NAME=""

# Test setup/teardown
SETUP_FUNCTION=""
TEARDOWN_FUNCTION=""

# Initialize test suite
init_tests() {
    local suite_name="$1"
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Running test suite: ${suite_name}${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

# Set setup function
set_setup() {
    SETUP_FUNCTION="$1"
}

# Set teardown function
set_teardown() {
    TEARDOWN_FUNCTION="$1"
}

# Run setup if defined
run_setup() {
    if [[ -n "$SETUP_FUNCTION" ]] && type "$SETUP_FUNCTION" &>/dev/null; then
        "$SETUP_FUNCTION"
    fi
}

# Run teardown if defined
run_teardown() {
    if [[ -n "$TEARDOWN_FUNCTION" ]] && type "$TEARDOWN_FUNCTION" &>/dev/null; then
        "$TEARDOWN_FUNCTION"
    fi
}

# Start a test
test_start() {
    CURRENT_TEST_NAME="$1"
    TESTS_RUN=$((TESTS_RUN + 1))
    echo -n "  Testing: $CURRENT_TEST_NAME ... "
    run_setup
}

# Pass a test
test_pass() {
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓ PASS${NC}"
    run_teardown
}

# Fail a test
test_fail() {
    local message="$1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗ FAIL${NC}"
    if [[ -n "$message" ]]; then
        echo -e "    ${RED}Error: $message${NC}"
    fi
    run_teardown
}

# Assert equals
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Expected '$expected', got '$actual'}"

    if [[ "$expected" == "$actual" ]]; then
        return 0
    else
        echo -e "\n    ${RED}$message${NC}"
        return 1
    fi
}

# Assert not equals
assert_not_equals() {
    local not_expected="$1"
    local actual="$2"
    local message="${3:-Expected not '$not_expected', but got '$actual'}"

    if [[ "$not_expected" != "$actual" ]]; then
        return 0
    else
        echo -e "\n    ${RED}$message${NC}"
        return 1
    fi
}

# Assert file exists
assert_file_exists() {
    local file="$1"
    local message="${2:-File does not exist: $file}"

    if [[ -f "$file" ]]; then
        return 0
    else
        echo -e "\n    ${RED}$message${NC}"
        return 1
    fi
}

# Assert directory exists
assert_dir_exists() {
    local dir="$1"
    local message="${2:-Directory does not exist: $dir}"

    if [[ -d "$dir" ]]; then
        return 0
    else
        echo -e "\n    ${RED}$message${NC}"
        return 1
    fi
}

# Assert file not exists
assert_file_not_exists() {
    local file="$1"
    local message="${2:-File should not exist: $file}"

    if [[ ! -f "$file" ]]; then
        return 0
    else
        echo -e "\n    ${RED}$message${NC}"
        return 1
    fi
}

# Assert command succeeds
assert_success() {
    local message="${1:-Command failed}"
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        return 0
    else
        echo -e "\n    ${RED}$message (exit code: $exit_code)${NC}"
        return 1
    fi
}

# Assert command fails
assert_failure() {
    local message="${1:-Command should have failed}"
    local exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        return 0
    else
        echo -e "\n    ${RED}$message${NC}"
        return 1
    fi
}

# Assert contains
assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-String does not contain expected substring}"

    if [[ "$haystack" == *"$needle"* ]]; then
        return 0
    else
        echo -e "\n    ${RED}$message${NC}"
        echo -e "    ${RED}Expected to find: '$needle'${NC}"
        echo -e "    ${RED}In string: '$haystack'${NC}"
        return 1
    fi
}

# Assert not contains
assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-String should not contain substring}"

    if [[ "$haystack" != *"$needle"* ]]; then
        return 0
    else
        echo -e "\n    ${RED}$message${NC}"
        echo -e "    ${RED}Should not find: '$needle'${NC}"
        echo -e "    ${RED}In string: '$haystack'${NC}"
        return 1
    fi
}

# Run a test with automatic pass/fail
run_test() {
    local test_name="$1"
    local test_function="$2"

    test_start "$test_name"

    if $test_function; then
        test_pass
    else
        test_fail
    fi
}

# Print test summary
test_summary() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Test Summary${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "Total tests:  $TESTS_RUN"
    echo -e "${GREEN}Passed:       $TESTS_PASSED${NC}"
    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo -e "${RED}Failed:       $TESTS_FAILED${NC}"
    else
        echo -e "Failed:       $TESTS_FAILED"
    fi
    echo ""

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}Some tests failed!${NC}"
        return 1
    fi
}

# Skip a test
skip_test() {
    local reason="$1"
    echo -e "${YELLOW}⊘ SKIP${NC} ${reason:+(reason: $reason)}"
}
