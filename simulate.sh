#!/bin/bash

# --- Default Config ---
SUCCESS_PERCENT=70
ERROR_REQUESTS=10
SLEEP_SECONDS=5
ROUNDS=-1
SERVER_CHECK_RETRIES=5
SERVER_URL="http://localhost:3000"
EXTERNAL_CALL="no"

# --- Parse Arguments ---
while [[ $# -gt 0 ]]; do
  key="$1"
  val="$2"
  case "$key" in
    success) SUCCESS_PERCENT=$val; shift 2 ;;
    error) ERROR_REQUESTS=$val; shift 2 ;;
    waitevent) SLEEP_SECONDS=$val; shift 2 ;;
    round) ROUNDS=$val; shift 2 ;;
    externalcall) EXTERNAL_CALL=$val; shift 2 ;;
    *) echo "⚠️ Unknown argument: $key"; shift ;;
  esac
done

# --- Internal Routes ---
SUCCESS_ENDPOINTS=(
  "/success/200"
  "/success/201"
  "/success/202"
  "/success/update"
)

ERROR_ENDPOINTS=(
  "/error/unhandled"
  "/error/handled"
  "/error/async"
  "/error/custom-span"
  "/error/deleteFail"
  "/error/updateFail"
)

# --- External URLs by Status Code Category ---
EXTERNAL_SUCCESS=(
  "https://httpstat.us/200"
  "https://httpstat.us/201"
  "https://httpstat.us/204"
)

EXTERNAL_REDIRECT=(
  "https://httpstat.us/301"
  "https://httpstat.us/302"
)

EXTERNAL_CLIENT_ERROR=(
  "https://httpstat.us/400"
  "https://httpstat.us/403"
  "https://httpstat.us/404"
)

EXTERNAL_SERVER_ERROR=(
  "https://httpstat.us/500"
  "https://httpstat.us/502"
  "https://httpstat.us/503"
)

EXTERNAL_TIMEOUT=(
  "https://httpstat.us/200?sleep=5000"
)

SLOW_ENDPOINT="/slow/timeout"
BASE_URL="$SERVER_URL"

# --- Check if server is up ---
check_server_ready() {
  for ((i=1; i<=SERVER_CHECK_RETRIES; i++)); do
    code=$(curl -s -o /dev/null -w "%{http_code}" "$SERVER_URL")
    if [[ "$code" =~ ^2|3 ]]; then
      echo "✅ Server ready at $SERVER_URL"
      return 0
    fi
    echo "⏳ Waiting for server... ($i/$SERVER_CHECK_RETRIES)"
    sleep 2
  done
  echo "❌ Server not ready. Exiting."
  exit 1
}

# --- Send one request to random internal success/error endpoint ---
send_random_request() {
  local -n endpoints=$1
  local url="$BASE_URL${endpoints[$((RANDOM % ${#endpoints[@]}))]}"
  echo "🌐 Internal → $url"
  curl -s -o /dev/null -w "%{http_code}\n" "$url"
}

# --- Optional: slow endpoint ---
maybe_send_slow() {
  if [ $((RANDOM % 10)) -eq 0 ]; then
    echo "🐢 Slow → $BASE_URL$SLOW_ENDPOINT"
    curl -s -o /dev/null -w "%{http_code}\n" "$BASE_URL$SLOW_ENDPOINT" &
  fi
}

# --- Send a random external call by category ---
send_random_external_request() {
  case $((RANDOM % 5)) in
    0) url="${EXTERNAL_SUCCESS[$((RANDOM % ${#EXTERNAL_SUCCESS[@]}))]}"; label="✅ SUCCESS" ;;
    1) url="${EXTERNAL_REDIRECT[$((RANDOM % ${#EXTERNAL_REDIRECT[@]}))]}"; label="↪️ REDIRECT" ;;
    2) url="${EXTERNAL_CLIENT_ERROR[$((RANDOM % ${#EXTERNAL_CLIENT_ERROR[@]}))]}"; label="🚫 CLIENT ERROR" ;;
    3) url="${EXTERNAL_SERVER_ERROR[$((RANDOM % ${#EXTERNAL_SERVER_ERROR[@]}))]}"; label="💥 SERVER ERROR" ;;
    4) url="${EXTERNAL_TIMEOUT[$((RANDOM % ${#EXTERNAL_TIMEOUT[@]}))]}"; label="🐢 TIMEOUT" ;;
  esac

  echo "$label → $url"
  curl -s -o /dev/null -w "%{http_code}\n" "$url"
}

# --- Main Simulation ---
check_server_ready
current_round=0

while [[ $ROUNDS -eq -1 || $current_round -lt $ROUNDS ]]; do
  echo -e "\n🔁 Round $((current_round+1)) @ $(date)"

  if [ "$ERROR_REQUESTS" -gt 0 ]; then
    for ((i=1; i<=ERROR_REQUESTS; i++)); do
      CHANCE=$((RANDOM % 100))
      if [ $CHANCE -lt $SUCCESS_PERCENT ]; then
        send_random_request SUCCESS_ENDPOINTS
      else
        send_random_request ERROR_ENDPOINTS
      fi
    done
  else
    echo "⚠️ Skipping internal requests (error=0)"
  fi

  if [[ "$EXTERNAL_CALL" == "yes" ]]; then
    send_random_external_request
  else
    echo "❌ Skipping external call (externalcall=no)"
  fi

  maybe_send_slow

  echo "⏱ Sleeping $SLEEP_SECONDS seconds..."
  sleep $SLEEP_SECONDS
  current_round=$((current_round + 1))
done

echo "✅ Simulation completed."
