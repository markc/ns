# NetServa Start/Stop/Restart Commands

## Usage
```
ns start <TARGET>
ns stop <TARGET>
ns restart <TARGET>
```

## Description
Start, stop, or restart services, containers, or VMs.

Provides unified interface for controlling system services and containers across different platforms.

## Arguments
- `TARGET` - Service, container, or VM name (required)

## Options
- `-f, --force` - Force operation (bypass safety checks)
- `-w, --wait` - Wait for completion before returning

## Examples

### Service Control
```bash
# Start/stop/restart services
ns start nginx
ns stop mysql
ns restart postfix
```

### Container Management
```bash
# Container operations
ns start my-container
ns stop test-vm
ns restart web-server
```

### Advanced Options
```bash
# Force operation (use with caution)
ns stop --force stuck-service

# Wait for completion
ns restart --wait nginx
```

## Service Detection

The command automatically detects:
- **System services**: via systemctl (systemd) or rc-service (OpenRC)
- **Containers**: via incus/lxc commands
- **VMs**: via virtualization platform commands

## Platform Support
- **systemd**: Modern Linux distributions
- **OpenRC**: Alpine Linux, some embedded systems
- **LXC/Incus**: Container management
- **OpenWrt**: Router/embedded systems

## Related Commands
- `ns status` - Check service/container status
- `ns status <target>` - Check specific target status
- `ns mount <system>` - Access container filesystems