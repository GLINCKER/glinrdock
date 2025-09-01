# Docker Installation Guide

Run GlinrDock using Docker containers for easy deployment and isolation.

## Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+ (optional but recommended)

## Quick Start with Docker Compose

1. **Download docker-compose.yml**:
```bash
curl -fsSL https://raw.githubusercontent.com/GLINCKER/glinrdock-release/main/packaging/compose/docker-compose.yml -o docker-compose.yml
```

2. **Set required environment variables**:
```bash
# Create .env file with secure admin token
echo "ADMIN_TOKEN=$(openssl rand -hex 32)" > .env
```

3. **Start GlinrDock**:
```bash
docker compose up -d
```

4. **Access the interface**:
   - Open http://localhost:8080
   - Use the admin token from your .env file

## Container Image

GlinrDock uses a minimal, security-hardened container image:

- **Base**: `gcr.io/distroless/static:nonroot` 
- **Registry**: `ghcr.io/glincker/glinrdock`
- **Architecture**: Multi-arch (amd64, arm64)
- **Security**: Non-root user, read-only filesystem, minimal attack surface

## Manual Docker Run

### Basic Setup

```bash
docker run -d \
  --name glinrdock \
  --restart unless-stopped \
  --read-only \
  --security-opt no-new-privileges:true \
  --user 65532:65532 \
  -p 8080:8080 \
  -v ./data:/data \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  --tmpfs /tmp:size=100M,mode=1777 \
  -e ADMIN_TOKEN="$(openssl rand -hex 32)" \
  ghcr.io/glincker/glinrdock:latest
```

### Production Setup

```bash
docker run -d \
  --name glinrdock \
  --restart unless-stopped \
  --read-only \
  --security-opt no-new-privileges:true \
  --user 65532:65532 \
  --cap-drop ALL \
  -p 127.0.0.1:8080:8080 \
  -v ./data:/data \
  -v ./config:/etc/glinrdock:ro \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -v /etc/localtime:/etc/localtime:ro \
  --tmpfs /tmp:size=100M,mode=1777 \
  -e ADMIN_TOKEN="your-secure-token-here" \
  -e GLINRDOCK_LOG_LEVEL="info" \
  ghcr.io/glincker/glinrdock:latest
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `GLINRDOCK_HTTP_ADDR` | `:8080` | HTTP server bind address |
| `GLINRDOCK_DATA_DIR` | `/data` | Data directory path |
| `ADMIN_TOKEN` | *required* | Admin authentication token |
| `GLINRDOCK_LOG_LEVEL` | `info` | Log level (debug, info, warn, error) |
| `GLINRDOCK_LOG_FORMAT` | `json` | Log format (json, text) |

### Volume Mounts

- `/data` - Application data and configuration
- `/var/run/docker.sock` - Docker daemon socket (read-only)
- `/etc/glinrdock` - Configuration files (optional, read-only)
- `/tmp` - Temporary files (tmpfs recommended)

## Docker Compose Configuration

Complete `docker-compose.yml` example:

```yaml
version: '3.8'

services:
  glinrdock:
    image: ghcr.io/glincker/glinrdock:latest
    container_name: glinrdock
    restart: unless-stopped
    ports:
      - "127.0.0.1:8080:8080"
    volumes:
      - glinrdock_data:/var/lib/glinrdock
      - /var/run/docker.sock:/var/run/docker.sock
      - /etc/localtime:/etc/localtime:ro
    environment:
      - GLINRDOCK_LOG_LEVEL=info
      - GLINRDOCK_ADMIN_TOKEN=${GLINRDOCK_ADMIN_TOKEN:-}
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:8080/v1/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

volumes:
  glinrdock_data:
```

## Reverse Proxy Setup

### Nginx

```nginx
server {
    listen 80;
    server_name glinrdock.example.com;
    
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

### Traefik

```yaml
services:
  glinrdock:
    image: ghcr.io/glincker/glinrdock:latest
    labels:
      - traefik.enable=true
      - traefik.http.routers.glinrdock.rule=Host(`glinrdock.example.com`)
      - traefik.http.routers.glinrdock.tls.certresolver=letsencrypt
      - traefik.http.services.glinrdock.loadbalancer.server.port=8080
```

## Backup and Restore

### Backup
```bash
# Stop container
docker-compose down

# Backup data volume
docker run --rm -v glinrdock_data:/data -v $(pwd):/backup alpine tar czf /backup/glinrdock-backup.tar.gz -C /data .

# Restart
docker-compose up -d
```

### Restore
```bash
# Stop container
docker-compose down

# Remove existing volume (caution!)
docker volume rm glinrdock_data

# Restore data
docker run --rm -v glinrdock_data:/data -v $(pwd):/backup alpine tar xzf /backup/glinrdock-backup.tar.gz -C /data

# Restart
docker-compose up -d
```

## Troubleshooting

### Common Issues

**Container fails to start**:
```bash
docker logs glinrdock
```

**Cannot connect to Docker daemon**:
- Verify Docker socket is mounted correctly
- Check Docker daemon is running on host
- Ensure container has permission to access socket

**Port binding errors**:
- Check if port 8080 is already in use: `netstat -tlnp | grep 8080`
- Change port mapping: `-p 8081:8080`

**Permission denied accessing Docker socket**:
```bash
# Option 1: Run container as docker group user
docker run --user $(id -u):$(getent group docker | cut -d: -f3) ...

# Option 2: Add Docker socket permissions (less secure)
sudo chmod 666 /var/run/docker.sock
```

### Health Checks

Check container health:
```bash
docker exec glinrdock wget -qO- http://localhost:8080/v1/health
```

View container logs:
```bash
docker logs -f glinrdock
```

## Security Considerations

1. **Bind to localhost only** in production: `127.0.0.1:8080:8080`
2. **Use strong admin token**: Generate with `openssl rand -hex 32`
3. **Regular updates**: `docker-compose pull && docker-compose up -d`
4. **Network isolation**: Use custom Docker networks
5. **Read-only container**: Add `--read-only --tmpfs /tmp`

## Next Steps

- [Quick Start Guide](QUICKSTART.md)
- [Security Best Practices](SECURITY.md)
- [Troubleshooting Guide](TROUBLESHOOTING.md)