#!/bin/bash
# TLS Security Checker Script
# Tests TLS configuration against common vulnerabilities
# Author: Claude Assistant
# Date: 2025-07-21

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Default values
DEFAULT_PORTS="443,25,465,587,993"
VERBOSE=0

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "PASS") echo -e "${GREEN}[✓]${NC} $message" ;;
        "FAIL") echo -e "${RED}[✗]${NC} $message" ;;
        "WARN") echo -e "${YELLOW}[!]${NC} $message" ;;
        "INFO") echo -e "${BLUE}[i]${NC} $message" ;;
        "HEAD") echo -e "\n${BOLD}$message${NC}" ;;
    esac
}

# Function to check if a command exists
check_command() {
    if ! command -v $1 &> /dev/null; then
        print_status "FAIL" "$1 is required but not installed"
        return 1
    fi
    return 0
}

# Function to test TLS protocol support
test_tls_protocol() {
    local host=$1
    local port=$2
    local protocol=$3
    local service_type=$4
    
    if [[ $VERBOSE -eq 1 ]]; then
        print_status "INFO" "Testing $protocol on $host:$port"
    fi
    
    local result
    if [[ "$service_type" == "smtp" ]]; then
        result=$(echo "QUIT" | timeout 5 openssl s_client -connect "$host:$port" -starttls smtp -$protocol 2>&1)
    else
        result=$(echo | timeout 5 openssl s_client -connect "$host:$port" -$protocol 2>&1)
    fi
    
    if echo "$result" | grep -q "no protocols available\|wrong version number\|unsupported protocol"; then
        return 1  # Protocol not supported (good for old protocols)
    else
        return 0  # Protocol supported
    fi
}

# Function to test anonymous cipher suites
test_anonymous_ciphers() {
    local host=$1
    local port=$2
    local service_type=$3
    
    local anon_ciphers="aNULL:eNULL:ADH:AECDH:DH_anon:ECDH_anon"
    local result
    
    if [[ "$service_type" == "smtp" ]]; then
        result=$(echo "QUIT" | timeout 5 openssl s_client -connect "$host:$port" -starttls smtp -cipher "$anon_ciphers" 2>&1)
    else
        result=$(echo | timeout 5 openssl s_client -connect "$host:$port" -cipher "$anon_ciphers" 2>&1)
    fi
    
    if echo "$result" | grep -q "no cipher match\|no ciphers available\|handshake failure"; then
        return 1  # Anonymous ciphers blocked (good)
    else
        return 0  # Anonymous ciphers allowed (bad)
    fi
}

# Function to test weak ciphers
test_weak_ciphers() {
    local host=$1
    local port=$2
    local service_type=$3
    
    local weak_ciphers="EXPORT:DES:RC4:MD5:PSK:SRP:3DES"
    local result
    
    if [[ "$service_type" == "smtp" ]]; then
        result=$(echo "QUIT" | timeout 5 openssl s_client -connect "$host:$port" -starttls smtp -cipher "$weak_ciphers" 2>&1)
    else
        result=$(echo | timeout 5 openssl s_client -connect "$host:$port" -cipher "$weak_ciphers" 2>&1)
    fi
    
    if echo "$result" | grep -q "no cipher match\|no ciphers available\|handshake failure"; then
        return 1  # Weak ciphers blocked (good)
    else
        return 0  # Weak ciphers allowed (bad)
    fi
}

# Function to get cipher suite details using nmap
get_cipher_details() {
    local host=$1
    local port=$2
    
    if command -v nmap &> /dev/null; then
        nmap --script ssl-enum-ciphers -p "$port" "$host" 2>/dev/null
    else
        echo "nmap not available for detailed cipher analysis"
    fi
}

# Function to check key exchange strength
check_key_exchange() {
    local host=$1
    local port=$2
    local service_type=$3
    
    local result
    if [[ "$service_type" == "smtp" ]]; then
        result=$(echo "QUIT" | timeout 5 openssl s_client -connect "$host:$port" -starttls smtp 2>&1)
    else
        result=$(echo | timeout 5 openssl s_client -connect "$host:$port" 2>&1)
    fi
    
    local key_info=$(echo "$result" | grep -E "Server Temp Key:|Server public key")
    echo "$key_info"
}

# Function to determine service type based on port
get_service_type() {
    local port=$1
    case $port in
        25|587) echo "smtp" ;;
        *) echo "standard" ;;
    esac
}

# Main testing function
test_host() {
    local host=$1
    local ports=$2
    
    print_status "HEAD" "TLS Security Report for: $host"
    print_status "INFO" "Testing ports: $ports"
    print_status "INFO" "Date: $(date)"
    echo ""
    
    # Convert comma-separated ports to array
    IFS=',' read -ra PORT_ARRAY <<< "$ports"
    
    local total_tests=0
    local passed_tests=0
    local failed_tests=0
    
    for port in "${PORT_ARRAY[@]}"; do
        print_status "HEAD" "Port $port Analysis"
        
        # Check if port is open
        if ! timeout 2 bash -c "echo >/dev/tcp/$host/$port" 2>/dev/null; then
            print_status "WARN" "Port $port appears to be closed or filtered"
            continue
        fi
        
        local service_type=$(get_service_type "$port")
        
        # Test deprecated protocols
        print_status "INFO" "Testing deprecated protocols..."
        
        for protocol in tls1 tls1_1; do
            ((total_tests++))
            if test_tls_protocol "$host" "$port" "$protocol" "$service_type"; then
                print_status "FAIL" "$protocol is SUPPORTED (security risk)"
                ((failed_tests++))
            else
                print_status "PASS" "$protocol is properly BLOCKED"
                ((passed_tests++))
            fi
        done
        
        # Test current protocols
        for protocol in tls1_2 tls1_3; do
            if test_tls_protocol "$host" "$port" "$protocol" "$service_type"; then
                print_status "PASS" "$protocol is supported"
            else
                print_status "INFO" "$protocol is not supported"
            fi
        done
        
        # Test anonymous ciphers
        print_status "INFO" "Testing anonymous cipher suites..."
        ((total_tests++))
        if test_anonymous_ciphers "$host" "$port" "$service_type"; then
            print_status "FAIL" "Anonymous ciphers ALLOWED (security risk)"
            ((failed_tests++))
        else
            print_status "PASS" "Anonymous ciphers properly BLOCKED"
            ((passed_tests++))
        fi
        
        # Test weak ciphers
        print_status "INFO" "Testing weak cipher suites..."
        ((total_tests++))
        if test_weak_ciphers "$host" "$port" "$service_type"; then
            print_status "FAIL" "Weak ciphers ALLOWED (security risk)"
            ((failed_tests++))
        else
            print_status "PASS" "Weak ciphers properly BLOCKED"
            ((passed_tests++))
        fi
        
        # Check key exchange
        print_status "INFO" "Checking key exchange parameters..."
        local key_exchange=$(check_key_exchange "$host" "$port" "$service_type")
        if [[ -n "$key_exchange" ]]; then
            echo "$key_exchange" | while read -r line; do
                if [[ "$line" =~ "Server Temp Key" ]]; then
                    if [[ "$line" =~ "X25519|secp256r1|secp384r1" ]] && [[ "$line" =~ "25[0-9]|384" ]]; then
                        print_status "PASS" "Strong key exchange: $line"
                    else
                        print_status "WARN" "Key exchange: $line"
                    fi
                else
                    print_status "INFO" "$line"
                fi
            done
        fi
        
        # Get detailed cipher information if nmap is available
        if [[ $VERBOSE -eq 1 ]] && command -v nmap &> /dev/null; then
            print_status "INFO" "Detailed cipher analysis..."
            local cipher_details=$(get_cipher_details "$host" "$port")
            echo "$cipher_details" | grep -E "TLS.*:|cipher preference:|ciphers:|least strength:" | sed 's/^/    /'
        fi
        
        echo ""
    done
    
    # Summary
    print_status "HEAD" "Summary"
    print_status "INFO" "Total security tests: $total_tests"
    print_status "INFO" "Passed: $passed_tests"
    if [[ $failed_tests -eq 0 ]]; then
        print_status "PASS" "Failed: $failed_tests - EXCELLENT SECURITY"
    else
        print_status "FAIL" "Failed: $failed_tests - SECURITY ISSUES FOUND"
    fi
    
    # Recommendations if issues found
    if [[ $failed_tests -gt 0 ]]; then
        print_status "HEAD" "Recommendations"
        print_status "WARN" "1. Disable TLS 1.0 and TLS 1.1 protocols"
        print_status "WARN" "2. Remove anonymous cipher suites (aNULL, ADH, AECDH)"
        print_status "WARN" "3. Disable weak ciphers (EXPORT, DES, RC4, MD5, 3DES)"
        print_status "WARN" "4. Use ECDHE key exchange with strong curves"
        print_status "WARN" "5. Prefer AEAD ciphers (GCM, ChaCha20-Poly1305)"
    fi
}

# Usage function
usage() {
    echo "Usage: $0 [-p ports] [-v] [-h] hostname"
    echo ""
    echo "Options:"
    echo "  -p PORTS    Comma-separated list of ports to test (default: $DEFAULT_PORTS)"
    echo "  -v          Verbose mode (show detailed cipher information)"
    echo "  -h          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 mail.example.com"
    echo "  $0 -p 443,465,993 mail.example.com"
    echo "  $0 -v -p 443 secure.example.com"
    exit 1
}

# Main script
main() {
    local ports="$DEFAULT_PORTS"
    local host=""
    
    # Parse command line options
    while getopts "p:vh" opt; do
        case $opt in
            p) ports="$OPTARG" ;;
            v) VERBOSE=1 ;;
            h) usage ;;
            \?) echo "Invalid option: -$OPTARG" >&2; usage ;;
        esac
    done
    
    shift $((OPTIND-1))
    
    # Check if hostname was provided
    if [[ $# -eq 0 ]]; then
        print_status "FAIL" "Error: No hostname provided"
        usage
    fi
    
    host="$1"
    
    # Check required commands
    print_status "INFO" "Checking required tools..."
    check_command "openssl" || exit 1
    
    if ! command -v nmap &> /dev/null; then
        print_status "WARN" "nmap not found - detailed cipher analysis will be limited"
    fi
    
    # Run the tests
    test_host "$host" "$ports"
}

# Run main function
main "$@"