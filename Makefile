#!make
ARGS = $(filter-out $@,$(MAKECMDGOALS))

# Setup ——————————————————————————————————————————————————————————————————————————————————
.DEFAULT_GOAL = help

OS := $(shell uname)
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
.PHONY: help install env uninstall

help: ## Outputs this help screen
	@grep -hE '(^[a-zA-Z0-9_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

install: env init_dir compose_up composer_install

env: ## Create env variables files if there are not already created
	@echo "Create environment variables files if not exists"
ifeq ($(OS), Darwin)
	cp -n .env.dist .env 2>/dev/null || :
	cp -n app/.env app/.env.local 2>/dev/null || :
	cp -n app/.php-cs-fixer.dist.php app/.php-cs-fixer.php 2>/dev/null || :
	cp -n app/phpstan.dist.neon app/phpstan.neon 2>/dev/null || :
else
	cp -n .env.dist .env
	cp -n app/.env app/.env.local
	cp -n app/.php-cs-fixer.dist.php app/.php-cs-fixer.php
	cp -n app/phpstan.dist.neon app/phpstan.neon
endif
	chmod 644 .env app/.env.local

init_dir: ## Init essentials directory
	mkdir -p app/var/cache app/var/log

uninstall: ## Uninstall application
	$(DOCKER_COMPOSE) down -v --rmi local
	sudo rm -Rf ./app/var ./app/vendor

## ——————————————————
## —— Docker
## ——————————————————
.PHONY: compose_up compose_down docker_build_latest

compose_up: ## Execute the docker compose up command
	$(DOCKER_COMPOSE) up -d

compose_down: ## Execute the docker compose down command
	$(DOCKER_COMPOSE) down

docker_build_latest: ## Build Docker latest image locally
	$(DOCKER) build -f ./docker/Dockerfile -t php:latest --target php_prod .
	$(DOCKER) build -f ./docker/Dockerfile -t caddy:latest --target caddy_prod .


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
## —— Caddy
## ——————————————————
.PHONY: caddy_fmt caddy_reload

caddy_fmt: ## Format Caddyfile config
	$(DOCKER_COMPOSE) exec -w /etc/caddy caddy caddy fmt --overwrite

caddy_reload: ## Reloading Caddy server
	$(DOCKER_COMPOSE) exec -w /etc/caddy caddy caddy reload

## ——————————————————
## —— Quality Assurance
## ——————————————————
.PHONY: qa lint lintTwig lintYaml csFixer csFixerLint phpStan

qa: lint csFixerLint phpStan sf_security ## Launch all QA steps

lint: lintTwig lintYaml ## Lint files

lintTwig: ## Lint TWIG files
	$(SYMFONY_CONSOLE) lint:twig templates

lintYaml: ## Lint YAML files
	$(SYMFONY_CONSOLE) lint:yaml config
	$(SYMFONY_CONSOLE) lint:yaml src

## —— PHP
csFixer: ## Apply php-cs-fixer
	$(PHP) vendor/bin/php-cs-fixer fix --using-cache=no --verbose --diff

csFixerLint: ## Lint php-cs-fixer
	$(PHP) vendor/bin/php-cs-fixer fix --dry-run --using-cache=no --verbose --diff

phpStan: ## PHPStan Check
	$(PHP_ROOT) vendor/bin/phpstan -vvv analyse src

## ——————————————————
## —— Symfony
## ——————————————————
.PHONY: sf_version sf_console sf_cc sf_security

sf_version: ## Displays Symfony version
	$(SYMFONY_CONSOLE) --version

sf_console: ## Use app console
	$(SYMFONY_CONSOLE) $(ARGS)

sf_cc: ## Clear caches
	$(SYMFONY_CONSOLE) cache:clear

sf_security: ## Check if there is known vulnerabilities
	$(PHP_ROOT) symfony security:check

# To avoid ${ARGS} errors ——————————————————————————————————————————————————————————————————————————————————
%::
	@:
