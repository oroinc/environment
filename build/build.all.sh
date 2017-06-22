#!/usr/bin/env bash
pushd "$(dirname "$0")" > /dev/null;DIR="$(pwd -P)";popd > /dev/null

bash "${DIR}/build.php.sh"
bash "${DIR}/build.db.sh"

DIR="$DIR/.."

find "$DIR"/*/*/Dockerfile -type f | grep -v 'universal'  | awk -F '/' '{print $(NF-2) " " $(NF-1)}' | xargs -n 2 bash -c "docker build -t oroinc/\$0:\$1 -f '${DIR}'/\$0/\$1/Dockerfile '${DIR}'/\$0 && echo \"COMPLETE >>> oroinc/\$0:\$1\" || echo \"FAILURE >>> oroinc/\$0:\$1\" "

docker build -t oroinc/data "${DIR}/data" || {
  echo "Can't build oroinc/data"
  exit 1
}

docker build -t oroinc/data-cache "${DIR}/data-cache" || {
  echo "Can't build oroinc/data-cache"
  exit 1
}
