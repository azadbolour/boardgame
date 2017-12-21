#!/bin/sh -x

# Run locally deployed play server.

port=$1
defaultPort=${http.port}

if [ -z "$port" ]; then
  port="${defaultPort}"
fi

deployDir=dist
cd dist/scala-server-1.0
export JAVA_OPTS="-Dhttp.port=${port}"
./bin/scala-server

