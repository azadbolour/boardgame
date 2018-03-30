#!/bin/sh -x

# 
# Initial setup of the production machine where the docker container will be deployed.
#   
# Sets up a template play production configuration file that then needs to be 
# edited appropriately.
#
# Copy the production application.conf file to a well-known
# file system location accessible by the application. The well-known
# location of all data pertaining to the board game application is:
# 
#       /opt/data/boardgame
#
# The well-known location of the production configuration file
# is conf/prod.conf under the boardgame data directory.
#
# Once copied, the production config file can must be customized 
# to reflect the given deployment.
#

# Get defaults value DEFAULT_BOARDGAME_DATA for conf file.
. defaults.sh

BOARDGAME_DATA=$DEFAULT_BOARDGAME_DATA

confDir=$WORKSPACE/scala-server/conf
prodConfDir=$BOARDGAME_DATA/conf

sudo mkdir -p $BOARDGAME_DATA
sudo chown $USER $BOARDGAME_DATA
sudo mkdir -p $prodConfDir
sudo chown $USER $prodConfDir

cp $confDir/prod.conf.template $prodConfDir/prod.conf
echo "edit $prodConfDir/prod.conf to reflect the environment of your deployment"

