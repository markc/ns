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

## Important Instructions
Do what has been asked; nothing more, nothing less.
NEVER create files unless they're absolutely necessary for achieving your goal.
ALWAYS prefer editing an existing file to creating a new one.
NEVER proactively create documentation files (*.md) or README files. Only create documentation files if explicitly requested by the User.