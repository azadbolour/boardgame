#!/bin/sh

config=$1

if [ -z "$config" ]; then
  config="benchmark-config.yml"
fi

java -jar target/benchmark-0.5-jar-with-dependencies.jar ${config}
