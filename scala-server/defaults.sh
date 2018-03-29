#!/bin/sh

#
# Default values used in build and deploy scripts.
#

#
# Running board game's area used for configuration of a deployment, etc.
#
BOARDGAME_DATA=/opt/data/boardgame

#
# Directory of the board game's play server pid file.
#
BOARDGAME_RUN=/var/run/boardgame

#
# Version of the application as provided in build.sbt.
#
VERSION=`grep '^version\s*:=\s*' build.sbt | sed -e 's/version[ ]*:=[ ]*//' -e 's/"//g' -e 's/ //g'`

#
# Default http port - may be changed in command line scripts that use it.
#
HTTP_PORT=6597

#
# The path to the deployed application's configuration file. 
# Configuration parameters may be added or overridden here.
#
PROD_CONF=$BOARDGAME_DATA/conf/prod.conf

#
# The pid aka lock for for board game's play server.
#
PID_FILE=$BOARDGAME_RUN/play.pid

