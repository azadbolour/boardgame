#!/bin/sh -x

#
# Run a deployed play server.
#
# Assumes the server is deployed to the 'dist' directory (relative to the cwd).
#

port=$1             # The http port of the server.
PROD_CONF=$2        # The location of the custom application.conf overriding the bundled one.

defaultPort=6587

if [ -z "$port" ]; then
  port="${defaultPort}"
fi

deployDir=dist

cd ${deployDir}/scala-server-1.0

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
export JAVA_OPTS
echo "JAVA_OPTS: ${JAVA_OPTS}"

./bin/scala-server

