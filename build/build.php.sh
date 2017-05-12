#!/usr/bin/env bash
pushd "$(dirname "$0")" > /dev/null;DIR="$(pwd -P)";popd > /dev/null
DIR="${DIR}/../"

PHP_VERSIONS="5.6 7.0 7.1"
DIST="xenial"

for version in ${PHP_VERSIONS}; do
  docker build --build-arg "PHP_VERSION=${version}" -t "oroinc/php:${version}-fpm-${DIST}" -f "${DIR}/php/universal-fpm-${DIST}/Dockerfile" "${DIR}/php" || {
    echo "Can't build oroinc/php:${version}-fpm-${DIST}"
    exit 1
  }
  
  docker build -t "oroinc/websocket:${version}-${DIST}" -f "${DIR}/websocket/${version}-${DIST}/Dockerfile" "${DIR}/websocket" || {
    echo "Can't build oroinc/websocket:${version}-${DIST}"
    exit 1
  }
  
  docker build -t "oroinc/cron:${version}-${DIST}" -f "${DIR}/cron/${version}-${DIST}/Dockerfile" "${DIR}/cron" || {
    echo "Can't build oroinc/cron:${version}-${DIST}"
    exit 1
  }
  
  docker build -t "oroinc/consumer:${version}-${DIST}" -f "${DIR}/consumer/${version}-${DIST}/Dockerfile" "${DIR}/consumer" || {
    echo "Can't build oroinc/consumer:${version}-${DIST}"
    exit 1
  }
done

