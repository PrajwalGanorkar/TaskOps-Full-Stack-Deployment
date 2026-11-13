#!/bin/sh
# Pull the published images and (re)start the stack. Run from the folder that holds docker-compose.yml.
#   DOCKERHUB_USER=<namespace> IMAGE_TAG=<tag> sh deploy.sh
# Works the same on a local machine, a self-hosted Jenkins agent, or the EC2 server.
set -eu

: "${DOCKERHUB_USER:?DOCKERHUB_USER must be set (Docker Hub namespace that holds the images)}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
export DOCKERHUB_USER IMAGE_TAG

# First deploy on a fresh machine: generate a random secret instead of shipping one in git.
if [ ! -f .env ]; then
  echo ">> .env not found - generating one with a random DJANGO_SECRET_KEY"
  SECRET="${DJANGO_SECRET_KEY:-$(head -c 48 /dev/urandom | base64 | tr -d '\n=+/')}"
  ( umask 077; printf 'DJANGO_SECRET_KEY=%s\nDEBUG=False\n' "$SECRET" > .env )
fi

echo ">> Pulling ${DOCKERHUB_USER}/taskops-*:${IMAGE_TAG}"
docker compose pull
echo ">> Starting stack"
docker compose up -d --remove-orphans

echo ">> Waiting for the app to become healthy"
i=0
until docker compose exec -T frontend wget -qO- http://127.0.0.1:8080/api/health/ >/dev/null 2>&1; do
  i=$((i+1))
  if [ "$i" -ge 30 ]; then
    echo "!! Health check failed after 2 minutes. Recent logs:"
    docker compose logs --tail=50
    exit 1
  fi
  sleep 4
done
echo ">> Deployment OK"
docker compose ps
