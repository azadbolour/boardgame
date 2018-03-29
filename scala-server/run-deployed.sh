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
# HTTP_PORT, PROD_CONF, PID_FILE, VERSION.
#
. defaults.sh

while [ $# -gt 0 ]; do
    case "$1" in
        --http-port) 
            shift && HTTP_PORT="$1" || die ;;
        --prod-conf) 
            shift && PROD_CONF="$1" || die ;;
        --pid-file) 
            shift && PID_FILE="$1" || die ;;
        --version) 
            shift && VERSION="$1" || die ;;
        *) 
            echo "$0: unknown option $1" && die ;;
    esac
    shift
done

if [ -z "$VERSION" ]; then echo "missing version" && die; fi

#
# Customize the runtime environment of the application.
#
# Play recognizes the system properties http.port (the port it should use)
# and config.file (the custom config file overriding the bundled application.conf).
#

JAVA_OPTS="-Dhttp.port=${port}"
if [ ! -z "$PROD_CONF" ]; then
    JAVA_OPTS="${JAVA_OPTS} -Dconfig.file=${PROD_CONF}"
fi
if [ ! -z "$PID_FILE" ]; then
    mkdir -p `dirname $PID_FILE`
    # Assume this script is only run on when the application cannot be running.
    # If there is a leftover pid file from stopping the docker container - remove it.
    # TODO. Check that no server is running.
    rm -f $PID_FILE
    JAVA_OPTS="${JAVA_OPTS} -Dpidfile.path=${PID_FILE}"
fi

export JAVA_OPTS
echo "JAVA_OPTS: ${JAVA_OPTS}"

server=scala-server-${VERSION}
deployDir=dist
cd ${deployDir}/${server}
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
