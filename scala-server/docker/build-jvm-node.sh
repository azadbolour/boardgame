#!/bin/sh

#
# Build the packager image for the board game.
#

namespace=$1
tag=$2

if [ -z "${namespace}" -o -z "${tag}" ]; then
  echo "usage: $0 docker-namespace repository-tag [base-image]"
  exit 1
fi

repository=jvm-node
dockerfile=Dockerfile.${repository}

docker build --no-cache --force-rm=true -f ${dockerfile} -t --build-arg BASE=${baseImage} ${namespace}/${repository}:${tag} .

