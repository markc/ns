# NetServa - Server Management System

**A unified bash-based toolkit for managing Virtual Machines, LXC Containers, and VPS servers**

---

## What is NetServa?

NetServa is a comprehensive server management system designed for system administrators who need to efficiently manage multiple servers, containers, and services across different platforms. Built with modern bash scripting principles, it provides a unified command-line interface that abstracts the complexity of managing diverse server environments.

### Key Platforms Supported
- **Incus/LXD** - Modern LXC container management
- **Proxmox** - Virtualization platform management  
- **BinaryLane VPS** - Commercial VPS server management
- **Alpine Linux** - Lightweight container OS
- **Debian Trixie** - Modern Debian-based systems
- **CachyOS** - Arch-based development environments

## Why NetServa Exists

### The Problem
Modern server administration involves juggling multiple technologies, platforms, and service management systems. System administrators often find themselves:

- Managing servers across different OS types (systemd, OpenRC, OpenWrt)
- Dealing with inconsistent configuration formats and locations
- Manually configuring email, web, and DNS services repeatedly
- Struggling with secure SSH key and host management
- Lacking unified tools for security auditing and TLS testing
- Needing to remember different command syntaxes for each platform

### The Solution
NetServa addresses these challenges by providing:

1. **Unified Interface** - Single `ns` command for all operations across platforms
2. **Cross-Platform Compatibility** - Automatically detects and adapts to different OS types
3. **Production-Ready Templates** - Pre-configured email (Postfix/Dovecot), web (Nginx), and DNS (PowerDNS) setups  
4. **Secure SSH Management** - Organized SSH key and host configuration system
5. **Security-First Approach** - Built-in TLS testing and security auditing tools
6. **Container-Native** - Designed for modern LXC container workflows
7. **Remote Management** - SSH-based mounting and remote command execution

## Who Should Use NetServa

### Target Users
- **System Administrators** managing multiple Linux servers
- **DevOps Engineers** working with container-based infrastructures  
- **Self-hosted Service Providers** running email, web, and DNS services
- **Security-Conscious Admins** needing regular TLS/SSL auditing
- **Multi-Platform Managers** dealing with mixed OS environments

### Use Cases
- **Email Server Management** - Complete Postfix/Dovecot/PowerDNS configurations
- **Web Hosting** - Nginx and PHP-FPM setups with SSL/TLS security
- **Container Orchestration** - LXC container lifecycle management via Incus
- **VPS Fleet Management** - Managing multiple commercial VPS instances
- **Security Auditing** - Automated TLS/SSL vulnerability testing
- **SSH Infrastructure** - Organized key management and host configurations

## Core Philosophy

### Design Principles
1. **Simplicity Over Complexity** - One command interface for all operations
2. **Security by Default** - Auto-generated secure passwords, proper file permissions
3. **Platform Agnostic** - Works consistently across different Linux distributions
4. **Production Ready** - Battle-tested configurations and best practices
5. **Modern Standards** - Uses current security practices and technologies

### Technology Choices
- **Bash Scripting** - Universal availability, excellent for system administration
- **MIT License** - Open source with maximum flexibility
- **No Dependencies** - Uses standard Linux tools available everywhere
- **Modular Architecture** - Extensible library system for custom workflows

## Project Evolution

NetServa represents the modernization and consolidation of two previous projects:
- **sh project** - Legacy shell environment and server management toolkit
- **hcp project** - PHP-based web interface for hosting control

This unified approach combines the best of both worlds: powerful command-line tools with the option for web-based management interfaces.

## What Makes NetServa Different

### Compared to Other Solutions
- **More Lightweight** than complex orchestration platforms
- **More Secure** than default distributions with hardened configurations  
- **More Unified** than using separate tools for each service
- **More Flexible** than rigid container orchestration systems
- **More Practical** than academic or overly complex solutions

### Unique Features
- **Dynamic Host Configuration** - Automatic environment setup based on FQDN
- **Cross-Platform Service Control** - `sc()` function works on systemd, OpenRC, and OpenWrt
- **SSH Mount System** - Remote servers accessible as local directories
- **Integrated Security Testing** - Built-in TLS/SSL vulnerability scanning
- **Production Templates** - Real-world email, web, and DNS configurations

---

## Getting Started

For installation instructions, command usage, and detailed guides, see:
- **[doc/](doc/)** - Technical documentation and deployment guides
- **[man/](man/)** - Command reference and usage examples

### Quick Commands
```bash
# Get help on any command
ns help

# Check system status
ns status

# List available mounts
ns mounts

# Browse documentation
ns doc
```

---

**NetServa** - Making server management simpler, more secure, and more consistent across all your infrastructure.

*Copyright (C) 1995-2025 Mark Constable <mc@netserva.org> (MIT License)*