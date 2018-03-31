#!/bin/sh -x

#
# Build the packager image for the board game.
#

namespace=$1
tag=$2
baseImage=$3

if [ -z "${namespace}" -o -z "${tag}" ]; then
  echo "usage: $0 docker-namespace repository-tag [base-image]"
  exit 1
fi

if [ -z "$baseImage" ]; then 
  baseImage="azadbolour/jvm-node:1.0"
fi

repository=boardgame-scala-packager
dockerfile=Dockerfile.${repository}

#
# Use --no-cache so that the latest source will be pulled.
# Otherwise docker just compares the pull request with a previously-built and cached layer's 
# command and since they are the same it will use the old cached layer.
#
docker build --no-cache --force-rm=true -f ${dockerfile} --build-arg BASE=${baseImage} -t ${namespace}/${repository}:${tag} .

