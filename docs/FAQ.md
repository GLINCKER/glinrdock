# Frequently Asked Questions

## General Questions

### What is GlinrDock?

GlinrDock is a lightweight container management platform that provides a web interface for managing Docker containers and Docker Compose projects. It offers team collaboration features, monitoring, and deployment capabilities.

### How is GlinrDock different from other container management tools?

- **Lightweight**: Minimal resource usage compared to Kubernetes
- **Docker Compose compatible**: Import existing compose files
- **Team-focused**: Built-in multi-user support and RBAC
- **Easy setup**: 30-second installation process
- **Production-ready**: Zero-downtime deployments and monitoring

### Is GlinrDock free?

GlinrDock offers:
- **Free tier**: Personal projects and development use
- **Commercial licenses**: For production and enterprise use
- See our pricing at https://glincker.com/pricing

### Where is the source code?

The source code is maintained in a private repository. This public repository contains only binary distributions, documentation, and installation scripts.

## Installation Questions

### What are the system requirements?

**Minimum**:
- Linux kernel 3.10+ or macOS 10.15+
- Docker Engine 20.10+
- 512MB RAM
- 1GB disk space

**Recommended**:
- 2GB+ RAM
- 10GB+ disk space
- SSD storage
- systemd (Linux)

### Can I run GlinrDock without Docker?

No, GlinrDock requires Docker Engine to manage containers. However, you can run GlinrDock itself as:
- Native binary (recommended for Linux)
- Docker container (easier deployment)

### How do I install on ARM64/Apple Silicon?

Use the automated installer which detects your architecture:
```bash
curl -fsSL https://github.com/GLINCKER/glinrdock-release/releases/latest/download/install.sh | sudo bash
```

Or download the appropriate binary manually:
- `glinrdockd_darwin_arm64.tar.gz` for Apple Silicon
- `glinrdockd_linux_arm64.tar.gz` for ARM64 Linux

### Can I install without sudo/root access?

The automated installer requires root privileges to:
- Install to `/usr/local/bin`
- Create systemd service
- Set up system user

For non-root installation:
1. Download binary manually
2. Run in user space
3. Use Docker installation method

## Configuration Questions

### How do I change the default port?

**Linux installation**:
Edit `/etc/glinrdock/config.toml`:
```toml
[server]
bind_addr = "127.0.0.1:9090"
```

**Docker installation**:
```bash
docker run -p 9090:8080 ...
```

### Where are my projects and data stored?

**Linux installation**:
- Configuration: `/etc/glinrdock/`
- Data: `/var/lib/glinrdock/`
- Logs: `journalctl -u glinrdockd`

**Docker installation**:
- Data volume: `glinrdock_data`
- Container logs: `docker logs glinrdock`

### How do I backup my data?

**Linux**:
```bash
sudo tar czf glinrdock-backup.tar.gz -C /var/lib/glinrdock .
```

**Docker**:
```bash
docker run --rm -v glinrdock_data:/data -v $(pwd):/backup alpine tar czf /backup/glinrdock-backup.tar.gz -C /data .
```

### How do I reset the admin password/token?

**Generate new token**:
```bash
openssl rand -hex 32
```

**Linux installation**:
```bash
sudo sed -i 's/admin_token = .*/admin_token = "NEW_TOKEN_HERE"/' /etc/glinrdock/config.toml
sudo systemctl restart glinrdockd
```

**Docker installation**:
```bash
docker run -e GLINRDOCK_ADMIN_TOKEN="NEW_TOKEN_HERE" ...
```

## Usage Questions

### Can I import existing Docker Compose files?

Yes! GlinrDock supports importing Docker Compose files:
1. Go to **Projects** → **Import**
2. Upload your `docker-compose.yml` file
3. Review and deploy

### How do I manage multiple environments?

Use GlinrDock's project-based organization:
- Create separate projects for dev/staging/prod
- Use environment variables for configuration
- Deploy to different Docker networks

### Can I use private Docker registries?

Yes, configure registry credentials in:
- **Settings** → **Registries**
- Add registry URL, username, and password
- GlinrDock will authenticate automatically

### Does GlinrDock support Docker Swarm or Kubernetes?

Currently, GlinrDock focuses on single-node Docker and Docker Compose deployments. Swarm and Kubernetes support are planned for future releases.

## Troubleshooting Questions

### GlinrDock won't start - "port already in use"

Check what's using port 8080:
```bash
sudo netstat -tlnp | grep 8080
```

Solutions:
- Kill the conflicting process
- Change GlinrDock's port (see configuration above)
- Use a different port: `-p 8081:8080` (Docker)

### Can't connect to Docker daemon

**Check Docker is running**:
```bash
sudo systemctl status docker
sudo systemctl start docker
```

**Check permissions**:
```bash
# Add user to docker group
sudo usermod -aG docker $USER
# Log out and back in

# Or for GlinrDock user (Linux installation)
sudo usermod -aG docker glinrdock
sudo systemctl restart glinrdockd
```

### Web interface shows "Unauthorized"

**Check admin token**:
```bash
# Linux
sudo grep admin_token /etc/glinrdock/config.toml

# Docker
docker logs glinrdock | grep "Admin token"
```

**Clear browser cache**:
- Hard refresh (Ctrl+F5)
- Clear browser data
- Try incognito/private mode

### How do I enable debug logging?

**Linux installation**:
Edit `/etc/glinrdock/config.toml`:
```toml
[logging]
level = "debug"
```

**Docker installation**:
```bash
docker run -e GLINRDOCK_LOG_LEVEL="debug" ...
```

View logs:
```bash
# Linux
sudo journalctl -u glinrdockd -f

# Docker  
docker logs -f glinrdock
```

## Performance Questions

### How many containers can GlinrDock manage?

GlinrDock can manage hundreds of containers, limited primarily by:
- Available system resources (RAM, CPU)
- Docker daemon performance
- Network and storage I/O

### Does GlinrDock affect container performance?

No, GlinrDock acts as a management layer and doesn't impact container runtime performance. It uses the Docker API for all operations.

### How much memory does GlinrDock use?

- Binary installation: 50-100MB
- Docker installation: 100-200MB (including base image)
- Memory usage scales with number of managed containers

## Security Questions

### Is it safe to expose GlinrDock to the internet?

**Not recommended without proper security measures**:
- Use HTTPS with valid certificates
- Implement strong authentication
- Use firewall and access controls
- Consider VPN access

**Better approach**:
- Keep on private network
- Use VPN or SSH tunneling for remote access
- Implement reverse proxy with authentication

### How do I secure the Docker socket?

The Docker socket provides root-equivalent access. Security options:

1. **Use TCP with TLS** (advanced):
```bash
dockerd --host=tcp://127.0.0.1:2376 --tls --tlscert=... --tlskey=...
```

2. **Restrict socket permissions**:
```bash
sudo chmod 660 /var/run/docker.sock
```

3. **Use Docker-in-Docker** (more complex setup)

## Support Questions

### How do I get help?

1. **Documentation**: Check our comprehensive docs
2. **GitHub Issues**: Report bugs or feature requests
3. **Community**: GitHub Discussions for questions
4. **Enterprise**: Contact support@glincker.com

### How do I report a security issue?

**DO NOT** use public GitHub issues for security vulnerabilities.

Email: **security@glincker.com**

See our [Security Policy](SECURITY.md) for details.

### How often is GlinrDock updated?

- **Patch releases**: Monthly (bug fixes)
- **Minor releases**: Quarterly (new features)  
- **Major releases**: Yearly (breaking changes)
- **Security updates**: As needed

### Can I contribute to GlinrDock?

While the source code is private, you can contribute by:
- Reporting issues and feature requests
- Improving documentation
- Sharing usage examples
- Providing feedback

## Migration Questions

### How do I migrate from Portainer?

1. Export your Docker Compose files from Portainer
2. Install GlinrDock
3. Import compose files into GlinrDock projects
4. Verify deployments and remove Portainer

### Can I run GlinrDock alongside other management tools?

Yes, GlinrDock uses standard Docker APIs and can coexist with other tools. However, avoid simultaneous management of the same containers to prevent conflicts.

### How do I upgrade GlinrDock?

**Linux installation**:
```bash
curl -fsSL https://github.com/GLINCKER/glinrdock-release/releases/latest/download/install.sh | sudo bash
```

**Docker installation**:
```bash
docker-compose pull
docker-compose up -d
```

Data and configuration are preserved during upgrades.

---

**Still have questions?** 
- Check our [Troubleshooting Guide](TROUBLESHOOTING.md)
- Ask in [GitHub Discussions](https://github.com/GLINCKER/glinrdock-release/discussions)
- Contact support@glincker.com