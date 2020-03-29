FROM alpine:3.11.5

RUN apk update && apk upgrade && apk add nginx --no-cache \
&& mkdir -p /run/nginx

COPY default.conf /etc/nginx/conf.d/default.conf

WORKDIR /usr/share/nginx/html

COPY index.html /usr/share/nginx/html

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]