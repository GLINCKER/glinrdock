# Uninstall Guide

Complete instructions for removing GlinrDock from your system.

## Before Uninstalling

### Backup Your Data (Optional)

If you want to preserve your projects and configurations:

**Linux Installation**:
```bash
sudo tar czf glinrdock-backup-$(date +%Y%m%d).tar.gz -C /var/lib/glinrdock .
```

**Docker Installation**:
```bash
docker run --rm -v glinrdock_data:/data -v $(pwd):/backup alpine tar czf /backup/glinrdock-backup-$(date +%Y%m%d).tar.gz -C /data .
```

### Export Projects

Use the web interface to export your Docker Compose files:
1. Go to each project
2. Click **Export** → **Docker Compose**
3. Save the files for future use

## Uninstall Methods

### Method 1: Automated Uninstall Script

Download and run the uninstall script:
```bash
curl -fsSL https://github.com/GLINCKER/glinrdock-release/releases/latest/download/uninstall.sh | sudo bash
```

This will remove:
- GlinrDock binary
- systemd service
- Configuration files
- Data directory
- System user account

### Method 2: Manual Uninstall (Linux)

1. **Stop the service**:
```bash
sudo systemctl stop glinrdockd
sudo systemctl disable glinrdockd
```

2. **Remove systemd service**:
```bash
sudo rm -f /etc/systemd/system/glinrdockd.service
sudo systemctl daemon-reload
```

3. **Remove binary**:
```bash
sudo rm -f /usr/local/bin/glinrdockd
```

4. **Remove configuration and data**:
```bash
sudo rm -rf /etc/glinrdock
sudo rm -rf /var/lib/glinrdock
```

5. **Remove system user** (optional):
```bash
sudo userdel glinrdock
```

6. **Remove logs** (optional):
```bash
sudo journalctl --vacuum-time=1d
```

### Method 3: Docker Uninstall

**Docker Compose**:
```bash
# Stop and remove containers
docker-compose down

# Remove volumes (WARNING: This deletes all data)
docker-compose down -v

# Remove downloaded files
rm docker-compose.yml
```

**Manual Docker**:
```bash
# Stop and remove container
docker stop glinrdock
docker rm glinrdock

# Remove volume (WARNING: This deletes all data)
docker volume rm glinrdock_data

# Remove image (optional)
docker rmi ghcr.io/glincker/glinrdock:latest
```

### Method 4: Package Manager Uninstall

**RPM-based systems**:
```bash
sudo rpm -e glinrdockd
```

**DEB-based systems**:
```bash
sudo dpkg -r glinrdockd
```

## Clean Up Remaining Files

After uninstalling, you may want to remove additional files:

### Log Files
```bash
# systemd logs
sudo journalctl --vacuum-time=1d

# Application logs (if any)
sudo rm -rf /var/log/glinrdock
```

### Firewall Rules
```bash
# UFW
sudo ufw delete allow 8080/tcp

# firewalld
sudo firewall-cmd --permanent --remove-port=8080/tcp
sudo firewall-cmd --reload
```

### Docker Networks (Docker installation)
```bash
# List networks
docker network ls | grep glinrdock

# Remove custom networks
docker network rm glinrdock_default
```

## Verification

Ensure GlinrDock is completely removed:

1. **Check process**:
```bash
ps aux | grep glinrdock
```

2. **Check ports**:
```bash
netstat -tlnp | grep 8080
```

3. **Check systemd services**:
```bash
systemctl list-units | grep glinrdock
```

4. **Check Docker containers**:
```bash
docker ps -a | grep glinrdock
```

## Troubleshooting Uninstall

### Service Won't Stop
```bash
# Force kill the process
sudo pkill -f glinrdockd

# Force stop systemd service
sudo systemctl kill glinrdockd
```

### Permission Denied Errors
```bash
# Some files may be owned by the glinrdock user
sudo rm -rf /var/lib/glinrdock
sudo rm -rf /etc/glinrdock
```

### Docker Container Won't Remove
```bash
# Force remove container
docker rm -f glinrdock

# Force remove volume
docker volume rm -f glinrdock_data
```

### Partial Package Removal
```bash
# Force remove package (RPM)
sudo rpm -e --noscripts glinrdockd

# Force remove package (DEB)
sudo dpkg -r --force-remove-reinstreq glinrdockd
```

## Reinstallation

If you want to reinstall GlinrDock later:

1. **Follow installation guide**: [Linux](INSTALL_LINUX.md) or [Docker](INSTALL_DOCKER.md)
2. **Restore backup** (if created):
```bash
# Linux
sudo tar xzf glinrdock-backup-*.tar.gz -C /var/lib/glinrdock

# Docker
docker run --rm -v glinrdock_data:/data -v $(pwd):/backup alpine tar xzf /backup/glinrdock-backup-*.tar.gz -C /data
```

## Support

If you encounter issues during uninstall:
- Check our [Troubleshooting Guide](TROUBLESHOOTING.md)
- Report issues at [GitHub Issues](https://github.com/GLINCKER/glinrdock-release/issues)

## Feedback

We're sorry to see you go! If you have feedback about GlinrDock, please share it in our [GitHub Discussions](https://github.com/GLINCKER/glinrdock-release/discussions).