#!/bin/sh -x

#
# Build the server and copy the installation files to
# to a package directory given in the argument (default
# see below).
#

PACKAGE_DIR=$1
DEFAULT_PACKAGE_DIR=/opt/data/boardgame/haskell/package

if [ -z "${PACKAGE_DIR}" ]; then
  PACKAGE_DIR=${DEFAULT_PACKAGE_DIR}
fi

#
# Sanity check the environment and the source tree.
#
. ${WORKSPACE}/prepare.sh

cd $WORKSPACE/web-ui \
  && npm install \
  && ./build-prod.sh

cd $WORKSPACE/haskell-server
stack build
./update-ui-bundle.sh

PROG=.stack-work/install/x86_64-linux/lts-6.35/7.10.3/bin/boardgame-server

mkdir -p $PACKAGE_DIR

cp $PROG $PACKAGE_DIR
cp -a static $PACKAGE_DIR
cp -aL dict $PACKAGE_DIR
cp "test-data/sqlite-config.yml" $PACKAGE_DIR/config.yml

