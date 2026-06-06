FROM php:8.3-fpm

# UID/GID del host: alinean el usuario del contenedor con el del anfitrión
# para que los ficheros creados en los bind mounts no queden como root
ARG USER_ID=1000
ARG GROUP_ID=1000

# Dependencias del sistema necesarias para compilar las extensiones PHP
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl libonig-dev libxml2-dev zip unzip \
    && rm -rf /var/lib/apt/lists/*

# Extensiones PHP que requiere Laravel
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www

# Usuario sin privilegios con el UID/GID del host para los bind mounts
RUN groupadd -g ${GROUP_ID} dreamrooms \
    && useradd -m -u ${USER_ID} -g ${GROUP_ID} -s /bin/bash dreamrooms \
    && usermod -aG www-data dreamrooms

# Carpetas que Laravel necesita escribir, con permisos del usuario de la app
RUN mkdir -p /var/www/storage /var/www/bootstrap/cache \
    && chown -R ${USER_ID}:${GROUP_ID} /var/www

USER dreamrooms

CMD ["php-fpm"]
