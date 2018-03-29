#!/bin/sh -x

#
# Run a deployed play server.
#
# Assumes the server is deployed to the 'dist' directory (relative to the cwd).
#
# Command line options:
#
#   --http-port port# - the http port of the play application
#   --prod-conf path - the specialized application configuration file 
#               that overrides the built-in conf/applicatin.conf
#   --pid-file path -  The pid aka lock file of the running production server.
#

#
# Get default values of command line parameters:
#
#       DEFAULT_HTTP_PORT
#       DEFAULT_PROD_CONF
#       DEFAULT_PID_FILE
#       DEFAULT_VERSION
#
. defaults.sh

while [ $# -gt 0 ]; do
    case "$1" in
        --http-port) 
            shift && HTTP_PORT="$1" || (echo "missing http-port value"; exit 1) ;;
        --prod-conf) 
            shift && PROD_CONF="$1" || (echo "missing prod-donf value"; exit 1) ;;
        --pid-file) 
            shift && PID_FILE="$1" || (echo "missing pid-file value"; exit 1) ;;
        --version) 
            shift && VERSION="$1" || (echo "mission version value"; exit 1) ;;
        *) 
            echo "$0: unknown option $1" && exit 1 ;;
    esac
    shift
done

if [ -z "$HTTP_PORT" ]; then HTTP_PORT=${DEFAULT_HTTP_PORT}; fi
if [ -z "$PROD_CONF" ]; then PROD_CONF=${DEFAULT_PROD_CONF}; fi
if [ -z "$PID_FILE" ]; then PID_FILE=${DEFAULT_PID_FILE}; fi
if [ -z "$VERSION" ]; then VERSION=${DEFAULT_VERSION}; fi

initMessage="make sure host machine has been initialized"
test -f "${PROD_CONF}" || (echo "production config file ${PROD_CONF} does not exist - $initMessage" ; exit 1)
test -d "`dirname $PID_FILE`" || (echo "directory of pid file ${PID_FILE} does not exist - $initMessage" ; exit 1)

#
# Customize the runtime environment of the application.
#
# Play recognizes the system properties http.port (the port it should use)
# and config.file (the custom config file overriding the bundled application.conf).
#

JAVA_OPTS="-Dhttp.port=${HTTP_PORT}"
JAVA_OPTS="${JAVA_OPTS} -Dconfig.file=${PROD_CONF}"
JAVA_OPTS="${JAVA_OPTS} -Dpidfile.path=${PID_FILE}"

# Assume this script is only run on when the application cannot be running.
# If there is a leftover pid file from stopping the docker container - remove it.
# TODO. Check that no server is running.
rm -f $PID_FILE

export JAVA_OPTS
echo "JAVA_OPTS: ${JAVA_OPTS}"

server=scala-server-${VERSION}
deployDir=dist
serverDir=${deployDir}/${server}

test -d $serverDir || (echo "server directory ${serverDir} does not exists - make sure server has been deployed"; exit 1)

cd $serverDir
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
