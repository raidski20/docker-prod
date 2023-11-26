FROM node:21-alpine AS node
FROM php:8.1-fpm

ARG user
ARG uid

RUN useradd \
    -m \
    -G root \
    -u $uid \
    -d /home/$user \
    $user

RUN apt update && apt install -y \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libonig-dev \
    libzip-dev \
    zip \
    unzip \
    vim \
    git \
    nginx \
    supervisor

RUN apt-get clean && rm -rf /var/lib/apr/lists/*

COPY ../docker/default.conf /etc/nginx/conf.d/default.conf

# copy supervisord configuration
COPY ../docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# install nodejs
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=node /usr/local/bin/node /usr/local/bin/node
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm

# install extensions
RUN docker-php-ext-install pdo pdo_mysql mbstring exif pcntl bcmath zip gd

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Laravel config
ENV APP_ENV production
ENV APP_DEBUG false

# copy the application code
COPY ../source /var/www/html

# Set the working directory
WORKDIR /var/www/html

RUN chown -R www-data:www-data /var/www/html/storage
RUN chown -R www-data:www-data /var/www/html/bootstrap/cache

USER $user

EXPOSE 9000
EXPOSE 80

#CMD ["nginx", "-g", "daemon off;"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
