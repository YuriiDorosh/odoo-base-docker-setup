# Docker services

Every service in this repository has its own folder under
`docker_compose/<service>/` with its own `docker-compose.yml`. They join the
shared external `backend` network so they can resolve each other by container
name.

| Service        | Folder                                  | Default port(s) | Compose file                                  |
|----------------|------------------------------------------|-----------------|-----------------------------------------------|
| Odoo 18        | `docker_compose/odoo/`                  | (proxied)       | `docker-compose.yml`, `docker-compose-prod.yml`|
| Nginx          | `docker_compose/nginx/`                 | 5433 → 81       | bundled into Odoo compose                     |
| PostgreSQL 15  | `docker_compose/db/`                    | 5435 → 5432     | `docker-compose.yml`, `docker-compose-prod.yml`|
| pgAdmin 4      | `docker_compose/pgadmin/`               | 5050 → 80       | `docker-compose.yml`, `docker-compose-prod.yml`|
| Adminer        | `docker_compose/adminer/`               | 8080            | `docker-compose.yml`, `docker-compose-prod.yml`|
| Redis 7        | `docker_compose/redis/`                 | 6379, 8081      | `docker-compose.yml`                          |
| RabbitMQ 3.13  | `docker_compose/message_brokers/rabbitmq/` | 5672, 15672, 15692 | `docker-compose.yml`                     |
| Kafka 3.7      | `docker_compose/message_brokers/kafka/` | 9094, 8089      | `docker-compose.yml` (KRaft, no Zookeeper)    |
| Prometheus     | `docker_compose/monitoring/`            | 9090            | `docker-compose.yml`                          |
| Grafana        | `docker_compose/monitoring/`            | 3000            | `docker-compose.yml`                          |
| node_exporter  | `docker_compose/monitoring/`            | 9100 (internal) | `docker-compose.yml`                          |
| postgres_exporter | `docker_compose/monitoring/`         | 9187 (internal) | `docker-compose.yml`                          |
| cAdvisor       | `docker_compose/monitoring/`            | 8080 (internal) | `docker-compose.yml`                          |

## Why split compose files?

Splitting into per-service compose files lets you start exactly what you need
(`make up-db`, `make up-monitoring`, …) and keep CI/dev environments
lightweight. The trade-off: every service must reference the same external
network — defined once by `make network`.

## Production vs dev

`docker-compose-prod.yml` variants exist for services that need different
images, ports, or volume locations in production. They are wired up via the
`*-prod` Make targets (`make up-prod`, `make down-prod`).

## Hostnames inside the network

From inside any container on `backend`:

| To reach…            | Connect to                  |
|----------------------|-----------------------------|
| PostgreSQL           | `postgres:5432`             |
| Odoo                 | `odoo:8069`                 |
| Redis                | `redis:6379`                |
| RabbitMQ AMQP        | `rabbitmq:5672`             |
| Kafka                | `kafka:9092`                |
| Prometheus           | `prometheus:9090`           |
| Grafana              | `grafana:3000`              |
