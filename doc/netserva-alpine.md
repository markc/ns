# NetServa Alpine Edge LXC Container Setup

This document describes the process of setting up a NetServa-based Incus LXC container running Alpine Edge with mail and web services.

## Overview

This guide creates a mail server (mail.netserva.org) with web hosting capabilities for netserva.org, netserva.com, and netserva.net using:
- **Container**: Incus LXC running Alpine Edge
- **Database**: SQLite (lightweight alternative to MySQL/MariaDB)
- **Mail**: Postfix (SMTP) + Dovecot (IMAP)
- **Web**: Nginx + PHP-FPM 8.4
- **DNS**: PowerDNS with SQLite backend

## Prerequisites

- Incus installed and configured on the host system
- NetServa codebase in `~/Dev/ns/`
- Network bridge (br0) configured for containers

## Step-by-Step Installation

### 1. Create Alpine Edge Container

**Important**: Choose a custom container name instead of using "mail" to avoid conflicts when setting up multiple mail servers. The container name should be unique and descriptive (e.g., `nsorg`, `clientname`, `domain-tld`).

```bash
# Create the container with a custom name
# Example: incus launch images:alpine/edge nsorg
# Example: incus launch images:alpine/edge client1
# Example: incus launch images:alpine/edge example-com
incus launch images:alpine/edge <container-name>

# Attach network
incus network attach br0 <container-name>

# Get DHCP lease
incus exec <container-name> -- sh -c "ifconfig eth0 up && udhcpc -i eth0"

# Verify IP assignment (should show 192.168.1.xxx or similar)
incus list <container-name>
```

**Note**: Throughout this guide, replace `<container-name>` with your chosen container name.

### 2. Initial Container Setup

```bash
# Install basic tools
incus exec <container-name> -- apk add bash rsync openssh-server

# Create SSH config from original (if missing)
incus exec <container-name> -- cp /etc/ssh/sshd_config.orig /etc/ssh/sshd_config

# Start SSH service
incus exec <container-name> -- rc-service sshd start

# Enable SSH on boot
incus exec <container-name> -- rc-update add sshd default

# Create SSH directory and copy your public key
incus exec <container-name> -- mkdir -p /root/.ssh && incus exec <container-name> -- chmod 700 /root/.ssh
cat ~/.ssh/id_ed25519.pub | incus exec <container-name> -- sh -c 'cat > /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys'
```

### 3. Copy NetServa Files

```bash
# Create .ns directory
incus exec <container-name> -- mkdir -p /root/.ns

# Copy NetServa files (excluding mnt/ and .git/)
tar cf - --exclude='mnt/*' --exclude='.git' . | incus exec <container-name> -- tar xf - -C /root/.ns

# Fix ownership and permissions
incus exec <container-name> -- sh -c 'chown -R root:root /root/.ns && chmod +x /root/.ns/bin/*'
```

### 4. SSH Host Configuration and SSHFS Mounting

Set up SSH host configuration and mount the container for easy file access:

```bash
# Get the container's IP address
CONTAINER_IP=$(incus list <container-name> -c 4 --format csv | cut -d' ' -f1)

# Create SSH host configuration using sshm
bin/sshm create <container-name> $CONTAINER_IP 22 root ~/.ssh/lan

# Test SSH connection
ssh <container-name> "echo 'SSH connection successful'"

# Create mount point and mount via SSHFS
mkdir -p mnt/<container-name>
sshfs -o idmap=user <container-name>:/ mnt/<container-name>/

# Verify mount
ls -la mnt/<container-name>/root/.ns/
```

**Benefits of SSHFS mounting:**
- Edit files directly from your host system
- Proper user permission mapping
- Real-time file synchronization
- Standard Unix tools work seamlessly

### 5. Fix Script Paths

Before running the setup scripts, update all references from `~/.sh` to `~/.ns`:

```bash
# Update setup scripts
sed -i 's#~/.sh/#~/.ns/#g' ~/Dev/ns/bin/setup-host
sed -i 's#~/.sh/#~/.ns/#g' ~/Dev/ns/bin/setup-etc
sed -i 's#~/.sh/#~/.ns/#g' ~/Dev/ns/bin/setup-fqdn
sed -i 's#~/.sh/#~/.ns/#g' ~/Dev/ns/bin/setup-hcp

# Update copyright headers to MIT License
sed -i 's/AGPL-3.0/MIT License/g' ~/Dev/ns/bin/setup-*
sed -i 's/markc@renta.net/mc@netserva.org/g' ~/Dev/ns/bin/setup-*

# Push updated scripts to container
for script in setup-host setup-db setup-etc setup-fqdn setup-hcp; do
    incus file push ~/Dev/ns/bin/$script <container-name>/root/.ns/bin/$script
done
```

### 6. Run Setup Scripts

#### 6.1 setup-host
Installs all required packages and configures the base system:

```bash
incus exec <container-name> -- bash -c 'cd /root/.ns && export OSTYP=alpine && ./bin/setup-host mail.netserva.org sqlite'
```

This installs:
- Mail: postfix, dovecot, opendkim, postfix-policyd-spf-perl
- Web: nginx, php84-fpm, php84-* modules
- Database: sqlite
- Tools: git, rsync, sudo, etc.

#### 6.2 setup-db
Creates SQLite databases for the system:

```bash
incus exec <container-name> -- bash -c 'cd /root/.ns && source lib/functions.sh && source lib/setup_core.sh && export OSTYP=alpine && sethost mail.netserva.org sqlite && ./bin/setup-db sqlite'
```

Creates:
- `/var/lib/sqlite/sysadm/sysadm.db` - Main system database
- `/var/lib/sqlite/sysadm/pdns.db` - PowerDNS database
- Hardlinks for dovecot/postfix access

#### 6.3 setup-etc
Configures all service configuration files:

```bash
incus exec <container-name> -- bash -c 'cd /root/.ns && source lib/functions.sh && source lib/setup_core.sh && export OSTYP=alpine && sethost mail.netserva.org sqlite && ./bin/setup-etc'
```

Configures:
- Postfix main.cf and master.cf
- Dovecot with SQLite authentication
- Nginx with PHP-FPM pools
- PowerDNS with SQLite backend

#### 6.4 setup-fqdn
Sets up the primary domain (mail.netserva.org):

```bash
incus exec <container-name> -- bash -c 'cd /root/.ns && source lib/functions.sh && source lib/setup_core.sh && export OSTYP=alpine && sethost mail.netserva.org sqlite && ./bin/setup-fqdn mail.netserva.org'
```

Creates:
- Self-signed SSL certificate
- Updates mail/web configurations
- Sets up cron jobs

#### 6.5 setup-hcp
Installs the web management interface:

```bash
# Install PHP CLI first
incus exec <container-name> -- apk add php84-cli

# Run setup-hcp
incus exec <container-name> -- bash -c 'cd /root/.ns && ./bin/setup-hcp mail.netserva.org'
```

### 7. Add Virtual Hosts and Email

#### 7.1 Create password generator
```bash
cat > ~/Dev/ns/bin/newpw << 'EOF'
#!/usr/bin/env bash
# Generate a random password
TYPE=${1:-1}
LENGTH=${2:-16}

if [[ $TYPE == 2 ]]; then
    head /dev/urandom | tr -dc a-z | head -c$LENGTH
else
    head /dev/urandom | tr -dc A-Za-z0-9 | head -c$LENGTH
fi
echo
EOF

chmod +x ~/Dev/ns/bin/newpw
incus file push ~/Dev/ns/bin/newpw <container-name>/root/.ns/bin/newpw
```

#### 7.2 Add virtual hosts
```bash
# Create directory structure
incus exec <container-name> -- mkdir -p /root/.vhosts

# Add netserva.org
incus exec <container-name> -- bash -c 'cd /root/.ns && source lib/functions.sh && source lib/setup_core.sh && export OSTYP=alpine && sethost netserva.org sqlite && ./bin/addvhost netserva.org'

# Add netserva.com
incus exec <container-name> -- bash -c 'cd /root/.ns && source lib/functions.sh && source lib/setup_core.sh && export OSTYP=alpine && sethost netserva.com sqlite && ./bin/addvhost netserva.com'

# Add netserva.net
incus exec <container-name> -- bash -c 'cd /root/.ns && source lib/functions.sh && source lib/setup_core.sh && export OSTYP=alpine && sethost netserva.net sqlite && ./bin/addvhost netserva.net'
```

#### 7.3 Add email account
```bash
# Create mail directories
incus exec <container-name> -- mkdir -p /home/u/netserva.org/home

# Add admin@netserva.org manually (due to script limitations)
incus exec <container-name> -- sqlite3 /var/lib/sqlite/sysadm/sysadm.db "INSERT INTO vmails (uid, gid, hid, active, user, password, quota) VALUES (1001, 1001, 1, 1, 'admin@netserva.org', 'testpass123', 104857600);"
```

## Container Details

### Network Configuration
- IP Address: 192.168.1.248 (via DHCP)
- Hostname: mail.netserva.org

### Directory Structure
```
/root/.ns/          - NetServa installation
/home/u/            - Virtual hosts
  ├── mail.netserva.org/
  ├── netserva.org/
  ├── netserva.com/
  └── netserva.net/
/var/lib/sqlite/    - SQLite databases
/etc/nginx/         - Web server config
/etc/postfix/       - Mail server config
/etc/dovecot/       - IMAP server config
```

### Services
All services are managed via OpenRC:
```bash
rc-service nginx start|stop|restart
rc-service php-fpm84 start|stop|restart
rc-service postfix start|stop|restart
rc-service dovecot start|stop|restart
rc-service pdns start|stop|restart
```

## DNS Configuration

Add these DNS records to your DNS server:

```
netserva.org        300  IN  A    192.168.1.248
netserva.org        300  IN  MX   10 mail.netserva.org.
mail.netserva.org   300  IN  A    192.168.1.248
netserva.org        300  IN  TXT  "v=spf1 ip4:192.168.1.248/32 -all"
netserva.org        300  IN  CAA  0 issue "letsencrypt.org"
```

Repeat similar records for netserva.com and netserva.net.

## Known Issues

1. **Missing Functions**: Some helper functions (sethost, gethost, newpw, etc.) need to be sourced properly
2. **Path References**: Some scripts still have hardcoded paths that need updating
3. **Service Management**: The `sc()` and `serva` functions need proper Alpine/OpenRC integration
4. **SSL Certificates**: Currently using self-signed certificates; implement Let's Encrypt when publicly accessible

## Next Steps

1. Start services:
   ```bash
   incus exec <container-name> -- rc-service nginx start
   incus exec <container-name> -- rc-service php-fpm84 start
   incus exec <container-name> -- rc-service postfix start
   incus exec <container-name> -- rc-service dovecot start
   ```

2. Test web access: https://192.168.1.248 (accept self-signed certificate)

3. Test mail functionality with an email client

4. Configure proper SSL certificates when the server is publicly accessible

5. Set up proper DNS records for production use

## SSHFS Mount Management

To unmount the container when done working:

```bash
# Unmount SSHFS
fusermount -u ~/Dev/ns/mnt/<container-name>

# Or use umount
umount ~/Dev/ns/mnt/<container-name>
```

To remount the container:

```bash
# Remount using saved SSH config
sshfs -o idmap=user <container-name>:/ ~/Dev/ns/mnt/<container-name>/
```

**Note**: The SSHFS mount provides a seamless development experience, allowing you to edit container files directly from your host system with proper permission mapping.

## HAProxy Integration (Optional)

If you have an existing HAProxy container acting as a reverse proxy for your local LAN, you can configure it to route traffic to your NetServa container.

### Prerequisites

- HAProxy container running at 192.168.1.254
- DNS entries pointing your domains to the HAProxy container
- HAProxy configured with modular configuration files in `/etc/haproxy/conf.d/`

### Configure HAProxy Backend

Create a backend configuration file for your NetServa container:

```bash
# SSH into your HAProxy container or use incus exec
incus exec haproxy -- sh -c 'cat > /etc/haproxy/conf.d/50-backend-nsorg.cfg << "EOF"
# Backend definitions for the NetServa container (replace with your container IP)

# Backend for ACME HTTP-01 challenges  
backend nsorg_http_backend
    mode http
    server nsorg_http 192.168.1.248:80 check inter 15s fall 3 rise 2

# Backend for HTTPS traffic
backend nsorg_https_backend
    mode tcp
    balance source
    option log-health-checks
    server nsorg_https 192.168.1.248:443 check inter 15s fall 3 rise 2

# Backend for SMTPS traffic
backend nsorg_smtps_backend
    mode tcp
    timeout server 1m
    balance source
    server nsorg_smtps 192.168.1.248:465 check inter 15s fall 3 rise 2

# Backend for IMAPS traffic
backend nsorg_imaps_backend
    mode tcp
    timeout server 1m
    balance source
    stick-table type ip size 200k expire 30m
    stick on src
    server nsorg_imaps 192.168.1.248:993 check inter 15s fall 3 rise 2

# Backend for Sieve traffic (if needed)
backend nsorg_sieve_backend
    mode tcp
    timeout server 1m
    balance source
    server nsorg_sieve 192.168.1.248:4190 check inter 15s fall 3 rise 2
EOF'
```

### Update ACME Challenge Routing

Add your domains to the ACME challenge routing map:

```bash
incus exec haproxy -- sh -c 'cat >> /etc/haproxy/acme_map.txt << "EOF"
mail.netserva.org       nsorg_http_backend
netserva.org           nsorg_http_backend
netserva.com           nsorg_http_backend
netserva.net           nsorg_http_backend
EOF'
```

### Update Frontend Configuration

Add the new domains to your HAProxy frontend configuration. This example shows adding to an existing frontend file:

```bash
# Backup existing frontend config
incus exec haproxy -- cp /etc/haproxy/conf.d/10-frontends.cfg /etc/haproxy/conf.d/10-frontends.cfg.backup

# Update the frontend configuration to include NetServa domains
# Add these ACLs to your HTTPS frontend section:
# acl host_mail_netserva req_ssl_sni -i mail.netserva.org
# acl host_netserva_org req_ssl_sni -i netserva.org
# acl host_netserva_com req_ssl_sni -i netserva.com
# acl host_netserva_net req_ssl_sni -i netserva.net

# Add these backend routing rules:
# use_backend nsorg_https_backend if host_mail_netserva
# use_backend nsorg_https_backend if host_netserva_org
# use_backend nsorg_https_backend if host_netserva_com
# use_backend nsorg_https_backend if host_netserva_net

# For SMTPS frontend, add:
# acl host_mail_netserva req_ssl_sni -i mail.netserva.org
# use_backend nsorg_smtps_backend if host_mail_netserva

# For IMAPS frontend, add:
# acl host_mail_netserva req_ssl_sni -i mail.netserva.org  
# use_backend nsorg_imaps_backend if host_mail_netserva
```

### Configure Mail Relay (If HAProxy handles SMTP)

If your HAProxy container also handles mail relay, add transport rules:

```bash
# Add domains to relay map
incus exec haproxy -- sh -c 'cat >> /etc/postfix/relay_domains_map << "EOF"
netserva.org               OK
mail.netserva.org          OK
netserva.com               OK  
netserva.net               OK
EOF'

# Update transport map
incus exec haproxy -- sh -c 'cat >> /etc/postfix/transport << "EOF"
netserva.org            smtp:[192.168.1.248]:25
mail.netserva.org       smtp:[192.168.1.248]:25
netserva.com            smtp:[192.168.1.248]:25
netserva.net            smtp:[192.168.1.248]:25
EOF'

# Regenerate maps and reload
incus exec haproxy -- postmap /etc/postfix/transport
incus exec haproxy -- postmap /etc/postfix/relay_domains_map
incus exec haproxy -- rc-service postfix reload
```

### Restart HAProxy

Test and restart HAProxy with the new configuration:

```bash
# Test configuration
incus exec haproxy -- haproxy -c -f /etc/haproxy/haproxy.cfg

# Restart HAProxy
incus exec haproxy -- pkill haproxy
incus exec haproxy -- haproxy -f /etc/haproxy/haproxy.cfg -D
```

### Benefits of HAProxy Integration

- **Single Entry Point**: All traffic comes through HAProxy at 192.168.1.254
- **SSL Termination**: HAProxy can handle SSL certificates centrally
- **Load Balancing**: Can distribute load across multiple backend containers
- **Health Monitoring**: HAProxy monitors backend health automatically
- **Flexible Routing**: Route different services to different containers

**Note**: This configuration assumes HAProxy is acting as an ultra-lightweight proxy layer. Adjust backend IP addresses (192.168.1.248) to match your container's actual IP address.

## Differences from Debian Setup

- Uses Alpine Edge instead of Debian Trixie
- Uses SQLite instead of MariaDB/MySQL
- Uses OpenRC instead of systemd
- PHP 8.4 instead of PHP 8.3
- Lighter resource usage overall