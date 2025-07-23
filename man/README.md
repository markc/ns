# NetServa Command Reference (man/)

This directory contains the manual pages for all NetServa commands. These files are displayed when you use `ns help <command>`.

## 📖 Command Reference Index

### Core Commands
- [**ns**](ns.md) - Main help and quick start guide
- [**setup**](setup.md) - Initialize and configure NetServa system
- [**status**](status.md) - Show system, service, and container status

### Service Management
- [**start**](start.md) - Start services, containers, or VMs
- [**stop**](stop.md) → *links to start.md* - Stop services, containers, or VMs
- [**restart**](restart.md) → *links to start.md* - Restart services, containers, or VMs

### Mount Operations
- [**mount**](mount.md) - Mount containers or remote systems via SSHFS
- [**unmount**](unmount.md) - Unmount previously mounted systems
- [**remount**](remount.md) - Refresh mount connections
- [**mounts**](mounts.md) - List currently mounted systems
- [**list-mounts**](list-mounts.md) → *links to mounts.md* - Alternative command name

### System Administration
- [**ssh**](ssh.md) - SSH key and host management
- [**security**](security.md) - Security scanning and auditing

## 🚀 Quick Command Examples

### Getting Started
```bash
# Show main help
ns help

# Get help for specific command
ns help mount

# Initialize system
ns setup --host mail.example.com
```

### Daily Operations
```bash
# Check system status
ns status --all

# Mount a container
ns mount mycontainer

# List mounted systems
ns mounts

# Manage services
ns start nginx
ns restart mysql
ns stop postfix
```

### Security & SSH
```bash
# Quick security scan
ns security scan mail.example.com

# Create SSH host config
ns ssh create myserver server.com

# List SSH hosts
ns ssh list
```

## 📚 Using the Help System

### With Glow (Recommended)
If you have `glow` installed, help pages are automatically rendered with beautiful formatting:
```bash
ns help mount         # Renders with glow
glow man/mount.md     # Direct glow rendering
```

### Without Glow
Help pages are still readable as plain markdown:
```bash
ns help mount         # Falls back to cat
cat man/mount.md      # Direct viewing
```

## 🔗 Related Documentation

### Technical Guides
For in-depth technical documentation, see the [**doc/ directory**](../doc/README.md):
- Deployment guides
- Configuration tutorials  
- Security documentation
- Development plans

### Adding New Commands
When adding a new command to NetServa:
1. Create a markdown file: `man/commandname.md`
2. Follow the existing format structure
3. Add entry to this README.md
4. Test with: `ns help commandname`

## 📝 Manual Page Format

All manual pages follow this structure:
```markdown
# NetServa [Command] Command

## Usage
`command syntax`

## Description
Brief description

## Options
- Option descriptions

## Examples
Code examples

## Related Commands
Cross-references
```

---

[**Back to Main**](../README.md) | [**Technical Documentation**](../doc/README.md)