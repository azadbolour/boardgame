#!/bin/sh

#
# Build a base docker image for the game server as of a given git tag.
# TODO. The dockerfiel should checkout the given tag. Currently it just clones. 
# OK for our current purposes.
#

tag=$1

if [ -z "${tag}" ]; then
  echo "usage: $0 tag"
  exit 1
fi

dockerfile=Dockerfile.boardgame-base

docker build --force-rm=true -f ${dockerfile} -t azadbolour/boardgame-base:${tag} .
