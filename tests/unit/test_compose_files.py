"""Static validation of every ``docker-compose.yml`` in the repo.

We don't *run* compose here — that would require Docker — but we make sure
each file:

* parses as YAML,
* declares a ``services`` mapping,
* every service joins the external ``backend`` network.
"""
from __future__ import annotations

from pathlib import Path

import pytest

yaml = pytest.importorskip("yaml")

pytestmark = pytest.mark.unit


def _all_compose_files(project_root: Path) -> list[Path]:
    return sorted(
        p
        for p in (project_root / "docker_compose").rglob("docker-compose*.yml")
        if p.stat().st_size > 0
    )


def test_at_least_one_compose_file(project_root: Path) -> None:
    assert _all_compose_files(project_root), "no docker-compose files found"


@pytest.mark.parametrize(
    "compose_path",
    _all_compose_files(Path(__file__).resolve().parents[2]),
    ids=lambda p: str(p.relative_to(Path(__file__).resolve().parents[2])),
)
def test_compose_is_valid(compose_path: Path) -> None:
    data = yaml.safe_load(compose_path.read_text())

    assert isinstance(data, dict), f"{compose_path}: top-level is not a mapping"
    assert "services" in data and isinstance(data["services"], dict), (
        f"{compose_path}: missing 'services' mapping"
    )
    assert data["services"], f"{compose_path}: 'services' is empty"

    # Every service should attach to the shared network.
    networks_decl = data.get("networks", {})
    backend_net = networks_decl.get("backend") if isinstance(networks_decl, dict) else None
    if backend_net is not None:
        assert backend_net.get("external") is True, (
            f"{compose_path}: 'backend' network must be declared external"
        )

    for name, svc in data["services"].items():
        if not isinstance(svc, dict):
            continue
        nets = svc.get("networks", [])
        # Some prod overlays might reference a different network — only enforce
        # 'backend' on dev compose files.
        if compose_path.name == "docker-compose.yml":
            assert "backend" in (nets or []), (
                f"{compose_path}: service '{name}' does not join the 'backend' network"
            )
