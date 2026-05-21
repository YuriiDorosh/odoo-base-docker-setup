#!/usr/bin/env bash
#
# On-demand pg_dump of the Odoo database into ./backups/.
#
# Usage:
#   ./scripts/backup-db.sh                  # dumps $ODOO_DB
#   ./scripts/backup-db.sh my_other_db      # dumps the given db
#
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

# shellcheck disable=SC1091
source .env

DB_NAME="${1:-${ODOO_DB:-prod}}"
DB_CONTAINER="${DB_CONTAINER:-postgres}"
TIMESTAMP="$(date +%Y-%m-%d_%H%M%S)"
OUT_DIR="${ROOT_DIR}/backups"
OUT_FILE="${OUT_DIR}/${DB_NAME}_${TIMESTAMP}.sql"

mkdir -p "$OUT_DIR"

echo "[backup] Dumping database '$DB_NAME' from container '$DB_CONTAINER'..."
docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" "$DB_CONTAINER" \
  pg_dump -U "${POSTGRES_USER}" -d "$DB_NAME" > "$OUT_FILE"

echo "[backup] Wrote $OUT_FILE ($(du -h "$OUT_FILE" | cut -f1))"
