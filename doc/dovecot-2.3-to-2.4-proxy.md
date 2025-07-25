# Complete Dovecot 2.3 to 2.4 Proxy Configuration Guide

This comprehensive guide provides a production-ready configuration for Dovecot 2.3 proxy servers connecting to Dovecot 2.4 backends using the separate passdb blocks approach with skip=notfound parameter.

## Table of Contents
1. [Core Proxy Configuration](#core-proxy-configuration)
2. [Database Schema and SQL Queries](#database-schema-and-sql-queries)
3. [Backend Server Configuration](#backend-server-configuration)
4. [Master User Authentication](#master-user-authentication)
5. [SSL/TLS Configuration](#ssltls-configuration)
6. [Network Trust Configuration](#network-trust-configuration)
7. [Step-by-Step Implementation](#step-by-step-implementation)
8. [Troubleshooting Guide](#troubleshooting-guide)
9. [Performance Optimization](#performance-optimization)
10. [Security Considerations](#security-considerations)

## Core Proxy Configuration

### Dovecot 2.3 Proxy Server Configuration

Create `/etc/dovecot/dovecot.conf` on the proxy server:

```bash
# Basic settings for proxy server
protocols = imap pop3 lmtp
listen = *, ::

# Authentication and user settings
mail_uid = vmail
mail_gid = vmail
first_valid_uid = 1000
first_valid_gid = 1000

# Disable local mail storage on proxy
mail_location = 

# Enable auth caching for performance
auth_cache_size = 4096
auth_cache_ttl = 1 hour
auth_cache_negative_ttl = 5 mins

# Authentication mechanisms
auth_mechanisms = plain login

# Login process settings for high performance
service imap-login {
    inet_listener imap {
        port = 143
    }
    inet_listener imaps {
        port = 993
        ssl = yes
    }
    service_count = 1
    client_limit = 1000
    process_min_avail = 4
    process_limit = 100
}

service pop3-login {
    inet_listener pop3 {
        port = 110
    }
    inet_listener pop3s {
        port = 995
        ssl = yes
    }
    service_count = 1
    client_limit = 1000
    process_min_avail = 4
    process_limit = 100
}

# Auth process configuration
service auth {
    unix_listener auth-userdb {
        mode = 0600
        user = vmail
        group = vmail
    }
}

# Login proxy settings
login_proxy_max_disconnect_delay = 3 secs
auth_proxy_self = 192.168.1.10  # IP of this proxy server

# CRITICAL: Separate passdb blocks configuration
# First passdb for proxy users (with skip parameter)
passdb {
    driver = sql
    args = /etc/dovecot/dovecot-proxy.conf.ext
    skip = notfound
    result_success = return-ok
    result_internalfail = continue
    result_failure = continue
}

# Second passdb for regular/local users (fallback)
passdb {
    driver = sql  
    args = /etc/dovecot/dovecot-local.conf.ext
    result_success = return-ok
    result_internalfail = continue
    result_failure = return-fail
}

# Static userdb since proxy doesn't need user lookups
userdb {
    driver = static
    args = uid=vmail gid=vmail home=/dev/null
}
```

### Proxy SQL Configuration

Create `/etc/dovecot/dovecot-proxy.conf.ext`:

```bash
# Proxy SQL configuration
driver = mysql
connect = host=localhost dbname=mailproxy user=dovecot password=secret

# Password query for proxy users
password_query = SELECT \
    NULL AS password, \
    'Y' AS nopassword, \
    host, \
    port, \
    'Y' AS proxy, \
    CASE WHEN ssl_mode = 'ssl' THEN 'yes' \
         WHEN ssl_mode = 'starttls' THEN 'any-cert' \
         ELSE 'no' END AS starttls, \
    CASE WHEN ssl_mode = 'ssl' THEN 'any-cert' \
         ELSE 'no' END AS ssl, \
    'Y' AS nodelay, \
    destuser, \
    'Y' AS proxy_nopipelining \
FROM proxy_users \
WHERE username = '%u' AND active = 1
```

### Local Users SQL Configuration

Create `/etc/dovecot/dovecot-local.conf.ext`:

```bash
# Local users SQL configuration
driver = mysql
connect = host=localhost dbname=maillocal user=dovecot password=secret

# Password query for local users (non-proxy)
password_query = SELECT \
    username AS user, \
    password, \
    home, \
    uid, \
    gid \
FROM local_users \
WHERE username = '%u' AND active = 1
```

## Database Schema and SQL Queries

### Complete Database Schema

```sql
-- Proxy routing table
CREATE TABLE proxy_users (
    username VARCHAR(255) PRIMARY KEY,
    host VARCHAR(100) NOT NULL,
    port INT DEFAULT 143,
    ssl_mode ENUM('none', 'starttls', 'ssl') DEFAULT 'starttls',
    destuser VARCHAR(255),
    active TINYINT(1) DEFAULT 1,
    created TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Backend users table
CREATE TABLE users (
    userid VARCHAR(128) NOT NULL,
    domain VARCHAR(128) NOT NULL, 
    password VARCHAR(64) NOT NULL,
    home VARCHAR(255) NOT NULL,
    uid INTEGER NOT NULL,
    gid INTEGER NOT NULL,
    masteradmin TINYINT(1) NOT NULL DEFAULT '0',
    owns_domain TINYINT(1) NOT NULL DEFAULT '0',
    UNIQUE KEY emaillookup (domain, userid)
);

-- Master users table (for proxy-to-backend authentication)
CREATE TABLE master_users (
    user_name VARCHAR(80) NOT NULL,
    domain_name VARCHAR(80) NOT NULL,
    password VARCHAR(60) DEFAULT NULL,
    masteradmin TINYINT(1) NOT NULL DEFAULT '1',
    UNIQUE KEY emaillookup (domain_name, user_name)
);

-- Insert example data
INSERT INTO proxy_users (username, host, ssl_mode) VALUES 
('user1@domain1.com', 'backend1.example.com', 'starttls'),
('user2@domain2.com', 'backend2.example.com', 'ssl');

INSERT INTO users (userid, domain, password, home, uid, gid) VALUES 
('john', 'domain1.com', '{SHA512-CRYPT}$6$salt$hash...', '/var/vmail/domain1.com/john', 5000, 5000),
('jane', 'domain2.com', '{SHA512-CRYPT}$6$salt$hash...', '/var/vmail/domain2.com/jane', 5000, 5000);
```

## Backend Server Configuration

### Dovecot 2.4 Backend Configuration

Create `/etc/dovecot/dovecot.conf` on the backend server:

```bash
# REQUIRED: Dovecot 2.4 configuration version
dovecot_config_version = 2.4.0

# REQUIRED: Storage version for compatibility
dovecot_storage_version = 2.4.0

# Basic settings
protocols = imap pop3 lmtp
listen = *, ::

# Authentication and user settings  
mail_uid = vmail
mail_gid = vmail
first_valid_uid = 1000
first_valid_gid = 1000

# Mail location with new 2.4 syntax
mail_location = maildir:~/Maildir

# Trust proxy servers - CRITICAL for proper client IP logging
login_trusted_networks = 192.168.1.10, 192.168.1.0/24

# Authentication mechanisms
auth_mechanisms = plain login

# Service configurations with 2.4 syntax
service imap-login {
    inet_listener imap {
        port = 143
    }
    inet_listener imaps {
        port = 993
        ssl = yes
    }
}

service pop3-login {
    inet_listener pop3 {
        port = 110  
    }
    inet_listener pop3s {
        port = 995
        ssl = yes
    }
}

# Named passdb (required in 2.4)
passdb backend_auth {
    driver = sql
    args = /etc/dovecot/dovecot-backend-sql.conf.ext
}

# Named userdb (required in 2.4)  
userdb backend_users {
    driver = sql
    args = /etc/dovecot/dovecot-backend-sql.conf.ext
}
```

### Backend SQL Configuration

Create `/etc/dovecot/dovecot-backend-sql.conf.ext`:

```bash
# Backend SQL configuration with 2.4 variable syntax
driver = mysql
connect = host=localhost dbname=mailbackend user=dovecot password=secret

# Password query using new 2.4 variable expansion syntax
password_query = SELECT \
    username AS user, \
    password, \
    %{user | domain} AS userdb_domain, \
    %{user | username} AS userdb_username, \
    CONCAT('/var/mail/', %{user | domain}, '/', %{user | username}) AS userdb_home, \
    'vmail' AS userdb_uid, \
    'vmail' AS userdb_gid \
FROM users \
WHERE username = %{user} AND active = 1

# User query for 2.4
user_query = SELECT \
    CONCAT('/var/mail/', %{user | domain}, '/', %{user | username}) AS home, \
    'vmail' AS uid, \
    'vmail' AS gid, \
    'maildir:~/Maildir' AS mail \
FROM users \
WHERE username = %{user} AND active = 1
```

## Master User Authentication

### Proxy Server Master User Configuration

Add to proxy server's `dovecot.conf`:

```bash
auth_master_user_separator = *

# Master user passdb for proxy authentication
passdb {
    driver = sql
    args = /etc/dovecot/dovecot-sql-master.conf.ext
    master = yes
    result_success = continue
}
```

Create `/etc/dovecot/dovecot-sql-master.conf.ext`:

```bash
driver = mysql
connect = host=localhost dbname=mail user=dovecot password=secret

# Query for master user authentication to backend
password_query = SELECT user_name, domain_name, password \
FROM master_users \
WHERE user_name = '%{user | username}' \
AND domain_name = '%{user | domain}' \
AND masteradmin='1'
```

### Backend Server Master User Setup

Add to backend server's `dovecot.conf`:

```bash
auth_master_user_separator = *

# Master user authentication
passdb {
    driver = passwd-file
    args = /etc/dovecot/passwd.masterusers
    master = yes
    result_success = continue
}
```

Create `/etc/dovecot/passwd.masterusers`:

```
proxy_master:{SHA512}nU4eI71bcnBGqeO0t9tXvY1u5oQ=
admin_proxy:{SHA512}i+UhJqb95FCnFio2UdWJu1HpV50=
```

## SSL/TLS Configuration

### Proxy Server SSL Configuration

Add to proxy server's `dovecot.conf`:

```bash
# SSL/TLS configuration for proxy
ssl_cert = </etc/ssl/certs/mail.example.com.pem
ssl_key = </etc/ssl/private/mail.example.com.key
ssl_ca = </etc/ssl/certs/ca-bundle.pem
ssl_dh = </etc/ssl/dh2048.pem

# Enhanced security settings
ssl_cipher_list = ALL:!kRSA:!SRP:!kDHd:!DSS:!aNULL:!eNULL:!EXPORT:!DES:!3DES:!MD5:!PSK:!RC4:!ADH:!LOW@STRENGTH
ssl_min_protocol = TLSv1.2
```

### Backend Server SSL Configuration

Add to backend server's `dovecot.conf`:

```bash
# SSL/TLS configuration
ssl_server_cert_file = </etc/ssl/certs/backend.example.com.pem
ssl_server_key_file = </etc/ssl/private/backend.example.com.key
ssl_client_ca_file = </etc/ssl/certs/ca-bundle.pem
ssl_server_dh_file = </etc/ssl/dh2048.pem

# Security settings
ssl = required
ssl_min_protocol = TLSv1.2
ssl_cipher_list = ECDHE+AESGCM:ECDHE+CHACHA20:DHE+AESGCM:DHE+CHACHA20:!aNULL:!MD5:!DSS
```

## Network Trust Configuration

### Backend Server Trust Configuration

**CRITICAL**: Configure `login_trusted_networks` on the backend server:

```bash
# Trust proxy servers - essential for client IP forwarding
login_trusted_networks = 192.168.1.10, 192.168.1.0/24

# For dual-stack environments
login_trusted_networks = 192.168.1.0/24 10.0.0.0/8 2001:db8::/32 fe80::/10 ::1 127.0.0.1
```

### Firewall Configuration

Configure firewall rules on the backend server:

```bash
# Allow proxy to backend communication
iptables -A INPUT -s 192.168.1.0/24 -p tcp --dport 143 -j ACCEPT
iptables -A INPUT -s 192.168.1.0/24 -p tcp --dport 993 -j ACCEPT
iptables -A INPUT -s 192.168.1.0/24 -p tcp --dport 110 -j ACCEPT
iptables -A INPUT -s 192.168.1.0/24 -p tcp --dport 995 -j ACCEPT

# Block all other connections to mail ports
iptables -A INPUT -p tcp --dport 143 -j DROP
iptables -A INPUT -p tcp --dport 993 -j DROP
iptables -A INPUT -p tcp --dport 110 -j DROP
iptables -A INPUT -p tcp --dport 995 -j DROP
```

## Step-by-Step Implementation

### Phase 1: Initial Setup

1. **Install Dovecot packages**:
   ```bash
   # Proxy server (Dovecot 2.3)
   apt-get install dovecot-core dovecot-imapd dovecot-pop3d dovecot-mysql
   
   # Backend server (Dovecot 2.4)
   apt-get install dovecot-core dovecot-imapd dovecot-pop3d dovecot-mysql
   ```

2. **Create database structure**:
   ```bash
   mysql -u root -p < create_tables.sql
   ```

3. **Configure proxy server**:
   - Copy the proxy dovecot.conf
   - Create SQL configuration files
   - Set proper permissions:
     ```bash
     chmod 600 /etc/dovecot/*.conf.ext
     chown root:dovecot /etc/dovecot/*.conf.ext
     ```

4. **Configure backend server**:
   - Copy the backend dovecot.conf
   - Create SQL configuration files
   - Configure login_trusted_networks

### Phase 2: Testing

1. **Test basic connectivity**:
   ```bash
   # From proxy server
   telnet backend.example.com 143
   ```

2. **Test authentication**:
   ```bash
   doveadm auth test user@domain password
   ```

3. **Verify proxy functionality**:
   ```bash
   # Check logs
   tail -f /var/log/dovecot.log | grep proxy
   ```

4. **Test SSL/TLS**:
   ```bash
   openssl s_client -connect backend:993 -starttls imap
   ```

### Phase 3: Production Deployment

1. **Enable performance settings**:
   ```bash
   # Increase auth cache
   auth_cache_size = 16M
   auth_cache_ttl = 3600
   
   # Optimize login processes
   service imap-login {
       service_count = 0
       client_limit = 5000
       process_min_avail = 4
   }
   ```

2. **Configure monitoring**:
   ```bash
   # Enable statistics
   service stats {
       inet_listener http {
           port = 9900
       }
   }
   ```

3. **Set up log rotation**:
   ```bash
   # /etc/logrotate.d/dovecot
   /var/log/dovecot.log {
       weekly
       rotate 4
       compress
       postrotate
           doveadm log reopen
       endscript
   }
   ```

## Troubleshooting Guide

### Common Issues and Solutions

**1. Proxy loops**:
```bash
Error: "Proxying loops to itself"
Solution: Set auth_proxy_self = <proxy_server_ip>
```

**2. Authentication failures**:
```bash
# Enable debugging
auth_debug = yes
auth_verbose = yes
log_debug = category=auth

# Check authentication
doveadm auth test user@domain password
```

**3. SSL/TLS handshake failures**:
```bash
# Test SSL connection
openssl s_client -connect backend:993 -verify_return_error

# Use relaxed verification (testing only)
ssl = any-cert
```

**4. Backend unreachable**:
```bash
# Check network connectivity
telnet backend 143

# Verify firewall rules
iptables -L -n
```

### Debug Commands

```bash
# Monitor authentication cache
kill -USR2 $(pidof dovecot-auth)

# Check proxy states
grep "state=" /var/log/dovecot.log

# Analyze authentication flow
grep -E "(Login|auth)" /var/log/dovecot.log
```

## Performance Optimization

### Recommended Settings by Deployment Size

**Small deployments (<1000 users)**:
```bash
auth_cache_size = 4M
client_limit = 1000
process_limit = 2
auth_cache_ttl = 1800
```

**Medium deployments (1000-10000 users)**:
```bash
auth_cache_size = 16M
client_limit = 5000
process_limit = 4
auth_cache_ttl = 3600
login_source_ips = proxy1 proxy2 proxy3
```

**Large deployments (>10000 users)**:
```bash
auth_cache_size = 64M
client_limit = 10000
process_limit = 8
auth_cache_ttl = 7200
auth_cache_verify_password_with_worker = yes
```

### Database Connection Pooling

```bash
# Multiple database hosts for redundancy
connect = host=db1 host=db2 dbname=mail user=dovecot password=secret

# Connection reuse
service_count = 100
client_limit = 1000
```

## Security Considerations

### Critical Security Settings

1. **Restrict trusted networks**:
   ```bash
   # Only include proxy server IPs
   login_trusted_networks = 192.168.1.10 192.168.1.11
   ```

2. **Secure master users**:
   - Use strong, unique passwords
   - Limit master user accounts
   - Regular audit of master user access

3. **SSL/TLS hardening**:
   ```bash
   ssl = required
   ssl_min_protocol = TLSv1.2
   disable_plaintext_auth = yes
   ```

4. **Authentication security**:
   ```bash
   auth_mechanisms = plain login
   auth_cache_negative_ttl = 1 hour
   auth_failure_delay = 2 secs
   ```

### Security Monitoring

```bash
# Monitor authentication failures
grep "auth failed" /var/log/dovecot.log | tail -20

# Check for suspicious IPs
grep "Login:" /var/log/dovecot.log | awk '{print $NF}' | sort | uniq -c | sort -nr

# Audit master user logins
grep "master user" /var/log/dovecot.log
```

### Regular Security Tasks

1. **Update Dovecot regularly** for security patches
2. **Rotate SSL certificates** before expiration
3. **Review and update** trusted networks quarterly
4. **Audit database access** and user permissions
5. **Monitor logs** for authentication anomalies

This configuration provides a robust, secure, and high-performance Dovecot proxy setup with proper authentication separation, SSL/TLS security, and comprehensive monitoring capabilities. Always test thoroughly in a development environment before deploying to production.
