"""Example skeleton for testing an Odoo addon with ``pytest-odoo``.

``pytest-odoo`` boots a real Odoo registry and exposes ``env`` as a fixture.
Run it via the Make target:

    make odoo-test MODULES=web_notify

…or, with the host venv activated and a running stack:

    pytest --odoo-database $ODOO_DB tests/addons -m odoo
"""
from __future__ import annotations

import pytest

pytestmark = [pytest.mark.odoo, pytest.mark.integration]

odoo = pytest.importorskip("odoo", reason="run inside the Odoo container or via pytest-odoo")


@pytest.fixture(scope="module")
def env():
    """Yield an Odoo ``env`` with the demo user as current user."""
    from odoo.tests import common  # noqa: WPS433  (runtime import is the only option)

    with common.SavepointCase._cr.savepoint():  # type: ignore[attr-defined]
        yield common.SavepointCase.env  # type: ignore[attr-defined]


def test_web_notify_module_is_installed(env) -> None:
    module = env["ir.module.module"].search([("name", "=", "web_notify")], limit=1)
    assert module, "web_notify is not present in the registry"
    assert module.state in {"installed", "to upgrade"}, (
        f"web_notify state: {module.state}"
    )


def test_admin_can_receive_notify(env) -> None:
    admin = env.ref("base.user_admin")
    # The web_notify addon adds these methods to res.users.
    assert hasattr(admin, "notify_info"), "web_notify did not patch res.users"
    admin.notify_info(message="hello from tests", title="pytest")
