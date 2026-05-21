#!/usr/bin/env bash
#
# Run pylint-odoo / ruff against the custom addons in src/addons.
# Assumes pylint-odoo + ruff are installed (see requirements/dev-requirements.txt).
#
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ADDONS_DIR="${ROOT_DIR}/src/addons"

if ! command -v pylint >/dev/null 2>&1; then
  echo "pylint not found. Install dev requirements: pip install -r requirements/dev-requirements.txt" >&2
  exit 1
fi

echo "[lint] ruff..."
ruff check "$ADDONS_DIR" || true

echo "[lint] pylint-odoo..."
pylint --load-plugins=pylint_odoo \
       --disable=all \
       --enable=odoolint \
       "$ADDONS_DIR" || true

echo "[lint] Done."
