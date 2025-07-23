# NetServa Documentation

Welcome to the NetServa documentation directory. This folder contains technical documentation, guides, and planning documents for the NetServa server management system.

## 📚 Documentation Index

### Configuration & Setup
- [**Bayes Spam Learning Configuration**](Bayes-spam-learning-configuration.md) - Configure Bayesian spam filtering for email servers
- [**Deployment Guide**](deployment.md) - Instructions for deploying NetServa to production servers

### Security & Testing
- [**TLS Testing Guide**](TLS-TESTING-README.md) - Comprehensive guide to TLS/SSL security testing tools
- [**Security Command Reference**](../man/security.md) - Quick reference for `ns security` commands

### Container Management
- [**Incus Backup Management**](incus-backup-management.md) - Backup strategies and scripts for Incus containers
- [**Mount Commands**](../man/mount.md) - Reference for container mounting operations

### Project Information
- [**Changelog**](changelog.md) - Version history and release notes
- [**Development Plan**](plan.md) - Project roadmap and feature planning

## 🔗 Quick Links

### Command Reference
For command-line usage and quick help, see the [**man/ directory**](../man/README.md) which contains:
- Command syntax and options
- Usage examples
- Quick reference guides

### Getting Started
1. Review the [deployment guide](deployment.md) for installation
2. Check the [command reference](../man/README.md) for usage
3. Configure [spam filtering](Bayes-spam-learning-configuration.md) for email servers
4. Set up [TLS security testing](TLS-TESTING-README.md)

### Key Commands
```bash
# View any documentation with glow
glow doc/README.md

# Get help for any command
ns help <command>

# Quick start
ns setup
ns status
ns mount <system>
```

## 📖 Documentation Standards

All documentation in this directory follows these conventions:
- **Markdown format** (.md) for consistency
- **Descriptive filenames** with hyphens for spaces
- **Clear headings** using markdown headers
- **Code examples** in fenced code blocks
- **Cross-references** using relative links

## 🚀 Contributing

When adding new documentation:
1. Use descriptive filenames (e.g., `feature-name-guide.md`)
2. Add an entry to this README.md
3. Include examples and use cases
4. Cross-reference related documents
5. Test all code examples

---

For command-line help and usage, see the [**man/ directory**](../man/README.md) | [**Main README**](../README.md)