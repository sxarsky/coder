#!/usr/bin/env bash
# Build coder from source and start the SUT (coder + postgres).
# NOTE: The Go build inside Docker is heavy (~10-15 min on first run).
set -euo pipefail
cd "$(dirname "$0")"

echo "==> Building coder from source + starting services (may take 10-15 min on first run)..."
docker compose -f docker-compose.yml up -d --build

echo "==> Waiting for coder to be healthy (up to 15 min)..."
for i in $(seq 1 300); do
  if curl -sf -m5 http://localhost:8093/healthz 2>/dev/null | grep -qi "ok"; then
    echo "==> Coder is healthy after $((i * 3)) seconds."
    break
  fi
  if [ "$i" = 300 ]; then
    echo "ERROR: coder did not become healthy within 15 minutes."
    echo "--- coder logs ---"
    docker compose -f docker-compose.yml logs --tail 100 coder
    exit 1
  fi
  sleep 3
done

echo "==> Setup complete. Coder is running at http://localhost:8093"
echo "    Swagger spec: http://localhost:8093/swagger/doc.json"
