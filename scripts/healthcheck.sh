#!/usr/bin/env bash
#
# Quick "is everything running?" report for the stack.
#
set -euo pipefail

containers=(
  postgres
  odoo
  nginx
  pgadmin
  adminer-postgres
  rabbitmq
  kafka
  redis
  redis_commander
  prometheus
  grafana
  node_exporter
  postgres_exporter
  redis_exporter
  cadvisor
)

printf "%-22s %-12s %-25s\n" "CONTAINER" "STATUS" "HEALTH"
printf "%-22s %-12s %-25s\n" "---------" "------" "------"

for c in "${containers[@]}"; do
  if ! docker inspect "$c" >/dev/null 2>&1; then
    printf "%-22s %-12s %-25s\n" "$c" "missing" "-"
    continue
  fi
  status=$(docker inspect -f '{{.State.Status}}' "$c")
  health=$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}n/a{{end}}' "$c")
  printf "%-22s %-12s %-25s\n" "$c" "$status" "$health"
done
