#!/bin/sh

#
# Build a base docker image for the game server as of the latest github source.
#

tag=$1

if [ -z "${tag}" ]; then
  echo "usage: $0 tag"
  exit 1
fi

dockerfile=Dockerfile.boardgame-base

docker build --no-cache --force-rm=true -f ${dockerfile} -t azadbolour/boardgame-base:${tag} .
# docker build --force-rm=true -f ${dockerfile} -t azadbolour/boardgame-base:${tag} .
