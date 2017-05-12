FROM oroinc/php:7.1-fpm-xenial

RUN export DEBIAN_FRONTEND=noninteractive \
&& apt-get -qq update \
&& apt-get -qqy install --no-install-recommends mysql-client postgresql-client \
&& apt-get autoclean
