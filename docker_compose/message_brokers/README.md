# Message brokers

Two brokers are provided, each with their own `docker-compose.yml` so they can
be brought up independently.

## RabbitMQ

Folder: `rabbitmq/`

| Port  | Purpose            |
|-------|--------------------|
| 5672  | AMQP               |
| 15672 | Management UI      |
| 15692 | Prometheus metrics |

Defaults: user `odoo` / pass `odoo`. Override via `.env`:
```
RABBITMQ_USER=odoo
RABBITMQ_PASSWORD=ChangeMe_Strong_123
RABBITMQ_VHOST=/
```

The `definitions.json` file seeds an `odoo.events` topic exchange and a
default queue bound to `#` — adjust freely for your project.

```bash
make up-rabbitmq
make logs-rabbitmq
make down-rabbitmq
```

## Kafka (KRaft mode, no Zookeeper)

Folder: `kafka/`

| Port | Purpose                                        |
|------|------------------------------------------------|
| 9092 | Internal listener (in-network producers)       |
| 9094 | External listener (host machine producers)     |
| 8089 | kafka-ui (web UI from provectuslabs)           |

Auto-topic-creation is on for dev convenience. From the host:
```
bootstrap.servers=localhost:9094
```
From other containers on the `backend` network:
```
bootstrap.servers=kafka:9092
```

```bash
make up-kafka
make logs-kafka
make down-kafka
```

A `kafka_exporter` is included so Prometheus can scrape lag/topic metrics.
