FROM php:7.2-apache

RUN apt-get update

# 1. development packages
RUN apt-get install -y \
    git \
    zip \
    curl \
    sudo \
    unzip \
    libicu-dev \
    libbz2-dev \
    libpng-dev \
    libjpeg-dev \
    libmcrypt-dev \
    libreadline-dev \
    libfreetype6-dev \
    g++

# 2. apache configs + document root
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# 3. mod_rewrite for URL rewrite and mod_headers for .htaccess extra headers like Access-Control-Allow-Origin-
RUN a2enmod rewrite headers

# 4. start with base php config, then add extensions
RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

RUN docker-php-ext-install \
    bz2 \
    intl \
    iconv \
    bcmath \
    opcache \
    calendar \
    mbstring \
    pdo_mysql \
    zip

# 5. install modsecurity 2
# RUN apt-get install -y libapache2-mod-security2
# RUN cp /etc/modsecurity/modsecurity.conf-recommended /etc/modsecurity/modsecurity.conf
# RUN sed -i '/SecRuleEngine/s/DetectionOnly/On/g' /etc/modsecurity/modsecurity.conf
# RUN git clone https://github.com/SpiderLabs/owasp-modsecurity-crs.git
# RUN cd owasp-modsecurity-crs && mv crs-setup.conf.example /etc/modsecurity/crs-setup.conf && mv rules/ /etc/modsecurity
# RUN sed -i '/IncludeOptional \/etc\/modsecurity\/\*\.conf/a     Include \/etc\/modsecurity\/rules\/\*\.conf' /etc/apache2/mods-enabled/security2.conf
# Nesse ponto estou tendo um erro de regra duplicada

# 6. composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 7. we need a user with the same UID/GID with host user
# so when we execute CLI commands, all the host file's ownership remains intact
# otherwise command from inside container will create root-owned files and directories
ARG uid
RUN useradd -G www-data,root -u $uid -d /home/devuser devuser
RUN mkdir -p /home/devuser/.composer && \
    chown -R devuser:devuser /home/devuser