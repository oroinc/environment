#!/usr/bin/env bash

set -o errexit;
set -o pipefail;
set -o errtrace;
set -o nounset;

DEBUG=${DEBUG-};
if [[ "${DEBUG}" ]]; then set -o xtrace; fi

STEP=$1;
BUILD_DIR=${BUILD_DIR};
PHP=${PHP-7.1};
UPGRADE=${UPGRADE:-};
FULL_BUILD=${FULL_BUILD:-};
ORO_SEARCH_ENGINE=${ORO_SEARCH_ENGINE:-};
DB=${DB-mysql};
ORO_INSTALLED=${ORO_INSTALLED:-};
APPLICATION=${APPLICATION-application/platform};
PROJECT_NAME=${PROJECT_NAME:-"$(env | grep -v PATCH | grep -v CI_SKIP | grep -v SUB_NETWORK | md5sum | awk '{print $1}')"};
TEST_RUNNER_OPTIONS=${TEST_RUNNER_OPTIONS};
PARALLEL_PROCESSES=${PARALLEL_PROCESSES-4};
TEST_SUITE=${TEST_SUITE:-functional};
CHANGE_TARGET=${CHANGE_TARGET-master}
COMMIT_RANGE=${COMMIT_RANGE:-"origin/$CHANGE_TARGET...$(git rev-parse --verify HEAD)"};
COMPOSE_FILE=${BUILD_DIR}/functional.yml;
if [ -n "${ORO_SEARCH_ENGINE}" ]; then
  COMPOSE_FILE="${COMPOSE_FILE} -f ${BUILD_DIR}/elasticsearch.yml";
fi

case "${STEP}" in
  check)
    mkdir -p "${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}" || true;
    { cd "${APPLICATION}";
      git diff --name-only --diff-filter=ACMR "${COMMIT_RANGE}" > "${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}/diff.log";
    cd "${BUILD_DIR}"; }
    
    echo "Defining strategy for Tests...";
    if  [ -n "${FULL_BUILD}" ]; then
      echo "Full build is detected. Run all";
    else
      { set +e; files=$(grep -e "^application/" -e "^package/" -r --exclude=\*.{feature,msi,ods,psd,bat,gif,gitignore,gitkeep,html,jpg,jpeg,md,mp4,png,py,rst,txt,gliffy,css,js,less,scss,cur,eot,ico,svg,ttf,woff,woff2,xlsx} "${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}/diff.log"); set -e; }
      if [[ "${files}" ]]; then
        echo "Source code changes were detected";
      else
        echo "Source code changes were not detected";
        echo "Tests build not required!";
        export CI_SKIP=1;
        
        exit 0;
      fi
    fi
  ;;
  before_install)
    docker-compose \
    -f ${COMPOSE_FILE} \
    -p ${PROJECT_NAME} \
    up -d;
    
    # todo: health check database
    sleep 15s;
    
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
    run php cp app/config/parameters.yml app/config/parameters_test.yml;
    
    docker-compose \
    -f ${COMPOSE_FILE} \
    -p ${PROJECT_NAME} \
    run composer validate composer.json --no-check-lock --no-check-all --no-check-publish --no-ansi;
    
    docker-compose \
    -f ${COMPOSE_FILE} \
    -p ${PROJECT_NAME} \
    run composer validate dev.json --no-check-all --no-check-publish --no-ansi;
    
    if [ -n "${ORO_INSTALLED}" ]; then
      case "${DB}" in
        mysql)
          zcat < "${BUILD_DIR}/dumps/${ORO_INSTALLED}.${DB}.sql.gz" | docker-compose \
          -f ${COMPOSE_FILE} \
          -p ${PROJECT_NAME} \
          run \
          database \
          bash -c "mysql -uoro_db_user -poro_db_pass -hdatabase oro_db > /dev/null";
        ;;
        pgsql)
          zcat < "${BUILD_DIR}/dumps/${ORO_INSTALLED}.${DB}.sql.gz" | docker-compose \
          -f ${COMPOSE_FILE} \
          -p ${PROJECT_NAME} \
          run \
          database \
          bash -c "PGPASSWORD=oro_db_pass psql -Uoro_db_user -w -hdatabase oro_db > /dev/null";
        ;;
      esac
    fi
  ;;
  install)
    if [ -n "${ORO_INSTALLED}" ]; then
      if [ -n "$UPGRADE" ]; then
        docker-compose \
        -f ${COMPOSE_FILE} \
        -p ${PROJECT_NAME} \
        run php app/console oro:platform:upgrade20 \
        --no-interaction \
        --skip-assets \
        --skip-translations \
        --force \
        --no-ansi \
        --timeout=600;
      else
        docker-compose \
        -f ${COMPOSE_FILE} \
        -p ${PROJECT_NAME} \
        run php app/console oro:platform:update \
        --no-interaction \
        --skip-assets \
        --skip-translations \
        --force \
        --no-ansi \
        --timeout=600;
      fi
      
      docker-compose \
      -f ${COMPOSE_FILE} \
      -p ${PROJECT_NAME} \
      run php app/console oro:config:update --no-ansi oro_ui.application_url 'http://localhost/';
      docker-compose \
      -f ${COMPOSE_FILE} \
      -p ${PROJECT_NAME} \
      run php app/console oro:config:update --no-ansi oro_website.url 'http://localhost/';
      docker-compose \
      -f ${COMPOSE_FILE} \
      -p ${PROJECT_NAME} \
      run php app/console oro:config:update --no-ansi oro_website.secure_url 'http://localhost/';
    else
      docker-compose \
      -f ${COMPOSE_FILE} \
      -p ${PROJECT_NAME} \
      run php app/console oro:install \
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
      run php app/console oro:search:reindex --no-ansi;
    fi
  ;;
  before_script)
    if [ -z "${TEST_RUNNER_OPTIONS}" ]; then
      declare -a CONTAINERS=(data data-cache database);
      if [ -n "${ORO_SEARCH_ENGINE}" ]; then
        CONTAINERS+=(search);
      fi
      PATCH=${PROJECT_NAME};
      
      docker-compose \
      -f ${COMPOSE_FILE} \
      -p ${PROJECT_NAME} \
      run php bin/phpunit --testsuite=functional --group=schema --colors;
      
      if [ -z "${ORO_INSTALLED}" ]; then
        docker-compose \
        -f ${COMPOSE_FILE} \
        -p ${PROJECT_NAME} \
        run php bin/phpunit --testsuite=functional --group=install --colors;
      fi
      
      for CONTAINER in "${CONTAINERS[@]}"
      do
        CONTAINER_ID=$(docker-compose -f ${COMPOSE_FILE} -p ${PROJECT_NAME} ps -q ${CONTAINER});
        IMAGE="$(docker inspect --format='{{.Config.Image}}' "${CONTAINER_ID}" | cut -d':' -f1)";
        docker commit "${CONTAINER_ID}" "${IMAGE}:${PATCH}";
      done
      
      export PATCH;
      
      if [ -n "${PARALLEL_PROCESSES}" ]; then
        for I in $(seq 1 "${PARALLEL_PROCESSES}"); do
          SUB_NETWORK=${I} docker-compose \
          -f ${COMPOSE_FILE} \
          -p ${PROJECT_NAME}_${I} \
          up -d &
        done
      fi
      
      docker-compose \
      -f ${COMPOSE_FILE} \
      -p ${PROJECT_NAME} \
      run php find -L vendor/oro -type d -ipath "**tests/functional" | uniq | sort | grep -v 'export' | tr -d '\r' \
      > "${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}/testsuites.log";
      
      docker-compose \
      -f ${COMPOSE_FILE} \
      -p ${PROJECT_NAME} \
      stop;
      
      # todo: health check database
      sleep 60s;
    fi
  ;;
  script)
    if [ -z "${TEST_RUNNER_OPTIONS}" ]; then
      parallel --env _ --joblog "${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}/parallel.log" -j ${PARALLEL_PROCESSES} -a "${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}/testsuites.log" \
      "docker-compose -f ${COMPOSE_FILE} -p ${PROJECT_NAME}_{%} exec -T --user www-data php php bin/phpunit {} --testsuite=functional --colors --log-junit=/var/www/html/application/app/logs/junit/functional.${PROJECT_NAME}.{#}.xml"
    else
      docker-compose \
      -f ${COMPOSE_FILE} \
      -p ${PROJECT_NAME} \
      run php bin/phpunit --testsuite=functional "${TEST_RUNNER_OPTIONS}" --colors --log-junit="/var/www/html/application/app/logs/junit/functional.${PROJECT_NAME}.xml";
    fi
  ;;
  after_script)
    set +e;
    if [ -n "${PARALLEL_PROCESSES}" ]; then
      for I in $(seq 1 "${PARALLEL_PROCESSES}"); do
        docker-compose \
        -f ${COMPOSE_FILE} \
        -p ${PROJECT_NAME}_${I} \
        logs --no-color --timestamps > "${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}/docker.${I}.log";
        
        docker-compose \
        -f ${COMPOSE_FILE} \
        -p ${PROJECT_NAME}_${I} \
        down -v;
      done
    fi
    
    docker-compose \
    -f ${COMPOSE_FILE} \
    -p ${PROJECT_NAME} \
    logs --no-color --timestamps > "${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}/docker.log";
    
    docker-compose \
    -f ${COMPOSE_FILE} \
    -p ${PROJECT_NAME} \
    down -v;
    
    rm -f "${APPLICATION}/app/config/parameters.yml" || true;
    rm -f "${APPLICATION}/app/config/parameters_test.yml" || true;
    
    docker images | grep "${PROJECT_NAME}" | awk '{print $3}' | xargs docker rmi -f;
    
    unset PATCH;
    set -e;
  ;;
esac
