#!/bin/sh
set -e

# GlinrDock Linux Installer
# POSIX compliant installation script for GlinrDock
#
# Copyright (c) 2025 GLINCKER LLC
# Licensed under MIT License (see LICENSE-SCRIPTS)

# Default configuration
DEFAULT_VERSION="latest"
DEFAULT_CHANNEL="stable"
DEFAULT_PREFIX="/usr/local"
DEFAULT_BIND_ADDR=":8080"
GITHUB_REPO="GLINCKER/glinrdock-release"
SERVICE_USER="glinrdock"
SERVICE_NAME="glinrdockd"

# Global variables
VERSION=""
CHANNEL=""
PREFIX=""
BIND_ADDR=""
NON_INTERACTIVE=0
FORCE=0

# Colors for output (if terminal supports it)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log_info() {
    printf "${BLUE}[INFO]${NC} %s\n" "$1"
}

log_success() {
    printf "${GREEN}[SUCCESS]${NC} %s\n" "$1"
}

log_warning() {
    printf "${YELLOW}[WARNING]${NC} %s\n" "$1"
}

log_error() {
    printf "${RED}[ERROR]${NC} %s\n" "$1" >&2
}

# Usage information
usage() {
    cat << EOF
GlinrDock Linux Installer

USAGE:
    install.sh [OPTIONS]

OPTIONS:
    --version VERSION      Install specific version (default: latest)
    --channel CHANNEL      Release channel: stable|edge (default: stable)
    --bind ADDR            Override bind address (default: :8080)
    --prefix PATH          Installation prefix (default: /usr/local)
    --non-interactive      Run without prompts for CI/automation
    --force               Force reinstallation over existing installation
    --help                Show this help message

EXAMPLES:
    # Install latest stable version
    sudo ./install.sh

    # Install specific version
    sudo ./install.sh --version v1.2.3

    # Install with custom bind address
    sudo ./install.sh --bind 127.0.0.1:9090

    # Non-interactive installation for CI
    sudo ./install.sh --non-interactive

REQUIREMENTS:
    - Root privileges (run with sudo)
    - Docker Engine installed and running
    - systemd init system
    - curl or wget available
    - tar and gzip available

EOF
}

# Parse command line arguments
parse_args() {
    while [ $# -gt 0 ]; do
        case $1 in
            --version)
                VERSION="$2"
                shift 2
                ;;
            --channel)
                CHANNEL="$2"
                case $CHANNEL in
                    stable|edge) ;;
                    *) log_error "Invalid channel: $CHANNEL. Use 'stable' or 'edge'"; exit 1 ;;
                esac
                shift 2
                ;;
            --bind)
                BIND_ADDR="$2"
                shift 2
                ;;
            --prefix)
                PREFIX="$2"
                shift 2
                ;;
            --non-interactive)
                NON_INTERACTIVE=1
                shift
                ;;
            --force)
                FORCE=1
                shift
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done

    # Set defaults for unspecified values
    VERSION=${VERSION:-$DEFAULT_VERSION}
    CHANNEL=${CHANNEL:-$DEFAULT_CHANNEL}
    PREFIX=${PREFIX:-$DEFAULT_PREFIX}
    BIND_ADDR=${BIND_ADDR:-$DEFAULT_BIND_ADDR}
}

# Check if running as root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        log_error "This script must be run as root. Please use sudo."
        exit 1
    fi
}

# Detect system architecture
detect_arch() {
    arch=$(uname -m)
    case $arch in
        x86_64|amd64)
            echo "amd64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        *)
            log_error "Unsupported architecture: $arch"
            log_error "Supported architectures: x86_64 (amd64), aarch64 (arm64)"
            exit 1
            ;;
    esac
}

# Check required dependencies
check_dependencies() {
    log_info "Checking system dependencies..."
    
    # Check for required commands
    for cmd in curl tar gzip systemctl; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log_error "Required command not found: $cmd"
            case $cmd in
                curl)
                    log_error "Please install curl: apt-get install curl (Debian/Ubuntu) or yum install curl (RHEL/CentOS)"
                    ;;
                systemctl)
                    log_error "systemd is required for service management"
                    ;;
            esac
            exit 1
        fi
    done
    
    # Check Docker
    if ! command -v docker >/dev/null 2>&1; then
        log_warning "Docker not found. GlinrDock requires Docker Engine to manage containers."
        if [ $NON_INTERACTIVE -eq 0 ]; then
            printf "Continue installation without Docker? [y/N]: "
            read -r response
            case $response in
                [Yy]*) ;;
                *) log_error "Docker is required. Please install Docker first."; exit 1 ;;
            esac
        fi
    else
        if ! systemctl is-active --quiet docker; then
            log_warning "Docker service is not running"
            log_info "Starting Docker service..."
            systemctl start docker || {
                log_error "Failed to start Docker service"
                exit 1
            }
        fi
    fi
    
    log_success "Dependencies check passed"
}

# Get latest release version from GitHub API
get_latest_version() {
    log_info "Fetching latest version from GitHub..."
    
    # Try curl first, fallback to wget
    if command -v curl >/dev/null 2>&1; then
        latest=$(curl -s "https://api.github.com/repos/$GITHUB_REPO/releases/latest" | \
                 grep '"tag_name":' | \
                 sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')
    elif command -v wget >/dev/null 2>&1; then
        latest=$(wget -qO- "https://api.github.com/repos/$GITHUB_REPO/releases/latest" | \
                 grep '"tag_name":' | \
                 sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')
    else
        log_error "Neither curl nor wget found. Cannot fetch version information."
        exit 1
    fi
    
    if [ -z "$latest" ]; then
        log_error "Failed to fetch latest version from GitHub API"
        exit 1
    fi
    
    echo "$latest"
}

# Download and verify release files
download_release() {
    local version="$1"
    local arch="$2"
    local temp_dir="/tmp/glinrdock-install-$$"
    
    # Resolve version
    if [ "$version" = "latest" ]; then
        version=$(get_latest_version)
        log_info "Latest version: $version"
    fi
    
    log_info "Downloading GlinrDock $version for linux/$arch..."
    
    # Create temporary directory
    mkdir -p "$temp_dir"
    cd "$temp_dir"
    
    # Construct download URLs
    local base_url="https://github.com/$GITHUB_REPO/releases/download/$version"
    local tarball="${SERVICE_NAME}_linux_${arch}.tar.gz"
    local checksum_file="SHA256SUMS"
    
    # Download tarball and checksums
    if command -v curl >/dev/null 2>&1; then
        curl -L -o "$tarball" "$base_url/$tarball" || {
            log_error "Failed to download $tarball"
            cleanup_temp "$temp_dir"
            exit 1
        }
        curl -L -o "$checksum_file" "$base_url/$checksum_file" || {
            log_error "Failed to download $checksum_file"
            cleanup_temp "$temp_dir"
            exit 1
        }
    else
        wget -O "$tarball" "$base_url/$tarball" || {
            log_error "Failed to download $tarball"
            cleanup_temp "$temp_dir"
            exit 1
        }
        wget -O "$checksum_file" "$base_url/$checksum_file" || {
            log_error "Failed to download $checksum_file"
            cleanup_temp "$temp_dir"
            exit 1
        }
    fi
    
    # Verify checksum
    log_info "Verifying download integrity..."
    if ! sha256sum -c "$checksum_file" --ignore-missing >/dev/null 2>&1; then
        log_error "Checksum verification failed"
        cleanup_temp "$temp_dir"
        exit 1
    fi
    
    # Extract binary
    log_info "Extracting binary..."
    tar -xzf "$tarball" || {
        log_error "Failed to extract tarball"
        cleanup_temp "$temp_dir"
        exit 1
    }
    
    # Find extracted binary
    local binary_name="${SERVICE_NAME}_linux_${arch}"
    if [ ! -f "$binary_name" ]; then
        log_error "Binary not found in archive: $binary_name"
        cleanup_temp "$temp_dir"
        exit 1
    fi
    
    echo "$temp_dir/$binary_name"
}

# Cleanup temporary directory
cleanup_temp() {
    local temp_dir="$1"
    if [ -d "$temp_dir" ]; then
        rm -rf "$temp_dir"
    fi
}

# Check for existing installation
check_existing_installation() {
    local binary_path="$PREFIX/bin/$SERVICE_NAME"
    
    if [ -f "$binary_path" ]; then
        if [ $FORCE -eq 0 ]; then
            log_warning "GlinrDock is already installed at $binary_path"
            if [ $NON_INTERACTIVE -eq 0 ]; then
                printf "Reinstall over existing installation? [y/N]: "
                read -r response
                case $response in
                    [Yy]*) ;;
                    *) log_info "Installation cancelled"; exit 0 ;;
                esac
            else
                log_error "Existing installation found. Use --force to reinstall."
                exit 1
            fi
        fi
        log_info "Reinstalling over existing installation..."
    fi
}

# Install binary
install_binary() {
    local binary_path="$1"
    local install_path="$PREFIX/bin/$SERVICE_NAME"
    
    log_info "Installing binary to $install_path..."
    
    # Create bin directory if it doesn't exist
    mkdir -p "$PREFIX/bin"
    
    # Copy and set permissions
    cp "$binary_path" "$install_path" || {
        log_error "Failed to copy binary to $install_path"
        exit 1
    }
    
    chmod +x "$install_path" || {
        log_error "Failed to set executable permissions"
        exit 1
    }
    
    # Verify installation
    if ! "$install_path" --version >/dev/null 2>&1; then
        log_warning "Binary installation may be incomplete (version check failed)"
    fi
    
    log_success "Binary installed successfully"
}

# Create system user
create_user() {
    log_info "Creating system user: $SERVICE_USER"
    
    if id "$SERVICE_USER" >/dev/null 2>&1; then
        log_info "User $SERVICE_USER already exists"
        return
    fi
    
    # Create system user with no login shell and home directory
    useradd --system \
            --no-create-home \
            --home-dir "/var/lib/$SERVICE_NAME" \
            --shell /usr/sbin/nologin \
            --comment "GlinrDock service user" \
            "$SERVICE_USER" || {
        log_error "Failed to create user $SERVICE_USER"
        exit 1
    }
    
    log_success "User $SERVICE_USER created"
}

# Create directories
create_directories() {
    log_info "Creating directories..."
    
    local dirs="/etc/$SERVICE_NAME /var/lib/$SERVICE_NAME /var/log/$SERVICE_NAME"
    
    for dir in $dirs; do
        mkdir -p "$dir" || {
            log_error "Failed to create directory: $dir"
            exit 1
        }
    done
    
    # Set ownership
    chown "$SERVICE_USER:$SERVICE_USER" "/var/lib/$SERVICE_NAME" "/var/log/$SERVICE_NAME"
    
    log_success "Directories created"
}

# Install systemd service
install_service() {
    log_info "Installing systemd service..."
    
    local service_file="/etc/systemd/system/${SERVICE_NAME}.service"
    
    cat > "$service_file" << EOF
[Unit]
Description=GlinrDock Container Management Service
Documentation=https://github.com/GLINCKER/glinrdock-release
After=network.target docker.service
Wants=docker.service

[Service]
Type=exec
User=$SERVICE_USER
Group=$SERVICE_USER
ExecStart=$PREFIX/bin/$SERVICE_NAME --config /etc/$SERVICE_NAME/config.env
EnvironmentFile=-/etc/$SERVICE_NAME/config.env
WorkingDirectory=/var/lib/$SERVICE_NAME
StandardOutput=journal
StandardError=journal
SyslogIdentifier=$SERVICE_NAME
Restart=always
RestartSec=5
TimeoutStopSec=30

# Security settings
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/lib/$SERVICE_NAME /var/log/$SERVICE_NAME /tmp
PrivateTmp=true
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true

# Resource limits
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload || {
        log_error "Failed to reload systemd daemon"
        exit 1
    }
    
    log_success "Systemd service installed"
}

# Generate configuration
generate_config() {
    local config_file="/etc/$SERVICE_NAME/config.env"
    
    if [ -f "$config_file" ]; then
        log_info "Configuration file already exists: $config_file"
        return
    fi
    
    log_info "Generating configuration..."
    
    # Generate admin token
    local admin_token
    if command -v openssl >/dev/null 2>&1; then
        admin_token=$(openssl rand -hex 32)
    else
        # Fallback: use /dev/urandom
        admin_token=$(dd if=/dev/urandom bs=32 count=1 2>/dev/null | od -An -tx1 | tr -d ' \n')
    fi
    
    cat > "$config_file" << EOF
# GlinrDock Configuration
# This file is sourced by systemd service

# Server Configuration
GLINRDOCK_BIND_ADDR=$BIND_ADDR
GLINRDOCK_DATA_DIR=/var/lib/$SERVICE_NAME
GLINRDOCK_LOG_LEVEL=info

# Authentication
GLINRDOCK_ADMIN_TOKEN=$admin_token

# Docker Configuration
GLINRDOCK_DOCKER_SOCKET=/var/run/docker.sock

# Logging
GLINRDOCK_LOG_FILE=/var/log/$SERVICE_NAME/$SERVICE_NAME.log
EOF

    chmod 600 "$config_file"
    chown "$SERVICE_USER:$SERVICE_USER" "$config_file"
    
    log_success "Configuration generated"
    log_info "Admin token saved to $config_file"
}

# Add user to docker group
setup_docker_access() {
    log_info "Setting up Docker access for $SERVICE_USER..."
    
    if ! getent group docker >/dev/null; then
        log_warning "Docker group not found. Creating docker group..."
        groupadd docker || {
            log_warning "Failed to create docker group"
            return
        }
    fi
    
    usermod -aG docker "$SERVICE_USER" || {
        log_warning "Failed to add $SERVICE_USER to docker group"
        log_warning "You may need to manually add the user to docker group:"
        log_warning "  sudo usermod -aG docker $SERVICE_USER"
    }
    
    log_success "Docker access configured"
}

# Start and enable service
start_service() {
    log_info "Starting $SERVICE_NAME service..."
    
    systemctl enable "$SERVICE_NAME" || {
        log_error "Failed to enable service"
        exit 1
    }
    
    systemctl start "$SERVICE_NAME" || {
        log_error "Failed to start service"
        log_error "Check logs with: journalctl -u $SERVICE_NAME"
        exit 1
    }
    
    # Wait a moment for service to start
    sleep 2
    
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        log_success "Service started successfully"
    else
        log_warning "Service may not have started correctly"
        log_info "Check status with: systemctl status $SERVICE_NAME"
    fi
}

# Verify installation
verify_installation() {
    log_info "Verifying installation..."
    
    # Check service status
    if ! systemctl is-active --quiet "$SERVICE_NAME"; then
        log_warning "Service is not running"
        return
    fi
    
    # Test health endpoint
    local max_attempts=10
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s "http://localhost:${BIND_ADDR#:}/v1/health" >/dev/null 2>&1; then
            log_success "Health check passed"
            return
        fi
        
        log_info "Waiting for service to be ready... (attempt $attempt/$max_attempts)"
        sleep 2
        attempt=$((attempt + 1))
    done
    
    log_warning "Health check failed - service may still be starting"
    log_info "Check logs with: journalctl -u $SERVICE_NAME"
}

# Print installation summary
print_summary() {
    local config_file="/etc/$SERVICE_NAME/config.env"
    local bind_addr_display="$BIND_ADDR"
    
    # Extract port from bind address
    case $BIND_ADDR in
        :*) bind_addr_display="localhost${BIND_ADDR}" ;;
        *:*) bind_addr_display="$BIND_ADDR" ;;
        *) bind_addr_display="localhost:$BIND_ADDR" ;;
    esac
    
    cat << EOF

${GREEN}GlinrDock Installation Complete!${NC}

Service Information:
  Status:      systemctl status $SERVICE_NAME
  Logs:        journalctl -u $SERVICE_NAME -f
  Config:      $config_file

Access Information:
  Web Interface: http://$bind_addr_display
  Health Check:  http://$bind_addr_display/v1/health

Next Steps:
  1. Access the web interface at http://$bind_addr_display
  2. Find your admin token in $config_file
  3. Log in with the admin token to start managing containers

Service Management:
  Start:   sudo systemctl start $SERVICE_NAME
  Stop:    sudo systemctl stop $SERVICE_NAME
  Restart: sudo systemctl restart $SERVICE_NAME
  Status:  sudo systemctl status $SERVICE_NAME

For help and documentation:
  https://github.com/GLINCKER/glinrdock-release

EOF
}

# Main installation function
main() {
    log_info "Starting GlinrDock installation..."
    
    parse_args "$@"
    check_root
    check_dependencies
    check_existing_installation
    
    local arch
    arch=$(detect_arch)
    
    local binary_path
    binary_path=$(download_release "$VERSION" "$arch")
    
    create_user
    create_directories
    install_binary "$binary_path"
    install_service
    generate_config
    setup_docker_access
    start_service
    verify_installation
    
    # Cleanup
    cleanup_temp "$(dirname "$binary_path")"
    
    print_summary
    log_success "Installation completed successfully!"
}

# Trap to cleanup on exit
trap 'cleanup_temp "/tmp/glinrdock-install-$$"' EXIT

# Run main function if script is executed directly
if [ "${0##*/}" = "install.sh" ]; then
    main "$@"
fi