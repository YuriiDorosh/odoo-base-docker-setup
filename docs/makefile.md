# Makefile reference

Every workflow goes through `make`. Run `make help` to see the live list.

## Naming convention

```
up-<service>        bring service up (-d, background)
up-<service>-build  rebuild image and bring service up
down-<service>      stop and remove containers
logs-<service>      tail the container log
shell-<service>     exec into the container

up                  alias for the core dev stack
up-full             core + brokers + monitoring
*-prod              same target, prod compose file
```

## High-level

| Target          | What it does                                         |
|-----------------|------------------------------------------------------|
| `make init`     | Create `.env`, network, and required folders.        |
| `make up`       | postgres + odoo + nginx + pgadmin + adminer.         |
| `make up-full`  | Above + RabbitMQ + Kafka + Prometheus + Grafana.     |
| `make down`     | Stop the core stack.                                 |
| `make down-full`| Stop everything.                                     |
| `make restart`  | `down` then `up`.                                    |
| `make ps`       | List containers on the `backend` network.            |
| `make logs`     | Tail Odoo + Postgres logs together.                  |

## Per-service

| Target              | Notes                                              |
|---------------------|----------------------------------------------------|
| `up-db` / `down-db` | postgres + backup sidecar.                         |
| `up-odoo` / `down-odoo` | Odoo + nginx (they share the same compose file). |
| `up-pgadmin`        | <http://localhost:5050>                            |
| `up-adminer`        | <http://localhost:8080>                            |
| `up-rabbitmq`       | <http://localhost:15672> (UI), 5672 AMQP           |
| `up-kafka`          | `localhost:9094`, UI on <http://localhost:8089>    |
| `up-monitoring`     | Prometheus :9090 + Grafana :3000 + exporters       |
| `up-brokers`        | Both RabbitMQ and Kafka.                           |

## Odoo helpers

| Target                                      | Purpose                                          |
|---------------------------------------------|--------------------------------------------------|
| `make install-addon ADDON=<name> [DB=<db>]` | Install / activate an addon.                     |
| `make upgrade-addon ADDON=<name> [DB=<db>]` | Run the addon's upgrade hook.                    |
| `make odoo-shell`                           | Open the Odoo Python REPL with env/registry.     |
| `make odoo-psql`                            | Open `psql` against the Odoo DB.                 |
| `make odoo-test MODULES=base_search_fuzzy`  | Run tests for the given comma-separated modules. |

## Backup / restore

| Target                                      | Purpose                                          |
|---------------------------------------------|--------------------------------------------------|
| `make backup [DB=<db>]`                     | Write `./backups/<db>_<timestamp>.sql`.          |
| `make restore-db FILE=<path> [DB=<db>]`     | Drop & recreate DB, then load the dump.          |
| `make load-backup FILE=<name>`              | `pg_restore` from inside the backup container.   |
| `make clean-backups [DAYS=<n>]`             | Purge files older than N days (default 14).      |

## Diagnostics

| Target            | Purpose                                                |
|-------------------|--------------------------------------------------------|
| `make health`     | One-line status + healthcheck for every container.     |
| `make stop-all`   | `docker stop` every container on the host.             |
| `make rm-all`     | `docker rm` every stopped container on the host.       |
| `make prune`      | `docker system prune` (asks for confirmation).         |

## Python tooling

| Target          | Purpose                                       |
|-----------------|-----------------------------------------------|
| `make lint`     | `ruff` + `pylint-odoo` against `src/addons`.  |
| `make format`   | `black` + `isort` over `src/`.                |

> Passing variables: anything `VAR=value` after the target overrides the
> default. e.g. `make backup DB=staging` or `make restore-db FILE=x.sql DB=qa`.
