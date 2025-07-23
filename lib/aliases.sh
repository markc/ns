# Created: 20151231 - Updated: 20250407
# Copyright (C) 1995-2025 Mark Constable <markc@renta.net> (AGPL-3.0)

alias ..='cd ..'
alias ?='bash ~/.help'
alias a='php artisan'
alias c='composer'
alias df='df -kTh'
alias e='nano -t -x -c'
alias eh='e ~/.help'
alias es='e ~/.myrc; nsrc_reload'
alias hcp='shm pull; su - sysadm -c "cd var/www/html/hcp; git pull"'
alias l='journalctl -f'
alias la='LC_COLLATE=C ls -lFAh --group-directories-first --color'
alias ll='LC_COLLATE=C ls -lF --group-directories-first --color'
alias ls='LC_COLLATE=C ls -F --group-directories-first --color'
alias lx='lxc list'
alias m='bash ~/.menu'
alias n='echo -e "-- $(date) --\n" >> ~/.note && e +10000 ~/.note'
alias p='ps auxxww | grep -v grep | grep'
alias q='find -type f -print0 | xargs -0 grep '
alias se='sudo nano -t -x -c'
alias sn='[ -f ~/.note ] && cat ~/.note'
alias wt="curl -s -w '%{time_total}\n' -o /dev/null"
alias ff="fastfetch --logo none --colors-block-width 0"

if [[ $OSTYP == openwrt ]]; then
    alias edpkg=$SUDO'nano -t -x -c /etc/opkg/customfeeds.conf'
    alias i=$SUDO'opkg install'
    alias l=$SUDO'logread -f'
    alias lspkg=$SUDO'opkg list-installed | sort | grep'
    alias p='ps | grep -v grep | grep'
    alias r=$SUDO'opkg remove'
    alias s=$SUDO'opkg list | sort | grep '
    alias u=$SUDO'opkg update && '$SUDO'opkg list-upgradable | cut -f 1 -d " " | xargs -r opkg upgrade'
    alias ram=$SUDO"ps w | grep -v \"   0\" | awk '{print \$3\"\t\"\$5\" \"\$6\" \"\$7\" \"\$8\" \"\$9}' | sort -n"
elif [[ $OSTYP == alpine ]]; then
    alias edpkg=$SUDO'nano -t -x -c /etc/apk/repositories'
    alias i=$SUDO'apk add'
    alias l=$SUDO'tail -f /var/log/messages'
    alias lspkg=$SUDO'apk info | sort | grep'
    alias r=$SUDO'apk del'
    alias ram=$SUDO'ps ax -o rss:10,vsz:10,comm | grep -v "   0" | sort -n'
    alias s=$SUDO'apk search -v'
    alias u=$SUDO'apk update && '$SUDO'apk upgrade'
    alias ram='ps ax -o rss,vsz,comm | grep -v "   0" | sort -n'
elif [[ $OSTYP == manjaro || $OSTYP == cachyos || $OSTYP == arch ]]; then
    alias edpkg=$SUDO'nano -t -x -c /etc/pacman.conf'
    alias i=$SUDO'pacman -S'
    alias lspkg=$SUDO'pacman -Qs'
    alias r=$SUDO'pacman -Rns'
    alias s=$SUDO'pacman -Ss'
    alias u=$SUDO'pacman -Syu --noconfirm ; '$SUDO' pacman -Scc --noconfirm'
    alias uu='yay -Syyuu --noconfirm ; yay -Scc --noconfirm ; '$SUDO' pacman -Scc --noconfirm'
    alias ram='ps -eo rss:10,vsz:10,%cpu:5,cmd --sort=rss | grep -v "^\s\+0" | cut -c -79'
else
    alias aptkey=$SUDO'apt-key adv --recv-keys --keyserver keyserver.ubuntu.com'
    alias edpkg=$SUDO'nano -t -x -c /etc/apt/sources.list'
    alias i=$SUDO'apt-get install'
    alias lspkg='dpkg --get-selections | awk "{print \$1}" | sort | grep'
    alias r=$SUDO'apt-get remove --purge'
    alias s='apt-cache search'
    alias u=$SUDO'apt-get update && '$SUDO'apt-get -y -f dist-upgrade && '$SUDO'apt-get -y autoremove && '$SUDO'apt-get clean'
    alias ram='ps -eo rss:10,vsz:10,%cpu:5,cmd --sort=rss | grep -v "^\s\+0" | cut -c -79'
fi

#alias block="nft version?"

alias shblock="nft list set ip sshguard attackers | tr '\n' ' '| sed 's/.*elements = {\([^}]*\)}.*/\1\n/' | sed -r 's/\s+//g' | tr ',' '\n'"

# this throws an error, for now
#unblock() {
#    nft delete element ip sshguard attackers { $1 }
#}

# Old iptables version, change to sshguard w/ nft format above
alias oldblock='iptables -A INPUT -j DROP -s '
alias oldshblock='iptables -L -n | grep ^DROP | awk '\''{print $4}'\'' | sort -n'
alias oldunblock='iptables -D INPUT -j DROP -s '

alias dlog='journalctl -f -t pdns_server -t pdns_recursor'
alias hlog='journalctl -f -t hlog'
alias slog='journalctl -f -t sshd'

alias mlog='tail -f /var/log/mail.log'
alias mgrep='mlog | grep '

alias alog='tail -f ../log/access.log'
alias elog='tail -f /var/log/nginx/error.log'
alias plog='tail -f ../log/php-errors.log'

# Depends on /etc/postfix/header_checks
alias maillog="journalctl -f -n 10000 | stdbuf -oL grep 'warning: header Subject:' | sed -e 's/mail .*warning: header Subject:\(.*\)/\1/' -e 's/ from .*];//' -e 's/proto=.*$//'"
