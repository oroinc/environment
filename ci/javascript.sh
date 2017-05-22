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
CS=${CS-true};
APPLICATION=${APPLICATION};
PROJECT_NAME=${PROJECT_NAME:-"$(env | grep -v PATCH | grep -v CI_SKIP | grep -v SUB_NETWORK | md5sum | awk '{print $1}')"};
CHANGE_TARGET=${CHANGE_TARGET-master}
COMMIT_RANGE=${COMMIT_RANGE:-"origin/$CHANGE_TARGET...$(git rev-parse --verify HEAD)"};
LINES=500;
COMPOSE_FILE=${BUILD_DIR}/javascript.yml;

case "${STEP}" in
  check)
    mkdir -p "${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}" || true;
    { cd "${APPLICATION}";
      git diff --name-only --diff-filter=ACMR "${COMMIT_RANGE}" > "${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}/diff.log";
    cd "${BUILD_DIR}"; }
    
    if [[ -s "${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}/diff.log" ]]; then
      { set +e; grep -e "^package/.*\.js$" "${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}/diff.log" > "${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}/diff_js.log"; set -e; }
      [ -e "${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}/diff_js.log" ] && files=$(cat "${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}/diff_js.log")
    fi
    
    if [ "${FULL_BUILD}" == "true" ]; then
      echo "Full build is detected. Run all";
      elif [[ "${files}" ]]; then
      echo "Package or application changes were detected";
    else
      echo "JS build not required!";
      export CI_SKIP=1;
      exit 0;
    fi
  ;;
  before_install)
  ;;
  install)
    docker-compose \
    -f ${COMPOSE_FILE} \
    -p ${PROJECT_NAME} \
    up -d;
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
    --no-ansi
    --optimize-autoloader || true;
    
    docker-compose \
    -f ${COMPOSE_FILE} \
    -p ${PROJECT_NAME} \
    run php npm install --prefix vendor/oro/platform/build/;
  ;;
  script)
    if [ -n "${CS}" ]; then
      if [ -n "${FULL_BUILD}" ]; then
        docker-compose \
        -f ${COMPOSE_FILE} \
        -p ${PROJECT_NAME} \
        run php vendor/oro/platform/build/node_modules/.bin/jscs --config=vendor/oro/platform/build/.jscsrc vendor/oro;
        
        docker-compose \
        -f ${COMPOSE_FILE} \
        -p ${PROJECT_NAME} \
        run php vendor/oro/platform/build/node_modules/.bin/jshint --config=vendor/oro/platform/build/.jshintrc --exclude-path=vendor/oro/platform/build/.jshintignore vendor/oro;
      fi
      if [[ -s "{BUILD_DIR}/ci/artifacts/${PROJECT_NAME}/diff_js.log" ]]; then
        split -l "${LINES}" "${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}/diff_js.log" "${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}/diff_js_";
        for f in ${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}/diff_js_* ; do
          if [[ ! -s "${f}" ]]; then
            break;
          fi
          jsFiles=$(cat "${f}");
          jsFiles=${jsFiles//'package/'/'/var/www/package/'};
          docker-compose \
          -f ${COMPOSE_FILE} \
          -p ${PROJECT_NAME} \
          run php vendor/oro/platform/build/node_modules/.bin/jscs "${jsFiles//$'\n'/' '}" \
          --config=vendor/oro/platform/build/.jscsrc;
          
          docker-compose \
          -f ${COMPOSE_FILE} \
          -p ${PROJECT_NAME} \
          run php vendor/oro/platform/build/node_modules/.bin/jshint "${jsFiles//$'\n'/' '}" \
          --config=vendor/oro/platform/build/.jshintrc \
          --exclude-path=vendor/oro/platform/build/.jshintignore;
        done
      fi
    fi
    
    docker-compose \
    -f ${COMPOSE_FILE} \
    -p ${PROJECT_NAME} \
    run php app/console oro:localization:dump --no-ansi;
    docker-compose \
    -f ${COMPOSE_FILE} \
    -p ${PROJECT_NAME} \
    run php app/console oro:assets:install --no-ansi;
    docker-compose \
    -f ${COMPOSE_FILE} \
    -p ${PROJECT_NAME} \
    run php app/console assetic:dump --no-ansi;
    docker-compose \
    -f ${COMPOSE_FILE} \
    -p ${PROJECT_NAME} \
    run php app/console oro:requirejs:build --no-ansi;
    docker-compose \
    -f ${COMPOSE_FILE} \
    -p ${PROJECT_NAME} \
    run php vendor/oro/platform/build/node_modules/.bin/karma start vendor/oro/platform/build/karma.conf.js.dist --single-run;
  ;;
  after_script)
    set +e;
    docker-compose \
    -f ${COMPOSE_FILE} \
    -p ${PROJECT_NAME} \
    logs --no-color --timestamps > "${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}/docker.log";
    docker-compose \
    -f ${COMPOSE_FILE} \
    -p ${PROJECT_NAME} \
    down -v;
    
    rm -f "${APPLICATION}/app/config/parameters.yml" || true;
    set -e;
  ;;
esac
