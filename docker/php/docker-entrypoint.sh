#!/bin/bash
set -e

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	set -- php-fpm "$@"
fi

if [ "$1" = 'php-fpm' ] || [ "$1" = 'bin/console' ]; then
	if [ "$APP_ENV" == "prod" ]; then
		# Creating .env.local.php...
		composer dump-env "$APP_ENV"
	fi
fi


exec docker-php-entrypoint "$@"
