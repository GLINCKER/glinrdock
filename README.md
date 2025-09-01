# GlinrDock

**Binary Distribution Repository**

This repository contains release binaries, installation scripts, and documentation for GlinrDock, a lightweight container management platform. The source code is maintained in a separate private repository.

## Installation

### Quick Install
```bash
curl -fsSL https://github.com/GLINCKER/glinrdock-release/releases/latest/download/install.sh | sudo bash
```

### Manual Download
Download the appropriate binary for your platform from the [releases page](https://github.com/GLINCKER/glinrdock-release/releases).

## Supported Platforms

- Linux (x86_64, ARM64)
- macOS (Intel, Apple Silicon)

## Documentation

📖 **[View Full Documentation](https://glincker.github.io/glinrdock-release/)** - Complete installation and usage guide

### Quick Links
- [Quick Start Guide](docs/QUICKSTART.md)
- [Linux Installation](docs/INSTALL_LINUX.md)
- [Docker Installation](docs/INSTALL_DOCKER.md)
- [Uninstall Instructions](docs/UNINSTALL.md)
- [Security Policy](docs/SECURITY.md)
- [FAQ](docs/FAQ.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)

## System Requirements

- Linux kernel 3.10+ or macOS 10.15+
- Docker Engine 20.10+
- 512MB RAM minimum (2GB recommended)
- 1GB available disk space

## Support

- Issues: [GitHub Issues](https://github.com/GLINCKER/glinrdock-release/issues)
- Security: See [Security Policy](docs/SECURITY.md)

## License

This repository contains multiple components with different licensing terms:

- **GlinrDock Controller Binary**: Proprietary software (see [EULA.md](EULA.md))
- **Installation Scripts & Automation**: MIT License (see [LICENSE-SCRIPTS](LICENSE-SCRIPTS))
- **Documentation**: CC BY 4.0 (see [LICENSE-DOCS](LICENSE-DOCS))
- **Third-Party Components**: See [THIRD-PARTY-ATTRIBUTIONS.md](THIRD-PARTY-ATTRIBUTIONS.md)

See [LICENSE](LICENSE) for complete licensing information.

---

**Important**: The GlinrDock controller binary (glinrdockd) is proprietary software owned by GLINCKER LLC. This repository provides only the binary distribution, installation tools, and documentation under permissive licenses. The controller source code is maintained separately and is not open source.