#!make
ARGS = $(filter-out $@,$(MAKECMDGOALS))

# Setup ——————————————————————————————————————————————————————————————————————————————————
.DEFAULT_GOAL = help

CURRENT_UID := $(shell id -u)
CURRENT_GID := $(shell id -g)

DOCKER ?= docker
DOCKER_COMPOSE ?= $(DOCKER) compose
DOCKER_EXEC ?= $(DOCKER_COMPOSE) exec --user="$(CURRENT_UID):$(CURRENT_GID)"
DOCKER_EXEC_ROOT ?= $(DOCKER_COMPOSE) exec
DOCKER_RUN ?= $(DOCKER_COMPOSE) run --rm --user="$(CURRENT_UID):$(CURRENT_GID)"
DOCKER_BUILD ?= $(DOCKER) build
DOCKER_PUSH ?= $(DOCKER) push

PHP = $(DOCKER_EXEC) php
PHP_ROOT = $(DOCKER_EXEC_ROOT) php

SYMFONY_CONSOLE = $(PHP) bin/console

COMPOSER = $(PHP_ROOT) composer

## ——————————————————
## —— Project
## ——————————————————
.PHONY: help install files_permissions env

help: ## Outputs this help screen
	@grep -hE '(^[a-zA-Z0-9_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

install: env docker_compose_up composer_install files_permissions

files_permissions: ## ACL permissions
	sudo setfacl -dR -m u:$(CURRENT_UID):rwX ./app/var
	sudo setfacl -R -m u:$(CURRENT_UID):rwX ./app/var

env: ## Create env variables files if there are not already created
	@echo "Create environment variables files if not exists"
	cp -n .env.dist .env
	chmod 644 .env

## ——————————————————
## —— Docker
## ——————————————————
.PHONY: docker_compose_up docker_build_prod docker_run_prod

docker_compose_up: ## Execute the docker compose up command
	$(DOCKER_COMPOSE) up -d

docker_build_prod: ## Build the production docker image
	 $(DOCKER_BUILD) -t symfonydocker/php:prod --target php_prod -f ./docker/Dockerfile ./

docker_run_prod: ## Run the production docker image
	$(DOCKER) run --rm -d -p 443:8000 --name symfony_docker symfonydocker/php:prod

## ——————————————————
## —— Composer
## ——————————————————
.PHONY: composer_install composer_update composer_require composer_require_dev

composer_install: ## Install composer dependencies
	$(COMPOSER) install --optimize-autoloader --no-scripts

composer_update: ## Update composer dependencies
	$(COMPOSER) update --no-scripts

composer_require: ## Require composer dependency
	$(COMPOSER) require $(ARGS)

composer_require_dev:
	$(COMPOSER) require --dev $(ARGS)

## ——————————————————
## —— Symfony
## ——————————————————
.PHONY: sf_version sf_console sf_cc sf_security sf_install_ca sf_start_server sf_stop_server sf_log_server

sf_version: ## Displays Symfony version
	$(SYMFONY_CONSOLE) --version

sf_console: ## Use app console
	$(SYMFONY_CONSOLE) $(ARGS)

sf_cc: ## Clear caches
	$(SYMFONY_CONSOLE) cache:clear

sf_security: ## Check if there is known vulnerabilities
	$(PHP_ROOT) symfony security:check

sf_install_ca: ## Install local CA certificate
	$(PHP_ROOT) symfony server:ca:install

sf_start_server: ## Start local Symfony server
	$(PHP_ROOT) symfony server:start -d

sf_stop_server: ## Stop local Symfony server
	$(PHP_ROOT) symfony server:stop

sf_log_server: ## Display log of local Symfony server
	$(PHP_ROOT) symfony server:log

# To avoid ${ARGS} errors ——————————————————————————————————————————————————————————————————————————————————
%::
	@:
