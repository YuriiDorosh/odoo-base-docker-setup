# Setup

## Requirements

| Tool             | Version             | Notes                                        |
|------------------|---------------------|----------------------------------------------|
| Docker Engine    | ≥ 24                | Compose V2 is bundled with Engine 20.10.13+. |
| docker compose   | ≥ 2.20              | `docker compose ...` (no hyphen).            |
| GNU make         | ≥ 4.0               | All workflow targets go through `make`.      |
| Python (host)    | ≥ 3.11              | Only needed for local linting/tests.         |
| Free RAM         | ≥ 6 GB              | Full stack (with brokers + monitoring).      |
| Free disk        | ≥ 15 GB             | Image and volume storage.                    |

## First-time bootstrap

```bash
git clone <this-repo> odoo-stack
cd odoo-stack

# Copy .env, create the docker network and required folders.
make init

# Edit .env — at minimum set strong values for POSTGRES_PASSWORD and ODOO_ADMIN_PASSWD.
$EDITOR .env

# Bring up the core stack (postgres + odoo + nginx + pgadmin + adminer).
make up
```

When Odoo finishes its first start (≈ 30–60s), open:

- Odoo:    <http://localhost:5433>
- pgAdmin: <http://localhost:5050>
- Adminer: <http://localhost:8080>

The database manager URL (<http://localhost:5433/web/database/manager>) lets
you create the actual Odoo database (the value you put into `ODOO_DB` in
`.env`).

## Adding the optional stacks

```bash
make up-redis        # Redis + redis-commander + redis_exporter
make up-brokers      # RabbitMQ + Kafka
make up-monitoring   # Prometheus + Grafana + exporters
# or everything at once:
make up-full
```

## Tearing it all down

```bash
make down            # core stack
make down-full       # core + brokers + monitoring
make down-db         # individual service
```

To wipe volumes too, target the compose file directly:

```bash
docker compose -f docker_compose/db/docker-compose.yml down -v
```

## Network

All services join the shared external network `backend`. The `make init` /
`make network` target creates it idempotently. If you nuke it manually you
will get `network backend declared as external, but could not be found` —
re-run `make network`.
