FROM ubuntu:xenial

ARG PHP_VERSION="7.1"
ARG BLACKFIRE_VERSION="1.10.0"

RUN export DEBIAN_FRONTEND=noninteractive \
&& export LC_ALL='en_US.UTF-8' \
&& export LANG='en_US.UTF-8' \
&& export LANGUAGE='en_US.UTF-8' \
&& apt-get -qq update \
&& apt-get -qqy install --no-install-recommends \
  software-properties-common \
  python-software-properties \
  curl \
  wget \
  gettext \
  git \
  nodejs \
  nodejs-legacy \
  npm \
  bzip2 \
  locales \
&& localedef -c -f UTF-8 -i en_US en_US.UTF-8 \
&& locale-gen en en_US en_US.UTF-8 && dpkg-reconfigure locales \
&& wget -O - https://packagecloud.io/gpg.key | apt-key add - \
&& echo "deb http://packages.blackfire.io/debian any main" > /etc/apt/sources.list.d/blackfire.list \
&& add-apt-repository -y ppa:ondrej/php && apt-get -qq update \
&& apt-get -qqy install --no-install-recommends \
  php${PHP_VERSION}-fpm \
  php${PHP_VERSION}-cli \
  php${PHP_VERSION}-common \
  php${PHP_VERSION}-mysql \
  php${PHP_VERSION}-pgsql \
  php${PHP_VERSION}-curl \
  php${PHP_VERSION}-gd \
  php${PHP_VERSION}-mcrypt \
  php${PHP_VERSION}-xmlrpc \
  php${PHP_VERSION}-ldap \
  php${PHP_VERSION}-xsl \
  php${PHP_VERSION}-intl \
  php${PHP_VERSION}-soap \
  php${PHP_VERSION}-mbstring \
  php${PHP_VERSION}-zip \
  php${PHP_VERSION}-bz2 \
  php${PHP_VERSION}-tidy \
  php${PHP_VERSION}-bcmath \
  php${PHP_VERSION}-xdebug \
  blackfire-php \
&& wget -O /usr/local/bin/blackfire https://packages.blackfire.io/binaries/blackfire-agent/${BLACKFIRE_VERSION}/blackfire-cli-linux_static_amd64 \ 
&& chmod +x /usr/local/bin/blackfire \
&& apt-get -qy autoremove --purge software-properties-common python-software-properties \  
&& apt-get autoclean

RUN ln -sf /usr/sbin/php-fpm${PHP_VERSION} /usr/local/bin/php-fpm
RUN ln -sf /etc/php/${PHP_VERSION} /etc/php/current

ENV SYMFONY_ENV="prod"
ENV SYMFONY_DEBUG=0
ENV OPCACHE_ENABLED="1"
ENV XDEBUG_ENABLED="0"
ENV NPM_CONFIG_PREFIX=/usr/local/etc/npm

COPY conf-xenial/entrypoint.sh /entrypoint.sh
COPY conf-xenial/xdebug.ini    /etc/php/${PHP_VERSION}/mods-available/xdebug.ini
COPY conf-xenial/blackfire.ini /etc/php/${PHP_VERSION}/mods-available/blackfire.ini
COPY conf-xenial/php.fpm.ini   /etc/php/${PHP_VERSION}/fpm/php.ini
COPY conf-xenial/php.cli.ini   /etc/php/${PHP_VERSION}/cli/php.ini
COPY conf-xenial/fpm.conf      /etc/php/${PHP_VERSION}/fpm/php-fpm.conf
COPY conf-xenial/fpm.www.conf  /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf

ENV GOSU_VERSION 1.10
RUN set -x \
	&& wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
	&& wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture | awk -F- '{ print $NF }').asc" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
	&& gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
	&& rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
	&& chmod +x /usr/local/bin/gosu \
	&& gosu nobody true

ENTRYPOINT ["/entrypoint.sh"]

VOLUME ["/var/www/html/application"]
WORKDIR "/var/www/html/application"

CMD ["php-fpm", "-R", "--nodaemonize", "--force-stderr"]
