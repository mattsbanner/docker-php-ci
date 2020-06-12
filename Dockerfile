FROM ubuntu:18.04

LABEL maintainer = "Matt Banner <matt@banner.wtf>"

ENV DEBIAN_FRONTEND noninteractive
ENV COMPOSER_ALLOW_SUPERUSER 1

# Versions

ENV COMPOSER_VERSION 1.9.1
ENV NODE_VERSION 10.x
ENV PHP_VERSION 7.4

# Base setup and install dependencies

RUN apt-get update \
    && apt-get install -y locales \
    && locale-gen en_US.UTF-8

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN apt-get update \
    && apt-get update >/dev/null \
    && apt-get install -y nginx git zip unzip curl build-essential python make g++ libfontconfig \
    software-properties-common rsync acl zlib1g-dev apt-utils sqlite3 libsqlite3-dev supervisor

# Install NodeJS

RUN curl -sL https://deb.nodesource.com/setup_$NODE_VERSION -o nodesource_setup.sh \
    && bash ./nodesource_setup.sh \
    && apt-get update \
    && apt-get install -y nodejs

CMD [ "node" ]

# Install PHP, Composer, PHP extensions and configure Nginx

RUN add-apt-repository -y universe \
    && add-apt-repository -y ppa:ondrej/php \
    && apt-get update \
    && apt-get install -y \
        php$PHP_VERSION-fpm \
        php-pear \
        libmagickwand-dev \
        imagemagick \
        php-dev \
        php-xml \
        php$PHP_VERSION-intl \
        php$PHP_VERSION-xdebug \
        php$PHP_VERSION-curl \
        php$PHP_VERSION-dev \
        php$PHP_VERSION-mbstring \
        php$PHP_VERSION-zip \
        php$PHP_VERSION-mysql \
        php$PHP_VERSION-xml \
        php$PHP_VERSION-gd \
        php$PHP_VERSION-sqlite3 \
        php$PHP_VERSION-bcmath \
        php$PHP_VERSION-soap \
        php-mongodb \
        gcc \
        make \
        autoconf \
        libc-dev \
        pkg-config \
        libmcrypt-dev \
    && pecl install imagick mcrypt-1.0.1 \
    && php -r "readfile('https://getcomposer.org/installer');" | php -- --install-dir=/usr/bin/ --filename=composer --version=${COMPOSER_VERSION} \
    && mkdir /run/php \
    && echo "daemon off;" >> /etc/nginx/nginx.conf \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

# Copy config files into position

COPY nginx-default /etc/nginx/sites-available/default
COPY php-fpm.conf /etc/php/$PHP_VERSION/fpm/php-fpm.conf
COPY php.ini /etc/php/$PHP_VERSION/fpm/conf.d/99-php.ini
COPY xdebug.ini /etc/php/$PHP_VERSION/mods-available/xdebug.ini
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Update config files with the PHP version

RUN sed -i s/%%PHP_VERSION%%/$PHP_VERSION/g /etc/php/$PHP_VERSION/fpm/php-fpm.conf
RUN sed -i s/%%PHP_VERSION%%/$PHP_VERSION/g /etc/supervisor/conf.d/supervisord.conf
RUN sed -i s/%%PHP_VERSION%%/$PHP_VERSION/g /etc/nginx/sites-available/default

# Install Deployer

RUN curl -LO https://deployer.org/deployer.phar \
    && mv deployer.phar /usr/local/bin/dep \
    && chmod +x /usr/local/bin/dep

# Set command-line version of PHP to preferred version

RUN update-alternatives --set php /usr/bin/php$PHP_VERSION

# Install Prestissimo to speed up composer package installation

RUN composer global require hirak/prestissimo

# Update NPM to the latest version

RUN npm i -g npm@latest

# Cleanup
RUN apt-get remove -y --purge software-properties-common \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/apt/*

COPY start.sh /start.sh
RUN chmod +x /start.sh

CMD ["/start.sh"]
