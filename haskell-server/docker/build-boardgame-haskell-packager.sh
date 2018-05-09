#!/bin/sh

#
# Build a docker repository for the haskell game server that packages all its build and run dependencies.
#

namespace=$1
tag=$2

if [ -z "${namespace}" -o -z "${tag}" ]; then
  echo "usage: $0 docker-namespace  repository-tag"
  exit 1
fi

repository=boardgame-haskell-packager
dockerfile=Dockerfile.${repository}

docker build --no-cache --force-rm=true -f ${dockerfile} -t ${namespace}/${repository}:${tag} .
