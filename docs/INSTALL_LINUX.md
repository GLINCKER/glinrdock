# Linux Installation Guide

This guide covers installing GlinrDock on Linux systems using various methods.

## System Requirements

- Linux kernel 3.10+ (RHEL/CentOS 7+, Ubuntu 16.04+, Debian 9+)
- Docker Engine 20.10+ 
- systemd (for service management)
- 512MB RAM minimum, 2GB recommended
- 1GB available disk space

## Installation Methods

### Method 1: Automated Script (Recommended)

Download and run the installation script:

```bash
curl -fsSL https://github.com/GLINCKER/glinrdock-release/releases/latest/download/install.sh | sudo bash
```

This script will:
- Download the appropriate binary for your architecture
- Install to `/usr/local/bin/glinrdockd`
- Create systemd service unit
- Generate initial configuration
- Start the service

### Method 2: Manual Binary Installation

1. **Download the binary**:
```bash
# For x86_64
curl -LO https://github.com/GLINCKER/glinrdock-release/releases/latest/download/glinrdockd_linux_amd64.tar.gz

# For ARM64
curl -LO https://github.com/GLINCKER/glinrdock-release/releases/latest/download/glinrdockd_linux_arm64.tar.gz
```

2. **Verify the download**:
```bash
curl -LO https://github.com/GLINCKER/glinrdock-release/releases/latest/download/SHA256SUMS
sha256sum -c SHA256SUMS --ignore-missing
```

3. **Extract and install**:
```bash
tar -xzf glinrdockd_linux_*.tar.gz
sudo cp glinrdockd_linux_* /usr/local/bin/glinrdockd
sudo chmod +x /usr/local/bin/glinrdockd
```

4. **Create system user**:
```bash
sudo useradd --system --shell /bin/false --home-dir /var/lib/glinrdock glinrdock
sudo mkdir -p /var/lib/glinrdock /etc/glinrdock
sudo chown glinrdock:glinrdock /var/lib/glinrdock
```

5. **Install systemd service**:
```bash
curl -fsSL https://raw.githubusercontent.com/GLINCKER/glinrdock-release/main/deploy/systemd/glinrdockd.service | sudo tee /etc/systemd/system/glinrdockd.service
sudo systemctl daemon-reload
```

### Method 3: Package Manager Installation

**RPM-based systems (RHEL, CentOS, Fedora)**:
```bash
# Download RPM package
curl -LO https://github.com/GLINCKER/glinrdock-release/releases/latest/download/glinrdockd.rpm
sudo rpm -i glinrdockd.rpm
```

**DEB-based systems (Ubuntu, Debian)**:
```bash
# Download DEB package
curl -LO https://github.com/GLINCKER/glinrdock-release/releases/latest/download/glinrdockd.deb
sudo dpkg -i glinrdockd.deb
```

## Configuration

### Initial Configuration

Create configuration file:
```bash
sudo tee /etc/glinrdock/config.toml << EOF
[server]
bind_addr = "127.0.0.1:8080"
data_dir = "/var/lib/glinrdock"

[auth]
admin_token = "$(openssl rand -hex 32)"

[docker]
socket_path = "/var/run/docker.sock"
EOF
```

### Service Management

Start and enable the service:
```bash
sudo systemctl enable glinrdockd
sudo systemctl start glinrdockd
```

Check service status:
```bash
sudo systemctl status glinrdockd
```

View logs:
```bash
sudo journalctl -u glinrdockd -f
```

## Verification

1. **Check service is running**:
```bash
curl http://localhost:8080/v1/health
```

2. **Access web interface**:
   - Open http://localhost:8080
   - Get admin token: `sudo grep admin_token /etc/glinrdock/config.toml`

## Firewall Configuration

If using firewall, allow access to GlinrDock:

**UFW (Ubuntu)**:
```bash
sudo ufw allow 8080/tcp
```

**firewalld (RHEL/CentOS)**:
```bash
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload
```

## Troubleshooting

- **Service fails to start**: Check logs with `journalctl -u glinrdockd`
- **Permission denied errors**: Verify user is in `docker` group
- **Port binding errors**: Ensure port 8080 is available
- **Docker connection issues**: Verify Docker daemon is running

See [Troubleshooting Guide](TROUBLESHOOTING.md) for more details.

## Next Steps

- [Quick Start Guide](QUICKSTART.md)
- [Uninstall Instructions](UNINSTALL.md)
- [Security Best Practices](SECURITY.md)