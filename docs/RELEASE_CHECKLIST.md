# Release Checklist

This checklist ensures comprehensive validation of each GlinrDock release before publication.

## Pre-Release Validation

### Build Verification
- [ ] All platform binaries built successfully (Linux AMD64, Linux ARM64, macOS Intel, macOS ARM64)
- [ ] Binary sizes are within expected ranges (no significant bloat)
- [ ] All binaries are executable and pass basic smoke tests
- [ ] Container image builds successfully for all supported architectures

### Security & Compliance
- [ ] SBOM (Software Bill of Materials) generated and validated
- [ ] All dependencies scanned for known vulnerabilities
- [ ] Security review completed for any dependency changes
- [ ] No hardcoded secrets or credentials in binaries
- [ ] Container image security scan passed (no critical vulnerabilities)

### Checksums & Signatures
- [ ] SHA256SUMS file generated with correct checksums for all artifacts
- [ ] All binary checksums verified against generated hashes
- [ ] Container image digest recorded and verified
- [ ] GPG signatures generated (if applicable)

### Automated Testing
- [ ] All CI/CD pipeline tests passed
- [ ] Smoke tests passed for container deployment
- [ ] Asset verification workflow completed successfully
- [ ] No failing workflows in repository

## Installation Testing

### Linux Distribution Testing
- [ ] **Ubuntu 22.04 LTS**: Install script tested and verified
- [ ] **Ubuntu 20.04 LTS**: Install script tested and verified  
- [ ] **Debian 12**: Install script tested and verified
- [ ] **Debian 11**: Install script tested and verified
- [ ] **RHEL/CentOS**: Manual binary installation tested
- [ ] **Alpine Linux**: Container deployment tested

### Installation Methods
- [ ] **Automated installer**: `curl | bash` method works correctly
- [ ] **Manual binary**: Download, verify, install process tested
- [ ] **Docker Compose**: Container starts and health check passes
- [ ] **systemd service**: Service installs, starts, and operates correctly
- [ ] **Uninstaller**: Removal script works without leaving artifacts

### Post-Installation Verification
- [ ] Web interface accessible at http://localhost:8080
- [ ] Admin token authentication works correctly
- [ ] Basic container management operations functional
- [ ] Health endpoint `/v1/health` responds correctly
- [ ] Logs are being written to expected locations

## Documentation & Release Notes

### Documentation Updates
- [ ] Installation documentation updated for new version
- [ ] Breaking changes documented (if any)
- [ ] Security advisories updated (if applicable)
- [ ] FAQ updated with any new common issues
- [ ] Troubleshooting guide updated

### Release Notes Quality
- [ ] Release notes generated and reviewed
- [ ] All significant changes included
- [ ] Breaking changes clearly highlighted
- [ ] Security fixes prominently mentioned
- [ ] Installation instructions accurate

## Final Release Steps

### Draft Release Preparation
- [ ] Draft release created with auto-generated notes
- [ ] Release notes manually reviewed and enhanced
- [ ] All artifacts attached to draft release
- [ ] Release tagged with correct version format (vX.Y.Z)

### Pre-Publication Review
- [ ] Release notes proofread for clarity and accuracy
- [ ] All download links tested and working
- [ ] Installation instructions verified in release notes
- [ ] Security contact information current

### Publication
- [ ] Release published publicly
- [ ] Container images pushed to registry (ghcr.io)
- [ ] Documentation site updated automatically
- [ ] Social media/communication channels notified (if applicable)

### Post-Release Monitoring
- [ ] Monitor GitHub Issues for installation problems
- [ ] Verify container registry shows new images
- [ ] Check documentation site reflects new version
- [ ] Monitor download statistics and error reports

## Rollback Procedures

In case of critical issues discovered post-release:

- [ ] **Immediate**: Mark release as pre-release or draft
- [ ] **Container**: Remove problematic image tags from registry
- [ ] **Communication**: Post issue acknowledgment and ETA for fix
- [ ] **Fix**: Prepare hotfix release following abbreviated checklist

## Sign-Off

**Release Manager**: _____________________  **Date**: ___________

**Security Reviewer**: ____________________  **Date**: ___________

**QA Lead**: ___________________________  **Date**: ___________

---

**Note**: This checklist should be completed for every release. For hotfix releases, focus on security, testing, and rollback preparation sections.