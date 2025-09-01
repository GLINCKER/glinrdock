# Troubleshooting Guide

This guide covers common issues and their solutions for GlinrDock.

## Installation Issues

### Installation Script Fails

**Error**: `curl: command not found`
```bash
# Install curl first
# Ubuntu/Debian:
sudo apt-get update && sudo apt-get install curl

# RHEL/CentOS:
sudo yum install curl
```

**Error**: `Permission denied` during installation
```bash
# Ensure you're running with sudo
curl -fsSL https://github.com/GLINCKER/glinrdock-release/releases/latest/download/install.sh | sudo bash

# Or download and inspect first
curl -fsSL https://github.com/GLINCKER/glinrdock-release/releases/latest/download/install.sh > install.sh
chmod +x install.sh
sudo ./install.sh
```

**Error**: `Architecture not supported`
```bash
# Check your architecture
uname -m

# Supported architectures:
# x86_64 (amd64)
# aarch64 (arm64)

# For unsupported architectures, try Docker installation
```

### Binary Download Issues

**Error**: `404 Not Found` when downloading
```bash
# Check latest release version
curl -s https://api.github.com/repos/GLINCKER/glinrdock-release/releases/latest | grep tag_name

# Download specific version
curl -LO https://github.com/GLINCKER/glinrdock-release/releases/download/v1.0.0/glinrdockd_linux_amd64.tar.gz
```

**Error**: `Checksum mismatch`
```bash
# Re-download the file and checksums
curl -LO https://github.com/GLINCKER/glinrdock-release/releases/latest/download/glinrdockd_linux_amd64.tar.gz
curl -LO https://github.com/GLINCKER/glinrdock-release/releases/latest/download/SHA256SUMS

# Verify with verbose output
sha256sum -c SHA256SUMS --ignore-missing -v
```

## Service Issues

### Service Won't Start

**Check service status**:
```bash
sudo systemctl status glinrdockd
```

**Common error**: `bind: address already in use`
```bash
# Find process using port 8080
sudo netstat -tlnp | grep 8080
sudo lsof -i :8080

# Kill conflicting process or change GlinrDock port
sudo systemctl edit glinrdockd
```

Add override configuration:
```ini
[Service]
Environment=GLINRDOCK_BIND_ADDR=127.0.0.1:8081
```

**Common error**: `permission denied: /var/run/docker.sock`
```bash
# Add glinrdock user to docker group
sudo usermod -aG docker glinrdock
sudo systemctl restart glinrdockd

# Or fix socket permissions (less secure)
sudo chmod 666 /var/run/docker.sock
```

**Common error**: `no such file or directory: /usr/local/bin/glinrdockd`
```bash
# Verify binary exists and is executable
ls -la /usr/local/bin/glinrdockd
sudo chmod +x /usr/local/bin/glinrdockd

# Or reinstall
curl -fsSL https://github.com/GLINCKER/glinrdock-release/releases/latest/download/install.sh | sudo bash
```

### Service Crashes or Restarts

**Check logs**:
```bash
# Recent logs
sudo journalctl -u glinrdockd --since "1 hour ago"

# Follow logs in real-time
sudo journalctl -u glinrdockd -f

# All logs
sudo journalctl -u glinrdockd --no-pager
```

**Common causes**:
- Out of memory (check with `free -h`)
- Disk space full (check with `df -h`)
- Docker daemon not running
- Configuration file errors

## Docker Installation Issues

### Container Won't Start

**Check container status**:
```bash
docker ps -a | grep glinrdock
docker logs glinrdock
```

**Common error**: `docker: permission denied`
```bash
# Add user to docker group
sudo usermod -aG docker $USER
# Log out and back in, or:
newgrp docker

# Test Docker access
docker run hello-world
```

**Common error**: `pull access denied`
```bash
# Check image name and tag
docker images | grep glinrdock

# Pull image manually
docker pull ghcr.io/glincker/glinrdock:latest

# Or use specific version
docker pull ghcr.io/glincker/glinrdock:v1.0.0
```

**Common error**: `port is already allocated`
```bash
# Find process using port
sudo netstat -tlnp | grep 8080

# Use different port
docker run -p 8081:8080 ...

# Or stop conflicting container
docker stop $(docker ps -q --filter publish=8080)
```

### Volume Mount Issues

**Error**: `invalid mount config`
```bash
# Check volume syntax
docker run -v glinrdock_data:/var/lib/glinrdock ...

# Create volume explicitly
docker volume create glinrdock_data
```

**Error**: `permission denied` in container
```bash
# Check volume ownership
docker exec glinrdock ls -la /var/lib/glinrdock

# Fix permissions
docker exec --user root glinrdock chown -R glinrdock:glinrdock /var/lib/glinrdock
```

## Web Interface Issues

### Cannot Access Web Interface

**Check if service is running**:
```bash
# Linux
sudo systemctl status glinrdockd

# Docker
docker ps | grep glinrdock
```

**Check network connectivity**:
```bash
# Test locally
curl http://localhost:8080/v1/health

# Test from remote machine
curl http://YOUR_SERVER_IP:8080/v1/health
```

**Check firewall settings**:
```bash
# UFW (Ubuntu)
sudo ufw status
sudo ufw allow 8080/tcp

# firewalld (RHEL/CentOS)
sudo firewall-cmd --list-ports
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload

# iptables (manual)
sudo iptables -L | grep 8080
```

### Authentication Issues

**Error**: `Unauthorized` or `Invalid token`
```bash
# Get admin token
# Linux:
sudo grep admin_token /etc/glinrdock/config.toml

# Docker:
docker logs glinrdock | grep "Admin token"
docker exec glinrdock cat /etc/glinrdock/config.toml | grep admin_token
```

**Clear browser cache**:
- Hard refresh: Ctrl+F5 (Windows/Linux) or Cmd+Shift+R (Mac)
- Clear browser data and cookies
- Try incognito/private browsing mode

**Reset admin token**:
```bash
# Generate new token
NEW_TOKEN=$(openssl rand -hex 32)

# Linux:
sudo sed -i "s/admin_token = .*/admin_token = \"$NEW_TOKEN\"/" /etc/glinrdock/config.toml
sudo systemctl restart glinrdockd

# Docker:
docker run -e GLINRDOCK_ADMIN_TOKEN="$NEW_TOKEN" ...
```

### Interface Loads but Shows Errors

**Check browser console**:
1. Open Developer Tools (F12)
2. Check Console tab for JavaScript errors
3. Check Network tab for failed API requests

**Common API errors**:
- `CORS errors`: Check GlinrDock is bound to correct interface
- `Connection refused`: Verify GlinrDock is running
- `Timeout errors`: Check system resources and Docker daemon

## Docker Integration Issues

### Cannot Connect to Docker Daemon

**Verify Docker is running**:
```bash
sudo systemctl status docker
sudo systemctl start docker

# Test Docker access
docker ps
```

**Check Docker socket permissions**:
```bash
ls -la /var/run/docker.sock

# Should show: srw-rw---- 1 root docker
# If not, fix permissions:
sudo chown root:docker /var/run/docker.sock
sudo chmod 660 /var/run/docker.sock
```

**For Docker-in-Docker setups**:
```bash
# Mount Docker binary and socket
docker run -v /usr/bin/docker:/usr/bin/docker -v /var/run/docker.sock:/var/run/docker.sock ...
```

### Container Operations Fail

**Error**: `container not found`
- Container may have been removed outside GlinrDock
- Refresh the interface
- Check Docker directly: `docker ps -a`

**Error**: `network not found`
```bash
# List networks
docker network ls

# Recreate default network
docker network create glinrdock_default
```

**Error**: `volume not found`
```bash
# List volumes
docker volume ls

# Recreate volume
docker volume create PROJECT_VOLUME_NAME
```

## Performance Issues

### High Memory Usage

**Check system memory**:
```bash
free -h
top -p $(pgrep glinrdockd)

# For Docker
docker stats glinrdock
```

**Optimize GlinrDock**:
```bash
# Linux - limit memory in service file
sudo systemctl edit glinrdockd
```

Add:
```ini
[Service]
MemoryMax=512M
```

**Clean up Docker resources**:
```bash
# Remove unused containers, networks, images
docker system prune -f

# Remove unused volumes (careful!)
docker volume prune -f
```

### High CPU Usage

**Check processes**:
```bash
top -p $(pgrep glinrdockd)
htop
```

**Common causes**:
- Too many containers being monitored
- Frequent log polling
- Docker daemon issues

**Solutions**:
- Reduce log monitoring frequency in settings
- Restart Docker daemon: `sudo systemctl restart docker`
- Restart GlinrDock: `sudo systemctl restart glinrdockd`

### Slow Web Interface

**Check network latency**:
```bash
# Test API response time
time curl http://localhost:8080/v1/health
```

**Browser issues**:
- Disable browser extensions
- Clear cache and cookies
- Try different browser
- Check browser Developer Tools for slow requests

**System issues**:
- Check disk space: `df -h`
- Check I/O wait: `iostat -x 1`
- Check system load: `uptime`

## Configuration Issues

### Invalid Configuration File

**Check configuration syntax**:
```bash
# Linux
sudo cat /etc/glinrdock/config.toml

# Look for syntax errors
sudo glinrdockd --config /etc/glinrdock/config.toml --check-config
```

**Reset to default configuration**:
```bash
sudo cp /etc/glinrdock/config.toml /etc/glinrdock/config.toml.backup

# Regenerate default config
sudo /usr/local/bin/glinrdockd --generate-config > /tmp/config.toml
sudo cp /tmp/config.toml /etc/glinrdock/config.toml
sudo chown glinrdock:glinrdock /etc/glinrdock/config.toml
sudo systemctl restart glinrdockd
```

### Environment Variable Issues

**Docker environment variables not working**:
```bash
# Check variables are set
docker exec glinrdock env | grep GLINRDOCK

# Restart container with correct variables
docker run -e GLINRDOCK_LOG_LEVEL=debug ...
```

## Networking Issues

### Cannot Access from Remote Hosts

**Check bind address**:
```bash
# Should bind to 0.0.0.0 for remote access
netstat -tlnp | grep glinrdockd

# Linux - edit config
sudo nano /etc/glinrdock/config.toml
# Change: bind_addr = "0.0.0.0:8080"

# Docker - ensure correct port mapping
docker run -p 8080:8080 ...  # Not -p 127.0.0.1:8080:8080
```

**Security note**: Only bind to 0.0.0.0 if necessary and behind firewall/proxy.

### DNS Resolution Issues

**Check DNS inside containers**:
```bash
docker exec CONTAINER_NAME nslookup google.com

# Fix DNS in Docker daemon
sudo nano /etc/docker/daemon.json
```

Add:
```json
{
  "dns": ["8.8.8.8", "8.8.4.4"]
}
```

```bash
sudo systemctl restart docker
```

## Data Recovery

### Restore from Backup

**Linux installation**:
```bash
sudo systemctl stop glinrdockd
sudo tar xzf glinrdock-backup.tar.gz -C /var/lib/glinrdock/
sudo chown -R glinrdock:glinrdock /var/lib/glinrdock/
sudo systemctl start glinrdockd
```

**Docker installation**:
```bash
docker-compose down
docker run --rm -v glinrdock_data:/data -v $(pwd):/backup alpine tar xzf /backup/glinrdock-backup.tar.gz -C /data
docker-compose up -d
```

### Recover Lost Projects

**Check Docker directly**:
```bash
# Find containers that may belong to lost projects
docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"

# Check container labels
docker inspect CONTAINER_NAME | grep -A5 -B5 Label
```

## Getting More Help

### Enable Debug Logging

**Linux**:
```bash
sudo nano /etc/glinrdock/config.toml
# Change: level = "debug"
sudo systemctl restart glinrdockd
```

**Docker**:
```bash
docker run -e GLINRDOCK_LOG_LEVEL=debug ...
```

### Collect System Information

```bash
# Create support bundle
{
  echo "=== System Info ==="
  uname -a
  echo "=== Docker Info ==="
  docker version
  docker info
  echo "=== GlinrDock Status ==="
  systemctl status glinrdockd
  echo "=== Recent Logs ==="
  journalctl -u glinrdockd --since "1 hour ago" | tail -50
} > glinrdock-debug.txt
```

### Report Issues

When reporting issues, include:
1. GlinrDock version
2. Operating system and version
3. Docker version
4. Installation method used
5. Error messages and logs
6. Steps to reproduce the issue

**GitHub Issues**: https://github.com/GLINCKER/glinrdock-release/issues
**Enterprise Support**: support@glincker.com

---

**Still having issues?**
- Check our [FAQ](FAQ.md)
- Ask in [GitHub Discussions](https://github.com/GLINCKER/glinrdock-release/discussions)
- Review [installation guides](INSTALL_LINUX.md)