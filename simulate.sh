#!/bin/bash

# --- Default Values ---
SUCCESS_PERCENT=70
ERROR_REQUESTS=10
SLEEP_SECONDS=5
ROUNDS=-1  # -1 means infinite loop

# --- Parse Named Arguments ---
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
  esac
done

# --- Internals ---
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
BASE_URL="http://localhost:3000"

# --- Functions ---

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

  FAIL_ICON=""
  if [ $SHOULD_FAIL -eq 1 ]; then
    URL="$URL&fail=true"
    FAIL_ICON="❌"
  else
    FAIL_ICON="✅"
  fi

  echo "$EMOJI [HTTPBIN $METHOD] $FAIL_ICON → $URL"
  curl -s -o /dev/null -w "%{http_code}\n" "$URL" &
}

maybe_send_slow() {
  local chance=$((RANDOM % 10))
  if [ $chance -eq 0 ]; then
    echo "🐢 [SLOW] → $BASE_URL$SLOW_ENDPOINT"
    curl -s -o /dev/null -w "%{http_code}\n" "$BASE_URL$SLOW_ENDPOINT" &
  fi
}

# --- Execution ---
current_round=0
while [[ $ROUNDS -eq -1 || $current_round -lt $ROUNDS ]]; do
  echo ""
  echo "🔁 Round $((current_round+1)) @ $(date)"

  for ((i=1; i<=ERROR_REQUESTS; i++)); do
    CHANCE=$((RANDOM % 100))
    if [ $CHANCE -lt $SUCCESS_PERCENT ]; then
      send_random_request SUCCESS_ENDPOINTS
    else
      send_random_request ERROR_ENDPOINTS
    fi
  done

  random_method_httpbin_call
  maybe_send_slow

  echo "⏱ Sleeping for $SLEEP_SECONDS seconds..."
  sleep $SLEEP_SECONDS

  current_round=$((current_round + 1))
done

echo "✅ Simulation completed"
