#!/bin/sh

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

BOARDGAME_DATA=/opt/data/boardgame

confDir=$WORKSPACE/scala-server/conf
prodConfDir=$BOARDGAME_DATA/conf

sudo mkdir -p $BOARDGAME_DATA
sudo chown $USER $BOARDGAME_DATA
sudo mkdir -p $prodConfDir
sudo chown $USER $prodConfDir

cp $confDir/prod.conf.template $prodConfDir/prod.conf
echo "edit $prodConfDir/prod.conf to reflect the environment of your deployment"

