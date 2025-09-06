# GlinrDock Documentation

> **🚧 COMING SOON** - Currently in development. Star this repo to get notified when we launch!

**Lightweight, Secure Container Management Platform**

GlinrDock is a modern container management platform designed for simplicity, security, and performance. Built for developers and DevOps teams who need reliable container orchestration without the complexity of heavyweight solutions.

## Key Features

- **Lightweight Architecture** - Minimal resource footprint with maximum performance
- **Enterprise Security** - Built-in security hardening and compliance features  
- **Developer Friendly** - Intuitive web interface and comprehensive API
- **Easy Deployment** - Simple installation on Linux, Docker, or Kubernetes
- **Multi-Architecture** - Native support for AMD64 and ARM64 platforms

## Quick Navigation

<div class="grid cards" markdown>

-   :material-rocket-launch:{ .lg .middle } **Quick Start**
    
    ---
    
    Get GlinrDock running in minutes with our streamlined setup guide.
    
    [:octicons-arrow-right-24: Quick Start](QUICKSTART.md)

-   :material-linux:{ .lg .middle } **Linux Installation**
    
    ---
    
    Complete installation guide for Linux systems using various methods.
    
    [:octicons-arrow-right-24: Linux Install](INSTALL_LINUX.md)

-   :material-docker:{ .lg .middle } **Docker Installation**
    
    ---
    
    Run GlinrDock using Docker containers for easy deployment.
    
    [:octicons-arrow-right-24: Docker Install](INSTALL_DOCKER.md)

-   :material-shield-check:{ .lg .middle } **Security Guide**
    
    ---
    
    Learn about security best practices and hardening options.
    
    [:octicons-arrow-right-24: Security](SECURITY.md)

</div>

## Installation Methods

=== "Linux (Recommended)"

    ```bash
    curl -fsSL https://github.com/GLINCKER/glinrdock-release/releases/latest/download/install.sh | sudo bash
    ```

=== "Docker Compose"

    ```bash
    curl -fsSL https://raw.githubusercontent.com/GLINCKER/glinrdock-release/main/packaging/compose/docker-compose.yml -o docker-compose.yml
    echo "ADMIN_TOKEN=$(openssl rand -hex 32)" > .env
    docker compose up -d
    ```

=== "Manual Binary"

    ```bash
    # Download and verify
    curl -LO https://github.com/GLINCKER/glinrdock-release/releases/latest/download/glinrdockd_linux_amd64.tar.gz
    curl -LO https://github.com/GLINCKER/glinrdock-release/releases/latest/download/SHA256SUMS
    sha256sum -c SHA256SUMS --ignore-missing
    
    # Install
    tar -xzf glinrdockd_linux_amd64.tar.gz
    sudo cp glinrdockd_linux_amd64 /usr/local/bin/glinrdockd
    sudo chmod +x /usr/local/bin/glinrdockd
    ```

## Architecture Overview

GlinrDock follows a clean, modular architecture designed for reliability and maintainability:

```mermaid
graph TB
    A[Web Interface] --> B[API Gateway]
    B --> C[Controller Core]
    C --> D[Docker Engine]
    C --> E[Data Store]
    C --> F[Security Layer]
    
    G[CLI Client] --> B
    H[External API] --> B
    
    style C fill:#e1f5fe
    style F fill:#fff3e0
    style D fill:#f3e5f5
```

## First Steps

!!! tip "Quick Start"
    After installation, access the dashboard at **http://localhost:8080** and use your admin token to log in.

1. **Access the Interface** - Open http://localhost:8080 in your browser
2. **Get Admin Token** - Find the token in installation output or config file  
3. **Log In** - Use the admin token to authenticate
4. **Create Project** - Start managing containers with your first project

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

This documentation and binary distribution repository is licensed under the MIT License. See [LICENSE](https://github.com/GLINCKER/glinrdock/blob/main/LICENSE) for details.

The main GlinrDock application source code is maintained in a separate private repository.