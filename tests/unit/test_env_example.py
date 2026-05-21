"""Validate ``.env.example`` declares every key the stack relies on."""
from __future__ import annotations

from pathlib import Path

import pytest

pytestmark = pytest.mark.unit


REQUIRED_KEYS = {
    # Postgres
    "POSTGRES_DB",
    "POSTGRES_USER",
    "POSTGRES_PASSWORD",
    "ODOO_DB",
    # Odoo / nginx
    "ODOO_ADMIN_PASSWD",
    "NGINX_PORT",
    # pgAdmin
    "PGADMIN_DEFAULT_EMAIL",
    "PGADMIN_DEFAULT_PASSWORD",
    # Redis
    "REDIS_PORT",
    "REDIS_PASSWORD",
    "REDIS_UI_PORT",
    "REDIS_UI_USER",
    "REDIS_UI_PASSWORD",
    # RabbitMQ
    "RABBITMQ_USER",
    "RABBITMQ_PASSWORD",
    "RABBITMQ_VHOST",
    "RABBITMQ_PORT",
    "RABBITMQ_UI_PORT",
    "RABBITMQ_PROM_PORT",
    # Kafka
    "KAFKA_EXTERNAL_HOST",
    "KAFKA_EXTERNAL_PORT",
    "KAFKA_UI_PORT",
    # Monitoring
    "PROMETHEUS_PORT",
    "GRAFANA_PORT",
    "GRAFANA_USER",
    "GRAFANA_PASSWORD",
}


def test_env_example_declares_all_required_keys(project_root: Path) -> None:
    env_path = project_root / ".env.example"
    assert env_path.exists(), ".env.example is missing"

    declared = {
        line.split("=", 1)[0].strip()
        for line in env_path.read_text().splitlines()
        if line.strip() and not line.strip().startswith("#") and "=" in line
    }

    missing = REQUIRED_KEYS - declared
    assert not missing, f"keys missing from .env.example: {sorted(missing)}"
