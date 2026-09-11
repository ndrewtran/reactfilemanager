#!/bin/sh
set -eu

cd /var/www/html

mkdir -p \
    storage/app/public \
    storage/framework/cache \
    storage/framework/sessions \
    storage/framework/views \
    storage/logs \
    bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache

if [ ! -L public/storage ]; then
    php artisan storage:link || true
fi

php artisan config:cache
php artisan route:cache
php artisan view:cache

attempt=1
until php artisan migrate --force; do
    if [ "$attempt" -ge 30 ]; then
        echo "Database migrations did not complete after 30 attempts." >&2
        exit 1
    fi
    attempt=$((attempt + 1))
    sleep 2
done

exec /usr/bin/supervisord -c /etc/supervisord.conf
