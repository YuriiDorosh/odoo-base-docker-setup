# Redis

Single-node Redis 7 used as a general-purpose cache / queue / pub-sub
backend for the stack.

```bash
make up-redis
make logs-redis
make cli-redis     # interactive redis-cli
make down-redis
```

## Components

| Container         | Image                                  | Port  | Purpose                       |
|-------------------|----------------------------------------|-------|-------------------------------|
| `redis`           | `redis:7.4-alpine`                     | 6379  | Cache / queue / pub-sub       |
| `redis_commander` | `rediscommander/redis-commander:latest`| 8081  | Web UI (basic-auth protected) |
| `redis_exporter`  | `oliver006/redis_exporter`             | 9121 (int) | Prometheus metrics       |

## Configuration

`docker_compose/redis/redis.conf` ships with sensible dev defaults:

- AOF persistence on (`appendfsync everysec`).
- RDB snapshots on top of AOF (defence in depth).
- `maxmemory 256mb`, `allkeys-lru` eviction.
- `FLUSHALL` and `CONFIG` disabled (renamed to empty strings).
- Auth password supplied at container start via `--requirepass`.

Override anything in `.env`:

| Var                | Default | Purpose                                |
|--------------------|---------|----------------------------------------|
| `REDIS_PORT`       | 6379    | Host port exposed.                     |
| `REDIS_PASSWORD`   | redis   | `requirepass` value.                   |
| `REDIS_UI_PORT`    | 8081    | Host port for redis-commander.         |
| `REDIS_UI_USER`    | admin   | Basic-auth user for the UI.            |
| `REDIS_UI_PASSWORD`| admin   | Basic-auth password for the UI.        |

## Connecting

From another container on `backend`:

```python
import redis

client = redis.Redis(
    host="redis", port=6379,
    password="redis",          # $REDIS_PASSWORD
    decode_responses=True,
)
client.set("foo", "bar")
```

From the host machine:

```bash
redis-cli -h localhost -p 6379 -a "$REDIS_PASSWORD"
# or:
make cli-redis
```

## Use cases inside Odoo

- **Session store / cache** — wrap Odoo functions with a custom decorator
  using the bundled `redis` library (already in
  `requirements/base-requirements.txt`).
- **Background tasks** — queue work to a Python worker subscribed to a
  Redis stream / list, decoupling long jobs from the HTTP worker pool.
- **Rate limiting / debounce** — share counters between Odoo workers.
- **Pub/sub bridge** — push UI notifications via `web_notify` when an
  external system publishes to a Redis channel.

## Monitoring

`docker_compose/monitoring/prometheus/prometheus.yml` already declares a
`redis` scrape job targeting `redis_exporter:9121`. Recommended Grafana
dashboard import IDs:

| Dashboard               | ID    |
|-------------------------|-------|
| Redis Dashboard         | 763   |
| Redis Exporter          | 11835 |

## Backup

Redis writes both AOF (`appendonly.aof`) and RDB (`dump.rdb`) to the
`redis_data` volume. A one-shot snapshot:

```bash
docker exec redis redis-cli -a "$REDIS_PASSWORD" SAVE
docker run --rm \
    -v odoo-base-docker-setup_redis_data:/data \
    -v "$PWD/backups:/out" \
    alpine sh -c "cp /data/dump.rdb /out/redis_$(date +%F).rdb"
```

(Adjust the volume name to whatever `docker volume ls` shows.)
