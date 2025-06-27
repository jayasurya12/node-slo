#!/bin/bash

# --- Default Config Values ---
SUCCESS_PERCENT=70      # % of requests that should succeed
ERROR_REQUESTS=10       # Number of requests per round
SLEEP_SECONDS=5         # Time to wait between rounds (in seconds)
ROUNDS=-1               # Number of rounds (-1 = infinite)
SERVER_CHECK_RETRIES=5  # How many times to check if the server is up before giving up
SERVER_URL="http://localhost:3000"
EXTERNAL_CALL="no"      # Whether to send external API calls (yes or no)

# --- Parse CLI Arguments ---
# Example usage:
# ./simulator.sh success 90 error 10 waitevent 2 round 20 externalcall yes

for ((i=1; i<=$#; i++)); do
  arg=${!i}
  next=$((i+1))
  val=${!next}

  case "$arg" in
    success)
      SUCCESS_PERCENT=$val
      ;;
    error)
      ERROR_REQUESTS=$val
      ;;
    waitevent)
      SLEEP_SECONDS=$val
      ;;
    round)
      ROUNDS=$val
      ;;
    externalcall)
      EXTERNAL_CALL=$val
      ;;
  esac
done

# --- Endpoints Lists ---

# Successful endpoints to simulate success requests
SUCCESS_ENDPOINTS=(
  "/success/200"
  "/success/201"
  "/success/202"
  "/success/httpbin"
  "/success/update"
  "/outgoing/httpbin"
  "/outgoing/delete"
)

# Error endpoints to simulate error requests
ERROR_ENDPOINTS=(
  "/error/unhandled"
  "/error/handled"
  "/error/async"
  "/error/custom-span"
  "/error/deleteFail"
  "/error/updateFail"
)

# External URLs for optional external simulation
EXTERNAL_ENDPOINTS=(
  "https://httpbin.org/get"
  "https://jsonplaceholder.typicode.com/posts"
  "https://jsonplaceholder.typicode.com/comments"
  "https://httpstat.us/500"
  "https://httpstat.us/200?sleep=2000"
)

SLOW_ENDPOINT="/slow/timeout"
BASE_URL="$SERVER_URL"

# --- Check if the local server is ready before starting the test ---
check_server_ready() {
  for ((i=1; i<=SERVER_CHECK_RETRIES; i++)); do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$SERVER_URL")
    if [[ "$HTTP_CODE" =~ ^2|3 ]]; then
      echo "✅ Server is ready at $SERVER_URL"
      return 0
    fi
    echo "⏳ Waiting for server to be ready ($i/$SERVER_CHECK_RETRIES)..."
    sleep 2
  done

  echo "❌ Server not ready after $SERVER_CHECK_RETRIES attempts. Exiting."
  exit 1
}

# --- Function to randomly send a success or error request ---
send_random_request() {
  local -n endpoints=$1
  local index=$((RANDOM % ${#endpoints[@]}))
  local endpoint="${endpoints[$index]}"
  local full_url="$BASE_URL$endpoint"

  if [[ "$endpoint" == *"success"* ]]; then
    echo "✅ [SUCCESS] → $full_url"
  else
    echo "❌ [ERROR] → $full_url"
  fi

  curl -s -o /dev/null -w "%{http_code}\n" "$full_url"
}

# --- Simulate outgoing HTTP requests with various methods (GET, POST, etc.) ---
random_method_httpbin_call() {
  METHODS=("get" "post" "put" "delete")
  METHOD=${METHODS[$((RANDOM % 4))]}
  SHOULD_FAIL=$((RANDOM % 4 == 0))
  URL="$BASE_URL/outgoing/httpbin-method?method=$METHOD"

  EMOJI=""
  case "$METHOD" in
    get) EMOJI="🔍";;
    post) EMOJI="➕";;
    put) EMOJI="✏️";;
    delete) EMOJI="🗑️";;
  esac

  if [ $SHOULD_FAIL -eq 1 ]; then
    URL="$URL&fail=true"
    echo "$EMOJI [HTTPBIN $METHOD] ❌ → $URL"
  else
    echo "$EMOJI [HTTPBIN $METHOD] ✅ → $URL"
  fi

  curl -s -o /dev/null -w "%{http_code}\n" "$URL" &
}

# --- Occasionally simulate a slow endpoint ---
maybe_send_slow() {
  local chance=$((RANDOM % 10))
  if [ $chance -eq 0 ]; then
    echo "🐢 [SLOW] → $BASE_URL$SLOW_ENDPOINT"
    curl -s -o /dev/null -w "%{http_code}\n" "$BASE_URL$SLOW_ENDPOINT" &
  fi
}

# --- Simulate one random external API call ---
send_random_external_request() {
  local index=$((RANDOM % ${#EXTERNAL_ENDPOINTS[@]}))
  local url="${EXTERNAL_ENDPOINTS[$index]}"
  echo "🌐 [EXTERNAL] → $url"
  curl -s -o /dev/null -w "%{http_code}\n" "$url"
}

# --- Begin Simulation ---
check_server_ready

current_round=0
while [[ $ROUNDS -eq -1 || $current_round -lt $ROUNDS ]]; do
  echo ""
  echo "🔁 Round $((current_round+1)) @ $(date)"

  # Send multiple requests based on success/error chance
  for ((i=1; i<=ERROR_REQUESTS; i++)); do
    CHANCE=$((RANDOM % 100))
    if [ $CHANCE -lt $SUCCESS_PERCENT ]; then
      send_random_request SUCCESS_ENDPOINTS
    else
      send_random_request ERROR_ENDPOINTS
    fi
  done

  # Simulate random method HTTP request
  random_method_httpbin_call

  # Occasionally simulate slow response
  maybe_send_slow

  # Optionally call external services
  if [[ "$EXTERNAL_CALL" == "yes" ]]; then
    send_random_external_request
  fi

  echo "⏱ Sleeping for $SLEEP_SECONDS seconds..."
  sleep $SLEEP_SECONDS

  current_round=$((current_round + 1))
done

echo "✅ Simulation completed"
