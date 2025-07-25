#!/bin/bash
# TLS Security Audit Report Generator
# Performs comprehensive TLS testing and generates detailed reports
# Author: Claude Assistant
# Date: 2025-07-21

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
BOLD='\033[1m'

# Default configuration
REPORT_DIR="./tls-reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_FORMAT="text"  # text, json, html

# Create report directory
mkdir -p "$REPORT_DIR"

# Function to generate JSON report
generate_json_report() {
    local host=$1
    local data=$2
    local report_file="$REPORT_DIR/${host}_${TIMESTAMP}.json"
    
    echo "$data" > "$report_file"
    echo "JSON report saved to: $report_file"
}

# Function to generate HTML report
generate_html_report() {
    local host=$1
    local data=$2
    local report_file="$REPORT_DIR/${host}_${TIMESTAMP}.html"
    
    cat > "$report_file" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>TLS Security Report - $host</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background-color: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        h1 { color: #333; border-bottom: 2px solid #007bff; padding-bottom: 10px; }
        h2 { color: #555; margin-top: 30px; }
        .pass { color: #28a745; font-weight: bold; }
        .fail { color: #dc3545; font-weight: bold; }
        .warn { color: #ffc107; font-weight: bold; }
        .info { color: #17a2b8; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #007bff; color: white; }
        tr:nth-child(even) { background-color: #f8f9fa; }
        .summary { background-color: #e9ecef; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .recommendation { background-color: #fff3cd; padding: 15px; border-radius: 5px; margin: 10px 0; }
        pre { background-color: #f8f9fa; padding: 10px; border-radius: 4px; overflow-x: auto; }
    </style>
</head>
<body>
    <div class="container">
        <h1>TLS Security Audit Report</h1>
        <div class="summary">
            <p><strong>Host:</strong> $host</p>
            <p><strong>Date:</strong> $(date)</p>
            <p><strong>Auditor:</strong> TLS Security Checker v1.0</p>
        </div>
        
        <div id="report-content">
            $data
        </div>
    </div>
</body>
</html>
EOF
    
    echo "HTML report saved to: $report_file"
}

# Function to test specific vulnerabilities
test_vulnerabilities() {
    local host=$1
    local port=$2
    
    echo "{"
    echo "  \"host\": \"$host\","
    echo "  \"port\": $port,"
    echo "  \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
    echo "  \"tests\": {"
    
    # Test for BEAST vulnerability
    echo "    \"beast\": {"
    local beast_ciphers="AES128-SHA:AES256-SHA:DES-CBC3-SHA"
    if echo | timeout 5 openssl s_client -connect "$host:$port" -cipher "$beast_ciphers" -tls1 2>&1 | grep -q "Cipher"; then
        echo "      \"vulnerable\": true,"
        echo "      \"description\": \"Server supports CBC ciphers with TLS 1.0\""
    else
        echo "      \"vulnerable\": false,"
        echo "      \"description\": \"Not vulnerable to BEAST attack\""
    fi
    echo "    },"
    
    # Test for CRIME vulnerability
    echo "    \"crime\": {"
    local compression=$(echo | timeout 5 openssl s_client -connect "$host:$port" 2>&1 | grep "Compression:")
    if [[ "$compression" =~ "NONE" ]] || [[ -z "$compression" ]]; then
        echo "      \"vulnerable\": false,"
        echo "      \"description\": \"Compression disabled\""
    else
        echo "      \"vulnerable\": true,"
        echo "      \"description\": \"Compression enabled: $compression\""
    fi
    echo "    },"
    
    # Test for POODLE vulnerability
    echo "    \"poodle\": {"
    if echo | timeout 5 openssl s_client -connect "$host:$port" -ssl3 2>&1 | grep -q "ssl handshake failure\|no protocols\|wrong version"; then
        echo "      \"vulnerable\": false,"
        echo "      \"description\": \"SSLv3 properly disabled\""
    else
        echo "      \"vulnerable\": true,"
        echo "      \"description\": \"SSLv3 enabled - vulnerable to POODLE\""
    fi
    echo "    },"
    
    # Test for Heartbleed
    echo "    \"heartbleed\": {"
    echo "      \"vulnerable\": \"unknown\","
    echo "      \"description\": \"Heartbleed test requires specialized tools\""
    echo "    }"
    
    echo "  }"
    echo "}"
}

# Function to get certificate information
get_cert_info() {
    local host=$1
    local port=$2
    
    local cert_info=$(echo | timeout 5 openssl s_client -connect "$host:$port" -servername "$host" 2>&1 | openssl x509 -noout -text 2>/dev/null)
    
    if [[ -n "$cert_info" ]]; then
        echo "<h2>Certificate Information</h2>"
        echo "<pre>"
        echo "$cert_info" | grep -E "Subject:|Issuer:|Not Before:|Not After:|Public-Key:|Signature Algorithm:"
        echo "</pre>"
    fi
}

# Function for comprehensive port test
comprehensive_test() {
    local host=$1
    local port=$2
    
    echo "<h2>Port $port Analysis</h2>"
    
    # Check if port is open
    if ! timeout 2 bash -c "echo >/dev/tcp/$host/$port" 2>/dev/null; then
        echo "<p class='warn'>Port $port appears to be closed or filtered</p>"
        return
    fi
    
    echo "<h3>Protocol Support</h3>"
    echo "<table>"
    echo "<tr><th>Protocol</th><th>Status</th><th>Security Assessment</th></tr>"
    
    for proto in ssl2 ssl3 tls1 tls1_1 tls1_2 tls1_3; do
        echo "<tr>"
        echo "<td>$proto</td>"
        if echo | timeout 5 openssl s_client -connect "$host:$port" -$proto 2>&1 | grep -q "CONNECTED"; then
            case $proto in
                ssl2|ssl3|tls1|tls1_1)
                    echo "<td class='fail'>Enabled</td>"
                    echo "<td class='fail'>INSECURE - Should be disabled</td>"
                    ;;
                tls1_2|tls1_3)
                    echo "<td class='pass'>Enabled</td>"
                    echo "<td class='pass'>Secure when properly configured</td>"
                    ;;
            esac
        else
            case $proto in
                ssl2|ssl3|tls1|tls1_1)
                    echo "<td class='pass'>Disabled</td>"
                    echo "<td class='pass'>Good - Insecure protocol disabled</td>"
                    ;;
                tls1_2|tls1_3)
                    echo "<td class='info'>Disabled</td>"
                    echo "<td class='info'>Consider enabling for compatibility</td>"
                    ;;
            esac
        fi
        echo "</tr>"
    done
    echo "</table>"
    
    # Get certificate info
    get_cert_info "$host" "$port"
    
    # Vulnerability tests
    echo "<h3>Vulnerability Assessment</h3>"
    local vuln_data=$(test_vulnerabilities "$host" "$port")
    echo "<pre>$vuln_data</pre>"
}

# Main function
main() {
    local host=""
    local ports="443,25,465,587,993"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--host)
                host="$2"
                shift 2
                ;;
            -p|--ports)
                ports="$2"
                shift 2
                ;;
            -f|--format)
                OUTPUT_FORMAT="$2"
                shift 2
                ;;
            --help)
                echo "Usage: $0 -h hostname [-p ports] [-f format]"
                echo "  -h, --host     Hostname to test (required)"
                echo "  -p, --ports    Comma-separated ports (default: 443,25,465,587,993)"
                echo "  -f, --format   Output format: text, json, html (default: text)"
                echo ""
                echo "Example: $0 -h mail.example.com -f html"
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    if [[ -z "$host" ]]; then
        echo "Error: Hostname required. Use --help for usage."
        exit 1
    fi
    
    # Generate report based on format
    case $OUTPUT_FORMAT in
        json)
            # Run tests and output JSON
            echo "Generating JSON report for $host..."
            json_data="{"
            json_data+="\"host\":\"$host\","
            json_data+="\"ports\":["
            
            IFS=',' read -ra PORT_ARRAY <<< "$ports"
            for port in "${PORT_ARRAY[@]}"; do
                vuln_result=$(test_vulnerabilities "$host" "$port")
                json_data+="$vuln_result,"
            done
            json_data="${json_data%,}]}"
            
            generate_json_report "$host" "$json_data"
            ;;
            
        html)
            # Run tests and generate HTML
            echo "Generating HTML report for $host..."
            html_content=""
            
            IFS=',' read -ra PORT_ARRAY <<< "$ports"
            for port in "${PORT_ARRAY[@]}"; do
                port_result=$(comprehensive_test "$host" "$port")
                html_content+="$port_result"
            done
            
            generate_html_report "$host" "$html_content"
            ;;
            
        text|*)
            # Run the basic text report
            echo "Generating text report for $host..."
            bash "$(dirname "$0")/tls-security-check.sh" -p "$ports" "$host" | tee "$REPORT_DIR/${host}_${TIMESTAMP}.txt"
            echo ""
            echo "Text report saved to: $REPORT_DIR/${host}_${TIMESTAMP}.txt"
            ;;
    esac
}

# Run main
main "$@"