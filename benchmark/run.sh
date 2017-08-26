#!/bin/sh

config=$1

if [ -z "$config" ]; then
  config="benchmark-config.yml"
fi

java -jar target/benchmark-0.1-SNAPSHOT-jar-with-dependencies.jar $config
