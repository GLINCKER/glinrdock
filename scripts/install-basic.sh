#!/bin/sh
set -eu

# GlinrDock POSIX Installer
# Safe installation script with checksum verification and dry-run support

# Default configuration
DEFAULT_PREFIX="/usr/local"
DEFAULT_CHANNEL="stable"
DEFAULT_BIN_NAME="glinrdockd"
DEFAULT_BASE_URL="https://github.com/GLINCKER/glinrdock-release/releases"

# Configuration from environment or defaults
GLINR_VERSION="${GLINR_VERSION:-latest}"
GLINR_BASE_URL="${GLINR_BASE_URL:-$DEFAULT_BASE_URL}"
GLINR_BIN_NAME="${GLINR_BIN_NAME:-$DEFAULT_BIN_NAME}"
GLINR_DESTDIR="${GLINR_DESTDIR:-$DEFAULT_PREFIX}"

# Script variables
DRY_RUN=false
PREFIX="$GLINR_DESTDIR"
CHANNEL="$DEFAULT_CHANNEL"
TEMP_DIR=""

# Terminal colors (disabled if not a terminal)
if [ -t 1 ] && [ -t 2 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

# Logging functions
log() {
    printf "${GREEN}[INFO]${NC} %s\n" "$1" >&2
}

warn() {
    printf "${YELLOW}[WARN]${NC} %s\n" "$1" >&2
}

error() {
    printf "${RED}[ERROR]${NC} %s\n" "$1" >&2
    exit 1
}

debug() {
    if [ "${DEBUG:-}" = "1" ]; then
        printf "${BLUE}[DEBUG]${NC} %s\n" "$1" >&2
    fi
}

# Print usage information
usage() {
    cat << 'EOF'
GlinrDock POSIX Installer

USAGE:
    install.sh [OPTIONS]

OPTIONS:
    --dry-run           Show what would be done without making changes
    --prefix DIR        Installation prefix (default: /usr/local)
    --channel CHANNEL   Release channel: stable|nightly (default: stable)
    --help              Show this help message

ENVIRONMENT VARIABLES:
    GLINR_VERSION       Version to install (default: latest)
    GLINR_BASE_URL      Base URL for downloads (default: GitHub releases)
    GLINR_BIN_NAME      Binary name (default: glinrdockd)
    GLINR_DESTDIR       Destination directory (default: /usr/local)
    DEBUG               Enable debug output (set to 1)

EXAMPLES:
    # Basic installation
    ./install.sh

    # Dry run to see what would happen
    ./install.sh --dry-run

    # Install to custom location
    ./install.sh --prefix /opt/glinrdock

    # Install specific version
    GLINR_VERSION=v1.0.0 ./install.sh

    # Test against local server
    GLINR_BASE_URL=http://localhost:8000 ./install.sh --dry-run

EOF
}

# Parse command line arguments
parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --dry-run)
                DRY_RUN=true
                ;;
            --prefix)
                if [ $# -lt 2 ]; then
                    error "Option --prefix requires an argument"
                fi
                PREFIX="$2"
                shift
                ;;
            --channel)
                if [ $# -lt 2 ]; then
                    error "Option --channel requires an argument"
                fi
                case "$2" in
                    stable|nightly)
                        CHANNEL="$2"
                        ;;
                    *)
                        error "Invalid channel: $2. Must be 'stable' or 'nightly'"
                        ;;
                esac
                shift
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            *)
                error "Unknown option: $1. Use --help for usage information"
                ;;
        esac
        shift
    done
}

# Detect operating system
detect_os() {
    case "$(uname -s)" in
        Linux*)
            echo "linux"
            ;;
        Darwin*)
            echo "darwin"
            ;;
        *)
            error "Unsupported operating system: $(uname -s). Supported: Linux, macOS"
            ;;
    esac
}

# Detect architecture
detect_arch() {
    case "$(uname -m)" in
        x86_64|amd64)
            echo "amd64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        *)
            error "Unsupported architecture: $(uname -m). Supported: x86_64, arm64"
            ;;
    esac
}

# Check if running as root when needed
check_permissions() {
    # Check if we can write to the destination directory
    if [ "$DRY_RUN" = "false" ]; then
        bin_dir="$PREFIX/bin"
        
        # Check if directory exists and is writable, or if we can create it
        if [ -d "$bin_dir" ]; then
            if [ ! -w "$bin_dir" ]; then
                error "Cannot write to $bin_dir. Try running with sudo or use --prefix to specify a writable location"
            fi
        else
            # Check if we can create the parent directory
            parent_dir="$(dirname "$bin_dir")"
            while [ ! -d "$parent_dir" ] && [ "$parent_dir" != "/" ]; do
                parent_dir="$(dirname "$parent_dir")"
            done
            
            if [ ! -w "$parent_dir" ]; then
                error "Cannot create $bin_dir. Try running with sudo or use --prefix to specify a writable location"
            fi
        fi
    fi
}

# Check required tools
check_dependencies() {
    debug "Checking required dependencies"
    
    # Check for required commands
    for cmd in curl tar; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            error "Required command not found: $cmd. Please install it and try again"
        fi
        debug "Found required command: $cmd"
    done
    
    # Check for checksum command
    if command -v sha256sum >/dev/null 2>&1; then
        CHECKSUM_CMD="sha256sum"
    elif command -v shasum >/dev/null 2>&1; then
        CHECKSUM_CMD="shasum -a 256"
    else
        error "No checksum command found. Please install sha256sum or shasum"
    fi
    debug "Using checksum command: $CHECKSUM_CMD"
}

# Create temporary directory
create_temp_dir() {
    if command -v mktemp >/dev/null 2>&1; then
        TEMP_DIR="$(mktemp -d)"
    else
        TEMP_DIR="/tmp/glinrdock-install-$$"
        mkdir -p "$TEMP_DIR"
    fi
    debug "Created temporary directory: $TEMP_DIR"
}

# Cleanup function
cleanup() {
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
        debug "Cleaned up temporary directory: $TEMP_DIR"
    fi
}

# Set up cleanup trap
trap cleanup EXIT INT TERM

# Construct download URL
get_download_url() {
    local os="$1"
    local arch="$2"
    local filename="${GLINR_BIN_NAME}_${os}_${arch}.tar.gz"
    
    if [ "$GLINR_VERSION" = "latest" ]; then
        echo "${GLINR_BASE_URL}/latest/download/${filename}"
    else
        echo "${GLINR_BASE_URL}/download/${GLINR_VERSION}/${filename}"
    fi
}

# Download file with curl
download_file() {
    local url="$1"
    local output="$2"
    local description="$3"
    
    log "Downloading $description from $url"
    
    if [ "$DRY_RUN" = "true" ]; then
        log "[DRY-RUN] Would download: $url -> $output"
        return 0
    fi
    
    if ! curl -fsSL --connect-timeout 10 --max-time 300 "$url" -o "$output"; then
        error "Failed to download $description from $url"
    fi
    
    if [ ! -f "$output" ]; then
        error "Download failed: file not created at $output"
    fi
    
    debug "Successfully downloaded: $output"
}

# Verify checksum
verify_checksum() {
    local archive_file="$1"
    local checksum_file="$2"
    
    log "Verifying checksum for $(basename "$archive_file")"
    
    if [ "$DRY_RUN" = "true" ]; then
        log "[DRY-RUN] Would verify checksum using $CHECKSUM_CMD"
        return 0
    fi
    
    if [ ! -f "$checksum_file" ]; then
        error "Checksum file not found: $checksum_file"
    fi
    
    # Extract expected checksum and filename from checksum file
    expected_checksum="$(awk '{print $1}' "$checksum_file")"
    
    if [ -z "$expected_checksum" ]; then
        error "Could not extract checksum from $checksum_file"
    fi
    
    # Calculate actual checksum
    cd "$(dirname "$archive_file")"
    actual_checksum="$($CHECKSUM_CMD "$(basename "$archive_file")" | awk '{print $1}')"
    
    if [ "$actual_checksum" != "$expected_checksum" ]; then
        error "Checksum verification failed!
Expected: $expected_checksum
Actual:   $actual_checksum

This could indicate a corrupted download or a security issue.
Please try downloading again or report this issue."
    fi
    
    log "Checksum verification passed"
}

# Extract archive
extract_archive() {
    local archive_file="$1"
    local extract_dir="$2"
    
    log "Extracting $(basename "$archive_file")"
    
    if [ "$DRY_RUN" = "true" ]; then
        log "[DRY-RUN] Would extract: $archive_file -> $extract_dir"
        return 0
    fi
    
    if ! tar -xzf "$archive_file" -C "$extract_dir"; then
        error "Failed to extract archive: $archive_file"
    fi
    
    debug "Successfully extracted archive to: $extract_dir"
}

# Install binary
install_binary() {
    local os="$1"
    local arch="$2"
    local extract_dir="$3"
    
    local binary_name="${GLINR_BIN_NAME}_${os}_${arch}"
    local source_binary="$extract_dir/$binary_name"
    local dest_dir="$PREFIX/bin"
    local dest_binary="$dest_dir/$GLINR_BIN_NAME"
    
    log "Installing binary to $dest_binary"
    
    if [ "$DRY_RUN" = "true" ]; then
        log "[DRY-RUN] Would create directory: $dest_dir"
        log "[DRY-RUN] Would copy: $source_binary -> $dest_binary"
        log "[DRY-RUN] Would set permissions: chmod 755 $dest_binary"
        return 0
    fi
    
    # Check if extracted binary exists
    if [ ! -f "$source_binary" ]; then
        error "Extracted binary not found: $source_binary"
    fi
    
    # Create destination directory
    if ! mkdir -p "$dest_dir"; then
        error "Failed to create directory: $dest_dir"
    fi
    
    # Copy binary
    if ! cp "$source_binary" "$dest_binary"; then
        error "Failed to copy binary to: $dest_binary"
    fi
    
    # Set executable permissions
    if ! chmod 755 "$dest_binary"; then
        error "Failed to set permissions on: $dest_binary"
    fi
    
    log "Binary installed successfully"
}

# Verify installation
verify_installation() {
    local dest_binary="$PREFIX/bin/$GLINR_BIN_NAME"
    
    if [ "$DRY_RUN" = "true" ]; then
        log "[DRY-RUN] Would verify installation at: $dest_binary"
        return 0
    fi
    
    if [ ! -f "$dest_binary" ]; then
        error "Installation verification failed: binary not found at $dest_binary"
    fi
    
    if [ ! -x "$dest_binary" ]; then
        error "Installation verification failed: binary not executable at $dest_binary"
    fi
    
    # Test binary execution (version check)
    if ! "$dest_binary" --version >/dev/null 2>&1; then
        warn "Binary installed but --version check failed. This may be normal for some versions."
    fi
    
    log "Installation verification passed"
}

# Print installation summary
print_summary() {
    local os="$1"
    local arch="$2"
    local dest_binary="$PREFIX/bin/$GLINR_BIN_NAME"
    
    printf "\n"
    printf "================================================================\n"
    printf "             GlinrDock Installation Complete\n"
    printf "================================================================\n"
    printf "\n"
    
    if [ "$DRY_RUN" = "true" ]; then
        printf "DRY-RUN MODE: No changes were made to your system.\n"
        printf "\n"
        printf "The following would have been installed:\n"
    else
        printf "Installation successful!\n"
        printf "\n"
    fi
    
    printf "Binary:      %s\n" "$dest_binary"
    printf "Platform:    %s/%s\n" "$os" "$arch"
    printf "Version:     %s\n" "$GLINR_VERSION"
    printf "Channel:     %s\n" "$CHANNEL"
    printf "\n"
    
    if [ "$DRY_RUN" = "false" ]; then
        printf "Next Steps:\n"
        printf "\n"
        printf "1. Test the installation:\n"
        printf "   %s --version\n" "$dest_binary"
        printf "\n"
        printf "2. Create configuration directory:\n"
        printf "   sudo mkdir -p /etc/glinrdock\n"
        printf "\n"
        printf "3. Create configuration file:\n"
        printf "   sudo tee /etc/glinrdock/glinrdock.conf > /dev/null << 'EOF'\n"
        printf "GLINRDOCK_BIND_ADDR=0.0.0.0:8080\n"
        printf "GLINRDOCK_DATA_DIR=/var/lib/glinrdock/data\n"
        printf "ADMIN_TOKEN=your-secure-admin-token-change-this\n"
        printf "EOF\n"
        printf "\n"
        printf "4. Create data directory:\n"
        printf "   sudo mkdir -p /var/lib/glinrdock/data\n"
        printf "   sudo useradd --system --user-group --home-dir /var/lib/glinrdock glinrdock\n"
        printf "   sudo chown -R glinrdock:glinrdock /var/lib/glinrdock\n"
        printf "\n"
        printf "5. Optional: Create systemd service:\n"
        printf "   sudo tee /etc/systemd/system/glinrdock.service > /dev/null << 'EOF'\n"
        printf "[Unit]\n"
        printf "Description=GlinrDock Container Management\n"
        printf "After=network.target docker.service\n"
        printf "Wants=docker.service\n"
        printf "\n"
        printf "[Service]\n"
        printf "Type=exec\n"
        printf "User=glinrdock\n"
        printf "Group=glinrdock\n"
        printf "EnvironmentFile=/etc/glinrdock/glinrdock.conf\n"
        printf "ExecStart=%s\n" "$dest_binary"
        printf "Restart=always\n"
        printf "RestartSec=3\n"
        printf "\n"
        printf "[Install]\n"
        printf "WantedBy=multi-user.target\n"
        printf "EOF\n"
        printf "\n"
        printf "   sudo systemctl daemon-reload\n"
        printf "   sudo systemctl enable glinrdock.service\n"
        printf "   sudo systemctl start glinrdock.service\n"
        printf "\n"
        printf "6. Access the dashboard:\n"
        printf "   Open http://localhost:8080 in your browser\n"
        printf "\n"
    fi
    
    printf "Documentation:\n"
    printf "   Installation: https://github.com/GLINCKER/glinrdock-release/blob/main/docs/INSTALL.md\n"
    printf "   Configuration: https://github.com/GLINCKER/glinrdock-release/blob/main/docs/CONFIG.md\n"
    printf "   Troubleshooting: https://github.com/GLINCKER/glinrdock-release/blob/main/docs/TROUBLESHOOTING.md\n"
    printf "\n"
    
    if [ "$DRY_RUN" = "false" ]; then
        printf "To uninstall: run the uninstall script from the same location\n"
        printf "\n"
    fi
}

# Main installation function
main() {
    log "Starting GlinrDock installation"
    
    # Parse command line arguments
    parse_args "$@"
    
    # Show configuration
    debug "Configuration:"
    debug "  DRY_RUN=$DRY_RUN"
    debug "  PREFIX=$PREFIX"
    debug "  CHANNEL=$CHANNEL"
    debug "  GLINR_VERSION=$GLINR_VERSION"
    debug "  GLINR_BASE_URL=$GLINR_BASE_URL"
    debug "  GLINR_BIN_NAME=$GLINR_BIN_NAME"
    
    if [ "$DRY_RUN" = "true" ]; then
        log "Running in DRY-RUN mode - no changes will be made"
    fi
    
    # Detect system
    os="$(detect_os)"
    arch="$(detect_arch)"
    log "Detected platform: $os/$arch"
    
    # Check permissions and dependencies
    check_permissions
    check_dependencies
    
    # Create temporary directory
    create_temp_dir
    
    # Construct URLs
    archive_url="$(get_download_url "$os" "$arch")"
    checksum_url="${archive_url}.sha256"
    
    # File paths
    archive_file="$TEMP_DIR/$(basename "$archive_url")"
    checksum_file="$TEMP_DIR/$(basename "$checksum_url")"
    extract_dir="$TEMP_DIR/extract"
    
    debug "Download URLs:"
    debug "  Archive: $archive_url"
    debug "  Checksum: $checksum_url"
    
    # Create extraction directory
    if [ "$DRY_RUN" = "false" ]; then
        mkdir -p "$extract_dir"
    fi
    
    # Download files
    download_file "$archive_url" "$archive_file" "binary archive"
    download_file "$checksum_url" "$checksum_file" "checksum file"
    
    # Verify checksum
    verify_checksum "$archive_file" "$checksum_file"
    
    # Extract archive
    extract_archive "$archive_file" "$extract_dir"
    
    # Install binary
    install_binary "$os" "$arch" "$extract_dir"
    
    # Verify installation
    verify_installation
    
    # Print summary
    print_summary "$os" "$arch"
    
    log "Installation completed successfully"
}

# Run main function with all arguments
main "$@"