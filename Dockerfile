FROM php:8.3-fpm-alpine

RUN apk add --no-cache \
    curl \
    exiftool \
    freetype-dev \
    git \
    icu-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    libwebp-dev \
    libxml2-dev \
    libzip-dev \
    nginx \
    nodejs \
    npm \
    oniguruma-dev \
    supervisor \
    unzip \
    zip

RUN docker-php-ext-configure gd \
        --with-freetype \
        --with-jpeg \
        --with-webp \
    && docker-php-ext-install -j"$(getconf _NPROCESSORS_ONLN)" \
        bcmath \
        exif \
        ftp \
        gd \
        intl \
        mbstring \
        pcntl \
        pdo_mysql \
        xml \
        zip

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html
COPY . .

RUN composer install \
        --no-interaction \
        --no-progress \
        --prefer-dist \
        --optimize-autoloader \
    && npm ci --no-audit --no-fund \
    && npm run production \
    && rm -rf node_modules

RUN mkdir -p \
        storage/app/public \
        storage/framework/cache \
        storage/framework/sessions \
        storage/framework/views \
        storage/logs \
        bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R ug+rwx storage bootstrap/cache

COPY docker/nginx.conf /etc/nginx/nginx.conf
COPY docker/supervisord.conf /etc/supervisord.conf
COPY docker/start.sh /usr/local/bin/start-app
RUN chmod +x /usr/local/bin/start-app

EXPOSE 80

CMD ["/usr/local/bin/start-app"]
