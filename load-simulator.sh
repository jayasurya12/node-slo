#!/bin/bash

# SLO Load Testing Simulator
# Enterprise-grade script for testing SLO/SLI with Datadog, New Relic, or Atatus
# Usage: ./load-simulator.sh [endpoint] [duration_seconds] [rps]

set -e

# Configuration
HOST="${SLO_HOST:-http://localhost:3000}"
ENDPOINT="${1:-all}"
DURATION="${2:-60}"
RPS="${3:-10}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Check dependencies
check_deps() {
    local deps=("curl" "jq")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            log_error "$dep is required but not installed."
            exit 1
        fi
    done
}

# Health check before starting
health_check() {
    log_info "Checking if server is healthy at $HOST..."
    if curl -sf "$HOST/health" > /dev/null 2>&1; then
        log_success "Server is healthy"
    else
        log_error "Server is not responding at $HOST"
        exit 1
    fi
}

# Send request and log result
send_request() {
    local method="$1"
    local url="$2"
    local data="${3:-}"
    local start_time end_time duration_ms

    start_time=$(date +%s%N)

    if [ "$method" == "GET" ]; then
        response=$(curl -s -w "\n%{http_code}" -o /dev/null "$url" 2>/dev/null || echo "000")
    else
        response=$(curl -s -w "\n%{http_code}" -X "$method" \
            -H "Content-Type: application/json" \
            -d "$data" \
            -o /dev/null "$url" 2>/dev/null || echo "000")
    fi

    end_time=$(date +%s%N)
    duration_ms=$(( (end_time - start_time) / 1000000 ))

    if [ "$response" -ge 200 ] && [ "$response" -lt 300 ]; then
        echo -e "${GREEN}✓${NC} $method $url (${duration_ms}ms)"
    elif [ "$response" -ge 400 ]; then
        echo -e "${RED}✗${NC} $method $url (${duration_ms}ms) - HTTP $response"
    else
        echo -e "${YELLOW}?${NC} $method $url (${duration_ms}ms) - HTTP $response"
    fi
}

# Success endpoint tests
test_success() {
    log_info "Testing success endpoints..."
    local endpoints=("/success/200" "/success/accepted" "/success/delete")
    for ep in "${endpoints[@]}"; do
        send_request "GET" "$HOST$ep"
    done
    send_request "POST" "$HOST/success/post" '{"test": "data"}'
    send_request "PUT" "$HOST/success/update" '{"test": "data"}'
}

# Error endpoint tests
test_errors() {
    log_info "Testing error endpoints..."
    local endpoints=("/error/handled" "/error/deleteFail" "/error/updateFail")
    for ep in "${endpoints[@]}"; do
        send_request "GET" "$HOST$ep"
    done
    # Test JSON parse error
    send_request "POST" "$HOST/error/json" "invalid json here"
}

# External calls
test_external() {
    log_info "Testing external calls..."
    send_request "GET" "$HOST/outgoing/httpbin"
    send_request "GET" "$HOST/outgoing/httpbin?fail=true"
}

# Slow endpoint
test_slow() {
    log_info "Testing slow endpoint (10s timeout instead of 120s)..."
    curl -s -m 10 "$HOST/slow/timeout" || log_warn "Slow endpoint timed out (expected)"
}

# Load test with concurrent requests
run_load_test() {
    log_info "Starting load test: $RPS RPS for $DURATION seconds"
    log_info "Target: $HOST"

    local start_time end_time elapsed
    start_time=$(date +%s)
    local total_requests=0
    local successful_requests=0
    local failed_requests=0

    while true; do
        current_time=$(date +%s)
        elapsed=$((current_time - start_time))

        if [ $elapsed -ge $DURATION ]; then
            break
        fi

        # Send RPS requests
        for ((i=0; i<RPS; i++)); do
            (
                response=$(curl -s -o /dev/null -w "%{http_code}" "$HOST/success/200" || echo "000")
                if [ "$response" -ge 200 ] && [ "$response" -lt 300 ]; then
                    ((successful_requests++))
                else
                    ((failed_requests++))
                fi
            ) &
        done

        total_requests=$((total_requests + RPS))
        wait

        # Progress bar
        local progress=$((elapsed * 100 / DURATION))
        printf "\rProgress: [%s%-*s] %d%% (%d/%d seconds)"
            "$(printf '#%.0s' $(seq 1 $((progress / 2))))"
            $((50 - progress / 2)) "" "$progress" "$elapsed" "$DURATION"

        sleep 1
    done

    echo # New line after progress bar
    log_success "Load test completed"
    log_info "Total requests: $total_requests"
    log_info "Successful: $successful_requests"
    log_info "Failed: $failed_requests"

    # Show metrics
    log_info "Fetching metrics..."
    curl -s "$HOST/metrics" | jq . || log_warn "Could not fetch metrics"
}

# Main execution
main() {
    echo "=========================================="
    echo "  SLO Testing Load Simulator"
    echo "=========================================="
    echo ""

    check_deps
    health_check

    case "$ENDPOINT" in
        success)
            test_success
            ;;
        error)
            test_errors
            ;;
        external)
            test_external
            ;;
        slow)
            test_slow
            ;;
        load)
            run_load_test
            ;;
        all|*)
            test_success
            test_errors
            test_external
            test_slow
            ;;
    esac

    echo ""
    log_success "Testing completed!"
}

# Handle script interruption
trap 'echo; log_warn "Interrupted by user"; exit 130' INT

main