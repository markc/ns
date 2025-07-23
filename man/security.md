# NetServa Security Command

## Usage
```
ns security <ACTION> [TARGET]
```

## Description
Security scanning and auditing tools.

Comprehensive security testing including TLS/SSL analysis, port scanning, and vulnerability assessment.

## Actions
- `scan` - Quick security scan
- `check` - Comprehensive security check
- `audit` - Generate detailed security audit report

## Options
- `-p, --ports PORTS` - Port list (default: 443,25,465,587,993)
- `-f, --format FORMAT` - Report format (text|json|html)

## Examples

### Basic Scanning
```bash
# Quick security scan
ns security scan mail.example.com

# Comprehensive security check
ns security check mail.example.com
```

### Advanced Auditing
```bash
# Generate HTML audit report
ns security audit --format html mail.example.com

# Custom port scanning
ns security scan --ports 80,443,22 web.example.com

# JSON format for automation
ns security check --format json mail.example.com
```

## Security Tests

### TLS/SSL Analysis
- Certificate validation and chain verification
- Cipher suite analysis and recommendations
- Protocol version support (TLS 1.0/1.1/1.2/1.3)
- Certificate transparency and OCSP checking
- Vulnerability detection (BEAST, CRIME, POODLE, etc.)

### Port Analysis
- **SMTP** (25, 465, 587): Mail server security
- **HTTPS** (443): Web server TLS configuration
- **IMAPS** (993): Secure IMAP configuration
- **Custom ports**: User-specified service analysis

### Report Formats
- **text**: Human-readable terminal output
- **json**: Machine-readable for automation
- **html**: Detailed web-based reports

## Integration

Uses existing NetServa TLS security tools:
- `tls-security-check.sh` - Core vulnerability scanning
- `tls-audit-report.sh` - Comprehensive reporting
- `tls-quick-check.sh` - Fast pass/fail checks

## Output Location
Reports are saved to `tmp/tls-reports/` with timestamps for tracking changes over time.

## Related Commands
- `ns status` - General system status
- `ns setup` - Initial security configuration