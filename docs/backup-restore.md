# Backup & restore

There are **two** backup mechanisms in this repo.

## 1. Automatic — `postgres_backup` sidecar

Defined in `docker_compose/db/docker-compose.yml`, it runs alongside Postgres
and writes a daily `pg_dump` of the database listed in
`docker_compose/db/backup.sh` (variable
`DATABASE_WHICH_YOU_CREATED_IN_ODOO_WEB_INTERFACE`).

Output files land in `docker_compose/db/backups/` and are git-ignored.

To restore from there:

```bash
make load-backup FILE=backup_prod_2025-10-14.sql
```

(This uses `pg_restore` and assumes a custom-format dump. For plain
`.sql` files, use `make restore-db` below.)

## 2. On-demand — `./scripts/`

`make backup` and `make restore-db` go through `./scripts/`, which writes to
the top-level `./backups/` folder (also git-ignored).

```bash
# Dump the database named in $ODOO_DB.
make backup

# Dump a different database.
make backup DB=staging

# Restore from a .sql or .dump file. Drops & recreates the target DB first.
make restore-db FILE=backups/prod_2025-10-14_120000.sql
make restore-db FILE=backups/prod_2025-10-14_120000.sql DB=staging
```

## Retention

```bash
make clean-backups            # delete files older than 14 days
make clean-backups DAYS=30    # delete files older than 30 days
```

The `.gitkeep` file is preserved.

## What does and doesn't get backed up

- **Backed up:** all rows in the chosen PostgreSQL database, including Odoo's
  `ir_attachment` (if you store attachments in the DB).
- **Not backed up:** the filestore on disk (`odoo-data` volume, mounted at
  `/var/lib/odoo`). For a complete clone of an environment, also snapshot the
  filestore — for example:
  ```bash
  docker run --rm -v odoo_odoo-data:/data -v "$PWD/backups:/out" \
      alpine tar czf /out/filestore_$(date +%F).tgz -C /data .
  ```

## Restoring through the Odoo web UI

Odoo's `/web/database/manager` page also supports zip-based backup/restore
(database + filestore in one file). That route uses `ODOO_ADMIN_PASSWD` from
`odoo.conf` / `.env`.
