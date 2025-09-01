#!/bin/sh
# GlinrDock Uninstaller Script
# POSIX-compliant uninstaller for GlinrDock
# Supports --dry-run for safe testing

set -eu

# Configuration
BIN_NAME="${GLINR_BIN_NAME:-glinrdockd}"
DEFAULT_PREFIX="/usr/local"
SERVICE_NAME="glinrdock"

# Colors for output (if terminal supports it)
if [ -t 1 ] && command -v tput >/dev/null 2>&1; then
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    BOLD=$(tput bold)
    RESET=$(tput sgr0)
else
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    BOLD=""
    RESET=""
fi

# Global variables
DRY_RUN=0
VERBOSE=0
PREFIX="$DEFAULT_PREFIX"
FORCE=0
REMOVE_DATA=0
REMOVE_LOGS=0

# Logging functions
log_info() {
    printf "%s[INFO]%s %s\n" "$BLUE" "$RESET" "$*"
}

log_warn() {
    printf "%s[WARN]%s %s\n" "$YELLOW" "$RESET" "$*" >&2
}

log_error() {
    printf "%s[ERROR]%s %s\n" "$RED" "$RESET" "$*" >&2
}

log_success() {
    printf "%s[SUCCESS]%s %s\n" "$GREEN" "$RESET" "$*"
}

log_debug() {
    if [ "$VERBOSE" -eq 1 ]; then
        printf "%s[DEBUG]%s %s\n" "$RESET" "$RESET" "$*" >&2
    fi
}

# Print usage information
usage() {
    cat << 'EOF'
GlinrDock Uninstaller

USAGE:
    uninstall.sh [OPTIONS]

OPTIONS:
    --dry-run           Show what would be removed without actually removing
    --prefix DIR        Set installation prefix (default: /usr/local)
    --force             Force removal even if service is running
    --remove-data       Also remove user data directory
    --remove-logs       Also remove log files
    --verbose           Enable verbose output
    --help              Show this help message

ENVIRONMENT VARIABLES:
    GLINR_BIN_NAME      Binary name to uninstall (default: glinrdockd)
    GLINR_DESTDIR       Installation prefix override

EXAMPLES:
    # Dry run to see what would be removed
    ./uninstall.sh --dry-run

    # Remove with custom prefix
    ./uninstall.sh --prefix /opt/glinr

    # Force removal and clean up data
    ./uninstall.sh --force --remove-data --remove-logs

    # Verbose dry run
    ./uninstall.sh --dry-run --verbose

The uninstaller will:
1. Stop and disable the systemd service (if present)
2. Remove the binary from PREFIX/bin/
3. Remove systemd service file (if present)
4. Remove configuration directory (if --remove-data)
5. Remove log files (if --remove-logs)

EOF
}

# Parse command line arguments
parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --dry-run)
                DRY_RUN=1
                log_info "Dry run mode enabled - no files will be removed"
                ;;
            --prefix)
                shift
                if [ $# -eq 0 ] || [ -z "$1" ]; then
                    log_error "Option --prefix requires a directory argument"
                    exit 1
                fi
                PREFIX="$1"
                ;;
            --force)
                FORCE=1
                ;;
            --remove-data)
                REMOVE_DATA=1
                ;;
            --remove-logs)
                REMOVE_LOGS=1
                ;;
            --verbose)
                VERBOSE=1
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                usage >&2
                exit 1
                ;;
        esac
        shift
    done
}

# Check if systemctl is available and service exists
service_exists() {
    if command -v systemctl >/dev/null 2>&1; then
        systemctl list-unit-files "$SERVICE_NAME.service" >/dev/null 2>&1
    else
        false
    fi
}

# Check if service is running
service_running() {
    if command -v systemctl >/dev/null 2>&1; then
        systemctl is-active "$SERVICE_NAME" >/dev/null 2>&1
    else
        false
    fi
}

# Stop and disable systemd service
stop_service() {
    if ! service_exists; then
        log_debug "systemd service $SERVICE_NAME.service does not exist"
        return 0
    fi

    if service_running; then
        if [ "$FORCE" -eq 0 ]; then
            log_error "Service $SERVICE_NAME is currently running"
            log_error "Use --force to stop and remove it, or stop it manually first:"
            log_error "  sudo systemctl stop $SERVICE_NAME"
            exit 1
        fi

        log_info "Stopping systemd service: $SERVICE_NAME"
        if [ "$DRY_RUN" -eq 0 ]; then
            if ! sudo systemctl stop "$SERVICE_NAME" 2>/dev/null; then
                log_error "Failed to stop service $SERVICE_NAME"
                exit 1
            fi
        fi
    else
        log_debug "Service $SERVICE_NAME is not running"
    fi

    log_info "Disabling systemd service: $SERVICE_NAME"
    if [ "$DRY_RUN" -eq 0 ]; then
        if ! sudo systemctl disable "$SERVICE_NAME" 2>/dev/null; then
            log_warn "Could not disable service $SERVICE_NAME (may not be enabled)"
        fi
    fi
}

# Remove systemd service file
remove_service_file() {
    local service_file="/etc/systemd/system/$SERVICE_NAME.service"
    
    if [ -f "$service_file" ]; then
        log_info "Removing systemd service file: $service_file"
        if [ "$DRY_RUN" -eq 0 ]; then
            if ! sudo rm -f "$service_file"; then
                log_error "Failed to remove service file: $service_file"
                exit 1
            fi
            # Reload systemd after removing service file
            sudo systemctl daemon-reload 2>/dev/null || true
        fi
    else
        log_debug "systemd service file not found: $service_file"
    fi
}

# Remove binary
remove_binary() {
    local bin_path="$PREFIX/bin/$BIN_NAME"
    
    if [ -f "$bin_path" ]; then
        log_info "Removing binary: $bin_path"
        if [ "$DRY_RUN" -eq 0 ]; then
            if ! sudo rm -f "$bin_path"; then
                log_error "Failed to remove binary: $bin_path"
                exit 1
            fi
        fi
    else
        log_debug "Binary not found: $bin_path"
    fi
}

# Remove configuration directory
remove_config() {
    local config_dirs="/etc/glinrdock /etc/$SERVICE_NAME"
    
    for config_dir in $config_dirs; do
        if [ -d "$config_dir" ]; then
            if [ "$REMOVE_DATA" -eq 1 ]; then
                log_info "Removing configuration directory: $config_dir"
                if [ "$DRY_RUN" -eq 0 ]; then
                    if ! sudo rm -rf "$config_dir"; then
                        log_error "Failed to remove configuration directory: $config_dir"
                        exit 1
                    fi
                fi
            else
                log_warn "Configuration directory exists: $config_dir"
                log_warn "Use --remove-data to remove it"
            fi
        else
            log_debug "Configuration directory not found: $config_dir"
        fi
    done
}

# Remove user and group (if they exist and have no other purpose)
remove_user() {
    local username="glinrdock"
    
    if id "$username" >/dev/null 2>&1; then
        if [ "$REMOVE_DATA" -eq 1 ]; then
            log_info "Removing system user: $username"
            if [ "$DRY_RUN" -eq 0 ]; then
                if command -v userdel >/dev/null 2>&1; then
                    sudo userdel "$username" 2>/dev/null || log_warn "Could not remove user $username"
                fi
                if command -v groupdel >/dev/null 2>&1; then
                    sudo groupdel "$username" 2>/dev/null || log_warn "Could not remove group $username"
                fi
            fi
        else
            log_warn "System user exists: $username"
            log_warn "Use --remove-data to remove it"
        fi
    else
        log_debug "System user not found: $username"
    fi
}

# Remove data directories
remove_data() {
    local data_dirs="/var/lib/glinrdock /var/lib/$SERVICE_NAME /opt/glinrdock"
    
    for data_dir in $data_dirs; do
        if [ -d "$data_dir" ]; then
            if [ "$REMOVE_DATA" -eq 1 ]; then
                log_info "Removing data directory: $data_dir"
                if [ "$DRY_RUN" -eq 0 ]; then
                    if ! sudo rm -rf "$data_dir"; then
                        log_error "Failed to remove data directory: $data_dir"
                        exit 1
                    fi
                fi
            else
                log_warn "Data directory exists: $data_dir"
                log_warn "Use --remove-data to remove it"
            fi
        else
            log_debug "Data directory not found: $data_dir"
        fi
    done
}

# Remove log files
remove_logs() {
    local log_dirs="/var/log/glinrdock /var/log/$SERVICE_NAME"
    
    for log_dir in $log_dirs; do
        if [ -d "$log_dir" ]; then
            if [ "$REMOVE_LOGS" -eq 1 ]; then
                log_info "Removing log directory: $log_dir"
                if [ "$DRY_RUN" -eq 0 ]; then
                    if ! sudo rm -rf "$log_dir"; then
                        log_error "Failed to remove log directory: $log_dir"
                        exit 1
                    fi
                fi
            else
                log_warn "Log directory exists: $log_dir"
                log_warn "Use --remove-logs to remove it"
            fi
        else
            log_debug "Log directory not found: $log_dir"
        fi
    done
}

# Check if we have necessary permissions
check_permissions() {
    local bin_path="$PREFIX/bin/$BIN_NAME"
    local need_sudo=0
    
    # Check if binary exists and if we need sudo to remove it
    if [ -f "$bin_path" ] && [ ! -w "$bin_path" ]; then
        need_sudo=1
    fi
    
    # Check systemd service files
    if service_exists; then
        need_sudo=1
    fi
    
    # Check other directories that might need sudo
    local check_dirs="/etc/glinrdock /var/lib/glinrdock /var/log/glinrdock"
    for dir in $check_dirs; do
        if [ -d "$dir" ] && [ ! -w "$dir" ]; then
            need_sudo=1
            break
        fi
    done
    
    if [ "$need_sudo" -eq 1 ]; then
        if ! sudo -n true 2>/dev/null; then
            log_info "This uninstaller requires sudo privileges for some operations"
            log_info "You may be prompted for your password"
        fi
    fi
}

# Main uninstall function
main() {
    # Override prefix from environment if set
    if [ -n "${GLINR_DESTDIR:-}" ]; then
        PREFIX="$GLINR_DESTDIR"
    fi
    
    # Parse arguments
    parse_args "$@"
    
    log_info "GlinrDock Uninstaller"
    log_info "Configuration:"
    log_info "  Binary name: $BIN_NAME"
    log_info "  Install prefix: $PREFIX"
    log_info "  Dry run: $([ "$DRY_RUN" -eq 1 ] && echo "Yes" || echo "No")"
    log_info "  Force removal: $([ "$FORCE" -eq 1 ] && echo "Yes" || echo "No")"
    log_info "  Remove data: $([ "$REMOVE_DATA" -eq 1 ] && echo "Yes" || echo "No")"
    log_info "  Remove logs: $([ "$REMOVE_LOGS" -eq 1 ] && echo "Yes" || echo "No")"
    echo
    
    # Check permissions early
    if [ "$DRY_RUN" -eq 0 ]; then
        check_permissions
    fi
    
    # Perform uninstall steps
    log_info "Starting uninstall process..."
    
    # 1. Stop and disable service
    stop_service
    
    # 2. Remove service file
    remove_service_file
    
    # 3. Remove binary
    remove_binary
    
    # 4. Remove configuration (if requested)
    remove_config
    
    # 5. Remove user (if requested)
    remove_user
    
    # 6. Remove data directories (if requested)
    remove_data
    
    # 7. Remove log files (if requested)
    remove_logs
    
    echo
    if [ "$DRY_RUN" -eq 1 ]; then
        log_success "Dry run completed - no files were actually removed"
        log_info "Run without --dry-run to perform the actual uninstall"
    else
        log_success "GlinrDock has been successfully uninstalled"
        
        if [ "$REMOVE_DATA" -eq 0 ] || [ "$REMOVE_LOGS" -eq 0 ]; then
            echo
            log_info "Note: Some files may remain on your system:"
            if [ "$REMOVE_DATA" -eq 0 ]; then
                log_info "  - Configuration and data directories (use --remove-data to clean)"
            fi
            if [ "$REMOVE_LOGS" -eq 0 ]; then
                log_info "  - Log files (use --remove-logs to clean)"
            fi
        fi
    fi
}

# Run main function with all arguments
main "$@"