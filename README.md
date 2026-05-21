# Odoo 18 — base docker setup

A batteries-included template for running **Odoo 18** in Docker, with
everything you typically reach for in real projects already wired up:
PostgreSQL, Nginx, pgAdmin / Adminer, message brokers (RabbitMQ + Kafka),
a full monitoring stack (Prometheus + Grafana + exporters), per-service
compose files, a documented `Makefile`, helper bash scripts, and curated
custom addons.

> Use this as a starting point for new Odoo 18 projects, or as a reference
> when wiring an existing project to brokers / observability.

---

## Table of contents

1. [Stack overview](#stack-overview)
2. [Quick start](#quick-start)
3. [Repository layout](#repository-layout)
4. [Docker services](#docker-services)
5. [Custom addons](#custom-addons)
6. [Odoo 18](#odoo-18)
7. [Makefile guide](#makefile-guide)
8. [Helper scripts (`scripts/`)](#helper-scripts-scripts)
9. [Backups](#backups)
10. [Monitoring (Prometheus + Grafana)](#monitoring-prometheus--grafana)
11. [Message brokers (RabbitMQ + Kafka)](#message-brokers-rabbitmq--kafka)
12. [Redis](#redis)
13. [Requirements (`requirements/`)](#requirements-requirements)
14. [Testing (`tests/`)](#testing-tests)
15. [Python tooling (`pyproject.toml`)](#python-tooling-pyprojecttoml)
16. [Environment variables](#environment-variables)
17. [Deeper docs (`docs/`)](#deeper-docs-docs)
18. [Troubleshooting](#troubleshooting)

---

## Stack overview

```
        Host  ──►  nginx ─► odoo 18  ──►  postgres 15
                                │
                                ├─►  pgAdmin / Adminer
                                ├─►  Redis 7         (redis/)
                                ├─►  RabbitMQ 3.13   (message_brokers/rabbitmq)
                                ├─►  Kafka 3.7 KRaft (message_brokers/kafka)
                                └─►  Prometheus + Grafana + exporters
                                         (monitoring/)
```

Every service has its **own compose file** under
`docker_compose/<service>/`. They join a shared external Docker network
(`backend`) so they can resolve each other by container name.

---

## Quick start

```bash
git clone <this-repo> odoo-stack
cd odoo-stack

# 1. Bootstrap: copy .env.example -> .env, create the backend network and folders
make init

# 2. Edit .env and set strong values (passwords, ports, etc.)
$EDITOR .env

# 3. Bring up the core stack: postgres + odoo + nginx + pgadmin + adminer
make up

# Optional extras:
make up-redis         # Redis + redis-commander + redis_exporter
make up-brokers       # RabbitMQ + Kafka
make up-monitoring    # Prometheus + Grafana + exporters
# Or everything at once:
make up-full

# Day to day:
make ps               # which containers are up
make logs-odoo        # tail Odoo logs
make health           # status of every stack container
make down             # stop the core stack
```

Then open:

| URL                                  | Service             | Credentials (default)              |
|--------------------------------------|---------------------|------------------------------------|
| <http://localhost:5433>              | Odoo (via nginx)    | created on first run, web manager  |
| <http://localhost:5050>              | pgAdmin             | `admin@admin.com` / `admin`        |
| <http://localhost:8080>              | Adminer             | postgres / odoo / (POSTGRES_PASSWORD) |
| <http://localhost:8081>              | redis-commander     | `admin` / `admin`                  |
| <http://localhost:15672>             | RabbitMQ UI         | `odoo` / `odoo`                    |
| <http://localhost:8089>              | kafka-ui            | —                                  |
| <http://localhost:9090>              | Prometheus          | —                                  |
| <http://localhost:3000>              | Grafana             | `admin` / `admin`                  |

> Change every password before exposing the stack outside localhost.

---

## Repository layout

```
.
├── Makefile                         # workflow targets (see `make help`)
├── README.md                        # this file
├── .env / .env.example              # environment variables
├── .gitignore / .dockerignore
├── backups/                         # on-demand DB dumps (gitignored, .gitkeep)
├── logs/                            # bind-mounted log directory
│   ├── nginx/
│   └── odoo/
├── docs/                            # extended documentation (.md / .mdx)
│   ├── setup.md
│   ├── services.md
│   ├── odoo-18.md
│   ├── addons.md
│   ├── makefile.md
│   ├── monitoring.md
│   ├── message-brokers.md
│   ├── backup-restore.md
│   ├── development.md
│   ├── architecture.mdx
│   └── troubleshooting.mdx
├── docker_compose/
│   ├── db/                          # PostgreSQL 15 + backup sidecar
│   ├── odoo/                        # Odoo 18 + nginx
│   ├── nginx/                       # nginx configs (dev + prod)
│   ├── pgadmin/                     # pgAdmin 4
│   ├── adminer/                     # Adminer
│   ├── redis/                       # Redis 7 + redis-commander + redis_exporter
│   ├── message_brokers/
│   │   ├── rabbitmq/                # RabbitMQ 3.13 (Mgmt + Prom plugin)
│   │   └── kafka/                   # Kafka 3.7 KRaft + kafka-ui + exporter
│   └── monitoring/                  # Prometheus + Grafana + exporters
│       ├── prometheus/
│       └── grafana/
├── requirements/                    # pip requirement files
│   ├── base-requirements.txt
│   ├── dev-requirements.txt
│   └── all-requirements.txt
├── scripts/                         # helper bash scripts
│   ├── init.sh
│   ├── backup-db.sh
│   ├── restore-db.sh
│   ├── install-addon.sh
│   ├── upgrade-addon.sh
│   ├── shell.sh
│   ├── psql.sh
│   ├── healthcheck.sh
│   ├── clean-backups.sh
│   ├── wait-for-postgres.sh
│   └── lint-addons.sh
├── tests/                           # host-side pytest suite
│   ├── conftest.py
│   ├── unit/                        # layout / manifest / compose sanity
│   ├── integration/                 # require RUN_INTEGRATION=1 + running stack
│   └── addons/                      # pytest-odoo skeletons
├── pyproject.toml                   # black / isort / ruff / mypy / pytest config
└── src/
    ├── addons/                      # custom + OCA-style addons
    │   ├── base_search_fuzzy/
    │   ├── eqp_backup/
    │   ├── password_security/
    │   ├── web_notify/
    │   ├── website_menu_by_user_status/
    │   └── website_require_login/
    ├── configs/odoo.conf            # mounted to /etc/odoo/odoo.conf
    └── patches/                     # space for runtime patches
```

---

## Docker services

| Service           | Container          | Port (host) | Compose file                                       |
|-------------------|--------------------|-------------|----------------------------------------------------|
| Odoo 18           | `odoo`             | (via nginx) | `docker_compose/odoo/docker-compose.yml`           |
| Nginx             | `nginx`            | 5433 → 81   | bundled in the Odoo compose                        |
| PostgreSQL 15     | `postgres`         | 5435 → 5432 | `docker_compose/db/docker-compose.yml`             |
| Postgres backup   | `postgres_backup`  | —           | same compose file as `postgres`                    |
| pgAdmin 4         | `pgadmin`          | 5050 → 80   | `docker_compose/pgadmin/docker-compose.yml`        |
| Adminer           | `adminer-postgres` | 8080        | `docker_compose/adminer/docker-compose.yml`        |
| Redis 7           | `redis`            | 6379        | `docker_compose/redis/docker-compose.yml`          |
| redis-commander   | `redis_commander`  | 8081        | same compose as `redis`                            |
| redis_exporter    | `redis_exporter`   | 9121 (int)  | same compose as `redis`                            |
| RabbitMQ 3.13     | `rabbitmq`         | 5672, 15672, 15692 | `docker_compose/message_brokers/rabbitmq/`  |
| Kafka 3.7 (KRaft) | `kafka`            | 9094        | `docker_compose/message_brokers/kafka/`            |
| kafka-ui          | `kafka_ui`         | 8089 → 8080 | same compose as `kafka`                            |
| kafka_exporter    | `kafka_exporter`   | 9308 (int)  | same compose as `kafka`                            |
| Prometheus        | `prometheus`       | 9090        | `docker_compose/monitoring/docker-compose.yml`     |
| Grafana           | `grafana`          | 3000        | same compose as `prometheus`                       |
| node_exporter     | `node_exporter`    | 9100 (int)  | same compose as `prometheus`                       |
| postgres_exporter | `postgres_exporter`| 9187 (int)  | same compose as `prometheus`                       |
| cAdvisor          | `cadvisor`         | 8080 (int)  | same compose as `prometheus`                       |

Production variants live alongside the dev files as
`docker-compose-prod.yml` and are wired up through the `*-prod` Make targets.

See [`docs/services.md`](docs/services.md) and
[`docs/architecture.mdx`](docs/architecture.mdx) for more.

---

## Custom addons

All addons live under `src/addons/` and are mounted into the Odoo container at
`/mnt/extra-addons` (already in `odoo.conf`'s `addons_path`).

| Addon                          | Version    | Summary                                                                                         |
|--------------------------------|------------|-------------------------------------------------------------------------------------------------|
| `base_search_fuzzy`            | 18.0.1.0.0 | Fuzzy search via PostgreSQL `pg_trgm`.                                                          |
| `eqp_backup`                   | 18.0.1.0   | UI for scheduling Odoo DB / filestore backups directly from inside Odoo.                        |
| `password_security`            | 18.0.1.0.0 | Password complexity, expiration, history, lockout for Odoo users.                               |
| `web_notify`                   | 18.0.1.1.1 | Send toast/notification messages to specific Odoo users from Python.                            |
| `website_menu_by_user_status`  | 18.0.1.0.0 | Conditionally show/hide `website.menu` items based on user state.                               |
| `website_require_login`        | 18.0.1.0.0 | Lock the public website behind authentication.                                                  |

Install / upgrade / test:

```bash
make install-addon ADDON=web_notify
make upgrade-addon ADDON=web_notify
make odoo-test     MODULES=base_search_fuzzy,password_security
```

See [`docs/addons.md`](docs/addons.md) for the full guide (manifest layout,
how to scaffold a new addon, live-reload tips).

---

## Odoo 18

This stack pins the official **`odoo:18`** image and runs in `proxy_mode`
behind nginx with 3 workers and 2 cron threads.

| Concern               | Where                                                       |
|-----------------------|-------------------------------------------------------------|
| Image                 | `docker_compose/odoo/Dockerfile` (adds fonts on top of `odoo:18`) |
| Config                | `src/configs/odoo.conf` → `/etc/odoo/odoo.conf` (ro)        |
| Custom addons         | `src/addons/` → `/mnt/extra-addons`                         |
| Filestore             | named volume `odoo-data` → `/var/lib/odoo`                  |
| Server logs           | `./logs/odoo-server.log` (bind-mounted from host)           |
| Nginx access / errors | `./logs/nginx/`                                             |
| Admin password        | `ODOO_ADMIN_PASSWD` in `.env` and `odoo.conf`               |

See [`docs/odoo-18.md`](docs/odoo-18.md) for image internals, useful CLI
flags, and notes on what changed in Odoo 18.

---

## Makefile guide

Run `make help` for the always-up-to-date list. Naming convention:

```
up-<svc>            bring service up in the background
up-<svc>-build      rebuild image and bring up
down-<svc>          stop & remove containers
restart-<svc>       down then up
logs-<svc>          tail container logs (last 200 + follow)
shell-<svc>         exec bash inside the container

up                  alias for the core dev stack
up-full             core + redis + brokers + monitoring
*-prod              same target, prod compose
```

Most-used:

| Target                                       | What it does                                            |
|----------------------------------------------|---------------------------------------------------------|
| `make help`                                  | List every target with its description.                 |
| `make init`                                  | Create `.env`, network, and folders (idempotent).       |
| `make up`                                    | postgres + odoo + nginx + pgadmin + adminer.            |
| `make up-full`                               | Above + redis + brokers + monitoring.                   |
| `make down` / `make down-full`               | Stop core / everything.                                 |
| `make restart`                               | Restart the core stack.                                 |
| `make ps`                                    | List containers on the `backend` network.               |
| `make logs-odoo` / `make logs-db` / ...      | Tail one service.                                       |
| `make health`                                | One-line status for every container.                    |
| `make backup [DB=<db>]`                      | On-demand `pg_dump` into `./backups/`.                  |
| `make restore-db FILE=<path> [DB=<db>]`      | Drop & recreate the DB, then restore.                   |
| `make load-backup FILE=<file>`               | `pg_restore` from inside the backup sidecar.            |
| `make install-addon ADDON=<name> [DB=<db>]`  | Install an Odoo addon.                                  |
| `make upgrade-addon ADDON=<name> [DB=<db>]`  | Upgrade an Odoo addon.                                  |
| `make odoo-shell`                            | Open the Odoo Python shell.                             |
| `make odoo-psql`                             | Open `psql` against the Odoo DB.                        |
| `make odoo-test MODULES=a,b`                 | Run tests for the listed modules.                       |
| `make up-redis` / `make down-redis`          | Start / stop Redis stack.                               |
| `make cli-redis`                             | Open `redis-cli` authenticated with `$REDIS_PASSWORD`.  |
| `make clean-backups [DAYS=<n>]`              | Purge old backup files (default 14 days).               |
| `make lint`                                  | `ruff` + `pylint-odoo` against `src/addons`.            |
| `make format`                                | `black` + `isort` over `src/`.                          |
| `make stop-all` / `rm-all` / `prune`         | Host-wide docker cleanup.                               |

Full reference: [`docs/makefile.md`](docs/makefile.md).

---

## Helper scripts (`scripts/`)

All wrappers around `docker exec` / `pg_dump` / `odoo`. They read `.env`
from the repo root.

| Script                       | What it does                                          |
|------------------------------|-------------------------------------------------------|
| `init.sh`                    | `.env` + docker network + required folders.           |
| `backup-db.sh [db]`          | `pg_dump` of `$ODOO_DB` into `./backups/`.            |
| `restore-db.sh <file> [db]`  | Drop + recreate DB, load `.sql` or `.dump`.           |
| `install-addon.sh <a> [db]`  | `odoo -i <addon> --stop-after-init`.                  |
| `upgrade-addon.sh <a> [db]`  | `odoo -u <addon> --stop-after-init`.                  |
| `shell.sh [db]`              | `odoo shell` REPL inside the odoo container.          |
| `psql.sh [db]`               | `psql` inside the postgres container.                 |
| `healthcheck.sh`             | One-line status for every stack container.            |
| `clean-backups.sh [days]`    | Delete backups older than N days (default 14).        |
| `wait-for-postgres.sh [t]`   | Block until `pg_isready`. Useful in CI / init paths.  |
| `lint-addons.sh`             | `ruff` + `pylint-odoo` on `src/addons`.               |

After cloning:

```bash
chmod +x scripts/*.sh
```

---

## Backups

Two backup paths, intentionally:

1. **Automatic sidecar** — `postgres_backup` container next to Postgres does a
   daily `pg_dump` into `docker_compose/db/backups/`. Restore with:
   ```bash
   make load-backup FILE=backup_prod_2025-10-14.sql
   ```

2. **On-demand** via `./scripts/`, writing to the top-level `./backups/`
   folder:
   ```bash
   make backup                              # dumps $ODOO_DB
   make backup DB=staging                   # different db
   make restore-db FILE=backups/...sql      # drop+recreate then load
   make clean-backups DAYS=30               # retention sweep
   ```

Both backup folders are git-ignored but kept around via `.gitkeep`.
The filestore (`odoo-data` volume) is **not** included in `pg_dump`; see
[`docs/backup-restore.md`](docs/backup-restore.md) for a full-stack snapshot
recipe.

---

## Monitoring (Prometheus + Grafana)

Located in `docker_compose/monitoring/`.

```bash
make up-monitoring
make logs-monitoring
make down-monitoring
```

| Container          | Image                                            | Purpose                       |
|--------------------|--------------------------------------------------|-------------------------------|
| `prometheus`       | `prom/prometheus:v2.54.1`                        | Scraping + TSDB (15d retention)|
| `grafana`          | `grafana/grafana:11.2.0`                         | Dashboards & alerting         |
| `node_exporter`    | `prom/node-exporter:v1.8.2`                      | Host CPU / mem / disk         |
| `postgres_exporter`| `prometheuscommunity/postgres-exporter:v0.15.0`  | Postgres metrics              |
| `cadvisor`         | `gcr.io/cadvisor/cadvisor:v0.49.1`               | Per-container metrics         |

Grafana is auto-provisioned with the Prometheus datasource. Drop dashboard
JSON files into `docker_compose/monitoring/grafana/dashboards/` and they
appear automatically. Starter alert rules ship in
`docker_compose/monitoring/prometheus/alerts.yml`.

Full guide: [`docs/monitoring.md`](docs/monitoring.md).

---

## Message brokers (RabbitMQ + Kafka)

Located in `docker_compose/message_brokers/`. Independent compose files —
run only what you need.

### RabbitMQ

```bash
make up-rabbitmq      # AMQP 5672, UI 15672, /metrics 15692
```

Pre-declares a topic exchange `odoo.events` and a queue
`odoo.events.default` bound to `#` (see `definitions.json`).

### Kafka (KRaft, single broker)

```bash
make up-kafka         # PLAINTEXT kafka:9092 (in-net), localhost:9094 (host)
```

Includes [kafka-ui](https://github.com/provectus/kafka-ui) at
<http://localhost:8089> and a Prometheus exporter wired into the monitoring
stack.

Full guide: [`docs/message-brokers.md`](docs/message-brokers.md).

---

## Redis

Located in `docker_compose/redis/`. Single-node Redis 7 with a web UI and a
Prometheus exporter — useful as a cache, queue backend, session store, or
generic pub/sub for custom Odoo modules.

```bash
make up-redis        # redis:6379 + redis-commander:8081 + redis_exporter
make logs-redis
make cli-redis       # interactive redis-cli (uses $REDIS_PASSWORD)
make down-redis
```

| Container         | Image                                  | Port  | Purpose                       |
|-------------------|----------------------------------------|-------|-------------------------------|
| `redis`           | `redis:7.4-alpine`                     | 6379  | Cache / queue / pub-sub       |
| `redis_commander` | `rediscommander/redis-commander:latest`| 8081  | Web UI (basic-auth protected) |
| `redis_exporter`  | `oliver006/redis_exporter`             | 9121 (int) | Prometheus metrics       |

The custom `redis.conf` enables AOF persistence (`appendfsync everysec`) and
RDB snapshots, caps memory at `256mb` with `allkeys-lru` eviction, and
disables `FLUSHALL` / `CONFIG` in shared dev environments. The password is
supplied at container start via `--requirepass $REDIS_PASSWORD`.

### Connecting

From another container on `backend`:

```python
import redis

client = redis.Redis(
    host="redis", port=6379,
    password="redis",          # $REDIS_PASSWORD
    decode_responses=True,
)
client.set("hello", "world")
```

From the host, swap `host="redis"` for `host="localhost"`.

`prometheus.yml` already scrapes the exporter on `redis_exporter:9121`, so
metrics show up in Grafana as soon as both stacks are running.

Folder README: [`docker_compose/redis/README.md`](docker_compose/redis/README.md).

---

## Requirements (`requirements/`)

Pip requirement files for **host-side** linting / scripting. The official
Odoo image already ships its own Python dependencies; these are extras the
custom addons or helper scripts use.

```
requirements/
├── base-requirements.txt    # runtime libs (psycopg2, requests, pika, kafka-python, ...)
├── dev-requirements.txt     # tooling (ruff, black, isort, pylint-odoo, pytest-odoo, mkdocs, ...)
└── all-requirements.txt     # -r base + -r dev
```

Highlights:

- **`pika`**, **`kafka-python`** — clients for the bundled message brokers.
- **`prometheus-client`** — expose custom metrics from inside Odoo.
- **`sentry-sdk`**, **`structlog`** — error tracking + structured logging.
- **`openpyxl`**, **`xlsxwriter`**, **`reportlab`** — Excel / PDF reports.
- **`qrcode`**, **`Pillow`** — barcodes / images.
- **`pytest-odoo`** — Odoo-aware test runner.
- **`pylint-odoo`**, **`ruff`**, **`black`**, **`isort`** — code quality.
- **`mkdocs-material`** — render the `docs/` folder locally.

Install everything:

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements/all-requirements.txt
```

---

## Testing (`tests/`)

Host-side test suite, separate from the Odoo-internal addon tests under
`src/addons/*/tests/`. Configured through `pyproject.toml`
(`[tool.pytest.ini_options]`).

```
tests/
├── conftest.py                # shared fixtures: project_root, addons_dir, env, ...
├── unit/                      # cheap checks — no Docker required
│   ├── test_project_layout.py     # required files / folders / executable scripts
│   ├── test_env_example.py        # .env.example declares every key the stack uses
│   ├── test_addon_manifests.py    # every __manifest__.py is valid + pinned to 18.x
│   ├── test_compose_files.py      # every docker-compose.yml is valid YAML
│   └── test_makefile_targets.py   # Makefile declares the expected targets
├── integration/               # require RUN_INTEGRATION=1 + a running stack
│   └── test_postgres_connection.py
└── addons/                    # pytest-odoo entry points (skeleton)
    └── test_web_notify_sample.py
```

### Quick commands

```bash
make test                # pytest tests/unit
make test-integration    # RUN_INTEGRATION=1 pytest tests/integration
make test-cov            # pytest tests/unit --cov --cov-report=term-missing

# Odoo-side tests (boot a real Odoo registry):
make odoo-test MODULES=base_search_fuzzy,password_security
```

### Markers (declared in `pyproject.toml`)

| Marker        | Meaning                                              |
|---------------|------------------------------------------------------|
| `unit`        | Pure Python, no DB, no Docker.                       |
| `integration` | Requires the Docker stack to be running.             |
| `odoo`        | Boots an Odoo registry via `pytest-odoo`.            |
| `slow`        | Long-running tests; deselect with `-m 'not slow'`.   |

Integration tests are auto-skipped unless `RUN_INTEGRATION=1` is set — that
gate lives in `tests/conftest.py`.

Full details: [`tests/README.md`](tests/README.md).

---

## Python tooling (`pyproject.toml`)

All host-side Python tools share one config file at the project root.

| Section                           | Tool                  | What it controls                                              |
|-----------------------------------|-----------------------|---------------------------------------------------------------|
| `[project]`                       | metadata              | name, version, Python ≥ 3.11, license, URLs.                  |
| `[tool.black]`                    | **black**             | Line length 100, target Python 3.11, excludes static/migrations. |
| `[tool.isort]`                    | **isort**             | Black profile, custom `ODOO` section for `import odoo.*`.     |
| `[tool.ruff]` / `[tool.ruff.lint]`| **ruff**              | E/W/F/I/B/UP/SIM/C4/RUF rule sets, Odoo-friendly ignores.     |
| `[tool.mypy]`                     | **mypy**              | Python 3.11, ignore missing imports (Odoo isn't pip-installable). |
| `[tool.pytest.ini_options]`       | **pytest**            | `testpaths = tests, src/addons`, markers, default `addopts`.  |
| `[tool.coverage.*]`               | **coverage.py**       | Branch coverage on `src/addons` and `scripts`.                |
| `[tool.pylint.*]`                 | **pylint-odoo**       | Loaded via `scripts/lint-addons.sh`.                          |

Running the tools:

```bash
make format             # black + isort on src/ and tests/
make lint               # ruff + pylint-odoo on src/addons
make test               # pytest tests/unit
make test-cov           # + coverage report
```

Everything reads from `pyproject.toml`, so editor integrations (VS Code's
Python extension, PyCharm's inspections, etc.) pick up the same settings as
CI.

---

## Environment variables

`.env.example` is the source of truth. Copy it to `.env` (handled by
`make init`) and edit. Sections:

| Section       | Variables                                                                              |
|---------------|----------------------------------------------------------------------------------------|
| PostgreSQL    | `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `ODOO_DB`                          |
| Odoo / Nginx  | `ODOO_ADMIN_PASSWD`, `NGINX_PORT`                                                       |
| pgAdmin       | `PGADMIN_DEFAULT_EMAIL`, `PGADMIN_DEFAULT_PASSWORD`                                     |
| Redis         | `REDIS_PORT`, `REDIS_PASSWORD`, `REDIS_UI_PORT`, `REDIS_UI_USER`, `REDIS_UI_PASSWORD`     |
| RabbitMQ      | `RABBITMQ_USER`, `RABBITMQ_PASSWORD`, `RABBITMQ_VHOST`, `RABBITMQ_PORT`, `RABBITMQ_UI_PORT`, `RABBITMQ_PROM_PORT` |
| Kafka         | `KAFKA_EXTERNAL_HOST`, `KAFKA_EXTERNAL_PORT`, `KAFKA_UI_PORT`                           |
| Monitoring    | `PROMETHEUS_PORT`, `GRAFANA_PORT`, `GRAFANA_USER`, `GRAFANA_PASSWORD`                   |

`.env` is git-ignored.

---

## Deeper docs (`docs/`)

| File                                              | What                                          |
|---------------------------------------------------|-----------------------------------------------|
| [`docs/setup.md`](docs/setup.md)                  | First-time bootstrap and OS requirements.     |
| [`docs/services.md`](docs/services.md)            | Every container + ports + network hostnames.  |
| [`docs/odoo-18.md`](docs/odoo-18.md)              | Odoo 18 image / config notes.                 |
| [`docs/addons.md`](docs/addons.md)                | Bundled addons + how to add your own.         |
| [`docs/makefile.md`](docs/makefile.md)            | Make target reference.                        |
| [`docs/monitoring.md`](docs/monitoring.md)        | Prometheus + Grafana playbook.                |
| [`docs/message-brokers.md`](docs/message-brokers.md) | RabbitMQ + Kafka with code samples.        |
| [`docs/redis.md`](docs/redis.md)                  | Redis 7 setup, config, and usage examples.    |
| [`docs/backup-restore.md`](docs/backup-restore.md)| Both backup paths and full restore recipes.   |
| [`docs/development.md`](docs/development.md)      | Local Python tooling, tests, pre-commit.      |
| [`docs/architecture.mdx`](docs/architecture.mdx)  | ASCII topology + volumes / bind-mounts.       |
| [`docs/troubleshooting.mdx`](docs/troubleshooting.mdx) | Common failures and fixes.              |

---

## Troubleshooting

Quick cheats — full list in
[`docs/troubleshooting.mdx`](docs/troubleshooting.mdx).

| Symptom                                              | Fix                                                |
|------------------------------------------------------|----------------------------------------------------|
| `network backend ... could not be found`             | `make network` (or `make init`).                   |
| Odoo restart loop, "auth failed"                     | `.env` and `odoo.conf` passwords disagree.         |
| Port 5433 already bound                              | Change `NGINX_PORT` in `.env`.                     |
| Restore fails: "database is being accessed"          | `pg_terminate_backend(...)` open sessions.         |
| Prometheus target down                               | Run `make health`, check `prometheus.yml` ports.   |
| Grafana datasource missing                           | Recreate the volume: `docker volume rm monitoring_grafana_data`. |

---

## License

Each bundled addon keeps the license declared in its own `__manifest__.py`
(LGPL-3 / AGPL-3). The rest of this template is provided as-is.
