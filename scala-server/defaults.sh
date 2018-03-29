#!/bin/sh

#
# Default values used in build and deploy scripts.
#

#
# Running board game's area used for configuration of a deployment, etc.
#
DEFAULT_BOARDGAME_DATA=/opt/data/boardgame

#
# Temporary runtime file area for the board game.
# Make sure it is under /var, so the contents get wiped out on system restart.
# The play pid lock file must be configured to be in this area.
# That way the pid lock is automatically removed on restart.
#
DEFAULT_BOARDGAME_RUN=/var/run/boardgame

#
# Version of the application as provided in build.sbt.
#
DEFAULT_VERSION=`./server-version.sh`

#
# Default http port - may be changed in command line scripts that use it.
#
DEFAULT_HTTP_PORT=6597

#
# The path to the deployed application's configuration file. 
# Configuration parameters may be added or overridden here.
#
DEFAULT_PROD_CONF=$DEFAULT_BOARDGAME_DATA/conf/prod.conf

#
# The pid aka lock for for board game's play server.
#
DEFAULT_PID_FILE=$DEFAULT_BOARDGAME_RUN/play.pid

