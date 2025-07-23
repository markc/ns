# NetServa Architecture Plan

## Overview
Create a unified command-line interface through `bin/ns` that serves as the main entry point for all NetServa operations. This master script will delegate to modular functions in `lib/` for maintainability and reusability.

## Command Structure

### Primary Commands
- `ns setup [options]` - Initial system setup and configuration
- `ns status [target]` - Show status of services, containers, VMs
- `ns start <service|container|vm>` - Start services/containers/VMs
- `ns stop <service|container|vm>` - Stop services/containers/VMs
- `ns restart <service|container|vm>` - Restart services/containers/VMs
- `ns mount <hostname>` - Mount remote server via SSH
- `ns unmount <hostname>` - Unmount remote server
- `ns deploy [target]` - Deploy configurations to target systems
- `ns backup [target]` - Backup data/configurations
- `ns restore <backup>` - Restore from backup
- `ns security [scan|check|audit]` - Security operations
- `ns logs <target>` - View logs for services/containers
- `ns config <action> [target]` - Configuration management
- `ns ssh <action> [args]` - SSH key and host management (delegate to sshm)

### Secondary Commands
- `ns update` - Update NetServa system
- `ns version` - Show version information
- `ns help [command]` - Show help for specific command

## Library Organization

### Core Libraries
- `lib/netserva.sh` - Global configuration and constants
- `lib/functions.sh` - Common utility functions
- `lib/setup.sh` - System setup and initialization functions
- `lib/services.sh` - Service management (start/stop/status)
- `lib/containers.sh` - LXC container operations
- `lib/virtual.sh` - VM and VPS management
- `lib/network.sh` - Network and mounting operations
- `lib/security.sh` - Security and TLS functions
- `lib/backup.sh` - Backup and restore operations
- `lib/deploy.sh` - Deployment functions
- `lib/logging.sh` - Logging and monitoring functions

### Function Naming Convention
- Functions prefixed with library name: `setup_system()`, `services_start()`, `containers_list()`
- Private/helper functions prefixed with underscore: `_setup_validate_deps()`
- Error handling functions: `error()`, `warn()`, `info()`

## Implementation Strategy

### Phase 1: Core Infrastructure
1. Create `bin/ns` with argument parsing and command routing
2. Refactor existing functions into appropriate lib files
3. Implement error handling and logging framework
4. Create help system and documentation

### Phase 2: Service Integration
1. Integrate existing standalone scripts as subcommands
2. Standardize configuration management
3. Implement unified status reporting
4. Add backup/restore functionality

### Phase 3: Advanced Features
1. Remote deployment capabilities
2. Automated monitoring and alerting
3. Web interface integration
4. Container orchestration features

## File Structure Changes

### New Files
```
bin/ns                    # Master command script
lib/setup.sh             # Setup functions
lib/services.sh          # Service management
lib/containers.sh        # Container operations
lib/virtual.sh           # VM/VPS management
lib/network.sh           # Network and SSH mounting
lib/security.sh          # Security functions
lib/backup.sh            # Backup operations
lib/deploy.sh            # Deployment functions
lib/logging.sh           # Logging utilities
```

### Existing Files (to be refactored)
- `bin/sshm` → integrate into `ns ssh` subcommand
- `bin/tls-*` → integrate into `ns security` subcommand
- `bin/mount*` → integrate into `ns mount/unmount` subcommands
- Various utility functions → move to appropriate lib files

## Configuration Management

### Environment Variables
- Use `lib/netserva.sh` for global settings
- Support per-host configuration files
- Environment file precedence: `~/.ns/config` > `./config` > defaults

### Runtime Configuration
- Dynamic host detection via `sethost()` function
- OS-specific configuration overrides
- Service-specific settings management

## Error Handling & Logging

### Exit Codes
- 0: Success
- 1-250: General errors
- 251: Success with alert
- 252: Info message
- 253: Warning
- 254: Warning with empty content
- 255: Error with empty content

### Logging Levels
- ERROR: Critical issues requiring immediate attention
- WARN: Non-critical issues that should be reviewed
- INFO: General operational messages
- DEBUG: Detailed diagnostic information

## Security Considerations

### Privilege Management
- Run with minimum required privileges
- Escalate to root only when necessary using `sudo`
- Validate all user inputs

### Credential Handling
- Never store passwords in plain text
- Use SSH keys for authentication
- Generate secure random passwords via `/dev/urandom`

### File Permissions
- Maintain strict permissions on SSH keys (600/700)
- Secure configuration files appropriately
- Validate file ownership before operations

## Testing Strategy

### Unit Testing
- Test individual library functions
- Mock external dependencies
- Validate error handling paths

### Integration Testing
- Test command-line interface
- Verify cross-platform compatibility
- Test real service interactions

### Security Testing
- Validate input sanitization
- Test privilege escalation
- Verify credential handling