#!/bin/bash

# --- USAGE ---
# ./simulate.sh

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

SLOW_ENDPOINT="/slow/timeout"
OUTGOING_ENDPOINT="/outgoing/httpbin"
BASE_URL="http://localhost:3000"

send_random_request() {
  local -n endpoints=$1
  local index=$((RANDOM % ${#endpoints[@]}))
  local full_url="$BASE_URL${endpoints[$index]}"
  echo "→ Hitting $full_url"
  curl -s -o /dev/null -w "%{http_code}\n" "$full_url"
}

maybe_send_slow() {
  local chance=$((RANDOM % 10))
  if [ $chance -eq 0 ]; then
    echo "🐢 Triggering slow request: $BASE_URL$SLOW_ENDPOINT"
    curl -s -o /dev/null -w "%{http_code}\n" "$BASE_URL$SLOW_ENDPOINT" &
  fi
}

while true; do
  echo "🔁 Triggering batch at $(date)"

  send_random_request SUCCESS_ENDPOINTS
  send_random_request ERROR_ENDPOINTS

  echo "🌐 Outgoing: $BASE_URL$OUTGOING_ENDPOINT"
  curl -s -o /dev/null -w "%{http_code}\n" "$BASE_URL$OUTGOING_ENDPOINT" &

  maybe_send_slow

  echo "⏱ Sleeping for 10 seconds..."
  sleep 10
done
