# Monitoring (Prometheus + Grafana)

The monitoring stack lives in `docker_compose/monitoring/`.

```bash
make up-monitoring
make logs-monitoring
make down-monitoring
```

## Components

| Container          | Image                                            | Purpose                                  |
|--------------------|--------------------------------------------------|------------------------------------------|
| `prometheus`       | `prom/prometheus:v2.54.1`                        | Scrapes metrics from every exporter.     |
| `grafana`          | `grafana/grafana:11.2.0`                         | Dashboards / alerting UI.                |
| `node_exporter`    | `prom/node-exporter:v1.8.2`                      | Host CPU / mem / disk / network.         |
| `postgres_exporter`| `prometheuscommunity/postgres-exporter:v0.15.0`  | Postgres backend metrics.                |
| `cadvisor`         | `gcr.io/cadvisor/cadvisor:v0.49.1`               | Per-container resource usage.            |

Plus, optional scrape targets for `rabbitmq` (Prometheus plugin on 15692) and
`kafka_exporter` (when the broker stack is up).

## Default URLs

- Prometheus → <http://localhost:9090>
- Grafana   → <http://localhost:3000>  (admin / admin)

Override via `.env`: `PROMETHEUS_PORT`, `GRAFANA_PORT`, `GRAFANA_USER`,
`GRAFANA_PASSWORD`.

## Grafana provisioning

Grafana is wired with the Prometheus datasource at startup
(`grafana/provisioning/datasources/datasource.yml`).

To preload dashboards: drop their JSON files into
`docker_compose/monitoring/grafana/dashboards/` — they will appear on the next
restart (the provider polls every 30s and `allowUiUpdates` is on).

Recommended community dashboards to import by ID:

| Dashboard               | ID    | Source                        |
|-------------------------|-------|-------------------------------|
| Node Exporter Full      | 1860  | Grafana Labs                  |
| PostgreSQL Database     | 9628  | prometheus-community          |
| Docker / cAdvisor       | 14282 | Grafana Labs                  |
| RabbitMQ Overview       | 10991 | RabbitMQ team                 |
| Kafka Exporter Overview | 7589  | Grafana Labs                  |

## Alerts

A starter rule file sits at
`docker_compose/monitoring/prometheus/alerts.yml` with four rules:

- `InstanceDown` — any scrape target unreachable > 2 min
- `HighNodeCpu` — average CPU > 85% for 10 min
- `HighNodeMemory` — memory > 90% for 10 min
- `PostgresDown` — `pg_up == 0` for 2 min

Wire Alertmanager separately when needed; this repo intentionally ships
without one to keep the dev stack small.

## Scraping Odoo

Install one of the OCA `prometheus_*` modules (or your own custom exporter)
to expose `/metrics` on the Odoo HTTP port — the scrape job is already in
`prometheus.yml`.
