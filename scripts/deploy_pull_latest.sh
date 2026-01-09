#!/usr/bin/env bash
# Pull and restart latest GHCR image for Visualizer Backend
# Usage: ./deploy_pull_latest.sh ghcr.io/<owner>/<repo>-visualizer-backend:latest

set -euo pipefail
IMAGE_REF=${1:-}
CONTAINER_NAME=${CONTAINER_NAME:-visualizer-backend}
PORT=${PORT:-8000}
ENV_FILE=${ENV_FILE:-/opt/visualizer/.env}
MODELS_DIR=${MODELS_DIR:-/opt/visualizer/models}
SECRETS_DIR=${SECRETS_DIR:-/opt/visualizer/secrets}

if [[ -z "$IMAGE_REF" ]]; then
  echo "Usage: $0 ghcr.io/<owner>/<repo>-visualizer-backend:latest" >&2
  exit 1
fi

echo "Pulling $IMAGE_REF ..."
docker pull "$IMAGE_REF"

# Stop and remove existing container if present
if docker ps -a --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}$"; then
  echo "Stopping ${CONTAINER_NAME} ..."
  docker stop "$CONTAINER_NAME" || true
  echo "Removing ${CONTAINER_NAME} ..."
  docker rm "$CONTAINER_NAME" || true
fi

echo "Starting ${CONTAINER_NAME} ..."
docker run -d \
  --name "$CONTAINER_NAME" \
  --restart unless-stopped \
  --env-file "$ENV_FILE" \
  -v "$MODELS_DIR":/models:ro \
  -v "$SECRETS_DIR":/secrets:ro \
  -p ${PORT}:8000 \
  "$IMAGE_REF"

echo "Deployment complete. Health check:"
curl -sSf http://127.0.0.1:${PORT}/health || true
