FROM php:8.3-fpm

ARG USER_ID=1000
ARG GROUP_ID=1000

RUN apt-get update && apt-get install -y \
    git curl libpng-dev libonig-dev libxml2-dev zip unzip \
    && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www

RUN groupadd -g ${GROUP_ID} dreamrooms \
    && useradd -m -u ${USER_ID} -g ${GROUP_ID} -s /bin/bash dreamrooms \
    && usermod -aG www-data dreamrooms

RUN mkdir -p /var/www/storage /var/www/bootstrap/cache \
    && chown -R ${USER_ID}:${GROUP_ID} /var/www

USER dreamrooms

CMD ["php-fpm"]
