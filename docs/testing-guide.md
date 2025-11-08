# Testing Guide

Comprehensive testing framework for the dotfiles repository to ensure reliability and prevent regressions.

## Quick Start

```bash
# Run all tests
./run-tests.sh

# Run specific test suite
./run-tests.sh bootstrap

# Run multiple test suites
./run-tests.sh configs scripts

# List available test suites
./run-tests.sh --list

# Get help
./run-tests.sh --help
```

## Test Structure

### Test Suites

The repository includes the following test suites:

#### 1. Bootstrap Tests (`test-bootstrap.sh`)
Tests for the main bootstrap and installation scripts:
- Verifies bootstrap.sh exists and is executable
- Checks for proper shebangs
- Validates core functions and configurations
- Ensures all essential directories exist
- Verifies utility scripts are present

#### 2. Configuration Tests (`test-configs.sh`)
Tests for configuration file validity:
- Validates TOML files (starship, atuin, yazi)
- Validates JSON files (.mcp.json)
- Checks all tool configurations exist
- Ensures .gitignore is properly configured
- Verifies no backup files are tracked in git

#### 3. Scripts Tests (`test-scripts.sh`)
Tests for utility and setup scripts:
- Verifies all scripts have proper shebangs
- Ensures scripts are executable
- Checks for correct file organization
- Validates no Windows line endings (CRLF)
- Ensures proper directory structure (setup/, tests/)

#### 4. MCP Tests (`test-mcp.sh`)
Tests for MCP server installations:
- Tests individual MCP servers
- Validates server availability
- Tests stdio initialization

## Test Framework

### Core Functions

The test framework (`tests/test-framework.sh`) provides:

```bash
# Initialize test suite
init_tests "Test Suite Name"

# Run a test
test_start "test description"
# ... test code ...
test_pass  # or test_fail "reason"

# Assertions
assert_equals expected actual [message]
assert_not_equals not_expected actual [message]
assert_file_exists file [message]
assert_dir_exists directory [message]
assert_file_not_exists file [message]
assert_success [message]  # checks $?
assert_failure [message]  # checks $?
assert_contains haystack needle [message]
assert_not_contains haystack needle [message]

# Test summary
test_summary  # prints results and returns exit code
```

### Setup and Teardown

```bash
# Define setup/teardown functions
set_setup "my_setup_function"
set_teardown "my_cleanup_function"

# These run before/after each test
my_setup_function() {
    # Prepare test environment
}

my_cleanup_function() {
    # Clean up after test
}
```

## Writing Tests

### Example Test File

```bash
#!/usr/bin/env bash

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Source test framework
source "$SCRIPT_DIR/test-framework.sh"

# Initialize test suite
init_tests "My Test Suite"

# Test 1: Simple assertion
test_start "example test with assertion"
if assert_equals "expected" "expected"; then
    test_pass
else
    test_fail
fi

# Test 2: File existence
test_start "file exists"
if assert_file_exists "$REPO_ROOT/some-file.sh"; then
    test_pass
else
    test_fail
fi

# Test 3: Command execution
test_start "command succeeds"
some_command &>/dev/null
if assert_success "command should succeed"; then
    test_pass
else
    test_fail
fi

# Print summary (required at end)
test_summary
exit $?
```

### Best Practices

1. **Always use `set -euo pipefail`** at the top of test files
2. **Source the test framework** before writing tests
3. **Initialize with `init_tests`** at the start
4. **End with `test_summary`** and exit with its return code
5. **Use descriptive test names** that explain what's being tested
6. **Keep tests independent** - each test should be self-contained
7. **Clean up after tests** - use setup/teardown for temporary files

## Adding New Tests

### 1. Create a New Test File

```bash
cd tests
touch test-myfeature.sh
chmod +x test-myfeature.sh
```

### 2. Write Test Structure

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/test-framework.sh"
init_tests "My Feature Tests"

# Add your tests here

test_summary
exit $?
```

### 3. Register in Test Runner

Edit `run-tests.sh` and add your test suite:

```bash
declare -A TEST_SUITES=(
    ["bootstrap"]="$TESTS_DIR/test-bootstrap.sh"
    ["configs"]="$TESTS_DIR/test-configs.sh"
    ["scripts"]="$TESTS_DIR/test-scripts.sh"
    ["mcp"]="$TESTS_DIR/test-mcp.sh"
    ["myfeature"]="$TESTS_DIR/test-myfeature.sh"  # Add this line
)
```

Update the usage function to document the new suite.

## Continuous Integration

### Running Tests in CI

The test suite is designed to be CI-friendly:

```yaml
# Example GitHub Actions workflow
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run tests
        run: ./run-tests.sh
```

### Exit Codes

- `0`: All tests passed
- `1`: One or more tests failed

## Troubleshooting

### Test Fails Locally But Not in CI
- Check for hardcoded paths
- Ensure dependencies are documented
- Verify environment variables

### Test is Flaky
- Add proper setup/teardown
- Avoid race conditions
- Make tests deterministic

### Skipping Tests

```bash
test_start "optional test requiring external tool"
if command -v special_tool &>/dev/null; then
    # Run test
    test_pass
else
    skip_test "special_tool not available"
fi
```

## Test Coverage

Current test coverage:

- ✅ Bootstrap scripts validation
- ✅ Configuration file validation
- ✅ Utility scripts validation
- ✅ MCP server testing
- ⏳ Integration tests (planned)
- ⏳ Performance tests (planned)

## Contributing Tests

When contributing:

1. Add tests for new features
2. Update existing tests when modifying functionality
3. Ensure all tests pass before submitting PR
4. Document any new test dependencies
5. Follow the existing test patterns

## Examples

### Testing a Script Exists and is Executable

```bash
test_start "my-script exists and is executable"
if assert_file_exists "$REPO_ROOT/scripts/my-script.sh" && \
   [[ -x "$REPO_ROOT/scripts/my-script.sh" ]]; then
    test_pass
else
    test_fail
fi
```

### Testing Configuration Content

```bash
test_start "config contains required setting"
config_content=$(cat "$REPO_ROOT/tool/config.toml")
if assert_contains "$config_content" "required_setting"; then
    test_pass
else
    test_fail "config missing required_setting"
fi
```

### Testing Command Output

```bash
test_start "command produces expected output"
output=$(./my-command 2>&1)
if assert_contains "$output" "expected text"; then
    test_pass
else
    test_fail "unexpected output: $output"
fi
```

## Future Enhancements

Planned improvements:

- [ ] Code coverage reporting
- [ ] Performance benchmarking
- [ ] Integration tests with containers
- [ ] Automated test generation
- [ ] Test result reporting (HTML, JSON)
- [ ] Parallel test execution
- [ ] Test fixtures management

## Resources

- Test framework source: `tests/test-framework.sh`
- Test runner source: `run-tests.sh`
- Example tests: `tests/test-*.sh`
