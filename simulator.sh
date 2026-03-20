#!/bin/bash

# Enterprise SLO Testing Simulator
# Tests all endpoints and generates load for SLO monitoring

set -e

BASE_URL="${BASE_URL:-http://localhost:3000}"
REQUESTS="${REQUESTS:-100}"
CONCURRENT="${CONCURRENT:-10}"
DELAY="${DELAY:-0.1}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         Enterprise SLO Testing Simulator                 ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Configuration:"
echo "  Base URL:   $BASE_URL"
echo "  Requests:   $REQUESTS"
echo "  Concurrent: $CONCURRENT"
echo "  Delay:      ${DELAY}s"
echo ""

# Check if server is running
echo -n "Checking server health... "
if ! curl -sf "${BASE_URL}/health" > /dev/null 2>&amp;1; then
    echo -e "${RED}FAILED${NC}"
    echo "Server not responding at $BASE_URL"
    echo "Start the server with: npm start"
    exit 1
fi
echo -e "${GREEN}OK${NC}"

# Test endpoints one by one
test_endpoint() {
    local method=$1
    local endpoint=$2
    local expected=$3
    local description=$4

    local url="${BASE_URL}${endpoint}"
    local response
    local status

    if [ "$method" = "POST" ] || [ "$method" = "PUT" ]; then
        response=$(curl -s -w "\n%{http_code}" -X "$method" -H "Content-Type: application/json" -d '{"test":"data"}' "$url" 2>/dev/null || echo -e "\n000")
    else
        response=$(curl -s -w "\n%{http_code}" -X "$method" "$url" 2>/dev/null || echo -e "\n000")
    fi

    status=$(echo "$response" | tail -n1)

    if [ "$status" = "$expected" ]; then
        echo -e "${GREEN}✓${NC} $method $endpoint - $description"
    else
        echo -e "${RED}✗${NC} $method $endpoint - Expected $expected, got $status"
    fi
}

echo ""
echo "Testing endpoints..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Success routes
test_endpoint "GET" "/success/200" "200" "GET success"
test_endpoint "GET" "/success/accepted" "202" "Accepted"
test_endpoint "GET" "/success/delete" "200" "DELETE success"
test_endpoint "POST" "/success/post" "201" "POST success"
test_endpoint "PUT" "/success/update" "200" "PUT success"

# Error routes
test_endpoint "GET" "/error/handled" "500" "Handled error"
test_endpoint "GET" "/error/deleteFail" "500" "DELETE failure"
test_endpoint "GET" "/error/updateFail" "500" "PUT failure"
test_endpoint "GET" "/error/custom-span" "500" "Custom span error"

# External and slow
test_endpoint "GET" "/outgoing/httpbin" "200" "External HTTP call"
test_endpoint "GET" "/outgoing/httpbin?fail=true" "500" "External failure"

# Health checks
test_endpoint "GET" "/health" "200" "Health check"
test_endpoint "GET" "/ready" "200" "Readiness check"
test_endpoint "GET" "/metrics" "200" "Metrics"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Generate load if hey or ab is available
generate_load() {
    echo "Generating load: $REQUESTS requests with $CONCURRENT concurrent connections..."

    if command -v hey &> /dev/null; then
        hey -n "$REQUESTS" -c "$CONCURRENT" -m GET "${BASE_URL}/success/200" > /dev/null 2>&amp;1
    elif command -v ab &> /dev/null; then
        ab -n "$REQUESTS" -c "$CONCURRENT" "${BASE_URL}/success/200" > /dev/null 2>&amp;1
    else
        echo "Installing load generation tools..."
        if command -v apt-get &> /dev/null; then
            sudo apt-get update > /dev/null 2>&amp;1 && sudo apt-get install -y apache2-utils > /dev/null 2>&amp;1
        elif command -v yum &> /dev/null; then
            sudo yum install -y httpd-tools > /dev/null 2>&amp;1
        fi

        # Fallback to curl loop
        echo "Using curl for load generation (slower)..."
        for i in $(seq 1 "$REQUESTS"); do
            curl -sf "${BASE_URL}/success/200" > /dev/null &
            if [ $((i % CONCURRENT)) -eq 0 ]; then
                wait
            fi
        done
        wait
    fi

    echo -e "${GREEN}Load generation complete${NC}"
}

# Menu
case "${1:-test}" in
    test)
        echo "Basic testing complete!"
        ;;
    load)
        generate_load
        ;;
    full)
        generate_load
        echo ""
        echo "Simulating error scenarios..."
        for i in {1..10}; do
            curl -sf "${BASE_URL}/error/handled" > /dev/null &
            curl -sf "${BASE_URL}/error/custom-span" > /dev/null &
            wait
        done
        echo -e "${GREEN}Error simulation complete${NC}"
        ;;
    *)
        echo "Usage: $0 [test|load|full]"
        echo "  test - Run endpoint tests (default)"
        echo "  load - Generate traffic load"
        echo "  full - Run tests + load + error simulation"
        exit 1
        ;;
esac

echo ""
echo "Current metrics:"
curl -sf "${BASE_URL}/metrics" | python3 -m json.tool 2>/dev/null || curl -sf "${BASE_URL}/metrics"
echo ""
echo -e "${GREEN}Done!${NC}"
