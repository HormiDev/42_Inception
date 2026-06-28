#!/bin/sh
set -e

WP_PATH="/var/www/html"
DB_HOST="${WORDPRESS_DB_HOST:-mariadb}"

# Estas variables vienen de srcs/.env a traves de docker-compose.yml.
: "${MYSQL_DATABASE:?MYSQL_DATABASE is required}"
: "${MYSQL_USER:?MYSQL_USER is required}"
: "${MYSQL_PASSWORD:?MYSQL_PASSWORD is required}"

php_escape() {
	printf "%s" "$1" | sed "s/\\\\/\\\\\\\\/g; s/'/\\\\'/g"
}

wp_secret() {
	head -c 48 /dev/urandom | base64
}

# El volumen puede estar vacio en el primer arranque. En ese caso copiamos
# WordPress desde la copia limpia guardada en la imagen.
if [ ! -f "$WP_PATH/wp-settings.php" ]; then
	cp -a /usr/src/wordpress/. "$WP_PATH/"
fi

# WordPress necesita este archivo para saber como conectarse a MariaDB.
if [ ! -f "$WP_PATH/wp-config.php" ]; then
	DB_NAME="$(php_escape "$MYSQL_DATABASE")"
	DB_USER="$(php_escape "$MYSQL_USER")"
	DB_PASSWORD="$(php_escape "$MYSQL_PASSWORD")"
	DB_HOST_ESCAPED="$(php_escape "$DB_HOST")"

	cat > "$WP_PATH/wp-config.php" <<-EOF
	<?php
	define( 'DB_NAME', '$DB_NAME' );
	define( 'DB_USER', '$DB_USER' );
	define( 'DB_PASSWORD', '$DB_PASSWORD' );
	define( 'DB_HOST', '$DB_HOST_ESCAPED' );
	define( 'DB_CHARSET', 'utf8' );
	define( 'DB_COLLATE', '' );

	define( 'AUTH_KEY',         '$(php_escape "$(wp_secret)")' );
	define( 'SECURE_AUTH_KEY',  '$(php_escape "$(wp_secret)")' );
	define( 'LOGGED_IN_KEY',    '$(php_escape "$(wp_secret)")' );
	define( 'NONCE_KEY',        '$(php_escape "$(wp_secret)")' );
	define( 'AUTH_SALT',        '$(php_escape "$(wp_secret)")' );
	define( 'SECURE_AUTH_SALT', '$(php_escape "$(wp_secret)")' );
	define( 'LOGGED_IN_SALT',   '$(php_escape "$(wp_secret)")' );
	define( 'NONCE_SALT',       '$(php_escape "$(wp_secret)")' );

	\$table_prefix = 'wp_';

	define( 'WP_DEBUG', false );

	if ( ! defined( 'ABSPATH' ) ) {
		define( 'ABSPATH', __DIR__ . '/' );
	}

	require_once ABSPATH . 'wp-settings.php';
	EOF
fi

chown -R www-data:www-data "$WP_PATH"

# depends_on solo ordena el arranque; este bucle espera a que MariaDB responda.
until php83 -r '
mysqli_report(MYSQLI_REPORT_OFF);
$connection = @new mysqli(getenv("WORDPRESS_DB_HOST") ?: "mariadb", getenv("MYSQL_USER"), getenv("MYSQL_PASSWORD"), getenv("MYSQL_DATABASE"));
if ($connection->connect_errno) {
	exit(1);
}
$connection->close();
'; do
	sleep 2
done

exec "$@"
