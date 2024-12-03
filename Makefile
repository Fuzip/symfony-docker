# Executables (local)
DOCKER_COMP = docker compose

# Docker containers
PHP_CONT = $(DOCKER_COMP) exec php

# Executables
PHP      = $(PHP_CONT) php
COMPOSER = $(PHP_CONT) composer
SYMFONY  = $(PHP) bin/console

# Misc
.DEFAULT_GOAL = help
.PHONY        : help build build_prod up up_prod start start_prod down logs sh composer vendor sf cc qa csFixer phpStan test

## —— 🎵 🐳 The Symfony Docker Makefile 🐳 🎵 ——————————————————————————————————
help: ## Outputs this help screen
	@grep -E '(^[a-zA-Z0-9\./_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

## —— Docker 🐳 ————————————————————————————————————————————————————————————————
build: ## Builds the Docker images
	@$(DOCKER_COMP) build --pull --no-cache

build_prod: ## Builds the prod Docker images
	@$(DOCKER_COMP) -f compose.prod.yml build --pull --no-cache

up: ## Start the docker hub in detached mode (no logs)
	@$(DOCKER_COMP) up -d

up_prod: ## Start the docker prod hub in detached mode (no logs)
	@$(DOCKER_COMP) -f compose.prod.yml up -d

start: build up ## Build and start the containers

start_prod: build_prod up_prod ## Build and start the prod containers

down: ## Stop the docker hub
	@$(DOCKER_COMP) down --remove-orphans --volumes

logs: ## Show live logs
	@$(DOCKER_COMP) logs --tail=0 --follow

sh: ## Connect to the php container
	@$(PHP_CONT) sh

bash: ## Connect to the php container via bash so up and down arrows go to previous commands
	@$(PHP_CONT) bash

## —— Composer 🧙 ——————————————————————————————————————————————————————————————
composer: ## Run composer, pass the parameter "c=" to run a given command, example: make composer c='req symfony/orm-pack'
	@$(eval c ?=)
	@$(COMPOSER) $(c)

vendor: ## Install vendors according to the current composer.lock file
vendor: c=install --prefer-dist --no-dev --no-progress --no-scripts --no-interaction
vendor: composer

## —— Symfony 🎵 ———————————————————————————————————————————————————————————————
sf: ## List all Symfony commands or pass the parameter "c=" to run a given command, example: make sf c=about
	@$(eval c ?=)
	@$(SYMFONY) $(c)

cc: c=c:c ## Clear the cache
cc: sf

## —— QA ✅ ———————————————————————————————————————————————————————————————
qa: ## Run all quality assurance step
qa: csFixer phpStan

csFixer: ## Run CSFixer, pass the parameter "c=" to add options, example: make csFixer c='--dry-run'
	@$(eval c ?=)
	@$(DOCKER_COMP) exec php vendor/bin/php-cs-fixer fix --using-cache=no --verbose --diff $(c)

phpStan: ## Run PHPStan, pass the parameter "c=" to add options, example: make phpStan c='-vv'
	@$(eval c ?=)
	@$(DOCKER_COMP) exec php vendor/bin/phpstan analyse src $(c)

test: ## Start tests with phpunit, pass the parameter "c=" to add options to phpunit, example: make test c="--group e2e --stop-on-failure"
	@$(eval c ?=)
	@$(DOCKER_COMP) exec -e APP_ENV=test php vendor/bin/phpunit $(c)
