# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Netserva is a server management system for Virtual Machines (VM), LXC Containers (CT), and commercial VPS servers using Incus, Proxmox, and BinaryLane VPS. This is the deployment version of the development project (~/Dev/ns), built with bash scripting and designed for production server deployment.

**Important Terminology:**
- VM = Virtual Machine  
- CT = LXC Container (never Docker)
- VPS = Commercial VM like BinaryLane
- "container" always refers to LXC Container

## Architecture & Structure

### Development vs Deployment
- **Development**: `~/Dev/ns/` - Local development environment
- **Deployment**: `~/.ns/` - Deployed on servers as root user (THIS REPOSITORY)

### Core Components

#### NS Command Manager (`bin/ns`)
The main command-line interface that provides unified access to all NetServa functionality:
- `ns help` - Show available commands
- `ns status` - Check system status
- `ns mount <host>` - Mount remote server
- `ns ssh <command>` - SSH management

#### SSH Management (`bin/sshm`)
The critical SSH Manager script that manages `~/.ssh/config.d/` configurations. All SSH host configs are stored in separate files under `~/.ssh/config.d/` and included via the main `~/.ssh/config`.

Key functions:
- `sshm create <Name> <Host> [Port] [User] [Skey]` - Create SSH host config
- `sshm key_create <Name> [Comment] [Password]` - Generate SSH keys
- `sshm list` - List all configured hosts
- `sshm init` - Initialize SSH structure

#### Library Functions (`lib/`)
- `lib/netserva.sh` - Global configuration and environment variables
- `lib/functions.sh` - Core utility functions including:
  - `sethost()` - Dynamic host configuration based on FQDN
  - `sc()` - Service control wrapper for systemd/OpenRC/OpenWrt
  - `go2()` - Navigate to user directories
  - `sx()` - Execute commands on remote hosts

#### Configuration Templates (`etc/`)
Production-ready configuration files for:
- **Email**: Postfix (SMTP), Dovecot (IMAP), PowerDNS
- **Web**: Nginx, PHP-FPM configurations
- **Database**: MySQL/SQLite configurations

### Operating System Support
- **Development**: CachyOS (Arch-based)
- **Containers**: Alpine Linux (LXC)
- **VMs/VPS**: Debian Trixie
- **Legacy**: OpenWrt support in functions

### Environment Variables & Configuration
The `sethost()` function in `lib/functions.sh` dynamically configures environment based on hostname and OS type:
- Auto-detects OS type and sets appropriate paths
- Generates secure random passwords
- Configures service paths and database connections
- Sets user/group permissions

#### NetServa Path Variables (5-char naming convention):
- `NSDIR` - NetServa Directory (root) - `~/.ns`
- `NSBIN` - NetServa Binaries - `$NSDIR/bin`
- `NSLIB` - NetServa Libraries - `$NSDIR/lib`
- `NSETC` - NetServa Configurations - `$NSDIR/etc`
- `NSDOC` - NetServa Documentation - `$NSDIR/doc`
- `NSMAN` - NetServa Manual pages - `$NSDIR/man`

## Development Environment

### Technology Stack
- **Scripting**: Bash (primary)
- **Database**: MySQL/MariaDB and SQLite support
- **Web Server**: Nginx + PHP-FPM
- **Email**: Postfix + Dovecot + PowerDNS + RSpamd/SpamProbe

### Avoided Technologies
- Docker (use LXC instead)
- Python, Ruby, Java
- Node.js (except where strictly needed)

### File Permissions & Security
- SSH files: 600/700 permissions
- Scripts should be executable (755)
- All passwords auto-generated via `/dev/urandom`
- No hardcoded credentials in code

## Code Conventions

### Bash Scripting
- Use `#!/usr/bin/env bash` or `#!/bin/bash`
- Source `lib/functions.sh` for common utilities
- Use `sethost()` for environment setup
- Error handling with exit codes 0-255:
  - 0: Success
  - 1-250: Error with 'danger' alert
  - 251: Success with 'success' alert
  - 252: Info with 'info' alert
  - 253: Warning with 'warning' alert
  - 254/255: Various alert states

### Service Management
Use `sc()` function for cross-platform service control:
```bash
sc start nginx     # Start service
sc stop nginx      # Stop service  
sc status nginx    # Check status
sc                 # List all services
```

### Database Operations
Use environment variables for database access:
```bash
$SQCMD             # MySQL/SQLite command
$EXMYS             # MySQL execution
$EXSQL             # SQLite execution
```

## Security Considerations
- All scripts implement defensive security measures
- TLS security testing tools detect vulnerabilities
- SSH key management with proper permissions
- Auto-generated secure passwords
- Configuration templates follow security best practices

## File Locations
- **Deployment**: `~/.ns/` (THIS REPOSITORY - root user home on deployed servers)
- **SSH configs**: `~/.ssh/config.d/` (individual host files)
- **Mount points**: `mnt/<hostname>/` (SSH-mounted servers)

## Migration notes
- This is the migrated and modernized version from the old "sh" project
- Use "Netserva" as the project name and label
- All license references changed from AGPL-3.0 to MIT License
- All references changed from ~/.sh to ~/.ns
- User copyright notice changed from markc@renta.net to mc@netserva.org
- Retain the following template example at the top of all bin/ etc/ and lib/ files:
```bash
# Created: YYYYMMDD - Updated: YYYYMMDD
# Copyright (C) 1995-2025 Mark Constable <mc@netserva.org> (MIT License)
```

## Commands

- Build: None (shell scripts repository)
- Test: `ns status` (basic functionality check)
- Install: Run `setup-ns` script
- Management: `ns <command>` - unified command interface

## Documentation & Configuration Sanitization

### Public vs Private Content
This repository is intended for public GitHub. All documentation and configuration files must be sanitized:

#### Directory Structure:
- `doc/` - Public sanitized documentation
- `doc/private/` - Real configurations (gitignored)
- `man/` - Public sanitized manual pages  
- `man/private/` - Real manual pages (gitignored)
- `etc/` - Public sanitized config templates
- `etc/private/` - Real config files (gitignored)

#### Sanitization Rules:
1. Replace real domain names with example.com, example.net, example.org
2. Replace real IPs with 192.168.100.0/24 range
3. Use placeholder variables prefixed with underscore (e.g., `_MAIL_IP`, `_DB_PASSWORD`)
4. Include sed replacement examples in docs for deployment

#### Example Placeholders:
- `_DOMAIN` - Primary domain
- `_MAIL_IP` - Mail server IP
- `_DB_HOST` - Database hostname
- `_DB_PASSWORD` - Database password
- `_SSH_KEY` - SSH key path

#### Deployment Example:
```bash
# Replace placeholders during deployment
sed -i 's/_DOMAIN/yourdomain.com/g' config.conf
sed -i 's/_MAIL_IP/192.168.1.244/g' config.conf
```

### Private Documentation:
Store real-world configurations in `*/private/` subdirectories. These are gitignored and contain:
- Actual domain names and IPs
- Real passwords and keys
- Production configurations
- Network topology details

#### Critical `doc/private/` Policy:
Each VM/CT/VPS installation MUST have a corresponding documentation file:
- **Naming**: `doc/private/<vhost>.md` where `<vhost>` is the SSH host config name
- **Purpose**: Maintain detailed analysis and memory of each server over time
- **Content**: Real configurations, troubleshooting history, network details, passwords
- **Examples**:
  - `doc/private/haproxy.md` - HAProxy container documentation
  - `doc/private/mgo.md` - mail.goldcoast.org server documentation
  - `doc/private/trixie.md` - trixie.goldcoast.org server documentation
  - `doc/private/nsorg.md` - mail.netserva.org server documentation
- This creates a persistent knowledge base for each server that grows over time

## Important Instructions
Do what has been asked; nothing more, nothing less.
NEVER create files unless they're absolutely necessary for achieving your goal.
ALWAYS prefer editing an existing file to creating a new one.
ALWAYS proactively create documentation files in doc/ and man/ folders when implementing new features or making significant changes:
- Create sanitized public docs in `doc/` with example domains and placeholder variables
- Store real-world examples in `doc/private/` (gitignored)
- Man pages in `man/` should ALWAYS be generic enough to not need private versions
- Follow the sanitization rules above for all public-facing documentation
ALWAYS sanitize sensitive information in public-facing files using the rules above.