#!/usr/bin/env bash
#
# Install or upgrade an Odoo addon on a running odoo container.
#
# Usage:
#   ./scripts/install-addon.sh <addon_name> [database]
#   ./scripts/install-addon.sh web_notify prod
#
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

# shellcheck disable=SC1091
source .env

ADDON="${1:?Addon technical name required}"
DB_NAME="${2:-${ODOO_DB:-prod}}"
ODOO_CONTAINER="${ODOO_CONTAINER:-odoo}"

echo "[addon] Installing/upgrading '$ADDON' on database '$DB_NAME'..."
docker exec -it "$ODOO_CONTAINER" \
  odoo -c /etc/odoo/odoo.conf \
       -d "$DB_NAME" \
       -i "$ADDON" \
       --stop-after-init \
       --no-http
echo "[addon] Done."
