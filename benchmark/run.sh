#!/bin/sh

version=0.9.1

config=$1

if [ -z "$config" ]; then
  config="benchmark-config.yml"
fi

java -jar target/benchmark-${version}-jar-with-dependencies.jar ${config}
