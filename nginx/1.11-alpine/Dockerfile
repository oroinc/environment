FROM nginx:1.11-alpine

COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY conf/symfony2.conf /etc/nginx/conf.d/default.conf
COPY conf/websocket.conf /etc/nginx/conf.d/websocket.conf
COPY conf/entrypoint.sh /entrypoint.sh

ENV SYMFONY_ENV="prod"
ENV SYMFONY_DEBUG=0

RUN echo http://dl-2.alpinelinux.org/alpine/edge/community/ >> /etc/apk/repositories
RUN apk --no-cache add shadow
RUN useradd www-data

ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
