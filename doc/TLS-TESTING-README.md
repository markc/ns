# TLS Security Testing Tools

This directory contains three scripts for testing and auditing TLS/SSL security configurations.

## Scripts Overview

### 1. tls-security-check.sh
Comprehensive TLS security testing script that checks for common vulnerabilities.

**Usage:**
```bash
./tls-security-check.sh [-p ports] [-v] [-h] hostname

# Examples:
./tls-security-check.sh mail.goldcoast.org
./tls-security-check.sh -p 443,465,993 mail.goldcoast.org
./tls-security-check.sh -v -p 443 secure.example.com
```

**Features:**
- Tests for deprecated protocols (SSL 2/3, TLS 1.0/1.1)
- Checks for anonymous cipher suites
- Verifies weak cipher blocking
- Examines key exchange strength
- Provides detailed recommendations

### 2. tls-audit-report.sh
Advanced audit tool that generates reports in multiple formats.

**Usage:**
```bash
./tls-audit-report.sh -h hostname [-p ports] [-f format]

# Examples:
./tls-audit-report.sh -h mail.goldcoast.org -f html
./tls-audit-report.sh -h mail.example.com -p 443,25 -f json
./tls-audit-report.sh -h secure.example.com -f text
```

**Output Formats:**
- **text**: Plain text report (default)
- **json**: Machine-readable JSON format
- **html**: Interactive HTML report with styling

**Features:**
- Vulnerability assessments (BEAST, CRIME, POODLE)
- Certificate information extraction
- Comprehensive protocol testing
- Timestamped reports saved to `./tls-reports/`

### 3. tls-quick-check.sh
Fast pass/fail security check for quick assessments.

**Usage:**
```bash
./tls-quick-check.sh [hostname] [port]

# Examples:
./tls-quick-check.sh
./tls-quick-check.sh mail.example.com
./tls-quick-check.sh secure.example.com 8443
```

**Features:**
- Quick pass/fail for critical security checks
- Minimal output for easy reading
- Default checks mail.goldcoast.org:443

## What These Scripts Test

### Security Issues Detected:
1. **Deprecated Protocols**
   - SSL v2/v3 (critically insecure)
   - TLS 1.0 (vulnerable to BEAST)
   - TLS 1.1 (outdated)

2. **Weak Cipher Suites**
   - Anonymous ciphers (aNULL, ADH, AECDH)
   - Export-grade ciphers
   - DES and 3DES
   - RC4 stream cipher
   - MD5 hash

3. **Key Exchange Issues**
   - Weak DH parameters (<2048 bits)
   - Insecure elliptic curves
   - Missing forward secrecy

4. **Configuration Problems**
   - No server cipher preference
   - Compression enabled (CRIME)
   - Certificate issues

## Interpreting Results

### Pass (✓ / GREEN)
- Security requirement is met
- No action needed

### Fail (✗ / RED)
- Security vulnerability detected
- Immediate action recommended

### Warning (! / YELLOW)
- Potential issue or consideration
- Review recommended

### Info (i / BLUE)
- Informational message
- No security impact

## Requirements

- **openssl**: Required for all tests
- **nmap**: Optional but recommended for detailed cipher analysis
- **bash**: Version 4.0 or higher
- **timeout**: Usually included with coreutils

## Installation from MKO or External Server

```bash
# Clone or download the scripts
wget https://example.com/tls-security-check.sh
wget https://example.com/tls-audit-report.sh
wget https://example.com/tls-quick-check.sh

# Make executable
chmod +x tls-*.sh

# Install dependencies (if needed)
apt-get update && apt-get install -y openssl nmap
```

## Common Use Cases

### 1. Quick Security Check
```bash
./tls-quick-check.sh mail.example.com
```

### 2. Full Security Audit
```bash
./tls-security-check.sh -v mail.example.com
```

### 3. Generate HTML Report for Management
```bash
./tls-audit-report.sh -h mail.example.com -f html
# Open ./tls-reports/mail.example.com_*.html in browser
```

### 4. Automated Testing (JSON output)
```bash
./tls-audit-report.sh -h mail.example.com -f json | jq '.ports[].tests'
```

### 5. Test Multiple Hosts
```bash
for host in mail.example.com secure.example.com web.example.com; do
    echo "Testing $host..."
    ./tls-quick-check.sh "$host"
    echo ""
done
```

## Troubleshooting

### "Connection refused" errors
- Check if the port is open and service is running
- Verify firewall rules
- Ensure correct hostname/IP

### "Command not found" errors
- Install missing dependencies (openssl, nmap)
- Check PATH environment variable

### Timeout issues
- Increase timeout values in scripts
- Check network connectivity
- Some services may have rate limiting

## Security Best Practices

Based on these tests, ensure your servers:

1. **Disable old protocols**: Only support TLS 1.2 and TLS 1.3
2. **Remove weak ciphers**: No anonymous, export, or deprecated algorithms
3. **Use strong key exchange**: ECDHE with X25519 or secp256r1/secp384r1
4. **Enable forward secrecy**: Use ECDHE cipher suites
5. **Prefer AEAD ciphers**: GCM or ChaCha20-Poly1305
6. **Set server preference**: Ensure server selects best available cipher

## License

These scripts are provided as-is for security testing purposes. Use responsibly and only on systems you own or have permission to test.