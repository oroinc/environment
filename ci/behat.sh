#!/usr/bin/env bash

set -o errexit;
set -o pipefail;
set -o errtrace;
set -o nounset;

DEBUG=${DEBUG-};
if [[ "${DEBUG}" ]]; then set -o xtrace; fi

STEP=${1:-before_install};
BUILD_DIR=${BUILD_DIR:-};
ORO_APP=${ORO_APP:-};
PROJECT_NAME=${PROJECT_NAME:-"$(ORO=true env | grep ORO | md5sum | awk '{print $1}' | cut -b 1-7)"};
PARALLEL_PROCESSES=${PARALLEL_PROCESSES:-$(($(parallel --number-of-cores) / 2))};
TEST_RUNNER_OPTIONS=${TEST_RUNNER_OPTIONS:-};
COMPOSE_FILE=${BUILD_DIR}/behat.yml;

case "${STEP}" in
  before_install)
    docker volume create ${PROJECT_NAME:-behat}_cache0;
    
    docker-compose \
    -f ${COMPOSE_FILE} \
    -p ${PROJECT_NAME} \
    up --no-color -d;
    
    docker-compose \
    -f ${COMPOSE_FILE} \
    -p ${PROJECT_NAME} \
    exec -T --user www-data php \
    rm -f app/config/parameters.yml behat.yml;
    
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
    exec -T --user www-data php bash -c 'echo -e "\nimports:" >> app/config/parameters.yml; find -L vendor/oro -type f -iname "parameters.yml" -ipath "**Tests/Behat**" -exec echo "  - { resource: ./../../{} }" >> app/config/parameters.yml \;';
    
    docker-compose \
    -f ${COMPOSE_FILE} \
    -p ${PROJECT_NAME} \
    exec -T --user www-data php cp behat.yml.dist behat.yml;
    
    docker-compose \
    -f ${COMPOSE_FILE} \
    -p ${PROJECT_NAME} \
    exec -T --user www-data php sed -i "s/base_url:.*$/base_url: 'http:\/\/webserver:80\/'/g" behat.yml;
    
    docker-compose \
    -f ${COMPOSE_FILE} \
    -p ${PROJECT_NAME} \
    exec -T --user www-data php sed -i '/^.*Symfony2Extension.*$/i \
            sessions: \
                second_session: \
                    oroSelenium2: \
                        wd_host: "http://browser:8910/wd/hub" \
                first_session: \
                    oroSelenium2: \
                        wd_host: "http://browser:8910/wd/hub"
    ' behat.yml;
  ;;
  install)
    docker-compose \
    -f ${COMPOSE_FILE} \
    -p ${PROJECT_NAME} \
    exec -T --user www-data php php bin/behat -vvv -s OroInstallerBundle \
    -f pretty -o std -f junit -o /var/www/html/application/app/logs/${PROJECT_NAME}/ --strict --colors;
  ;;
  before_script)
    CONTAINER_ID=$(docker-compose -f ${COMPOSE_FILE} -p ${PROJECT_NAME} ps -q database);
    IMAGE="$(docker inspect --format='{{.Config.Image}}' "${CONTAINER_ID}" | cut -d':' -f1)";
    docker commit "${CONTAINER_ID}" "${IMAGE}:${PROJECT_NAME}-empty";
    
    docker-compose \
    -f ${COMPOSE_FILE} \
    -p ${PROJECT_NAME} \
    exec -T --user www-data php php bin/behat --available-suites | grep -iv OroInstallerBundle | uniq | sort | grep -iv 'SYMFONY_ENV' | tr -d '\r' \
    >> "${ORO_APP}/app/logs/${PROJECT_NAME}/testsuites.log";
    
    docker-compose \
    -f ${COMPOSE_FILE} \
    -p ${PROJECT_NAME} \
    logs --no-color --timestamps >> "${ORO_APP}/app/logs/${PROJECT_NAME}/docker.log";
    
    docker-compose \
    -f ${COMPOSE_FILE} \
    -p ${PROJECT_NAME} \
    stop;
  ;;
  script)
    if [ -z "${TEST_RUNNER_OPTIONS}" ]; then
      seq ${PARALLEL_PROCESSES} | COMPOSE_FILE=${COMPOSE_FILE} PROJECT_NAME=${PROJECT_NAME} PATCH=${PROJECT_NAME} \
      parallel --gnu -k --lb --env _ --joblog "${ORO_APP}/app/logs/${PROJECT_NAME}/parallel_cache.log" -j ${PARALLEL_PROCESSES} \
      'docker volume create --name ${PROJECT_NAME:-behat}_cache{%};
      docker run --rm -i -v ${PROJECT_NAME:-behat}_cache0:/from -v ${PROJECT_NAME:-behat}_cache{%}:/to oroinc/data-cache ash -c "cd /to ; cp -ra /from/* .";';
      
      seq ${PARALLEL_PROCESSES} | COMPOSE_FILE=${COMPOSE_FILE} PROJECT_NAME=${PROJECT_NAME} PATCH=${PROJECT_NAME} \
      parallel --gnu -k --lb --env _ --joblog "${ORO_APP}/app/logs/${PROJECT_NAME}/parallel_up.log" -j ${PARALLEL_PROCESSES} \
      'SUB_NETWORK={%} CACHE_VOLUME={%} docker-compose -f ${COMPOSE_FILE} -p ${PROJECT_NAME}_{%} up --no-color -d;';
      
      COMPOSE_FILE=${COMPOSE_FILE} PROJECT_NAME=${PROJECT_NAME} PATCH=${PROJECT_NAME} \
      parallel --gnu -k --lb --env _ --joblog "${ORO_APP}/app/logs/${PROJECT_NAME}/parallel_behat.log" -j ${PARALLEL_PROCESSES} -a "${ORO_APP}/app/logs/${PROJECT_NAME}/testsuites.log" \
      'SUB_NETWORK={%} CACHE_VOLUME={%} docker-compose -f ${COMPOSE_FILE} -p ${PROJECT_NAME}_{%} exec -T --user www-data php bin/behat -vvv -s {} -f pretty -o std -f junit -o /var/www/html/application/app/logs/${PROJECT_NAME}/ --strict --colors;';
      
      seq ${PARALLEL_PROCESSES} | COMPOSE_FILE=${COMPOSE_FILE} PROJECT_NAME=${PROJECT_NAME} PATCH=${PROJECT_NAME} \
      parallel --gnu -k --lb --env _ --joblog "${ORO_APP}/app/logs/${PROJECT_NAME}/parallel_log.log" -j ${PARALLEL_PROCESSES} \
      'SUB_NETWORK={%} CACHE_VOLUME={%} docker-compose -f ${COMPOSE_FILE} -p ${PROJECT_NAME}_{%} logs --no-color --timestamps >> ${ORO_APP}/app/logs/${PROJECT_NAME}/docker.log 2>&1;';
    else
      docker-compose \
      -f ${COMPOSE_FILE} \
      -p ${PROJECT_NAME} \
      exec -T --user www-data php php bin/behat -vvv "${TEST_RUNNER_OPTIONS}" -f pretty -o std -f junit -o /var/www/html/application/app/logs/${PROJECT_NAME}/ --strict --no-colors;
    fi
  ;;
  after_script)
    set +e;
    docker ps --filter "name=${PROJECT_NAME}" -aq | xargs docker rm -fv;
    docker network ls --filter "name=${PROJECT_NAME}" -q | xargs docker network rm;
    docker images | grep "${PROJECT_NAME}" | awk '{print $3}' | xargs docker rmi -f;
    docker volume rm -f ${PROJECT_NAME:-behat}_cache0;
    seq ${PARALLEL_PROCESSES} | PROJECT_NAME=${PROJECT_NAME} parallel --gnu -k --lb --env _ \
    'docker volume rm -f ${PROJECT_NAME:-behat}_cache{%};';
    set -e;
  ;;
esac
