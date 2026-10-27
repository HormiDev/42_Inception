# Secrets

[← README](../README.md)

## Qué son

Los `secrets` son archivos que guardan datos sensibles, como contraseñas.

En este proyecto viven en:

```text
secrets/
```

La idea es separar dos tipos de información:

- Configuración no sensible: nombres de base de datos, usuarios o dominios.
- Información sensible: contraseñas y credenciales privadas.

La configuración no sensible puede estar en `srcs/.env`. Las contraseñas deben
estar en `secrets/`.

## Archivos del proyecto

Este proyecto usa estos archivos:

```text
secrets/db_password.txt
secrets/db_root_password.txt
secrets/credentials.txt
```

Uso recomendado:

- `db_password.txt`: contraseña del usuario normal de MariaDB que usa WordPress.
- `db_root_password.txt`: contraseña del usuario `root` de MariaDB.
- `credentials.txt`: credenciales que usa `wp-cli` para instalar WordPress y
  crear sus usuarios por defecto.

## Formato

Cada archivo debe contener solo el valor de la credencial.

Ejemplo para `secrets/db_password.txt`:

```text
wordpress_user_password
```

Ejemplo para `secrets/db_root_password.txt`:

```text
mariadb_root_password
```

`secrets/credentials.txt` usa formato `KEY=VALUE`, porque guarda varias
credenciales de WordPress en un solo archivo:

```env
WP_TITLE=Inception
WP_ADMIN_USER=ide_dieg
WP_ADMIN_PASSWORD=change_me_wp_owner_password
WP_ADMIN_EMAIL=ide-dieg@student.42madrid.com
WP_USER=wp_user
WP_USER_PASSWORD=change_me_wp_user_password
WP_USER_EMAIL=wp_user@example.com
```

`WP_ADMIN_USER` no debería llamarse `admin` ni contener `admin`. `WP_USER` es el
segundo usuario de WordPress y se crea con rol `author`.

Para `db_password.txt` y `db_root_password.txt`, evita este formato:

```text
MYSQL_PASSWORD=wordpress_user_password
```

Ese formato es válido para `.env`, pero no es ideal para un archivo secret. En un
secret lo más simple es guardar solo el valor.

## Por qué no meterlos en el Dockerfile

No conviene pasar contraseñas al compilar la imagen.

Si escribes una contraseña en un `Dockerfile`, o la usas en un `RUN`, puede quedar
guardada en las capas de la imagen. Eso significa que alguien con acceso a la
imagen podría recuperarla.

Lo correcto es:

1. Construir la imagen sin contraseñas.
2. Montar los secrets al arrancar el contenedor.
3. Leerlos desde el entrypoint.

En Docker Compose, los secrets aparecen dentro del contenedor en:

```text
/run/secrets/
```

## Ejemplo en Docker Compose

Un ejemplo para MariaDB:

```yaml
services:
  mariadb:
    environment:
      MYSQL_DATABASE: ${MYSQL_DATABASE}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD_FILE: /run/secrets/db_password
      MYSQL_ROOT_PASSWORD_FILE: /run/secrets/db_root_password
    secrets:
      - db_password
      - db_root_password

secrets:
  db_password:
    file: ../secrets/db_password.txt
  db_root_password:
    file: ../secrets/db_root_password.txt
```

Un ejemplo para WordPress:

```yaml
services:
  wordpress:
    environment:
      WORDPRESS_DB_HOST: mariadb
      WORDPRESS_URL: ${WORDPRESS_URL}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD_FILE: /run/secrets/db_password
      WP_CREDENTIALS_FILE: /run/secrets/credentials
    secrets:
      - db_password
      - credentials
```

## Ejemplo en un entrypoint

El contenedor puede leer la contraseña así:

```sh
if [ -n "$MYSQL_PASSWORD_FILE" ]; then
	MYSQL_PASSWORD="$(cat "$MYSQL_PASSWORD_FILE")"
fi

if [ -n "$MYSQL_ROOT_PASSWORD_FILE" ]; then
	MYSQL_ROOT_PASSWORD="$(cat "$MYSQL_ROOT_PASSWORD_FILE")"
fi
```

Después el script puede seguir usando `MYSQL_PASSWORD` y
`MYSQL_ROOT_PASSWORD` como variables normales.

El entrypoint de WordPress lee `credentials.txt` como pares `KEY=VALUE`. Con
esos datos ejecuta `wp core install` y `wp user create` si WordPress todavía no
está instalado.

## Relación con srcs/.env

`srcs/.env` debería guardar valores que no son secretos:

```env
MYSQL_DATABASE=wordpress
MYSQL_USER=wp_user
WORDPRESS_URL=https://ide-dieg.42.fr
```

Los valores secretos deberían salir de:

```text
secrets/db_password.txt
secrets/db_root_password.txt
secrets/credentials.txt
```

Así queda más claro qué se puede versionar y qué no.

## Seguridad en Git

La carpeta `secrets/` no debería subirse al repositorio con valores reales.

En este proyecto, `.gitignore` ignora `secrets`, así que las contraseñas locales
no deberían terminar en Git.

Si quieres documentar qué archivos hacen falta, puedes usar nombres descriptivos
en la documentación, pero no hace falta subir los valores reales.

## Errores comunes

Si el contenedor dice que falta `MYSQL_PASSWORD`, puede que:

- El secret no esté declarado en `docker-compose.yml`.
- La ruta `MYSQL_PASSWORD_FILE` no apunte a `/run/secrets/db_password`.
- El archivo `secrets/db_password.txt` esté vacío.

Si MariaDB no acepta la contraseña, puede que el volumen `mariadb_data` ya se
inicializara con una contraseña anterior. En ese caso, cambiar el secret no cambia
automáticamente la contraseña guardada dentro de la base ya creada.

Si el archivo secret tiene espacios, comillas o `MYSQL_PASSWORD=...`, el valor
real puede no coincidir con lo que espera MariaDB.

Si WordPress sigue mandando a `/wp-admin/install.php`, puede que la base ya se
hubiera inicializado antes de añadir `wp-cli` o que `credentials.txt` esté vacío.
