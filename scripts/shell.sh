#!/usr/bin/env bash
#
# Open an Odoo interactive shell (Python REPL with env, models, registry).
#
# Usage:
#   ./scripts/shell.sh [database]
#
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

# shellcheck disable=SC1091
source .env

DB_NAME="${1:-${ODOO_DB:-prod}}"
ODOO_CONTAINER="${ODOO_CONTAINER:-odoo}"

docker exec -it "$ODOO_CONTAINER" \
  odoo shell -c /etc/odoo/odoo.conf -d "$DB_NAME" --no-http
