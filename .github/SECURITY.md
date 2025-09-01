# Security Policy

## Reporting Security Vulnerabilities

**DO NOT** report security vulnerabilities through public GitHub issues.

Instead, please report security vulnerabilities via email to: **security@glinr.dev**

Include the following in your report:
- Description of the vulnerability
- Steps to reproduce the issue
- Potential impact assessment
- Suggested fix (if available)

We will respond within **24 hours** and provide regular updates on our progress.

## Supported Versions

We provide security updates for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| Latest  | :white_check_mark: |
| < 1.0   | :x:                |

## Security Best Practices

For production deployments, please follow our [Security Guide](../SECURITY.md) which covers:

- Network security configuration
- Authentication and authorization
- Container security hardening
- Monitoring and auditing
- Incident response procedures

## Security Features

GlinrDock includes several built-in security features:
- Mandatory authentication for all API endpoints
- Input validation and sanitization
- Audit logging
- Rate limiting
- CSRF protection
- Secure defaults

## Vulnerability Disclosure Timeline

1. **Report received**: We acknowledge receipt within 24 hours
2. **Initial triage**: Assessment completed within 3 business days  
3. **Investigation**: Ongoing updates provided weekly
4. **Resolution**: Timeline varies by severity (24h - 30 days)
5. **Disclosure**: Public disclosure after fix is available

## Recognition

We recognize security researchers who responsibly disclose vulnerabilities:
- Public acknowledgment (with permission)
- Security hall of fame
- Early access to new features

Thank you for helping keep GlinrDock secure!