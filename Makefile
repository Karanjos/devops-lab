.DEFAULT_GOAL := help
COMPOSE ?= docker compose

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-14s %s\n", $$1, $$2}'

db: ## Phase 1: start only Postgres
	$(COMPOSE) up -d postgres

backend-run: ## Phase 1: run the API on your machine, without Kafka (needs `make db`)
	cd backend && KAFKA_ENABLED=false mvn spring-boot:run

backend-test: ## Run backend unit tests
	cd backend && mvn -B test

frontend-dev: ## Phase 1: run the React dev server on :5173
	cd frontend && npm install && npm run dev

up: ## Phase 2: build and start the whole stack
	$(COMPOSE) up -d --build

down: ## Stop the stack (keeps data)
	$(COMPOSE) down

clean: ## Stop the stack and DELETE all data volumes
	$(COMPOSE) down -v

ps: ## Show container status
	$(COMPOSE) ps

logs: ## Follow logs of all services
	$(COMPOSE) logs -f --tail=100

smoke: ## End-to-end check: order -> Kafka -> processed -> Connect -> report table
	./scripts/smoke-test.sh

psql: ## Open a psql shell in the database
	$(COMPOSE) exec postgres psql -U orders -d orders

topics: ## List Kafka topics
	$(COMPOSE) exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka:9092 --list

.PHONY: help db backend-run backend-test frontend-dev up down clean ps logs smoke psql topics
