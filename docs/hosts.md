# /etc/hosts

[← README](../README.md)

## Qué problema resuelve

El proyecto usa este dominio:

```text
ide-dieg.42.fr
```

Nginx está configurado para responder a ese nombre en HTTPS. Pero tu ordenador
necesita saber a qué IP corresponde ese dominio.

En un dominio público normal, esa relación la resolvería DNS. En Inception no se
usa DNS público: se añade una entrada local en `/etc/hosts`.

## Qué hay que añadir

Abre `/etc/hosts` con permisos de administrador y añade esta línea:

```text
127.0.0.1 ide-dieg.42.fr
```

Por ejemplo:

```sh
sudo nano /etc/hosts
```

Al final del archivo debería quedar algo parecido a:

```text
127.0.0.1 localhost
127.0.0.1 ide-dieg.42.fr
```

## Qué significa

La línea:

```text
127.0.0.1 ide-dieg.42.fr
```

significa:

```text
cuando el navegador pida ide-dieg.42.fr, conéctate a esta misma máquina
```

`127.0.0.1` es la dirección local de tu ordenador. Como Docker publica Nginx en el
puerto `443` del host, el navegador llega al contenedor Nginx usando:

```text
https://ide-dieg.42.fr
```

## No es una redirección HTTP

`/etc/hosts` no redirige páginas. Solo traduce un nombre a una IP.

La redirección HTTP real ocurre dentro de Nginx. En este proyecto se usa para el
caso en que alguien escriba por error:

```text
http://ide-dieg.42.fr:443
```

Ese puerto espera HTTPS, no HTTP simple. La configuración de Nginx lo corrige con:

```nginx
error_page 497 https://$host$request_uri;
```

Así Nginx devuelve una redirección hacia:

```text
https://ide-dieg.42.fr
```

## Cómo comprobarlo

Comprobar que el nombre apunta a tu máquina:

```sh
getent hosts ide-dieg.42.fr
```

Deberías ver algo parecido a:

```text
127.0.0.1 ide-dieg.42.fr
```

Comprobar HTTPS con el certificado autofirmado:

```sh
curl -k -I https://ide-dieg.42.fr
```

Si WordPress todavía no está instalado, lo normal es ver una respuesta `302` hacia:

```text
https://ide-dieg.42.fr/wp-admin/install.php
```

## Errores comunes

Si el navegador no encuentra `ide-dieg.42.fr`, falta la entrada en `/etc/hosts` o
la línea está mal escrita.

Si aparece `400 Bad Request` con un mensaje sobre HTTP enviado al puerto HTTPS,
se está usando `http://` en vez de `https://`.

Si aparece una advertencia de seguridad del navegador, es normal: el certificado
del proyecto es autofirmado.
