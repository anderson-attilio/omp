FROM php:7.3-apache

# install the PHP extensions we need
RUN set -ex; \
        \
        savedAptMark="$(apt-mark showmanual)"; \
        \
        apt-get update; \
        apt-get install -y --no-install-recommends \
                libjpeg-dev \
                libmcrypt-dev \
                libxml2-dev \
                libxslt-dev \
                libpng-dev \
                libzip-dev \
                sudo \
                gnupg2 \
        ; \
        curl -sL https://deb.nodesource.com/setup_11.x | sudo bash -; \
        sudo apt-get install -y nodejs npm; \
        \
        docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr; \
        docker-php-ext-install gd mysqli opcache zip soap xsl

# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
#       apt-mark auto '.*' > /dev/null; \
#       apt-mark manual $savedAptMark; \
#       ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
#               | awk '/=>/ { print $3 }' \
#               | sort -u \
#               | xargs -r dpkg-query -S \
#               | cut -d: -f1 \
#               | sort -u \
#               | xargs -rt apt-mark manual; \
#       \
#       apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
#       rm -rf /var/lib/apt/lists/*

#RUN curl -sL https://deb.nodesource.com/setup_11.x | bash -
#    apt-get install -y nodejs

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
                echo 'opcache.memory_consumption=128'; \
                echo 'opcache.interned_strings_buffer=8'; \
                echo 'opcache.max_accelerated_files=4000'; \
                echo 'opcache.revalidate_freq=2'; \
                echo 'opcache.fast_shutdown=1'; \
                echo 'opcache.enable_cli=1'; \
        } > /usr/local/etc/php/conf.d/opcache-recommended.ini

RUN a2enmod rewrite expires

VOLUME /var/www/html

ENV OMP_VERSION 3.1.2
ENV OMP_SHA1 34d0d7abad85da5813bc49003ca86302be080677

RUN set -ex; \
        curl -o omp-${OMP_VERSION}.tar.gz -fSL "http://pkp.sfu.ca/omp/download/omp-${OMP_VERSION}.tar.gz"; \
        echo "$OMP_SHA1 *omp-${OMP_VERSION}.tar.gz" | sha1sum -c -; \
# upstream tarballs include ./omp/ so this gives us /var/www/omp-${OMP_VERSION}
        tar -xzf omp-${OMP_VERSION}.tar.gz -C /var/www/; \
        rm omp-${OMP_VERSION}.tar.gz; \
        mv /var/www/omp-${OMP_VERSION} /var/www/omp; \
        chown -R www-data:www-data /var/www/omp

COPY docker-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
