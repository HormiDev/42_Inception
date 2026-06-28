# Documentación para desarrolladores

[← README](README.md)

Este documento resume el flujo de trabajo técnico del proyecto. La documentación
detallada vive en `docs/`.

## Arquitectura esperada

```mermaid
flowchart LR
    Nginx["Nginx<br/>HTTPS :443"] --> WP["WordPress / PHP-FPM<br/>:9000"]
    WP --> DB["MariaDB<br/>:3306"]
    DB --> Volume["Volumen persistente"]

    classDef web fill:#dcfce7,stroke:#16a34a,color:#14532d
    classDef app fill:#fef3c7,stroke:#d97706,color:#78350f
    classDef data fill:#fce7f3,stroke:#db2777,color:#831843
    classDef volume fill:#ede9fe,stroke:#7c3aed,color:#4c1d95
    class Nginx web
    class WP app
    class DB data
    class Volume volume
```

## Puntos que debe cubrir el entorno

- Configurar requisitos previos, archivos de configuración y secretos.
- Construir y ejecutar el proyecto con `make` y Docker Compose.
- Gestionar contenedores, imágenes, redes y volúmenes.
- Identificar dónde persisten los datos, especialmente MariaDB.

## Inicialización de datos

`srcs/.env` define `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD` y
`MYSQL_ROOT_PASSWORD`.

En el primer arranque, el entrypoint de MariaDB inicializa `/var/lib/mysql`, crea
la base de WordPress y da permisos al usuario de WordPress. El entrypoint de
WordPress copia los archivos al volumen, genera `wp-config.php` y espera a que
MariaDB acepte conexiones antes de ejecutar PHP-FPM.

## Documentación relacionada

- [Docker](docs/docker.md)
- [Docker Compose](docs/docker-compose.md)
- [Volúmenes Docker](docs/docker-volumenes.md)
- [Redes Docker](docs/docker-redes.md)
- [Nginx](docs/nginx.md)
- [MariaDB](docs/mariadb.md)
