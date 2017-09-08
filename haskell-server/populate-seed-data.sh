#!/bin/sh

configPath=$1

if [ -z "$configPath" ]; then
  configPath="./config.yml"
fi

if [ -f ${configPath} ]; then 
  stack exec boardgame-seed-data-populator $configPath
else
  stack exec boardgame-seed-data-populator
fi

