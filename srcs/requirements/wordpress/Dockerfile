FROM alpine:3.20

RUN apk add --no-cache ca-certificates curl tar php83 php83-fpm php83-mysqli \
	&& (addgroup -S www-data 2>/dev/null || true) \
	&& (adduser -S -G www-data www-data 2>/dev/null || true) \
	&& mkdir -p /var/www/html /usr/src \
	&& curl -fsSL https://wordpress.org/latest.tar.gz -o /tmp/wordpress.tar.gz \
	&& tar -xzf /tmp/wordpress.tar.gz -C /usr/src \
	&& rm -f /tmp/wordpress.tar.gz \
	&& chown -R www-data:www-data /var/www/html /usr/src/wordpress

WORKDIR /var/www/html

COPY conf/php-fpm.conf /etc/php83/php-fpm.d/www.conf
COPY tools/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 9000

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["php-fpm83", "-F"]
