#!/bin/sh
set -e

DATADIR="/var/lib/mysql"
SOCKET="/run/mysqld/mysqld.sock"
INIT_MARKER="$DATADIR/.inception_initialized"

# Las variables no sensibles vienen de srcs/.env. Las contrasenas vienen de
# Docker secrets y se montan como archivos en /run/secrets.
if [ -n "$MYSQL_PASSWORD_FILE" ]; then
	MYSQL_PASSWORD="$(cat "$MYSQL_PASSWORD_FILE")"
fi

if [ -n "$MYSQL_ROOT_PASSWORD_FILE" ]; then
	MYSQL_ROOT_PASSWORD="$(cat "$MYSQL_ROOT_PASSWORD_FILE")"
fi

: "${MYSQL_DATABASE:?MYSQL_DATABASE is required}"
: "${MYSQL_USER:?MYSQL_USER is required}"
: "${MYSQL_PASSWORD:?MYSQL_PASSWORD is required}"
: "${MYSQL_ROOT_PASSWORD:?MYSQL_ROOT_PASSWORD is required}"

sql_escape() {
	printf "%s" "$1" | sed "s/\\\\/\\\\\\\\/g; s/'/''/g"
}

mkdir -p /run/mysqld "$DATADIR"
chown -R mysql:mysql /run/mysqld "$DATADIR"

if [ ! -d "$DATADIR/mysql" ]; then
	mariadb-install-db --user=mysql --datadir="$DATADIR" >/dev/null
fi

if [ ! -f "$INIT_MARKER" ]; then
	mariadbd --user=mysql --datadir="$DATADIR" --skip-networking --socket="$SOCKET" &
	pid="$!"

	until mariadb-admin --socket="$SOCKET" ping --silent; do
		sleep 1
	done

	MYSQL_PASSWORD_SQL="$(sql_escape "$MYSQL_PASSWORD")"
	MYSQL_ROOT_PASSWORD_SQL="$(sql_escape "$MYSQL_ROOT_PASSWORD")"

	mariadb --socket="$SOCKET" -uroot <<-EOSQL
		DELETE FROM mysql.user WHERE User='';
		DROP DATABASE IF EXISTS test;
		DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
		ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD_SQL}';
		CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
		CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD_SQL}';
		GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
		FLUSH PRIVILEGES;
	EOSQL

	touch "$INIT_MARKER"
	chown mysql:mysql "$INIT_MARKER"

	mariadb-admin --socket="$SOCKET" -uroot -p"$MYSQL_ROOT_PASSWORD" shutdown
	wait "$pid"
fi

exec "$@"
