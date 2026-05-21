# =============================================================================
# Odoo 18 base docker stack — Makefile
#
# Conventions:
#   up-<svc>      bring service up in the background
#   down-<svc>    stop & remove service containers
#   restart-<svc> down then up
#   logs-<svc>    tail logs for the container
#   shell-<svc>   exec into the container
#
# Profiles:
#   *             dev profile (default docker-compose.yml)
#   *-prod        prod profile (docker-compose-prod.yml)
#
# Run `make help` for a discoverable list.
# =============================================================================

SHELL := /bin/bash

# --- Tooling --------------------------------------------------------------
DC          := docker compose
ENV         := --env-file .env
LOGS        := docker logs -f --tail=200
EXEC        := docker exec -it

# --- Container names ------------------------------------------------------
ODOO_CONTAINER       := odoo
NGINX_CONTAINER      := nginx
DB_CONTAINER         := postgres
DB_BACKUP_CONTAINER  := postgres_backup
PGADMIN_CONTAINER    := pgadmin
ADMINER_CONTAINER    := adminer-postgres
RABBITMQ_CONTAINER   := rabbitmq
KAFKA_CONTAINER      := kafka
KAFKA_UI_CONTAINER   := kafka_ui
REDIS_CONTAINER      := redis
REDIS_UI_CONTAINER   := redis_commander
PROMETHEUS_CONTAINER := prometheus
GRAFANA_CONTAINER    := grafana

# --- Network --------------------------------------------------------------
NETWORK_NAME      := backend
NETWORK_NAME_PROD := backend-prod

# --- Compose file shortcuts ----------------------------------------------
DB_COMPOSE          := docker_compose/db/docker-compose.yml
DB_COMPOSE_PROD     := docker_compose/db/docker-compose-prod.yml
ODOO_COMPOSE        := docker_compose/odoo/docker-compose.yml
ODOO_COMPOSE_PROD   := docker_compose/odoo/docker-compose-prod.yml
PGADMIN_COMPOSE     := docker_compose/pgadmin/docker-compose.yml
PGADMIN_COMPOSE_PROD:= docker_compose/pgadmin/docker-compose-prod.yml
ADMINER_COMPOSE     := docker_compose/adminer/docker-compose.yml
ADMINER_COMPOSE_PROD:= docker_compose/adminer/docker-compose-prod.yml
RABBITMQ_COMPOSE    := docker_compose/message_brokers/rabbitmq/docker-compose.yml
KAFKA_COMPOSE       := docker_compose/message_brokers/kafka/docker-compose.yml
REDIS_COMPOSE       := docker_compose/redis/docker-compose.yml
MONITORING_COMPOSE  := docker_compose/monitoring/docker-compose.yml

-include .env
export

.DEFAULT_GOAL := help
.PHONY: help \
        init network network-prod \
        up down restart logs ps \
        up-prod down-prod \
        up-db up-db-build down-db logs-db shell-db \
        up-odoo up-odoo-build down-odoo logs-odoo shell-odoo \
        up-pgadmin down-pgadmin logs-pgadmin \
        up-adminer down-adminer logs-adminer \
        up-rabbitmq down-rabbitmq logs-rabbitmq shell-rabbitmq \
        up-kafka down-kafka logs-kafka shell-kafka \
        up-brokers down-brokers \
        up-redis down-redis logs-redis shell-redis restart-redis cli-redis \
        up-monitoring up-monitoring-build down-monitoring logs-monitoring \
        backup restore-db load-backup \
        install-addon upgrade-addon odoo-shell odoo-psql odoo-test \
        health clean-backups stop-all rm-all prune \
        lint format

# ============================================================================
# Help
# ============================================================================
help: ## Show this help
	@echo ""
	@echo "Odoo 18 docker stack — available targets:"
	@echo ""
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / { printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@echo ""

# ============================================================================
# Bootstrap
# ============================================================================
init: ## Create .env, network and required folders
	./scripts/init.sh

network: ## Ensure the dev docker network exists
	@docker network inspect $(NETWORK_NAME) >/dev/null 2>&1 || \
		(echo "Creating network $(NETWORK_NAME)..." && docker network create $(NETWORK_NAME))

network-prod: ## Ensure the prod docker network exists
	@docker network inspect $(NETWORK_NAME_PROD) >/dev/null 2>&1 || \
		(echo "Creating network $(NETWORK_NAME_PROD)..." && docker network create $(NETWORK_NAME_PROD))

# ============================================================================
# Top-level orchestration (dev)
# ============================================================================
up: network up-db up-odoo up-pgadmin up-adminer ## Bring up the core dev stack (db + odoo + ui)

down: down-adminer down-pgadmin down-odoo down-db ## Stop the core dev stack

restart: down up ## Restart core dev stack

up-full: up up-redis up-brokers up-monitoring ## Bring up EVERYTHING (core + redis + brokers + monitoring)

down-full: down-monitoring down-brokers down-redis down ## Tear down EVERYTHING

ps: ## List running containers in this project
	@docker ps --filter "network=$(NETWORK_NAME)"

logs: ## Tail logs for odoo + postgres
	$(LOGS) $(ODOO_CONTAINER) &
	$(LOGS) $(DB_CONTAINER)

# ============================================================================
# Top-level orchestration (prod)
# ============================================================================
up-prod: network-prod ## Bring up the core prod stack
	$(DC) -f $(DB_COMPOSE_PROD) $(ENV) up -d
	$(DC) -f $(ODOO_COMPOSE_PROD) $(ENV) up -d
	$(DC) -f $(ADMINER_COMPOSE_PROD) $(ENV) up -d

down-prod: ## Stop the core prod stack
	$(DC) -f $(ADMINER_COMPOSE_PROD) down
	$(DC) -f $(ODOO_COMPOSE_PROD) down
	$(DC) -f $(DB_COMPOSE_PROD) down

# ============================================================================
# PostgreSQL
# ============================================================================
up-db: network ## Start postgres + backup sidecar
	$(DC) -f $(DB_COMPOSE) $(ENV) up -d

up-db-build: network ## Rebuild and start postgres
	$(DC) -f $(DB_COMPOSE) $(ENV) build --no-cache
	$(DC) -f $(DB_COMPOSE) $(ENV) up -d

down-db: ## Stop postgres
	$(DC) -f $(DB_COMPOSE) down

logs-db: ## Tail postgres logs
	$(LOGS) $(DB_CONTAINER)

shell-db: ## Open a bash shell inside the postgres container
	$(EXEC) $(DB_CONTAINER) bash

# ============================================================================
# Odoo
# ============================================================================
up-odoo: network ## Start Odoo (and nginx in front of it)
	$(DC) -f $(ODOO_COMPOSE) $(ENV) up -d

up-odoo-build: network ## Rebuild and start Odoo
	$(DC) -f $(ODOO_COMPOSE) $(ENV) build --no-cache
	$(DC) -f $(ODOO_COMPOSE) $(ENV) up -d

down-odoo: ## Stop Odoo
	$(DC) -f $(ODOO_COMPOSE) down

logs-odoo: ## Tail Odoo logs
	$(LOGS) $(ODOO_CONTAINER)

shell-odoo: ## Open a bash shell inside the Odoo container
	$(EXEC) $(ODOO_CONTAINER) bash

restart-odoo: down-odoo up-odoo ## Restart Odoo

restart-db: down-db up-db ## Restart PostgreSQL

restart-monitoring: down-monitoring up-monitoring ## Restart the monitoring stack

restart-brokers: down-brokers up-brokers ## Restart RabbitMQ + Kafka

odoo-shell: ## Open the Odoo Python shell (`odoo shell`)
	./scripts/shell.sh

odoo-psql: ## Open psql against the Odoo database
	./scripts/psql.sh

odoo-test: ## Run Odoo tests for a comma-separated MODULES list (MODULES=base_search_fuzzy)
	$(EXEC) $(ODOO_CONTAINER) odoo -c /etc/odoo/odoo.conf -d $(ODOO_DB) \
	    --test-enable -i $(MODULES) --stop-after-init --no-http

# ============================================================================
# pgAdmin / Adminer
# ============================================================================
up-pgadmin: network ## Start pgAdmin at http://localhost:5050
	$(DC) -f $(PGADMIN_COMPOSE) $(ENV) up -d

down-pgadmin: ## Stop pgAdmin
	$(DC) -f $(PGADMIN_COMPOSE) down

logs-pgadmin: ## Tail pgAdmin logs
	$(LOGS) $(PGADMIN_CONTAINER)

up-adminer: network ## Start Adminer at http://localhost:8080
	$(DC) -f $(ADMINER_COMPOSE) $(ENV) up -d

down-adminer: ## Stop Adminer
	$(DC) -f $(ADMINER_COMPOSE) down

logs-adminer: ## Tail Adminer logs
	$(LOGS) $(ADMINER_CONTAINER)

# ============================================================================
# Message brokers
# ============================================================================
up-brokers: up-rabbitmq up-kafka ## Start both RabbitMQ and Kafka

down-brokers: down-kafka down-rabbitmq ## Stop both brokers

up-rabbitmq: network ## Start RabbitMQ (UI: http://localhost:15672)
	$(DC) -f $(RABBITMQ_COMPOSE) $(ENV) up -d

down-rabbitmq: ## Stop RabbitMQ
	$(DC) -f $(RABBITMQ_COMPOSE) down

logs-rabbitmq: ## Tail RabbitMQ logs
	$(LOGS) $(RABBITMQ_CONTAINER)

shell-rabbitmq: ## Open shell inside RabbitMQ container
	$(EXEC) $(RABBITMQ_CONTAINER) bash

up-kafka: network ## Start Kafka (UI: http://localhost:8089)
	$(DC) -f $(KAFKA_COMPOSE) $(ENV) up -d

down-kafka: ## Stop Kafka
	$(DC) -f $(KAFKA_COMPOSE) down

logs-kafka: ## Tail Kafka logs
	$(LOGS) $(KAFKA_CONTAINER)

shell-kafka: ## Open shell inside Kafka container
	$(EXEC) $(KAFKA_CONTAINER) bash

# ============================================================================
# Redis
# ============================================================================
up-redis: network ## Start Redis + redis-commander + redis_exporter
	$(DC) -f $(REDIS_COMPOSE) $(ENV) up -d

down-redis: ## Stop Redis
	$(DC) -f $(REDIS_COMPOSE) down

restart-redis: down-redis up-redis ## Restart Redis

logs-redis: ## Tail Redis logs
	$(LOGS) $(REDIS_CONTAINER)

shell-redis: ## Open a shell inside the Redis container
	$(EXEC) $(REDIS_CONTAINER) sh

cli-redis: ## Open redis-cli authenticated with $REDIS_PASSWORD
	$(EXEC) $(REDIS_CONTAINER) redis-cli -a $(REDIS_PASSWORD)

# ============================================================================
# Monitoring (Prometheus + Grafana + exporters)
# ============================================================================
up-monitoring: network ## Start Prometheus + Grafana + exporters
	$(DC) -f $(MONITORING_COMPOSE) $(ENV) up -d

up-monitoring-build: network ## Rebuild and start the monitoring stack
	$(DC) -f $(MONITORING_COMPOSE) $(ENV) build --no-cache
	$(DC) -f $(MONITORING_COMPOSE) $(ENV) up -d

down-monitoring: ## Stop the monitoring stack
	$(DC) -f $(MONITORING_COMPOSE) down

logs-monitoring: ## Tail Prometheus + Grafana logs
	$(LOGS) $(PROMETHEUS_CONTAINER) &
	$(LOGS) $(GRAFANA_CONTAINER)

# ============================================================================
# Backup / restore
# ============================================================================
backup: ## Run an on-demand pg_dump into ./backups (DB=<name> overrides ODOO_DB)
	./scripts/backup-db.sh $(DB)

restore-db: ## Restore from FILE=<path>  (use DB=<name> to override target db)
	./scripts/restore-db.sh $(FILE) $(DB)

# Legacy alias used by the in-container backup sidecar.
# make load-backup FILE=your_backup_file.dump
load-backup: ## Pg_restore FILE=<filename inside backup container>
	@echo "Restoring backup $(FILE) into database $(POSTGRES_DB)..."
	docker exec -i $(DB_CONTAINER) pg_restore -U $(POSTGRES_USER) -d $(POSTGRES_DB) "/backups/$(FILE)"

clean-backups: ## Purge backups older than DAYS=<n> (default 14)
	./scripts/clean-backups.sh $(DAYS)

# ============================================================================
# Addon helpers
# ============================================================================
install-addon: ## Install ADDON=<name> into ODOO_DB (or DB=<name>)
	./scripts/install-addon.sh $(ADDON) $(DB)

upgrade-addon: ## Upgrade ADDON=<name> in ODOO_DB (or DB=<name>)
	./scripts/upgrade-addon.sh $(ADDON) $(DB)

# ============================================================================
# Diagnostics / utility
# ============================================================================
health: ## One-line status for every container
	./scripts/health-check.sh 2>/dev/null || ./scripts/healthcheck.sh

stop-all: ## Stop every docker container on the host
	@docker stop $$(docker ps -q) 2>/dev/null || true

rm-all: ## Remove every stopped container on the host
	@docker rm $$(docker ps -aq) 2>/dev/null || true

prune: ## Prune unused images/volumes/networks (asks for confirmation)
	docker system prune

# ============================================================================
# Python tooling
# ============================================================================
lint: ## Run ruff + pylint-odoo against src/addons
	./scripts/lint-addons.sh

format: ## Run black + isort over src/ and tests/
	black src tests
	isort src tests

test: ## Run host-side pytest suite (unit tests only)
	pytest tests/unit

test-integration: ## Run integration tests against a running stack
	RUN_INTEGRATION=1 pytest tests/integration

test-cov: ## Run unit tests with coverage report
	pytest tests/unit --cov --cov-report=term-missing
