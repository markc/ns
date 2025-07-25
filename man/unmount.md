# NetServa Unmount Command

## Usage
```
ns unmount [OPTIONS] <system-name>
```

## Description
Unmount previously mounted SSH-accessible systems.

Safely unmounts SSHFS-mounted systems with options for force unmounting if needed. Works with any system that was mounted via `ns mount`.

## Arguments
- `system-name` - Name of system to unmount (required)

## Options
- `-p, --path PATH` - Custom mount point to unmount (default: `mnt/<system-name>`)
- `-f, --force` - Force unmount (use if system is unresponsive)
- `-h, --help` - Show help message

## Examples

### Basic Usage
```bash
# Unmount system 'mgo'
ns unmount mgo

# Unmount system 'mko'
ns unmount mko
```

### Advanced Options
```bash
# Force unmount if stuck
ns unmount -f problematic-server

# Unmount custom mount point
ns unmount -p /tmp/myserver

# Get help
ns unmount --help
```

## How It Works
1. Checks if the mount point exists
2. Verifies the mount is active
3. Attempts graceful unmount using fusermount
4. Falls back to system umount if needed
5. With `--force`, uses forced unmount options
6. Removes empty mount directory after successful unmount

## Safety Features
- Checks if mount point is actually mounted before attempting unmount
- Provides force option for unresponsive systems
- Gracefully handles already-unmounted systems
- Preserves mount directory if it contains local files

## Troubleshooting

If unmount fails:
1. Check for active processes: `lsof +D mnt/system-name`
2. Close applications using the mount
3. Use `--force` option if system is unresponsive
4. Check if you have permission to unmount

Common issues:
- "Device or resource busy" - Files are still open
- "Transport endpoint is not connected" - Connection already lost (use --force)
- "Permission denied" - May need to check FUSE permissions

## Related Commands
- `ns mount <system>` - Mount systems
- `ns mounts` - List currently mounted systems
- `ns remount <system>` - Refresh mount connections