#!/bin/sh

#
# Package a play application from the latest source and export to a 
# well-known directory mapped to the host (this script is intended to be run
# in a docker container for packaging the application).
#

#
# import DEFAULT_BOARDGAME_DATA
# import BOARDGAME_SERVER
#
. defaults.sh

#
# Get the latest source.
#
git pull origin master

./package.sh

#
# Check that it was packaged and can be installed.
#
./install.sh

#
# Make the bundle available outside the container.
#

BOARDGAME_DATA=$DEFAULT_BOARDGAME_DATA

#
# Copy the bundle to well-known location mapped to host machine.
#
PACKAGE_EXPORT_DIR=$BOARDGAME_DATA/package
sudo mkdir -p $PACKAGE_EXPORT_DIR
sudo chown $USER $PACKAGE_EXPORT_DIR
cp -a target/universal/*.zip $PACKAGE_EXPORT_DIR

# 
# Copy startup scripts similarly.
#
# TODO. Only copy needed scripts.
#
SCRIPT_EXPORT_DIR=$BOARDGAME_DATA/package/script
mkdir -p $SCRIPT_EXPORT_DIR
cp -a *.sh $SCRIPT_EXPORT_DIR


