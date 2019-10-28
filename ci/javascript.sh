#!/usr/bin/env bash

set -o errexit;
set -o pipefail;
set -o errtrace;
set -o nounset;

DEBUG=${DEBUG-};
if [[ "${DEBUG}" ]]; then set -o xtrace; fi

BIN_CONSOLE="app/console"
CONFIG_DIR="app/config"
LOGS_DIR="app/logs"
if [[ ! -f ${BIN_CONSOLE} ]]
then
  BIN_CONSOLE="bin/console"
  CONFIG_DIR="config"
  LOGS_DIR="var/logs"
fi

STEP=${1:-before_install};
BUILD_DIR=${BUILD_DIR:-};
ORO_APP=${ORO_APP:-};
ORO_CS=${ORO_CS-true};
PROJECT_NAME=${PROJECT_NAME:-"$(ORO=true env | grep ORO | md5sum | awk '{print $1}' | cut -b 1-7)"};
COMPOSE_FILE=${BUILD_DIR}/javascript.yml;

case "${STEP}" in
  before_install)
    docker volume create ${PROJECT_NAME:-javascript}_cache0;
  ;;
  install)
    docker-compose \
    -f ${COMPOSE_FILE} \
    -p ${PROJECT_NAME} \
    up --no-color -d;
    
    docker-compose \
    -f ${COMPOSE_FILE} \
    -p ${PROJECT_NAME} \
    exec -T --user www-data php rm -f ${CONFIG_DIR}/parameters.yml;
  ;;
  before_script)
    docker-compose \
    -f ${COMPOSE_FILE} \
    -p ${PROJECT_NAME} \
    run composer install \
    --prefer-dist \
    --no-suggest \
    --no-interaction \
    --ignore-platform-reqs \
    --no-ansi \
    --optimize-autoloader || true;
    
    docker-compose \
    -f ${COMPOSE_FILE} \
    -p ${PROJECT_NAME} \
    exec -T --user www-data php npm install --prefix vendor/oro/platform/build/;
  ;;
  script)
    if [ -n "${ORO_CS}" ]; then
      docker-compose \
      -f ${COMPOSE_FILE} \
      -p ${PROJECT_NAME} \
      exec -T --user www-data php vendor/oro/platform/build/node_modules/.bin/jscs --config=vendor/oro/platform/build/.jscsrc vendor/oro;
      
      docker-compose \
      -f ${COMPOSE_FILE} \
      -p ${PROJECT_NAME} \
      exec -T --user www-data php vendor/oro/platform/build/node_modules/.bin/jshint --config=vendor/oro/platform/build/.jshintrc --exclude-path=vendor/oro/platform/build/.jshintignore vendor/oro;
    fi
    
    docker-compose \
    -f ${COMPOSE_FILE} \
    -p ${PROJECT_NAME} \
    exec -T --user www-data php php ${BIN_CONSOLE} oro:localization:dump --no-ansi;
    docker-compose \
    -f ${COMPOSE_FILE} \
    -p ${PROJECT_NAME} \
    exec -T --user www-data php php ${BIN_CONSOLE} assets:install --no-ansi;
    docker-compose \
    -f ${COMPOSE_FILE} \
    -p ${PROJECT_NAME} \
    exec -T --user www-data php php ${BIN_CONSOLE} oro:assets:build --no-ansi;
    docker-compose \
    -f ${COMPOSE_FILE} \
    -p ${PROJECT_NAME} \
    exec -T --user www-data php vendor/oro/platform/build/node_modules/.bin/karma start vendor/oro/platform/build/karma.conf.js.dist --single-run;
    
    docker-compose \
    -f ${COMPOSE_FILE} \
    -p ${PROJECT_NAME} \
    logs --no-color --timestamps >> "${ORO_APP}/${LOGS_DIR}/${PROJECT_NAME}/docker.log";
  ;;
  after_script)
    set +e;
    docker ps --filter "name=${PROJECT_NAME}" -aq | xargs docker rm -fv;
    docker network ls --filter "name=${PROJECT_NAME}" -q | xargs docker network rm;
    docker volume rm -f ${PROJECT_NAME:-javascript}_cache0;
    set -e;
  ;;
esac
