#!/bin/sh

if [ -z "$HTTP_PORT" ]; then
  echo "env varaible HTTP_PORT not set - aborting"
  exit 1
fi

scalaDevDir=$1

if [ -z "$scalaDevDir" ]; then
  echo "usage: $0 scalaDevDir - aborting"
  exit 1
fi

cd $scalaDevDir

exec "./run-deployed.sh" "$HTTP_PORT" 
