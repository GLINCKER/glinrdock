#!/usr/bin/env bash
set -euo pipefail

# GlinrDock Release Script
# Builds cross-platform binaries and optionally signs them with cosign

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
VERSION="${VERSION:-$(git describe --tags --always --dirty)}"
BUILD_TIME="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
COMMIT="$(git rev-parse HEAD)"

# Build configuration
BINARY_NAME="glinrdockd"
BUILD_DIR="${PROJECT_ROOT}/build"
STAGING_DIR="${PROJECT_ROOT}/_staging/${VERSION}"

# Platform targets
PLATFORMS=(
    "linux/amd64"
    "linux/arm64" 
    "darwin/amd64"
    "darwin/arm64"
)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_dependencies() {
    log_info "Checking build dependencies..."
    
    local missing_deps=()
    
    command -v go >/dev/null 2>&1 || missing_deps+=("go")
    command -v tar >/dev/null 2>&1 || missing_deps+=("tar")
    
    if ! command -v sha256sum >/dev/null 2>&1 && ! command -v shasum >/dev/null 2>&1; then
        missing_deps+=("sha256sum or shasum")
    fi
    
    if [[ -n "${COSIGN_PASSWORD:-}" && -n "${COSIGN_KEY:-}" ]]; then
        command -v cosign >/dev/null 2>&1 || missing_deps+=("cosign")
        log_info "Cosign signing enabled"
    else
        log_warning "Cosign signing disabled (COSIGN_PASSWORD and COSIGN_KEY not both set)"
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        exit 1
    fi
    
    log_success "All dependencies verified"
}

build_binaries() {
    log_info "Building GlinrDock ${VERSION} for all platforms..."
    
    mkdir -p "${BUILD_DIR}"
    
    local ldflags="-s -w -X main.version=${VERSION} -X main.buildTime=${BUILD_TIME} -X main.commit=${COMMIT}"
    
    for platform in "${PLATFORMS[@]}"; do
        local os="${platform%/*}"
        local arch="${platform#*/}"
        local output="${BUILD_DIR}/${BINARY_NAME}_${os}_${arch}"
        
        log_info "Building for ${os}/${arch}..."
        
        CGO_ENABLED=0 GOOS="${os}" GOARCH="${arch}" go build \
            -ldflags="${ldflags}" \
            -trimpath \
            -o "${output}" \
            ./cmd/${BINARY_NAME}
    done
    
    log_success "Build complete"
}

create_packages() {
    log_info "Creating release packages..."
    
    mkdir -p "${STAGING_DIR}"
    
    for platform in "${PLATFORMS[@]}"; do
        local os="${platform%/*}"
        local arch="${platform#*/}"
        local binary="${BUILD_DIR}/${BINARY_NAME}_${os}_${arch}"
        local tarball="${STAGING_DIR}/${BINARY_NAME}_${os}_${arch}.tar.gz"
        
        log_info "Packaging ${os}/${arch}..."
        
        tar -czf "${tarball}" -C "${BUILD_DIR}" "${BINARY_NAME}_${os}_${arch}"
    done
    
    log_success "Packages created"
}

generate_checksums() {
    log_info "Generating checksums..."
    
    cd "${STAGING_DIR}"
    
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum *.tar.gz > SHA256SUMS
    else
        shasum -a 256 *.tar.gz > SHA256SUMS
    fi
    
    log_success "Checksums generated"
}

sign_artifacts() {
    if [[ -z "${COSIGN_PASSWORD:-}" || -z "${COSIGN_KEY:-}" ]]; then
        log_warning "Skipping artifact signing (COSIGN_PASSWORD and COSIGN_KEY not both set)"
        return 0
    fi
    
    log_info "Signing artifacts with cosign..."
    
    cd "${STAGING_DIR}"
    
    local files_to_sign=(*.tar.gz SHA256SUMS)
    
    for file in "${files_to_sign[@]}"; do
        if [[ -f "${file}" ]]; then
            log_info "Signing ${file}..."
            
            cosign sign-blob \
                --key env://COSIGN_KEY \
                --output-signature "${file}.sig" \
                "${file}"
        fi
    done
    
    log_success "Artifact signing complete"
}

verify_release() {
    log_info "Verifying release artifacts..."
    
    cd "${STAGING_DIR}"
    
    # Verify checksums
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum -c SHA256SUMS
    else
        shasum -a 256 -c SHA256SUMS
    fi
    
    # Count artifacts
    local tarballs
    tarballs=$(ls -1 *.tar.gz 2>/dev/null | wc -l)
    local expected_tarballs=${#PLATFORMS[@]}
    
    if [[ "${tarballs}" -eq "${expected_tarballs}" ]]; then
        log_success "All ${tarballs} platform tarballs present"
    else
        log_error "Expected ${expected_tarballs} tarballs, found ${tarballs}"
        exit 1
    fi
    
    # Check for signatures if signing was enabled
    if [[ -n "${COSIGN_PASSWORD:-}" && -n "${COSIGN_KEY:-}" ]]; then
        local signatures
        signatures=$(ls -1 *.sig 2>/dev/null | wc -l)
        local expected_signatures=$((expected_tarballs + 1)) # +1 for SHA256SUMS.sig
        
        if [[ "${signatures}" -eq "${expected_signatures}" ]]; then
            log_success "All ${signatures} signatures present"
        else
            log_warning "Expected ${expected_signatures} signatures, found ${signatures}"
        fi
    fi
    
    log_success "Release verification complete"
}

print_summary() {
    log_info "Release ${VERSION} summary:"
    echo
    echo "Artifacts location: ${STAGING_DIR}"
    echo
    echo "Files:"
    ls -la "${STAGING_DIR}"
    echo
    
    if [[ -n "${COSIGN_PASSWORD:-}" && -n "${COSIGN_KEY:-}" ]]; then
        echo "Signatures created with cosign"
        echo "To verify signatures:"
        echo "  1. Extract public key: cosign public-key --key env://COSIGN_KEY > cosign.pub"
        echo "  2. Verify: cosign verify-blob --key cosign.pub --signature file.sig file"
        echo
    fi
    
    echo "Upload to GitHub release:"
    echo "  gh release create ${VERSION} ${STAGING_DIR}/* --draft --title \"GlinrDock ${VERSION}\""
}

main() {
    log_info "Starting GlinrDock release process..."
    
    check_dependencies
    build_binaries
    create_packages
    generate_checksums
    sign_artifacts
    verify_release
    print_summary
    
    log_success "Release process complete!"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi