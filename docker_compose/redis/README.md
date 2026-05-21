# Redis

Single-node Redis 7 with a management UI and a Prometheus exporter.

| Container         | Image                                  | Port  | Purpose                       |
|-------------------|----------------------------------------|-------|-------------------------------|
| `redis`           | `redis:7.4-alpine`                     | 6379  | Cache / queue / pub-sub       |
| `redis_commander` | `rediscommander/redis-commander:latest`| 8081  | Web UI (basic-auth protected) |
| `redis_exporter`  | `oliver006/redis_exporter`             | 9121 (internal) | Prometheus metrics  |

## Configuration

`redis.conf` ships with sensible dev defaults:

- AOF persistence on (`appendfsync everysec`) + RDB snapshots.
- `maxmemory 256mb`, `allkeys-lru` eviction.
- `FLUSHALL` and `CONFIG` renamed to empty strings (re-enable per environment).
- Password supplied at container start via `--requirepass $REDIS_PASSWORD`.

## Run it

```bash
make up-redis
make logs-redis
make down-redis
```

UI: <http://localhost:8081> (basic-auth: `REDIS_UI_USER` / `REDIS_UI_PASSWORD`,
defaults `admin` / `admin`).

## Connecting

```python
import redis

client = redis.Redis(
    host="redis",            # from another container
    port=6379,
    password="redis",        # value of REDIS_PASSWORD
    decode_responses=True,
)
client.set("key", "value")
```

From the host machine, replace `host="redis"` with `host="localhost"`.

## Environment variables

| Var                | Default | Purpose                              |
|--------------------|---------|--------------------------------------|
| `REDIS_PORT`       | 6379    | Host port exposed for the Redis API. |
| `REDIS_PASSWORD`   | redis   | Auth password (`requirepass`).       |
| `REDIS_UI_PORT`    | 8081    | Host port for redis-commander.       |
| `REDIS_UI_USER`    | admin   | Basic-auth user for the UI.          |
| `REDIS_UI_PASSWORD`| admin   | Basic-auth password for the UI.      |

Override via `.env`.
