# Created: 20250721 - Updated: 20250721
# Copyright (C) 1995-2025 Mark Constable <markc@renta.net> (MIT License)
# Network and SSH mounting functions for NetServa

# Mount remote server via SSH
network_mount() {
    local hostname=""
    local mount_path=""
    local ssh_user="root"

    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
        -p | --path)
            mount_path="$2"
            shift 2
            ;;
        -u | --user)
            ssh_user="$2"
            shift 2
            ;;
        -*)
            warn "Unknown option: $1"
            shift
            ;;
        *)
            hostname="$1"
            shift
            ;;
        esac
    done

    [[ -z "$hostname" ]] && error "No hostname specified for mounting"

    # Set default mount path if not specified
    if [[ -z "$mount_path" ]]; then
        mount_path="$(dirname "$SCRIPT_DIR")/mnt/$hostname"
    fi

    info "Mounting $hostname to $mount_path (user: $ssh_user)"

    if [[ $DRY_RUN -eq 1 ]]; then
        info "DRY RUN: Would mount $hostname:/ to $mount_path"
        return 0
    fi

    # Use existing mount-system script if available
    if [[ -x "$SCRIPT_DIR/mount-system" ]]; then
        "$SCRIPT_DIR/mount-system" "$hostname"
    else
        _network_mount_sshfs "$hostname" "$mount_path" "$ssh_user"
    fi
}

# Unmount remote server
network_unmount() {
    local hostname=""
    local mount_path=""

    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
        -p | --path)
            mount_path="$2"
            shift 2
            ;;
        -*)
            warn "Unknown option: $1"
            shift
            ;;
        *)
            hostname="$1"
            shift
            ;;
        esac
    done

    [[ -z "$hostname" ]] && error "No hostname specified for unmounting"

    # Set default mount path if not specified
    if [[ -z "$mount_path" ]]; then
        mount_path="$(dirname "$SCRIPT_DIR")/mnt/$hostname"
    fi

    info "Unmounting $hostname from $mount_path"

    if [[ $DRY_RUN -eq 1 ]]; then
        info "DRY RUN: Would unmount $mount_path"
        return 0
    fi

    # Use existing unmount-container script if available
    if [[ -x "$SCRIPT_DIR/unmount-container" ]]; then
        "$SCRIPT_DIR/unmount-container" "$hostname"
    else
        _network_unmount_sshfs "$mount_path"
    fi
}

# Internal SSHFS mounting function
_network_mount_sshfs() {
    local hostname="$1"
    local mount_path="$2"
    local ssh_user="$3"

    # Check if sshfs is available
    if ! command -v sshfs >/dev/null 2>&1; then
        error "sshfs is required for mounting remote filesystems"
    fi

    # Create mount directory if it doesn't exist
    if [[ ! -d "$mount_path" ]]; then
        mkdir -p "$mount_path"
        debug "Created mount directory: $mount_path"
    fi

    # Check if already mounted
    if mountpoint -q "$mount_path" 2>/dev/null; then
        warn "Path is already mounted: $mount_path"
        return 0
    fi

    # Check SSH connectivity
    if ! ssh -o ConnectTimeout=5 -o BatchMode=yes "$ssh_user@$hostname" exit 2>/dev/null; then
        error "Cannot connect to $ssh_user@$hostname via SSH"
    fi

    # Mount with SSHFS
    local sshfs_opts="idmap=user,allow_other,reconnect,ServerAliveInterval=15,ServerAliveCountMax=3"

    if sshfs "$ssh_user@$hostname:/" "$mount_path" -o "$sshfs_opts"; then
        info "Successfully mounted $hostname at $mount_path"
    else
        error "Failed to mount $hostname"
    fi
}

# Internal SSHFS unmounting function
_network_unmount_sshfs() {
    local mount_path="$1"

    # Check if path is mounted
    if ! mountpoint -q "$mount_path" 2>/dev/null; then
        warn "Path is not mounted: $mount_path"
        return 0
    fi

    # Unmount
    if fusermount -u "$mount_path" 2>/dev/null || umount "$mount_path" 2>/dev/null; then
        info "Successfully unmounted $mount_path"
    else
        warn "Failed to unmount $mount_path, trying force unmount..."
        if fusermount -uz "$mount_path" 2>/dev/null || umount -f "$mount_path" 2>/dev/null; then
            info "Force unmount successful"
        else
            error "Failed to unmount $mount_path"
        fi
    fi
}

# List mounted remote systems
network_list_mounts() {
    local mnt_dir="$(dirname "$SCRIPT_DIR")/mnt"

    info "Mounted remote systems:"

    if [[ ! -d "$mnt_dir" ]]; then
        info "No mount directory found at $mnt_dir"
        return 0
    fi

    local found_mounts=0

    for mount_dir in "$mnt_dir"/*; do
        if [[ -d "$mount_dir" ]]; then
            local hostname=$(basename "$mount_dir")
            if mountpoint -q "$mount_dir" 2>/dev/null; then
                echo -e "  ${GREEN}●${NC} $hostname (mounted at $mount_dir)"
                found_mounts=1
            else
                echo -e "  ${YELLOW}○${NC} $hostname (directory exists but not mounted)"
            fi
        fi
    done

    if [[ $found_mounts -eq 0 ]]; then
        info "No active mounts found"
    fi
}

# Test SSH connectivity to a host
network_test_ssh() {
    local hostname="$1"
    local ssh_user="${2:-root}"
    local timeout="${3:-5}"

    [[ -z "$hostname" ]] && error "No hostname specified for SSH test"

    info "Testing SSH connectivity to $ssh_user@$hostname..."

    if ssh -o ConnectTimeout="$timeout" -o BatchMode=yes "$ssh_user@$hostname" exit 2>/dev/null; then
        info "✓ SSH connection successful"
        return 0
    else
        warn "✗ SSH connection failed"
        return 1
    fi
}

# Check network connectivity
network_check_connectivity() {
    local host="${1:-8.8.8.8}"
    local timeout="${2:-3}"

    info "Checking network connectivity to $host..."

    if ping -c 1 -W "$timeout" "$host" >/dev/null 2>&1; then
        info "✓ Network connectivity OK"
        return 0
    else
        warn "✗ Network connectivity failed"
        return 1
    fi
}

# Show network interface information
network_show_interfaces() {
    info "Network interfaces:"

    if command -v ip >/dev/null 2>&1; then
        ip -br addr show | while read -r interface flags addr; do
            case $flags in
            *UP*)
                echo -e "  ${GREEN}●${NC} $interface: $addr"
                ;;
            *)
                echo -e "  ${YELLOW}○${NC} $interface: $addr"
                ;;
            esac
        done
    else
        # Fallback to ifconfig if available
        if command -v ifconfig >/dev/null 2>&1; then
            ifconfig | grep -E "^[a-z]|inet " | awk '
                /^[a-z]/ { iface=$1 }
                /inet / { print "  " iface ": " $2 }
            '
        else
            warn "No network interface command available (ip/ifconfig)"
        fi
    fi
}
