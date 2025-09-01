# Installation Guide

This guide covers all installation methods for GlinrDock across supported platforms.

## Installation Methods

### Method 1: Install Script (Recommended)

The install script provides the fastest path to a production-ready installation with systemd service management.

**Quick Installation:**
```bash
# Download and inspect install script (recommended)
curl -fsSL https://raw.githubusercontent.com/GLINCKER/glinrdock-release/main/scripts/install.sh -o install.sh
chmod +x install.sh
./install.sh --dry-run  # See what it would do

# Install with defaults
./install.sh

# Or pipe directly (less secure)
curl -fsSL https://raw.githubusercontent.com/GLINCKER/glinrdock-release/main/scripts/install.sh | sudo bash
```

**Installation Options:**
```bash
# Dry run to see what would happen
./install.sh --dry-run

# Custom installation prefix
./install.sh --prefix /opt/glinrdock

# Install nightly build
./install.sh --channel nightly

# Combine options
./install.sh --dry-run --prefix /opt/glinrdock --channel stable
```

**Environment Variable Overrides:**
```bash
# Override version to install
GLINR_VERSION=v1.0.0 ./install.sh

# Use different download location
GLINR_BASE_URL=https://my-mirror.com/releases ./install.sh

# Install with custom binary name
GLINR_BIN_NAME=my-glinrdockd ./install.sh

# Custom destination directory
GLINR_DESTDIR=/usr/local ./install.sh
```

**What the script does:**
1. Detects OS and architecture automatically
2. Downloads binary and checksum from GitHub releases
3. Verifies SHA256 checksum (hard failure on mismatch)
4. Creates system user and secure directories
5. Installs binary with proper permissions
6. Creates and enables systemd service
7. Generates secure admin token if not provided
8. Displays post-install instructions

### Method 2: Docker Compose

For containerized deployments or development environments.

```bash
# Download compose file
curl -fsSL https://raw.githubusercontent.com/GLINCKER/glinrdock-release/main/deploy/docker-compose.yml -o docker-compose.yml

# Start services
docker-compose up -d

# Check status
docker-compose ps
```

**Docker Compose profiles:**
- `default`: Basic GlinrDock service
- `proxy`: Includes reverse proxy
- `monitoring`: Adds monitoring stack

### Method 3: Manual Installation

For custom deployments or when you need full control.

#### Download and Verify

```bash
# Set your platform
PLATFORM="linux_amd64"  # or linux_arm64, darwin_amd64, darwin_arm64

# Download binary and checksum
curl -LO "https://github.com/GLINCKER/glinrdock-release/releases/latest/download/glinrdockd_${PLATFORM}.tar.gz"
curl -LO "https://github.com/GLINCKER/glinrdock-release/releases/latest/download/glinrdockd_${PLATFORM}.tar.gz.sha256"

# Verify checksum
sha256sum -c "glinrdockd_${PLATFORM}.tar.gz.sha256"

# Extract binary
tar -xzf "glinrdockd_${PLATFORM}.tar.gz"
```

#### System User Creation

Create the dedicated system user for GlinrDock:

```bash
# Create system user and group
sudo useradd --system --user-group \
    --home-dir /var/lib/glinrdock \
    --shell /usr/sbin/nologin \
    --comment "GlinrDock service user" \
    glinrdock

# Add user to docker group for container management
sudo usermod -aG docker glinrdock

# Create required directories
sudo mkdir -p /var/lib/glinrdock/{data,logs}
sudo mkdir -p /etc/glinrdock
sudo mkdir -p /var/log/glinrdock

# Set proper ownership and permissions
sudo chown -R glinrdock:glinrdock /var/lib/glinrdock
sudo chown glinrdock:glinrdock /var/log/glinrdock
sudo chmod 750 /var/lib/glinrdock
sudo chmod 750 /var/log/glinrdock
```

#### Binary Installation

```bash
# Install binary
sudo cp glinrdockd_linux_amd64 /usr/local/bin/glinrdockd
sudo chmod 755 /usr/local/bin/glinrdockd
sudo chown root:root /usr/local/bin/glinrdockd
```

#### Configuration

```bash
# Create configuration file
sudo tee /etc/glinrdock/glinrdock.conf > /dev/null <<EOF
GLINRDOCK_BIND_ADDR=0.0.0.0:8080
GLINRDOCK_DATA_DIR=/var/lib/glinrdock/data
ADMIN_TOKEN=$(openssl rand -hex 32)
EOF

# Secure configuration
sudo chown root:glinrdock /etc/glinrdock/glinrdock.conf
sudo chmod 640 /etc/glinrdock/glinrdock.conf
```

#### systemd Service Installation

**Option 1: Using the systemd helper script (Recommended)**

```bash
# Download systemd helper script
curl -fsSL https://raw.githubusercontent.com/GLINCKER/glinrdock-release/main/scripts/systemd.sh -o systemd.sh
chmod +x systemd.sh

# Verify the hardened unit file
./systemd.sh verify

# Install the unit file (does not enable)
./systemd.sh install

# Enable and start the service
./systemd.sh enable
./systemd.sh start

# Check status
./systemd.sh status
```

**Option 2: Manual service installation**

```bash
# Download hardened unit file
curl -fsSL https://raw.githubusercontent.com/GLINCKER/glinrdock-release/main/deploy/systemd/glinrdockd.service -o glinrdockd.service

# Install unit file
sudo cp glinrdockd.service /etc/systemd/system/
sudo chmod 644 /etc/systemd/system/glinrdockd.service
sudo chown root:root /etc/systemd/system/glinrdockd.service

# Create environment file (optional)
sudo tee /etc/default/glinrdockd > /dev/null <<EOF
# GlinrDock environment configuration
GLINRDOCK_LOG_LEVEL=info
GLINRDOCK_BIND_ADDR=:8080
# ADMIN_TOKEN will be read from /etc/glinrdock/glinrdock.conf
EOF

# Reload, enable, and start
sudo systemctl daemon-reload
sudo systemctl enable glinrdockd.service
sudo systemctl start glinrdockd.service
```

**systemd Security Hardening Features:**

The included systemd unit implements comprehensive security hardening:

- **Process Isolation**: Runs as non-root `glinrdock` user
- **Filesystem Protection**: Read-only root filesystem with targeted write access
- **Capability Restrictions**: All capabilities removed, minimal privilege model  
- **System Call Filtering**: Blocks dangerous system calls
- **Network Restrictions**: Limited to required address families and local networks
- **Memory Protection**: Write-execute protection and SUID/SGID restrictions
- **Device Isolation**: No access to physical devices
- **Temporary File Isolation**: Private /tmp directory

**Security Verification:**

```bash
# Verify unit file syntax
systemd-analyze verify /etc/systemd/system/glinrdockd.service

# Security analysis (shows hardening score)
systemd-analyze security glinrdockd.service

# Or use the helper script
./systemd.sh verify
./systemd.sh security
```

### Method 4: Offline Installation

For environments without internet access or when you have pre-downloaded binaries.

1. **Download on connected machine:**
   ```bash
   # Download all required files
   curl -LO https://github.com/GLINCKER/glinrdock-release/releases/latest/download/glinrdockd_linux_amd64.tar.gz
   curl -LO https://github.com/GLINCKER/glinrdock-release/releases/latest/download/glinrdockd_linux_amd64.tar.gz.sha256
   curl -LO https://raw.githubusercontent.com/GLINCKER/glinrdock-release/main/scripts/install.sh
   ```

2. **Transfer to target machine:**
   ```bash
   scp glinrdockd_* install.sh user@target-host:~
   ```

3. **Install on target:**
   ```bash
   # Make installer executable
   chmod +x install.sh
   
   # Dry run to verify it will work
   ./install.sh --dry-run
   
   # Install using local files
   GLINR_LOCAL_TARBALL=./glinrdockd_linux_amd64.tar.gz ./install.sh
   ```

**Offline Installation Variables:**
- `GLINR_LOCAL_TARBALL`: Path to pre-downloaded tarball
- `GLINR_LOCAL_CHECKSUM`: Path to checksum file (optional, auto-detected)
- `GLINR_SKIP_DOWNLOAD`: Skip download step entirely

## Post-Installation

### Verify Installation

```bash
# Check service status
sudo systemctl status glinrdock

# Check binary version
glinrdockd --version

# Test API endpoint
curl http://localhost:8080/health
```

### Access Dashboard

1. Open http://localhost:8080 in your browser
2. Get admin token:
   ```bash
   sudo grep ADMIN_TOKEN /etc/glinrdock/glinrdock.conf
   ```
3. Log in with the admin token

### Configure Firewall

```bash
# Allow access from local network only
sudo ufw allow from 192.168.0.0/16 to any port 8080
sudo ufw allow from 10.0.0.0/8 to any port 8080

# Or allow from specific IP
sudo ufw allow from 192.168.1.100 to any port 8080
```

## Configuration Options

Environment variables can be set in `/etc/glinrdock/glinrdock.conf`:

| Variable | Default | Description |
|----------|---------|-------------|
| `GLINRDOCK_BIND_ADDR` | `0.0.0.0:8080` | Bind address and port |
| `GLINRDOCK_DATA_DIR` | `/var/lib/glinrdock/data` | Data directory |
| `ADMIN_TOKEN` | *required* | Admin authentication token |
| `DOCKER_HOST` | `unix:///var/run/docker.sock` | Docker daemon socket |

**Installer Environment Variables:**
| Variable | Default | Description |
|----------|---------|-------------|
| `GLINR_VERSION` | `latest` | Version to install (e.g., v1.0.0) |
| `GLINR_BASE_URL` | GitHub releases | Custom download URL |
| `GLINR_BIN_NAME` | `glinrdockd` | Binary name |
| `GLINR_DESTDIR` | `/usr/local` | Installation prefix |
| `GLINR_LOCAL_TARBALL` | - | Path to local tarball for offline install |
| `GLINR_SKIP_DOWNLOAD` | `false` | Skip download step |

See [CONFIG.md](CONFIG.md) for complete configuration reference.

## Uninstall

### Using Uninstall Script (Recommended)

The uninstall script provides safe removal with dry-run support:

```bash
# Download uninstaller
curl -fsSL https://raw.githubusercontent.com/GLINCKER/glinrdock-release/main/scripts/uninstall.sh -o uninstall.sh
chmod +x uninstall.sh

# Dry run to see what would be removed
./uninstall.sh --dry-run

# Standard uninstall (keeps data and logs)
./uninstall.sh

# Force uninstall even if service is running
./uninstall.sh --force

# Complete removal including data and logs
./uninstall.sh --force --remove-data --remove-logs
```

**Uninstall Options:**
- `--dry-run`: Show what would be removed without removing
- `--prefix DIR`: Specify custom installation prefix
- `--force`: Force removal even if service is running
- `--remove-data`: Also remove configuration and data directories
- `--remove-logs`: Also remove log files
- `--verbose`: Enable verbose output

### Manual Uninstall

If you don't have the uninstall script:

```bash
# Stop and disable service
sudo systemctl stop glinrdock.service
sudo systemctl disable glinrdock.service

# Remove files
sudo rm -f /etc/systemd/system/glinrdock.service
sudo rm -f /usr/local/bin/glinrdockd
sudo rm -rf /etc/glinrdock
sudo rm -rf /var/lib/glinrdock
sudo rm -rf /var/log/glinrdock

# Remove user
sudo userdel glinrdock
sudo groupdel glinrdock

# Reload systemd
sudo systemctl daemon-reload
```

### Docker Compose

```bash
# Stop and remove containers
docker-compose down -v

# Remove images (optional)
docker rmi ghcr.io/glincker/glinrdock:latest
```

## Troubleshooting

### Common Issues

**Service fails to start:**
```bash
# Check logs
sudo journalctl -u glinrdock.service -f

# Check Docker socket permissions
sudo ls -la /var/run/docker.sock
sudo usermod -aG docker glinrdock
```

**Port already in use:**
```bash
# Check what's using port 8080
sudo netstat -tlnp | grep :8080

# Use different port
sudo sed -i 's/8080/8081/g' /etc/glinrdock/glinrdock.conf
sudo systemctl restart glinrdock.service
```

**Permission denied errors:**
```bash
# Fix data directory permissions
sudo chown -R glinrdock:glinrdock /var/lib/glinrdock
sudo chmod 750 /var/lib/glinrdock
```

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for detailed troubleshooting guide.

## Next Steps

- [Configuration Guide](CONFIG.md) - Configure GlinrDock for your environment
- [Security Guide](SECURITY.md) - Security best practices
- [Upgrade Guide](UPGRADE.md) - Upgrading to newer versions