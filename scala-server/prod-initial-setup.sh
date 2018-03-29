#!/bin/sh -x

# 
# Initial setup of the production machine: 
#   
#       setup the production configuration file
#       setup the production application pid (lock) file
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

# Get defaults for locations of various files:
# BOARDGAME_DATA for conf file, BOARDGAME_VAR for pid file.
. defaults.sh

BOARDGAME_DATA=$DEFAULT_BOARDGAME_DATA
BOARDGAME_RUN=$DEFAULT_BOARDGAME_RUN

confDir=$WORKSPACE/scala-server/conf
prodConfDir=$BOARDGAME_DATA/conf

sudo mkdir -p $BOARDGAME_DATA
sudo chown $USER $BOARDGAME_DATA
sudo mkdir -p $prodConfDir
sudo chown $USER $prodConfDir

cp $confDir/prod.conf.template $prodConfDir/prod.conf
echo "edit $prodConfDir/prod.conf to reflect the environment of your deployment"

# Set up the temporary file area for board game. 
# The contents are wiped out on system restart.
# The play pid lock file will be configured to be in this area.
# That way the pid lock is automatically removed on restart.

sudo mkdir -p $BOARDGAME_RUN
sudo chown $USER $BOARDGAME_RUN

