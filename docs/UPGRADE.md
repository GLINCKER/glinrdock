# Upgrade Guide

This guide covers upgrading GlinrDock to newer versions with rollback procedures.

## Before Upgrading

### Check Current Version

```bash
# Check running version
glinrdockd --version

# Or via API
curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:8080/v1/info
```

### Review Release Notes

Check the [release notes](https://github.com/GLINCKER/glinrdock-release/releases) for:
- Breaking changes
- New features
- Configuration changes
- Migration requirements

### Backup Data

```bash
# Stop service
sudo systemctl stop glinrdock

# Backup data directory
sudo tar -czf /tmp/glinrdock-backup-$(date +%Y%m%d).tar.gz -C /var/lib/glinrdock data

# Backup configuration
sudo cp /etc/glinrdock/glinrdock.conf /tmp/glinrdock-config-backup.conf
```

## Upgrade Methods

### Method 1: In-Place Upgrade (Recommended)

For systemd installations using the install script.

```bash
# Download new binary
PLATFORM="linux_amd64"  # Adjust for your platform
VERSION="v1.2.0"         # Target version

curl -LO "https://github.com/GLINCKER/glinrdock-release/releases/download/${VERSION}/glinrdockd_${PLATFORM}.tar.gz"
curl -LO "https://github.com/GLINCKER/glinrdock-release/releases/download/${VERSION}/glinrdockd_${PLATFORM}.tar.gz.sha256"

# Verify checksum
sha256sum -c "glinrdockd_${PLATFORM}.tar.gz.sha256"

# Extract binary
tar -xzf "glinrdockd_${PLATFORM}.tar.gz"

# Stop service
sudo systemctl stop glinrdock

# Backup current binary
sudo cp /usr/local/bin/glinrdockd /usr/local/bin/glinrdockd.backup

# Install new binary
sudo cp glinrdockd_linux_amd64 /usr/local/bin/glinrdockd
sudo chmod +x /usr/local/bin/glinrdockd

# Start service
sudo systemctl start glinrdock

# Verify upgrade
sudo systemctl status glinrdock
glinrdockd --version
```

### Method 2: Docker Compose Upgrade

```bash
# Update compose file to new version
curl -fsSL https://raw.githubusercontent.com/GLINCKER/glinrdock-release/main/deploy/docker-compose.yml -o docker-compose.yml

# Pull new images
docker-compose pull

# Restart with new image
docker-compose up -d

# Verify
docker-compose ps
```

### Method 3: Install Script Re-run

```bash
# Run install script with new version
curl -fsSL https://github.com/GLINCKER/glinrdock-release/releases/latest/download/install.sh | sudo bash
```

**Note:** This preserves existing configuration and data.

## Zero-Downtime Upgrade

For production environments requiring continuous availability.

### Setup Load Balancer

```bash
# Example with HAProxy configuration
backend glinrdock
    balance roundrobin
    server node1 127.0.0.1:8080 check
    server node2 127.0.0.1:8081 check
```

### Rolling Upgrade Procedure

1. **Start second instance on different port:**
   ```bash
   # Copy configuration with different port
   sudo cp /etc/glinrdock/glinrdock.conf /etc/glinrdock/glinrdock-new.conf
   sudo sed -i 's/8080/8081/g' /etc/glinrdock/glinrdock-new.conf
   
   # Start new version
   sudo GLINRDOCK_CONFIG=/etc/glinrdock/glinrdock-new.conf /usr/local/bin/glinrdockd-new &
   ```

2. **Health check new instance:**
   ```bash
   curl http://localhost:8081/health
   ```

3. **Update load balancer to drain traffic from old instance**

4. **Stop old instance and promote new one:**
   ```bash
   sudo systemctl stop glinrdock
   sudo systemctl start glinrdock
   ```

## Version-Specific Upgrades

### v1.0.x to v1.1.x

No breaking changes. Standard upgrade procedure applies.

### v1.1.x to v1.2.x

**Configuration changes:**
- New environment variable `WEBHOOK_SECRET` for webhook validation
- Database migration runs automatically on first start

**Upgrade steps:**
1. Follow standard upgrade procedure
2. Add `WEBHOOK_SECRET` to configuration if using webhooks:
   ```bash
   echo "WEBHOOK_SECRET=$(openssl rand -hex 32)" | sudo tee -a /etc/glinrdock/glinrdock.conf
   ```

### v1.2.x to v2.0.x

**Breaking changes:**
- API endpoint paths changed from `/api/v1/` to `/v1/`
- Configuration file format updated

**Upgrade steps:**
1. Backup current configuration
2. Follow migration guide in release notes
3. Update client applications for new API paths

## Post-Upgrade Verification

### Service Health

```bash
# Check service status
sudo systemctl status glinrdock

# Check logs for errors
sudo journalctl -u glinrdock.service -f

# Test API endpoint
curl http://localhost:8080/health
```

### Data Integrity

```bash
# Login to dashboard and verify:
# - Projects list loads
# - Container status displays
# - Logs are accessible
# - Settings are preserved
```

### Performance Baseline

```bash
# Check memory usage
ps aux | grep glinrdockd

# Check response time
time curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:8080/v1/projects
```

## Rollback Procedures

### Rollback Binary

```bash
# Stop current service
sudo systemctl stop glinrdock

# Restore backup binary
sudo cp /usr/local/bin/glinrdockd.backup /usr/local/bin/glinrdockd

# Start service
sudo systemctl start glinrdock

# Verify rollback
glinrdockd --version
```

### Rollback Data

```bash
# Stop service
sudo systemctl stop glinrdock

# Restore data backup
sudo rm -rf /var/lib/glinrdock/data
sudo tar -xzf /tmp/glinrdock-backup-YYYYMMDD.tar.gz -C /var/lib/glinrdock/

# Fix permissions
sudo chown -R glinrdock:glinrdock /var/lib/glinrdock

# Start service
sudo systemctl start glinrdock
```

### Rollback Configuration

```bash
# Restore configuration backup
sudo cp /tmp/glinrdock-config-backup.conf /etc/glinrdock/glinrdock.conf

# Restart service
sudo systemctl restart glinrdock
```

### Docker Rollback

```bash
# Use specific version tag
docker-compose down
sed -i 's/:latest/:v1.0.0/g' docker-compose.yml
docker-compose up -d
```

## Automated Upgrades

### Systemd Timer for Updates

```bash
# Create update script
sudo tee /usr/local/bin/glinrdock-update.sh > /dev/null <<'EOF'
#!/bin/bash
set -e

# Check for new releases
LATEST=$(curl -s https://api.github.com/repos/GLINCKER/glinrdock-release/releases/latest | grep tag_name | cut -d'"' -f4)
CURRENT=$(glinrdockd --version | grep -o 'v[0-9.]*')

if [ "$LATEST" != "$CURRENT" ]; then
    echo "Updating from $CURRENT to $LATEST"
    curl -fsSL https://github.com/GLINCKER/glinrdock-release/releases/latest/download/install.sh | bash
else
    echo "Already up to date: $CURRENT"
fi
EOF

sudo chmod +x /usr/local/bin/glinrdock-update.sh

# Create systemd timer
sudo tee /etc/systemd/system/glinrdock-update.timer > /dev/null <<'EOF'
[Unit]
Description=GlinrDock Update Check
Requires=glinrdock-update.service

[Timer]
OnCalendar=weekly
Persistent=true

[Install]
WantedBy=timers.target
EOF

sudo tee /etc/systemd/system/glinrdock-update.service > /dev/null <<'EOF'
[Unit]
Description=GlinrDock Update Service
Type=oneshot

[Service]
ExecStart=/usr/local/bin/glinrdock-update.sh
EOF

# Enable timer
sudo systemctl daemon-reload
sudo systemctl enable glinrdock-update.timer
sudo systemctl start glinrdock-update.timer
```

## Troubleshooting Upgrades

### Common Issues

**Service fails to start after upgrade:**
```bash
# Check systemd logs
sudo journalctl -u glinrdock.service --no-pager

# Check configuration syntax
sudo /usr/local/bin/glinrdockd --config-check
```

**Database migration fails:**
```bash
# Check data directory permissions
sudo ls -la /var/lib/glinrdock/data/

# Manual migration (if supported)
sudo -u glinrdock /usr/local/bin/glinrdockd --migrate-db
```

**Performance regression:**
```bash
# Compare resource usage
# Before upgrade: note memory/CPU usage
# After upgrade: check for significant changes

# Check for memory leaks
watch 'ps aux | grep glinrdockd'
```

### Recovery Steps

1. **Immediate rollback** if critical issues occur
2. **Check logs** for specific error messages
3. **Review configuration** for deprecated options
4. **Test in staging** environment first for major upgrades
5. **Contact support** if rollback doesn't resolve issues

## Best Practices

- **Test upgrades** in non-production environment first
- **Schedule maintenance windows** for major version upgrades
- **Monitor services** closely after upgrades
- **Keep multiple backup copies** before major changes
- **Document custom configurations** for easier rollbacks
- **Subscribe to release notifications** for security updates

## Support

For upgrade-related issues:
- Check [troubleshooting guide](TROUBLESHOOTING.md)
- Review [FAQ](FAQ.md) for common questions
- Report issues on [GitHub](https://github.com/GLINCKER/glinrdock-release/issues)