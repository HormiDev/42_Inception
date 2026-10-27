#!/bin/sh
set -e

WP_PATH="/var/www/html"
DB_HOST="${WORDPRESS_DB_HOST:-mariadb}"
WORDPRESS_URL="${WORDPRESS_URL:-https://ide-dieg.42.fr}"

# Las variables no sensibles vienen de srcs/.env. Las contrasenas y credenciales
# privadas vienen de Docker secrets y se montan como archivos en /run/secrets.
if [ -n "$MYSQL_PASSWORD_FILE" ]; then
	MYSQL_PASSWORD="$(cat "$MYSQL_PASSWORD_FILE")"
fi

if [ -n "$WP_CREDENTIALS_FILE" ]; then
	while IFS='=' read -r key value || [ -n "$key" ]; do
		case "$key" in
			''|\#*) ;;
			WP_TITLE) WP_TITLE="$value" ;;
			WP_ADMIN_USER) WP_ADMIN_USER="$value" ;;
			WP_ADMIN_PASSWORD) WP_ADMIN_PASSWORD="$value" ;;
			WP_ADMIN_EMAIL) WP_ADMIN_EMAIL="$value" ;;
			WP_USER) WP_USER="$value" ;;
			WP_USER_PASSWORD) WP_USER_PASSWORD="$value" ;;
			WP_USER_EMAIL) WP_USER_EMAIL="$value" ;;
		esac
	done < "$WP_CREDENTIALS_FILE"
fi

: "${MYSQL_DATABASE:?MYSQL_DATABASE is required}"
: "${MYSQL_USER:?MYSQL_USER is required}"
: "${MYSQL_PASSWORD:?MYSQL_PASSWORD is required}"

export MYSQL_PASSWORD

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

# Si la base esta vacia, wp-cli crea las tablas y el usuario administrador.
if ! wp core is-installed --path="$WP_PATH" --allow-root >/dev/null 2>&1; then
	: "${WP_TITLE:?WP_TITLE is required in credentials secret}"
	: "${WP_ADMIN_USER:?WP_ADMIN_USER is required in credentials secret}"
	: "${WP_ADMIN_PASSWORD:?WP_ADMIN_PASSWORD is required in credentials secret}"
	: "${WP_ADMIN_EMAIL:?WP_ADMIN_EMAIL is required in credentials secret}"

	wp core install \
		--path="$WP_PATH" \
		--url="$WORDPRESS_URL" \
		--title="$WP_TITLE" \
		--admin_user="$WP_ADMIN_USER" \
		--admin_password="$WP_ADMIN_PASSWORD" \
		--admin_email="$WP_ADMIN_EMAIL" \
		--skip-email \
		--allow-root
fi

# Inception suele pedir un segundo usuario que no sea administrador.
if [ -n "$WP_USER" ] && ! wp user get "$WP_USER" --path="$WP_PATH" --allow-root >/dev/null 2>&1; then
	: "${WP_USER_PASSWORD:?WP_USER_PASSWORD is required in credentials secret}"
	: "${WP_USER_EMAIL:?WP_USER_EMAIL is required in credentials secret}"

	wp user create "$WP_USER" "$WP_USER_EMAIL" \
		--path="$WP_PATH" \
		--user_pass="$WP_USER_PASSWORD" \
		--role=author \
		--allow-root
fi

chown -R www-data:www-data "$WP_PATH"

exec "$@"
