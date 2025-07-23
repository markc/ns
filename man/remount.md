# NetServa Remount Command

## Usage
```
ns remount [OPTIONS] <system-name> [mount-options...]
```

## Description
Unmount and remount a system (useful for refreshing connections).

This command is particularly useful when SSH connections have timed out or when you need to refresh mount options.

## Arguments
- `system-name` - Name of system to remount (required)
- `mount-options` - Any additional options supported by mount command

## Examples

### Basic Usage
```bash
# Simple remount to refresh connection
ns remount mgo

# Remount with different path
ns remount mko /var/www

# Remount remote system
ns remount webserver
```

### Advanced Usage
```bash
# Remount with specific SSH options
ns remount -o reconnect,idmap=user myserver

# Remount container with different user mapping
ns remount container-name /home/user
```

## Use Cases

- **Connection timeouts**: Refresh stale SSH connections
- **Network issues**: Re-establish after network interruption
- **Permission changes**: Update user mappings or access rights
- **Path changes**: Mount different directory on same system

## Process
1. Safely unmounts the existing mount
2. Re-establishes connection using saved configuration
3. Mounts with original or updated options
4. Verifies mount is successful

## Related Commands
- `ns mount <system>` - Initial mount operation
- `ns unmount <system>` - Unmount without remounting
- `ns mounts` - List all mounted systems
- `ns ssh list` - Check SSH configurations