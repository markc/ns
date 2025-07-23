# Created: 20130315 - Updated: 20250721
# Copyright (C) 2015-2025 Mark Constable <mc@netserva.org> (MIT License)
# NetServa master environment and library loader

# Detect OS type and architecture
detect_os() {
    local uname_s=$(uname -s | tr 'A-Z' 'a-z')
    local uname_m=$(uname -m)

    # Enhanced OS detection
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        case "${ID:-}" in
        alpine | debian | ubuntu | cachyos | manjaro | arch | openwrt)
            OSTYP="$ID"
            ;;
        *)
            # Fallback to ID_LIKE if available
            case "${ID_LIKE:-}" in
            *debian*) OSTYP="debian" ;;
            *arch*) OSTYP="arch" ;;
            *) OSTYP="${ID:-$uname_s}" ;;
            esac
            ;;
        esac
    elif [[ -f /etc/openwrt_release ]]; then
        OSTYP="openwrt"
    elif [[ "$uname_s" == "darwin" ]]; then
        OSTYP="macos"
    else
        OSTYP="$uname_s"
    fi

    # Set architecture
    case "$uname_m" in
    x86_64 | amd64) ARCH="x86_64" ;;
    aarch64 | arm64) ARCH="arm64" ;;
    armv7l | armhf) ARCH="armv7" ;;
    *) ARCH="$uname_m" ;;
    esac

    export OSTYP ARCH
}

# Set NetServa paths
set_netserva_paths() {
    # Determine NetServa root directory
    if [[ -n "${NSDIR:-}" ]]; then
        NSDIR="$NSDIR"
    elif [[ -f "$HOME/.ns/lib/nsrc.sh" ]]; then
        NSDIR="$HOME/.ns"
    elif [[ -f "./lib/nsrc.sh" ]]; then
        NSDIR="$(pwd)"
    elif [[ -f "../lib/nsrc.sh" ]]; then
        NSDIR="$(cd .. && pwd)"
    else
        # Search common locations
        local search_paths=("$HOME/Dev/ns" "$HOME/.ns" "/opt/netserva" "/usr/local/netserva")
        for path in "${search_paths[@]}"; do
            if [[ -f "$path/lib/nsrc.sh" ]]; then
                NSDIR="$path"
                break
            fi
        done
        NSDIR="${NSDIR:-$HOME/.ns}"
    fi

    # Set NetServa paths (5 char uppercase convention)
    # This provides consistent paths for all NetServa operations
    # Both in development (/home/user/Dev/ns) and deployed (/.ns) environments
    NSBIN="$NSDIR/bin"
    NSLIB="$NSDIR/lib"
    NSETC="$NSDIR/etc"
    NSDOC="$NSDIR/doc"
    NSTMP="$NSDIR/tmp"
    NSMNT="$NSDIR/mnt"
    NSMAN="$NSDIR/man"

    export NSDIR NSBIN NSLIB NSETC NSDOC NSTMP NSMNT NSMAN
}

# Initialize environment
detect_os
set_netserva_paths

# Set default values for variables that might be unbound
DEBUG=${DEBUG:-}
VERBOSE=${VERBOSE:-}

# Set up environment variables with proper PATH management
update_path() {
    local new_bin_path="$1"

    # Convert PATH to array and filter out unwanted entries
    local IFS=':'
    local path_array=($PATH)
    local clean_path=""

    for path_entry in "${path_array[@]}"; do
        # Skip if it's a NetServa-related path or empty
        if [[ -n "$path_entry" ]] &&
            [[ "$path_entry" != *"/.sh/bin" ]] &&
            [[ "$path_entry" != *"/Dev/ns/bin" ]] &&
            [[ "$path_entry" != *"/.ns/bin" ]] &&
            [[ "$path_entry" != "$new_bin_path" ]]; then
            if [[ -z "$clean_path" ]]; then
                clean_path="$path_entry"
            else
                clean_path="$clean_path:$path_entry"
            fi
        fi
    done

    # Add new NetServa bin to front of clean PATH
    if [[ -n "$clean_path" ]]; then
        PATH="$new_bin_path:$clean_path"
    else
        PATH="$new_bin_path"
    fi

    export PATH
}

# Update PATH with current NetServa bin (only if not already initialized)
if [[ "${NSRC_INITIALIZED:-}" != "1" ]]; then
    update_path "$NSBIN"
fi
EDITOR=${EDITOR:-nano}
COLOR=${COLOR:-31}

unalias sudo 2>/dev/null || true
SUDO=$([[ $(id -u) -gt 0 ]] && echo '/usr/bin/sudo ')
export SUDO EDITOR PATH

# Import hostname alternative for resolved and openwrt hosts (skip if causing issues)
# [[ -f $NS_LIB/hostname.sh ]] && . $NS_LIB/hostname.sh

LABEL=$(hostname)

# Local custom aliases and env vars
[[ -f ~/.myrc ]] && . ~/.myrc

# Enable tracing of sourced and standalone scripts
if [[ -n "$DEBUG" ]]; then
    set -x
    if [[ -f ~/.bash_debug_init ]]; then
        export BASH_ENV=~/.bash_debug_init
    fi
else
    unset BASH_ENV DEBUG
fi

# Import NetServa libraries with fallback to legacy paths
load_netserva_lib() {
    local lib_name="$1"
    if [[ -f "$NSLIB/$lib_name" ]]; then
        . "$NSLIB/$lib_name"
    elif [[ -f "$HOME/.ns/lib/$lib_name" ]]; then
        . "$HOME/.ns/lib/$lib_name"
    fi
}

# Load core NetServa libraries
load_netserva_lib "aliases.sh"
load_netserva_lib "functions.sh"

_HOST=$(hostname -f | tr 'A-Z' 'a-z')

# Host configuration (temporarily disabled to fix ns help)
# if [[ -f ~/.vhosts/$_HOST ]]; then
#     . ~/.vhosts/$_HOST
# else
#     sethost
# fi

PS1="\[\033[1;${COLOR}m\]${LABEL} \w\[\033[0m\] "

export EDITOR PATH PS1

export ADMIN AHOST AMAIL ANAME APASS A_GID A_UID BPATH CIMAP CSMTP
export C_DNS C_FPM C_SQL C_SSL C_WEB DBMYS DBSQL DHOST DNAME DPASS
export DPATH DPORT DTYPE DUSER EPASS EXMYS EXSQL HNAME HDOMN IP4_0
export LROOT MHOST MPATH OSMIR OSREL OSTYP SQCMD SQDNS TAREA TCITY
export UPASS UPATH UUSER U_GID U_SHL U_UID VHOST VPATH VUSER V_PHP
export WPASS WPATH WPUSR WUGID
# Export commonly used runtime functions
export -f chktime f getdb getuser getusers go2 grepuser sc sx
export -f detect_os set_netserva_paths load_netserva_lib update_path

# Setup functions (sethost, gethost, newuid, setuser) are in lib/setup_core.sh
# These are ONLY loaded during 'ns setup' - not during normal runtime

# Note: get_fqdn and hostname functions are in lib/hostname.sh
# They're not exported by default due to unbound variable issues

# Add reload function for es alias compatibility
nsrc_reload() {
    # Re-detect OS and paths
    detect_os
    set_netserva_paths

    # Update PATH with new NetServa bin
    update_path "$NSBIN"

    # Reload libraries
    load_netserva_lib "aliases.sh"
    load_netserva_lib "functions.sh"

    # Re-source host configuration if it exists
    _HOST=$(hostname -f | tr 'A-Z' 'a-z')
    if [[ -f ~/.vhosts/$_HOST ]]; then
        . ~/.vhosts/$_HOST
        echo "Loaded host config for $_HOST"
    else
        echo "No saved host config found for $_HOST (use 'ns setup' to create)"
    fi

    # Source personal config
    [[ -f ~/.myrc ]] && . ~/.myrc

    echo "NetServa environment reloaded (PATH updated)"
}

# Export reload function
export -f nsrc_reload

[[ ${DEBUG:-} ]] && set +x
