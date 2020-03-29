FROM alpine:3.11.5

RUN apk update && apk upgrade \
&& apk add php7 php7-fpm --no-cache \
&& sed -i 's/^listen = .*/listen = 0.0.0.0:9000/' /etc/php7/php-fpm.d/www.conf 

EXPOSE 9000

CMD ["/usr/sbin/php-fpm7", "-F"]