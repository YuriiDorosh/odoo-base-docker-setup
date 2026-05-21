# Custom addons

All custom addons live under `src/addons/` and are mounted into the Odoo
container at `/mnt/extra-addons` (via `docker_compose/odoo/docker-compose.yml`).

The `odoo.conf` already adds that path:

```ini
addons_path = /usr/lib/python3/dist-packages/odoo/addons,/mnt/extra-addons
```

After dropping a new addon into `src/addons/<addon_name>/`:

```bash
make restart-odoo       # or: make down-odoo && make up-odoo
make install-addon ADDON=<addon_name>
```

## Bundled addons

| Addon                          | Version    | What it does                                                                                          |
|--------------------------------|------------|-------------------------------------------------------------------------------------------------------|
| `base_search_fuzzy`            | 18.0.1.0.0 | Fuzzy search across Odoo using the PostgreSQL `pg_trgm` extension.                                    |
| `eqp_backup`                   | 18.0.1.0   | UI for scheduling and managing Odoo DB / filestore backups directly from the Odoo interface.          |
| `password_security`            | 18.0.1.0.0 | Lets administrators enforce password complexity, expiration, history, and lockout policies.           |
| `web_notify`                   | 18.0.1.1.1 | Server-side helper for showing toast/notification messages to specific Odoo users from Python code.   |
| `website_menu_by_user_status`  | 18.0.1.0.0 | Show / hide `website.menu` entries based on whether the visitor is logged-in, a portal user, etc.     |
| `website_require_login`        | 18.0.1.0.0 | Restrict the public website to authenticated users only (everyone else gets redirected to login).     |

## Adding a new addon

```bash
mkdir -p src/addons/my_addon/{models,views,security}
touch src/addons/my_addon/__init__.py
touch src/addons/my_addon/__manifest__.py
```

Minimum manifest:

```python
{
    "name": "My addon",
    "summary": "Short description.",
    "version": "18.0.1.0.0",
    "category": "Tools",
    "depends": ["base"],
    "data": [],
    "installable": True,
    "license": "LGPL-3",
}
```

Then:

```bash
make install-addon ADDON=my_addon
```

## Common addon commands

```bash
# Install / upgrade
make install-addon ADDON=web_notify
make upgrade-addon ADDON=web_notify

# Run module tests
make odoo-test MODULES=web_notify,password_security

# Drop into the Python shell with env/registry/models loaded
make odoo-shell
```
