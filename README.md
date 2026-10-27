# 42_Inception

Proyecto Inception de 42.

## Vista rápida

```mermaid
flowchart LR
    Internet(("🌐<br/>WWW"))

    subgraph Host["Host"]
        direction TB

        subgraph Network["Docker network"]
            direction LR
            Nginx["Nginx<br/>container"]
            WordPress["WordPress<br/>container"]
            MariaDB["MariaDB<br/>container"]
        end

        subgraph Volumes["Volúmenes"]
            direction LR
            WPVolume[("wordpress<br/>volume")]
            DBVolume[("mariadb<br/>volume")]
        end
    end

    Internet -. "HTTPS :443" .-> Nginx
    Nginx -->|":9000"| WordPress
    WordPress -->|":3306"| MariaDB
    WPVolume -.-> WordPress
    WPVolume -.-> Nginx
    DBVolume -.-> MariaDB

    classDef internet fill:#172554,stroke:#60a5fa,color:#eff6ff
    classDef nginx fill:#064e3b,stroke:#34d399,color:#ecfdf5
    classDef wordpress fill:#78350f,stroke:#fbbf24,color:#fffbeb
    classDef mariadb fill:#831843,stroke:#f472b6,color:#fdf2f8
    classDef volume fill:#4c1d95,stroke:#a78bfa,color:#faf5ff

    class Internet internet
    class Nginx nginx
    class WordPress wordpress
    class MariaDB mariadb
    class WPVolume,DBVolume volume
    style Host fill:#1f2937,stroke:#9ca3af,color:#f9fafb,stroke-width:2px
    style Network fill:#0f172a,stroke:#38bdf8,color:#e0f2fe,stroke-width:2px
    style Volumes fill:#2e1065,stroke:#c4b5fd,color:#faf5ff,stroke-width:2px
```

## Documentación

Documentación técnica del proyecto:

- [Nginx](docs/nginx.md): qué es, cómo funciona como servidor HTTPS y cómo se conecta con WordPress/PHP-FPM.
- [WordPress](docs/wordpress.md): qué es, cómo genera la web dinámica y cómo usa PHP-FPM, MariaDB y el volumen compartido.
- [PHP](docs/php.md): qué es PHP, qué es PHP-FPM y por qué el contenedor WordPress usa `php83-fpm`.
- [OpenSSL](docs/openssl.md): cómo se genera el certificado autofirmado usado por Nginx.
- [/etc/hosts](docs/hosts.md): qué línea añadir para que `ide-dieg.42.fr` apunte al Nginx local.
- [Alpine Linux](docs/alpine.md): por qué se usa como base de los contenedores y cómo funciona `apk`.
- [MariaDB](docs/mariadb.md): qué es, cómo guarda los datos de WordPress y cómo se inicializa la base del sitio.
- [Secrets](docs/secrets.md): cómo guardar contraseñas fuera de las imágenes y cargarlas en los contenedores.
- [Docker](docs/docker.md): guía general sobre instalación, uso básico y conceptos como contenedores, imágenes, Compose, volúmenes y redes.
- [Documentación para desarrolladores](DEV_DOC.md): vista técnica del flujo de trabajo y enlaces útiles.
- [Documentación de usuario](USER_DOC.md): explicación simple de la pila desde el punto de vista de uso.

Los diagramas están escritos con Mermaid. Si tu visor Markdown no los renderiza,
instala soporte Mermaid o usa una versión reciente de VS Code.

## Uso rápido

Construir y ejecutar el contenedor Nginx principal:

```sh
make
```

Probar el módulo de Nginx de forma aislada:

```sh
cd srcs/requirements/nginx
make
```

El Makefile principal publica HTTPS en `443`. El Makefile del módulo Nginx
publica HTTPS en `8088`.
