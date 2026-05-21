"""Project-wide pytest fixtures.

Fixtures here are available to every test file under ``tests/``. Addon tests
under ``src/addons/*/tests/`` are run by Odoo's own test loader (via
``pytest-odoo``) and have their own ``setUp``/``setUpClass`` instead.
"""
from __future__ import annotations

import os
from pathlib import Path
from typing import Iterator

import pytest


ROOT_DIR = Path(__file__).resolve().parents[1]


# ---------------------------------------------------------------------------
# Generic helpers
# ---------------------------------------------------------------------------
@pytest.fixture(scope="session")
def project_root() -> Path:
    """Absolute path to the repository root."""
    return ROOT_DIR


@pytest.fixture(scope="session")
def addons_dir(project_root: Path) -> Path:
    """Path to the custom addons directory."""
    return project_root / "src" / "addons"


@pytest.fixture(scope="session")
def compose_files(project_root: Path) -> dict[str, Path]:
    """Map of service name -> docker-compose.yml path."""
    base = project_root / "docker_compose"
    return {
        "db":           base / "db" / "docker-compose.yml",
        "odoo":         base / "odoo" / "docker-compose.yml",
        "pgadmin":      base / "pgadmin" / "docker-compose.yml",
        "adminer":      base / "adminer" / "docker-compose.yml",
        "rabbitmq":     base / "message_brokers" / "rabbitmq" / "docker-compose.yml",
        "kafka":        base / "message_brokers" / "kafka" / "docker-compose.yml",
        "redis":        base / "redis" / "docker-compose.yml",
        "monitoring":   base / "monitoring" / "docker-compose.yml",
    }


# ---------------------------------------------------------------------------
# Environment loading
# ---------------------------------------------------------------------------
@pytest.fixture(scope="session")
def env(project_root: Path) -> Iterator[dict[str, str]]:
    """Parse ``.env`` (or ``.env.example``) into a plain dict.

    Tests should prefer reading values from this fixture over ``os.environ``
    so they remain reproducible regardless of the host shell.
    """
    env_path = project_root / ".env"
    if not env_path.exists():
        env_path = project_root / ".env.example"

    values: dict[str, str] = {}
    if env_path.exists():
        for line in env_path.read_text().splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, _, value = line.partition("=")
            values[key.strip()] = value.strip().strip('"').strip("'")
    yield values


# ---------------------------------------------------------------------------
# Marker-based skips for environments without Docker
# ---------------------------------------------------------------------------
def pytest_collection_modifyitems(config: pytest.Config, items: list[pytest.Item]) -> None:
    """Auto-skip ``integration`` tests when ``RUN_INTEGRATION`` is unset."""
    if os.environ.get("RUN_INTEGRATION") in {"1", "true", "yes"}:
        return
    skip_marker = pytest.mark.skip(reason="set RUN_INTEGRATION=1 to enable")
    for item in items:
        if "integration" in item.keywords:
            item.add_marker(skip_marker)
