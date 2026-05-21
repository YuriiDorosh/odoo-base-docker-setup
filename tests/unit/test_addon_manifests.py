"""Sanity-check the ``__manifest__.py`` of every bundled addon."""
from __future__ import annotations

import ast
from pathlib import Path

import pytest

pytestmark = pytest.mark.unit


def _load_manifest(manifest_path: Path) -> dict:
    """Parse a manifest file safely (no exec) using ``ast.literal_eval``."""
    return ast.literal_eval(manifest_path.read_text())


def _addon_manifests(addons_dir: Path) -> list[Path]:
    return sorted(addons_dir.glob("*/__manifest__.py"))


def test_addons_dir_is_not_empty(addons_dir: Path) -> None:
    assert addons_dir.is_dir()
    assert _addon_manifests(addons_dir), "no addons found in src/addons"


@pytest.mark.parametrize(
    "manifest_path",
    _addon_manifests(Path(__file__).resolve().parents[2] / "src" / "addons"),
    ids=lambda p: p.parent.name,
)
def test_manifest_has_required_keys(manifest_path: Path) -> None:
    manifest = _load_manifest(manifest_path)

    for required in ("name", "version", "depends"):
        assert required in manifest, f"{manifest_path.parent.name}: missing '{required}'"

    assert isinstance(manifest["depends"], list), "depends must be a list"
    assert manifest.get("installable", True), (
        f"{manifest_path.parent.name}: installable must be True (or omitted)"
    )

    version = str(manifest["version"])
    assert version.startswith("18."), (
        f"{manifest_path.parent.name}: version '{version}' is not pinned to Odoo 18"
    )
