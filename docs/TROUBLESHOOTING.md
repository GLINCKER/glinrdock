# Troubleshooting Guide

This guide covers common issues and solutions for GlinrDock installation and operation.

## Installation Issues

### Install Script Fails

**Problem**: Install script exits with errors during execution.

**Common causes and solutions:**

1. **Insufficient permissions:**
   ```bash
   # Run with sudo
   curl -fsSL https://github.com/GLINCKER/glinrdock-release/releases/latest/download/install.sh | sudo bash
   ```

2. **Network connectivity issues:**
   ```bash
   # Test connectivity
   curl -I https://github.com/GLINCKER/glinrdock-release/releases/latest
   
   # Use offline installation
   curl -LO https://github.com/GLINCKER/glinrdock-release/releases/latest/download/install.sh
   curl -LO https://github.com/GLINCKER/glinrdock-release/releases/latest/download/glinrdockd_linux_amd64.tar.gz
   chmod +x install.sh
   sudo LOCAL_BINARY=./glinrdockd_linux_amd64.tar.gz ./install.sh
   ```

3. **Unsupported architecture:**
   ```bash
   # Check your architecture
   uname -m
   dpkg --print-architecture  # On Debian/Ubuntu
   
   # Available architectures: x86_64 (amd64), aarch64 (arm64)
   ```

4. **Missing dependencies:**
   ```bash
   # Install required tools
   # Ubuntu/Debian
   sudo apt update && sudo apt install -y curl tar
   
   # CentOS/RHEL
   sudo yum install -y curl tar
   ```

### Binary Download Fails

**Problem**: Cannot download GlinrDock binary from GitHub releases.

**Solutions:**

1. **Check release availability:**
   ```bash
   curl -s https://api.github.com/repos/GLINCKER/glinrdock-release/releases/latest | grep "tag_name"
   ```

2. **Manual download:**
   ```bash
   # Go to releases page and download manually
   # https://github.com/GLINCKER/glinrdock-release/releases
   ```

3. **Proxy/firewall issues:**
   ```bash
   # Configure proxy if needed
   export http_proxy=http://proxy.company.com:8080
   export https_proxy=http://proxy.company.com:8080
   ```

### Checksum Verification Fails

**Problem**: SHA256 checksum doesn't match downloaded file.

**Solutions:**

1. **Re-download the file:**
   ```bash
   rm glinrdockd_linux_amd64.tar.gz
   curl -LO https://github.com/GLINCKER/glinrdock-release/releases/latest/download/glinrdockd_linux_amd64.tar.gz
   ```

2. **Verify checksum file:**
   ```bash
   # Re-download checksum
   curl -LO https://github.com/GLINCKER/glinrdock-release/releases/latest/download/glinrdockd_linux_amd64.tar.gz.sha256
   
   # Manual verification
   sha256sum glinrdockd_linux_amd64.tar.gz
   cat glinrdockd_linux_amd64.tar.gz.sha256
   ```

3. **Network corruption:**
   Use a different network or download method if checksums consistently fail.

## Service Startup Issues

### systemd Service Won't Start

**Problem**: `systemctl start glinrdock` fails or service doesn't start.

**Diagnosis:**
```bash
# Check service status
sudo systemctl status glinrdock.service

# View detailed logs
sudo journalctl -u glinrdock.service -f

# Check service file
sudo systemctl cat glinrdock.service
```

**Common causes and solutions:**

1. **Binary not found or not executable:**
   ```bash
   # Check binary location and permissions
   ls -la /usr/local/bin/glinrdockd
   
   # Fix permissions if needed
   sudo chmod +x /usr/local/bin/glinrdockd
   ```

2. **Configuration file issues:**
   ```bash
   # Check configuration file
   sudo ls -la /etc/glinrdock/glinrdock.conf
   
   # Verify syntax (no spaces around =)
   sudo cat /etc/glinrdock/glinrdock.conf
   
   # Fix permissions
   sudo chown root:glinrdock /etc/glinrdock/glinrdock.conf
   sudo chmod 640 /etc/glinrdock/glinrdock.conf
   ```

3. **User and directory permissions:**
   ```bash
   # Check glinrdock user exists
   id glinrdock
   
   # Create if missing
   sudo useradd --system --user-group --home-dir /var/lib/glinrdock glinrdock
   
   # Fix directory permissions
   sudo chown -R glinrdock:glinrdock /var/lib/glinrdock
   sudo chmod 750 /var/lib/glinrdock
   ```

4. **Port already in use:**
   ```bash
   # Check what's using the port
   sudo netstat -tlnp | grep :8080
   sudo ss -tlnp | grep :8080
   
   # Use different port
   sudo sed -i 's/8080/8081/g' /etc/glinrdock/glinrdock.conf
   ```

### Docker Socket Permission Issues

**Problem**: GlinrDock can't access Docker daemon.

**Error messages:**
- "Permission denied" when accessing Docker socket
- "Cannot connect to the Docker daemon"

**Solutions:**

1. **Add user to docker group:**
   ```bash
   sudo usermod -aG docker glinrdock
   
   # Restart service to pick up new group membership
   sudo systemctl restart glinrdock.service
   ```

2. **Check Docker socket permissions:**
   ```bash
   ls -la /var/run/docker.sock
   # Should show: srw-rw---- 1 root docker
   
   # Fix permissions if needed
   sudo chmod 660 /var/run/docker.sock
   sudo chown root:docker /var/run/docker.sock
   ```

3. **Verify Docker is running:**
   ```bash
   sudo systemctl status docker
   sudo systemctl start docker
   ```

4. **Test Docker access:**
   ```bash
   # Test as glinrdock user
   sudo -u glinrdock docker ps
   ```

### Data Directory Issues

**Problem**: Cannot write to data directory or database errors.

**Solutions:**

1. **Check directory permissions:**
   ```bash
   ls -la /var/lib/glinrdock/
   
   # Fix permissions
   sudo chown -R glinrdock:glinrdock /var/lib/glinrdock
   sudo chmod 750 /var/lib/glinrdock
   sudo chmod 640 /var/lib/glinrdock/data/*
   ```

2. **Disk space issues:**
   ```bash
   # Check available space
   df -h /var/lib/glinrdock
   
   # Clean up if needed
   sudo find /var/lib/glinrdock/logs -name "*.log" -mtime +30 -delete
   ```

3. **SELinux issues (RHEL/CentOS):**
   ```bash
   # Check SELinux status
   sestatus
   
   # Set proper context
   sudo semanage fcontext -a -t container_file_t "/var/lib/glinrdock(/.*)?"
   sudo restorecon -R /var/lib/glinrdock
   ```

## Network and Connectivity Issues

### Cannot Access Web Interface

**Problem**: Browser cannot connect to GlinrDock dashboard.

**Diagnosis steps:**

1. **Test local access:**
   ```bash
   curl http://localhost:8080/health
   curl -I http://localhost:8080/
   ```

2. **Check service binding:**
   ```bash
   sudo netstat -tlnp | grep glinrdockd
   # Should show: tcp 0 0 0.0.0.0:8080 LISTEN pid/glinrdockd
   ```

3. **Test from remote machine:**
   ```bash
   # Replace SERVER_IP with actual IP
   curl http://SERVER_IP:8080/health
   ```

**Solutions:**

1. **Firewall blocking access:**
   ```bash
   # Ubuntu/Debian (ufw)
   sudo ufw status
   sudo ufw allow 8080
   
   # CentOS/RHEL (firewalld)
   sudo firewall-cmd --list-ports
   sudo firewall-cmd --add-port=8080/tcp --permanent
   sudo firewall-cmd --reload
   
   # iptables
   sudo iptables -I INPUT -p tcp --dport 8080 -j ACCEPT
   ```

2. **Wrong bind address:**
   ```bash
   # Check configuration
   sudo grep BIND_ADDR /etc/glinrdock/glinrdock.conf
   
   # For remote access, use:
   GLINRDOCK_BIND_ADDR=0.0.0.0:8080
   
   # For local only:
   GLINRDOCK_BIND_ADDR=127.0.0.1:8080
   ```

3. **Cloud/VPS security groups:**
   - Check AWS Security Groups, Azure NSGs, or GCP Firewall Rules
   - Ensure port 8080 is open for inbound traffic

### API Requests Return "Unauthorized"

**Problem**: All API requests return 401 Unauthorized.

**Diagnosis:**
```bash
# Test health endpoint (should work without auth)
curl http://localhost:8080/health

# Test with admin token
curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:8080/v1/info
```

**Solutions:**

1. **Missing or incorrect admin token:**
   ```bash
   # Find admin token
   sudo grep ADMIN_TOKEN /etc/glinrdock/glinrdock.conf
   
   # Test with correct format
   curl -H "Authorization: Bearer actual-token-here" http://localhost:8080/v1/info
   ```

2. **Token too short:**
   ```bash
   # Generate new secure token (32+ characters)
   NEW_TOKEN=$(openssl rand -hex 32)
   
   # Update configuration
   sudo sed -i "s/ADMIN_TOKEN=.*/ADMIN_TOKEN=$NEW_TOKEN/" /etc/glinrdock/glinrdock.conf
   sudo systemctl restart glinrdock
   ```

3. **Configuration not loaded:**
   ```bash
   # Check if config file is being read
   sudo journalctl -u glinrdock.service | grep -i config
   
   # Verify EnvironmentFile in service
   sudo systemctl cat glinrdock.service | grep EnvironmentFile
   ```

### CORS Errors in Browser

**Problem**: Browser console shows CORS errors when accessing API.

**Solutions:**

1. **Configure CORS origins:**
   ```bash
   # Add to configuration
   echo "CORS_ORIGINS=http://localhost:3000,https://yourdomain.com" | sudo tee -a /etc/glinrdock/glinrdock.conf
   sudo systemctl restart glinrdock
   ```

2. **Use reverse proxy:**
   Set up nginx or Caddy to handle CORS properly.

## Docker Integration Issues

### Containers Don't Appear in GlinrDock

**Problem**: Running Docker containers are not visible in GlinrDock.

**Solutions:**

1. **Check Docker connection:**
   ```bash
   # Test as glinrdock user
   sudo -u glinrdock docker ps
   
   # Check Docker socket path
   sudo grep DOCKER_HOST /etc/glinrdock/glinrdock.conf
   ```

2. **Verify Docker API version:**
   ```bash
   docker version
   
   # Set specific API version if needed
   echo "DOCKER_API_VERSION=1.40" | sudo tee -a /etc/glinrdock/glinrdock.conf
   ```

3. **Restart GlinrDock service:**
   ```bash
   sudo systemctl restart glinrdock
   ```

### Cannot Create or Manage Containers

**Problem**: GlinrDock can see containers but cannot create or manage them.

**Solutions:**

1. **Check Docker daemon permissions:**
   ```bash
   # Ensure Docker daemon is accessible
   sudo -u glinrdock docker info
   ```

2. **Verify Docker image access:**
   ```bash
   # Test image pulling
   sudo -u glinrdock docker pull nginx:alpine
   ```

3. **Check for Docker daemon issues:**
   ```bash
   sudo systemctl status docker
   sudo journalctl -u docker.service
   ```

## Performance Issues

### Slow Response Times

**Problem**: GlinrDock web interface or API responds slowly.

**Diagnosis:**
```bash
# Check resource usage
ps aux | grep glinrdockd
top -p $(pgrep glinrdockd)

# Check disk I/O
iostat -x 1 5

# Test response times
time curl http://localhost:8080/health
```

**Solutions:**

1. **Insufficient resources:**
   ```bash
   # Check available memory
   free -h
   
   # Check disk space
   df -h
   
   # Consider upgrading system resources
   ```

2. **Database performance:**
   ```bash
   # Check database file size
   ls -lh /var/lib/glinrdock/data/glinrdock.db
   
   # Consider vacuum if very large (when service is stopped)
   sudo systemctl stop glinrdock
   sqlite3 /var/lib/glinrdock/data/glinrdock.db "VACUUM;"
   sudo systemctl start glinrdock
   ```

3. **Network latency to Docker:**
   ```bash
   # Test Docker API response time
   time docker ps
   
   # Consider local Docker socket if using TCP
   ```

### High Memory Usage

**Problem**: GlinrDock uses excessive memory.

**Solutions:**

1. **Check for memory leaks:**
   ```bash
   # Monitor over time
   watch 'ps aux | grep glinrdockd'
   ```

2. **Adjust log levels:**
   ```bash
   # Reduce logging
   sudo sed -i 's/LOG_LEVEL=debug/LOG_LEVEL=warn/' /etc/glinrdock/glinrdock.conf
   sudo systemctl restart glinrdock
   ```

3. **Restart service periodically:**
   ```bash
   # Add to cron for periodic restarts
   echo "0 2 * * 0 systemctl restart glinrdock" | sudo crontab -
   ```

## Database Issues

### Database Corruption

**Problem**: Database errors or corruption messages in logs.

**Solutions:**

1. **Stop service and check database:**
   ```bash
   sudo systemctl stop glinrdock
   
   # Check database integrity
   sqlite3 /var/lib/glinrdock/data/glinrdock.db "PRAGMA integrity_check;"
   ```

2. **Restore from backup:**
   ```bash
   # If you have a backup
   sudo cp /path/to/backup/glinrdock.db /var/lib/glinrdock/data/
   sudo chown glinrdock:glinrdock /var/lib/glinrdock/data/glinrdock.db
   ```

3. **Reset database (CAUTION: Data loss):**
   ```bash
   sudo systemctl stop glinrdock
   sudo rm /var/lib/glinrdock/data/glinrdock.db
   sudo systemctl start glinrdock
   # GlinrDock will create a new database
   ```

### Migration Failures

**Problem**: Database migration fails during startup.

**Solutions:**

1. **Check migration logs:**
   ```bash
   sudo journalctl -u glinrdock.service | grep -i migration
   ```

2. **Manual migration (if supported):**
   ```bash
   sudo systemctl stop glinrdock
   sudo -u glinrdock /usr/local/bin/glinrdockd --migrate-db
   sudo systemctl start glinrdock
   ```

## Log Analysis

### Reading GlinrDock Logs

**systemd installations:**
```bash
# Current logs
sudo journalctl -u glinrdock.service -f

# Recent logs
sudo journalctl -u glinrdock.service --since "1 hour ago"

# All logs
sudo journalctl -u glinrdock.service --no-pager
```

**File-based logging:**
```bash
# If configured with log file
sudo tail -f /var/lib/glinrdock/logs/glinrdock.log

# Search for errors
sudo grep -i error /var/lib/glinrdock/logs/glinrdock.log
```

### Common Log Messages

**"Permission denied" on Docker socket:**
- Add glinrdock user to docker group
- Check Docker socket permissions

**"Port already in use":**
- Change port in configuration
- Find and stop conflicting service

**"Database locked":**
- Stop service and check for orphaned processes
- Check file permissions on database

**"Failed to connect to Docker daemon":**
- Verify Docker is running
- Check DOCKER_HOST configuration

## Docker Compose Issues

### Service Won't Start

**Problem**: `docker-compose up` fails or services don't start.

**Solutions:**

1. **Check compose file syntax:**
   ```bash
   docker-compose config
   ```

2. **Verify image availability:**
   ```bash
   docker pull ghcr.io/glincker/glinrdock:latest
   ```

3. **Check environment variables:**
   ```bash
   # Verify .env file
   cat .env
   
   # Check for missing ADMIN_TOKEN
   grep ADMIN_TOKEN .env
   ```

4. **Volume mount issues:**
   ```bash
   # Check Docker socket accessibility
   ls -la /var/run/docker.sock
   
   # Ensure Docker is running
   docker info
   ```

### Cannot Access Through Docker

**Problem**: Cannot access GlinrDock running in Docker container.

**Solutions:**

1. **Check port mapping:**
   ```bash
   docker-compose ps
   # Should show: 0.0.0.0:8080->8080/tcp
   ```

2. **Test container health:**
   ```bash
   docker-compose exec glinrdock curl localhost:8080/health
   ```

3. **Check container logs:**
   ```bash
   docker-compose logs glinrdock
   ```

## Getting Help

### Before Seeking Help

1. **Check logs** for specific error messages
2. **Verify configuration** files and permissions
3. **Test basic connectivity** (curl commands)
4. **Review recent changes** to system or configuration

### Information to Include

When reporting issues, include:

1. **System information:**
   ```bash
   uname -a
   cat /etc/os-release
   docker --version
   glinrdockd --version
   ```

2. **Configuration (sanitized):**
   ```bash
   # Remove sensitive values like tokens
   sudo grep -v "TOKEN\|SECRET" /etc/glinrdock/glinrdock.conf
   ```

3. **Error logs:**
   ```bash
   sudo journalctl -u glinrdock.service --since "1 hour ago" --no-pager
   ```

4. **Network and permissions:**
   ```bash
   sudo netstat -tlnp | grep :8080
   ls -la /var/lib/glinrdock/
   id glinrdock
   ```

### Support Channels

- **GitHub Issues**: [Report bugs and issues](https://github.com/GLINCKER/glinrdock-release/issues)
- **Documentation**: [Browse documentation](https://github.com/GLINCKER/glinrdock-release/tree/main/docs)
- **Security Issues**: security@glinr.dev

## Emergency Recovery

### Complete System Reset

**CAUTION: This will delete all GlinrDock data**

```bash
# Stop service
sudo systemctl stop glinrdock.service

# Remove data (CAUTION: Data loss!)
sudo rm -rf /var/lib/glinrdock/data/*

# Reset configuration to defaults
sudo cp /etc/glinrdock/glinrdock.conf /etc/glinrdock/glinrdock.conf.backup
sudo rm /etc/glinrdock/glinrdock.conf

# Re-run installation
curl -fsSL https://github.com/GLINCKER/glinrdock-release/releases/latest/download/install.sh | sudo bash
```

### Service Recovery

**If service is completely broken:**

```bash
# Stop everything
sudo systemctl stop glinrdock.service
sudo pkill -f glinrdockd

# Reinstall service
sudo systemctl disable glinrdock.service
sudo rm /etc/systemd/system/glinrdock.service
sudo systemctl daemon-reload

# Re-run installation script
curl -fsSL https://github.com/GLINCKER/glinrdock-release/releases/latest/download/install.sh | sudo bash
```

Remember to restore your data and configuration backups after emergency recovery procedures.