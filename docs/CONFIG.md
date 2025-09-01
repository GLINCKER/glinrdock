# Configuration Guide

This guide covers all configuration options available for GlinrDock.

## Configuration Methods

GlinrDock can be configured using:
1. Environment variables
2. Configuration files
3. Command-line flags
4. Default values

### Priority Order

Configuration values are applied in this order (highest to lowest priority):
1. Command-line flags
2. Environment variables
3. Configuration file values
4. Default values

## Environment Variables

### Core Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `GLINRDOCK_BIND_ADDR` | `0.0.0.0:8080` | Network bind address and port |
| `GLINRDOCK_DATA_DIR` | `/var/lib/glinrdock/data` | Data storage directory |
| `GLINRDOCK_LOG_LEVEL` | `info` | Log level (debug, info, warn, error) |
| `GLINRDOCK_LOG_FILE` | *stdout* | Log file path |
| `GLINRDOCK_CONFIG_FILE` | *none* | Configuration file path |

### Authentication

| Variable | Default | Description |
|----------|---------|-------------|
| `ADMIN_TOKEN` | *required* | Admin API authentication token |
| `TOKEN_EXPIRY` | `24h` | API token expiration time |
| `SESSION_TIMEOUT` | `8h` | Web session timeout |

### Docker Integration

| Variable | Default | Description |
|----------|---------|-------------|
| `DOCKER_HOST` | `unix:///var/run/docker.sock` | Docker daemon socket |
| `DOCKER_API_VERSION` | *auto* | Docker API version to use |
| `DOCKER_TIMEOUT` | `30s` | Docker operation timeout |
| `DOCKER_TLS_VERIFY` | `false` | Enable Docker TLS verification |
| `DOCKER_CERT_PATH` | *none* | Docker TLS certificate path |

### Security Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `TLS_ENABLED` | `false` | Enable TLS/HTTPS |
| `TLS_CERT_FILE` | *none* | TLS certificate file |
| `TLS_KEY_FILE` | *none* | TLS private key file |
| `CORS_ORIGINS` | *none* | Allowed CORS origins (comma-separated) |
| `RATE_LIMIT_REQUESTS` | `100` | Rate limit requests per minute |
| `RATE_LIMIT_BURST` | `20` | Rate limit burst size |

### Webhook Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `WEBHOOK_SECRET` | *none* | HMAC secret for webhook validation |
| `WEBHOOK_TIMEOUT` | `30s` | Webhook processing timeout |
| `WEBHOOK_RETRIES` | `3` | Number of webhook retry attempts |

### Database Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `DB_PATH` | `data/glinrdock.db` | SQLite database file path |
| `DB_MIGRATE` | `true` | Run database migrations on startup |
| `DB_BACKUP_ENABLED` | `true` | Enable automatic database backups |
| `DB_BACKUP_INTERVAL` | `6h` | Database backup interval |

## Configuration File

### File Locations

GlinrDock looks for configuration files in these locations:
1. Path specified by `GLINRDOCK_CONFIG_FILE` environment variable
2. `/etc/glinrdock/glinrdock.conf`
3. `./glinrdock.conf`

### File Format

Configuration files use simple `KEY=VALUE` format:

```bash
# /etc/glinrdock/glinrdock.conf
# GlinrDock Configuration File

# Core Settings
GLINRDOCK_BIND_ADDR=127.0.0.1:8080
GLINRDOCK_DATA_DIR=/var/lib/glinrdock/data
GLINRDOCK_LOG_LEVEL=info
GLINRDOCK_LOG_FILE=/var/lib/glinrdock/logs/glinrdock.log

# Authentication
ADMIN_TOKEN=your-secure-admin-token-change-this
TOKEN_EXPIRY=24h

# Docker Settings
DOCKER_HOST=unix:///var/run/docker.sock
DOCKER_TIMEOUT=30s

# Security
TLS_ENABLED=false
CORS_ORIGINS=https://yourdomain.com,https://www.yourdomain.com
RATE_LIMIT_REQUESTS=100

# Webhooks
WEBHOOK_SECRET=your-webhook-secret
WEBHOOK_TIMEOUT=30s

# Database
DB_BACKUP_ENABLED=true
DB_BACKUP_INTERVAL=6h
```

### File Security

Secure your configuration file:

```bash
# Set proper ownership and permissions
sudo chown root:glinrdock /etc/glinrdock/glinrdock.conf
sudo chmod 640 /etc/glinrdock/glinrdock.conf

# Verify permissions
ls -la /etc/glinrdock/glinrdock.conf
# Should show: -rw-r----- 1 root glinrdock
```

## Command-Line Flags

Common command-line options:

```bash
glinrdockd [options]

Options:
  --bind-addr string     Bind address (default "0.0.0.0:8080")
  --data-dir string      Data directory (default "/var/lib/glinrdock/data")
  --log-level string     Log level (default "info")
  --log-file string      Log file path
  --config string        Configuration file path
  --version              Show version information
  --help                 Show help information
```

Example usage:
```bash
glinrdockd --bind-addr=127.0.0.1:8081 --log-level=debug --data-dir=/tmp/glinrdock
```

## Configuration Examples

### Production Configuration

```bash
# /etc/glinrdock/glinrdock.conf
# Production GlinrDock Configuration

# Network - bind to localhost only, use reverse proxy
GLINRDOCK_BIND_ADDR=127.0.0.1:8080
GLINRDOCK_DATA_DIR=/var/lib/glinrdock/data
GLINRDOCK_LOG_LEVEL=warn
GLINRDOCK_LOG_FILE=/var/lib/glinrdock/logs/glinrdock.log

# Strong authentication
ADMIN_TOKEN=prod-token-32-chars-minimum-length-required
TOKEN_EXPIRY=8h

# Docker
DOCKER_HOST=unix:///var/run/docker.sock
DOCKER_TIMEOUT=60s

# Security hardening
CORS_ORIGINS=https://glinrdock.yourdomain.com
RATE_LIMIT_REQUESTS=50
RATE_LIMIT_BURST=10

# Webhooks
WEBHOOK_SECRET=webhook-hmac-secret-for-validation
WEBHOOK_TIMEOUT=15s

# Database
DB_BACKUP_ENABLED=true
DB_BACKUP_INTERVAL=4h
```

### Development Configuration

```bash
# Development GlinrDock Configuration
GLINRDOCK_BIND_ADDR=0.0.0.0:8080
GLINRDOCK_DATA_DIR=./data
GLINRDOCK_LOG_LEVEL=debug
GLINRDOCK_LOG_FILE=./glinrdock.log

# Development token
ADMIN_TOKEN=dev-token-for-testing

# Docker
DOCKER_HOST=unix:///var/run/docker.sock

# Permissive CORS for development
CORS_ORIGINS=http://localhost:3000,http://127.0.0.1:3000

# Disable rate limiting for testing
RATE_LIMIT_REQUESTS=1000

# Disable backups in development
DB_BACKUP_ENABLED=false
```

### Docker Compose Configuration

```yaml
# docker-compose.yml
version: '3.8'
services:
  glinrdock:
    image: ghcr.io/glincker/glinrdock:latest
    environment:
      # Core settings
      GLINRDOCK_BIND_ADDR: 0.0.0.0:8080
      GLINRDOCK_DATA_DIR: /data
      GLINRDOCK_LOG_LEVEL: info
      
      # Authentication
      ADMIN_TOKEN: ${ADMIN_TOKEN}
      
      # Docker
      DOCKER_HOST: unix:///var/run/docker.sock
      
      # Security
      CORS_ORIGINS: ${CORS_ORIGINS:-}
      
      # Webhooks
      WEBHOOK_SECRET: ${WEBHOOK_SECRET:-}
    volumes:
      - glinrdock_data:/data
      - /var/run/docker.sock:/var/run/docker.sock:ro
    ports:
      - "8080:8080"

volumes:
  glinrdock_data:
```

### Reverse Proxy Configuration

#### nginx Configuration

```nginx
# /etc/nginx/sites-available/glinrdock
server {
    listen 443 ssl http2;
    server_name glinrdock.yourdomain.com;

    ssl_certificate /path/to/certificate.crt;
    ssl_certificate_key /path/to/private.key;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_read_timeout 86400;
    }
}
```

#### Caddy Configuration

```caddyfile
# /etc/caddy/Caddyfile
glinrdock.yourdomain.com {
    reverse_proxy 127.0.0.1:8080 {
        header_up Host {upstream_hostport}
        header_up X-Real-IP {remote_host}
        header_up X-Forwarded-For {remote_host}
        header_up X-Forwarded-Proto {scheme}
    }
    
    log {
        output file /var/log/caddy/glinrdock.log
    }
}
```

## Configuration Validation

### Validate Configuration

```bash
# Check configuration syntax (if supported)
glinrdockd --config-check

# Test configuration by starting in foreground
glinrdockd --config=/path/to/config --log-level=debug
```

### Common Configuration Issues

**Port binding errors:**
```bash
# Check if port is already in use
sudo netstat -tlnp | grep :8080

# Use different port
GLINRDOCK_BIND_ADDR=127.0.0.1:8081
```

**Permission errors:**
```bash
# Check data directory permissions
ls -la /var/lib/glinrdock/
sudo chown -R glinrdock:glinrdock /var/lib/glinrdock/

# Check Docker socket permissions
ls -la /var/run/docker.sock
sudo usermod -aG docker glinrdock
```

**Token authentication issues:**
```bash
# Verify token length (minimum 32 characters recommended)
echo -n "your-token" | wc -c

# Generate secure token
openssl rand -hex 32
```

## Environment-Specific Configurations

### Systemd Service Configuration

```ini
# /etc/systemd/system/glinrdock.service
[Unit]
Description=GlinrDock Container Management
After=network.target docker.service
Wants=docker.service

[Service]
Type=exec
User=glinrdock
Group=glinrdock
EnvironmentFile=/etc/glinrdock/glinrdock.conf
ExecStart=/usr/local/bin/glinrdockd
Restart=always
RestartSec=3

# Security hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectHome=true
ProtectSystem=strict
ReadWritePaths=/var/lib/glinrdock

[Install]
WantedBy=multi-user.target
```

### Container Configuration

```dockerfile
# Custom Docker image with configuration
FROM ghcr.io/glincker/glinrdock:latest

# Copy custom configuration
COPY glinrdock.conf /etc/glinrdock/glinrdock.conf

# Set proper permissions
RUN chown root:glinrdock /etc/glinrdock/glinrdock.conf && \
    chmod 640 /etc/glinrdock/glinrdock.conf

# Use configuration file
ENV GLINRDOCK_CONFIG_FILE=/etc/glinrdock/glinrdock.conf
```

## Advanced Configuration

### TLS/HTTPS Configuration

```bash
# Enable TLS
TLS_ENABLED=true
TLS_CERT_FILE=/path/to/certificate.crt
TLS_KEY_FILE=/path/to/private.key
GLINRDOCK_BIND_ADDR=0.0.0.0:8443
```

### Database Tuning

```bash
# SQLite-specific tuning
DB_PATH=/var/lib/glinrdock/data/glinrdock.db
DB_MIGRATE=true
DB_BACKUP_ENABLED=true
DB_BACKUP_INTERVAL=2h
```

### Logging Configuration

```bash
# Structured logging
GLINRDOCK_LOG_LEVEL=info
GLINRDOCK_LOG_FILE=/var/lib/glinrdock/logs/glinrdock.log
GLINRDOCK_LOG_FORMAT=json

# Log rotation (handled by logrotate)
# /etc/logrotate.d/glinrdock
/var/lib/glinrdock/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    notifempty
    create 640 glinrdock glinrdock
    postrotate
        systemctl reload glinrdock
    endscript
}
```

## Configuration Best Practices

### Security Best Practices

1. **Use strong admin tokens** (32+ characters, cryptographically random)
2. **Bind to localhost** when using reverse proxy
3. **Enable TLS** for production deployments
4. **Secure configuration files** (640 permissions, root:glinrdock ownership)
5. **Use environment-specific configurations**
6. **Regularly rotate tokens and secrets**

### Performance Optimization

1. **Adjust timeouts** based on your Docker environment
2. **Configure appropriate rate limits**
3. **Enable database backups** with suitable intervals
4. **Use appropriate log levels** (info or warn for production)
5. **Monitor resource usage** and adjust limits

### Maintenance

1. **Document configuration changes**
2. **Version control configuration files**
3. **Test configuration changes** in staging first
4. **Monitor logs** for configuration-related errors
5. **Review and update** configurations regularly

For configuration support, see:
- [Installation Guide](INSTALL.md) for setup procedures
- [Security Guide](SECURITY.md) for security considerations
- [Troubleshooting Guide](TROUBLESHOOTING.md) for common issues