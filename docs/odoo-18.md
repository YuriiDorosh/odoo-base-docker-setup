# Odoo 18 notes

This stack pins the official `odoo:18` image (see `docker_compose/odoo/Dockerfile`).
A few things changed between Odoo 17 and 18 that are worth knowing if you
came from an older template.

## Image layout

The Dockerfile only adds extra fonts on top of the base image:

```dockerfile
FROM odoo:18
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    fonts-dejavu-core fonts-dejavu-extra gsfonts fonts-liberation fontconfig \
 && fc-cache -f -v \
 && rm -rf /var/lib/apt/lists/*
RUN chown -R odoo:odoo /var/lib/odoo
USER odoo
```

Keep new system packages in this Dockerfile rather than installing them at
runtime — that way reproducible builds work.

## Configuration

`src/configs/odoo.conf` is mounted read-only into the container at
`/etc/odoo/odoo.conf`. Highlights:

```ini
admin_passwd = ChangeMe_Even_Stronger_456
db_host = postgres
db_port = 5432
db_user = odoo
db_password = ChangeMe_Strong_123

addons_path = /usr/lib/python3/dist-packages/odoo/addons,/mnt/extra-addons
proxy_mode = True

logfile = /mnt/logs/odoo-server.log
logrotate = False
log_level = debug_rpc
log_handler = :INFO
log_db_level = warning

max_cron_threads = 2
workers = 3
```

- `proxy_mode = True` because nginx terminates the connection and forwards.
- Multi-worker mode (`workers > 0`) requires nginx in front to handle the
  longpolling/websocket port — that's the topology used by the bundled
  `docker_compose/odoo/docker-compose.yml`.
- The `logs/` host folder is bind-mounted so you can `tail -f` server logs
  outside the container.

## Filestore vs database

Odoo writes attachments and asset bundles to `/var/lib/odoo/<dbname>` inside
the container (the `odoo-data` named volume). Database dumps **do not**
include this filestore — see [backup-restore.md](backup-restore.md).

## Useful Odoo CLI flags

```bash
odoo -c /etc/odoo/odoo.conf -d $DB -i <addon> --stop-after-init --no-http
odoo -c /etc/odoo/odoo.conf -d $DB -u <addon> --stop-after-init --no-http
odoo -c /etc/odoo/odoo.conf -d $DB --test-enable -i <addon> --stop-after-init --no-http
odoo shell -c /etc/odoo/odoo.conf -d $DB --no-http
```

All of these are wrapped by the corresponding `scripts/*.sh` and `make`
targets.

## Python version

Odoo 18 ships on Python 3.10/3.11 in the official image. Match the host
Python you use for linting accordingly (the repo targets ≥ 3.11).

## Useful upstream docs

- Odoo 18 changelog: <https://www.odoo.com/odoo-18-release-notes>
- ORM reference: <https://www.odoo.com/documentation/18.0/developer/reference/backend/orm.html>
- Custom modules: <https://www.odoo.com/documentation/18.0/developer/howtos/backend.html>
