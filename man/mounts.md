# NetServa Mounts Command

## Usage
```
ns mounts
ns list-mounts
```

## Description
List all currently mounted NetServa systems.

Shows mounted containers and remote systems with usage information, mount points, and connection status.

## Examples

### Basic Usage
```bash
# List mounted systems
ns mounts

# Alternative command name
ns list-mounts
```

## Output Information

The command displays:
- **System Name**: Container or remote host name
- **Mount Point**: Local directory where system is mounted
- **Type**: Container (local) or Remote (SSH)
- **Status**: Active, Stale, or Error
- **Usage**: Disk space information if available

## Sample Output
```
System     Type       Mount Point              Status    Usage
─────────────────────────────────────────────────────────────
mgo        Container  /home/user/Dev/ns/mnt/mgo   Active    2.1G/10G
mko        Remote     /home/user/Dev/ns/mnt/mko   Active    850M/5G
web01      Remote     /home/user/Dev/ns/mnt/web01 Stale     N/A
```

## Status Indicators
- **Active**: Mount is working and accessible
- **Stale**: Mount exists but connection may be lost
- **Error**: Mount point exists but has issues

## Troubleshooting
- **Stale mounts**: Use `ns remount <system>` to refresh
- **Error status**: Check `ns unmount <system>` then `ns mount <system>`
- **Missing systems**: Verify SSH config with `ns ssh list`

## Related Commands
- `ns mount <system>` - Mount new systems
- `ns unmount <system>` - Unmount systems
- `ns remount <system>` - Refresh connections