# NetServa Unmount Command

## Usage
```
ns unmount [OPTIONS] <system-name>
```

## Description
Unmount previously mounted systems.

Safely unmounts SSHFS-mounted containers and remote systems, with options for force unmounting if needed.

## Arguments
- `system-name` - Name of system to unmount (required)

## Options
- `-p, --path PATH` - Custom mount point to unmount
- `-f, --force` - Force unmount (use if system is unresponsive)
- `--dry-run` - Show what would be done without executing

## Examples

### Basic Usage
```bash
# Unmount system
ns unmount mgo

# Unmount remote system
ns unmount mko
```

### Advanced Options
```bash
# Force unmount if stuck
ns unmount -f problematic-server

# Unmount custom path
ns unmount -p /tmp/custom-mount myserver

# Preview unmount operation
ns unmount --dry-run mgo
```

## Safety Features
- Checks for active processes using the mount
- Warns if files are still open
- Provides force option for unresponsive systems
- Validates mount point before unmounting

## Troubleshooting

If unmount fails:
1. Check for active processes: `lsof +D mnt/system-name`
2. Close applications using the mount
3. Use `--force` option if system is unresponsive
4. Check system logs if issues persist

## Related Commands
- `ns mount <system>` - Mount systems
- `ns mounts` - List currently mounted systems
- `ns remount <system>` - Refresh mount connections