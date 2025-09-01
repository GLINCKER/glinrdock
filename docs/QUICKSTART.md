# GlinrDock Quick Start

Get GlinrDock running in minutes with this streamlined guide.

## Installation

### Linux (Recommended)
```bash
curl -fsSL https://github.com/GLINCKER/glinrdock-release/releases/latest/download/install.sh | sudo bash
```

### Docker Compose
```bash
curl -fsSL https://raw.githubusercontent.com/GLINCKER/glinrdock-release/main/deploy/docker-compose.yml -o docker-compose.yml
docker-compose up -d
```

## First Access

1. Open http://localhost:8080 in your browser
2. Find your admin token:
   - Linux: `sudo cat /etc/glinrdock/config.toml | grep admin_token`
   - Docker: `docker-compose logs glinrdock | grep "Admin token"`
3. Log in with the admin token

## Deploy Your First Container

### Using the Web Interface
1. Navigate to **Projects** → **New Project**
2. Create a project named "hello-world"
3. Add a service:
   - Name: `nginx-demo`
   - Image: `nginx:alpine`
   - Port: `80:8080`
4. Click **Deploy**
5. Access at http://localhost:8080

### Using Docker Compose Import
1. Create a `docker-compose.yml` file:
```yaml
version: '3.8'
services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
```

2. Import via web interface: **Projects** → **Import** → Upload file

## Next Steps

- [Complete Installation Guide](INSTALL_LINUX.md)
- [Docker Installation](INSTALL_DOCKER.md)
- [FAQ](FAQ.md)

Need help? Check our [troubleshooting guide](TROUBLESHOOTING.md).