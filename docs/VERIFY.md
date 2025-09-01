# Binary Verification Guide

This guide covers verifying the integrity and authenticity of GlinrDock binary releases.

## Overview

All GlinrDock releases include:
- **SHA256 checksums** for integrity verification
- **SBOM files** (Software Bill of Materials) when available
- **Sigstore signatures** for authenticity verification (future)

## Checksum Verification

### Download Checksums

```bash
# Download binary and checksum
curl -LO https://github.com/GLINCKER/glinrdock-release/releases/latest/download/glinrdockd_linux_amd64.tar.gz
curl -LO https://github.com/GLINCKER/glinrdock-release/releases/latest/download/glinrdockd_linux_amd64.tar.gz.sha256
```

### Verify Single File

```bash
# Using sha256sum (Linux)
sha256sum -c glinrdockd_linux_amd64.tar.gz.sha256

# Using shasum (macOS)
shasum -a 256 -c glinrdockd_linux_amd64.tar.gz.sha256

# Manual verification
echo "$(cat glinrdockd_linux_amd64.tar.gz.sha256)" | sha256sum -c -
```

### Verify All Files

```bash
# Download combined checksum file
curl -LO https://github.com/GLINCKER/glinrdock-release/releases/latest/download/SHA256SUMS

# Download all binaries for verification
curl -LO https://github.com/GLINCKER/glinrdock-release/releases/latest/download/glinrdockd_linux_amd64.tar.gz
curl -LO https://github.com/GLINCKER/glinrdock-release/releases/latest/download/glinrdockd_linux_arm64.tar.gz
curl -LO https://github.com/GLINCKER/glinrdock-release/releases/latest/download/glinrdockd_darwin_amd64.tar.gz
curl -LO https://github.com/GLINCKER/glinrdock-release/releases/latest/download/glinrdockd_darwin_arm64.tar.gz

# Verify all files
sha256sum -c SHA256SUMS
```

### Expected Output

```bash
$ sha256sum -c glinrdockd_linux_amd64.tar.gz.sha256
glinrdockd_linux_amd64.tar.gz: OK
```

## SBOM Verification

Software Bill of Materials (SBOM) files provide dependency information.

### Download SBOM

```bash
# Download SBOM file (if available)
curl -LO https://github.com/GLINCKER/glinrdock-release/releases/latest/download/glinrdockd_linux_amd64.sbom.spdx.json
```

### Analyze SBOM

```bash
# Install SBOM tools
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin

# Validate SBOM format
syft validate glinrdockd_linux_amd64.sbom.spdx.json

# View SBOM contents
cat glinrdockd_linux_amd64.sbom.spdx.json | jq '.packages[] | {name, versionInfo, licenseConcluded}'
```

## Signature Verification (Future)

*Note: Sigstore signatures will be available in future releases.*

### Install Cosign

```bash
# Install cosign for signature verification
curl -O -L https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64
sudo mv cosign-linux-amd64 /usr/local/bin/cosign
sudo chmod +x /usr/local/bin/cosign
```

### Verify Signatures

```bash
# Verify signature (when available)
cosign verify-blob \
  --certificate-identity=publisher@glinr.dev \
  --certificate-oidc-issuer=https://github.com/login/oauth \
  --signature=glinrdockd_linux_amd64.tar.gz.sig \
  glinrdockd_linux_amd64.tar.gz
```

## Binary Analysis

### File Type Verification

```bash
# Extract and check binary
tar -xzf glinrdockd_linux_amd64.tar.gz
file glinrdockd_linux_amd64
```

Expected output:
```
glinrdockd_linux_amd64: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked, BuildID[sha1]=..., stripped
```

### Architecture Verification

```bash
# Verify correct architecture
objdump -f glinrdockd_linux_amd64 | grep architecture
```

### Static Linking Verification

```bash
# Check for dynamic dependencies (should be none for static binary)
ldd glinrdockd_linux_amd64
```

Expected output for static binary:
```
not a dynamic executable
```

## Automated Verification Script

Create a verification script for automated checks:

```bash
#!/bin/bash
set -euo pipefail

PLATFORM="linux_amd64"
VERSION="${1:-latest}"

if [ "$VERSION" = "latest" ]; then
    BASE_URL="https://github.com/GLINCKER/glinrdock-release/releases/latest/download"
else
    BASE_URL="https://github.com/GLINCKER/glinrdock-release/releases/download/${VERSION}"
fi

BINARY="glinrdockd_${PLATFORM}.tar.gz"
CHECKSUM="glinrdockd_${PLATFORM}.tar.gz.sha256"

echo "Downloading GlinrDock ${VERSION} for ${PLATFORM}..."

# Download files
curl -LO "${BASE_URL}/${BINARY}"
curl -LO "${BASE_URL}/${CHECKSUM}"

# Verify checksum
echo "Verifying checksum..."
if sha256sum -c "${CHECKSUM}"; then
    echo "✅ Checksum verification passed"
else
    echo "❌ Checksum verification failed"
    exit 1
fi

# Extract and verify binary
echo "Extracting and verifying binary..."
tar -xzf "${BINARY}"

BINARY_FILE="${BINARY%.tar.gz}"

# Check file type
if file "${BINARY_FILE}" | grep -q "ELF.*statically linked"; then
    echo "✅ Binary is statically linked ELF"
else
    echo "❌ Binary verification failed"
    exit 1
fi

# Check if executable
if [ -x "${BINARY_FILE}" ]; then
    echo "✅ Binary is executable"
else
    echo "❌ Binary is not executable"
    exit 1
fi

echo "✅ All verifications passed"
echo "Binary: ${BINARY_FILE}"
echo "Ready for installation"
```

Save as `verify.sh` and use:

```bash
chmod +x verify.sh
./verify.sh v1.0.0
```

## Manual Verification Steps

### Complete Verification Workflow

1. **Download Release Files**
   ```bash
   VERSION="v1.0.0"
   PLATFORM="linux_amd64"
   
   curl -LO "https://github.com/GLINCKER/glinrdock-release/releases/download/${VERSION}/glinrdockd_${PLATFORM}.tar.gz"
   curl -LO "https://github.com/GLINCKER/glinrdock-release/releases/download/${VERSION}/glinrdockd_${PLATFORM}.tar.gz.sha256"
   curl -LO "https://github.com/GLINCKER/glinrdock-release/releases/download/${VERSION}/SHA256SUMS"
   ```

2. **Verify Checksums**
   ```bash
   # Individual file
   sha256sum -c "glinrdockd_${PLATFORM}.tar.gz.sha256"
   
   # Or from combined file
   sha256sum -c SHA256SUMS
   ```

3. **Extract and Inspect**
   ```bash
   tar -xzf "glinrdockd_${PLATFORM}.tar.gz"
   file "glinrdockd_${PLATFORM}"
   ls -la "glinrdockd_${PLATFORM}"
   ```

4. **Test Basic Functionality**
   ```bash
   # Test help command (should not require Docker)
   ./glinrdockd_linux_amd64 --help
   
   # Test version command
   ./glinrdockd_linux_amd64 --version
   ```

## Verification Failures

### Common Issues

**Checksum mismatch:**
- Re-download the file
- Check for network issues during download
- Verify you downloaded from official GitHub releases

**File not found:**
- Check release exists for your platform
- Verify URL is correct
- Check GitHub releases page for available files

**Binary not executable:**
- Check file permissions: `chmod +x glinrdockd_linux_amd64`
- Verify architecture matches your system
- Check for file corruption

### Troubleshooting

```bash
# Check download integrity
ls -la glinrdockd_*

# Verify file is not corrupted
hexdump -C glinrdockd_linux_amd64.tar.gz | head

# Check network/proxy issues
curl -v https://github.com/GLINCKER/glinrdock-release/releases/latest

# Manual checksum calculation
sha256sum glinrdockd_linux_amd64.tar.gz
```

## Security Considerations

### Verification Best Practices

1. **Always verify checksums** before installation
2. **Download from official sources** only
3. **Use HTTPS** for all downloads
4. **Check file permissions** after extraction
5. **Scan for malware** if required by policy
6. **Keep verification logs** for audit trails

### Supply Chain Security

- All binaries are built from source in GitHub Actions
- Build process is reproducible and auditable
- Dependencies are pinned to specific versions
- SBOM files document all included components

### Reporting Issues

If verification fails or you suspect tampering:
1. **Do not install** the binary
2. **Document** the verification failure
3. **Report** to security@glinr.dev
4. **Include** all error messages and file details

## Integration with CI/CD

### GitHub Actions Example

```yaml
- name: Verify GlinrDock Binary
  run: |
    curl -LO https://github.com/GLINCKER/glinrdock-release/releases/latest/download/glinrdockd_linux_amd64.tar.gz
    curl -LO https://github.com/GLINCKER/glinrdock-release/releases/latest/download/glinrdockd_linux_amd64.tar.gz.sha256
    sha256sum -c glinrdockd_linux_amd64.tar.gz.sha256
```

### Docker Build Example

```dockerfile
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y curl
RUN curl -LO https://github.com/GLINCKER/glinrdock-release/releases/latest/download/glinrdockd_linux_amd64.tar.gz
RUN curl -LO https://github.com/GLINCKER/glinrdock-release/releases/latest/download/glinrdockd_linux_amd64.tar.gz.sha256
RUN sha256sum -c glinrdockd_linux_amd64.tar.gz.sha256
RUN tar -xzf glinrdockd_linux_amd64.tar.gz
RUN cp glinrdockd_linux_amd64 /usr/local/bin/glinrdockd
```