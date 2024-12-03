# syntax=docker/dockerfile:1
ARG PHP_VERSION=8.4.1
ARG PHP_EXT_INSTALLER=2.7.4
ARG CADDY_VERSION=2.8.4
ARG APP_DIR=/app

# https://github.com/mlocati/docker-php-extension-installer
FROM mlocati/php-extension-installer:${PHP_EXT_INSTALLER} AS php_ext_installer


FROM php:${PHP_VERSION}-fpm AS php_common

ARG APP_DIR
WORKDIR $APP_DIR

# Install core package
RUN apt-get update && apt-get install -y --no-install-recommends \
    acl \
    yarn \
    make \
    && rm -rf /var/lib/apt/lists/*

# Install PHP core extensions
COPY --from=php_ext_installer /usr/bin/install-php-extensions /usr/local/bin/
RUN set -eux; \
    install-php-extensions \
      @composer \
      apcu-5.1.24 \
      intl \
      opcache \
    ;

# Composer configuration
# https://getcomposer.org/doc/03-cli.md#composer-allow-superuser
ENV COMPOSER_ALLOW_SUPERUSER=1

# PHP configuration
ENV PHP_INI_SCAN_DIR=":$PHP_INI_DIR/app.conf.d"
COPY --link ./docker/php/conf.d/10-app.ini $PHP_INI_DIR/app.conf.d/

# Entrypoint
COPY --link --chmod=755 ./docker/php/docker-entrypoint.sh /usr/local/bin/docker-entrypoint
ENTRYPOINT ["docker-entrypoint"]
CMD ["php-fpm"]


FROM php_common AS php_dev

RUN set -eux; \
    install-php-extensions \
      xdebug-3.4.0 \
    ;

# PHP configuration
RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"
COPY --link ./docker/php/conf.d/20-app.dev.ini $PHP_INI_DIR/app.conf.d/


FROM php_common AS php_prod

ENV APP_ENV=prod

# PHP configuration
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
COPY --link ./docker/php/conf.d/20-app.prod.ini $PHP_INI_DIR/app.conf.d/

# Prevent the reinstallation of vendors at every changes in the source code
COPY --link ./app/composer.* ./app/symfony.* ./
RUN set -eux; \
	composer install --no-cache --prefer-dist --no-dev --no-autoloader --no-scripts --no-progress

# Copy sources
COPY --link ./app/.env ./.env
COPY --link ./app/bin ./bin
COPY --link ./app/config ./config
COPY --link ./Makefile ./Makefile
COPY --link ./app/public ./public
COPY --link ./app/src ./src
COPY --link ./app/templates ./templates

RUN set -eux; \
	mkdir -p var/cache var/log; \
	composer dump-autoload --classmap-authoritative --no-dev; \
	composer dump-env prod; \
	composer run-script --no-dev post-install-cmd; \
	chmod +x bin/console; sync;


FROM php_common AS php_test

ENV APP_ENV=test

# Copy sources
COPY --link ./app/.php-cs-fixer.php ./app/phpstan.neon ./app/phpunit.xml ./
COPY --link ./app/composer.* ./app/symfony.* ./
COPY --link ./app/.env ./app/.env.test ./
COPY --link ./app/bin ./bin
COPY --link ./app/config ./config
COPY --link ./Makefile ./Makefile
COPY --link ./app/public ./public
COPY --link ./app/src ./src
COPY --link ./app/templates ./templates
COPY --link ./app/tests ./tests

# Re-install composer vendors for test environment
RUN composer install --quiet --no-scripts --no-progress


FROM caddy:${CADDY_VERSION}-alpine AS caddy_dev

# Caddy configuration
COPY ./docker/caddy/dev.Caddyfile /etc/caddy/dev.Caddyfile

CMD ["/usr/bin/caddy", "run", "--config", "/etc/caddy/dev.Caddyfile"]


FROM caddy:${CADDY_VERSION}-alpine AS caddy_prod

ARG APP_DIR

# Caddy configuration
COPY ./docker/caddy/Caddyfile /etc/caddy/Caddyfile

# Copy sources
COPY --from=php_prod $APP_DIR/public $APP_DIR/public

