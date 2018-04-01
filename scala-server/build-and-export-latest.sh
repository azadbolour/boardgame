#!/bin/sh -x

#
# Package a play application from the latest source and export to a 
# well-known directory mapped to the host (this script is intended to be run
# in a docker container for packaging the application).
#

#
# import DEFAULT_PACKAGE_DIR
#
. defaults.sh

#
# Get the latest source.
#
git pull origin master

./package.sh

# TODO. Check return from package.sh.

#
# Make the bundle available outside the container.
#

#
# Copy the bundle to well-known location mapped to host machine.
#
PACKAGE_DIR=$DEFAULT_PACKAGE_DIR
sudo mkdir -p $PACKAGE_DIR
cp -a target/universal/*.zip $PACKAGE_DIR

# 
# Copy startup scripts similarly.
#
# TODO. Only copy needed scripts.
#
SCRIPT_DIR=$PACKAGE_DIR/script
mkdir -p $SCRIPT_DIR
cp -a install.sh run-server.sh get-dynamic-params.sh defaults.sh $SCRIPT_DIR

chmod -R 777 $PACKAGE_DIR

