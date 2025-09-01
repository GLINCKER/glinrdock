# GlinrDock Installation Guide

This guide covers multiple installation methods to get GlinrDock running on your system, from quick Docker setups to production-ready systemd services.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation Methods](#installation-methods)
   - [Quick Install Script](#quick-install-script)
   - [Docker Compose](#docker-compose)
   - [Manual Installation](#manual-installation)
   - [Rootless Docker](#rootless-docker)
3. [Configuration](#configuration)
4. [Security Hardening](#security-hardening)
5. [Verification](#verification)
6. [Troubleshooting](#troubleshooting)
7. [Uninstallation](#uninstallation)

## Prerequisites

### System Requirements
- **OS:** Linux (Ubuntu 20.04+, CentOS 8+, RHEL 8+, Debian 11+)
- **Architecture:** x86_64 or ARM64
- **RAM:** 512MB minimum, 2GB recommended
- **Storage:** 1GB minimum, 10GB+ recommended
- **Network:** Port 8080 available

### Dependencies
- **Docker Engine 20.10+** (required)
- **curl** or **wget** (for installation)
- **systemd** (for service management)

### Docker Installation
If Docker isn't installed:
```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER

# CentOS/RHEL/Rocky
sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf install docker-ce docker-ce-cli containerd.io
sudo systemctl enable --now docker
```

## Installation Methods

### Quick Install Script

**Recommended for most users.** This script automatically detects your system architecture, downloads the latest release, and sets up a systemd service.

```bash
# Install as root (recommended)
curl -fsSL https://github.com/glinr/glinrdock/releases/latest/download/install.sh | sudo bash

# Or download and inspect first
curl -fsSL https://github.com/glinr/glinrdock/releases/latest/download/install.sh -o install.sh
chmod +x install.sh
sudo ./install.sh
```

**What the script does:**
1. Detects OS and architecture
2. Creates `glinrdock` user and group
3. Downloads and verifies binary checksum
4. Creates systemd service file
5. Generates admin token
6. Starts the service

**Script Options:**
```bash
# Custom installation directory
sudo GLINRDOCK_HOME=/opt/glinrdock ./install.sh

# Skip systemd service creation
sudo ./install.sh --no-systemd

# Set custom admin token
sudo ADMIN_TOKEN=your-secure-token ./install.sh

# Dry run mode (shows what would be done)
DRY_RUN=true ./install.sh
```

### Docker Compose

**Perfect for development or containerized deployments.** Uses official images with persistent volumes.

#### Basic Setup
```bash
# Download the compose file
curl -fsSL https://raw.githubusercontent.com/glinr/glinrdock/main/deploy/docker-compose.yml -o docker-compose.yml

# Start services
docker-compose up -d
```

#### Production Setup with Reverse Proxy
```bash
# Download full deployment configuration
curl -fsSL https://raw.githubusercontent.com/glinr/glinrdock/main/deploy/docker-compose.yml -o docker-compose.yml
curl -fsSL https://raw.githubusercontent.com/glinr/glinrdock/main/deploy/Caddyfile -o Caddyfile
curl -fsSL https://raw.githubusercontent.com/glinr/glinrdock/main/deploy/.env.example -o .env

# Edit environment variables
nano .env

# Deploy with reverse proxy
docker-compose --profile production up -d
```

#### Docker Compose Profiles
- **default** - Basic GlinrDock only
- **nginx** - With nginx reverse proxy
- **caddy** - With Caddy reverse proxy (automatic HTTPS)
- **monitoring** - Includes Prometheus metrics
- **production** - Full production stack

### Manual Installation

For custom setups or when you need full control.

#### 1. Create User and Directories
```bash
# Create system user
sudo useradd --system --user-group --home-dir /var/lib/glinrdock --shell /bin/false glinrdock

# Create directories
sudo mkdir -p /var/lib/glinrdock/{data,logs}
sudo mkdir -p /etc/glinrdock
sudo chown -R glinrdock:glinrdock /var/lib/glinrdock
```

#### 2. Download Binary
```bash
# Detect architecture
ARCH=$(dpkg --print-architecture 2>/dev/null || uname -m | sed 's/x86_64/amd64/')
VERSION=$(curl -s https://api.github.com/repos/glinr/glinrdock/releases/latest | grep '"tag_name"' | cut -d'"' -f4)

# Download binary
sudo wget https://github.com/glinr/glinrdock/releases/download/${VERSION}/glinrdockd-linux-${ARCH} \
  -O /usr/local/bin/glinrdockd

# Make executable
sudo chmod +x /usr/local/bin/glinrdockd
sudo chown root:root /usr/local/bin/glinrdockd
```

#### 3. Create Configuration
```bash
sudo tee /etc/glinrdock/glinrdock.conf > /dev/null << 'EOF'
# GlinrDock Configuration
GLINRDOCK_DATA_DIR=/var/lib/glinrdock/data
GLINRDOCK_LOG_LEVEL=info
GLINRDOCK_BIND_ADDR=0.0.0.0:8080
ADMIN_TOKEN=your-secure-admin-token-change-this
EOF

# Secure the config file
sudo chown root:glinrdock /etc/glinrdock/glinrdock.conf
sudo chmod 640 /etc/glinrdock/glinrdock.conf
```

#### 4. Create Systemd Service
```bash
sudo tee /etc/systemd/system/glinrdock.service > /dev/null << 'EOF'
[Unit]
Description=GlinrDock Container Management Platform
Documentation=https://github.com/glinr/glinrdock
After=network.target docker.service
Wants=docker.service

[Service]
Type=exec
User=glinrdock
Group=glinrdock
EnvironmentFile=/etc/glinrdock/glinrdock.conf
ExecStart=/usr/local/bin/glinrdockd
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal
SyslogIdentifier=glinrdock

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectHome=true
ProtectSystem=strict
ReadWritePaths=/var/lib/glinrdock

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable --now glinrdock.service
```

### Rootless Docker Setup

For running without root privileges on the Docker daemon.

#### 1. Setup Rootless Docker
```bash
# Install rootless Docker (if not already done)
curl -fsSL https://get.docker.com/rootless | sh

# Add to PATH
echo 'export PATH=$HOME/bin:$PATH' >> ~/.bashrc
export PATH=$HOME/bin:$PATH

# Start rootless Docker
systemctl --user enable --now docker
```

#### 2. Install GlinrDock for User
```bash
# Create user directories
mkdir -p ~/.local/share/glinrdock/{data,logs}
mkdir -p ~/.config/glinrdock

# Download binary
ARCH=$(uname -m | sed 's/x86_64/amd64/')
VERSION=$(curl -s https://api.github.com/repos/glinr/glinrdock/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
wget https://github.com/glinr/glinrdock/releases/download/${VERSION}/glinrdockd-linux-${ARCH} \
  -O ~/.local/bin/glinrdockd
chmod +x ~/.local/bin/glinrdockd
```

#### 3. User Service Configuration
```bash
# Create user systemd service
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/glinrdock.service << 'EOF'
[Unit]
Description=GlinrDock Container Management Platform (User)
After=docker.service
Wants=docker.service

[Service]
Type=exec
Environment=DOCKER_HOST=unix://%i/run/user/%i/docker.sock
Environment=GLINRDOCK_DATA_DIR=%h/.local/share/glinrdock/data
Environment=ADMIN_TOKEN=your-secure-admin-token
ExecStart=%h/.local/bin/glinrdockd
Restart=always
RestartSec=3

[Install]
WantedBy=default.target
EOF

# Enable user service
systemctl --user daemon-reload
systemctl --user enable --now glinrdock.service
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `GLINRDOCK_BIND_ADDR` | `0.0.0.0:8080` | Bind address and port |
| `GLINRDOCK_DATA_DIR` | `/var/lib/glinrdock/data` | Data directory |
| `GLINRDOCK_LOG_LEVEL` | `info` | Log level (debug, info, warn, error) |
| `ADMIN_TOKEN` | *required* | Admin authentication token |
| `WEBHOOK_SECRET` | *optional* | HMAC secret for webhook validation |
| `DOCKER_HOST` | *auto-detected* | Docker daemon socket |
| `GLINRDOCK_CORS_ORIGINS` | *none* | Allowed CORS origins (comma-separated) |

### Configuration File

Create `/etc/glinrdock/glinrdock.conf`:
```bash
# Core settings
GLINRDOCK_BIND_ADDR=0.0.0.0:8080
GLINRDOCK_DATA_DIR=/var/lib/glinrdock/data
GLINRDOCK_LOG_LEVEL=info

# Authentication
ADMIN_TOKEN=your-secure-token-min-32-chars

# Docker settings
DOCKER_HOST=unix:///var/run/docker.sock

# Optional: Webhook validation
WEBHOOK_SECRET=your-webhook-secret

# Optional: CORS for development
# GLINRDOCK_CORS_ORIGINS=http://localhost:3000,https://yourdomain.com
```

## Security Hardening

### 1. Network Security
```bash
# Use firewall to restrict access
sudo ufw allow from 10.0.0.0/8 to any port 8080  # Internal networks only
sudo ufw deny 8080  # Block external access

# Or use nginx/caddy reverse proxy with SSL
```

### 2. Docker Socket Security
```bash
# Create docker group for GlinrDock
sudo usermod -aG docker glinrdock

# Set socket permissions (if needed)
sudo chmod 660 /var/run/docker.sock
```

### 3. File Permissions
```bash
# Secure data directory
sudo chmod 750 /var/lib/glinrdock
sudo chmod 640 /etc/glinrdock/glinrdock.conf
```

### 4. Admin Token Security
```bash
# Generate secure admin token
ADMIN_TOKEN=$(openssl rand -hex 32)
echo "Your admin token: $ADMIN_TOKEN"

# Store securely and update configuration
sudo sed -i "s/ADMIN_TOKEN=.*/ADMIN_TOKEN=$ADMIN_TOKEN/" /etc/glinrdock/glinrdock.conf
```

## Verification

### Check Installation
```bash
# Verify binary
glinrdockd --version

# Check systemd service
sudo systemctl status glinrdock.service

# View logs
sudo journalctl -u glinrdock.service -f
```

### Test API Access
```bash
# Test health endpoint
curl http://localhost:8080/health

# Test authenticated endpoint (replace TOKEN)
curl -H "Authorization: Bearer YOUR_ADMIN_TOKEN" http://localhost:8080/v1/info
```

### Web Interface
Open http://localhost:8080 in your browser and log in with your admin token.

## Troubleshooting

### Common Issues

#### Service Won't Start
```bash
# Check logs
sudo journalctl -u glinrdock.service --no-pager

# Common causes:
# 1. Docker not running: sudo systemctl start docker
# 2. Port already in use: sudo netstat -tlnp | grep :8080
# 3. Permission issues: Check /var/lib/glinrdock ownership
```

#### Can't Connect to Docker
```bash
# Check Docker socket
sudo ls -la /var/run/docker.sock

# Add user to docker group
sudo usermod -aG docker glinrdock
sudo systemctl restart glinrdock.service
```

#### Permission Denied Errors
```bash
# Fix data directory permissions
sudo chown -R glinrdock:glinrdock /var/lib/glinrdock
sudo chmod 750 /var/lib/glinrdock
```

#### API Returns 401 Unauthorized
```bash
# Verify admin token in config
sudo cat /etc/glinrdock/glinrdock.conf | grep ADMIN_TOKEN

# Test with correct token
curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:8080/v1/info
```

### Debug Mode
```bash
# Enable debug logging
sudo sed -i 's/GLINRDOCK_LOG_LEVEL=info/GLINRDOCK_LOG_LEVEL=debug/' /etc/glinrdock/glinrdock.conf
sudo systemctl restart glinrdock.service

# View debug logs
sudo journalctl -u glinrdock.service -f
```

## Uninstallation

### Remove Service and Files
```bash
# Stop and disable service
sudo systemctl stop glinrdock.service
sudo systemctl disable glinrdock.service

# Remove files
sudo rm -f /etc/systemd/system/glinrdock.service
sudo rm -f /usr/local/bin/glinrdockd
sudo rm -rf /etc/glinrdock
sudo rm -rf /var/lib/glinrdock

# Remove user
sudo userdel glinrdock

# Reload systemd
sudo systemctl daemon-reload
```

### Docker Compose Cleanup
```bash
# Stop services and remove volumes
docker-compose down -v

# Remove images (optional)
docker rmi ghcr.io/glinr/glinrdock:latest
```

## Next Steps

- 📖 [Quick Start Guide](./QUICKSTART.md) - Deploy your first container
- 🔐 [Security Guide](./SECURITY.md) - Production security practices
- 🔧 [Troubleshooting](./docs/Troubleshooting.md) - Common issues and solutions
- 📚 [API Documentation](./docs/API.md) - REST API reference

---

Need help? Check our [troubleshooting guide](./docs/Troubleshooting.md) or [open an issue](https://github.com/glinr/glinrdock/issues).