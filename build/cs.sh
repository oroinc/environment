#!/usr/bin/env bash

pushd "$(dirname "$0")" > /dev/null;DIR="$(pwd -P)";popd > /dev/null

# https://github.com/koalaman/shellcheck
find "$DIR"/.. -type f -name '*.sh' -print -exec shellcheck -e SC2086 -e SC1004 -e SC2181 -e SC2094 {} \;

# https://github.com/bemeurer/beautysh
find "$DIR"/.. -type f -name '*.sh' -print -exec beautysh -i 2 --files {} \;

find "$DIR"/.. -type f -name '*.sh' -print -exec bash -n {} \;
