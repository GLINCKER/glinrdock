# Third-Party Attributions

This file contains attributions for third-party software, libraries, and resources used in the GlinrDock distribution repository.

## Documentation Build Tools

### MkDocs Material Theme
- **Project**: MkDocs Material
- **License**: MIT License
- **Source**: https://github.com/squidfunk/mkdocs-material
- **Usage**: Documentation site theme and styling

### GitHub Actions
- **Project**: GitHub Actions Marketplace Actions
- **Licenses**: Various (Apache 2.0, MIT)
- **Usage**: CI/CD automation for documentation builds and releases
- **Actions Used**:
  - actions/checkout
  - actions/setup-python
  - actions/configure-pages
  - actions/deploy-pages
  - actions/upload-pages-artifact
  - docker/setup-qemu-action
  - docker/setup-buildx-action
  - docker/login-action

## Container Base Images

### Distroless Images
- **Project**: Google Distroless
- **License**: Apache License 2.0
- **Source**: https://github.com/GoogleContainerTools/distroless
- **Usage**: Minimal container base image for security

## Installation Dependencies

### Docker
- **Project**: Docker Engine
- **License**: Apache License 2.0
- **Usage**: Container runtime dependency for GlinrDock operation

### systemd
- **Project**: systemd
- **License**: LGPL 2.1+
- **Usage**: Linux service management for native installations

---

**Note**: The GlinrDock controller binary itself is proprietary software owned by GLINCKER LLC and is not covered by the open source licenses in this repository. Only the installation scripts, documentation, and distribution infrastructure are provided under permissive licenses.

For questions about licensing or to report missing attributions, contact: licensing@glincker.com