#!/bin/sh

#
# Build a base docker image for the game server as of the latest github source.
#

namespace=$1
tag=$2

if [ -z "${namespace}" -o -z "${tag}" ]; then
  echo "usage: $0 docker-namespace repository-tag"
  exit 1
fi

dockerfile=Dockerfile.boardgame-base

docker build --no-cache --force-rm=true -f ${dockerfile} -t ${namespace}/boardgame-base:${tag} .
