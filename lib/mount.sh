# Created: 20250721 - Updated: 20250723
# Copyright (C) 1995-2025 Mark Constable <mc@netserva.org> (MIT License)
# NetServa mounting functions for SSH-accessible systems

# Check if required commands are available
mount_check_dependencies() {
    local missing_deps=()

    for cmd in sshfs fusermount; do
        if ! command -v "$cmd" &>/dev/null; then
            missing_deps+=("$cmd")
        fi
    done

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        error "Missing required commands: ${missing_deps[*]}"
        warn "Install with: $PACKAGE_MANAGER install sshfs"
        return 1
    fi

    return 0
}

# Test SSH connectivity
mount_test_ssh() {
    local hostname="$1"
    local timeout="${2:-5}"

    debug "Testing SSH connection to $hostname"

    if ssh -o ConnectTimeout="$timeout" -o BatchMode=yes "$hostname" true 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Check if system exists in SSH config
mount_check_ssh_host() {
    local system_name="$1"
    
    # Check if it's in SSH config.d directory
    if [[ -f "$HOME/.ssh/config.d/$system_name" ]]; then
        return 0
    fi
    
    # Check if it's in main SSH config
    if [[ -f "$HOME/.ssh/config" ]] && grep -q "^Host $system_name" "$HOME/.ssh/config" 2>/dev/null; then
        return 0
    fi
    
    return 1
}

# Main mount function
mount_system() {
    local system_name=""
    local mount_point=""
    local remote_path="/"
    local show_help=0

    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
        --path | -p)
            mount_point="$2"
            shift 2
            ;;
        --help | -h)
            show_help=1
            shift
            ;;
        -*)
            warn "Unknown option: $1"
            shift
            ;;
        *)
            if [[ -z "$system_name" ]]; then
                system_name="$1"
            elif [[ -z "$remote_path" || "$remote_path" == "/" ]]; then
                remote_path="$1"
            fi
            shift
            ;;
        esac
    done

    # Show help if requested or no system name
    if [[ $show_help -eq 1 || -z "$system_name" ]]; then
        cat <<EOF
Usage: ns mount [OPTIONS] <system-name> [remote-path]

Mount any SSH-accessible system via SSHFS

Options:
  -p, --path PATH       Custom mount point (default: $NSMNT/<system-name>)
  -h, --help            Show this help

Examples:
  ns mount mgo                    # Mount system 'mgo'
  ns mount mko /var/www           # Mount specific path from 'mko'
  ns mount -p /mnt/custom mko     # Use custom mount point

Requirements:
  - sshfs package installed
  - SSH host configuration in ~/.ssh/config.d/<system-name>
  - Key-based authentication configured
EOF
        return 0
    fi

    # Check dependencies
    mount_check_dependencies || return 1

    # Set default mount point
    if [[ -z "$mount_point" ]]; then
        mount_point="$NSMNT/$system_name"
    fi

    # Check if already mounted
    if mountpoint -q "$mount_point" 2>/dev/null; then
        info "System '$system_name' already mounted at $mount_point"
        df -h "$mount_point" 2>/dev/null | tail -1
        return 0
    fi

    # Check if SSH host exists
    if ! mount_check_ssh_host "$system_name"; then
        error "SSH host '$system_name' not found"
        warn "Add SSH configuration with: sshm create $system_name <hostname>"
        warn "Or create config file at: ~/.ssh/config.d/$system_name"
        return 1
    fi

    # Test SSH connection
    info "Testing SSH connection to $system_name..."
    if ! mount_test_ssh "$system_name"; then
        error "Cannot connect to $system_name via SSH"
        warn "Check SSH config, network connectivity, and key authentication"
        warn "Test with: ssh $system_name"
        return 1
    fi

    # Get remote system info
    local remote_info
    remote_info=$(ssh "$system_name" "hostname && uname -s" 2>/dev/null)
    if [[ $? -eq 0 ]]; then
        info "Connected to: $(echo "$remote_info" | head -1) ($(echo "$remote_info" | tail -1))"
    fi

    # Check if remote path exists
    if ! ssh "$system_name" "[[ -d '$remote_path' ]]" 2>/dev/null; then
        error "Remote path '$remote_path' does not exist on $system_name"
        return 1
    fi

    # Create mount point
    mkdir -p "$mount_point"

    # Mount with optimal SSHFS options
    info "Mounting $system_name:$remote_path to $mount_point"

    local sshfs_opts=(
        "-o" "allow_other,default_permissions,follow_symlinks,reconnect"
        "-o" "ServerAliveInterval=15,ServerAliveCountMax=3"
        "-o" "idmap=user,uid=$(id -u),gid=$(id -g)"
        "-o" "cache=yes,cache_timeout=115200,attr_timeout=115200"
    )

    if sshfs "$system_name:$remote_path" "$mount_point" "${sshfs_opts[@]}"; then
        info "Successfully mounted $system_name"
        df -h "$mount_point" 2>/dev/null | tail -1
        
        info "Usage tips:"
        info "  Browse: cd $mount_point"
        info "  Unmount: ns unmount $system_name"
        info "  Files are cached locally for faster access"
        return 0
    else
        error "Failed to mount $system_name"
        rmdir "$mount_point" 2>/dev/null
        return 1
    fi
}

# Unmount system
mount_unmount() {
    local system_name=""
    local mount_point=""
    local force=0
    local show_help=0

    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
        --path | -p)
            mount_point="$2"
            shift 2
            ;;
        --force | -f)
            force=1
            shift
            ;;
        --help | -h)
            show_help=1
            shift
            ;;
        -*)
            warn "Unknown option: $1"
            shift
            ;;
        *)
            system_name="$1"
            shift
            ;;
        esac
    done

    # Show help if requested or no system name
    if [[ $show_help -eq 1 || -z "$system_name" ]]; then
        cat <<EOF
Usage: ns unmount [OPTIONS] <system-name>

Unmount previously mounted systems

Options:
  -p, --path PATH    Custom mount point (default: $NSMNT/<system-name>)
  -f, --force        Force unmount
  -h, --help         Show this help

Examples:
  ns unmount mgo              # Unmount system
  ns unmount -f mko           # Force unmount
  ns unmount -p /mnt/custom   # Unmount custom mount point
EOF
        return 0
    fi

    # Set default mount point
    if [[ -z "$mount_point" ]]; then
        mount_point="$NSMNT/$system_name"
    fi

    # Check if mount point exists
    if [[ ! -d "$mount_point" ]]; then
        warn "Mount point does not exist: $mount_point"
        return 1
    fi

    # Check if mounted
    if ! mountpoint -q "$mount_point" 2>/dev/null; then
        info "System '$system_name' is not currently mounted"
        return 0
    fi

    info "Unmounting $system_name from $mount_point"

    # Try normal unmount first
    if fusermount -u "$mount_point" 2>/dev/null || umount "$mount_point" 2>/dev/null; then
        info "Successfully unmounted $system_name"
        # Remove empty mount directory
        rmdir "$mount_point" 2>/dev/null
        return 0
    elif [[ $force -eq 1 ]]; then
        warn "Normal unmount failed, trying force unmount"
        if fusermount -uz "$mount_point" 2>/dev/null || umount -f "$mount_point" 2>/dev/null; then
            info "Force unmount successful"
            rmdir "$mount_point" 2>/dev/null
            return 0
        else
            error "Force unmount failed"
            return 1
        fi
    else
        error "Unmount failed"
        warn "Use --force option to try force unmount"
        return 1
    fi
}

# Remount system (unmount then mount)
mount_remount() {
    local system_name=""
    local show_help=0
    local mount_args=()

    # Parse options and collect arguments for mount
    while [[ $# -gt 0 ]]; do
        case $1 in
        --help | -h)
            show_help=1
            shift
            ;;
        *)
            if [[ -z "$system_name" ]]; then
                system_name="$1"
            fi
            mount_args+=("$1")
            shift
            ;;
        esac
    done

    # Show help if requested or no system name
    if [[ $show_help -eq 1 || -z "$system_name" ]]; then
        cat <<EOF
Usage: ns remount [OPTIONS] <system-name> [mount-options...]

Unmount and remount a system (useful for refreshing connections)

This command first unmounts the system, waits briefly, then mounts it again
with the same or updated options.

Examples:
  ns remount mgo                    # Simple remount
  ns remount mko /var/www           # Remount with different path
  ns remount -p /mnt/custom mko     # Remount with custom mount point
EOF
        return 0
    fi

    info "Remounting system: $system_name"

    # Unmount first (ignore errors if not mounted)
    mount_unmount "$system_name" 2>/dev/null || true

    # Wait a moment for cleanup
    sleep 2

    # Mount again with original arguments
    mount_system "${mount_args[@]}"
}

# List mounted systems
mount_list() {
    info "Mounted NetServa systems:"

    if [[ ! -d "$NSMNT" ]]; then
        info "No mount directory found at $NSMNT"
        return 0
    fi

    local found_mounts=0

    for mount_dir in "$NSMNT"/*; do
        if [[ -d "$mount_dir" ]]; then
            local system_name=$(basename "$mount_dir")
            if mountpoint -q "$mount_dir" 2>/dev/null; then
                local mount_info=$(df -h "$mount_dir" 2>/dev/null | tail -1)
                echo -e "  ${GREEN}●${NC} $system_name"
                echo "    Location: $mount_dir"
                echo "    Space: $(echo "$mount_info" | awk '{print $3 "/" $2 " (" $5 " used)"}')"
                found_mounts=1
            else
                echo -e "  ${YELLOW}○${NC} $system_name (directory exists but not mounted)"
            fi
        fi
    done

    if [[ $found_mounts -eq 0 ]]; then
        info "No systems currently mounted"
        info "Use 'ns mount <system-name>' to mount a system"
    fi
}

# Export functions
export -f mount_check_dependencies mount_test_ssh mount_check_ssh_host
export -f mount_system mount_unmount mount_remount mount_list