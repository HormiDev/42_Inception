# Imagen base mínima
FROM alpine:3.20

# Instalar nginx y openssl
RUN apk update && apk add nginx openssl

# Crear directorios necesarios
RUN mkdir -p /run/nginx /etc/nginx/ssl

# Generar certificado autofirmado para SSL
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
	-keyout /etc/nginx/ssl/inception.key \
	-out /etc/nginx/ssl/inception.crt \
	-subj "/C=ES/ST=Madrid/L=Madrid/O=42/CN=ide-dieg.42.fr"

# Copiar configuración
COPY conf/nginx.conf /etc/nginx/http.d/default.conf

# Copiar archivos web
COPY tools/ /usr/share/nginx/html/

# Exponer puerto
EXPOSE 443

# Ejecutar nginx en primer plano
CMD ["nginx", "-g", "daemon off;"]