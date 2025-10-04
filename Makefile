NETWORK_NAME := web
COMPOSE_FILE := docker-compose.production.yml

ensure-network:
	@echo "Ensuring Docker network '$(NETWORK_NAME)' exists..."
	@docker network inspect $(NETWORK_NAME) >/dev/null 2>&1 || docker network create $(NETWORK_NAME)
	@echo "Network '$(NETWORK_NAME)' is ready."

up: ensure-network
	@echo "Starting production Traefik container..."
	@docker compose -f $(COMPOSE_FILE) up -d
	@echo "Traefik is now running."

down:
	@echo "Stopping production Traefik container..."
	@docker compose -f $(COMPOSE_FILE) down
	@echo "Traefik container has been stopped."

restart: ensure-network
	@docker compose -f $(COMPOSE_FILE) up -d --force-recreate

.PHONY: ensure-network up down restart
