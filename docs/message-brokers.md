# Message brokers

Two brokers, each in its own compose file under
`docker_compose/message_brokers/`. They are independent — bring up only what
you need.

## RabbitMQ

```bash
make up-rabbitmq
make logs-rabbitmq
make down-rabbitmq
```

| URL / endpoint                       | Purpose                  |
|--------------------------------------|--------------------------|
| amqp://odoo:odoo@localhost:5672/     | AMQP from the host       |
| amqp://odoo:odoo@rabbitmq:5672/      | AMQP from another container |
| <http://localhost:15672>             | Management UI            |
| <http://localhost:15692/metrics>     | Prometheus endpoint      |

The container loads `definitions.json` at startup with:

- exchange `odoo.events` (topic, durable)
- queue `odoo.events.default` bound to `#`

Connecting from Python (inside an Odoo addon):

```python
import pika

params = pika.URLParameters("amqp://odoo:odoo@rabbitmq:5672/")
with pika.BlockingConnection(params) as conn:
    ch = conn.channel()
    ch.basic_publish(
        exchange="odoo.events",
        routing_key="invoice.posted",
        body=b'{"id": 42}',
    )
```

## Kafka (KRaft mode)

```bash
make up-kafka
make logs-kafka
make down-kafka
```

| URL / endpoint                | Purpose                         |
|-------------------------------|---------------------------------|
| `localhost:9094`              | Bootstrap server from the host  |
| `kafka:9092`                  | Bootstrap server inside backend |
| <http://localhost:8089>       | kafka-ui (provectuslabs)        |

KRaft mode is used to keep the dev setup simple (no Zookeeper required).
Auto-topic-creation is enabled — produce to any topic and it will be created
with broker defaults.

Connecting from Python:

```python
from kafka import KafkaProducer

producer = KafkaProducer(bootstrap_servers="kafka:9092")
producer.send("odoo.events", b'{"id": 42}')
producer.flush()
```

## Choosing between them

| Use case                                                | Pick       |
|---------------------------------------------------------|------------|
| Per-message routing, fanout to many small consumers     | RabbitMQ   |
| Replayable event log, partitioned high-throughput streams | Kafka    |
| Mixing Odoo with workflow / RPC patterns                | RabbitMQ   |
| Audit / change-data-capture pipelines                   | Kafka      |

If you don't have a strong reason, RabbitMQ is the simpler default for Odoo.
