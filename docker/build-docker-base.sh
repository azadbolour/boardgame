#!/bin/sh

#
# Build a base docker image for the game server as of a given git tag.
#

# TODO. Parameterize the build by git tag and add tag to the name.

tag=v0.2
docker build --force-rm=true -t azadbolour/boardgame-base-${tag} base
