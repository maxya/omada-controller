SHELL := /usr/bin/env bash

COMPOSE_HOST := compose/docker-compose.host.yml
COMPOSE_BRIDGE := compose/docker-compose.bridge.yml
ENV_FILE := .env
OMADA_VERSION ?= 6.2.10.17
OMADA_VERSION := $(shell if [ -f "$(ENV_FILE)" ]; then sed -n 's/^OMADA_VERSION=//p' "$(ENV_FILE)" | tail -n 1; else printf '%s' "$(OMADA_VERSION)"; fi)
ROTATE_USER_FOR_TARGET = $(if $(filter command line,$(origin USER)),$(USER),omada)

.DEFAULT_GOAL := help

.PHONY: help
help: ## Show available targets
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make <target>\n\nTargets:\n"} /^[a-zA-Z0-9_.-]+:.*##/ {printf "  %-24s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: preflight
preflight: ## Validate local host, env, Compose, ports, and CPU support
	./scripts/preflight.sh

.PHONY: verify-download
verify-download: ## Download and verify the configured Omada artifact
	./scripts/verify-download.sh

.PHONY: build
build: ## Build local/omada-controller:<OMADA_VERSION>
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_HOST) build omada-controller

.PHONY: up
up: ## Start the host-mode stack
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_HOST) up -d

.PHONY: up-bridge
up-bridge: ## Start the bridge-mode stack
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_BRIDGE) up -d

.PHONY: down
down: ## Stop the host-mode stack
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_HOST) down

.PHONY: logs
logs: ## Follow stack logs
	docker compose --env-file $(ENV_FILE) -f $(COMPOSE_HOST) logs -f --tail=200

.PHONY: smoke
smoke: ## Check running stack and Omada login endpoint
	./scripts/smoke-test.sh

.PHONY: lint
lint: ## Run lightweight local lint checks
	bash -n docker/*.sh scripts/*.sh
	@if command -v shellcheck >/dev/null 2>&1; then shellcheck docker/*.sh scripts/*.sh; else echo "WARN: shellcheck not installed; skipped"; fi
	@if command -v yq >/dev/null 2>&1; then yq e '.' compose/*.yml compose/profiles/*.yml >/dev/null; else echo "WARN: yq not installed; skipped YAML parse"; fi

.PHONY: backup
backup: ## Stop controller, run authenticated MongoDB dump, restart controller
	./scripts/backup.sh

.PHONY: support-bundle
support-bundle: ## Collect redacted diagnostics
	./scripts/collect-support-bundle.sh

.PHONY: rotate-mongo-password
rotate-mongo-password: ## Rotate MongoDB user password; set USER=omada or USER=omada_backup and NEW_PASSWORD=...
	ROTATE_USER="$(ROTATE_USER_FOR_TARGET)" NEW_PASSWORD="$(NEW_PASSWORD)" ./scripts/rotate-mongo-password.sh

.PHONY: check-latest-omada
check-latest-omada: ## Print the official page to check for Omada releases
	./scripts/check-latest-omada.sh

.PHONY: test
test: lint ## Run available local tests
	@if command -v bats >/dev/null 2>&1; then bats tests; else echo "WARN: bats not installed; skipped BATS tests"; fi
