# Created: 20151231 - Updated: 20250723
# Copyright (C) 1995-2025 Mark Constable <mc@netserva.org> (MIT License)

f() { find . -type f -iname '*'$*'*'; }

if [[ ${OSTYP:-} == openwrt ]]; then
    sc() { $SUDO /etc/init.d/$2 $1; }
    function getent {
        if [[ $1 == passwd ]]; then
            cat /etc/passwd
        elif [[ $1 == group ]]; then
            cat /etc/group
        fi
        export -f getent
    }
elif [[ ${OSTYP:-} == alpine ]]; then
    sc() {
        # Convert systemd-style service@instance to OpenRC service.instance
        if [[ "$2" == *"@"* ]]; then
            local service_name="${2/@/.}"
        else
            local service_name="$2"
        fi

        # Helper function for WireGuard cleanup
        wg_cleanup() {
            local wg_interface="${service_name#wg-quick.}"
            wg-quick down "$wg_interface" 2>/dev/null || true
        }

        # Handle common actions first
        case "$1" in
        enable)
            $SUDO rc-update add "$service_name"
            ;;
        disable)
            $SUDO rc-update del "$service_name"
            ;;
        status)
            $SUDO rc-service "$service_name" status
            ;;
        restart)
            if [[ "$service_name" == wg-quick.* ]]; then
                wg_cleanup
                $SUDO rc-service "$service_name" stop 2>/dev/null || true
            else
                $SUDO rc-service "$service_name" stop
            fi
            $SUDO rc-service "$service_name" start
            ;;
        start)
            [[ "$service_name" == wg-quick.* ]] && wg_cleanup
            $SUDO rc-service "$service_name" start
            ;;
        stop)
            $SUDO rc-service "$service_name" stop
            [[ "$service_name" == wg-quick.* ]] && wg_cleanup
            ;;
        *)
            $SUDO rc-status --all | awk '/\[.*\]/ {print $1}'
            ;;
        esac
    }
else
    f() { find . -type f -iname '*'$*'*' -ls; }
    sc() {
        if [[ -z $1 ]]; then
            $SUDO systemctl list-units --type=service | awk 'NR>1 {sub(".service", "", $1); print $1}' | head -n -7
        else
            $SUDO systemctl $1 $2
        fi
    }
fi

chktime() {
    [[ $(($(stat -c %X $1) + $2)) < $(date +%s) ]] && return 0 || return 1
}

# gethost() moved to lib/setup_core.sh - only loaded during 'ns setup'

getusers() {
    getent passwd | awk -F: '{if ($3 > 999 && $3 < 9999) print}'
}

getuser() {
    echo "\
UUSER=$UUSER
U_UID=$U_UID
U_GID=$U_GID
VHOST=$VHOST
UPATH=$UPATH
U_SHL=$U_SHL"
}

go2() {
    if [[ $1 =~ "@" ]]; then
        cd /home/u/${1#*@}*/home/*${1%@*}
    else
        cd /home/u/$1*/var/www
    fi
}

grepuser() {
    getusers | grep -E "$1[,:]"
}

# newuid() moved to lib/setup_core.sh - only loaded during 'ns setup'

getdb() {
    echo $SQCMD
}

# setuser() moved to lib/setup_core.sh - only loaded during 'ns setup'

# sethost() moved to lib/setup_core.sh - only loaded during 'ns setup'

#-T' Disable pseudo-tty allocation.
#-t' Force pseudo-tty allocation. This can be used to execute arbitrary screen-based programs on a remote machine, which can be very useful, e.g. when implementing menu services. Multiple -t options force tty allocation, even if ssh has no local tty.

sx() {
    [[ -z $2 || $1 =~ -h ]] &&
        echo "Usage: sx host command (host must be in ~/.ssh/config)" && return 1
    local _HOST=$1
    shift
    ssh $_HOST -q -t "bash -ci '$@'"
}
