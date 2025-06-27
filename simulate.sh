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

# --- Simulate External HTTP Methods using httpbin ---
send_random_external_request() {
  METHODS=("get" "post" "put" "delete")
  METHOD=${METHODS[$((RANDOM % 4))]}
  FAIL_CHANCE=$((RANDOM % 4 == 0))
  URL="https://httpbin.org/$METHOD"

  if [ $FAIL_CHANCE -eq 1 ]; then
    URL="https://httpbin.org/status/500"
  fi

  echo "🔁 External $METHOD → $URL"
  curl -s -o /dev/null -w "%{http_code}\n" -X $METHOD "$URL"
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
    echo "⚠️ Skipping internal error requests (error=0)"
    for ((i=1; i<=SUCCESS_PERCENT; i++)); do
      send_random_request SUCCESS_ENDPOINTS
    done
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
