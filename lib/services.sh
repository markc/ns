# Created: 20250721 - Updated: 20250721
# Copyright (C) 1995-2025 Mark Constable <markc@renta.net> (MIT License)
# Service management functions for NetServa

# Service status checking
services_status() {
    local target="${1:-}"
    local show_all=0
    local show_services=0
    local show_containers=0

    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
        -a | --all)
            show_all=1
            shift
            ;;
        -s | --services)
            show_services=1
            shift
            ;;
        -c | --containers)
            show_containers=1
            shift
            ;;
        -*)
            warn "Unknown option: $1"
            shift
            ;;
        *)
            target="$1"
            shift
            ;;
        esac
    done

    info "Checking system status..."

    # Show specific target status
    if [[ -n "$target" ]]; then
        _services_check_target "$target"
        return $?
    fi

    # Show all or specific categories
    if [[ $show_all -eq 1 ]] || [[ $show_services -eq 1 ]] || [[ $show_all -eq 0 && $show_containers -eq 0 ]]; then
        _services_show_system_services
    fi

    if [[ $show_all -eq 1 ]] || [[ $show_containers -eq 1 ]]; then
        _services_show_containers
    fi

    if [[ $show_all -eq 1 ]]; then
        _services_show_system_info
    fi
}

# Service control (start/stop/restart)
services_control() {
    local action="$1"
    shift
    local target="${1:-}"
    local force=0
    local wait_completion=0

    [[ -z "$target" ]] && error "No target specified for $action"

    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
        -f | --force)
            force=1
            shift
            ;;
        -w | --wait)
            wait_completion=1
            shift
            ;;
        -*)
            warn "Unknown option: $1"
            shift
            ;;
        *)
            target="$1"
            shift
            ;;
        esac
    done

    info "Attempting to $action $target..."

    if [[ $DRY_RUN -eq 1 ]]; then
        info "DRY RUN: Would $action $target"
        return 0
    fi

    # Determine target type and execute action
    if _services_is_service "$target"; then
        _services_service_control "$action" "$target" "$force"
    elif _services_is_container "$target"; then
        _services_container_control "$action" "$target" "$force"
    else
        error "Unknown target: $target"
    fi

    # Wait for completion if requested
    if [[ $wait_completion -eq 1 ]]; then
        _services_wait_for_status "$target" "$action"
    fi
}

# Check if target is a service (using existing sc function)
_services_is_service() {
    local service="$1"

    # Use the existing sc() function which is OS-aware
    if [[ $OSTYP == openwrt ]]; then
        # OpenWrt: check if service exists in init.d
        [[ -f "/etc/init.d/$service" ]]
    elif [[ $OSTYP == alpine ]]; then
        # Alpine: check OpenRC services
        rc-service "$service" status >/dev/null 2>&1
        return $?
    else
        # SystemD systems
        systemctl list-unit-files --type=service 2>/dev/null | grep -q "^${service}.service"
    fi
}

# Check if target is a container
_services_is_container() {
    local container="$1"
    # Check if incus/lxc command is available and container exists
    if command -v incus >/dev/null 2>&1; then
        incus list --format csv 2>/dev/null | cut -d, -f1 | grep -q "^$container$"
    elif command -v lxc >/dev/null 2>&1; then
        lxc list --format csv 2>/dev/null | cut -d, -f1 | grep -q "^$container$"
    else
        return 1
    fi
}

# Service control using existing sc() function
_services_service_control() {
    local action="$1"
    local service="$2"
    local force="$3"

    # Use the existing sc() function which handles all OS types
    case $action in
    start | stop | restart)
        if sc "$action" "$service"; then
            info "Successfully ${action}ed service: $service"
        else
            error "Failed to $action service: $service"
        fi
        ;;
    *)
        error "Unknown action: $action"
        ;;
    esac
}

# Container control
_services_container_control() {
    local action="$1"
    local container="$2"
    local force="$3"

    local cmd=""
    if command -v incus >/dev/null 2>&1; then
        cmd="incus"
    elif command -v lxc >/dev/null 2>&1; then
        cmd="lxc"
    else
        error "No container management command available (incus/lxc)"
    fi

    case $action in
    start)
        $cmd start "$container"
        info "Started container: $container"
        ;;
    stop)
        if [[ $force -eq 1 ]]; then
            $cmd stop "$container" --force
        else
            $cmd stop "$container"
        fi
        info "Stopped container: $container"
        ;;
    restart)
        $cmd restart "$container"
        info "Restarted container: $container"
        ;;
    *)
        error "Unknown action: $action"
        ;;
    esac
}

# Check specific target status
_services_check_target() {
    local target="$1"

    if _services_is_service "$target"; then
        echo "Service Status for: $target"
        # Use sc() function for status checking
        sc status "$target"
    elif _services_is_container "$target"; then
        echo "Container Status for: $target"
        if command -v incus >/dev/null 2>&1; then
            incus info "$target"
        elif command -v lxc >/dev/null 2>&1; then
            lxc info "$target"
        fi
    else
        warn "Target not found: $target"
        return 1
    fi
}

# Show system services status
_services_show_system_services() {
    echo -e "\n${BOLD}System Services:${NC}"

    # Common services to check
    local services=("nginx" "apache2" "postfix" "dovecot" "mysql" "mariadb" "postgresql" "redis" "ssh" "sshd")

    for service in "${services[@]}"; do
        if _services_is_service "$service"; then
            # Get status using sc() function which is OS-aware
            if [[ $OSTYP == openwrt ]]; then
                # OpenWrt format
                if /etc/init.d/"$service" enabled 2>/dev/null; then
                    echo -e "  ${GREEN}●${NC} $service (enabled)"
                else
                    echo -e "  ${YELLOW}●${NC} $service (available)"
                fi
            elif [[ $OSTYP == alpine ]]; then
                # Alpine/OpenRC format
                local status=$(rc-service "$service" status 2>/dev/null | grep -o "started\|stopped\|inactive" || echo "unknown")
                case $status in
                started)
                    echo -e "  ${GREEN}●${NC} $service ($status)"
                    ;;
                stopped)
                    echo -e "  ${YELLOW}●${NC} $service ($status)"
                    ;;
                *)
                    echo -e "  ${RED}●${NC} $service ($status)"
                    ;;
                esac
            else
                # SystemD format
                local status=$(systemctl is-active "$service" 2>/dev/null || echo "inactive")
                local enabled=$(systemctl is-enabled "$service" 2>/dev/null || echo "disabled")

                case $status in
                active)
                    echo -e "  ${GREEN}●${NC} $service ($status, $enabled)"
                    ;;
                failed)
                    echo -e "  ${RED}●${NC} $service ($status, $enabled)"
                    ;;
                *)
                    echo -e "  ${YELLOW}●${NC} $service ($status, $enabled)"
                    ;;
                esac
            fi
        fi
    done
}

# Show containers status
_services_show_containers() {
    echo -e "\n${BOLD}Containers:${NC}"

    if command -v incus >/dev/null 2>&1; then
        incus list --format table
    elif command -v lxc >/dev/null 2>&1; then
        lxc list --format table
    else
        echo "  No container management available"
    fi
}

# Show system information
_services_show_system_info() {
    echo -e "\n${BOLD}System Information:${NC}"
    echo "  Hostname: $(hostname -f)"
    echo "  Uptime: $(uptime -p 2>/dev/null || uptime)"
    echo "  Load: $(cat /proc/loadavg 2>/dev/null | awk '{print $1, $2, $3}')"
    echo "  Memory: $(free -h 2>/dev/null | awk '/^Mem:/ {print $3 "/" $2 " (" $3/$2*100 "%)"}' || echo "N/A")"
    echo "  Disk: $(df -h / 2>/dev/null | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')"
}

# Wait for service/container to reach expected status
_services_wait_for_status() {
    local target="$1"
    local action="$2"
    local timeout=30
    local count=0

    info "Waiting for $target to complete $action..."

    while [[ $count -lt $timeout ]]; do
        if _services_is_systemd_service "$target"; then
            local status=$(systemctl is-active "$target" 2>/dev/null || echo "inactive")
            case $action in
            start)
                [[ "$status" == "active" ]] && {
                    info "Service is active"
                    return 0
                }
                ;;
            stop)
                [[ "$status" == "inactive" ]] && {
                    info "Service is inactive"
                    return 0
                }
                ;;
            esac
        elif _services_is_container "$target"; then
            local cmd=""
            if command -v incus >/dev/null 2>&1; then
                cmd="incus"
            elif command -v lxc >/dev/null 2>&1; then
                cmd="lxc"
            fi

            local status=$($cmd list --format csv 2>/dev/null | grep "^$target," | cut -d, -f3)
            case $action in
            start)
                [[ "$status" == "RUNNING" ]] && {
                    info "Container is running"
                    return 0
                }
                ;;
            stop)
                [[ "$status" == "STOPPED" ]] && {
                    info "Container is stopped"
                    return 0
                }
                ;;
            esac
        fi

        sleep 1
        ((count++))
    done

    warn "Timeout waiting for $target to complete $action"
    return 1
}
