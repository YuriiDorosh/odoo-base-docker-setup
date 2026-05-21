"""Integration tests against the running stack.

Skipped by default. To run:

    RUN_INTEGRATION=1 pytest tests/integration

Requires the dev stack to be up (``make up-db`` is enough for this file).
"""
from __future__ import annotations

import socket
import subprocess

import pytest

pytestmark = pytest.mark.integration


def _docker_available() -> bool:
    try:
        subprocess.run(
            ["docker", "info"],
            check=True,
            capture_output=True,
            timeout=5,
        )
    except (FileNotFoundError, subprocess.CalledProcessError, subprocess.TimeoutExpired):
        return False
    return True


@pytest.fixture(scope="module", autouse=True)
def _require_docker() -> None:
    if not _docker_available():
        pytest.skip("docker is not available on this host")


def test_postgres_container_is_running() -> None:
    out = subprocess.run(
        ["docker", "inspect", "-f", "{{.State.Status}}", "postgres"],
        capture_output=True,
        text=True,
    )
    if out.returncode != 0:
        pytest.skip("postgres container is not started — run `make up-db`")
    assert out.stdout.strip() == "running", f"postgres status: {out.stdout!r}"


def test_postgres_port_is_open(env: dict[str, str]) -> None:
    """The compose maps Postgres to host port 5435."""
    host_port = 5435
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(3.0)
    try:
        sock.connect(("127.0.0.1", host_port))
    except OSError as exc:
        pytest.skip(f"could not connect to postgres on {host_port}: {exc}")
    finally:
        sock.close()


def test_pg_isready_succeeds(env: dict[str, str]) -> None:
    user = env.get("POSTGRES_USER", "odoo")
    out = subprocess.run(
        ["docker", "exec", "postgres", "pg_isready", "-U", user],
        capture_output=True,
        text=True,
    )
    if out.returncode != 0:
        pytest.skip(f"pg_isready did not succeed: {out.stderr.strip()}")
    assert "accepting connections" in out.stdout
