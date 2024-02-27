ARG PHP_VERSION=8.3
ARG COMPOSER_VERSION=2.5
ARG NODE_VERSION=18
ARG APP_DIR=/app
ARG TZ=Europe/Paris

FROM composer:${COMPOSER_VERSION} AS composer

FROM php:${PHP_VERSION}-fpm as php_base

ARG TZ
ARG APP_DIR

# Get Symfony CLI
RUN curl -1sLf 'https://dl.cloudsmith.io/public/symfony/stable/setup.deb.sh' | bash

# Install core packages
ENV PACKAGES="curl g++ git libicu-dev locales netcat-openbsd symfony-cli unzip yarn"

RUN apt-get update \
    && apt-get install -y --no-install-recommends $PACKAGES \
    && rm -rf /var/lib/apt/lists/*

# Install PHP core extensions
# https://github.com/mlocati/docker-php-extension-installer
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/
RUN install-php-extensions intl opcache apcu

# Set locales & timezone
RUN echo "fr_FR.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen
RUN printf '[PHP]\ndate.timezone = %s\n' "$TZ" > /usr/local/etc/php/conf.d/tzone.ini

# Composer
ENV COMPOSER_HOME /.composer
ENV COMPOSER_ALLOW_SUPERUSER=1
COPY --from=composer /usr/bin/composer /usr/bin/composer

WORKDIR $APP_DIR

FROM php_base AS php_dev

# Network debug command (ping, nslookup, telnet, ...)
ENV PACKAGES="dnsutils iputils-ping telnet"

RUN apt-get update \
    && apt-get install -y --no-install-recommends $PACKAGES \
    && rm -rf /var/lib/apt/lists/*

# Specific dev php.ini(s)
COPY ./docker/php/php.dev.ini /usr/local/etc/php/php.ini

FROM php_base AS php_builder

COPY ./app/composer.* ./app/symfony.lock ./

RUN set -eux; \
	composer install --prefer-dist --no-dev --no-autoloader --no-scripts --no-progress; \
	composer clear-cache

COPY ./app/.env ./app/.env.prod ./
COPY ./app/bin ./bin
COPY ./app/config ./config
COPY ./app/public ./public
COPY ./app/src ./src

RUN set -eux; \
	mkdir -p var/cache var/log; \
	composer dump-autoload --classmap-authoritative --no-dev; \
	chmod +x bin/console; sync

FROM php_base AS php_prod

ENV APP_ENV prod

# Specific php.ini(s)
COPY ./docker/php/php.prod.ini $PHP_INI_DIR/php.ini

COPY --from=composer /usr/bin/composer /usr/local/bin/composer
COPY --from=php_builder $APP_DIR ./

COPY ./docker/php/docker-entrypoint.sh /usr/local/bin/docker-entrypoint
RUN chmod +x /usr/local/bin/docker-entrypoint

ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]
CMD ["php-fpm", "symfony server:start"]

FROM node:${NODE_VERSION} AS nodejs_builder

ARG APP_DIR
WORKDIR $APP_DIR

COPY ./app/package.json ./app/yarn.lock ./app/webpack.config.js ./app/.webpack-env.local ./
COPY ./app/assets/ ./assets
COPY --from=php_builder $APP_DIR ./

RUN set -eux; \
	yarn install; \
	yarn cache clean; \
    npm rebuild node-sass;

RUN set -eux; \
	yarn build
