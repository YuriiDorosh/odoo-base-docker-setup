#!/usr/bin/env bash
#
# Block until PostgreSQL is ready to accept connections. Useful in CI or in
# startup scripts before running migrations / module installs.
#
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

# shellcheck disable=SC1091
source .env

DB_CONTAINER="${DB_CONTAINER:-postgres}"
TIMEOUT="${1:-60}"
ELAPSED=0

echo "[wait] Waiting up to ${TIMEOUT}s for $DB_CONTAINER..."
until docker exec "$DB_CONTAINER" pg_isready -U "${POSTGRES_USER}" >/dev/null 2>&1; do
  sleep 2
  ELAPSED=$((ELAPSED + 2))
  if (( ELAPSED >= TIMEOUT )); then
    echo "[wait] Timed out after ${TIMEOUT}s" >&2
    exit 1
  fi
done
echo "[wait] PostgreSQL is ready (after ${ELAPSED}s)."
