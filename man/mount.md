# NetServa Mount Command

## Usage
```
ns mount [OPTIONS] <system-name> [remote-path]
```

## Description
Mount local LXC containers or remote systems via SSHFS for easy file access.

The mount system automatically detects whether the target is a local container or remote system and uses the appropriate mounting method.

## Arguments
- **system-name**: Name of container or remote host (must exist in SSH config)
- **remote-path**: Remote path to mount (default: root filesystem `/`)

## Options
- `-t, --type TYPE`: Force type detection ('container' or 'remote')
- `-p, --path PATH`: Custom local mount point (default: `mnt/<system-name>`)
- `-u, --user USER`: SSH user for remote systems (default: root)
- `--remote-path PATH`: Alternative way to specify remote path
- `--dry-run`: Show what would be done without executing

## Examples

### Basic Usage
```bash
# Mount local container 'mgo'
ns mount mgo

# Mount remote system 'mko' 
ns mount mko

# Mount specific remote directory
ns mount mko /var/www
```

### Advanced Options
```bash
# Force remote system type
ns mount -t remote webserver

# Custom mount point and user
ns mount -p /tmp/myserver -u admin webserver

# Test what would happen
ns mount --dry-run mko
```

## Auto-Detection Logic
- Checks if system name matches local incus containers
- Falls back to SSH-based remote mounting
- Uses SSH config from `~/.ssh/config.d/`

## Mount Location
All systems mount under `mnt/<system-name>/` by default.

## Related Commands
- `ns mounts` - List currently mounted systems
- `ns unmount <system>` - Unmount a system
- `ns remount <system>` - Refresh mount connection
- `ns ssh list` - Show available SSH hosts