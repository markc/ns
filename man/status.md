# NetServa Status Command

## Usage
```
ns status [TARGET]
```

## Description
Show status of services, containers, or VMs.

Provides comprehensive system status information including running services, container status, and system resources.

## Arguments
- `TARGET` - Specific target to check (optional)

## Options
- `-a, --all` - Show all status information
- `-s, --services` - Show service status only
- `-c, --containers` - Show container status only

## Examples

### Basic Usage
```bash
# General system status
ns status

# Check specific service
ns status nginx

# Show all available status information
ns status --all
```

### Filtered Views
```bash
# Services only
ns status --services

# Containers only
ns status --containers
```

## Status Information

The status command displays:
- **Services**: Running/stopped services via systemctl/rc-service
- **Containers**: LXC/Incus container states
- **System**: Load average, memory usage, disk usage
- **Network**: Active connections and interfaces

## Related Commands
- `ns mount <system>` - Mount systems for access
- `ns mounts` - List currently mounted systems
- `ns setup` - Initial system configuration