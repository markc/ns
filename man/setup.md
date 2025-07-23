# NetServa Setup Command

## Usage
```
ns setup [OPTIONS]
```

## Description
Initialize and configure NetServa system for a host.

The setup process configures environment variables, creates directory structure, and saves host configuration for future use.

## Options
- `-h, --host HOSTNAME` - Set target hostname (default: current FQDN)
- `-t, --type TYPE` - System type hint (vm|container|vps)
- `-d, --database TYPE` - Database type (mysql|sqlite)
- `--dry-run` - Show what would be configured without making changes
- `--help` - Show this help message

## Examples

### Basic Setup
```bash
# Setup for current host
ns setup

# Setup for specific host
ns setup --host mail.example.com --type vm

# Preview configuration without changes
ns setup --database sqlite --dry-run
```

### Advanced Options
```bash
# Container-specific setup
ns setup --type container --host test.lan

# MySQL database setup
ns setup --database mysql --host web.example.com
```

## Setup Process

The setup command will:
1. Configure environment variables for the specified host
2. Create necessary directory structure
3. Save host configuration to `~/.vhosts/` for future use
4. Set up database and service paths based on detected OS

## Configuration Storage

Host configurations are saved to `~/.vhosts/<hostname>` and can be loaded automatically in future sessions.

## Related Commands
- `ns status` - Check system status after setup
- `ns mount <system>` - Mount configured systems
- `ns help` - General help and available commands