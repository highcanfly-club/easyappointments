#########################################################################
# © Ronan LE MEILLAT 2023
# released under the GPLv3 terms
#########################################################################
FROM php:8.2-apache as builder
LABEL org.opencontainers.image.authors="ronan@highcanfly.club"
ENV PORT 8888
ENV BASE_URL=http://localhost:8888
ENV LANGUAGE=english
ENV DEBUG=TRUE
ENV DB_HOST=mysql
ENV DB_NAME=hcfschedule
ENV DB_USERNAME=root
ENV DB_PASSWORD=hellodocker
ENV GOOGLE_SYNC_FEATURE=FALSE
ENV GOOGLE_PRODUCT_NAME=""
ENV GOOGLE_CLIENT_ID=""
ENV GOOGLE_CLIENT_SECRET=""
ENV GOOGLE_API_KEY=""
ENV TZ="UTC"
WORKDIR /var/www/html
COPY --from=composer/composer:latest-bin /composer /usr/bin/composer
COPY --from=node:lts-bullseye /usr/local/bin/node /usr/local/bin/node
COPY --from=node:lts-bullseye /usr/local/lib/node_modules/ /usr/local/lib/node_modules/
RUN cd /usr/local/bin/ && ln -svf /usr/local/bin/node nodejs \
    && ln -svf ../lib/node_modules/npm/bin/npm-cli.js npm \
    && ln -svf ../lib/node_modules/npm/bin/npx-cli.js npx
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY entrypoint-dev.sh /usr/local/bin/entrypoint-dev.sh
COPY docker/opcache.ini /usr/local/etc/php/conf.d/opcache.ini
RUN chmod ugo+x /usr/local/bin/entrypoint.sh
RUN chmod ugo+x /usr/local/bin/entrypoint-dev.sh
RUN apt update && apt install -y --no-install-recommends \
        unzip \
        default-mysql-client \
        libfreetype6-dev \
		libjpeg62-turbo-dev \
		libpng-dev 
RUN docker-php-ext-install -j$(nproc) mysqli 
RUN docker-php-ext-install -j$(nproc) opcache
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
	&& docker-php-ext-install -j$(nproc) gd
RUN sed -i "s/Listen 80/Listen ${PORT}/" /etc/apache2/ports.conf
COPY ./ /var/www/html/
# Name change
# take care: GPLv3 forbid to remove copyright headers in source code, an force to publish the modified code
# 
RUN find ./ -name '*.php'  -type f  -exec sed -i -e 's/Easy!Appointments/HCF!Schedule/g' -e 's/EASY!APPOINTMENTS/HCF!Schedule/g' -e 's/Alex Tselegidis Logo/HCF!Schedule Logo/g' -e 's/<a href="https:\/\/alextselegidis.com">Alex Tselegidis<\/a>/<a href="https:\/\/sctg.eu.org">SCTG<\/a>/g' -e 's/d-lg-flex justify-content-start flex-wrap alight-items-center mb-5/hidden d-lg-flex justify-content-start flex-wrap alight-items-center mb-5/g' -e 's/https:\/\/easyappointments\.org/https:\/\/github.com\/highcanfly-club\/hcfschedule/g'  {} \;
RUN find ./ -name '*.js'   -type f  -exec sed -i -e 's/Easy!Appointments/HCF!Schedule/g' -e 's/EASY!APPOINTMENTS/HCF!Schedule/g' {} \;
RUN npm i && composer install

FROM php:8.2-apache
LABEL org.opencontainers.image.authors="ronan@highcanfly.club"
ENV PORT 8888
ENV BASE_URL=http://localhost:8888
ENV LANGUAGE=english
ENV DEBUG=TRUE
ENV DB_HOST=mysql
ENV DB_NAME=hcfschedule
ENV DB_USERNAME=root
ENV DB_PASSWORD=hellodocker
ENV GOOGLE_SYNC_FEATURE=FALSE
ENV GOOGLE_PRODUCT_NAME=""
ENV GOOGLE_CLIENT_ID=""
ENV GOOGLE_CLIENT_SECRET=""
ENV GOOGLE_API_KEY=""
ENV TZ="UTC"
RUN apt update && apt install -y --no-install-recommends \
        default-mysql-client \
        libfreetype6 \
		libjpeg62-turbo \
		libpng16-16 
WORKDIR /var/www/html
COPY --from=builder /var/www/html/index.php /var/www/html/index.php
COPY --from=builder /var/www/html/application/ /var/www/html/application/
COPY --from=builder /var/www/html/assets/ /var/www/html/assets/
COPY --from=builder /var/www/html/storage/ /var/www/html/storage/
COPY --from=builder /var/www/html/system/ /var/www/html/system/
COPY --from=builder /var/www/html/vendor/ /var/www/html/vendor/
COPY --from=builder /usr/local/lib/php/ /usr/local/lib/php/
COPY --from=builder /usr/local/etc/php/ /usr/local/etc/php/
COPY --from=builder /usr/local/bin/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN sed -i "s/Listen 80/Listen ${PORT}/" /etc/apache2/ports.conf

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]
EXPOSE ${PORT}