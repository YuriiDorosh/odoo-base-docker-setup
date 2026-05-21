# Monitoring stack

Prometheus + Grafana + exporters (node_exporter, postgres_exporter, cadvisor)
for the Odoo 18 stack.

## Services

| Service             | Container          | Port | Purpose                                |
|---------------------|--------------------|------|----------------------------------------|
| Prometheus          | `prometheus`       | 9090 | Time-series database / scraping        |
| Grafana             | `grafana`          | 3000 | Dashboards / alerting UI               |
| Node Exporter       | `node_exporter`    | 9100 | Host CPU / mem / disk metrics          |
| Postgres Exporter   | `postgres_exporter`| 9187 | PostgreSQL metrics                     |
| cAdvisor            | `cadvisor`         | 8080 | Per-container resource metrics         |

All services join the shared external `backend` network so they can talk to
`postgres`, `odoo`, `rabbitmq`, and `kafka` by service name.

## Run it

```bash
make up-monitoring        # bring everything up
make down-monitoring      # stop without removing volumes
make logs-monitoring      # tail logs
```

Grafana is provisioned with the Prometheus datasource automatically. Drop new
dashboard JSON files into `grafana/dashboards/` and they will be auto-loaded.

## Scraping Odoo

The `odoo` scrape job in `prometheus/prometheus.yml` expects an `/metrics`
endpoint on port 8069. Install one of the OCA `prometheus_*` modules (or any
equivalent) on the Odoo instance to expose it.

## Defaults

| Var               | Default | Purpose            |
|-------------------|---------|--------------------|
| `PROMETHEUS_PORT` | 9090    | Prometheus UI port |
| `GRAFANA_PORT`    | 3000    | Grafana UI port    |
| `GRAFANA_USER`    | admin   | Grafana admin user |
| `GRAFANA_PASSWORD`| admin   | Grafana admin pass |

Override them via `.env`.
