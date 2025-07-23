# Created: 20250721 - Updated: 20250721
# Copyright (C) 1995-2025 Mark Constable <mc@netserva.org> (MIT License)
# NetServa setup and initialization module

# Load core setup functions (sethost, gethost, etc) only when needed
# Use absolute path based on this script's location
SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SETUP_DIR/setup_core.sh" ]]; then
    source "$SETUP_DIR/setup_core.sh"
else
    echo "Error: Could not find setup_core.sh in $SETUP_DIR" >&2
    return 1
fi

# Main setup function called by 'ns setup'
setup_main() {
    local host=""
    local system_type=""
    local database_type=""
    local dry_run=0

    # Parse setup-specific options
    while [[ ${#} -gt 0 ]]; do
        case ${1:-} in
        -h | --host)
            host="${2:-}"
            shift 2
            ;;
        -t | --type)
            system_type="${2:-}"
            shift 2
            ;;
        -d | --database)
            database_type="${2:-}"
            shift 2
            ;;
        --dry-run)
            dry_run=1
            shift
            ;;
        --help)
            setup_show_help
            return 0
            ;;
        *)
            warn "Unknown setup option: ${1:-}"
            setup_show_help
            return 1
            ;;
        esac
    done

    info "Starting NetServa system setup..."

    # Set environment variables based on parameters
    [[ -n "$database_type" ]] && DTYPE="$database_type"
    [[ -n "$system_type" ]] && info "System type: $system_type"

    if [[ $dry_run -eq 1 ]]; then
        info "DRY RUN MODE - No changes will be made"
        setup_show_config "$host"
        return 0
    fi

    # Run actual setup
    setup_host_environment "$host"
    setup_create_directories
    setup_save_configuration

    info "NetServa setup completed successfully"
    exit 251 # Success with 'success' alert
}

# Show what configuration would be set
setup_show_config() {
    local host=${1:-$(hostname -f)}

    echo "Configuration that would be set for host: $host"
    echo "=============================================="

    # Temporarily set up environment to show what would be configured
    local saved_vhost="$VHOST"
    sethost "$host" >/dev/null 2>&1

    echo "Primary Domain: $VHOST"
    echo "Admin User: $ADMIN ($A_UID:$A_GID)"
    echo "Virtual User: $UUSER ($U_UID:$U_GID)"
    echo "Database Type: $DTYPE"
    echo "Web Path: $WPATH"
    echo "Mail Host: $MHOST"
    echo "OS Type: $OSTYP"
    echo "PHP Version: $V_PHP"

    # Restore original VHOST
    VHOST="$saved_vhost"
}

# Set up host environment variables
setup_host_environment() {
    local host="${1:-}"

    info "Configuring host environment..."

    # Load setup functions and run sethost
    sethost "$host"

    info "Host environment configured for: $VHOST"
    debug "Admin: $ADMIN, Virtual User: $UUSER"
}

# Create necessary directories
setup_create_directories() {
    info "Creating directory structure..."

    local dirs=(
        "$VPATH"
        "$BPATH"
        "$HOME/.vhosts"
        "$NSTMP"
    )

    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            debug "Creating directory: $dir"
            mkdir -p "$dir" || warn "Failed to create directory: $dir"
        fi
    done
}

# Save configuration for future use
setup_save_configuration() {
    info "Saving host configuration..."

    local config_file="$HOME/.vhosts/$VHOST"
    gethost >"$config_file"

    info "Configuration saved to: $config_file"
}

# Show setup help
setup_show_help() {
    cat <<EOF
Usage: ns setup [OPTIONS]

Initialize and configure NetServa system for a host.

Options:
  -h, --host HOSTNAME    Set target hostname (default: current FQDN)
  -t, --type TYPE        System type hint (vm|container|vps)
  -d, --database TYPE    Database type (mysql|sqlite)
  --dry-run              Show what would be configured without making changes
  --help                 Show this help message
  
Examples:
  ns setup                                    # Setup for current host
  ns setup --host mail.example.com           # Setup for specific host
  ns setup --database sqlite --dry-run       # Preview SQLite setup
  ns setup --type container --host test.lan  # Container-specific setup

The setup process will:
1. Configure environment variables for the specified host
2. Create necessary directory structure
3. Save host configuration to ~/.vhosts/ for future use
4. Set up database and service paths based on detected OS

Use --dry-run to preview configuration without making changes.
EOF
}
