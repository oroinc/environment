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
CS=${CS:-};
APPLICATION=${APPLICATION};
TEST_RUNNER_OPTIONS=${TEST_RUNNER_OPTIONS};
PROJECT_NAME=${PROJECT_NAME:-"$(env | grep -v PATCH | grep -v CI_SKIP | grep -v SUB_NETWORK | md5sum | awk '{print $1}')"};
CHANGE_TARGET=${CHANGE_TARGET-master}
COMMIT_RANGE=${COMMIT_RANGE:-"origin/$CHANGE_TARGET...$(git rev-parse --verify HEAD)"};
LINES=500;
COMPOSE_FILE=${BUILD_DIR}/unit.yml;

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
    
    if [ -n "${CS}" ] && [[ -s "${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}/diff.log" ]]; then
      { set +e; grep -e "^package/.*\.php$" "${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}/diff.log" > "${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}/diff_php.log"; set -e; }
      { set +e; grep -e "^package/commerce.*\.php$" "${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}/diff.log" > "${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}/diff_commerce.log"; set -e; }
    fi
  ;;
  before_install)
    docker-compose \
    -f ${COMPOSE_FILE} \
    -p ${PROJECT_NAME} \
    up -d;
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
    run php cp phpunit.xml.dist phpunit.xml;
    
    docker-compose \
    -f ${COMPOSE_FILE} \
    -p ${PROJECT_NAME} \
    run php sed -i "/PhpunitAccelerator/d" phpunit.xml;
  ;;
  before_script)
    docker-compose \
    -f ${COMPOSE_FILE} \
    -p ${PROJECT_NAME} \
    run php bin/phpunit --testsuite=unit "${TEST_RUNNER_OPTIONS}" --colors --log-junit="/var/www/html/application/app/logs/junit/unit.${PROJECT_NAME}.xml";
  ;;
  script)
    if [ -n "${CS}" ]; then
      if [ -n "${FULL_BUILD}" ]; then
        docker-compose \
        -f ${COMPOSE_FILE} \
        -p ${PROJECT_NAME} \
        run php bin/phpcs vendor/oro -p --encoding=utf-8 --extensions=php --standard=vendor/oro/platform/build/phpcs.xml;
        elif [[ -s "${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}/diff_php.log" ]]; then
        split -l "${LINES}" "${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}/diff_php.log" "${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}/diff_php_";
        for f in ${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}/diff_php_* ; do
          if [[ ! -s "${f}" ]]; then
            break;
          fi
          echo PHPCS "${f}";
          phpFiles=$(cat "${f}");
          phpFiles=${phpFiles//'package/'/'/var/www/package/'};
          docker-compose \
          -f ${COMPOSE_FILE} \
          -p ${PROJECT_NAME} \
          run php bin/phpcs ${phpFiles} -p --encoding=utf-8 --extensions=php --standard=vendor/oro/platform/build/phpcs.xml;
        done
      fi
      
      # Run PHPCPD only when something was changed in commerce (otherwise it doesn't make sense)
      if [[ -s "${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}/diff_commerce.log" ]]; then
        phpcpdArgs="--min-lines 25 --verbose ";
        for COMMERCE_PACKAGE in "commerce-enterprise/src/Oro/Bundle/*/" "commerce/src/Oro/Bundle/*/" "commerce/src/Oro/Bridge/*/" "commerce/src/Oro/Component/*/"
        do
          for bundlePath in ${APPLICATION}/vendor/oro/${COMMERCE_PACKAGE} ; do
            bundleName=$(basename "${bundlePath}");
            phpcpdArgs+="--exclude=${bundleName}/Migrations/Schema --exclude=${bundleName}/Entity ";
          done
        done
        
        docker-compose \
        -f ${COMPOSE_FILE} \
        -p ${PROJECT_NAME} \
        run php bin/phpcpd ${phpcpdArgs} /var/www/package/commerce;
      fi
      
      if [[ -s "${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}/diff_php.log" ]]; then
        if [[ -s "${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}/diff_commerce.log" ]]; then
          split -l "${LINES}" "${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}/diff_commerce.log" "${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}/diff_commerce_";
          for f in ${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}/diff_commerce_*; do
            if [[ ! -s "${f}" ]]; then
              break;
            fi
            echo PHPMD "${f}";
            commercePhpFiles=$(cat "${f}");
            commercePhpFiles=${commercePhpFiles//'package/'/'/var/www/package/'};
            docker-compose \
            -f ${COMPOSE_FILE} \
            -p ${PROJECT_NAME} \
            run php bin/phpmd "${commercePhpFiles//$'\n'/,}" text /var/www/package/commerce/build_config/phpmd.xml --suffixes php;
          done
        fi
        
        split -l "${LINES}" "${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}/diff_php.log" "${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}/diff_php_";
        for f in ${BUILD_DIR}/ci/artifacts/${PROJECT_NAME}/diff_php_*; do
          if [[ ! -s "${f}" ]]; then
            break;
          fi
          echo PHPMD "${f}";
          phpFiles=$(cat "${f}");
          phpFiles=${phpFiles//'package/'/'/var/www/package/'};
          docker-compose \
          -f ${COMPOSE_FILE} \
          -p ${PROJECT_NAME} \
          run php bin/phpmd "${phpFiles//$'\n'/,}" text /var/www/package/platform/build/phpmd.xml --suffixes php;
        done
      fi
    fi
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
    rm -f "${APPLICATION}/phpunit.xml" || true;
    set -e;
  ;;
esac
