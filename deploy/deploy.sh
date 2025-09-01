#!/bin/bash
set -euo pipefail

# GlinrDock Docker Compose Deployment Script
# This script helps deploy GlinrDock using Docker Compose with various profiles

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
COMPOSE_FILE="docker-compose.yml"
ENV_FILE=".env"
DEFAULT_PROFILE="default"
AVAILABLE_PROFILES=("default" "nginx" "caddy" "monitoring" "production")

# Logging functions
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

# Print usage
print_usage() {
    cat << EOF
GlinrDock Docker Compose Deployment Script

USAGE:
    $0 [COMMAND] [OPTIONS]

COMMANDS:
    up [profile]     Start services with optional profile
    down             Stop and remove services
    restart          Restart services
    logs [service]   Show logs for all services or specific service
    ps               Show running services
    pull             Pull latest images
    backup           Backup data volumes
    restore FILE     Restore data from backup
    help             Show this help message

PROFILES:
    default          GlinrDock only (default)
    nginx            GlinrDock + Nginx reverse proxy
    caddy            GlinrDock + Caddy reverse proxy (auto HTTPS)
    monitoring       GlinrDock + Prometheus + Grafana
    production       Full production stack (Caddy + Monitoring)

OPTIONS:
    --env FILE       Use custom environment file (default: .env)
    --detach         Run in background (default for up command)
    --force          Force operation without confirmation
    --dry-run        Show what would be done without executing

EXAMPLES:
    $0 up                    # Start basic GlinrDock
    $0 up caddy              # Start with Caddy reverse proxy
    $0 up production         # Start full production stack
    $0 down                  # Stop all services
    $0 logs glinrdock        # Show GlinrDock logs
    $0 backup                # Backup all data
    $0 restore backup.tar.gz # Restore from backup

EOF
}

# Check if Docker Compose is available
check_docker_compose() {
    if command -v docker-compose >/dev/null 2>&1; then
        COMPOSE_CMD="docker-compose"
    elif docker compose version >/dev/null 2>&1; then
        COMPOSE_CMD="docker compose"
    else
        error "Docker Compose not found. Please install Docker Compose."
    fi
    
    log "Using: $COMPOSE_CMD"
}

# Check if required files exist
check_files() {
    if [[ ! -f "$COMPOSE_FILE" ]]; then
        error "Docker Compose file not found: $COMPOSE_FILE"
    fi
    
    if [[ ! -f "$ENV_FILE" ]]; then
        warn "Environment file not found: $ENV_FILE"
        if [[ -f ".env.example" ]]; then
            log "Creating $ENV_FILE from .env.example"
            cp .env.example "$ENV_FILE"
            warn "Please edit $ENV_FILE with your configuration before proceeding"
            exit 1
        fi
    fi
}

# Validate profile
validate_profile() {
    local profile="$1"
    
    if [[ " ${AVAILABLE_PROFILES[*]} " != *" $profile "* ]]; then
        error "Invalid profile: $profile. Available: ${AVAILABLE_PROFILES[*]}"
    fi
}

# Generate secure admin token if needed
generate_admin_token() {
    if ! grep -q "ADMIN_TOKEN=" "$ENV_FILE" || grep -q "change-this" "$ENV_FILE"; then
        warn "No secure admin token found in $ENV_FILE"
        
        if command -v openssl >/dev/null 2>&1; then
            local token=$(openssl rand -hex 32)
            log "Generated secure admin token"
            
            if grep -q "ADMIN_TOKEN=" "$ENV_FILE"; then
                sed -i.bak "s/ADMIN_TOKEN=.*/ADMIN_TOKEN=$token/" "$ENV_FILE"
            else
                echo "ADMIN_TOKEN=$token" >> "$ENV_FILE"
            fi
            
            log "Admin token updated in $ENV_FILE"
        else
            warn "OpenSSL not available. Please manually set ADMIN_TOKEN in $ENV_FILE"
        fi
    fi
}

# Start services
start_services() {
    local profile="${1:-$DEFAULT_PROFILE}"
    local detach="${2:-true}"
    
    validate_profile "$profile"
    generate_admin_token
    
    log "Starting GlinrDock with profile: $profile"
    
    local compose_args="--env-file $ENV_FILE"
    
    if [[ "$profile" != "default" ]]; then
        compose_args="$compose_args --profile $profile"
    fi
    
    if [[ "$detach" == "true" ]]; then
        compose_args="$compose_args -d"
    fi
    
    # Pull images first
    log "Pulling latest images..."
    $COMPOSE_CMD $compose_args pull
    
    # Start services
    log "Starting services..."
    $COMPOSE_CMD $compose_args up
    
    if [[ "$detach" == "true" ]]; then
        sleep 5
        show_status
        show_access_info
    fi
}

# Stop services
stop_services() {
    local force="${1:-false}"
    
    if [[ "$force" != "true" ]]; then
        echo -n "Are you sure you want to stop all services? [y/N] "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            log "Operation cancelled"
            return
        fi
    fi
    
    log "Stopping all services..."
    $COMPOSE_CMD --env-file "$ENV_FILE" down
    
    log "Services stopped"
}

# Restart services
restart_services() {
    log "Restarting services..."
    $COMPOSE_CMD --env-file "$ENV_FILE" restart
    
    sleep 5
    show_status
}

# Show logs
show_logs() {
    local service="${1:-}"
    
    if [[ -n "$service" ]]; then
        log "Showing logs for service: $service"
        $COMPOSE_CMD --env-file "$ENV_FILE" logs -f "$service"
    else
        log "Showing logs for all services"
        $COMPOSE_CMD --env-file "$ENV_FILE" logs -f
    fi
}

# Show service status
show_status() {
    log "Service status:"
    $COMPOSE_CMD --env-file "$ENV_FILE" ps
}

# Pull images
pull_images() {
    log "Pulling latest images..."
    $COMPOSE_CMD --env-file "$ENV_FILE" pull
    log "Images updated"
}

# Show access information
show_access_info() {
    echo
    echo "======================================"
    echo "    GlinrDock Access Information"
    echo "======================================"
    echo
    
    # Get admin token
    local admin_token=""
    if [[ -f "$ENV_FILE" ]]; then
        admin_token=$(grep "^ADMIN_TOKEN=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '"')
    fi
    
    echo "Dashboard:     http://localhost:8080"
    echo "Admin Token:   $admin_token"
    echo
    
    # Show additional endpoints based on running services
    if $COMPOSE_CMD --env-file "$ENV_FILE" ps | grep -q nginx; then
        echo "HTTP Proxy:    http://localhost:80"
        echo "HTTPS Proxy:   https://localhost:443"
    fi
    
    if $COMPOSE_CMD --env-file "$ENV_FILE" ps | grep -q caddy; then
        echo "HTTP Proxy:    http://localhost:80"
        echo "HTTPS Proxy:   https://localhost:443"
    fi
    
    if $COMPOSE_CMD --env-file "$ENV_FILE" ps | grep -q prometheus; then
        echo "Prometheus:    http://localhost:9090"
    fi
    
    if $COMPOSE_CMD --env-file "$ENV_FILE" ps | grep -q grafana; then
        echo "Grafana:       http://localhost:3000"
        local grafana_pass=""
        if [[ -f "$ENV_FILE" ]]; then
            grafana_pass=$(grep "^GRAFANA_PASSWORD=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '"')
        fi
        echo "Grafana Login: admin / $grafana_pass"
    fi
    
    echo
    echo "Next steps:"
    echo "1. Open the dashboard in your browser"
    echo "2. Login with the admin token"
    echo "3. Create your first project"
    echo
}

# Backup data volumes
backup_data() {
    local backup_file="glinrdock-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    
    log "Creating backup: $backup_file"
    
    # Create temporary container to access volumes
    docker run --rm \
        -v glinrdock_data:/data:ro \
        -v glinrdock_logs:/logs:ro \
        -v "$(pwd):/backup" \
        alpine tar -czf "/backup/$backup_file" -C / data logs
    
    log "Backup created: $backup_file"
}

# Restore data from backup
restore_data() {
    local backup_file="$1"
    
    if [[ ! -f "$backup_file" ]]; then
        error "Backup file not found: $backup_file"
    fi
    
    warn "This will overwrite existing data. Continue? [y/N]"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        log "Restore cancelled"
        return
    fi
    
    log "Restoring from: $backup_file"
    
    # Stop services first
    $COMPOSE_CMD --env-file "$ENV_FILE" down
    
    # Restore data
    docker run --rm \
        -v glinrdock_data:/data \
        -v glinrdock_logs:/logs \
        -v "$(pwd):/backup" \
        alpine tar -xzf "/backup/$(basename "$backup_file")" -C /
    
    log "Data restored successfully"
    log "Start services with: $0 up"
}

# Main function
main() {
    local command="${1:-help}"
    
    case "$command" in
        up)
            check_docker_compose
            check_files
            start_services "${2:-$DEFAULT_PROFILE}"
            ;;
        down)
            check_docker_compose
            stop_services "${2:-false}"
            ;;
        restart)
            check_docker_compose
            check_files
            restart_services
            ;;
        logs)
            check_docker_compose
            check_files
            show_logs "${2:-}"
            ;;
        ps|status)
            check_docker_compose
            check_files
            show_status
            ;;
        pull)
            check_docker_compose
            check_files
            pull_images
            ;;
        backup)
            check_docker_compose
            backup_data
            ;;
        restore)
            if [[ -z "${2:-}" ]]; then
                error "Please specify backup file to restore"
            fi
            check_docker_compose
            restore_data "$2"
            ;;
        help|--help|-h)
            print_usage
            ;;
        *)
            error "Unknown command: $command. Use 'help' for usage information."
            ;;
    esac
}

# Run main function with all arguments
main "$@"