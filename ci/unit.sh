#!/usr/bin/env bash

set -o errexit;
set -o pipefail;
set -o errtrace;
set -o nounset;

DEBUG=${DEBUG-};
if [[ "${DEBUG}" ]]; then set -o xtrace; fi

STEP=${1:-before_install};
BUILD_DIR=${BUILD_DIR:-};
ORO_CS=${ORO_CS:-};
ORO_APP=${ORO_APP:-};
TEST_RUNNER_OPTIONS=${TEST_RUNNER_OPTIONS:-};
PROJECT_NAME=${PROJECT_NAME:-"$(ORO=true env | grep ORO | md5sum | awk '{print $1}' | cut -b 1-7)"};
COMPOSE_FILE=${BUILD_DIR}/unit.yml;
PARALLEL_PROCESSES=${PARALLEL_PROCESSES:-$(parallel --number-of-cores)};

case "${STEP}" in
  before_install)
    docker-compose \
    -f ${COMPOSE_FILE} \
    -p ${PROJECT_NAME} \
    up --no-color -d;
    
    docker-compose \
    -f ${COMPOSE_FILE} \
    -p ${PROJECT_NAME} \
    exec -T --user www-data php rm -f app/config/parameters.yml phpunit.xml;
  ;;
  install)
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
    exec -T --user www-data php cp phpunit.xml.dist phpunit.xml;
    
    docker-compose \
    -f ${COMPOSE_FILE} \
    -p ${PROJECT_NAME} \
    exec -T --user www-data php sed -i "/PhpunitAccelerator/d" phpunit.xml;
  ;;
  before_script)
    if [ -n "${ORO_CS}" ]; then
      docker-compose \
      -f ${COMPOSE_FILE} \
      -p ${PROJECT_NAME} \
      exec -T --user www-data php bash -c 'find -L vendor/oro -type f -iname *.php | grep -iv SYMFONY_ENV | tr -d "\r" | tee /var/www/html/application/app/logs/'"${PROJECT_NAME}"'/testsuites.cs.log >> /dev/null';
      
      docker-compose \
      -f ${COMPOSE_FILE} \
      -p ${PROJECT_NAME} \
      exec -T --user www-data php bash -c 'find -L vendor/oro -type f -iname *.php -a \( -ipath "**commerce**" -o -ipath "**customer-portal**" \) | grep -iv SYMFONY_ENV | tr -d "\r" | tee /var/www/html/application/app/logs/'"${PROJECT_NAME}"'/testsuites.strictcs.log >> /dev/null';
    fi
  ;;
  script)
    docker-compose \
    -f ${COMPOSE_FILE} \
    -p ${PROJECT_NAME} \
    exec -T --user www-data php php bin/phpunit --testsuite=unit "${TEST_RUNNER_OPTIONS}" --colors=always --log-junit="/var/www/html/application/app/logs/${PROJECT_NAME}/unit.xml";
    
    if [ -n "${ORO_CS}" ]; then
      seq ${PARALLEL_PROCESSES} | COMPOSE_FILE=${COMPOSE_FILE} PROJECT_NAME=${PROJECT_NAME} \
      parallel --gnu --env _ -k --lb -j ${PARALLEL_PROCESSES} --joblog "${ORO_APP}/app/logs/${PROJECT_NAME}/parallel_up.log" \
      'SUB_NETWORK={%} \
      docker-compose -f ${COMPOSE_FILE} -p ${PROJECT_NAME}_{%} up --no-color -d;';
      
      COMPOSE_FILE=${COMPOSE_FILE} PROJECT_NAME=${PROJECT_NAME} \
      parallel --gnu --env _ --xargs -k --lb -j ${PARALLEL_PROCESSES} --joblog "${ORO_APP}/app/logs/${PROJECT_NAME}/parallel_cs.log" -a "${ORO_APP}/app/logs/${PROJECT_NAME}/testsuites.cs.log" \
      'SUB_NETWORK={%} \
      docker-compose -f ${COMPOSE_FILE} -p ${PROJECT_NAME}_{%} exec -T --user www-data php php bin/phpcs {} -p --encoding=utf-8 --extensions=php --standard=vendor/oro/platform/build/phpcs.xml --report-full --report-junit=/var/www/html/application/app/logs/${PROJECT_NAME}/phpcs.{#}.xml;';
      
      COMPOSE_FILE=${COMPOSE_FILE} PROJECT_NAME=${PROJECT_NAME} \
      parallel --gnu --env _ --xargs -k --lb -j ${PARALLEL_PROCESSES} --joblog "${ORO_APP}/app/logs/${PROJECT_NAME}/parallel_cs_fixer.log" -a "${ORO_APP}/app/logs/${PROJECT_NAME}/testsuites.cs.log" \
      'SUB_NETWORK={%} \
      docker-compose -f ${COMPOSE_FILE} -p ${PROJECT_NAME}_{%} exec -T --user www-data php php bin/php-cs-fixer fix {} --dry-run --verbose --config=vendor/oro/platform/build/.php_cs --path-mode=intersection;';
      
      COMPOSE_FILE=${COMPOSE_FILE} PROJECT_NAME=${PROJECT_NAME} \
      parallel --gnu --env _ --xargs -k --lb -j ${PARALLEL_PROCESSES} --joblog "${ORO_APP}/app/logs/${PROJECT_NAME}/parallel_md1.log" -a "${ORO_APP}/app/logs/${PROJECT_NAME}/testsuites.cs.log" \
      'files="{}"; SUB_NETWORK={%} \
      docker-compose -f ${COMPOSE_FILE} -p ${PROJECT_NAME}_{%} exec -T --user www-data php php bin/phpmd ${files// /,} text vendor/oro/platform/build/phpmd.xml --suffixes php --reportfile-xml /var/www/html/application/app/logs/${PROJECT_NAME}/phpmd.{#}.xml;';
      
      COMPOSE_FILE=${COMPOSE_FILE} PROJECT_NAME=${PROJECT_NAME} \
      parallel --gnu --env _ --xargs -k --lb -j ${PARALLEL_PROCESSES} --joblog "${ORO_APP}/app/logs/${PROJECT_NAME}/parallel_md2.log" -a "${ORO_APP}/app/logs/${PROJECT_NAME}/testsuites.strictcs.log" \
      'files="{}"; SUB_NETWORK={%} \
      docker-compose -f ${COMPOSE_FILE} -p ${PROJECT_NAME}_{%} exec -T --user www-data php php bin/phpmd ${files// /,} text vendor/oro/commerce/build_config/phpmd.xml --suffixes php --reportfile-xml /var/www/html/application/app/logs/${PROJECT_NAME}/phpmd_strict.{#}.xml;';
      
      seq ${PARALLEL_PROCESSES} | COMPOSE_FILE=${COMPOSE_FILE} PROJECT_NAME=${PROJECT_NAME} \
      parallel --gnu --env _ -k --lb -j ${PARALLEL_PROCESSES} --joblog "${ORO_APP}/app/logs/${PROJECT_NAME}/parallel_log.log" \
      'SUB_NETWORK={%} \
      docker-compose -f ${COMPOSE_FILE} -p ${PROJECT_NAME}_{%} logs --no-color --timestamps >> ${ORO_APP}/app/logs/${PROJECT_NAME}/docker.log 2>&1;';
      
      # @todo: add * to the ending, like vendor/oro/commerce*, see BB-9400
      docker-compose \
      -f ${COMPOSE_FILE} \
      -p ${PROJECT_NAME} \
      exec -T --user www-data php php bin/phpcpd --min-lines 25 --verbose --regexps-exclude=Migrations/Schema/,Entity/ --log-pmd=/var/www/html/application/app/logs/${PROJECT_NAME}/phpcpd.xml vendor/oro/commerce;
    fi
    
    docker-compose \
    -f ${COMPOSE_FILE} \
    -p ${PROJECT_NAME} \
    logs --no-color --timestamps >> "${ORO_APP}/app/logs/${PROJECT_NAME}/docker.log";
  ;;
  after_script)
    set +e;
    docker ps --filter "name=${PROJECT_NAME}" -aq | xargs docker rm -fv;
    docker network ls --filter "name=${PROJECT_NAME}" -q | xargs docker network rm;
    set -e;
  ;;
esac
