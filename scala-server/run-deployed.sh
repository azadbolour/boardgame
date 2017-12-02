#!/bin/sh

# Run locally deployed play server.

port=6597

deployDir=dist
cd dist/scala-server-1.0
export JAVA_OPTS="-Dhttp.port=${port}"
./bin/scala-server

