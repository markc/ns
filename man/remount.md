# NetServa Remount Command

## Usage
```
ns remount [OPTIONS] <system-name> [mount-options...]
```

## Description
Unmount and remount a system to refresh the connection.

This command is particularly useful when SSH connections have timed out, when network issues have occurred, or when you need to mount a different path on the same system.

## Arguments
- `system-name` - Name of system to remount (required)
- `mount-options` - Any additional options supported by the mount command

## Examples

### Basic Usage
```bash
# Simple remount to refresh connection
ns remount mgo

# Remount with different path
ns remount mko /var/www

# Remount system after network interruption
ns remount webserver
```

### Advanced Usage
```bash
# Remount with custom mount point
ns remount -p /mnt/custom mko

# Remount different directory
ns remount mko /var/log

# Get help
ns remount --help
```

## Use Cases

- **Connection timeouts**: Refresh stale SSH/SSHFS connections
- **Network issues**: Re-establish mount after network interruption
- **Path changes**: Mount different directory on same system
- **Cache refresh**: Clear and refresh cached files
- **Permission updates**: Apply new SSH key or permission changes

## How It Works
1. Unmounts the existing mount (if any)
2. Waits 2 seconds for cleanup
3. Mounts again with the same or new options
4. All original mount options are preserved unless overridden

## Notes
- The remount preserves all original mount options
- You can specify new options which will be passed to mount
- If unmount fails, the command continues with mount attempt
- Useful for recovering from "Transport endpoint is not connected" errors

## Related Commands
- `ns mount <system>` - Initial mount operation
- `ns unmount <system>` - Unmount without remounting
- `ns mounts` - List all mounted systems