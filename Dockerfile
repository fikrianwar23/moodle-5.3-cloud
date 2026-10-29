
FROM php:8.4-fpm-bookworm

# Install OS dependencies and PHP extensions
RUN apt-get update && apt-get install -y --no-install-recommends \
    git unzip libicu-dev libxml2-dev libzip-dev \
    libpng-dev libjpeg62-turbo-dev libfreetype6-dev \
    libcurl4-openssl-dev libonig-dev libxslt1-dev \
    libldap2-dev libsodium-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" \
       mysqli pdo_mysql intl gd soap zip exif opcache \
       mbstring sockets xsl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

WORKDIR /var/www/html

ARG MOODLE_BRANCH=MOODLE_503_STABLE

RUN git clone --depth 1 --branch "${MOODLE_BRANCH}" \
    https://github.com/moodle/moodle.git /var/www/html \
    && composer install --no-dev --classmap-authoritative

# PHP configuration
COPY php/moodle.ini /usr/local/etc/php/conf.d/moodle.ini

# Verify required PHP extensions and Composer dependencies
RUN php -m | grep -qi '^sodium$' \
    && php -m | grep -qi '^mysqli$' \
    && php -m | grep -qi '^intl$' \
    && php -m | grep -qi '^zip$' \
    && test -f /var/www/html/vendor/autoload.php

CMD ["php-fpm"]
