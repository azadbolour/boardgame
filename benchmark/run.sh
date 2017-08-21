#!/bin/sh

config=$1

if [ -z "$config" ]; then
  config="benchmark-config.yml"
fi

java -jar target/benchmark-1.0-SNAPSHOT-jar-with-dependencies.jar $config
