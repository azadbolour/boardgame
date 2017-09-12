#!/bin/sh

#
# Build a docker image to run the board game.
# First build the board game from the latest source.
#

tag=$1

if [ -z "${tag}" ]; then
  echo "usage: $0 tag"
  exit 1
fi

dockerfile=Dockerfile.boardgame

docker build --no-cache --force-rm=true -f ${dockerfile} -t azadbolour/boardgame:${tag} .
# docker build --force-rm=true -f ${dockerfile} -t azadbolour/boardgame:${tag} .
