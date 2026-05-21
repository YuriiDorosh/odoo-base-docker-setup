#!/usr/bin/env bash
#
# Restore a .sql or .dump file into a (re)created Odoo database.
#
# Usage:
#   ./scripts/restore-db.sh backups/prod_2025-10-14.sql
#   ./scripts/restore-db.sh backups/file.dump target_db_name
#
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

# shellcheck disable=SC1091
source .env

FILE="${1:?Path to backup file required (.sql or .dump)}"
DB_NAME="${2:-${ODOO_DB:-prod}}"
DB_CONTAINER="${DB_CONTAINER:-postgres}"

if [[ ! -f "$FILE" ]]; then
  echo "[restore] File not found: $FILE" >&2
  exit 1
fi

echo "[restore] Dropping (if exists) and recreating database '$DB_NAME'..."
docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" "$DB_CONTAINER" \
  psql -U "${POSTGRES_USER}" -d postgres -c "DROP DATABASE IF EXISTS \"$DB_NAME\";"
docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" "$DB_CONTAINER" \
  psql -U "${POSTGRES_USER}" -d postgres -c "CREATE DATABASE \"$DB_NAME\" OWNER \"${POSTGRES_USER}\";"

case "$FILE" in
  *.sql)
    echo "[restore] Loading SQL dump..."
    docker exec -i -e PGPASSWORD="${POSTGRES_PASSWORD}" "$DB_CONTAINER" \
      psql -U "${POSTGRES_USER}" -d "$DB_NAME" < "$FILE"
    ;;
  *.dump|*.pgdump|*.custom)
    echo "[restore] Loading pg_restore custom dump..."
    docker exec -i -e PGPASSWORD="${POSTGRES_PASSWORD}" "$DB_CONTAINER" \
      pg_restore -U "${POSTGRES_USER}" -d "$DB_NAME" --no-owner --clean --if-exists < "$FILE"
    ;;
  *)
    echo "[restore] Unknown format for $FILE. Use .sql or .dump." >&2
    exit 2
    ;;
esac

echo "[restore] Done. Database '$DB_NAME' restored from $FILE"
