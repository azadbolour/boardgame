#!/bin/sh -x

#
# Run a deployed play server.
#
# Assumes the server is deployed to the 'dist' directory (relative to the cwd).
#

port=$1             # The http port of the server.
PROD_CONF=$2        # The location of the custom application.conf overriding the bundled one.
PID_FILE=$3         # The location of the process pid (lock) file for the play application.

defaultPort=6587

if [ -z "$port" ]; then
  port="${defaultPort}"
fi

deployDir=dist

# TODO. Get version from build.sbt.
version=0.9.1
server=scala-server-${version}

cd ${deployDir}/${server}

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
    JAVA_OPTS="${JAVA_OPTS} -Dpidfile.path=${PID_FILE}"
fi

export JAVA_OPTS
echo "JAVA_OPTS: ${JAVA_OPTS}"

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

# Normal run.
./bin/scala-server 

