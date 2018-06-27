FROM ubuntu:16.04

MAINTAINER Enovate Design Ltd (Michael Walsh)

ENV DEBIAN_FRONTEND noninteractive
ENV COMPOSER_ALLOW_SUPERUSER 1

# Versions

ENV COMPOSER_VERSION 1.6.5
ENV NODE_VERSION 9.x
ENV PHP_VERSION 7.1

# Base setup and install dependencies

RUN apt-get update \
    && apt-get install -y locales \
    && locale-gen en_US.UTF-8

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN apt-get update \
    && apt-get update >/dev/null \
    && apt-get install -y nginx git zip unzip curl build-essential python make g++ libfontconfig software-properties-common rsync acl zlib1g-dev apt-utils

# Install NodeJS

RUN curl -sL https://deb.nodesource.com/setup_$NODE_VERSION -o nodesource_setup.sh \
    && bash ./nodesource_setup.sh \
    && apt-get update \
    && apt-get install -y nodejs

CMD [ "node" ]

# Install PHP, Composer, PHP extensions and configure Nginx

RUN add-apt-repository -y ppa:ondrej/php \
    && apt-get update \
    && apt-get install -y \
        php$PHP_VERSION-fpm \
        php-pear \
        php-intl \
        libmagickwand-dev \
        imagemagick \
        php-dev \
        php-xml \
        php$PHP_VERSION-curl \
        php$PHP_VERSION-dev \
        php$PHP_VERSION-mbstring \
        php$PHP_VERSION-zip \
        php$PHP_VERSION-mysql \
        php$PHP_VERSION-xml \
        php$PHP_VERSION-gd \
    && pecl install imagick \
    && php -r "readfile('https://getcomposer.org/installer');" | php -- --install-dir=/usr/bin/ --filename=composer --version=${COMPOSER_VERSION} \
    && mkdir /run/php \
    && apt-get remove -y --purge software-properties-common \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && echo "daemon off;" >> /etc/nginx/nginx.conf \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

# Copy config files into position

COPY nginx-default /etc/nginx/sites-available/default
COPY php-fpm.conf /etc/php/$PHP_VERSION/fpm/php-fpm.conf
COPY php.ini /etc/php/$PHP_VERSION/fpm/conf.d/99-php.ini

# Install Deployer

RUN curl -LO https://deployer.org/deployer.phar \
    && mv deployer.phar /usr/local/bin/dep \
    && chmod +x /usr/local/bin/dep

# Install PHPUnit

RUN curl -LO https://phar.phpunit.de/phpunit-7.phar \
    && mv phpunit-7.phar /usr/local/bin/phpunit \
    && chmod +x /usr/local/bin/phpunit

# Install Codeception

RUN curl -LO https://codeception.com/codecept.phar \
    && mv codecept.phar /usr/local/bin/codecept \
    && chmod +x /usr/local/bin/codecept

# Install AWS SDK PHP globally via Composer

RUN composer global require aws/aws-sdk-php

# Install Iconv polyfill globally

RUN composer global require symfony/polyfill-iconv

# Install Gulp.js globally

RUN npm i -g gulp

# Set command-line version of PHP to preferred version
RUN update-alternatives --set php /usr/bin/php$PHP_VERSION
