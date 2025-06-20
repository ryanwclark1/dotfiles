# Playwright MCP DevContainer Setup

This directory contains configurations for running Playwright MCP inside VS Code Dev Containers.

## Overview

The Playwright MCP server is configured to work seamlessly inside a VS Code devcontainer, providing:
- Consistent development environment
- Pre-installed browsers and dependencies
- Isolated testing environment
- Easy setup and teardown
- Integration with VS Code extensions

## Prerequisites

- VS Code with "Dev Containers" extension installed
- Docker Desktop installed and running
- Claude Code with Playwright MCP server configured

## Getting Started

### 1. Open in DevContainer

1. Open your project in VS Code
2. Press `F1` and run: `Dev Containers: Reopen in Container`
3. VS Code will build and start the devcontainer
4. Wait for the container to fully initialize

### 2. Verify Installation

Inside the devcontainer terminal:

```bash
# Check Playwright is installed
npx playwright --version

# List installed browsers
npx playwright show-browsers

# Run a simple test
npx playwright test
```

## DevContainer Features

The devcontainer includes:
- **Base Image**: Microsoft Playwright official image (Ubuntu Jammy)
- **Browsers**: Chromium, Firefox, and WebKit pre-installed
- **Node.js**: LTS version with npm
- **VS Code Extensions**:
  - Playwright Test for VS Code
  - ESLint
  - Prettier
- **Tools**: git, curl, vim, build tools, Python 3

## Configuration Files

### .devcontainer/devcontainer.json
Main configuration file that defines:
- Container image or Dockerfile
- VS Code customizations
- Volume mounts for persistent data
- Environment variables
- Port forwarding

### .devcontainer/Dockerfile
Custom Dockerfile for additional tools and configurations

### playwright.config.js
Playwright test configuration optimized for headless execution in containers

## Writing Tests

Create test files in the `tests/` directory:

```javascript
// tests/example.spec.js
const { test, expect } = require('@playwright/test');

test('basic test', async ({ page }) => {
  await page.goto('https://playwright.dev/');
  await expect(page).toHaveTitle(/Playwright/);
});
```

Run tests:
```bash
# Run all tests
npx playwright test

# Run specific test file
npx playwright test tests/example.spec.js

# Run in headed mode (requires X11 forwarding)
npx playwright test --headed

# Generate test report
npx playwright show-report
```

## Volume Mounts

The devcontainer mounts these directories from your host:
- `~/.npm-global` → `/home/vscode/.npm-global` - Global npm packages
- `~/.cache/ms-playwright` → `/home/vscode/.cache/ms-playwright` - Browser cache

This ensures:
- Browsers don't need to be re-downloaded
- Global npm packages are shared
- Faster container startup

## Environment Variables

- `PLAYWRIGHT_BROWSERS_PATH`: Set to `/home/vscode/.cache/ms-playwright`
- `PATH`: Includes npm global bin directory

## Tips

### Running Tests in CI Mode
```bash
# Run with CI optimizations
CI=true npx playwright test
```

### Debugging Tests
```bash
# Run in debug mode
npx playwright test --debug

# Use VS Code debugger with Playwright extension
```

### Updating Browsers
```bash
# Update to latest browser versions
npx playwright install
```

## Troubleshooting

### Container fails to start
- Ensure Docker Desktop is running
- Check Docker has enough resources allocated
- Clear Docker cache: `docker system prune`

### Browsers not working
- Verify PLAYWRIGHT_BROWSERS_PATH is set
- Re-install browsers: `npx playwright install --force`
- Check system dependencies: `npx playwright install-deps`

### Permission issues
- The container runs as `vscode` user (UID 1000)
- Check file ownership in mounted volumes
- Ensure your host user has appropriate permissions

## Advanced Usage

### Custom Dockerfile
Uncomment the "build" section in devcontainer.json to use the custom Dockerfile instead of the base image.

### Additional ports
Add ports to `forwardPorts` array in devcontainer.json for your application servers.

### Post-create commands
Modify `postCreateCommand` in devcontainer.json to run additional setup steps.