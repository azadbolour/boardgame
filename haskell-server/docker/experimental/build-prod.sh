#!/bin/sh -x

#
# Quick build assuming the project is already set up.
#

PACKAGE_DIR=$1

if [ -z "${PACKAGE_DIR}" ]; then
  PACKAGE_DIR=/opt/data/boardgame/haskell/package
fi

# git pull origin master

# cd web-ui && npm install && ./build-prod.sh
# cd haskell-server && stack build
# cd haskell-server && ./update-ui-bundle.sh

PROG=.stack-work/install/x86_64-linux/lts-6.35/7.10.3/bin/boardgame-server

mkdir -p $PACKAGE_DIR

cp $PROG $PACKAGE_DIR
cp -a static $PACKAGE_DIR
cp -aL dict $PACKAGE_DIR
cp "test-data/sqlite-config.yml" $PACKAGE_DIR/config.yml

