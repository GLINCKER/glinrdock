# Security Guide

This document outlines security practices, vulnerability reporting procedures, and supported versions for GlinrDock.

## Reporting Security Vulnerabilities

**Do not report security vulnerabilities through public GitHub issues.**

### Reporting Process

1. **Email**: Send vulnerability reports to security@glinr.dev
2. **Subject**: `[SECURITY] GlinrDock Vulnerability Report`
3. **Include**:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact assessment
   - Affected versions
   - Your contact information

### Response Timeline

- **Initial Response**: Within 24 hours
- **Triage**: Within 72 hours
- **Status Updates**: Weekly until resolved
- **Resolution**: Depends on severity (see below)

### Severity Levels

| Severity | Response Time | Public Disclosure |
|----------|---------------|-------------------|
| **Critical** | 24-48 hours | After fix release |
| **High** | 3-7 days | After fix release |
| **Medium** | 7-14 days | After fix release |
| **Low** | 14-30 days | After fix release |

## Supported Versions

We provide security updates for the following versions:

| Version | Supported | End of Life |
|---------|-----------|-------------|
| 2.0.x | ✅ Yes | TBD |
| 1.2.x | ✅ Yes | 6 months after 2.1.0 |
| 1.1.x | ❌ No | 2024-12-31 |
| 1.0.x | ❌ No | 2024-06-30 |
| < 1.0 | ❌ No | 2024-01-01 |

### Support Policy

- **Current major version**: Full security support
- **Previous major version**: Security updates for 12 months
- **Older versions**: No security updates (upgrade required)

## Security Features

### Authentication & Authorization
- **Admin token required** for all API access
- **Token-based authentication** with configurable expiration
- **Role-based access control** for multi-user environments
- **API rate limiting** to prevent abuse

### Network Security
- **TLS/HTTPS support** with automatic certificate management
- **Configurable bind addresses** to restrict network access
- **CORS protection** with allowlist configuration
- **Request validation** and input sanitization

### Container Security
- **Docker socket access control** with user permissions
- **Container isolation** using Docker security features
- **Resource limits** to prevent resource exhaustion
- **Image signature verification** (when configured)

### Data Protection
- **Local data storage** - no external data transmission
- **Encrypted configuration** for sensitive values
- **Secure token generation** using cryptographic randomness
- **Log sanitization** to prevent credential exposure

## Security Best Practices

### Installation Security

#### Verify Binary Integrity
```bash
# Always verify checksums
curl -LO https://github.com/GLINCKER/glinrdock-release/releases/latest/download/glinrdockd_linux_amd64.tar.gz.sha256
sha256sum -c glinrdockd_linux_amd64.tar.gz.sha256
```

#### Secure Installation
```bash
# Run install script securely
curl -fsSL https://github.com/GLINCKER/glinrdock-release/releases/latest/download/install.sh > install.sh
# Review script contents before execution
less install.sh
chmod +x install.sh
sudo ./install.sh
```

### Network Security

#### Restrict Access
```bash
# Bind to localhost only
GLINRDOCK_BIND_ADDR=127.0.0.1:8080

# Or use firewall rules
sudo ufw allow from 192.168.1.0/24 to any port 8080
sudo ufw deny 8080
```

#### Use Reverse Proxy
```nginx
# nginx configuration
server {
    listen 443 ssl;
    server_name glinrdock.example.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Authentication Security

#### Strong Admin Tokens
```bash
# Generate secure token
ADMIN_TOKEN=$(openssl rand -hex 32)

# Store securely
echo "ADMIN_TOKEN=$ADMIN_TOKEN" | sudo tee -a /etc/glinrdock/glinrdock.conf
sudo chmod 600 /etc/glinrdock/glinrdock.conf
```

#### Token Rotation
```bash
# Rotate admin token periodically
NEW_TOKEN=$(openssl rand -hex 32)
sudo sed -i "s/ADMIN_TOKEN=.*/ADMIN_TOKEN=$NEW_TOKEN/" /etc/glinrdock/glinrdock.conf
sudo systemctl restart glinrdock
```

### File System Security

#### Secure Permissions
```bash
# Data directory
sudo chown -R glinrdock:glinrdock /var/lib/glinrdock
sudo chmod 750 /var/lib/glinrdock

# Configuration files
sudo chown root:glinrdock /etc/glinrdock/glinrdock.conf
sudo chmod 640 /etc/glinrdock/glinrdock.conf

# Binary
sudo chown root:root /usr/local/bin/glinrdockd
sudo chmod 755 /usr/local/bin/glinrdockd
```

#### Log Security
```bash
# Secure log files
sudo chmod 640 /var/lib/glinrdock/logs/*.log
sudo chown glinrdock:adm /var/lib/glinrdock/logs/*.log
```

### Docker Security

#### Docker Socket Permissions
```bash
# Add glinrdock user to docker group
sudo usermod -aG docker glinrdock

# Verify permissions
sudo ls -la /var/run/docker.sock
```

#### Container Security
```bash
# Run containers as non-root when possible
# Use security options in container configurations
{
  "SecurityOpt": ["no-new-privileges:true"],
  "User": "1000:1000",
  "ReadonlyRootfs": true
}
```

## Configuration Security

### Environment Variables
```bash
# Secure configuration file
sudo tee /etc/glinrdock/glinrdock.conf > /dev/null <<EOF
# Bind configuration
GLINRDOCK_BIND_ADDR=127.0.0.1:8080

# Authentication
ADMIN_TOKEN=$(openssl rand -hex 32)

# Optional: Webhook validation
WEBHOOK_SECRET=$(openssl rand -hex 32)

# Docker settings
DOCKER_HOST=unix:///var/run/docker.sock
EOF

# Secure the file
sudo chown root:glinrdock /etc/glinrdock/glinrdock.conf
sudo chmod 640 /etc/glinrdock/glinrdock.conf
```

### TLS Configuration
```bash
# Enable TLS (when supported)
GLINRDOCK_TLS_CERT=/path/to/cert.pem
GLINRDOCK_TLS_KEY=/path/to/key.pem
GLINRDOCK_TLS_BIND_ADDR=0.0.0.0:8443
```

## Monitoring & Auditing

### Log Monitoring
```bash
# Monitor for authentication failures
sudo grep "authentication failed" /var/lib/glinrdock/logs/glinrdock.log

# Monitor for unusual API access
sudo grep "unauthorized" /var/lib/glinrdock/logs/glinrdock.log
```

### System Monitoring
```bash
# Monitor process and resource usage
ps aux | grep glinrdockd
netstat -tlnp | grep :8080

# Check for unexpected network connections
sudo ss -tlnp | grep glinrdockd
```

### Audit Logging
Enable comprehensive audit logging in configuration:
```bash
GLINRDOCK_AUDIT_LOG=true
GLINRDOCK_LOG_LEVEL=info
```

## Incident Response

### Security Incident Checklist

1. **Immediate Response**
   - Stop the service: `sudo systemctl stop glinrdock`
   - Isolate the system from network if necessary
   - Preserve logs and evidence

2. **Assessment**
   - Check system logs: `sudo journalctl -u glinrdock.service`
   - Check application logs: `sudo tail -f /var/lib/glinrdock/logs/glinrdock.log`
   - Assess data integrity

3. **Containment**
   - Change all admin tokens
   - Update firewall rules
   - Apply security patches

4. **Recovery**
   - Restore from known-good backups if necessary
   - Update to patched version
   - Restart services with enhanced monitoring

5. **Follow-up**
   - Document the incident
   - Review security procedures
   - Report to security team if required

### Emergency Contacts
- **Security Team**: security@glinr.dev
- **Incident Response**: Use GitHub issues for non-security incidents

## Compliance

### Standards Alignment
GlinrDock security practices align with:
- **CIS Controls** for cyber defense
- **NIST Cybersecurity Framework**
- **ISO 27001** security management
- **SOC 2** security controls

### Audit Support
For compliance audits, we provide:
- Security documentation
- Configuration guides
- Audit log formats
- Vulnerability assessment reports

## Security Resources

### Documentation
- [Configuration Guide](CONFIG.md) - Secure configuration options
- [Installation Guide](INSTALL.md) - Secure installation practices
- [Troubleshooting](TROUBLESHOOTING.md) - Security-related issues

### External Resources
- [Docker Security](https://docs.docker.com/engine/security/)
- [Linux Security Hardening](https://linux-audit.com/linux-server-hardening/)
- [systemd Security](https://systemd.io/SECURITY/)

## Updates and Notifications

### Security Updates
- Subscribe to release notifications on GitHub
- Monitor security advisories
- Enable automatic updates for critical patches (when available)

### Communication Channels
- **Security Advisories**: GitHub Security tab
- **Release Notes**: GitHub Releases page
- **Email Updates**: Subscribe via GitHub notifications

## Legal

### Responsible Disclosure
We appreciate responsible disclosure of security vulnerabilities. Researchers who follow our reporting process may be eligible for:
- Public recognition (with permission)
- Security hall of fame listing
- Early access to fixed versions

### Disclaimer
While we strive to maintain high security standards, no software is completely secure. Users are responsible for:
- Keeping systems updated
- Following security best practices
- Monitoring for unusual activity
- Maintaining appropriate backups

For questions about this security policy, contact: security@glinr.dev