#!/bin/bash

# Creating and setting permission on cache folder
mkdir -p var/cache var/log
setfacl -R -m u:"www-data":rwX -m u:"$(whoami)":rwX var
setfacl -dR -m u:"www-data":rwX -m u:"$(whoami)":rwX var

# Installing Symfony CA certificate
symfony server:ca:install

# Creating .env.local.php...
composer dump-env "$APP_ENV"

symfony server:start
