#!/usr/bin/env bash

build () {
    echo 'Log: start build'
    root=$1 
    echo "Log: root path ${root}"
    code=0

    cd "${root}"
    npm install # install deps

    if [ -e "./gyp" ]; then
        git submodule init
        [ "$?" != "0" ] && code=1

        git submodule update
        [ "$?" != "0" ] && code=1

        cd ./gyp

        sh third-party.sh
        [ "$?" != "0" ] && code=1

        cd -
    fi
    
    if [ "$(uname)" = "Linux" ]; then
        export LINK=g++
    fi
    
    # build
    node-gyp rebuild
    [ "$?" != "0" ] && code=1
    
    # reset
    cd -

    echo 'Log: end build'

    if [ "${code}" != "0" ]; then
        exit 1
    fi
    exit 0
}

NPM_MODULES_PATH="$(npm prefix -g)/lib/node_modules"

NAME=$1
[ "$NAME" = "" ] && NAME="fis"
[ "$NAME" != "fis" ] && NAME="${NAME}/node_modules/fis"

NEED_BUILD_MODULES=(
    "node_modules/fis-optimizer-png-compressor/node_modules/node-pngcrush"
    "node_modules/fis-optimizer-png-compressor/node_modules/node-pngquant-native"
    "node_modules/fis-spriter-csssprites/node_modules/images"
)

for module in "${NEED_BUILD_MODULES[@]}"; do
    root="$NPM_MODULES_PATH/$NAME/$module"
    github=$(cat "$root/package.json" | grep '\.git"' | tr "\"" " " | awk '{print $3 }' | sed -e 's/git\+//')
    module_root="${NPM_MODULES_PATH}/$(echo $module | awk -F '/' '{print $NF}')"
    [ -e "${module_root}" ] && rm -rf "${module_root}"
    echo "LOG: git clone ${github} ${module_root}"
    git clone "${github}" "${module_root}"
    build "${module_root}"

    if [ "$?" = "0" ]; then
        echo "LOG: remove old module ${root}"
        rm -rf $root
    fi
done
