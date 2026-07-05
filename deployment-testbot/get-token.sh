#!/usr/bin/env bash
# Seed the first owner account (idempotent) and print a Coder session token.
# The token is printed to stdout so testbot can capture it.
set -euo pipefail

BASE_URL="${CODER_ACCESS_URL:-http://localhost:8093}"
EMAIL="${CODER_ADMIN_EMAIL:-admin@coder.test}"
USERNAME="${CODER_ADMIN_USERNAME:-testbot-admin}"
PASSWORD="${CODER_ADMIN_PASSWORD:-Password123!}"
NAME="${CODER_ADMIN_NAME:-Testbot Admin}"

# POST /api/v2/users/first creates the initial owner and returns a session_token.
# If the first user already exists the endpoint returns 400; in that case we
# log in instead to obtain a fresh token.
resp=$(curl -sf -m15 -X POST "${BASE_URL}/api/v2/users/first" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"${EMAIL}\",\"username\":\"${USERNAME}\",\"password\":\"${PASSWORD}\",\"name\":\"${NAME}\"}" \
  2>/dev/null) && true

if echo "$resp" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['session_token'])" 2>/dev/null; then
  # Successfully created first user — token extracted above
  exit 0
fi

# First user already exists — log in to get a token
resp=$(curl -sf -m15 -X POST "${BASE_URL}/api/v2/users/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\"}")

echo "$resp" | python3 -c "import json,sys; print(json.load(sys.stdin)['session_token'])"
