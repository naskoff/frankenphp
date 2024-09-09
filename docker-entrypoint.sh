#!/bin/bash

COMPOSER_FLAGS=--no-cache --prefer-dist --no-autoloader --no-scripts --no-progress

composer install $COMPOSER_FLAGS

wait-for-it db:3306 -t 30

frankenphp php-cli bin/console doctrine:migrations:migrate --no-iteraction

wait-for-it rabbitmq:5672 -t 30

frankenphp php-cli bin/console messenger:setup-transport

exec docker-php-entrypoint "$@"
