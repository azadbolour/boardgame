#!/bin/sh -x

#
# Wrapper for running a deployed scala server. Used by docker run.
#
# args: 
#   scalaServerDevDir - the root directory of the scala-dev server app
#                       lower level script locations are relative to this directory
#
# environment variables:
#   HTTP_PORT - the http port of the play application
#   PROD_CONF - the specialized application configuration file 
#               that overrides the built-in conf/applicatin.conf
#
#       they allow docker images to be run in different environments
#       without changing the image
#
if [ -z "$HTTP_PORT" ]; then
  HTTP_PORT=6597
fi

scalaServerDevDir=$1
BOARDGAME_VAR=/var/run/boardgame
PID_FILE=$BOARDGAME_VAR/RUNNING_PID

# Assume this script is only run on startup when application cannot be running.
# If there is a leftover pid file from stopping the docker container - remove it.
rm -f $PID_FILE

if [ -z "$scalaServerDevDir" ]; then
  echo "usage: $0 scalaServerDevDir - aborting"
  exit 1
fi

cd $scalaServerDevDir

exec "./run-deployed.sh" "$HTTP_PORT" "$PROD_CONF" "$PID_FILE"
