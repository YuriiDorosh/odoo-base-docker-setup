# Development workflow

## Local Python tooling

Install dev tools on the host (outside Docker) for linting and IDE support:

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements/all-requirements.txt
pre-commit install
```

## Pre-commit

The repo ships an empty `.pre-commit.yaml` placeholder. A reasonable starting
config is:

```yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.6.9
    hooks:
      - id: ruff
        args: [--fix]
  - repo: https://github.com/psf/black
    rev: 24.10.0
    hooks:
      - id: black
  - repo: https://github.com/pycqa/isort
    rev: 5.13.2
    hooks:
      - id: isort
```

## Tests

Tests use `pytest-odoo`, which boots Odoo, loads the module, and tears the DB
down per session.

```bash
make odoo-test MODULES=base_search_fuzzy,password_security
```

For pure-Python helpers, plain `pytest` works:

```bash
pytest src/addons/<addon>/tests
```

## Live-reload of addons

When you edit a Python file under `src/addons/`, restart the Odoo worker:

```bash
make restart-odoo   # in this Makefile: make down-odoo && make up-odoo
# or just upgrade the changed module:
make upgrade-addon ADDON=<name>
```

XML / static files in `views/` are picked up by `--dev=xml,reload` if you add
that flag to the odoo command line (consider adding a `dev` compose override).

## IDE setup (VS Code / PyCharm)

Point your interpreter at the project venv. For Odoo IntelliSense:

- Add `src/addons/` and the Odoo install path inside the container to your
  PYTHONPATH overlay.
- Install the **Odoo Snippets** extension (VS Code) or the **Odoo IDE**
  plugin (PyCharm).

## Branching / commits

Follow the existing convention in the repo:

- `ADD:` — new feature, file, or addon.
- `UPDATE:` — non-trivial change to existing code.
- `FIX:` — bug fix.
- `TEMP:` — short-lived WIP commit.
