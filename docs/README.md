# docs/

Project documentation. Plain Markdown + a few MDX files (rendered as
Markdown by Github too — the extension just enables MDX-aware tooling like
Docusaurus / Nextra later on).

| File                    | What                                                   |
|-------------------------|--------------------------------------------------------|
| [setup.md](setup.md)             | First-time bootstrap, requirements, ports.    |
| [services.md](services.md)       | Every container in the stack and its ports.   |
| [odoo-18.md](odoo-18.md)         | Image, config, and Odoo 18 specifics.         |
| [addons.md](addons.md)           | Bundled addons + how to add new ones.         |
| [makefile.md](makefile.md)       | Full `make` target reference.                 |
| [monitoring.md](monitoring.md)   | Prometheus + Grafana stack.                   |
| [message-brokers.md](message-brokers.md) | RabbitMQ + Kafka setup.               |
| [redis.md](redis.md)             | Redis 7 + UI + exporter setup.                |
| [backup-restore.md](backup-restore.md) | Two backup paths and restore commands.  |
| [development.md](development.md) | Local Python tooling, tests, pre-commit.      |
| [architecture.mdx](architecture.mdx) | ASCII topology + volumes/bind-mounts.     |
| [troubleshooting.mdx](troubleshooting.mdx) | Common failures and fixes.          |

To render these locally with mkdocs-material (already in
`requirements/dev-requirements.txt`), create a minimal `mkdocs.yml` and run
`mkdocs serve`.
