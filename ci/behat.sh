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
FULL_BUILD=${FULL_BUILD:-};
DB=${DB-mysql};
APPLICATION=${APPLICATION-application/platform};
PROJECT_NAME=${PROJECT_NAME:-"$(env | grep -v PATCH | grep -v CI_SKIP | grep -v SUB_NETWORK | md5sum | awk '{print $1}')"};
PARALLEL_PROCESSES=${PARALLEL_PROCESSES-2};
TEST_RUNNER_OPTIONS=${TEST_RUNNER_OPTIONS};
TEST_SUITE=${TEST_SUITE:-behat};
COMMIT_RANGE=${COMMIT_RANGE:-"origin/master...$(git rev-parse --verify HEAD)"};
COMPOSE_FILE=${BUILD_DIR}/behat.yml;

case "${STEP}" in
  check)
    mkdir -p "${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}" || true;
    { cd "${APPLICATION}";
      git diff --name-only --diff-filter=ACMR "${COMMIT_RANGE}" > "${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}/diff.log";
    cd "${BUILD_DIR}"; }

    echo "Defining strategy for Behat Tests...";
    if [ "${FULL_BUILD}" == "true" ]; then
      echo "Full build is detected. Run all";
      return 0;
    fi
    { set +e; files=$(grep -e "^application/" -e "^package/" -e "^Jenkinsfile" -e "^.jenkins" -r --exclude=\*.{msi,ods,psd,bat,gif,gitignore,gitkeep,html,jpg,jpeg,md,mp4,png,py,rst,txt,gliffy} "${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}/diff.log"); set -e; }
    if [[ "${files}" ]]; then
      echo "Package or application changes were detected";
    else
      echo "Documentation build not required!";
      export CI_SKIP=1;

      exit 0;
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
    run php bash -c 'echo -e "\nimports:" >> app/config/parameters.yml; find -L vendor/oro -type f -name "parameters.yml" -path "**Tests/Behat**" -exec echo "  - { resource: ./../../{} }" >> app/config/parameters.yml \;';

    docker-compose \
    -f ${COMPOSE_FILE} \
    -p ${PROJECT_NAME} \
    run php cp behat.yml.dist behat.yml;

    docker-compose \
    -f ${COMPOSE_FILE} \
    -p ${PROJECT_NAME} \
    run php sed -i "s/base_url:.*$/base_url: 'http:\/\/webserver:80\/'/g" behat.yml;

    docker-compose \
    -f ${COMPOSE_FILE} \
    -p ${PROJECT_NAME} \
    run php sed -i '/^.*Symfony2Extension.*$/i \
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
    run php bin/behat -s OroInstallerBundle --skip-isolators;
  ;;
  before_script)
    declare -a CONTAINERS=(data data-cache database);
    PATCH=${PROJECT_NAME};

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
    run php bin/behat --available-suites | grep -v OroInstallerBundle | uniq | sort | grep -v 'export' | tr -d '\r' \
    > "${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}/testsuites.log";

    docker-compose \
    -f ${COMPOSE_FILE} \
    -p ${PROJECT_NAME} \
    stop;

    # todo: health check database
    sleep 30s;
  ;;
  script)
    if [ -z "${TEST_RUNNER_OPTIONS}" ]; then
      parallel --env _ --joblog "${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}/parallel.log" -j ${PARALLEL_PROCESSES} -a "${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}/testsuites.log" \
      "docker-compose -f ${COMPOSE_FILE} -p ${PROJECT_NAME}_{%} exec -T --user www-data php bin/behat -s {} -f pretty -o std -f junit -o /var/www/html/application/app/logs/junit/ --strict --colors"
    else
      docker-compose \
      -f ${COMPOSE_FILE} \
      -p ${PROJECT_NAME} \
      run php bin/behat "${TEST_RUNNER_OPTIONS}" -f progress -o std -f junit -o /var/www/html/application/app/logs/junit/ --strict --no-colors;
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

    rm -f "${APPLICATION}/behat.yml" || true;
    rm -f "${APPLICATION}/app/config/parameters.yml" || true;

    docker images | grep "${PROJECT_NAME}" | awk '{print $3}' | xargs docker rmi -f;

    unset PATCH;
    set -e;
  ;;
esac
