# Created: 20250721 - Updated: 20250721
# Copyright (C) 1995-2025 Mark Constable <markc@renta.net> (MIT License)
# Security functions for NetServa

# Main security command handler
security_main() {
    local action="${1:-}"
    shift 2>/dev/null || true

    case $action in
    scan)
        security_scan "$@"
        ;;
    check)
        security_check "$@"
        ;;
    audit)
        security_audit "$@"
        ;;
    *)
        error "Unknown security action: $action. Use: scan, check, or audit"
        ;;
    esac
}

# Quick security scan
security_scan() {
    local target="${1:-mail.goldcoast.org}"
    local port="${2:-443}"

    info "Running quick security scan on $target:$port"

    if [[ $DRY_RUN -eq 1 ]]; then
        info "DRY RUN: Would scan $target:$port"
        return 0
    fi

    # Use existing tls-quick-check.sh if available
    if [[ -x "$SCRIPT_DIR/tls-quick-check.sh" ]]; then
        "$SCRIPT_DIR/tls-quick-check.sh" "$target" "$port"
    else
        _security_basic_tls_check "$target" "$port"
    fi
}

# Comprehensive security check
security_check() {
    local target=""
    local ports="443,25,465,587,993"
    local verbose=0

    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
        -p | --ports)
            ports="$2"
            shift 2
            ;;
        -v | --verbose)
            verbose=1
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

    [[ -z "$target" ]] && error "No target specified for security check"

    info "Running comprehensive security check on $target (ports: $ports)"

    if [[ $DRY_RUN -eq 1 ]]; then
        info "DRY RUN: Would check $target on ports $ports"
        return 0
    fi

    # Use existing tls-security-check.sh if available
    if [[ -x "$SCRIPT_DIR/tls-security-check.sh" ]]; then
        local args=("-p" "$ports")
        [[ $verbose -eq 1 ]] && args+=("-v")
        "$SCRIPT_DIR/tls-security-check.sh" "${args[@]}" "$target"
    else
        _security_comprehensive_check "$target" "$ports"
    fi
}

# Security audit with report generation
security_audit() {
    local target=""
    local ports="443,25,465,587,993"
    local format="text"

    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
        -h | --host)
            target="$2"
            shift 2
            ;;
        -p | --ports)
            ports="$2"
            shift 2
            ;;
        -f | --format)
            format="$2"
            shift 2
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

    [[ -z "$target" ]] && error "No target specified for security audit"

    info "Generating security audit report for $target (format: $format)"

    if [[ $DRY_RUN -eq 1 ]]; then
        info "DRY RUN: Would audit $target and generate $format report"
        return 0
    fi

    # Use existing tls-audit-report.sh if available
    if [[ -x "$SCRIPT_DIR/tls-audit-report.sh" ]]; then
        "$SCRIPT_DIR/tls-audit-report.sh" -h "$target" -p "$ports" -f "$format"
    else
        _security_generate_audit "$target" "$ports" "$format"
    fi
}

# Basic TLS check (fallback implementation)
_security_basic_tls_check() {
    local host="$1"
    local port="$2"

    if ! command -v openssl >/dev/null 2>&1; then
        error "OpenSSL is required for security checks"
    fi

    info "Testing TLS connection to $host:$port"

    # Test connection
    local result
    result=$(echo | timeout 5 openssl s_client -connect "$host:$port" 2>&1)

    if echo "$result" | grep -q "CONNECTED"; then
        info "✓ Connection successful"

        # Check TLS version
        local tls_version
        tls_version=$(echo "$result" | grep "Protocol" | awk '{print $3}')
        [[ -n "$tls_version" ]] && info "✓ TLS Version: $tls_version"

        # Check cipher
        local cipher
        cipher=$(echo "$result" | grep "Cipher" | awk '{print $3}')
        [[ -n "$cipher" ]] && info "✓ Cipher: $cipher"

        info "Basic security check completed"
    else
        warn "✗ Connection failed to $host:$port"
        return 1
    fi
}

# Comprehensive security check (fallback implementation)
_security_comprehensive_check() {
    local host="$1"
    local ports="$2"

    if ! command -v openssl >/dev/null 2>&1; then
        error "OpenSSL is required for security checks"
    fi

    info "Running comprehensive security analysis..."

    # Convert comma-separated ports to array
    IFS=',' read -ra port_array <<<"$ports"

    for port in "${port_array[@]}"; do
        info "Checking port $port..."

        # Check if port is open
        if ! timeout 2 bash -c "echo >/dev/tcp/$host/$port" 2>/dev/null; then
            warn "Port $port appears closed or filtered"
            continue
        fi

        # Test deprecated protocols
        for protocol in tls1 tls1_1; do
            if echo | timeout 5 openssl s_client -connect "$host:$port" -"$protocol" 2>&1 | grep -q "no protocols available"; then
                info "✓ $protocol properly blocked"
            else
                warn "✗ $protocol supported (security risk)"
            fi
        done

        # Test current protocols
        for protocol in tls1_2 tls1_3; do
            if echo | timeout 5 openssl s_client -connect "$host:$port" -"$protocol" 2>&1 | grep -q "CONNECTED"; then
                info "✓ $protocol supported"
            fi
        done
    done
}

# Generate audit report (fallback implementation)
_security_generate_audit() {
    local host="$1"
    local ports="$2"
    local format="$3"

    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local report_dir="./tmp/tls-reports"
    local report_file="$report_dir/${host}_${timestamp}.$format"

    # Create report directory
    mkdir -p "$report_dir"

    case $format in
    text)
        _security_generate_text_report "$host" "$ports" >"$report_file"
        ;;
    json)
        _security_generate_json_report "$host" "$ports" >"$report_file"
        ;;
    html)
        _security_generate_html_report "$host" "$ports" >"$report_file"
        ;;
    *)
        error "Unsupported format: $format"
        ;;
    esac

    info "Security audit report generated: $report_file"
}

# Generate text report
_security_generate_text_report() {
    local host="$1"
    local ports="$2"

    cat <<EOF
Security Audit Report
====================
Host: $host
Ports: $ports
Date: $(date)

$(security_check "$host" --ports "$ports" 2>&1 || echo "Check completed with warnings")

Report generated by NetServa Security Module
EOF
}

# Generate JSON report
_security_generate_json_report() {
    local host="$1"
    local ports="$2"

    cat <<EOF
{
  "audit_info": {
    "host": "$host",
    "ports": "$ports",
    "timestamp": "$(date -Iseconds)",
    "tool": "netserva-security"
  },
  "status": "completed",
  "summary": "Basic audit report - detailed implementation pending"
}
EOF
}

# Generate HTML report
_security_generate_html_report() {
    local host="$1"
    local ports="$2"

    cat <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Security Audit Report - $host</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background: #f0f0f0; padding: 10px; border-radius: 5px; }
        .pass { color: green; }
        .fail { color: red; }
        .warn { color: orange; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Security Audit Report</h1>
        <p><strong>Host:</strong> $host</p>
        <p><strong>Ports:</strong> $ports</p>
        <p><strong>Date:</strong> $(date)</p>
    </div>
    
    <h2>Results</h2>
    <p>Detailed security analysis results would appear here.</p>
    <p><em>Note: This is a basic template. Full implementation pending.</em></p>
    
    <footer>
        <hr>
        <p><small>Generated by NetServa Security Module</small></p>
    </footer>
</body>
</html>
EOF
}
