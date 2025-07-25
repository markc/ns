# Universal Mounting System

This directory contains enhanced mounting scripts that support both local Incus containers and remote VPS systems via SSHFS.

## Scripts Overview

### 1. mount-system (Main Script)
Universal mounting script that automatically detects and mounts both local containers and remote systems.

### 2. mount-container (Legacy Compatibility)
Symlink to `mount-system` for backward compatibility with existing workflows.

### 3. mount (Convenience Wrapper)
Short alias for `mount-system` for quick access.

## Features

- **Automatic Detection**: Distinguishes between local containers and remote VPS
- **SSH Integration**: Uses existing SSH config for remote systems
- **Intelligent Caching**: Optimized SSHFS options for performance
- **Error Handling**: Comprehensive connection and path validation
- **UID Mapping**: Proper file ownership preservation
- **Auto-reconnect**: Maintains connections during network interruptions

## Usage Examples

### Local Containers
```bash
# Mount local MGO container
./mount-system mgo
./mount mgo                    # Short form

# Mount with custom path
./mount-system -m /tmp/mgo mgo

# Unmount
./mount-system -u mgo
```

### Remote VPS Systems
```bash
# Mount entire remote filesystem
./mount-system mko

# Mount specific remote directory
./mount-system mko /var/www

# Mount with custom local path
./mount-system -m /mnt/remote-web mko /var/www

# Force remote type (if ambiguous)
./mount-system -t remote webserver

# Unmount
./mount-system -u mko
```

### Multiple Systems
```bash
# Mount multiple systems
for system in mgo haproxy trixie mko; do
    ./mount-system "$system"
done

# Unmount all
for system in mgo haproxy trixie mko; do
    ./mount-system -u "$system"
done
```

## Configuration Requirements

### For Local Containers (Incus/LXC)
1. Container must exist in Incus
2. SSH access configured to container
3. Container must be running (auto-started if needed)

### For Remote VPS Systems
1. SSH host configuration in `~/.ssh/config` or `~/.ssh/config.d/`
2. Key-based authentication setup
3. Remote system accessible via SSH

### SSH Config Example
```bash
# ~/.ssh/config
Host mko
    HostName 192.168.1.100
    User root
    Port 22
    IdentityFile ~/.ssh/id_rsa
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

Host production-web
    HostName web.example.com
    User webuser
    Port 2222
    IdentityFile ~/.ssh/id_production
```

## Command Line Options

```
Usage: mount-system [OPTIONS] <system-name> [remote-path]

Options:
    -u          Unmount the system
    -t TYPE     Force type: 'container' or 'remote'
    -m PATH     Custom mount point (default: ~/Dev/ns/<system-name>)
    -h          Show this help message

Arguments:
    system-name    Name of the container or remote host
    remote-path    Path to mount from remote (default: /, only for remote systems)
```

## System Detection Logic

The script automatically detects system type using this priority:

1. **Check SSH Config**: Look for host in `~/.ssh/config` and `~/.ssh/config.d/`
2. **Check Incus**: Look for container in `incus list`
3. **Ambiguous Cases**: When found in both, prompt for clarification or use `-t` flag
4. **Unknown**: Show helpful error with setup instructions

## SSHFS Options Used

### For Local Containers
```bash
sshfs container:/ /mount/point \
    -o allow_other,default_permissions,follow_symlinks,reconnect \
    -o ServerAliveInterval=15,ServerAliveCountMax=3 \
    -o idmap=user,uid=$(id -u),gid=$(id -g)
```

### For Remote VPS
```bash
sshfs remote:/path /mount/point \
    -o allow_other,default_permissions,follow_symlinks,reconnect \
    -o ServerAliveInterval=15,ServerAliveCountMax=3 \
    -o idmap=user,uid=$(id -u),gid=$(id -g) \
    -o cache=yes,cache_timeout=115200,attr_timeout=115200
```

## Performance Optimizations

### Caching (Remote Only)
- **File caching**: 32 hours cache timeout
- **Attribute caching**: Reduces metadata lookups
- **Reconnection**: Automatic reconnect on network issues

### UID/GID Mapping
- Maps remote UIDs to local user
- Preserves file permissions
- Prevents permission issues

## Troubleshooting

### "Cannot connect via SSH"
```bash
# Test SSH connection manually
ssh mko whoami

# Check SSH config
grep -A 10 "^Host mko" ~/.ssh/config

# Verify key authentication
ssh -i ~/.ssh/id_rsa mko whoami
```

### "Permission denied" on mount
```bash
# Check if user is in fuse group
groups | grep fuse

# Add user to fuse group if needed
sudo usermod -a -G fuse $USER
# Then logout and login again
```

### "Mount point busy"
```bash
# Force unmount
sudo umount -f /home/markc/Dev/ns/mko

# Or use fusermount
fusermount -u /home/markc/Dev/ns/mko

# Check what's using the mount
lsof +D /home/markc/Dev/ns/mko
```

### "Remote path does not exist"
```bash
# Check remote path manually
ssh mko "ls -la /var/www"

# Use absolute path
./mount-system mko /home/user/documents
```

## Dependencies

### Required
- **sshfs**: For mounting remote filesystems
- **fusermount**: For unmounting FUSE filesystems
- **ssh**: For remote connections

### Optional
- **incus**: For local container management
- **fuse**: Kernel module (usually included)

### Installation
```bash
# Ubuntu/Debian
sudo apt-get install sshfs fuse

# Fedora/RHEL
sudo dnf install sshfs fuse

# Arch Linux
sudo pacman -S sshfs fuse
```

## Security Considerations

1. **SSH Keys**: Use dedicated SSH keys for each system
2. **Known Hosts**: Consider using proper known_hosts for production
3. **File Permissions**: SSHFS preserves remote permissions
4. **Network Security**: SSH traffic is encrypted
5. **Mount Options**: `allow_other` requires proper fuse configuration

## Integration with Development Workflow

### VS Code Integration
```bash
# Mount system
./mount-system mko

# Open in VS Code
code /home/markc/Dev/ns/mko

# Work on remote files as if they were local
```

### Git Operations
```bash
# Mount remote development server
./mount-system dev-server /home/user/projects

# Work with git normally
cd /home/markc/Dev/ns/dev-server/myproject
git status
git commit -m "Update from local"
git push
```

### Testing with TLS Scripts
```bash
# Mount remote server
./mount-system production-web

# Run TLS tests from remote system
ssh production-web "./tls-security-check.sh target.domain.com"

# Or copy scripts to mounted filesystem
cp tls-*.sh /home/markc/Dev/ns/production-web/tmp/
```

## Best Practices

1. **Use descriptive host names** in SSH config
2. **Group related systems** with consistent naming
3. **Set up key-based auth** for all remote systems
4. **Use specific mount points** for different purposes
5. **Unmount when done** to free resources
6. **Test connections** before relying on mounts

## Migration from Old Script

The new script is fully backward compatible:

```bash
# Old way
./mount-container mgo

# New way (same result)
./mount-system mgo
./mount mgo
```

All existing workflows continue to work unchanged.