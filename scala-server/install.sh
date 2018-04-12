#!/bin/sh -x

#
# Install the board game package to /usr/local/boardgame.
# This script is called to install the board game in docker container.
#

#
# Root of the distribution.
#
PACKAGE_DIR=$1
test -d "$PACKAGE_DIR" || (echo "no distribution found at: ${PACKAGE_DIR}"; exit 1)

#
# import BOARDGAME_SERVER
# import DEFAULT_INSTALL_DIR
#

cd $PACKAGE_DIR/script
ls -lt
. ./defaults.sh

SERVER=$BOARDGAME_SERVER
INSTALL=$DEFAULT_INSTALL_DIR

cd $PACKAGE_DIR
VERSIONED_SERVER=`ls *.zip | sed -e "s/\.zip$//"`     # Assumes jus one zippped package.

# sudo mkdir -p $INSTALL
mkdir -p $INSTALL
test -d "$INSTALL" || (echo "unable to create installation directory: ${INSTALL}"; exit 1)

ZIPPED_BUNDLE=$PACKAGE_DIR/${VERSIONED_SERVER}.zip

cd $INSTALL
rm -rf ${VERSIONED_SERVER}/
rm -f $SERVER
unzip $ZIPPED_BUNDLE

# 
# Set up a well-known link so users become independent of the version.
#
ln -s ${VERSIONED_SERVER} $SERVER


