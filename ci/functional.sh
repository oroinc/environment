#!/usr/bin/env bash

set -o errexit;
set -o pipefail;
set -o errtrace;
set -o nounset;

DEBUG=${DEBUG-};
if [[ "${DEBUG}" ]]; then set -o xtrace; fi

STEP=${1:-before_install};
BUILD_DIR=${BUILD_DIR:-};
UPGRADE=${UPGRADE:-update};
ORO_SEARCH_ENGINE=${ORO_SEARCH_ENGINE:-};
ORO_INSTALLED=${ORO_INSTALLED:-};
ORO_APP=${ORO_APP:-};
PROJECT_NAME=${PROJECT_NAME:-"$(ORO=true env | grep ORO | md5sum | awk '{print $1}' | cut -b 1-7)"};
TEST_RUNNER_OPTIONS=${TEST_RUNNER_OPTIONS:-};
PARALLEL_PROCESSES=${PARALLEL_PROCESSES:-$(parallel --number-of-cores)};
COMPOSE_FILE=${BUILD_DIR}/functional.yml;
if [ -n "${ORO_SEARCH_ENGINE}" ]; then
  COMPOSE_FILE="${COMPOSE_FILE} -f ${BUILD_DIR}/elasticsearch.yml";
fi

case "${STEP}" in
  before_install)
    docker volume create ${PROJECT_NAME:-functional}_cache0;
    
    docker-compose \
    -f ${COMPOSE_FILE} \
    -p ${PROJECT_NAME} \
    up --no-color -d;
    
    docker-compose \
    -f ${COMPOSE_FILE} \
    -p ${PROJECT_NAME} \
    exec -T --user www-data php \
    rm -f app/config/parameters.yml app/config/parameters_test.yml;
    
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
    exec -T --user www-data php \
    cp app/config/parameters.yml app/config/parameters_test.yml;
    
    docker-compose \
    -f ${COMPOSE_FILE} \
    -p ${PROJECT_NAME} \
    run composer validate composer.json --no-check-lock --no-check-all --no-check-publish --no-ansi;
    
    docker-compose \
    -f ${COMPOSE_FILE} \
    -p ${PROJECT_NAME} \
    run composer validate dev.json --no-check-all --no-check-publish --no-ansi;
  ;;
  install)
    if [ -n "${ORO_INSTALLED}" ]; then
      docker-compose \
      -f ${COMPOSE_FILE} \
      -p ${PROJECT_NAME} \
      exec -T --user www-data php \
      php app/console "oro:platform:${UPGRADE}" \
      --no-interaction \
      --skip-assets \
      --skip-translations \
      --force \
      --no-ansi \
      --timeout=600;
      
      docker-compose \
      -f ${COMPOSE_FILE} \
      -p ${PROJECT_NAME} \
      exec -T --user www-data php php app/console oro:config:update --no-ansi oro_ui.application_url 'http://localhost/';
      docker-compose \
      -f ${COMPOSE_FILE} \
      -p ${PROJECT_NAME} \
      exec -T --user www-data php php app/console oro:config:update --no-ansi oro_website.url 'http://localhost/';
      docker-compose \
      -f ${COMPOSE_FILE} \
      -p ${PROJECT_NAME} \
      exec -T --user www-data php php app/console oro:config:update --no-ansi oro_website.secure_url 'http://localhost/';
    else
      docker-compose \
      -f ${COMPOSE_FILE} \
      -p ${PROJECT_NAME} \
      exec -T --user www-data php php app/console oro:install \
      --no-interaction \
      --skip-assets \
      --skip-translations \
      --user-name=admin \
      --user-email=admin@example.com \
      --user-firstname=John \
      --user-lastname=Doe \
      --user-password=admin \
      --sample-data=n \
      --organization-name=Oro \
      --application-url='http://localhost/' \
      --no-ansi \
      --timeout=600;
    fi
    
    if [ -n "${ORO_SEARCH_ENGINE}" ]; then
      docker-compose \
      -f ${COMPOSE_FILE} \
      -p ${PROJECT_NAME} \
      exec -T --user www-data php php app/console oro:search:reindex --no-ansi;
      docker-compose \
      -f ${COMPOSE_FILE} \
      -p ${PROJECT_NAME} \
      exec -T --user www-data php php app/console oro:website-search:reindex --no-ansi || true;
    fi
  ;;
  before_script)
    docker-compose \
    -f ${COMPOSE_FILE} \
    -p ${PROJECT_NAME} \
    exec -T --user www-data php php bin/phpunit --testsuite=functional --group=schema,install --colors=always \
    --log-junit=/var/www/html/application/app/logs/${PROJECT_NAME}/functional.schema.xml;
    
    if [ -z "${TEST_RUNNER_OPTIONS}" ]; then
      CONTAINER_ID=$(docker-compose -f ${COMPOSE_FILE} -p ${PROJECT_NAME} ps -q database);
      IMAGE="$(docker inspect --format='{{.Config.Image}}' "${CONTAINER_ID}" | cut -d':' -f1)";
      docker commit "${CONTAINER_ID}" "${IMAGE}:${PROJECT_NAME}-${ORO_INSTALLED:-empty}";
      if [ -n "${ORO_SEARCH_ENGINE}" ]; then
        CONTAINER_ID=$(docker-compose -f ${COMPOSE_FILE} -p ${PROJECT_NAME} ps -q search);
        IMAGE="$(docker inspect --format='{{.Config.Image}}' "${CONTAINER_ID}" | cut -d':' -f1)";
        docker commit "${CONTAINER_ID}" "${IMAGE}:${PROJECT_NAME}";
      fi
      
      docker-compose \
      -f ${COMPOSE_FILE} \
      -p ${PROJECT_NAME} \
      exec -T --user www-data php bash -c 'find -L vendor/oro -type d -ipath **tests/functional | uniq | sort | grep -iv SYMFONY_ENV | tr -d "\r" | tee /var/www/html/application/app/logs/'"${PROJECT_NAME}"'/testsuites.log >> /dev/null';
      
      docker-compose \
      -f ${COMPOSE_FILE} \
      -p ${PROJECT_NAME} \
      logs --no-color --timestamps >> "${ORO_APP}/app/logs/${PROJECT_NAME}/docker.log";
      
      docker-compose \
      -f ${COMPOSE_FILE} \
      -p ${PROJECT_NAME} \
      stop;
    fi
  ;;
  script)
    if [ -z "${TEST_RUNNER_OPTIONS}" ]; then
      seq ${PARALLEL_PROCESSES} | COMPOSE_FILE=${COMPOSE_FILE} PROJECT_NAME=${PROJECT_NAME} PATCH=${PROJECT_NAME} \
      parallel --gnu -k --lb --env _ --joblog "${ORO_APP}/app/logs/${PROJECT_NAME}/parallel_cache.log" -j ${PARALLEL_PROCESSES} \
      'docker volume create --name ${PROJECT_NAME:-functional}_cache{%};
      docker run --rm -i -v ${PROJECT_NAME:-functional}_cache0:/from -v ${PROJECT_NAME:-functional}_cache{%}:/to oroinc/data-cache ash -c "cd /to ; cp -ra /from/* .";';
      
      seq ${PARALLEL_PROCESSES} | COMPOSE_FILE=${COMPOSE_FILE} PROJECT_NAME=${PROJECT_NAME} PATCH=${PROJECT_NAME} \
      parallel --gnu -k --lb --env _ --joblog "${ORO_APP}/app/logs/${PROJECT_NAME}/parallel_up.log" -j ${PARALLEL_PROCESSES} \
      'SUB_NETWORK={%} CACHE_VOLUME={%} docker-compose -f ${COMPOSE_FILE} -p ${PROJECT_NAME}_{%} up --no-color -d;';
      
      COMPOSE_FILE=${COMPOSE_FILE} PROJECT_NAME=${PROJECT_NAME} PATCH=${PROJECT_NAME} \
      parallel --gnu -k --lb --env _ --joblog "${ORO_APP}/app/logs/${PROJECT_NAME}/parallel_functional.log" -j ${PARALLEL_PROCESSES} -a "${ORO_APP}/app/logs/${PROJECT_NAME}/testsuites.log" \
      'SUB_NETWORK={%} CACHE_VOLUME={%} docker-compose -f ${COMPOSE_FILE} -p ${PROJECT_NAME}_{%} exec -T --user www-data php php bin/phpunit --testsuite=functional {} --colors=always --log-junit=/var/www/html/application/app/logs/${PROJECT_NAME}/functional.{#}.xml;';
      
      seq ${PARALLEL_PROCESSES} | COMPOSE_FILE=${COMPOSE_FILE} PROJECT_NAME=${PROJECT_NAME} PATCH=${PROJECT_NAME} \
      parallel --gnu -k --lb --env _ --joblog "${ORO_APP}/app/logs/${PROJECT_NAME}/parallel_log.log" -j ${PARALLEL_PROCESSES} \
      'SUB_NETWORK={%} CACHE_VOLUME={%} docker-compose -f ${COMPOSE_FILE} -p ${PROJECT_NAME}_{%} logs --no-color --timestamps >> ${ORO_APP}/app/logs/${PROJECT_NAME}/docker.log 2>&1;';
    else
      docker-compose \
      -f ${COMPOSE_FILE} \
      -p ${PROJECT_NAME} \
      exec -T --user www-data php php bin/phpunit --testsuite=functional "${TEST_RUNNER_OPTIONS}" --colors=always --log-junit="/var/www/html/application/app/logs/${PROJECT_NAME}/functional.xml";
    fi
  ;;
  after_script)
    set +e;
    docker ps --filter "name=${PROJECT_NAME}" -aq | xargs docker rm -fv;
    docker network ls --filter "name=${PROJECT_NAME}" -q | xargs docker network rm;
    docker images | grep "${PROJECT_NAME}" | awk '{print $3}' | xargs docker rmi -f;
    docker volume rm -f ${PROJECT_NAME:-functional}_cache0;
    seq ${PARALLEL_PROCESSES} | PROJECT_NAME=${PROJECT_NAME} parallel --gnu -k --lb --env _ \
    'docker volume rm -f ${PROJECT_NAME:-functional}_cache{%};';
    set -e;
  ;;
esac
