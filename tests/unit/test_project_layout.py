"""Smoke tests for the repository layout.

These are intentionally cheap and require nothing more than the filesystem —
they protect against accidentally deleting top-level files or breaking the
expected folder structure.
"""
from __future__ import annotations

from pathlib import Path

import pytest

pytestmark = pytest.mark.unit


REQUIRED_TOP_LEVEL = [
    "Makefile",
    "README.md",
    ".env.example",
    ".gitignore",
    "pyproject.toml",
    "docker_compose",
    "src",
    "scripts",
    "docs",
    "requirements",
    "backups",
    "logs",
    "tests",
]


REQUIRED_COMPOSE_FILES = [
    "docker_compose/db/docker-compose.yml",
    "docker_compose/odoo/docker-compose.yml",
    "docker_compose/pgadmin/docker-compose.yml",
    "docker_compose/adminer/docker-compose.yml",
    "docker_compose/message_brokers/rabbitmq/docker-compose.yml",
    "docker_compose/message_brokers/kafka/docker-compose.yml",
    "docker_compose/redis/docker-compose.yml",
    "docker_compose/monitoring/docker-compose.yml",
]


REQUIRED_SCRIPTS = [
    "scripts/init.sh",
    "scripts/backup-db.sh",
    "scripts/restore-db.sh",
    "scripts/install-addon.sh",
    "scripts/upgrade-addon.sh",
    "scripts/shell.sh",
    "scripts/psql.sh",
    "scripts/healthcheck.sh",
    "scripts/clean-backups.sh",
    "scripts/wait-for-postgres.sh",
    "scripts/lint-addons.sh",
]


@pytest.mark.parametrize("rel_path", REQUIRED_TOP_LEVEL)
def test_top_level_entry_exists(project_root: Path, rel_path: str) -> None:
    assert (project_root / rel_path).exists(), f"missing: {rel_path}"


@pytest.mark.parametrize("rel_path", REQUIRED_COMPOSE_FILES)
def test_compose_file_exists(project_root: Path, rel_path: str) -> None:
    assert (project_root / rel_path).is_file(), f"missing compose file: {rel_path}"


@pytest.mark.parametrize("rel_path", REQUIRED_SCRIPTS)
def test_script_exists_and_is_executable(project_root: Path, rel_path: str) -> None:
    path = project_root / rel_path
    assert path.is_file(), f"missing script: {rel_path}"
    assert path.stat().st_mode & 0o111, f"script not executable: {rel_path}"
