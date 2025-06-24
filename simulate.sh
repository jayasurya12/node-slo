#!/bin/bash

# --- USAGE ---
# ./simulate.sh 100 70
# Runs continuously: 100 requests per batch, 70% success, 30% error

TOTAL_REQUESTS=$1
SUCCESS_PERCENT=$2

# 🛑 Validate input
if [ -z "$TOTAL_REQUESTS" ] || [ -z "$SUCCESS_PERCENT" ]; then
  echo "❗ Usage: ./simulate.sh <total_requests> <success_percent>"
  exit 1
fi

ERROR_PERCENT=$((100 - SUCCESS_PERCENT))
BASE_URL="http://localhost:3000"

SUCCESS_ENDPOINTS=(
  "/success/200"
  "/success/201"
  "/success/202"
)

ERROR_ENDPOINTS=(
  "/error/unhandled"
  "/error/handled"
  "/error/async"
  "/error/custom-span"
)

# 🛰 Send a random request and return status
send_random_request() {
  local -n endpoints=$1
  RANDOM_INDEX=$((RANDOM % ${#endpoints[@]}))
  FULL_URL="$BASE_URL${endpoints[$RANDOM_INDEX]}"
  STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$FULL_URL")
  echo "→ $FULL_URL | Status: $STATUS_CODE"
  echo "$STATUS_CODE"
}

# 🔁 Run batches forever
while true; do
  echo "🚀 Sending $TOTAL_REQUESTS requests: $SUCCESS_PERCENT% success, $ERROR_PERCENT% error..."

  success_count=0
  error_count=0

  for ((i=1; i<=TOTAL_REQUESTS; i++)); do
    CHANCE=$((RANDOM % 100))
    if [ $CHANCE -lt $SUCCESS_PERCENT ]; then
      status=$(send_random_request SUCCESS_ENDPOINTS)
    else
      status=$(send_random_request ERROR_ENDPOINTS)
    fi

    if [[ "$status" =~ ^2[0-9][0-9]$ ]]; then
      ((success_count++))
    else
      ((error_count++))
    fi
  done

  echo "✅ Batch complete: Success=$success_count | Error=$error_count"
  echo "-------------------------------------------"
  sleep 1
done
