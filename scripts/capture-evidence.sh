#!/bin/sh
# Saves text evidence of the running stack into screenshots/evidence.txt (supplement to real screenshots).
set -eu
OUT="screenshots/evidence.txt"
PORT="${HTTP_PORT:-80}"
{
  echo "Captured: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  echo; echo "### docker compose ps";            docker compose ps
  echo; echo "### GET /api/health/";             curl -fsS "http://localhost:${PORT}/api/health/"
  echo; echo; echo "### GET /api/metrics/";       curl -fsS "http://localhost:${PORT}/api/metrics/"
  echo; echo; echo "### running user (non-root check)"
  echo -n "backend : "; docker compose exec -T backend id
  echo -n "frontend: "; docker compose exec -T frontend id
  echo; echo "### image sizes"; docker images --format '{{.Repository}}:{{.Tag}}  {{.Size}}' | grep taskops
} > "$OUT" 2>&1
echo "Saved $OUT"
