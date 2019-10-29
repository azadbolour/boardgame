#!/bin/sh -x

# IMPORTANT. TODO. Remove all UI dependencies from this script.
# UI content is to be served indepdently of the backend server.

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
# Build the ui bundle and make sure resources are available in their required forms.
#
. ../pre-build.sh

#
# Copy over the ui bundle to the so it can be packaged with the play application.
# 
./update-ui-bundle.sh

stack build
(cd haskell-server/test-data \
  && cp sqlite-config.yml test-config.yml)
stack "test"

PROG=.stack-work/install/x86_64-linux/lts-6.35/7.10.3/bin/boardgame-server

mkdir -p $PACKAGE_DIR

cp $PROG $PACKAGE_DIR
cp -a static $PACKAGE_DIR
cp -aL dict $PACKAGE_DIR
cp "test-data/sqlite-config.yml" $PACKAGE_DIR/config.yml

