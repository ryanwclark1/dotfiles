# Docker Testing Guide

Complete guide for testing dotfiles installation in Docker containers.

## Quick Start

```bash
# Quick test (fastest)
make docker-test

# Full installation test
make docker-test-full

# Test on multiple distributions
make docker-test-multi

# Interactive testing
make docker-shell
```

## Why Docker Testing?

**Benefits:**
- ✅ **Clean Environment** - Test in pristine system
- ✅ **Reproducibility** - Same results every time
- ✅ **Safety** - No impact on your system
- ✅ **Multi-distro** - Test across distributions
- ✅ **CI Integration** - Use in automated pipelines
- ✅ **Fast Iteration** - Quick rebuild and test cycles

## Available Test Modes

### 1. Quick Test (Recommended for Development)

Tests basic functionality without full installation.

```bash
make docker-test
# or
./scripts/test-in-docker.sh quick
```

**What it does:**
- Runs `bootstrap.sh --dry-run`
- Executes test suite
- Fast (~2-3 minutes)

**Use when:**
- Developing and testing changes
- Quick validation before commit
- CI pipeline

### 2. Full Test

Complete installation test with all tools.

```bash
make docker-test-full
# or
./scripts/test-in-docker.sh full
```

**What it does:**
- Full bootstrap installation
- Installs all tools
- Runs validation script
- Runs health check
- Slower (~10-15 minutes)

**Use when:**
- Testing before release
- Validating major changes
- Comprehensive verification

### 3. Multi-Distribution Test

Tests across multiple Linux distributions.

```bash
make docker-test-multi
# or
./scripts/test-in-docker.sh multi
```

**What it tests:**
- Ubuntu 22.04 (full test)
- Debian Bullseye (full test)
- Alpine Linux (basic test)

**Use when:**
- Ensuring cross-platform compatibility
- Before releasing updates
- Validating package dependencies

### 4. Interactive Shell

Start an interactive container for manual testing.

```bash
make docker-shell
# or
./scripts/test-in-docker.sh interactive
```

**What it provides:**
- Interactive bash shell
- Pre-installed dotfiles
- Full testing environment
- User: testuser
- Working directory: /home/testuser/dotfiles

**Use when:**
- Debugging issues
- Manual testing
- Exploring behavior
- Testing individual commands

## Docker Files

### Dockerfile.test

Full installation test environment.

**Features:**
- Based on Ubuntu 22.04
- Non-root user (testuser)
- All dependencies installed
- Full bootstrap execution
- Validation and health checks

**Build:**
```bash
docker build -f Dockerfile.test -t dotfiles-test:full .
```

**Run:**
```bash
docker run --rm -it dotfiles-test:full bash
```

### Dockerfile.test-quick

Lightweight test environment (faster builds).

**Features:**
- Minimal dependencies
- Dry-run testing
- Unit tests only
- Fast builds (~1-2 minutes)

**Build:**
```bash
docker build -f Dockerfile.test-quick -t dotfiles-test:quick .
```

**Run:**
```bash
docker run --rm dotfiles-test:quick
```

### docker-compose.test.yml

Multi-service testing setup.

**Services:**
- `dotfiles-test-ubuntu` - Ubuntu full test
- `dotfiles-test-quick` - Quick test
- `dotfiles-dev` - Interactive development
- `dotfiles-test-alpine` - Alpine Linux test
- `dotfiles-test-debian` - Debian test

**Usage:**
```bash
# Build all
docker-compose -f docker-compose.test.yml build

# Run specific service
docker-compose -f docker-compose.test.yml run dotfiles-test-ubuntu

# Run all tests
docker-compose -f docker-compose.test.yml up
```

## Advanced Usage

### Custom Image Tags

```bash
# Build with custom tag
./scripts/test-in-docker.sh build --image my-custom-tag

# Use custom image
docker run --rm -it my-custom-tag bash
```

### Environment Variables

```bash
# Enable BuildKit for faster builds
DOCKER_BUILDKIT=1 make docker-test

# Verbose output
VERBOSE=1 ./scripts/test-in-docker.sh full

# Custom Dockerfile
DOCKERFILE=Dockerfile.custom ./scripts/test-in-docker.sh build
```

### Volume Mounting

Test with live changes:

```bash
docker run --rm -it \
  -v $(pwd):/home/testuser/dotfiles \
  dotfiles-test:full \
  bash
```

**Inside container:**
```bash
cd /home/testuser/dotfiles
./bootstrap.sh --dry-run
./run-tests.sh
```

### Testing Specific Features

```bash
# Test only scripts
docker run --rm dotfiles-test:quick \
  bash -c "cd /home/testuser/dotfiles && ./run-tests.sh scripts"

# Test only configs
docker run --rm dotfiles-test:quick \
  bash -c "cd /home/testuser/dotfiles && ./run-tests.sh configs"

# Run health check only
docker run --rm dotfiles-test:full \
  bash -c "cd /home/testuser/dotfiles && ./scripts/health-check.sh"
```

## CI Integration

### GitHub Actions

```yaml
name: Docker Tests

on: [push, pull_request]

jobs:
  docker-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Quick Docker Test
        run: make docker-test

      - name: Full Docker Test
        run: make docker-test-full
        if: github.ref == 'refs/heads/main'
```

### GitLab CI

```yaml
docker-test:
  image: docker:latest
  services:
    - docker:dind
  script:
    - apk add --no-cache make bash
    - make docker-test

docker-test-full:
  image: docker:latest
  services:
    - docker:dind
  script:
    - apk add --no-cache make bash
    - make docker-test-full
  only:
    - main
```

## Troubleshooting

### Build Fails

**Problem:** Docker build fails

**Solutions:**
```bash
# Clean build cache
docker builder prune

# Build without cache
docker build --no-cache -f Dockerfile.test .

# Check Docker disk space
docker system df

# Clean up
docker system prune -a
```

### Permission Issues

**Problem:** Permission denied errors

**Solutions:**
```bash
# Ensure scripts are executable
chmod +x scripts/*.sh

# Check file ownership in image
docker run --rm dotfiles-test:full \
  ls -la /home/testuser/dotfiles
```

### Container Won't Start

**Problem:** Container exits immediately

**Solutions:**
```bash
# Check container logs
docker logs <container-id>

# Run with shell override
docker run --rm -it dotfiles-test:full /bin/bash

# Check Dockerfile CMD
docker inspect dotfiles-test:full
```

### Tests Fail in Container

**Problem:** Tests pass locally but fail in Docker

**Solutions:**
1. Check for hardcoded paths
2. Verify dependencies in Dockerfile
3. Test interactively:
   ```bash
   make docker-shell
   # Then debug inside container
   ```

### Slow Builds

**Problem:** Docker builds take too long

**Solutions:**
```bash
# Use BuildKit
export DOCKER_BUILDKIT=1
make docker-test

# Use quick test instead
make docker-test

# Multi-stage builds (advanced)
# See Dockerfile.test for examples
```

## Best Practices

### 1. Use Quick Tests for Development

```bash
# During development
make docker-test

# Before committing
make docker-test && make test
```

### 2. Use Full Tests for Releases

```bash
# Before tagging release
make docker-test-full
make docker-test-multi
```

### 3. Clean Up Regularly

```bash
# Remove test images
make docker-clean

# Full Docker cleanup
docker system prune -a --volumes
```

### 4. Layer Caching

Organize Dockerfile for optimal caching:

```dockerfile
# Dependencies (rarely change) - cached
RUN apt-get update && apt-get install ...

# Application code (changes often) - not cached
COPY . /app
```

### 5. Security

```bash
# Always use non-root user
RUN useradd -m testuser
USER testuser

# Scan images for vulnerabilities
docker scan dotfiles-test:full
```

## Examples

### Test a Specific Branch

```bash
git checkout feature-branch
make docker-test
```

### Compare Two Branches

```bash
# Build image from main
git checkout main
docker build -f Dockerfile.test -t dotfiles-test:main .

# Build image from feature
git checkout feature-branch
docker build -f Dockerfile.test -t dotfiles-test:feature .

# Compare
docker run --rm dotfiles-test:main bash -c "eza --version"
docker run --rm dotfiles-test:feature bash -c "eza --version"
```

### Test with Different Base Images

```bash
# Create custom Dockerfile
cat > Dockerfile.ubuntu20 << 'EOF'
FROM ubuntu:20.04
# ... rest of Dockerfile.test content
EOF

# Build and test
docker build -f Dockerfile.ubuntu20 -t dotfiles-test:ubuntu20 .
docker run --rm dotfiles-test:ubuntu20 \
  bash -c "cd /home/testuser/dotfiles && ./run-tests.sh"
```

### Automated Nightly Tests

```bash
#!/bin/bash
# cron job: 0 2 * * * /path/to/nightly-test.sh

cd /path/to/dotfiles
git pull origin main
make docker-test-multi | tee test-results-$(date +%Y%m%d).log
```

## Performance Tips

### 1. Use BuildKit

```bash
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1
```

### 2. Optimize .dockerignore

Already included, but verify:
```bash
cat .dockerignore
```

### 3. Multi-stage Builds

For even faster builds, consider multi-stage:

```dockerfile
# Build stage
FROM ubuntu:22.04 AS builder
# ... install build tools

# Runtime stage
FROM ubuntu:22.04
COPY --from=builder /output /app
```

### 4. Parallel Testing

```bash
# Run multiple tests in parallel
make docker-test &
make test &
wait
```

## Reference

### Make Targets

```bash
make docker-test          # Quick test
make docker-test-full     # Full test
make docker-test-multi    # Multi-distro
make docker-shell         # Interactive
make docker-build         # Build image
make docker-clean         # Cleanup
```

### Script Commands

```bash
./scripts/test-in-docker.sh quick         # Quick test
./scripts/test-in-docker.sh full          # Full test
./scripts/test-in-docker.sh multi         # Multi-distro
./scripts/test-in-docker.sh interactive   # Interactive
./scripts/test-in-docker.sh build         # Build
./scripts/test-in-docker.sh clean         # Cleanup
```

### Exit Codes

- `0` - All tests passed
- `1` - Tests failed
- `2` - Docker not available

## Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Testing Guide](testing-guide.md)
- [Troubleshooting Guide](troubleshooting.md)
