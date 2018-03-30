#!/bin/sh -x

#
# Copy the packaged play bundle to a well-known host location.
# This script is run inside a docker container for creating the 
# play server package for the application.
#

#
# import DEFAULT_BOARDGAME_DATA
# import BOARDGAME_SERVER
#
. defaults.sh

BOARDGAME_DATA=$DEFAULT_BOARDGAME_DATA

#
# Copy the bundle to well-known location mapped to host machine.
#
mkdir -p $BOARDGAME_DATA/package
cp -a target/universal/*.zip $BOARDGAME_DATA/package/

# 
# Copy startup scripts similarly.
#
# TODO. Only copy needed scripts.
#
TARGET_SCRIPT_DIR=$BOARDGAME_DATA/package/script
mkdir -p $TARGET_SCRIPT_DIR
cp -a *.sh $TARGET_SCRIPT_DIR


