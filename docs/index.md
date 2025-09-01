# GlinrDock Documentation

**Container management platform - binary distribution and installation guide**

GlinrDock is a lightweight, secure container management platform designed for production environments. This documentation covers installation, configuration, and operation of the binary distribution.

## Overview

GlinrDock provides:
- Web-based container management interface
- REST API for programmatic control
- Multi-architecture binary support
- Secure default configuration
- Minimal resource footprint

## Quick Install

### Linux with systemd (Recommended)
```bash
curl -fsSL https://github.com/GLINCKER/glinrdock-release/releases/latest/download/install.sh | sudo bash
```

### Docker Compose
```bash
curl -fsSL https://raw.githubusercontent.com/GLINCKER/glinrdock-release/main/deploy/docker-compose.yml -o docker-compose.yml
docker-compose up -d
```

### Manual Installation
```bash
# Download binary for your platform
curl -LO https://github.com/GLINCKER/glinrdock-release/releases/latest/download/glinrdockd_linux_amd64.tar.gz

# Verify checksum
curl -LO https://github.com/GLINCKER/glinrdock-release/releases/latest/download/glinrdockd_linux_amd64.tar.gz.sha256
sha256sum -c glinrdockd_linux_amd64.tar.gz.sha256

# Extract and install
tar -xzf glinrdockd_linux_amd64.tar.gz
sudo cp glinrdockd_linux_amd64 /usr/local/bin/glinrdockd
sudo chmod +x /usr/local/bin/glinrdockd
```

## First Steps

After installation:
1. Access the dashboard at http://localhost:8080
2. Locate your admin token in the installation output or configuration file
3. Log in with the admin token
4. Create your first container project

## System Requirements

- **OS**: Linux kernel 3.10+ or macOS 10.15+
- **Memory**: 512MB minimum, 2GB recommended
- **Storage**: 1GB available space
- **Network**: Port 8080 available
- **Dependencies**: Docker Engine 20.10+

## Supported Platforms

| Platform | Architecture | Binary Package |
|----------|--------------|----------------|
| Linux | x86_64 | `glinrdockd_linux_amd64.tar.gz` |
| Linux | ARM64 | `glinrdockd_linux_arm64.tar.gz` |
| macOS | x86_64 | `glinrdockd_darwin_amd64.tar.gz` |
| macOS | ARM64 | `glinrdockd_darwin_arm64.tar.gz` |

## Documentation Index

### Installation
- [Installation Guide](INSTALL.md) - Comprehensive installation methods
- [Upgrade Guide](UPGRADE.md) - Version upgrade procedures
- [Local Testing](LOCAL_TESTING.md) - Testing before production deployment

### Operation
- [Configuration](CONFIG.md) - Configuration options and environment variables
- [Security](SECURITY.md) - Security practices and vulnerability reporting
- [Troubleshooting](TROUBLESHOOTING.md) - Common issues and solutions

### Reference
- [Verification](VERIFY.md) - Binary verification and checksum validation
- [FAQ](FAQ.md) - Frequently asked questions
- [Support](SUPPORT.md) - Getting help and support options
- [Release Process](RELEASE_PROCESS.md) - Release and versioning information

## Getting Help

- **Issues**: Report bugs at [GitHub Issues](https://github.com/GLINCKER/glinrdock-release/issues)
- **Documentation**: Browse the [docs directory](https://github.com/GLINCKER/glinrdock-release/tree/main/docs)
- **Security**: See [security reporting](SECURITY.md) for vulnerability disclosure

## License

This documentation and binary distribution repository is licensed under the MIT License. See [LICENSE](../LICENSE) for details.

The main GlinrDock application source code is maintained in a separate private repository.