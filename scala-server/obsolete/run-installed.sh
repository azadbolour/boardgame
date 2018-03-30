#!/bin/sh -x

#
# Run an installed play server.
#
# This script may be invoked from the shell to test a locally installed server,
# or from a docker file ENTRYPOINT. In addition, the docker container needs 
# be able deployed on container services. Our first targeted container service 
# is AWS ECS. It turns out that ECS only allows parameters to be passed to a
# container as environment variables.
#
# Because we'd like to run the docker ENTRYPOINT in the preferred 'exec' mode,
# which does not allow the evaluation of environment variables in command parameters,
# the parameters to this script have to be passed as environment variables.
#
# The following environment variables are needed to provide flexibility in running
# a container in different environments from the same docker image.
#
#   HTTP_PORT - the http port of the play application
#   ALLOWED_HOST - host:port
#   PROD_CONF - the specialized application configuration file 
#               that overrides the built-in conf/applicatin.conf
#   PID_FILE  - the pid aka lock file of the running server
#   FORCE_REWRITE - force rewrite of production configuration file even if it exists
#           a non-empty value forces a rewrite
#           use this for running from docker container since the parameters may change
#           over time and can be refreshed by restarting the container
#
# These parameters have default values provided in the defaults.sh
# script.

#
# This script assume that the source code used to build and install
# the server exists at the working directory and that the build and 
# install occurred under the source code root according to the build
# and install scripts in the source directory.
#

#
# Imports from defaults.sh: BOARDGAME_SERVER, DEFAULT_INSTALL_DIR, 
#   DEFAULT_HTTP_PORT, DEFAULT_PROD_CONF, DEFAULT_PID_FILE.
#
. defaults.sh

if [ -z "$HTTP_PORT" ]; then HTTP_PORT=${DEFAULT_HTTP_PORT}; fi
if [ -z "$ALLOWED_HOST" ]; then ALLOWED_HOST="127.0.0.1:${DEFAULT_HTTP_PORT}"; fi
if [ -z "$PROD_CONF" ]; then PROD_CONF=${DEFAULT_PROD_CONF}; fi
if [ -z "$PID_FILE" ]; then PID_FILE=${DEFAULT_PID_FILE}; fi

initMessage="make sure host machine has been initialized"
installMessage="make sure server has been deployed"

# Get PLAY_SECRET.
. get-dynamic-params.sh

#
# Make the directory of the pid file if necessary.
#
PID_DIR=`dirname $PID_FILE`
sudo mkdir -p $PID_DIR
sudo chown $USER $PID_DIR
test -d "$PID_DIR" || (echo "pid directory ${PID_DIR} could not be created" ; exit 1)

#
# Make the directory of the production config file if necessary.
#
CONF_DIR=$WORKSPACE/scala-server/conf
PROD_CONF_DIR=`dirname $PROD_CONF`
sudo mkdir -p $PROD_CONF_DIR
sudo chown $USER $PROD_CONF_DIR
test -d "$PROD_CONF_DIR" || (echo "production conf directory ${PROD_CONF_DIR} could not be created" ; exit 1)

#
# Recreate the production config file from its template.
# Must be redone each time since the parameters may change dynamically.
#
if [ ! -e $PID_FILE -o ! -z "$FORCE_REWRITE" ]; then
    cp $CONF_DIR/prod.conf.template $PROD_CONF
    test -f "${PROD_CONF}" || (echo "production config file ${PROD_CONF} could not be created" ; exit 1)
    set -i '' -e "s/_ALLOWED_HOSTS_/$ALLOWED_HOST/" -e "s/_SECRET_/$PLAY_SECRET/" $PROD_CONF
fi

SERVER=$BOARDGAME_SERVER
INSTALL_DIR=$DEFAULT_INSTALL_DIR
SERVER_ROOT=${INSTALL_DIR}/${SERVER}

test ! -d ${SERVER_ROOT} || (echo "server root ${SERVER_ROOT} not a directory - $installMessage"; exit 1)

#
# Customize the runtime environment of the application.
#
# Play recognizes the system properties http.port (the port it should use)
# and config.file (the custom config file overriding the bundled application.conf).
#

JAVA_OPTS="-Dhttp.port=${HTTP_PORT}"
JAVA_OPTS="${JAVA_OPTS} -Dconfig.file=${PROD_CONF}"
JAVA_OPTS="${JAVA_OPTS} -Dpidfile.path=${PID_FILE}"

#
# Assume this script is only run when the application cannot be running.
# If there is a leftover pid file from stopping the docker container - remove it.
# TODO. Check that no server is running.
#
rm -f $PID_FILE

export JAVA_OPTS
echo "JAVA_OPTS: ${JAVA_OPTS}"

cd $SERVER_ROOT
./bin/scala-server 


# 
# Profiling with YourKit:
#
# Uncomment the following for profiling.
# And use PROD_CONF to override default configurations, e.g., maxActiveGames.
#
# Here is what the custom application.conf might look like:
#
#    include "application.conf"
#    service.maxActiveGames=300
#
# TODO. Use sample run.sh in yourkit samples directory to get platform-specific installation directory.
# YOURKIT="/Applications/YourKit_Java_Profiler_2014_build_14112.app/Contents/Resources/"
# YOURKIT_AGENT=${YOURKIT}/bin/mac/libyjpagent.jnilib
# ./bin/scala-server -J-agentpath:${YOURKIT_AGENT}
