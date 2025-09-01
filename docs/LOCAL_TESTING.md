# Local Testing Guide

This guide covers testing GlinrDock installations and configurations locally before production deployment.

## Overview

Local testing helps verify:
- Installation procedures work correctly
- Binary functionality on target platforms
- Configuration options behave as expected
- Upgrade and rollback procedures
- Integration with existing systems

## Test Environment Setup

### Prerequisites

```bash
# Required tools
which docker
which curl
which tar
which sha256sum  # or shasum on macOS

# Recommended tools
which systemctl  # for systemd testing
which docker-compose
```

### Test Directories

```bash
# Create isolated test environment
mkdir -p ~/glinrdock-testing/{staging,install,backup}
cd ~/glinrdock-testing
```

## Binary Testing

### Download and Verify

```bash
# Set platform for testing
PLATFORM="linux_amd64"  # Adjust for your system

# Download latest release
curl -LO "https://github.com/GLINCKER/glinrdock-release/releases/latest/download/glinrdockd_${PLATFORM}.tar.gz"
curl -LO "https://github.com/GLINCKER/glinrdock-release/releases/latest/download/glinrdockd_${PLATFORM}.tar.gz.sha256"

# Verify checksum
sha256sum -c "glinrdockd_${PLATFORM}.tar.gz.sha256"

# Extract binary
tar -xzf "glinrdockd_${PLATFORM}.tar.gz"
chmod +x "glinrdockd_${PLATFORM}"
```

### Basic Functionality Test

```bash
# Test help command
./glinrdockd_linux_amd64 --help

# Test version command
./glinrdockd_linux_amd64 --version

# Test configuration check (if available)
./glinrdockd_linux_amd64 --config-check
```

### Smoke Test

```bash
# Create test configuration
cat > test-config.env <<EOF
GLINRDOCK_BIND_ADDR=127.0.0.1:8081
GLINRDOCK_DATA_DIR=./test-data
ADMIN_TOKEN=test-token-$(date +%s)
DOCKER_HOST=unix:///var/run/docker.sock
EOF

# Create data directory
mkdir -p test-data

# Start in background
env $(cat test-config.env | xargs) ./glinrdockd_linux_amd64 &
GLINRDOCK_PID=$!

# Wait for startup
sleep 3

# Test health endpoint
if curl -f http://127.0.0.1:8081/health; then
    echo "✅ Health check passed"
else
    echo "❌ Health check failed"
fi

# Test authenticated endpoint
ADMIN_TOKEN=$(grep ADMIN_TOKEN test-config.env | cut -d= -f2)
if curl -f -H "Authorization: Bearer $ADMIN_TOKEN" http://127.0.0.1:8081/v1/info; then
    echo "✅ Authentication test passed"
else
    echo "❌ Authentication test failed"
fi

# Cleanup
kill $GLINRDOCK_PID 2>/dev/null || true
wait $GLINRDOCK_PID 2>/dev/null || true
rm -rf test-data
```

## Installation Script Testing

### Dry Run Mode

```bash
# Download install script
curl -fsSL https://github.com/GLINCKER/glinrdock-release/releases/latest/download/install.sh -o install.sh
chmod +x install.sh

# Run in dry-run mode (shows what would be done)
DRY_RUN=true ./install.sh
```

### Test Installation in Container

```bash
# Create test Dockerfile
cat > Dockerfile.test <<EOF
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y curl sudo systemctl docker.io
RUN useradd -m -s /bin/bash testuser
RUN usermod -aG sudo testuser
USER testuser
WORKDIR /home/testuser
COPY install.sh .
RUN chmod +x install.sh
EOF

# Build test image
docker build -f Dockerfile.test -t glinrdock-test .

# Run installation test
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock glinrdock-test \
  sudo ./install.sh
```

### Offline Installation Test

```bash
# Download all required files
mkdir -p offline-test
cd offline-test

curl -LO https://github.com/GLINCKER/glinrdock-release/releases/latest/download/install.sh
curl -LO https://github.com/GLINCKER/glinrdock-release/releases/latest/download/glinrdockd_linux_amd64.tar.gz
curl -LO https://github.com/GLINCKER/glinrdock-release/releases/latest/download/glinrdockd_linux_amd64.tar.gz.sha256

# Test offline installation
chmod +x install.sh
LOCAL_BINARY=./glinrdockd_linux_amd64.tar.gz DRY_RUN=true ./install.sh

cd ..
```

## Docker Container Testing

### Local Build and Testing

**Build local container image:**

```bash
# Ensure you have a binary in the current directory
# For testing, you can use a dummy file:
echo '#!/bin/sh\necho "GlinrDock mock v1.0.0"' > glinrdockd_linux_amd64
chmod +x glinrdockd_linux_amd64

# Build container with local binary
docker build -f Dockerfile.controller \
  --build-arg BINARY_PATH=./glinrdockd_linux_amd64 \
  --build-arg VERSION=dev \
  -t localhost:5000/glinrdock:dev .

# Start local registry for testing (optional)
docker run -d -p 5000:5000 --name registry registry:2
docker push localhost:5000/glinrdock:dev
```

**Test hardened container:**

```bash
# Test with read-only filesystem
docker run --rm --read-only \
  --tmpfs /tmp \
  -p 8080:8080 \
  -e ADMIN_TOKEN=test-token \
  localhost:5000/glinrdock:dev &

CONTAINER_PID=$!
sleep 5

# Test health endpoint
curl -f http://localhost:8080/v1/health

# Stop container
docker kill $(docker ps -q --filter ancestor=localhost:5000/glinrdock:dev) 2>/dev/null || true
```

## Docker Compose Testing

### Basic Docker Compose Test

```bash
# Download compose file
curl -fsSL https://raw.githubusercontent.com/GLINCKER/glinrdock-release/main/deploy/docker-compose.yml -o docker-compose.test.yml

# Create test environment file
cat > .env.test <<EOF
TAG=localhost:5000/glinrdock:dev
ADMIN_TOKEN=test-token-$(date +%s)
GLINRDOCK_HTTP_PORT=8080
GLINRDOCK_CONFIG_DIR=./test-config
EOF

# Create test config directory
mkdir -p test-config

# Start services
docker compose -f docker-compose.test.yml --env-file .env.test up -d

# Wait for startup and health check
sleep 30

# Test health endpoint
curl -f http://localhost:8080/v1/health

# Test with admin token
ADMIN_TOKEN=$(grep ADMIN_TOKEN .env.test | cut -d= -f2)
curl -f -H "Authorization: Bearer $ADMIN_TOKEN" http://localhost:8080/v1/info

# View logs
docker compose -f docker-compose.test.yml logs controller

# Cleanup
docker compose -f docker-compose.test.yml --env-file .env.test down -v
rm docker-compose.test.yml .env.test
rm -rf test-config
```

### Multi-Profile Testing

```bash
# Create environment file for profile testing
cat > .env.profiles <<EOF
TAG=localhost:5000/glinrdock:dev
ADMIN_TOKEN=profile-test-token
GLINRDOCK_HTTP_PORT=8080
GLINRDOCK_CONFIG_DIR=./profile-config
EOF

mkdir -p profile-config

# Test different profiles
PROFILES=("" "proxy" "monitoring")

for profile in "${PROFILES[@]}"; do
    echo "Testing profile: ${profile:-default}"
    
    # Build profile argument
    profile_arg=""
    if [ -n "$profile" ]; then
        profile_arg="--profile $profile"
    fi
    
    # Start with profile
    docker compose --env-file .env.profiles $profile_arg up -d
    
    # Wait for services
    sleep 10
    
    # Basic health check
    if curl -f http://localhost:8080/v1/health 2>/dev/null; then
        echo "✅ Health check passed for profile: ${profile:-default}"
    else
        echo "❌ Health check failed for profile: ${profile:-default}"
    fi
    
    # Cleanup
    docker compose --env-file .env.profiles $profile_arg down -v
    
    sleep 5
done

rm .env.profiles
rm -rf profile-config
```

## Configuration Testing

### Environment Variable Testing

```bash
# Test configuration file
cat > config-test.conf <<EOF
GLINRDOCK_BIND_ADDR=127.0.0.1:8082
GLINRDOCK_DATA_DIR=./config-test-data
GLINRDOCK_LOG_LEVEL=debug
ADMIN_TOKEN=config-test-token
EOF

mkdir -p config-test-data

# Test with configuration
env $(cat config-test.conf | xargs) ./glinrdockd_linux_amd64 &
CONFIG_TEST_PID=$!

sleep 3

# Verify configuration took effect
if curl -f http://127.0.0.1:8082/health; then
    echo "✅ Configuration test passed"
else
    echo "❌ Configuration test failed"
fi

# Cleanup
kill $CONFIG_TEST_PID 2>/dev/null || true
wait $CONFIG_TEST_PID 2>/dev/null || true
rm -rf config-test-data config-test.conf
```

### Port Binding Test

```bash
# Test different ports
PORTS=(8080 8081 8082 9000)

for port in "${PORTS[@]}"; do
    echo "Testing port: $port"
    
    # Check if port is available
    if ! nc -z 127.0.0.1 $port 2>/dev/null; then
        # Start on this port
        GLINRDOCK_BIND_ADDR="127.0.0.1:$port" \
        GLINRDOCK_DATA_DIR="./port-test-$port" \
        ADMIN_TOKEN="port-test-$port" \
        ./glinrdockd_linux_amd64 &
        
        PID=$!
        sleep 3
        
        # Test connection
        if curl -f "http://127.0.0.1:$port/health"; then
            echo "✅ Port $port test passed"
        else
            echo "❌ Port $port test failed"
        fi
        
        # Cleanup
        kill $PID 2>/dev/null || true
        wait $PID 2>/dev/null || true
        rm -rf "./port-test-$port"
    else
        echo "⚠️  Port $port already in use, skipping"
    fi
done
```

## Upgrade Testing

### Version Upgrade Test

```bash
# Simulate upgrade process
CURRENT_VERSION="v1.0.0"
NEW_VERSION="v1.1.0"

# Download both versions
mkdir -p upgrade-test
cd upgrade-test

# Download current version
curl -LO "https://github.com/GLINCKER/glinrdock-release/releases/download/${CURRENT_VERSION}/glinrdockd_linux_amd64.tar.gz"
tar -xzf glinrdockd_linux_amd64.tar.gz
mv glinrdockd_linux_amd64 glinrdockd_current

# Download new version
curl -LO "https://github.com/GLINCKER/glinrdock-release/releases/download/${NEW_VERSION}/glinrdockd_linux_amd64.tar.gz"
tar -xzf glinrdockd_linux_amd64.tar.gz
mv glinrdockd_linux_amd64 glinrdockd_new

# Test current version
echo "Testing current version..."
GLINRDOCK_DATA_DIR=./upgrade-data ADMIN_TOKEN=upgrade-test ./glinrdockd_current &
CURRENT_PID=$!
sleep 3
curl http://127.0.0.1:8080/health
kill $CURRENT_PID && wait $CURRENT_PID 2>/dev/null || true

# Test upgrade
echo "Testing upgrade..."
GLINRDOCK_DATA_DIR=./upgrade-data ADMIN_TOKEN=upgrade-test ./glinrdockd_new &
NEW_PID=$!
sleep 3
curl http://127.0.0.1:8080/health

# Cleanup
kill $NEW_PID 2>/dev/null || true
wait $NEW_PID 2>/dev/null || true
cd ..
rm -rf upgrade-test
```

## Integration Testing

### Docker Socket Integration

```bash
# Test Docker socket access
echo "Testing Docker socket integration..."

# Start GlinrDock
GLINRDOCK_DATA_DIR=./docker-test-data \
ADMIN_TOKEN=docker-test-token \
./glinrdockd_linux_amd64 &
DOCKER_TEST_PID=$!

sleep 5

# Test Docker integration through API
ADMIN_TOKEN=docker-test-token
API_URL="http://127.0.0.1:8080/v1"

# Test container listing (should work if Docker is running)
if curl -f -H "Authorization: Bearer $ADMIN_TOKEN" "$API_URL/containers"; then
    echo "✅ Docker integration test passed"
else
    echo "❌ Docker integration test failed"
fi

# Cleanup
kill $DOCKER_TEST_PID 2>/dev/null || true
wait $DOCKER_TEST_PID 2>/dev/null || true
rm -rf docker-test-data
```

### Network Connectivity Test

```bash
# Test external network access
echo "Testing network connectivity..."

GLINRDOCK_DATA_DIR=./network-test-data \
ADMIN_TOKEN=network-test-token \
./glinrdockd_linux_amd64 &
NETWORK_TEST_PID=$!

sleep 5

# Test various network scenarios
TESTS=(
    "127.0.0.1:8080"
    "localhost:8080"
    "0.0.0.0:8080"  # This should fail if binding to 127.0.0.1
)

for test_addr in "${TESTS[@]}"; do
    if curl -f "http://$test_addr/health" 2>/dev/null; then
        echo "✅ Network test passed: $test_addr"
    else
        echo "❌ Network test failed: $test_addr"
    fi
done

# Cleanup
kill $NETWORK_TEST_PID 2>/dev/null || true
wait $NETWORK_TEST_PID 2>/dev/null || true
rm -rf network-test-data
```

## Performance Testing

### Basic Performance Test

```bash
# Simple load test
echo "Running basic performance test..."

GLINRDOCK_DATA_DIR=./perf-test-data \
ADMIN_TOKEN=perf-test-token \
./glinrdockd_linux_amd64 &
PERF_TEST_PID=$!

sleep 5

# Simple concurrent request test
for i in {1..10}; do
    curl -s http://127.0.0.1:8080/health &
done
wait

# Memory usage check
ps -o pid,vsz,rss,comm -p $PERF_TEST_PID

# Cleanup
kill $PERF_TEST_PID 2>/dev/null || true
wait $PERF_TEST_PID 2>/dev/null || true
rm -rf perf-test-data
```

## Automated Test Suite

### Complete Test Script

```bash
#!/bin/bash
set -euo pipefail

# GlinrDock Local Testing Suite
echo "Starting GlinrDock local testing suite..."

# Configuration
PLATFORM="${PLATFORM:-linux_amd64}"
TEST_DIR="${TEST_DIR:-./glinrdock-test-$(date +%s)}"
CLEANUP="${CLEANUP:-true}"

# Create test directory
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Test functions
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo "Running test: $test_name"
    if eval "$test_command"; then
        echo "✅ PASS: $test_name"
    else
        echo "❌ FAIL: $test_name"
        return 1
    fi
}

# Download and verify binary
echo "Downloading and verifying binary..."
curl -LO "https://github.com/GLINCKER/glinrdock-release/releases/latest/download/glinrdockd_${PLATFORM}.tar.gz"
curl -LO "https://github.com/GLINCKER/glinrdock-release/releases/latest/download/glinrdockd_${PLATFORM}.tar.gz.sha256"
sha256sum -c "glinrdockd_${PLATFORM}.tar.gz.sha256"
tar -xzf "glinrdockd_${PLATFORM}.tar.gz"
chmod +x "glinrdockd_${PLATFORM}"

# Run tests
run_test "Version Check" "./glinrdockd_${PLATFORM} --version"
run_test "Help Command" "./glinrdockd_${PLATFORM} --help"
run_test "Smoke Test" "timeout 10 ./smoke_test.sh"

# Create smoke test
cat > smoke_test.sh <<'EOF'
#!/bin/bash
GLINRDOCK_DATA_DIR=./smoke-data ADMIN_TOKEN=smoke-test ./glinrdockd_* &
PID=$!
sleep 3
curl -f http://127.0.0.1:8080/health
kill $PID 2>/dev/null || true
wait $PID 2>/dev/null || true
rm -rf smoke-data
EOF
chmod +x smoke_test.sh

echo "All tests completed successfully!"

# Cleanup
if [ "$CLEANUP" = "true" ]; then
    cd ..
    rm -rf "$TEST_DIR"
fi
```

Save as `test-suite.sh` and run:

```bash
chmod +x test-suite.sh
./test-suite.sh
```

## Troubleshooting Test Issues

### Common Test Failures

**Binary not executable:**
```bash
chmod +x glinrdockd_*
file glinrdockd_*  # Check if correct architecture
```

**Port already in use:**
```bash
netstat -tlnp | grep :8080
# Use different port in tests
```

**Docker socket permission denied:**
```bash
sudo usermod -aG docker $USER
# Or use sudo for tests
```

**Network connectivity issues:**
```bash
# Check firewall rules
sudo iptables -L
# Test with curl verbose mode
curl -v http://127.0.0.1:8080/health
```

### Debug Mode Testing

```bash
# Run tests with debug output
DEBUG=1 GLINRDOCK_LOG_LEVEL=debug ./test-suite.sh

# Check logs in detail
tail -f /tmp/glinrdock-test-*.log
```

## Test Documentation

When reporting test results:

1. **Environment details**: OS, architecture, Docker version
2. **Test commands**: Exact commands run
3. **Expected vs actual results**
4. **Error messages**: Complete error output
5. **System logs**: Relevant system/service logs

Example test report:
```markdown
## Test Environment
- OS: Ubuntu 22.04 LTS
- Architecture: x86_64
- Docker: 20.10.21
- GlinrDock: v1.0.0

## Test Results
- ✅ Binary download and verification
- ✅ Basic functionality test
- ❌ Docker integration test
  - Error: permission denied accessing Docker socket
  - Solution: Added user to docker group

## Recommendations
- Update documentation to mention Docker group membership
- Add docker socket permission check to installation script
```