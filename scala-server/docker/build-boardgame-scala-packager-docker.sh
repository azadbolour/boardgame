#!/bin/sh

#
# Build a base docker image for the game server as of the latest github source.
#

# namespace convention: azadbolour
# tag convention: 0.1, 0.2, ...

namespace=$1
tag=$2

if [ -z "${namespace}" -o -z "${tag}" ]; then
  echo "usage: $0 docker-namespace repository-tag"
  exit 1
fi

dockerfile=Dockerfile.boardgame-scala-packager

docker build --no-cache --force-rm=true -f ${dockerfile} -t ${namespace}/boardgame-scala-packager:${tag} .
