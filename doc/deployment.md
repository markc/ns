# NetServa Deployment Guide

## Development vs Production Paths

NetServa is designed to work in both development and deployment environments with automatic path detection.

### Development Environment
- **Location**: `~/Dev/ns/`
- **Library loading**: Uses relative paths via `nsrc.sh` path detection
- **PATH**: Includes `~/Dev/ns/bin` for testing commands
- **Configuration**: Uses development-specific settings

### Deployment Environment  
- **Location**: `~/.ns/` (deployed on target servers)
- **Library loading**: Uses deployed paths automatically detected by `nsrc.sh`
- **PATH**: Includes `~/.ns/bin` for production commands
- **Configuration**: Uses production settings

## Key Files for Deployment

### Core System Files
- `lib/nsrc.sh` - Master environment loader (handles path detection)
- `lib/functions.sh` - Core utility functions with multi-OS support
- `lib/aliases.sh` - Command aliases (updated to use `nsrc_reload`)
- `bin/ns` - Master command interface

### Path Detection Logic
The `lib/nsrc.sh` automatically detects the environment:

1. **Explicit override**: `NSDIR` environment variable
2. **Production**: `~/.ns/lib/nsrc.sh` exists
3. **Development (root)**: `./lib/nsrc.sh` exists  
4. **Development (bin/)**: `../lib/nsrc.sh` exists
5. **Fallback search**: Common locations
6. **Default**: `~/.ns/`

## Migration from Legacy ~/.sh System

When deploying NetServa, references have been updated:

### Updated References
- ✅ `~/.sh/bin` → uses `$NS_BIN` (auto-detected)
- ✅ `~/.sh/lib/` → uses `$NS_LIB` (auto-detected)  
- ✅ PATH includes correct bin directory for environment
- ✅ Library loading uses fallback to `~/.ns/lib/`

### Files Updated
- `lib/nsrc.sh`: Master environment with proper path detection
- `lib/aliases.sh`: `es` alias integration with `nsrc_reload`
- `bin/ns`: Uses relative path detection for libraries
- `lib/services.sh`: Leverages existing multi-OS `sc()` function

## Multi-OS Support

NetServa supports multiple operating systems through the existing `sc()` function:

### Supported Systems
- **OpenWrt**: Router/gateway environments (init.d)
- **Alpine**: Container environments (OpenRC)  
- **Debian/Ubuntu**: Traditional Linux (systemd)
- **Arch/CachyOS/Manjaro**: Arch-based systems (systemd)
- **macOS**: Development environments (launchctl)

### OS Detection
Automatic detection via `/etc/os-release`, `/etc/openwrt_release`, and `uname`:
- Sets `OSTYP` variable for OS-specific behavior
- Sets `ARCH` variable for architecture-specific behavior
- Configures package managers and service managers

## Environment Reloading

The `es` alias provides environment reloading:
```bash
es  # Edit ~/.myrc and reload NetServa environment
```

This calls `nsrc_reload()` which:
1. Re-detects OS and architecture
2. Re-sets NetServa paths
3. **Updates PATH** - removes old `~/.sh/bin` and adds correct NetServa bin
4. Reloads libraries
5. Re-sources host configuration
6. Sources personal configuration

### PATH Management

NetServa automatically manages your PATH to ensure the correct binaries are used:

**Before NetServa**:
```
/usr/bin:/bin:...:/home/user/.sh/bin:...
```

**After NetServa (Development)**:
```
/home/user/Dev/ns/bin:/usr/bin:/bin:...
```

**After NetServa (Deployment)**:
```
/home/user/.ns/bin:/usr/bin:/bin:...
```

The `update_path()` function:
- Removes all old NetServa paths (`~/.sh/bin`, `~/Dev/ns/bin`, `~/.ns/bin`)
- Adds the correct NetServa bin directory to the front of PATH
- Prevents duplicates
- Works for both development and deployment scenarios

## Deployment Checklist

### For Production Deployment
1. Clone/copy NetServa to `~/.ns/` on target system
2. Source `~/.ns/lib/nsrc.sh` in shell initialization (`.bashrc`, `.profile`)
3. Verify OS detection: `echo $OSTYP`
4. Test commands: `ns version`, `ns status`
5. Configure host-specific settings in `~/.ns/etc/host.conf`

### For Development
1. Work in `~/Dev/ns/` directory
2. Source `lib/nsrc.sh` for testing
3. Use `./bin/ns` for command testing
4. Environment auto-detects development mode

## Configuration Files

### Personal Configuration
- `~/.myrc` - Personal environment variables and customizations
- `~/.nsrc` - NetServa-specific personal configuration (future use)

### Host Configuration  
- `~/.ns/etc/host.conf` - Host-specific NetServa settings
- Auto-generated on first run with hostname detection

### SSH Configuration
- `~/.ssh/config.d/` - Individual host configurations (managed by `sshm`)
- `~/.ssh/config` - Main SSH config with Include directive

## Backwards Compatibility

NetServa maintains compatibility with existing `.sh` system:
- Library fallback paths still check legacy locations
- Existing `sc()` function preserved and enhanced
- Configuration patterns maintained
- SSH management system preserved (`sshm`)

The system gracefully handles migration from `~/.sh` to `~/.ns` structure.