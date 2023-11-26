ARG PHP_VERSION=8.2
ARG COMPOSER_VERSION=2.5
ARG APP_DIR=/app
ARG TZ=Europe/Paris

FROM composer:${COMPOSER_VERSION} AS composer

FROM php:${PHP_VERSION}-fpm as php_base

ARG TZ

###
# Pre-script
###

# Get Symfony CLI
RUN curl -1sLf 'https://dl.cloudsmith.io/public/symfony/stable/setup.deb.sh' | bash

###
# Install core packages
###
ENV PACKAGES="acl curl g++ git libicu-dev locales netcat-openbsd symfony-cli unzip yarn"

RUN apt-get update \
    && apt-get -y upgrade \
    && apt-get install -y --no-install-recommends $PACKAGES \
    && rm -rf /var/lib/apt/lists/*

# Set locales
RUN echo "fr_FR.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen

# PHP Timezone
RUN printf '[PHP]\ndate.timezone = "$TZ"\n' > /usr/local/etc/php/conf.d/tzone.ini

# Intl
RUN docker-php-ext-configure intl \
    && docker-php-ext-install intl

# OPCache
RUN docker-php-ext-configure opcache \
    && docker-php-ext-install opcache

# Composer
ENV COMPOSER_HOME /.composer
ENV COMPOSER_ALLOW_SUPERUSER=1
COPY --from=composer /usr/bin/composer /usr/bin/composer

# Build the dev image
FROM php_base AS php_dev

ARG APP_DIR

# Network debug command (ping, nslookup, telnet, ...)
ENV PACKAGES="dnsutils iputils-ping telnet"

RUN apt-get update \
    && apt-get -y upgrade \
    && apt-get install -y --no-install-recommends $PACKAGES \
    && rm -rf /var/lib/apt/lists/*

# Specific dev php.ini(s)
COPY ./docker/php/php.dev.ini /usr/local/etc/php/php.ini

WORKDIR $APP_DIR

# PHP Builder
FROM php_base AS php_builder

ARG APP_DIR

WORKDIR $APP_DIR

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

# Build the prod image
FROM php_base AS php_prod

ARG APP_DIR
ENV APP_ENV prod

# Specific php.ini(s)
COPY ./docker/php/php.prod.ini $PHP_INI_DIR/php.ini

WORKDIR $APP_DIR

COPY --from=composer /usr/bin/composer /usr/local/bin/composer
COPY --from=php_builder $APP_DIR ./

COPY ./docker/php/docker-entrypoint.sh /usr/local/bin/docker-entrypoint
RUN chmod +x /usr/local/bin/docker-entrypoint

ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]
CMD ["php-fpm", "symfony server:start"]
