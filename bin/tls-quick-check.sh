#!/bin/bash
# TLS Quick Check - Fast security verification
# For when you need a quick pass/fail assessment

HOST=${1:-mail.goldcoast.org}
PORT=${2:-443}

echo "TLS Quick Security Check for $HOST:$PORT"
echo "========================================"

# Quick tests with simple pass/fail
echo -n "TLS 1.0 blocked: "
if echo | timeout 2 openssl s_client -connect "$HOST:$PORT" -tls1 2>&1 | grep -q "no protocols"; then
    echo "✓ PASS"
else
    echo "✗ FAIL"
fi

echo -n "TLS 1.1 blocked: "
if echo | timeout 2 openssl s_client -connect "$HOST:$PORT" -tls1_1 2>&1 | grep -q "no protocols"; then
    echo "✓ PASS"
else
    echo "✗ FAIL"
fi

echo -n "Anonymous ciphers blocked: "
if ! echo | timeout 2 openssl s_client -connect "$HOST:$PORT" -cipher 'aNULL:ADH' 2>&1 | grep -q "Cipher    :"; then
    echo "✓ PASS"
else
    echo "✗ FAIL"
fi

echo -n "Weak ciphers blocked: "
if ! echo | timeout 2 openssl s_client -connect "$HOST:$PORT" -cipher 'EXPORT:DES:RC4:MD5' 2>&1 | grep -q "Cipher    :"; then
    echo "✓ PASS"
else
    echo "✗ FAIL"
fi

echo -n "Modern protocols supported: "
if echo | timeout 2 openssl s_client -connect "$HOST:$PORT" -tls1_2 2>&1 | grep -q "CONNECTED"; then
    echo "✓ TLS 1.2"
else
    echo "✗ No TLS 1.2"
fi

if echo | timeout 2 openssl s_client -connect "$HOST:$PORT" -tls1_3 2>&1 | grep -q "TLSv1.3"; then
    echo "                           ✓ TLS 1.3"
fi

echo ""
KEY_INFO=$(echo | timeout 3 openssl s_client -connect "$HOST:$PORT" 2>&1 | grep "Server Temp Key:")
if [[ -n "$KEY_INFO" ]]; then
    echo "Key Exchange: $KEY_INFO"
else
    echo "Key Exchange: Unable to determine"
fi