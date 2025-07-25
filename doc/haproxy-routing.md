# HAProxy Mail and Web Routing Configuration

This document describes the complete TCP routing setup for HAProxy in the NetServa environment, serving as a reference for rebuilding the configuration from scratch.

## Overview

HAProxy provides TCP-level routing for all SSL/TLS services (web and mail) while unencrypted SMTP (port 25) is managed directly by Postfix due to STARTTLS protocol requirements.

## Mail Server Backends

| Domain | Backend IP | Services |
|--------|------------|----------|
| mail.example.com | _MAIL_IP | HTTPS, SMTPS (465), IMAPS (993), Sieve (4190) |
| mail.example.org | _NSORG_IP | HTTPS, SMTPS (465), IMAPS (993), Sieve (4190) |
| host1.example.net | _HOST1_IP | HTTPS, SMTPS (465), IMAPS (993), Sieve (4190) |

## Port Configuration

### HAProxy-Managed Ports (TCP Routing)

#### Port 80 (HTTP)
- **Frontend**: `http_frontend`
- **Mode**: HTTP
- **Purpose**: HTTP to HTTPS redirect and ACME challenges
- **Routing**: Based on Host header
- **Backends**: 
  - `mail_http_backend` → _MAIL_IP:80
  - `nsorg_http_backend` → _NSORG_IP:80
  - `host1_http_backend` → _HOST1_IP:80
  - Others for additional services

#### Port 443 (HTTPS)
- **Frontend**: `https_frontend`
- **Mode**: TCP
- **Purpose**: SSL/TLS web traffic
- **Routing**: Based on SNI (Server Name Indication)
- **SSL Handling**: Passthrough (backend handles SSL)
- **Backends**:
  - `mail_backend` → _MAIL_IP:443 (mail.example.com)
  - `nsorg_https_backend` → _NSORG_IP:443 (mail.example.org)
  - `host1_backend` → _HOST1_IP:443 (host1.example.net)
  - Others for web services

#### Port 465 (SMTPS)
- **Frontend**: `smtps_frontend`
- **Mode**: TCP
- **Purpose**: SMTP over SSL/TLS
- **Routing**: Based on SNI
- **Backends**:
  - `smtps_backend` → _MAIL_IP:465 (mail.example.com)
  - `nsorg_smtps_backend` → _NSORG_IP:465 (mail.example.org)
  - `host1_smtps_backend` → _HOST1_IP:465 (host1.example.net)

#### Port 993 (IMAPS)
- **Frontend**: `imaps_frontend`
- **Mode**: TCP
- **Purpose**: IMAP over SSL/TLS
- **Routing**: Based on SNI
- **Backends**:
  - `imaps_backend` → _MAIL_IP:993 (mail.example.com)
  - `nsorg_imaps_backend` → _NSORG_IP:993 (mail.example.org)
  - `host1_imaps_backend` → _HOST1_IP:993 (host1.example.net)

#### Port 4190 (ManageSieve)
- **Frontend**: `sieve_frontend`
- **Mode**: TCP
- **Purpose**: Sieve script management
- **Routing**: Default backend only
- **Backend**: `sieve_backend` → _MAIL_IP:4190

### Postfix-Managed Ports
- **Port 25**: SMTP (unencrypted initially, STARTTLS negotiated)
  - Cannot be handled by HAProxy due to STARTTLS protocol requirements
  - Postfix on the HAProxy server receives and forwards mail
  - No transport_maps currently configured (direct delivery)

### Not Currently Configured
- **Port 143**: IMAP (unencrypted) - No frontend defined
- **Port 587**: Submission (STARTTLS) - Not needed, clients use port 465

## Configuration Files

- Main config: `/etc/haproxy/haproxy.cfg`
- Conflicting conf.d files have been disabled to prevent duplication errors

## HAProxy Configuration Structure

```
global
    # Global settings
    daemon
    maxconn 256

defaults
    # Default settings for all frontends/backends
    mode tcp
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms

frontend <name>
    bind *:<port>
    mode tcp/http
    # ACL rules for routing
    acl <acl_name> <condition>
    use_backend <backend_name> if <acl_name>
    default_backend <backend_name>

backend <name>
    mode tcp/http
    server <server_name> <ip>:<port> check
```

## SSL/TLS Handling

- HAProxy operates in TCP mode for SSL/TLS services
- Uses SNI (Server Name Indication) to route connections without decrypting
- SSL/TLS termination happens at the backend servers
- Requires `tcp-request inspect-delay` and `tcp-request content accept` for SNI detection

## Key Configuration Elements

### ACL Rules for SNI-based Routing
```
acl host_mail_example req_ssl_sni -i mail.example.com
acl host_mail_org req_ssl_sni -i mail.example.org
acl host_host1 req_ssl_sni -i host1.example.net
```

### Backend Health Checks
- `check`: Enable health checks
- `inter 15s`: Check interval
- `fall 3`: Mark down after 3 failures
- `rise 2`: Mark up after 2 successes

### Sticky Sessions (for IMAP)
```
stick-table type ip size 200k expire 30m
stick on src
```

## Troubleshooting

1. **Connection Refused**: Check if HAProxy is running: `rc-service haproxy status`
2. **SSL Errors**: Verify backend servers have valid certificates
3. **Port 25 Issues**: Check Postfix logs, not HAProxy
4. **Duplicate Config Errors**: Ensure conf.d directory doesn't duplicate main config
5. **Routing Issues**: Check ACL rules and backend server IPs

## Rebuilding from Scratch

1. Install HAProxy on Alpine: `apk add haproxy`
2. Create `/etc/haproxy/haproxy.cfg` with:
   - Global and defaults sections
   - Frontend definitions for ports 80, 443, 465, 993, 4190
   - Backend definitions for each server/service
   - ACL rules for hostname-based routing
3. Ensure backend servers are accessible from HAProxy
4. Start service: `rc-service haproxy start`
5. Enable at boot: `rc-update add haproxy`

## Deployment Variables

When deploying, replace the following placeholders:
- `_MAIL_IP`: Primary mail server IP (e.g., 192.168.100.244)
- `_NSORG_IP`: Organization mail server IP (e.g., 192.168.100.248)
- `_HOST1_IP`: Additional host IP (e.g., 192.168.100.250)

Example sed replacement:
```bash
sed -i 's/_MAIL_IP/192.168.100.244/g' haproxy.cfg
sed -i 's/_NSORG_IP/192.168.100.248/g' haproxy.cfg
sed -i 's/_HOST1_IP/192.168.100.250/g' haproxy.cfg
```

## Important Notes

- All mail clients should use SSL/TLS ports (465/993) for security
- Port 25 should only be used for server-to-server mail delivery
- HAProxy handles TCP-level routing, not application-level protocols
- HTTP mode is only used for port 80 (redirects and ACME challenges)
- All other services use TCP mode with SNI-based routing