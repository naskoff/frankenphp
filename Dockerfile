FROM dunglas/frankenphp:1-php8.3 AS upstream

FROM upstream AS base

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    acl \
    file \
    gettext \
    git \
    libnss3-tools \
    make \
    nodejs \
    npm \
    supervisor \
    curl \
    jq \
    && npm i -g yarn \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

RUN set -eux; install-php-extensions \
        @composer \
        amqp \
        apcu \
        intl  \
        opcache \
        redis \
        wait-for-it \
        zip;

COPY --link Caddyfile /etc/caddy/Caddyfile
COPY --link docker-entrypoint.sh /docker-entrypoint.sh

RUN chmod a+x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf", "-n"]

HEALTHCHECK --start-period=60s CMD curl -f http://localhost:2019/metrics || exit 1

FROM base AS dev

RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

RUN set -eux; install-php-extensions \
        pcov \
        xdebug;

FROM base AS prod

RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

ENV FRANKENPHP_CONFIG="import worker.Caddyfile"