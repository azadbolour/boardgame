#!/bin/sh -x

#
# Package a play application and copy it and the scripts used to install
# and run it to a well-known 'package' directory. The name of the package 
# directory is provided by the variable DEFAULT_PACKAGE_DIR defined in 
# 'defaults.sh'.
#
# The contents of the package directory then constitute the distribution package 
# for the Scala boardgame application.
#
# This script can be run in a docker container for packaging the application.
# In that case, the well-known directory should be volume-mapped to the host
# file system so that it can be used or distributed from the host.
#

#
# import DEFAULT_PACKAGE_DIR
#
. ./defaults.sh

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
# Copy install and startup scripts similarly.
#
# TODO. Only copy needed scripts.
#
SCRIPT_DIR=$PACKAGE_DIR/script
mkdir -p $SCRIPT_DIR
cp -a install.sh run-server.sh get-dynamic-params.sh defaults.sh $SCRIPT_DIR

chmod -R 777 $PACKAGE_DIR

