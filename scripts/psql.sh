#!/usr/bin/env bash
#
# Open a psql session against the Odoo database.
#
# Usage:
#   ./scripts/psql.sh [database]
#
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

# shellcheck disable=SC1091
source .env

DB_NAME="${1:-${ODOO_DB:-postgres}}"
DB_CONTAINER="${DB_CONTAINER:-postgres}"

docker exec -it -e PGPASSWORD="${POSTGRES_PASSWORD}" "$DB_CONTAINER" \
  psql -U "${POSTGRES_USER}" -d "$DB_NAME"
