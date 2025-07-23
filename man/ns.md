# NetServa - Server Management System

## Quick Start

NetServa is a server management system for VMs, LXC Containers, and VPS servers.

### Basic Usage
```
ns <command> [options] [arguments]
```

### Most Common Commands
```
ns help                    # Show this help
ns help <command>          # Show detailed help for a command
ns doc                     # Browse documentation interactively
ns status                  # Check system status  
ns mount <system>          # Mount a container/remote system
ns mounts                  # List mounted systems
ns ssh list                # List SSH configurations
```

### Essential Examples
```
# Get detailed help for any command
ns help mount
ns help status

# Check what's running
ns status --all

# Mount a local container
ns mount mgo

# Mount a remote system
ns mount myserver

# See what's mounted
ns mounts

# SSH management
ns ssh list
ns ssh create myserver server.example.com
```

### Available Commands
To see all available commands with descriptions, run:
```
ns help
```

### Getting Started
1. Initialize SSH if needed: `ns ssh init`
2. Check system status: `ns status`
3. List existing mounts: `ns mounts`
4. Get help on any command: `ns help <command>`

For detailed documentation, see the man/ directory or use `ns help <command>`.