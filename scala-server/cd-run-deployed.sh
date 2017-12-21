#!/bin/sh

scalaDevDir=$1
port=$2

if [ -z "$scalaDevDir" ]; then
  echo "usage: $0 scalaDevDir"
fi

cd $scalaDevDir

exec "./run-deployed.sh" "$port" 
