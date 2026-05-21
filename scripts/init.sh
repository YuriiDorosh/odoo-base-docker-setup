#!/usr/bin/env bash
#
# Bootstrap a fresh checkout: create .env from .env.example, ensure the docker
# network exists, and make sure backup/log folders are present.
#
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

NETWORK_NAME="${NETWORK_NAME:-backend}"

if [[ ! -f .env ]]; then
  cp .env.example .env
  echo "[init] Created .env from .env.example — review and update secrets!"
else
  echo "[init] .env already exists, skipping."
fi

mkdir -p backups logs/nginx logs/odoo docker_compose/db/backups

if ! docker network ls --format '{{.Name}}' | grep -qx "$NETWORK_NAME"; then
  docker network create "$NETWORK_NAME"
  echo "[init] Created docker network '$NETWORK_NAME'."
else
  echo "[init] Docker network '$NETWORK_NAME' already exists."
fi

echo "[init] Done. Next: make up-all"
