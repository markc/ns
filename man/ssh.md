# NetServa SSH Command

## Usage
```
ns ssh <ACTION> [ARGS]
```

## Description
SSH key and host management.

Manages SSH configurations, keys, and host entries for seamless server access.

## Actions
- `create` - Create new SSH host configuration
- `list` - List SSH hosts
- `key-create` - Create SSH key pair
- `key-list` - List SSH keys
- `init` - Initialize SSH structure

## Examples

### Host Management
```bash
# Create SSH host configuration
ns ssh create myserver server.example.com

# Create with custom port and user
ns ssh create myserver server.com 2222 admin

# List configured hosts
ns ssh list
```

### Key Management
```bash
# Create new SSH key
ns ssh key-create myserver

# Create key with comment
ns ssh key-create myserver "Server access key"

# List available keys
ns ssh key-list
```

### Initialization
```bash
# Initialize SSH structure
ns ssh init
```

## SSH Configuration

The system manages SSH configurations in:
- `~/.ssh/config.d/` - Individual host configurations
- `~/.ssh/config` - Main configuration that includes config.d files
- `~/.ssh/keys/` - SSH private keys
- `~/.ssh/keys/*.pub` - SSH public keys

## Host Configuration Format

Host entries are stored in `~/.ssh/config.d/<hostname>`:
```
Host myserver
    HostName server.example.com
    Port 22
    User root
    IdentityFile ~/.ssh/keys/myserver
```

## Integration

SSH configurations created here integrate seamlessly with:
- `ns mount <system>` - Uses SSH config for remote mounting
- `ns status <remote-system>` - Remote status checking
- Standard SSH commands - All configs work with ssh/scp/rsync

## Related Commands
- `ns mount <system>` - Mount configured SSH systems
- `ns status` - Check status of SSH-accessible systems