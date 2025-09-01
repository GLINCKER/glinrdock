# Frequently Asked Questions

## General Questions

### What is GlinrDock?

GlinrDock is a lightweight container management platform that provides a web-based interface for managing Docker containers, projects, and deployments. It's designed for production environments with enterprise-grade security features.

### How is GlinrDock different from other container management tools?

GlinrDock focuses on:
- **Lightweight architecture** - minimal resource footprint
- **Security-first design** - built-in RBAC, audit logging, and secure defaults
- **Simple deployment** - single binary with no external dependencies
- **Fast performance** - optimized for speed with sub-100ms response times

### Is GlinrDock open source?

The main source code is maintained in a private repository. This repository contains binary distributions, documentation, and installation scripts under the MIT license.

## Installation Questions

### What platforms are supported?

GlinrDock supports:
- **Linux**: x86_64, ARM64
- **macOS**: x86_64 (Intel), ARM64 (Apple Silicon)

All binaries are statically linked and have no external dependencies.

### What are the system requirements?

**Minimum requirements:**
- 512MB RAM
- 1GB storage
- Docker Engine 20.10+
- Linux kernel 3.10+ or macOS 10.15+

**Recommended for production:**
- 2GB+ RAM
- 10GB+ storage
- Dedicated server or VM

### How do I install GlinrDock?

**Quick install (Linux with systemd):**
```bash
curl -fsSL https://github.com/GLINCKER/glinrdock-release/releases/latest/download/install.sh | sudo bash
```

**Docker Compose:**
```bash
curl -fsSL https://raw.githubusercontent.com/GLINCKER/glinrdock-release/main/deploy/docker-compose.yml -o docker-compose.yml
docker-compose up -d
```

See the [Installation Guide](INSTALL.md) for detailed instructions.

### Can I install GlinrDock without root access?

Yes, you can install GlinrDock as a regular user:
1. Download and extract the binary to a directory in your PATH
2. Create a data directory in your home directory
3. Run GlinrDock manually or with user systemd services

For rootless Docker integration, see [rootless Docker setup](https://docs.docker.com/engine/security/rootless/).

## Configuration Questions

### Where is the configuration stored?

Configuration can be set via:
- **Environment variables** (recommended for containers)
- **Configuration file** at `/etc/glinrdock/glinrdock.conf`
- **Command-line flags**

See the [Configuration Guide](CONFIG.md) for details.

### How do I find my admin token?

**For systemd installations:**
```bash
sudo grep ADMIN_TOKEN /etc/glinrdock/glinrdock.conf
```

**For Docker Compose:**
```bash
grep ADMIN_TOKEN .env
# Or check container logs
docker-compose logs glinrdock | grep "Admin token"
```

### How do I change the port?

Set the bind address in your configuration:
```bash
# Environment variable
GLINRDOCK_BIND_ADDR=0.0.0.0:8081

# Or configuration file
echo "GLINRDOCK_BIND_ADDR=0.0.0.0:8081" | sudo tee -a /etc/glinrdock/glinrdock.conf

# Restart service
sudo systemctl restart glinrdock
```

### How do I enable HTTPS/TLS?

**Using reverse proxy (recommended):**
Set up nginx or Caddy with TLS termination. See [CONFIG.md](CONFIG.md) for examples.

**Direct TLS (if supported):**
```bash
TLS_ENABLED=true
TLS_CERT_FILE=/path/to/certificate.crt
TLS_KEY_FILE=/path/to/private.key
GLINRDOCK_BIND_ADDR=0.0.0.0:8443
```

## Usage Questions

### How do I access the web interface?

After installation, open your browser to:
- **Default**: http://localhost:8080
- **Custom port**: http://localhost:YOUR_PORT
- **Remote access**: http://your-server-ip:8080

Login with your admin token.

### Can I use GlinrDock with existing Docker containers?

Yes, GlinrDock can manage existing Docker containers. It will detect and display running containers when connected to the Docker daemon.

### Does GlinrDock support Docker Compose files?

GlinrDock can import Docker Compose files and convert them to native project configurations. Some Compose-specific features may not be fully supported.

### How do I create multiple projects?

In the web interface:
1. Click "Projects" in the navigation
2. Click "New Project"
3. Fill in project details
4. Add services to the project

Projects help organize related containers and services.

### Can I use private Docker registries?

Yes, GlinrDock supports authentication with private Docker registries. Configure registry credentials in the project or service settings.

## Docker Integration Questions

### Does GlinrDock require special Docker configuration?

No special configuration is required. GlinrDock works with standard Docker installations. Ensure the GlinrDock user has access to the Docker socket:

```bash
sudo usermod -aG docker glinrdock
```

### Can I use GlinrDock with Docker Swarm?

Current versions focus on single-node Docker management. Docker Swarm support may be added in future releases.

### Does GlinrDock work with rootless Docker?

Yes, GlinrDock can work with rootless Docker installations. Configure the Docker socket path appropriately:
```bash
DOCKER_HOST=unix:///run/user/$(id -u)/docker.sock
```

### How does GlinrDock handle Docker networks?

GlinrDock can create and manage Docker networks for projects. Services within the same project can communicate using service names.

## Security Questions

### Is GlinrDock secure for production use?

Yes, GlinrDock is designed with security as a priority:
- **Authentication required** for all API access
- **RBAC system** for granular permissions
- **Audit logging** for all operations
- **Rate limiting** to prevent abuse
- **Security defaults** for all configurations

See the [Security Guide](SECURITY.md) for best practices.

### How do I secure the admin token?

**Generate a strong token:**
```bash
openssl rand -hex 32
```

**Store securely:**
- Use environment variables in production
- Set proper file permissions (640) for config files
- Rotate tokens regularly

### Can I use GlinrDock behind a firewall?

Yes, GlinrDock works well behind firewalls:
- Bind to localhost and use a reverse proxy
- Configure firewall rules to allow specific IPs
- Use VPN access for remote management

### How do I enable audit logging?

Audit logging is enabled by default. Configure log level and file location:
```bash
GLINRDOCK_LOG_LEVEL=info
GLINRDOCK_LOG_FILE=/var/lib/glinrdock/logs/glinrdock.log
```

## Performance Questions

### How much resources does GlinrDock use?

**Typical resource usage:**
- **Memory**: 50-200MB depending on workload
- **CPU**: Low usage, spikes during API operations
- **Storage**: Minimal, mainly for database and logs

### Can GlinrDock handle many containers?

GlinrDock is optimized for performance and can manage hundreds of containers efficiently. Performance depends on:
- Available system resources
- Docker daemon performance
- Network latency

### How do I optimize GlinrDock performance?

1. **Adequate resources**: Ensure sufficient RAM and CPU
2. **SSD storage**: Use SSD for database and logs
3. **Network**: Low-latency network to Docker daemon
4. **Tuning**: Adjust timeouts and rate limits in configuration

## Backup and Recovery Questions

### How do I backup GlinrDock data?

**Data directory backup:**
```bash
sudo systemctl stop glinrdock
sudo tar -czf glinrdock-backup-$(date +%Y%m%d).tar.gz -C /var/lib/glinrdock data
sudo systemctl start glinrdock
```

**Configuration backup:**
```bash
sudo cp /etc/glinrdock/glinrdock.conf /tmp/glinrdock-config-backup.conf
```

### How do I restore from backup?

```bash
sudo systemctl stop glinrdock
sudo rm -rf /var/lib/glinrdock/data
sudo tar -xzf glinrdock-backup-YYYYMMDD.tar.gz -C /var/lib/glinrdock/
sudo chown -R glinrdock:glinrdock /var/lib/glinrdock
sudo systemctl start glinrdock
```

### Are automatic backups supported?

Yes, GlinrDock can be configured for automatic database backups:
```bash
DB_BACKUP_ENABLED=true
DB_BACKUP_INTERVAL=6h
```

## Upgrade Questions

### How do I upgrade GlinrDock?

**Using install script:**
```bash
curl -fsSL https://github.com/GLINCKER/glinrdock-release/releases/latest/download/install.sh | sudo bash
```

**Manual upgrade:**
1. Stop the service
2. Backup data and configuration
3. Download new binary
4. Replace old binary
5. Start service

See the [Upgrade Guide](UPGRADE.md) for detailed instructions.

### Will upgrades break my existing containers?

No, GlinrDock upgrades do not affect your running containers. GlinrDock manages containers through the Docker API without modifying container configurations directly.

### How do I rollback an upgrade?

1. Stop GlinrDock service
2. Restore previous binary
3. Restore configuration backup if needed
4. Restore data backup if required
5. Start service

Keep binary backups for easy rollbacks.

## Troubleshooting Questions

### GlinrDock won't start - what should I check?

1. **Check logs:**
   ```bash
   sudo journalctl -u glinrdock.service -f
   ```

2. **Verify configuration:**
   ```bash
   sudo cat /etc/glinrdock/glinrdock.conf
   ```

3. **Check port availability:**
   ```bash
   sudo netstat -tlnp | grep :8080
   ```

4. **Verify Docker access:**
   ```bash
   sudo -u glinrdock docker ps
   ```

### I can't access the web interface

1. **Check service status:**
   ```bash
   sudo systemctl status glinrdock
   ```

2. **Test local access:**
   ```bash
   curl http://localhost:8080/health
   ```

3. **Check firewall:**
   ```bash
   sudo ufw status
   sudo iptables -L
   ```

4. **Verify bind address:**
   Check if GlinrDock is bound to correct interface.

### API requests return "Unauthorized"

1. **Verify admin token:**
   ```bash
   sudo grep ADMIN_TOKEN /etc/glinrdock/glinrdock.conf
   ```

2. **Test with correct token:**
   ```bash
   curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:8080/v1/info
   ```

3. **Check token format:**
   Ensure token is properly formatted and has sufficient length.

### Docker containers don't appear in GlinrDock

1. **Check Docker socket permissions:**
   ```bash
   ls -la /var/run/docker.sock
   sudo usermod -aG docker glinrdock
   ```

2. **Test Docker access:**
   ```bash
   sudo -u glinrdock docker ps
   ```

3. **Restart GlinrDock service:**
   ```bash
   sudo systemctl restart glinrdock
   ```

## License and Support Questions

### What license does GlinrDock use?

The binary distributions and documentation in this repository are licensed under the MIT License. The main source code is maintained in a private repository.

### How do I get support?

**Community support:**
- [GitHub Issues](https://github.com/GLINCKER/glinrdock-release/issues) for bug reports
- [Documentation](https://github.com/GLINCKER/glinrdock-release/tree/main/docs) for guides and references

**Security issues:**
- Email: security@glinr.dev
- See [Security Policy](SECURITY.md) for details

### Is commercial support available?

Contact us at support@glincker.com for enterprise support options, including:
- Dedicated support channels
- Priority issue resolution
- Custom feature development
- Training and consulting

### Can I contribute to GlinrDock?

While the main source code is private, you can contribute to:
- Documentation improvements
- Installation scripts
- Docker configurations
- Bug reports and feature requests

Submit pull requests to this repository for documentation and packaging improvements.

---

**Don't see your question here?** Check the [Troubleshooting Guide](TROUBLESHOOTING.md) or [open an issue](https://github.com/GLINCKER/glinrdock-release/issues) on GitHub.