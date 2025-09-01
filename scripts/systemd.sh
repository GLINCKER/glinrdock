#!/bin/sh
# GlinrDock systemd Management Helper
# POSIX-compliant helper for systemd unit management

set -eu

# Configuration
SERVICE_NAME="glinrdockd"
UNIT_FILE="glinrdockd.service"
SYSTEMD_DIR="/etc/systemd/system"
SOURCE_UNIT_DIR="deploy/systemd"

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

# Print usage information
usage() {
    cat << 'EOF'
GlinrDock systemd Management Helper

USAGE:
    systemd.sh <command> [options]

COMMANDS:
    install         Install systemd unit file (does not enable)
    print-unit      Print unit file contents to stdout
    enable          Enable the service for automatic startup
    disable         Disable the service
    start           Start the service
    stop            Stop the service
    restart         Restart the service
    status          Show service status
    logs            Show service logs
    verify          Verify unit file with systemd-analyze
    security        Show security analysis of the unit
    help            Show this help message

OPTIONS:
    --user          Use user systemd (systemctl --user)
    --dry-run       Show what would be done without executing
    --follow        Follow logs in real-time (for logs command)

EXAMPLES:
    # Install unit file
    ./systemd.sh install

    # Verify unit file is valid
    ./systemd.sh verify

    # Enable and start service
    ./systemd.sh enable
    ./systemd.sh start

    # Check service status
    ./systemd.sh status

    # View logs
    ./systemd.sh logs --follow

    # Security analysis
    ./systemd.sh security

NOTES:
    - install command requires root privileges
    - Unit file is installed but not enabled by default
    - Service requires 'glinrdock' user to exist
    - Verify command checks unit file validity

EOF
}

# Check if we have necessary permissions
check_sudo() {
    if [ "$USER_MODE" -eq 0 ]; then
        if [ "$(id -u)" -ne 0 ] && ! sudo -n true 2>/dev/null; then
            log_info "This operation requires root privileges"
            log_info "You may be prompted for your password"
        fi
    fi
}

# Find unit file path
find_unit_file() {
    local source_paths="
        $SOURCE_UNIT_DIR/$UNIT_FILE
        deploy/systemd/$UNIT_FILE
        systemd/$UNIT_FILE
        $UNIT_FILE
    "
    
    for path in $source_paths; do
        if [ -f "$path" ]; then
            echo "$path"
            return 0
        fi
    done
    
    log_error "Unit file not found. Searched paths:"
    for path in $source_paths; do
        log_error "  $path"
    done
    return 1
}

# Install systemd unit file
install_unit() {
    local source_unit
    source_unit=$(find_unit_file) || return 1
    
    local target_unit="$SYSTEMD_DIR/$UNIT_FILE"
    
    log_info "Installing systemd unit file"
    log_info "  Source: $source_unit"
    log_info "  Target: $target_unit"
    
    if [ "$DRY_RUN" -eq 1 ]; then
        log_info "[DRY-RUN] Would copy unit file and reload systemd"
        return 0
    fi
    
    # Check if we need sudo
    if [ "$USER_MODE" -eq 0 ]; then
        check_sudo
        
        # Copy unit file
        if ! sudo cp "$source_unit" "$target_unit"; then
            log_error "Failed to install unit file"
            return 1
        fi
        
        # Set proper permissions
        sudo chmod 644 "$target_unit"
        sudo chown root:root "$target_unit"
        
        # Reload systemd
        log_info "Reloading systemd daemon"
        if ! sudo systemctl daemon-reload; then
            log_error "Failed to reload systemd daemon"
            return 1
        fi
    else
        # User mode
        mkdir -p "$HOME/.config/systemd/user"
        if ! cp "$source_unit" "$HOME/.config/systemd/user/$UNIT_FILE"; then
            log_error "Failed to install user unit file"
            return 1
        fi
        
        # Reload user systemd
        log_info "Reloading user systemd daemon"
        if ! systemctl --user daemon-reload; then
            log_error "Failed to reload user systemd daemon"
            return 1
        fi
    fi
    
    log_success "Unit file installed successfully"
    log_info "Unit installed but not enabled. Use 'systemd.sh enable' to enable it."
}

# Print unit file contents
print_unit() {
    local source_unit
    source_unit=$(find_unit_file) || return 1
    
    cat "$source_unit"
}

# Enable service
enable_service() {
    log_info "Enabling $SERVICE_NAME service"
    
    if [ "$DRY_RUN" -eq 1 ]; then
        log_info "[DRY-RUN] Would enable service"
        return 0
    fi
    
    local systemctl_cmd="systemctl"
    if [ "$USER_MODE" -eq 1 ]; then
        systemctl_cmd="systemctl --user"
    else
        check_sudo
        systemctl_cmd="sudo systemctl"
    fi
    
    if ! $systemctl_cmd enable "$SERVICE_NAME.service"; then
        log_error "Failed to enable service"
        return 1
    fi
    
    log_success "Service enabled for automatic startup"
}

# Disable service
disable_service() {
    log_info "Disabling $SERVICE_NAME service"
    
    if [ "$DRY_RUN" -eq 1 ]; then
        log_info "[DRY-RUN] Would disable service"
        return 0
    fi
    
    local systemctl_cmd="systemctl"
    if [ "$USER_MODE" -eq 1 ]; then
        systemctl_cmd="systemctl --user"
    else
        check_sudo
        systemctl_cmd="sudo systemctl"
    fi
    
    if ! $systemctl_cmd disable "$SERVICE_NAME.service"; then
        log_error "Failed to disable service"
        return 1
    fi
    
    log_success "Service disabled"
}

# Start service
start_service() {
    log_info "Starting $SERVICE_NAME service"
    
    if [ "$DRY_RUN" -eq 1 ]; then
        log_info "[DRY-RUN] Would start service"
        return 0
    fi
    
    local systemctl_cmd="systemctl"
    if [ "$USER_MODE" -eq 1 ]; then
        systemctl_cmd="systemctl --user"
    else
        check_sudo
        systemctl_cmd="sudo systemctl"
    fi
    
    if ! $systemctl_cmd start "$SERVICE_NAME.service"; then
        log_error "Failed to start service"
        return 1
    fi
    
    log_success "Service started"
}

# Stop service
stop_service() {
    log_info "Stopping $SERVICE_NAME service"
    
    if [ "$DRY_RUN" -eq 1 ]; then
        log_info "[DRY-RUN] Would stop service"
        return 0
    fi
    
    local systemctl_cmd="systemctl"
    if [ "$USER_MODE" -eq 1 ]; then
        systemctl_cmd="systemctl --user"
    else
        check_sudo
        systemctl_cmd="sudo systemctl"
    fi
    
    if ! $systemctl_cmd stop "$SERVICE_NAME.service"; then
        log_error "Failed to stop service"
        return 1
    fi
    
    log_success "Service stopped"
}

# Restart service
restart_service() {
    log_info "Restarting $SERVICE_NAME service"
    
    if [ "$DRY_RUN" -eq 1 ]; then
        log_info "[DRY-RUN] Would restart service"
        return 0
    fi
    
    local systemctl_cmd="systemctl"
    if [ "$USER_MODE" -eq 1 ]; then
        systemctl_cmd="systemctl --user"
    else
        check_sudo
        systemctl_cmd="sudo systemctl"
    fi
    
    if ! $systemctl_cmd restart "$SERVICE_NAME.service"; then
        log_error "Failed to restart service"
        return 1
    fi
    
    log_success "Service restarted"
}

# Show service status
show_status() {
    local systemctl_cmd="systemctl"
    if [ "$USER_MODE" -eq 1 ]; then
        systemctl_cmd="systemctl --user"
    fi
    
    $systemctl_cmd status "$SERVICE_NAME.service"
}

# Show service logs
show_logs() {
    local journalctl_cmd="journalctl"
    local follow_flag=""
    
    if [ "$USER_MODE" -eq 1 ]; then
        journalctl_cmd="journalctl --user"
    fi
    
    if [ "$FOLLOW_LOGS" -eq 1 ]; then
        follow_flag="-f"
    fi
    
    $journalctl_cmd -u "$SERVICE_NAME.service" $follow_flag
}

# Verify unit file
verify_unit() {
    local source_unit
    source_unit=$(find_unit_file) || return 1
    
    log_info "Verifying unit file: $source_unit"
    
    if ! command -v systemd-analyze >/dev/null 2>&1; then
        log_error "systemd-analyze not available"
        return 1
    fi
    
    if systemd-analyze verify "$source_unit"; then
        log_success "Unit file verification passed"
    else
        log_error "Unit file verification failed"
        return 1
    fi
}

# Security analysis
security_analysis() {
    log_info "Running security analysis for $SERVICE_NAME service"
    
    if ! command -v systemd-analyze >/dev/null 2>&1; then
        log_error "systemd-analyze not available"
        return 1
    fi
    
    local systemctl_cmd="systemctl"
    if [ "$USER_MODE" -eq 1 ]; then
        systemctl_cmd="systemctl --user"
    fi
    
    # Check if service is loaded
    if ! $systemctl_cmd list-unit-files "$SERVICE_NAME.service" >/dev/null 2>&1; then
        log_error "Service not installed. Run 'systemd.sh install' first."
        return 1
    fi
    
    systemd-analyze security "$SERVICE_NAME.service"
}

# Main function
main() {
    # Default options
    USER_MODE=0
    DRY_RUN=0
    FOLLOW_LOGS=0
    
    # Parse command and options
    if [ $# -eq 0 ]; then
        log_error "No command specified"
        usage >&2
        exit 1
    fi
    
    local command="$1"
    shift
    
    # Parse remaining options
    while [ $# -gt 0 ]; do
        case "$1" in
            --user)
                USER_MODE=1
                SYSTEMD_DIR="$HOME/.config/systemd/user"
                ;;
            --dry-run)
                DRY_RUN=1
                ;;
            --follow)
                FOLLOW_LOGS=1
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
    
    # Execute command
    case "$command" in
        install)
            install_unit
            ;;
        print-unit)
            print_unit
            ;;
        enable)
            enable_service
            ;;
        disable)
            disable_service
            ;;
        start)
            start_service
            ;;
        stop)
            stop_service
            ;;
        restart)
            restart_service
            ;;
        status)
            show_status
            ;;
        logs)
            show_logs
            ;;
        verify)
            verify_unit
            ;;
        security)
            security_analysis
            ;;
        help)
            usage
            ;;
        *)
            log_error "Unknown command: $command"
            usage >&2
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"