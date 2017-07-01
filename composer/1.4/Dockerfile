FROM composer:1.4

RUN echo http://dl-2.alpinelinux.org/alpine/edge/community/ >> /etc/apk/repositories
RUN apk --no-cache add shadow

ENV COMPOSER composer.json
ENV COMPOSER_HOME /usr/local/composer
ENV SYMFONY_ENV="prod"
ENV SYMFONY_DEBUG=0
ENV GOSU_VERSION 1.10
RUN set -x \
	&& apk add --no-cache gnupg ca-certificates wget \
	&& update-ca-certificates \
	&& gpg-agent --daemon \
	&& wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64" \
	&& wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64.asc" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
	&& gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
	&& rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
	&& chmod +x /usr/local/bin/gosu \
	&& /usr/local/bin/gosu nobody true

COPY conf/docker-entrypoint-wrapper.sh /docker-entrypoint-wrapper.sh
ENTRYPOINT ["/docker-entrypoint-wrapper.sh"]

RUN mkdir -p /usr/local/composer && chown www-data:www-data /usr/local/composer
VOLUME ["/usr/local/composer/cache", "/usr/local/composer/auth"]
WORKDIR "/var/www/html/application"
