#!/bin/sh -x

#
# Run an installed play server.
#
# This script may be invoked from the shell to test a locally installed server,
# or as a docker container ENTRYPOINT. In addition, the docker container needs
# be deployable to container services. Our first targeted container service
# is AWS ECS. And ECS only allows parameters to be passed to a
# container as environment variables.
#
# Because we'd like to run the docker ENTRYPOINT in the preferred 'exec' mode,
# which does not allow the evaluation of environment variables in command parameters,
# the parameters to this script have to be passed as environment variables.
#
# The following environment variables are supported:
#
#   HTTP_PORT - the http port of the play application
#   ALLOWED_HOST - host:port
#   PID_FILE  - the pid aka lock file of the running server
#
# These parameters have default values provided in the defaults.sh
# script.

#
# import BOARDGAME_SERVER
# import DEFAULT_INSTALL_DIR 
# import DEFAULT_HTTP_PORT
# import DEFAULT_PID_FILE
#
. ./defaults.sh

if [ -z "$HTTP_PORT" ]; then HTTP_PORT=${DEFAULT_HTTP_PORT}; fi
if [ -z "$ALLOWED_HOST" ]; then ALLOWED_HOST="127.0.0.1:${DEFAULT_HTTP_PORT}"; fi
if [ -z "$PID_FILE" ]; then PID_FILE=${DEFAULT_PID_FILE}; fi

installMessage="make sure server has been deployed"

# import PLAY_SECRET
. get-dynamic-params.sh

#
# Make the directory of the pid file if necessary.
#
PID_DIR=`dirname ${PID_FILE}`
sudo mkdir -p ${PID_DIR}
sudo chown ${USER} ${PID_DIR}
test -d "${PID_DIR}" || (echo "pid directory ${PID_DIR} could not be created" ; exit 1)

SERVER=${BOARDGAME_SERVER}
SERVER_ROOT=${DEFAULT_INSTALL_DIR}/${SERVER}

test ! -d ${SERVER_ROOT} || (echo "server root ${SERVER_ROOT} not a directory - $installMessage"; exit 1)

#
# Customize the runtime environment of the application.
#
# Play recognizes the system properties http.port (the port it should use)
# and config.file (the custom config file overriding the bundled application.conf).
#

JAVA_OPTS="${JAVA_OPTS} -Dhttp.port=${HTTP_PORT}"
JAVA_OPTS="${JAVA_OPTS} -Dplay.filters.hosts.allowed.0=${ALLOWED_HOST}"
JAVA_OPTS="${JAVA_OPTS} -Dpidfile.path=${PID_FILE}"
JAVA_OPTS="${JAVA_OPTS} -Dplay.http.secret.key=${PLAY_SECRET}"

#
# Assume this script is only run when the application cannot be running.
# If there is a leftover pid file from stopping the docker container - remove it.
# TODO. Check that no server is running.
#
rm -f ${PID_FILE}

export JAVA_OPTS
echo "JAVA_OPTS: ${JAVA_OPTS}"

cd ${SERVER_ROOT}
pwd
ls -lt

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
