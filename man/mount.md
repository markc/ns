# NetServa Mount Command

## Usage
```
ns mount [OPTIONS] <system-name> [remote-path]
```

## Description
Mount any SSH-accessible system via SSHFS for easy file access.

The mount command works with any system that has been configured in SSH via `sshm` or has a configuration file in `~/.ssh/config.d/`. This unified approach means local containers, remote VMs, and VPS servers are all accessed the same way through SSH.

## Arguments
- **system-name**: Name of the SSH host (must exist in SSH config)
- **remote-path**: Remote path to mount (default: root filesystem `/`)

## Options
- `-p, --path PATH`: Custom local mount point (default: `mnt/<system-name>`)
- `-h, --help`: Show help message

## Examples

### Basic Usage
```bash
# Mount system 'mgo' (could be container, VM, or VPS)
ns mount mgo

# Mount system 'mko' 
ns mount mko

# Mount specific directory from 'mko'
ns mount mko /var/www
```

### Advanced Options
```bash
# Use custom mount point
ns mount -p /tmp/myserver mko

# Mount web directory with custom path
ns mount -p /tmp/web mko /var/www/html
```

## How It Works
1. Checks if the SSH host exists in `~/.ssh/config.d/<system-name>` or main SSH config
2. Tests SSH connectivity to ensure the host is reachable
3. Creates mount point directory if it doesn't exist
4. Uses SSHFS with optimized options for performance and reliability
5. Caches files locally for faster subsequent access

## Prerequisites
- **sshfs**: Install with `sudo pacman -S sshfs` (or equivalent for your OS)
- **SSH configuration**: Host must be configured via `sshm create` or exist in SSH config
- **Key authentication**: Password-less SSH access must be configured

## Mount Location
All systems mount under `mnt/<system-name>/` by default, relative to your current directory.

## Performance Notes
- Files are cached locally for faster access
- Automatic reconnection on network interruptions
- Optimized for both local and remote connections

## Related Commands
- `ns mounts` - List currently mounted systems
- `ns unmount <system>` - Unmount a system
- `ns remount <system>` - Refresh mount connection
- `sshm list` - Show available SSH hosts
- `sshm create <name> <host>` - Add new SSH host configuration