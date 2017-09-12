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

#
# Use --no-cache so that the latest source will be pulled.
# Otherwise docker just compares the pull request with a previously-built and cached layer's 
# command and since they are the same it will use the old cached layer.
#
docker build --no-cache --force-rm=true -f ${dockerfile} -t azadbolour/boardgame:${tag} .

# For convenience in development only - when we change teh docker file after the pull request.
# docker build --force-rm=true -f ${dockerfile} -t azadbolour/boardgame:${tag} .
