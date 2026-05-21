"""The Makefile is our primary user interface — make sure key targets exist."""
from __future__ import annotations

import re
from pathlib import Path

import pytest

pytestmark = pytest.mark.unit


REQUIRED_TARGETS = {
    "help",
    "init",
    "network",
    "up",
    "down",
    "restart",
    "up-full",
    "down-full",
    "up-db",
    "down-db",
    "up-odoo",
    "down-odoo",
    "up-rabbitmq",
    "down-rabbitmq",
    "up-kafka",
    "down-kafka",
    "up-redis",
    "down-redis",
    "up-monitoring",
    "down-monitoring",
    "backup",
    "restore-db",
    "install-addon",
    "upgrade-addon",
    "health",
    "lint",
    "format",
}


def _declared_targets(makefile: Path) -> set[str]:
    """Return every Make target defined in the Makefile."""
    pattern = re.compile(r"^([A-Za-z0-9_-]+):.*", re.MULTILINE)
    return set(pattern.findall(makefile.read_text()))


def test_makefile_has_required_targets(project_root: Path) -> None:
    makefile = project_root / "Makefile"
    assert makefile.exists(), "Makefile is missing"

    declared = _declared_targets(makefile)
    missing = REQUIRED_TARGETS - declared
    assert not missing, f"Makefile is missing targets: {sorted(missing)}"
