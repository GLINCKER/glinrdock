#!/bin/sh
set -e

# GlinrDock Linux Uninstaller
# POSIX compliant uninstallation script for GlinrDock
#
# Copyright (c) 2025 GLINCKER LLC
# Licensed under MIT License (see LICENSE-SCRIPTS)

# Default configuration
DEFAULT_PREFIX="/usr/local"
SERVICE_NAME="glinrdockd"
SERVICE_USER="glinrdock"

# Global variables
PREFIX=""
PURGE=0
NON_INTERACTIVE=0
DRY_RUN=0
KEEP_LOGS=1

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
GlinrDock Linux Uninstaller

USAGE:
    uninstall.sh [OPTIONS]

OPTIONS:
    --purge               Remove all data including projects and logs
    --keep-data          Keep data directory (default behavior)
    --remove-logs        Remove log files (logs are kept by default)
    --prefix PATH        Installation prefix (default: /usr/local)
    --non-interactive    Run without prompts for CI/automation
    --dry-run           Show what would be removed without making changes
    --help              Show this help message

EXAMPLES:
    # Standard uninstall (keeps data and logs)
    sudo ./uninstall.sh

    # Complete removal including all data
    sudo ./uninstall.sh --purge

    # Dry run to see what would be removed
    sudo ./uninstall.sh --dry-run

    # Non-interactive uninstall for CI
    sudo ./uninstall.sh --non-interactive

DATA PRESERVATION:
    By default, the following are preserved:
    - User data in /var/lib/glinrdock
    - Configuration files in /etc/glinrdock
    - Log files in /var/log/glinrdock

    Use --purge to remove all data and configuration files.
    Use --remove-logs to also remove log files.

REQUIREMENTS:
    - Root privileges (run with sudo)
    - systemd init system

EOF
}

# Parse command line arguments
parse_args() {
    while [ $# -gt 0 ]; do
        case $1 in
            --purge)
                PURGE=1
                shift
                ;;
            --keep-data)
                PURGE=0
                shift
                ;;
            --remove-logs)
                KEEP_LOGS=0
                shift
                ;;
            --prefix)
                PREFIX="$2"
                shift 2
                ;;
            --non-interactive)
                NON_INTERACTIVE=1
                shift
                ;;
            --dry-run)
                DRY_RUN=1
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
    PREFIX=${PREFIX:-$DEFAULT_PREFIX}
}

# Check if running as root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        log_error "This script must be run as root. Please use sudo."
        exit 1
    fi
}

# Execute command with dry-run support
execute() {
    local cmd="$1"
    local description="$2"
    
    if [ $DRY_RUN -eq 1 ]; then
        log_info "[DRY RUN] $description"
        log_info "[DRY RUN] Would execute: $cmd"
    else
        log_info "$description"
        eval "$cmd" || {
            log_error "Failed: $description"
            return 1
        }
    fi
}

# Confirm destructive action
confirm_action() {
    local action="$1"
    local default_response="${2:-n}"
    
    if [ $NON_INTERACTIVE -eq 1 ]; then
        case $default_response in
            y|Y) return 0 ;;
            *) return 1 ;;
        esac
    fi
    
    if [ $DRY_RUN -eq 1 ]; then
        log_info "[DRY RUN] Would prompt: $action"
        return 0
    fi
    
    printf "%s [y/N]: " "$action"
    read -r response
    case $response in
        [Yy]*) return 0 ;;
        *) return 1 ;;
    esac
}

# Check for existing installation
check_installation() {
    local binary_path="$PREFIX/bin/$SERVICE_NAME"
    local service_file="/etc/systemd/system/${SERVICE_NAME}.service"
    
    if [ ! -f "$binary_path" ] && [ ! -f "$service_file" ]; then
        log_warning "GlinrDock does not appear to be installed"
        log_warning "Binary not found: $binary_path"
        log_warning "Service file not found: $service_file"
        
        if [ $NON_INTERACTIVE -eq 0 ]; then
            if ! confirm_action "Continue with cleanup anyway?"; then
                log_info "Uninstall cancelled"
                exit 0
            fi
        fi
    fi
    
    log_info "Found GlinrDock installation"
    if [ -f "$binary_path" ]; then
        log_info "Binary: $binary_path"
    fi
    if [ -f "$service_file" ]; then
        log_info "Service: $service_file"
    fi
}

# Stop and disable service
stop_service() {
    local service_file="/etc/systemd/system/${SERVICE_NAME}.service"
    
    if [ ! -f "$service_file" ]; then
        log_info "Service file not found, skipping service operations"
        return
    fi
    
    log_info "Stopping and disabling service..."
    
    # Check if service is running
    if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
        execute "systemctl stop $SERVICE_NAME" "Stopping $SERVICE_NAME service"
    else
        log_info "Service is not running"
    fi
    
    # Check if service is enabled
    if systemctl is-enabled --quiet "$SERVICE_NAME" 2>/dev/null; then
        execute "systemctl disable $SERVICE_NAME" "Disabling $SERVICE_NAME service"
    else
        log_info "Service is not enabled"
    fi
    
    log_success "Service stopped and disabled"
}

# Remove systemd service file
remove_service_file() {
    local service_file="/etc/systemd/system/${SERVICE_NAME}.service"
    
    if [ -f "$service_file" ]; then
        execute "rm -f $service_file" "Removing service file"
        execute "systemctl daemon-reload" "Reloading systemd daemon"
        log_success "Service file removed"
    else
        log_info "Service file not found: $service_file"
    fi
}

# Remove binary
remove_binary() {
    local binary_path="$PREFIX/bin/$SERVICE_NAME"
    
    if [ -f "$binary_path" ]; then
        execute "rm -f $binary_path" "Removing binary"
        log_success "Binary removed"
    else
        log_info "Binary not found: $binary_path"
    fi
}

# Remove or preserve data directories
handle_data_directories() {
    local config_dir="/etc/$SERVICE_NAME"
    local data_dir="/var/lib/$SERVICE_NAME"
    local log_dir="/var/log/$SERVICE_NAME"
    
    if [ $PURGE -eq 1 ]; then
        # Remove all data
        log_warning "PURGE mode: All data and configuration will be removed"
        
        if [ $NON_INTERACTIVE -eq 0 ] && [ $DRY_RUN -eq 0 ]; then
            if ! confirm_action "This will permanently delete all GlinrDock data. Continue?"; then
                log_info "Data preservation cancelled"
                return
            fi
        fi
        
        for dir in "$config_dir" "$data_dir" "$log_dir"; do
            if [ -d "$dir" ]; then
                execute "rm -rf $dir" "Removing directory: $dir"
            else
                log_info "Directory not found: $dir"
            fi
        done
        
        log_success "All data directories removed"
        
    else
        # Preserve data, show what's being kept
        log_info "Data preservation mode: Keeping user data and configuration"
        
        local preserved_dirs=""
        for dir in "$config_dir" "$data_dir"; do
            if [ -d "$dir" ]; then
                preserved_dirs="$preserved_dirs\n  - $dir"
            fi
        done
        
        if [ $KEEP_LOGS -eq 1 ]; then
            if [ -d "$log_dir" ]; then
                preserved_dirs="$preserved_dirs\n  - $log_dir"
            fi
        else
            # Remove logs if requested
            if [ -d "$log_dir" ]; then
                execute "rm -rf $log_dir" "Removing log directory: $log_dir"
            fi
        fi
        
        if [ -n "$preserved_dirs" ]; then
            log_info "Preserved directories:$preserved_dirs"
            log_info ""
            log_info "To remove preserved data later, run:"
            log_info "  sudo rm -rf $config_dir $data_dir"
            if [ $KEEP_LOGS -eq 1 ] && [ -d "$log_dir" ]; then
                log_info "  sudo rm -rf $log_dir"
            fi
            log_info ""
            log_info "Or use: sudo ./uninstall.sh --purge"
        fi
    fi
}

# Remove system user
remove_user() {
    if [ $PURGE -eq 0 ]; then
        log_info "Keeping system user: $SERVICE_USER (use --purge to remove)"
        return
    fi
    
    if id "$SERVICE_USER" >/dev/null 2>&1; then
        execute "userdel $SERVICE_USER" "Removing system user: $SERVICE_USER"
        log_success "System user removed"
    else
        log_info "System user not found: $SERVICE_USER"
    fi
}

# Clean up package manager files (if any)
cleanup_package_files() {
    # Check for any package manager installed files
    local rpm_installed=0
    local deb_installed=0
    
    # Check RPM installation
    if command -v rpm >/dev/null 2>&1; then
        if rpm -q "$SERVICE_NAME" >/dev/null 2>&1; then
            rpm_installed=1
        fi
    fi
    
    # Check DEB installation
    if command -v dpkg >/dev/null 2>&1; then
        if dpkg -l "$SERVICE_NAME" >/dev/null 2>&1; then
            deb_installed=1
        fi
    fi
    
    if [ $rpm_installed -eq 1 ] || [ $deb_installed -eq 1 ]; then
        log_warning "Package manager installation detected"
        log_warning "Consider using your package manager to uninstall:"
        
        if [ $rpm_installed -eq 1 ]; then
            log_warning "  sudo rpm -e $SERVICE_NAME"
        fi
        
        if [ $deb_installed -eq 1 ]; then
            log_warning "  sudo dpkg -r $SERVICE_NAME"
        fi
    fi
}

# Verify uninstallation
verify_removal() {
    log_info "Verifying uninstallation..."
    
    local binary_path="$PREFIX/bin/$SERVICE_NAME"
    local service_file="/etc/systemd/system/${SERVICE_NAME}.service"
    local remaining_files=0
    
    # Check binary
    if [ -f "$binary_path" ]; then
        log_warning "Binary still exists: $binary_path"
        remaining_files=1
    fi
    
    # Check service file
    if [ -f "$service_file" ]; then
        log_warning "Service file still exists: $service_file"
        remaining_files=1
    fi
    
    # Check service status
    if systemctl list-unit-files | grep -q "^${SERVICE_NAME}.service"; then
        log_warning "Service still registered with systemd"
        remaining_files=1
    fi
    
    if [ $remaining_files -eq 0 ]; then
        log_success "Uninstallation verification passed"
    else
        log_warning "Some files may still remain"
    fi
}

# Print uninstallation summary
print_summary() {
    cat << EOF

${GREEN}GlinrDock Uninstallation Summary${NC}

Removed:
  - Binary: $PREFIX/bin/$SERVICE_NAME
  - Service: /etc/systemd/system/${SERVICE_NAME}.service
  - systemd registration

EOF

    if [ $PURGE -eq 1 ]; then
        cat << EOF
  - Configuration: /etc/$SERVICE_NAME
  - Data directory: /var/lib/$SERVICE_NAME
  - System user: $SERVICE_USER
EOF
        if [ $KEEP_LOGS -eq 0 ]; then
            echo "  - Log directory: /var/log/$SERVICE_NAME"
        fi
    else
        cat << EOF
Preserved (use --purge to remove):
  - Configuration: /etc/$SERVICE_NAME
  - Data directory: /var/lib/$SERVICE_NAME
  - System user: $SERVICE_USER
EOF
        if [ $KEEP_LOGS -eq 1 ]; then
            echo "  - Log directory: /var/log/$SERVICE_NAME"
        fi
    fi

    cat << EOF

Manual cleanup (if needed):
  - Remove from docker group: sudo gpasswd -d $SERVICE_USER docker
  - Clean docker resources: docker system prune
  - Remove firewall rules for port 8080

EOF

    if [ $DRY_RUN -eq 1 ]; then
        cat << EOF
${YELLOW}This was a dry run. No changes were made.${NC}
Run without --dry-run to perform the actual uninstallation.

EOF
    fi
}

# Main uninstallation function
main() {
    log_info "Starting GlinrDock uninstallation..."
    
    parse_args "$@"
    
    if [ $DRY_RUN -eq 1 ]; then
        log_info "DRY RUN MODE: No changes will be made"
    fi
    
    check_root
    check_installation
    cleanup_package_files
    stop_service
    remove_service_file
    remove_binary
    handle_data_directories
    remove_user
    
    if [ $DRY_RUN -eq 0 ]; then
        verify_removal
    fi
    
    print_summary
    
    if [ $DRY_RUN -eq 0 ]; then
        log_success "Uninstallation completed successfully!"
    else
        log_info "Dry run completed successfully!"
    fi
}

# Run main function if script is executed directly
if [ "${0##*/}" = "uninstall.sh" ]; then
    main "$@"
fi