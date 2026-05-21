#!/usr/bin/env bash
#
# Remove old backup files in ./backups older than N days (default: 14).
#
# Usage:
#   ./scripts/clean-backups.sh           # purges files older than 14 days
#   ./scripts/clean-backups.sh 30        # purges files older than 30 days
#
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DAYS="${1:-14}"
TARGETS=("${ROOT_DIR}/backups" "${ROOT_DIR}/docker_compose/db/backups")

for dir in "${TARGETS[@]}"; do
  if [[ -d "$dir" ]]; then
    echo "[clean] Removing files in $dir older than ${DAYS} days..."
    find "$dir" -type f ! -name '.gitkeep' -mtime +"$DAYS" -print -delete
  fi
done
echo "[clean] Done."
