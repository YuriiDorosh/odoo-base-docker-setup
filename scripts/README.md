# scripts/

Helper bash scripts for day-to-day operations on the stack. All scripts read
`.env` from the repository root.

| Script                    | Purpose                                                   |
|---------------------------|-----------------------------------------------------------|
| `init.sh`                 | Create `.env`, ensure docker network and folders exist.   |
| `backup-db.sh [db]`       | On-demand `pg_dump` of the Odoo DB into `./backups/`.     |
| `restore-db.sh <file> [db]` | Drop+recreate DB and load a `.sql` or `.dump` file.     |
| `clean-backups.sh [days]` | Delete backup files older than N days (default 14).       |
| `install-addon.sh <addon> [db]` | Install an Odoo addon with `--stop-after-init`.     |
| `upgrade-addon.sh <addon> [db]` | Upgrade an installed Odoo addon.                    |
| `shell.sh [db]`           | Open the Odoo Python shell (`odoo shell`).                |
| `psql.sh [db]`            | Open `psql` against the Postgres container.               |
| `wait-for-postgres.sh [t]`| Block until Postgres is ready (timeout seconds).          |
| `healthcheck.sh`          | Print one-line status for every container in the stack.   |
| `lint-addons.sh`          | Run `ruff` + `pylint-odoo` over `src/addons`.             |

Make them executable once after cloning:

```bash
chmod +x scripts/*.sh
```
