# tests/

Project-level test suite. Organised into three buckets so you can run only
what's relevant for the moment.

```
tests/
├── conftest.py                # project_root / addons_dir / env fixtures
├── unit/                      # cheap, no Docker required
│   ├── test_project_layout.py
│   ├── test_env_example.py
│   ├── test_addon_manifests.py
│   ├── test_compose_files.py
│   └── test_makefile_targets.py
├── integration/               # require RUN_INTEGRATION=1 and a running stack
│   └── test_postgres_connection.py
└── addons/                    # pytest-odoo entry points (skeleton)
    └── test_web_notify_sample.py
```

## Running

```bash
# Everything that doesn't need Docker:
pytest -m unit                           # or simply: pytest tests/unit

# Integration tests against a running stack (make up-db first):
RUN_INTEGRATION=1 pytest tests/integration

# Coverage report:
pytest --cov --cov-report=term-missing

# Run a single file or test:
pytest tests/unit/test_addon_manifests.py
pytest tests/unit/test_addon_manifests.py::test_manifest_has_required_keys
```

## Markers

Configured in `pyproject.toml`:

| Marker         | Meaning                                              |
|----------------|------------------------------------------------------|
| `unit`         | Pure Python, no DB, no Docker.                       |
| `integration`  | Requires the Docker stack to be running.             |
| `odoo`         | Boots an Odoo registry via `pytest-odoo`.            |
| `slow`         | Slow tests — deselect with `-m 'not slow'`.          |

Integration tests are auto-skipped unless `RUN_INTEGRATION=1` is set (handled
by `tests/conftest.py::pytest_collection_modifyitems`).

## Addon tests vs project tests

* Tests **inside an addon** (e.g. `src/addons/web_notify/tests/`) follow
  Odoo's own `TransactionCase`/`HttpCase` style and are run by the Odoo
  test loader:
  ```bash
  make odoo-test MODULES=web_notify,password_security
  ```
* Tests **here** (`tests/`) are everything else: layout checks, env
  validation, manifest sanity, integration probes, and any helpers that
  don't need a booted Odoo registry.

## Useful flags

```bash
pytest -x                  # stop on first failure
pytest -k "manifest"       # only tests matching this substring
pytest --lf                # rerun last failures
pytest -v --tb=long        # verbose + full tracebacks
```

## CI suggestion

A minimal CI workflow:

```yaml
- run: pip install -r requirements/all-requirements.txt
- run: ruff check src tests
- run: black --check src tests
- run: pytest -m unit --cov --cov-report=xml
```
